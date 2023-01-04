/*
 * STAR paired end pipeline inner work flow.
 */

params.aligner = "star"

include { basenameExtractor; starIndexPath } from "../components/functions"
include { STAR } from "../processes/star"
include { pairedend } from "./pairedend"

workflow star_pe
{
    take:
        csv_channel

    main:
        star_index_channel = channel.fromPath(starIndexPath())

        fastq_channel =
            csv_channel
            .map
            {
                row ->
                tuple basenameExtractor(row.Read1),
                      [ file("${params.fastqDir}/${row.Read1}", checkIfExists: true),
                        file("${params.fastqDir}/${row.Read2}", checkIfExists: true) ]
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
        pairedend(STAR.out, csv_channel, chunk_count_channel)
}
