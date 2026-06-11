/*
 * BWAmem single read inner work flow.
 */

include { sizeOf } from "plugin/nf-crukci-support"
include { basenameExtractor; extractChunkNumber } from "../components/functions"
include { bowtie2IndexPath } from "../components/defaults"
include { splitFastq } from "../processes/fastq"
include { bowtieSE } from "../processes/bowtie"
include { singleRead } from "./singleread"


workflow bowtieSE_wf
{
    take:
        csvChannel

    main:
        bowtie2IndexFile = file(bowtie2IndexPath())
        bowtie2IndexDirValue    = channel.value(bowtie2IndexFile.parent)
        bowtie2IndexPrefixValue = channel.value(bowtie2IndexFile.name)

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
        // a single file per item. Also extract the chunk number from the file name.
        // Add the Bowtie 2 index fields to each per-chunk record.

        perChunkChannel =
            splitFastq.out
            .flatMap { r ->
                r.fastqFiles.collect { f ->
                    record(basename: r.basename, chunk: extractChunkNumber(f), read1: f)
                }
            }
            .combine(bowtie2IndexDir: bowtie2IndexDirValue, bowtie2IndexPrefix: bowtie2IndexPrefixValue)

        bowtieSe(perChunkChannel)
        singleread(bowtieSe.out, csvChannel, chunkCountChannel)
}
