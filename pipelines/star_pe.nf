/*
 * STAR paired end pipeline inner work flow.
 */

params.aligner = "star"

include { basenameExtractor } from "../components/functions"
include { STAR } from "../processes/star"
include { pairedend } from "./pairedend"

workflow star_pe
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
                tuple basenameExtractor(row.Read1), [ file("${params.fastqDir}/${row.Read1}"), file("${params.fastqDir}/${row.Read2}") ]
            }
            .combine(star_index_channel)

        STAR(fastq_channel)
        pairedend(STAR.out, csv_channel)
}
