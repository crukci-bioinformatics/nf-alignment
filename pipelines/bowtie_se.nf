/*
 * Bowtie 2 single read inner work flow.
 */

include { sizeOf } from "plugin/nf-crukci-support"
include { basenameExtractor; extractChunkNumber } from "../components/functions"
include { splitFastq } from "../processes/fastq"
include { bowtieSE } from "../processes/bowtie"
include { singleRead } from "./singleread"


workflow bowtieSE_wf
{
    take:
        csvChannel

    main:
        def bowtie2IndexPath = Path.of(APDefaults.bowtie2IndexPath(params))
        def bowtie2IndexDir = bowtie2IndexPath.parent
        def bowtie2IndexPrefix = bowtie2IndexPath.fileName.toString()

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
        // a single file per item. Also extract the chunk number from the file name.
        // Add the Bowtie 2 index fields to each per-chunk record.

        perChunkChannel =
            splitChannel.flatMap { r ->
                r.fastqFiles.collect { f ->
                    def chunkNum = extractChunkNumber(f)
                    record(basename: r.basename, chunk: chunkNum, read1: f,
                           bowtie2IndexDir: bowtie2IndexDir, bowtie2IndexPrefix: bowtie2IndexPrefix)
                }
            }

        bowtieChannel = bowtieSE(perChunkChannel)
        singleRead(bowtieChannel, csvChannel, chunkCountChannel)
}
