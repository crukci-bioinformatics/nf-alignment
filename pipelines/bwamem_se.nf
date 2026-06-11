/*
 * BWAmem single read inner work flow.
 */

include { sizeOf } from "plugin/nf-crukci-support"
include { basenameExtractor; extractChunkNumber } from "../components/functions"
include { bwamem2IndexPath } from "../components/defaults"
include { splitFastq } from "../processes/fastq"
include { bwaMem } from "../processes/bwamem"
include { singleRead } from "./singleread"

workflow bwamemSE_wf
{
    take:
        csvChannel

    main:
        bwamem2IndexFile = file(bwamem2IndexPath())
        bwamem2IndexDirValue    = channel.value(bwamem2IndexFile.parent)
        bwamem2IndexPrefixValue = channel.value(bwamem2IndexFile.name)

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
        // a single file per item in a list, and add the BWA-mem2 index fields.

        perChunkChannel =
            splitFastq.out
            .flatMap { r ->
                r.fastqFiles.collect { f ->
                    record(basename: r.basename, chunk: extractChunkNumber(f), sequenceFiles: [f])
                }
            }
            .combine(bwamem2IndexDir: bwamem2IndexDirValue, bwamem2IndexPrefix: bwamem2IndexPrefixValue)

        bwaMem(perChunkChannel)
        singleread(bwaMem.out, csvChannel, chunkCountChannel)
}
