/*
 * STAR paired end pipeline inner work flow.
 */

include { sizeOf } from "plugin/nf-crukci-support"
include { basenameExtractor; extractChunkNumber } from "../components/functions"
include { splitFastq as splitFastq1; splitFastq as splitFastq2 } from "../processes/fastq"
include { STAR } from "../processes/star"
include { pairedEnd } from "./pairedend"

workflow starPE_wf
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
                    fastq1: file("${params.fastqDir}/${row.Read1}", checkIfExists: true, arity: '1'),
                    fastq2: file("${params.fastqDir}/${row.Read2}", checkIfExists: true, arity: '1')
                )
            }

        // Split into two channels, one read in each, for fastq splitting.

        read1Channel =
            fastqChannel
            .map { r -> record(basename: r.basename, read: 1, fastqFile: r.fastq1) }

        read2Channel =
            fastqChannel
            .map { r -> record(basename: r.basename, read: 2, fastqFile: r.fastq2) }

        splitFastq1(read1Channel)
        splitFastq2(read2Channel)

        // Get the number of chunks for each base id (same for both channels).
        // See https://groups.google.com/g/nextflow/c/fScdmB_w_Yw and
        // https://github.com/danielecook/TIL/blob/master/Nextflow/groupKey.md

        chunkCountChannel =
            splitFastq1.out
            .map { r -> record(basename: r.basename, chunkCount: sizeOf(r.fastqFiles)) }

        // Flatten the list of files in both channels to have two channels with
        // a single file per item. Also extract the chunk number from the file name.

        perChunkChannel1 =
            splitFastq1.out
            .flatMap { r ->
                r.fastqFiles.collect { f ->
                    record(basename: r.basename, chunk: extractChunkNumber(f), read1: f)
                }
            }

        perChunkChannel2 =
            splitFastq2.out
            .flatMap { r ->
                r.fastqFiles.collect { f ->
                    record(basename: r.basename, chunk: extractChunkNumber(f), read2: f)
                }
            }

        // Join these channels by base name and chunk number, combine the two reads
        // into a list for STAR, and add the STAR index.

        combinedChunkChannel =
            perChunkChannel1
            .join(perChunkChannel2, by: ['basename', 'chunk'])
            .map { r -> record(basename: r.basename, chunk: r.chunk, sequenceFiles: [r.read1, r.read2], starIndex: starIndex) }

        STAR(combinedChunkChannel)
        pairedEnd(STAR.out, csvChannel, chunkCountChannel)
}
