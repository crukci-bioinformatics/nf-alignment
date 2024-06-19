/*
 * STAR single read inner work flow.
 */

include { sizeOf } from "../modules/nextflow-support/functions"
include { basenameExtractor; extractChunkNumber } from "../components/functions"
include { starIndexPath } from "../components/defaults"
include { split_fastq } from "../processes/fastq"
include { STAR } from "../processes/star"
include { singleread } from "./singleread"

workflow star_se_wf
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
                      1,
                      files("${params.fastqDir}/${row.Read1}", checkIfExists: true, arity: '1')
            }

        split_fastq(fastq_channel)

        // Get the number of chunks for each base id.
        // See https://groups.google.com/g/nextflow/c/fScdmB_w_Yw and
        // https://github.com/danielecook/TIL/blob/master/Nextflow/groupKey.md

        chunk_count_channel =
            split_fastq.out
            .map
            {
                basename, read, fastqFiles ->
                tuple basename, sizeOf(fastqFiles)
            }

        // Flatten the list of files in the channel to have a channel with
        // a single file per item in a list.
        // Also extract the chunk number from the file name.

        per_chunk_channel =
            split_fastq.out
            .transpose()
            .map
            {
                basename, read, fastq ->
                tuple basename, extractChunkNumber(fastq), [ fastq ]
            }
            .combine(star_index_channel)

        STAR(per_chunk_channel)
        singleread(STAR.out, csv_channel, chunk_count_channel)
}
