/*
 * STAR single read inner work flow.
 */

params.aligner = "star"

include { basenameExtractor } from "../components/functions"
include { STAR } from "../processes/star"
include { singleread } from "./singleread"

workflow star_se
{
    take:
        csv_channel

    main:
        star_index_channel = channel.fromPath(params.starIndex)

        fastq_channel =
            csv_channel
            .map
            {
                row ->
                tuple basenameExtractor(row.Read1), file("${params.fastqDir}/${row.Read1}")
            }
            .combine(star_index_channel)

        // STAR doesn't do chunking, so for every base name there is always one chunk.

        chunk_count_channel =
            fastq_channel
            .map
            {
                basename, files, index ->
                tuple basename, 1
            }

        STAR(fastq_channel)
        singleread(STAR.out, csv_channel, chunk_count_channel)
}
