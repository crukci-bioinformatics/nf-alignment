params.aligner = "bwamem"

include { basenameExtractor } from "../components/functions"
include { split_fastq } from "../processes/fastq"
include { splitToPerChunkChannel; bwa_mem } from "../processes/bwamem"
include { singleread } from "./singleread"

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
                tuple basenameExtractor(row.Read1), 1, file("${params.fastqDir}/${row.Read1}")
            }

        split_fastq(fastq_channel)

        per_chunk_channel = splitToPerChunkChannel(split_fastq.out)
            .map
            {
                basename, chunkNumber, fastq1 ->
                tuple basename, [ fastq1 ]
            }

        bwa_mem(per_chunk_channel)
        singleread(bwa_mem.out, csv_channel)
}
