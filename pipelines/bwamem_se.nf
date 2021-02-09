params.aligner = "bwamem"

include { basenameExtractor } from "../components/functions"
include { bwa_mem } from "../components/bwaprocesses"
include { singleread } from "../components/singleread"

workflow bwamem_se
{
    take:
        csv_channel

    main:
        fastq_channel =
            csv_channel
            .map
            {
                row ->
                tuple basenameExtractor(row.Read1), file("${params.fastqDir}/${row.Read1}")
            }
            .splitFastq(by: params.chunkSize, file: true, compress: params.compressSplitFastq)

        bwa_mem(fastq_channel)
        singleread(bwa_mem.out, csv_channel)
}
