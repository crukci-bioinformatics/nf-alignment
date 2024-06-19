/*
 * BWA single read inner work flow.
 */

include { sizeOf } from "../modules/nextflow-support/functions"
include { basenameExtractor } from "../components/functions"
include { bwaIndexPath } from "../components/defaults"
include { split_fastq } from "../processes/fastq"
include { bwa_aln; bwa_samse } from "../processes/bwa"
include { singleread } from "./singleread"

workflow bwa_se_wf
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
            .combine(bwa_index_channel)

        bwa_aln(per_chunk_channel)
        bwa_samse(bwa_aln.out.combine(bwa_index_channel))
        singleread(bwa_samse.out, csv_channel, chunk_count_channel)
}
