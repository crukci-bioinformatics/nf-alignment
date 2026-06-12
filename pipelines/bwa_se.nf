/*
 * BWA single read inner work flow.
 */

include { sizeOf } from "plugin/nf-crukci-support"
include { basenameExtractor } from "../components/functions"
include { splitFastq } from "../processes/fastq"
include { bwaAln; bwaSamSE } from "../processes/bwa"
include { singleRead } from "./singleread"

workflow bwaSE_wf
{
    take:
        csvChannel

    main:
        def bwaIndexPath = Path.of(APDefaults.bwaIndexPath(params))
        def bwaIndexDir = bwaIndexPath.parent
        def bwaIndexPrefix = bwaIndexPath.fileName.toString()

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
        // a single file per item. Add the BWA index fields to each per-chunk record.

        perChunkChannel =
            splitChannel.flatMap { r ->
                r.fastqFiles.collect { f ->
                    record(basename: r.basename, read: r.read, fastqFile: f,
                           bwaIndexDir: bwaIndexDir, bwaIndexPrefix: bwaIndexPrefix)
                }
            }

        alignChannel = bwaAln(perChunkChannel)

        samChannel =
            alignChannel.map { r ->
                record(basename: r.basename, chunk: r.chunk, saiFile: r.saiFile, fastqFile: r.fastqFile,
                       bwaIndexDir: bwaIndexDir, bwaIndexPrefix: bwaIndexPrefix) }

        // Add the index fields again for the samse step.
        bwaChannel = bwaSamSE(samChannel)
        singleRead(bwaChannel, csvChannel, chunkCountChannel)
}
