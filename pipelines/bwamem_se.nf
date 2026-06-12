/*
 * BWAmem single read inner work flow.
 */

include { sizeOf } from "plugin/nf-crukci-support"
include { basenameExtractor; extractChunkNumber } from "../components/functions"
include { splitFastq } from "../processes/fastq"
include { bwaMem } from "../processes/bwamem"
include { singleRead } from "./singleread"

workflow bwamemSE_wf
{
    take:
        csvChannel

    main:
        def bwamem2IndexPath = Path.of(APDefaults.bwamem2IndexPath(params))
        def bwamem2IndexDir = bwamem2IndexPath.parent
        def bwamem2IndexPrefix = bwamem2IndexPath.fileName.toString()

        fastqChannel =
            csvChannel
            .map { row ->
                record(
                    basename: basenameExtractor(row.Read1),
                    read: 1,
                    fastqFile: file("${params.fastqDir}/${row.Read1}", checkIfExists: true, arity: '1')
                )
            }

        splitChannel = splitFastq(fastqChannel)

        // Get the number of chunks for each base id.
        // See https://groups.google.com/g/nextflow/c/fScdmB_w_Yw and
        // https://github.com/danielecook/TIL/blob/master/Nextflow/groupKey.md

        chunkCountChannel =
            splitChannel.map { r -> record(basename: r.basename, chunkCount: sizeOf(r.fastqFiles)) }

        // Flatten the list of files in the channel to have a channel with
        // a single file per item in a list, and add the BWA-mem2 index fields.

        perChunkChannel =
            splitChannel.flatMap { r ->
                r.fastqFiles.collect { f ->
                    record(basename: r.basename, chunk: extractChunkNumber(f), sequenceFiles: [f],
                           bwamem2IndexDir: bwamem2IndexDir, bwamem2IndexPrefix: bwamem2IndexPrefix)
                }
            }

        bwaMemChannel = bwaMem(perChunkChannel)
        singleRead(bwaMemChannel, csvChannel, chunkCountChannel)
}
