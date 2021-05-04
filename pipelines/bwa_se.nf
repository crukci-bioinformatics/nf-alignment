/*
 * BWA single read inner work flow.
 */

params.aligner = "bwa"

include { basenameExtractor } from "../components/functions"
include { split_fastq } from "../processes/fastq"
include { bwa_aln; bwa_samse } from "../processes/bwa"
include { singleread } from "./singleread"

workflow bwa_se
{
    take:
        csv_channel

    main:
        bwa_index_path = file(params.bwaIndex)
        bwa_index_channel = channel.of(tuple bwa_index_path.parent, bwa_index_path.name)

        fastq_channel =
            csv_channel
            .map
            {
                row ->
                tuple basenameExtractor(row.Read1), 1, file("${params.fastqDir}/${row.Read1}")
            }

        split_fastq(fastq_channel)

        per_chunk_channel =
            split_fastq.out
            .transpose()
            .combine(bwa_index_channel)

        bwa_aln(per_chunk_channel)
        bwa_samse(bwa_aln.out.combine(bwa_index_channel))
        singleread(bwa_samse.out, csv_channel)
}
