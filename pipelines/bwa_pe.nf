/*
 * BWA paired end pipeline inner work flow.
 */

params.aligner = "bwa"

include { basenameExtractor; sizeOf } from "../components/functions"
include { bwaIndexPath } from "../components/defaults"
include { split_fastq as split_fastq_1; split_fastq as split_fastq_2 } from "../processes/fastq"
include { bwa_aln as bwa_aln_1; bwa_aln as bwa_aln_2; bwa_sampe } from "../processes/bwa"
include { pairedend } from "./pairedend"

workflow bwa_pe
{
    take:
        csv_channel

    main:
        bwa_index_path = file(bwaIndexPath())
        bwa_index_channel = channel.of(tuple bwa_index_path.parent, bwa_index_path.name)

        fastq_channel =
            csv_channel
            .map
            {
                row ->
                tuple basenameExtractor(row.Read1),
                      file("${params.fastqDir}/${row.Read1}", checkIfExists: true),
                      file("${params.fastqDir}/${row.Read2}", checkIfExists: true)
            }

        // Split into two channels, one read in each, for BWA aln.

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

        // Split the files in these channels into chunks.

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

        // Map these channels so there is a single FASTQ per item in the channel

        read1_per_chunk_channel =
            split_fastq_1.out
            .transpose()
            .combine(bwa_index_channel)

        read2_per_chunk_channel =
            split_fastq_2.out
            .transpose()
            .combine(bwa_index_channel)

        // Align the chunks in independent channels.

        bwa_aln_1(read1_per_chunk_channel)
        bwa_aln_2(read2_per_chunk_channel)

        // Combine the output of these two channels into one, grouping on base name and chunk number.

        sampe_channel =
            bwa_aln_1.out
            .join(bwa_aln_2.out, by: [0,1], failOnDuplicate: true, failOnMismatch: true)
            .combine(bwa_index_channel)

        bwa_sampe(sampe_channel)
        pairedend(bwa_sampe.out, csv_channel, chunk_count_channel)
}
