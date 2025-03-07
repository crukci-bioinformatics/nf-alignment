/*
 * BWAmem single read inner work flow.
 */

include { sizeOf } from "../modules/nextflow-support/functions"
include { basenameExtractor; extractChunkNumber } from "../components/functions"
include { bwamem2IndexPath } from "../components/defaults"
include { split_fastq } from "../processes/fastq"
include { bwa_mem } from "../processes/bwamem"
include { singleread } from "./singleread"

workflow bwamem_se_wf
{
    take:
        csv_channel

    main:
        bwamem2_index_path = file(bwamem2IndexPath())
        bwamem2_index_channel = channel.of(tuple bwamem2_index_path.parent, bwamem2_index_path.name)

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

        per_chunk_channel =
            split_fastq.out
            .transpose()
            .map
            {
                basename, read, fastq ->
                tuple basename, extractChunkNumber(fastq), [ fastq ]
            }
            .combine(bwamem2_index_channel)

        bwa_mem(per_chunk_channel)
        singleread(bwa_mem.out, csv_channel, chunk_count_channel)
}
