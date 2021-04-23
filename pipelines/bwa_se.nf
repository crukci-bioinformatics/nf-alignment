params.aligner = "bwa"

include { basenameExtractor } from "../components/functions"
include { split_fastq; bwa_aln; bwa_samse } from "../processes/bwa"
include { singleread } from "./singleread"

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

        split_fastq(fastq_channel)
        
        per_chunk_channel = split_fastq.out
            .flatMap
            {
                basename, read, chunks ->
                chunks.collect { tuple basename, read, it }
            }
        
        bwa_aln(per_chunk_channel) | bwa_samse
        singleread(bwa_samse.out, csv_channel)
}
