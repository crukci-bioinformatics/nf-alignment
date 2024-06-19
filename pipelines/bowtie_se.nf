/*
 * BWAmem single read inner work flow.
 */

include { sizeOf } from "../modules/nextflow-support/functions"
include { basenameExtractor; extractChunkNumber } from "../components/functions"
include { bowtie2IndexPath } from "../components/defaults"
include { split_fastq } from "../processes/fastq"
include { bowtie_se } from "../processes/bowtie"
include { singleread } from "./singleread"


workflow bowtie_se_wf
{
    take:
        csv_channel

    main:
        bowtie2_index_path = file(bowtie2IndexPath())
        bowtie2_index_channel = channel.of(tuple bowtie2_index_path.parent, bowtie2_index_path.name)

        fastq_channel =
            csv_channel
            .map
            {
                row ->
                tuple basenameExtractor(row.Read1),
                      1,
                      file("${params.fastqDir}/${row.Read1}", checkIfExists: true, arity: '1')
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
        // a single file per item. Also extract the chunk number from the file name.

        per_chunk_channel =
            split_fastq.out
            .transpose()
            .map
            {
                basename, read, fastq ->
                tuple basename, extractChunkNumber(fastq), fastq
            }
            .combine(bowtie2_index_channel)

        bowtie_se(per_chunk_channel)
        singleread(bowtie_se.out, csv_channel, chunk_count_channel)
}
