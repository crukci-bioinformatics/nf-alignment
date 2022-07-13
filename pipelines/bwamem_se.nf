/*
 * BWAmem single read inner work flow.
 */

params.aligner = "bwamem"

include { basenameExtractor } from "../components/functions"
include { split_fastq } from "../processes/fastq"
include { bwa_mem } from "../processes/bwamem"
include { singleread } from "./singleread"

workflow bwamem_se
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
                tuple basenameExtractor(row.Read1), 1, file("${params.fastqDir}/${row.Read1}")
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
                // Fastq files can be a single path or it can be a list of paths.
                // Ideally, Nextflow would always return a list, even of length 1.
                // See https://github.com/nextflow-io/nextflow/issues/2425
                fastqFiles instanceof Collection
                    ? tuple(basename, fastqFiles.size())
                    : tuple(basename, 1)
            }

        per_chunk_channel =
            split_fastq.out
            .transpose()
            .map
            {
                basename, read, fastq ->
                tuple basename, [ fastq ]
            }
            .combine(bwamem2_index_channel)

        bwa_mem(per_chunk_channel)
        singleread(bwa_mem.out, csv_channel, chunk_count_channel)
}
