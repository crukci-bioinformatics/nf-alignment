/*
 * Bowtie 2 paired end inner work flow.
 */

include { sizeOf } from "plugin/nf-crukci-support"
include { basenameExtractor; extractChunkNumber } from "../components/functions"
include { splitFastq as splitFastq1; splitFastq as splitFastq2 } from "../processes/fastq"
include { bowtiePE } from "../processes/bowtie"
include { pairedEnd } from "./pairedend"


workflow bowtiePE_wf
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

        splitChannel1 = splitFastq1(read1Channel)
        splitChannel2 = splitFastq2(read2Channel)

        // Get the number of chunks for each base id (same for both channels).
        // See https://groups.google.com/g/nextflow/c/fScdmB_w_Yw and
        // https://github.com/danielecook/TIL/blob/master/Nextflow/groupKey.md

        chunkCountChannel =
            splitChannel1.map { r -> record(basename: r.basename, chunkCount: sizeOf(r.fastqFiles)) }

        // Flatten the list of files in both channels to have two channels with
        // a single file per item. Also extract the chunk number from the file name.
        // Name the read fields 'read1' and 'read2' for the bowtiePe process.
        // For the strict parser, we need to create a single field in both called "key" for joining.

        perChunkChannel1 =
            splitChannel1.flatMap { r ->
                r.fastqFiles.collect { f ->
                    def chunkNum = extractChunkNumber(f)
                    record(key: "${r.basename}:${chunkNum}", basename: r.basename, chunk: chunkNum, read1: f)
                }
            }

        perChunkChannel2 =
            splitChannel2.flatMap { r ->
                r.fastqFiles.collect { f ->
                    def chunkNum = extractChunkNumber(f)
                    record(key: "${r.basename}:${chunkNum}", basename: r.basename, chunk: chunkNum, read2: f)
                }
            }

        // Join these channels by the "key" field, then remove the key and add the index.

        combinedChunkChannel =
            perChunkChannel1
                .join(perChunkChannel2, by: 'key')
                .map { r -> record(basename: r.basename, chunk: r.chunk, read1: r.read1, read2: r.read2,
                                   bowtie2IndexDir: bowtie2IndexDir, bowtie2IndexPrefix: bowtie2IndexPrefix) }

        bowtieChannel = bowtiePE(combinedChunkChannel)
        pairedEnd(bowtieChannel, csvChannel, chunkCountChannel)
}
