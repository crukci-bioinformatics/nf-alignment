/*
 * BWA paired end pipeline inner work flow.
 */

include { sizeOf } from "plugin/nf-crukci-support"
include { basenameExtractor } from "../components/functions"
include { splitFastq as splitFastq1; splitFastq as splitFastq2 } from "../processes/fastq"
include { bwaAln as bwaAln1; bwaAln as bwaAln2; bwaSamPE } from "../processes/bwa"
include { pairedEnd } from "./pairedend"

workflow bwaPE_wf
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
                    fastq1: file("${params.fastqDir}/${row.Read1}", checkIfExists: true, arity: '1'),
                    fastq2: file("${params.fastqDir}/${row.Read2}", checkIfExists: true, arity: '1')
                )
            }

        // Split into two channels, one read in each, for BWA aln.

        read1Channel =
            fastqChannel
            .map { r -> record(basename: r.basename, read: 1, fastqFile: r.fastq1) }

        read2Channel =
            fastqChannel
            .map { r -> record(basename: r.basename, read: 2, fastqFile: r.fastq2) }

        // Split the files in these channels into chunks.

        splitFastq1(read1Channel)
        splitFastq2(read2Channel)

        // Get the number of chunks for each base id (same for both channels).
        // See https://groups.google.com/g/nextflow/c/fScdmB_w_Yw and
        // https://github.com/danielecook/TIL/blob/master/Nextflow/groupKey.md

        chunkCountChannel =
            splitFastq1.out
            .map { r -> record(basename: r.basename, chunkCount: sizeOf(r.fastqFiles)) }

        // Flatten the chunks in each channel and add the BWA index fields.

        read1PerChunkChannel =
            splitFastq1.out
            .flatMap { r ->
                r.fastqFiles.collect { f ->
                    record(basename: r.basename, read: r.read, fastqFile: f,
                           bwaIndexDir: bwaIndexDir, bwaIndexPrefix: bwaIndexPrefix)
                }
            }

        read2PerChunkChannel =
            splitFastq2.out
            .flatMap { r ->
                r.fastqFiles.collect { f ->
                    record(basename: r.basename, read: r.read, fastqFile: f,
                           bwaIndexDir: bwaIndexDir, bwaIndexPrefix: bwaIndexPrefix)
                }
            }

        // Align the chunks in independent channels.

        bwaAln1(read1PerChunkChannel)
        bwaAln2(read2PerChunkChannel)

        // Join the output of these two channels into one, grouping on base name and chunk number.
        // Rename the sai/fastq fields so they don't collide when the two records are merged,
        // then add the index fields for the sampe step.

        sampeChannel =
            bwaAln1.out.map { r ->
                record(basename: r.basename, chunk: r.chunk, saiFile1: r.saiFile, fastqFile1: r.fastqFile)
            }
            .join(
                bwaAln2.out.map { r ->
                    record(basename: r.basename, chunk: r.chunk, saiFile2: r.saiFile, fastqFile2: r.fastqFile)
                },
                by: ['basename', 'chunk'],
                failOnDuplicate: true,
                failOnMismatch: true
            )
            .map { r -> record(basename: r.basename, chunk: r.chunk,
                               saiFile1: r.saiFile1, fastqFile1: r.fastqFile1,
                               saiFile2: r.saiFile2, fastqFile2: r.fastqFile2,
                               bwaIndexDir: bwaIndexDir, bwaIndexPrefix: bwaIndexPrefix) }

        bwaSamPE(sampeChannel)
        pairedEnd(bwaSamPE.out, csvChannel, chunkCountChannel)
}
