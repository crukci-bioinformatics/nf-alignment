/*
 * STAR single read inner work flow.
 */

include { sizeOf } from "plugin/nf-crukci-support"
include { basenameExtractor; extractChunkNumber } from "../components/functions"
include { splitFastq } from "../processes/fastq"
include { STAR } from "../processes/star"
include { singleRead } from "./singleread"

workflow starSE_wf
{
    take:
        csvChannel

    main:
        def starIndex = file(APDefaults.starIndexPath(params))

        fastqChannel =
            csvChannel
            .map { row ->
                record(
                    basename: basenameExtractor(row.Read1),
                    read: 1,
                    fastqFile: file("${params.fastqDir}/${row.Read1}", checkIfExists: true, arity: '1')
                )
            }

        splitFastq(fastqChannel)

        // Get the number of chunks for each base id.
        // See https://groups.google.com/g/nextflow/c/fScdmB_w_Yw and
        // https://github.com/danielecook/TIL/blob/master/Nextflow/groupKey.md

        chunkCountChannel =
            splitFastq.out
            .map { r -> record(basename: r.basename, chunkCount: sizeOf(r.fastqFiles)) }

        // Flatten the list of files in the channel to have a channel with
        // a single file per item in a list, and add the STAR index.

        perChunkChannel =
            splitFastq.out
            .flatMap { r ->
                r.fastqFiles.collect { f ->
                    record(basename: r.basename, chunk: extractChunkNumber(f), sequenceFiles: [f], starIndex: starIndex)
                }
            }

        STAR(perChunkChannel)
        singleRead(STAR.out, csvChannel, chunkCountChannel)
}
