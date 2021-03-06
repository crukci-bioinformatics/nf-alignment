/*
 * BWAmem paired end pipeline inner work flow.
 */

params.aligner = "bwamem"

include { basenameExtractor; extractChunkNumber } from "../components/functions"
include { split_fastq as split_fastq_1; split_fastq as split_fastq_2 } from "../processes/fastq"
include { bwa_mem } from "../processes/bwamem"
include { pairedend } from "./pairedend"


workflow bwamem_pe
{
    take:
        csv_channel

    main:
        bwamem2_index_path = file(params.bwamem2Index)
        bwamem2_index_channel = channel.of(tuple bwamem2_index_path.parent, bwamem2_index_path.name)

        fastq_channel =
            csv_channel
            .map
            {
                row ->
                tuple basenameExtractor(row.Read1), file("${params.fastqDir}/${row.Read1}"), file("${params.fastqDir}/${row.Read2}")
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
                tuple basename, [ r1, r2 ]
            }
            .combine(bwamem2_index_channel)

        bwa_mem(combined_chunk_channel)
        pairedend(bwa_mem.out, csv_channel)
}
