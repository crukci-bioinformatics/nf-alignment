params.aligner = "bwamem"

include { basenameExtractor } from "../components/functions"
include { bwa_mem } from "../components/bwaprocesses"
include { pairedend } from "../components/pairedend"

workflow bwamem_pe
{
    take:
        csv_channel

    main:
        fastq_channel =
            csv_channel
            .map
            {
                row ->
                tuple basenameExtractor(row.Read1), file("${params.fastqDir}/${row.Read1}"), file("${params.fastqDir}/${row.Read2}")
            }
            .splitFastq(by: params.chunkSize, pe:true, file: true, compress: params.compressSplitFastq)
            .map
            {
                // Converts a three element tuple into a two element tuple, with the second
                // element being a two element list of the reads.
                basename, read1, read2 ->
                tuple basename, [ read1, read2 ]
            }

        bwa_mem(fastq_channel)
        pairedend(bwa_mem.out, csv_channel)
}
