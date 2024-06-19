/*
 * STAR paired end pipeline inner work flow.
 */

include { sizeOf } from "../modules/nextflow-support/functions"
include { basenameExtractor; extractChunkNumber } from "../components/functions"
include { starIndexPath } from "../components/defaults"
include { split_fastq as split_fastq_1; split_fastq as split_fastq_2 } from "../processes/fastq"
include { STAR } from "../processes/star"
include { pairedend } from "./pairedend"

workflow star_pe_wf
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
                      file("${params.fastqDir}/${row.Read1}", checkIfExists: true, arity: '1'),
                      file("${params.fastqDir}/${row.Read2}", checkIfExists: true, arity: '1')
            }

        // Split into two channels, one read in each, for fastq splitting.

        read1_channel =
            fastq_channel
            .map
            {
                base, read1, read2 ->
                tuple base, 1, read1
            }

        read2_channel =
            fastq_channel
            .map
            {
                base, read1, read2 ->
                tuple base, 2, read2
            }

        split_fastq_1(read1_channel)
        split_fastq_2(read2_channel)

        // Get the number of chunks for each base id (same for both channels).
        // See https://groups.google.com/g/nextflow/c/fScdmB_w_Yw and
        // https://github.com/danielecook/TIL/blob/master/Nextflow/groupKey.md

        chunk_count_channel =
            split_fastq_1.out
            .map
            {
                basename, read, fastqFiles ->
                tuple basename, sizeOf(fastqFiles)
            }

        // Flatten the list of files in both channels to have two channels with
        // a single file per item. Also extract the chunk number from the file name.

        per_chunk_channel_1 =
            split_fastq_1.out
            .transpose()
            .map
            {
                basename, read, fastq ->
                tuple basename, extractChunkNumber(fastq), fastq
            }

        per_chunk_channel_2 =
            split_fastq_2.out
            .transpose()
            .map
            {
                basename, read, fastq ->
                tuple basename, extractChunkNumber(fastq), fastq
            }

        // Combine these channels by base name and chunk number, and present the
        // two individual files as a list of two.

        combined_chunk_channel = per_chunk_channel_1
            .combine(per_chunk_channel_2, by: 0..1)
            .map
            {
                basename, chunk, r1, r2 ->
                tuple basename, chunk, [ r1, r2 ]
            }
            .combine(star_index_channel)

        STAR(combined_chunk_channel)
        pairedend(STAR.out, csv_channel, chunk_count_channel)
}
