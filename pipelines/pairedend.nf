/*
 * Post alignment work flow for paired end alignment.
 * The input to this work flow should be the aligned BAM files from the aligner work flow.
 *
 * Process calls return their outputs directly as channel values rather than using
 * the .out accessor or the | pipe operator, making the data flow explicit and
 * compatible with typed workflow declarations.
 */

include {
    picardFixMate; picardMergeOrMarkDuplicates; picardAddReadGroups;
    picardAlignmentMetrics; picardWGSMetrics; picardRnaSeqMetrics; picardInsertSizeMetrics;
    sampleMergeOrMarkDuplicates;
    sampleAlignmentMetrics; sampleWGSMetrics; sampleRnaSeqMetrics; sampleInsertSizeMetrics
} from "../processes/picard"

include { makeSafeForMerging } from "../processes/premerging"

include {
    sampleGenomeCoverage; sampleBedSort; sampleBedgraphToBigwig
} from "../processes/coverage"

include { basenameExtractor } from "../components/functions"
include { fastaReferencePath; genomeSizesPath; referenceRefFlatPath } from "../components/defaults"

workflow pairedEnd
{
    take:
        alignmentChannel
        sequencingInfoChannel
        chunkCountChannel

    main:
        def referenceFasta   = file(fastaReferencePath())
        def genomeSizes      = file(genomeSizesPath())
        def referenceRefFlat = file(referenceRefFlatPath())

        // Add sequencing info back to the channel for read groups.
        // It is available from sequencingInfoChannel, the rows from the CSV file.
        readGroupsChannel =
            alignmentChannel
            .combine(
                sequencingInfoChannel.map { row ->
                    record(basename: basenameExtractor(row.Read1), sequencingInfo: row)
                },
                by: ['basename']
            )

        rgBams = picardAddReadGroups(readGroupsChannel)
        fixedBams = picardFixMate(rgBams)

        // Group the outputs by base name. Use the groupKey function to
        // allow things to run when each group is complete, rather than
        // waiting for everything.

        mergeChannel =
            fixedBams
            .combine(chunkCountChannel, by: ['basename'])
            .map { r ->
                tuple groupKey(r.basename, r.chunkCount), r.bam
            }
            .groupTuple()
            .map { basename, bams -> record(basename: basename, bams: bams) }

        mergeResult = picardMergeOrMarkDuplicates(mergeChannel)

        picardWithRef = mergeResult.mergedBam.map { r -> record(basename: r.basename, bam: r.bam, referenceFasta: referenceFasta) }

        picardAlignmentMetrics(picardWithRef)
        picardWGSMetrics(picardWithRef, false)
        picardRnaSeqMetrics(picardWithRef.map { r -> record(basename: r.basename, bam: r.bam, referenceFasta: r.referenceFasta, referenceRefFlat: referenceRefFlat) })
        picardInsertSizeMetrics(picardWithRef)

        // Join the output of merge or mark duplicates with the sequencing info
        // by base name.
        withInfoChannel =
            mergeResult.mergedBam
            .combine(
                sequencingInfoChannel.map { row ->
                    record(basename: basenameExtractor(row.Read1), sequencingInfo: row)
                },
                by: ['basename']
            )

        def safeForMerge = makeSafeForMerging(withInfoChannel)

        // Map to the sample name and collect BAM files for that sample.
        safeSampleChannel = safeForMerge
            .map { r -> record(sampleName: r.sequencingInfo.SampleName, bam: r.bam) }

        // Get the number of files for each sample and provide a groupKey for merging
        // so it can start each group once all the files are received.

        sampleCountChannel =
            sequencingInfoChannel
            .map { row -> tuple row.SampleName, row.Read1 }
            .groupTuple()
            .map { sampleName, readFiles ->
                record(sampleName: sampleName, chunkCount: readFiles.size())
            }

        sampleMergeChannel =
            safeSampleChannel
            .combine(sampleCountChannel, by: ['sampleName'])
            .map { r ->
                tuple groupKey(r.sampleName, r.chunkCount), r.bam
            }
            .groupTuple()
            .map { sampleName, bams -> record(sampleName: sampleName, bams: bams) }

        sampleMergeResult = sampleMergeOrMarkDuplicates(sampleMergeChannel)

        sampleWithRef = sampleMergeResult.sampleBam.map { r -> record(sampleName: r.sampleName, bam: r.bam, referenceFasta: referenceFasta) }

        sampleAlignmentMetrics(sampleWithRef)
        sampleWGSMetrics(sampleWithRef, false)
        sampleRnaSeqMetrics(sampleWithRef.map { r -> record(sampleName: r.sampleName, bam: r.bam, referenceFasta: r.referenceFasta, referenceRefFlat: referenceRefFlat) })
        sampleInsertSizeMetrics(sampleWithRef)

        def covOut  = sampleGenomeCoverage(sampleMergeResult.sampleBam.map { r -> record(sampleName: r.sampleName, bam: r.bam, genomeSizes: genomeSizes) })
        def sortOut = sampleBedSort(covOut.map { r -> record(sampleName: r.sampleName, bedgraph: r.bedgraph, genomeSizes: genomeSizes) })
        sampleBedgraphToBigwig(sortOut.map { r -> record(sampleName: r.sampleName, sortedBed: r.sortedBed, genomeSizes: genomeSizes) })

    emit:
        bams        = mergeResult.mergedBam
        sampleBams  = sampleMergeResult.sampleBam
}
