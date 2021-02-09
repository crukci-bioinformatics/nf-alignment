params.aligner = "bwa"

include { basenameExtractor } from "../components/functions"
include { bwa_aln; bwa_samse } from "../components/bwaprocesses"
include { singleread } from "../components/singleread"

workflow bwa_se
{
    take:
        csv_channel

    main:
        fastq_channel =
            csv_channel
            .map
            {
                row ->
                tuple basenameExtractor(row.Read1), 1, file("${params.fastqDir}/${row.Read1}")
            }
            .splitFastq(by: params.chunkSize, file: true, compress: params.compressSplitFastq)

        bwa_aln(fastq_channel)
        bwa_samse(bwa_aln.out)
        singleread(bwa_samse.out, csv_channel)
}
