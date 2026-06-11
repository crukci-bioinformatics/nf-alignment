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
        referenceFastaValue   = channel.value(file(fastaReferencePath()))
        genomeSizesValue      = channel.value(file(genomeSizesPath()))
        referenceRefFlatValue = channel.value(file(referenceRefFlatPath()))

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

        picardWithRef = mergeResult.mergedBam.combine(referenceFasta: referenceFastaValue)

        picardAlignmentMetrics(picardWithRef)
        picardWGSMetrics(picardWithRef, false)
        picardRnaSeqMetrics(picardWithRef.combine(referenceRefFlat: referenceRefFlatValue))
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

        sampleWithRef = sampleMergeResult.sampleBam.combine(referenceFasta: referenceFastaValue)

        sampleAlignmentMetrics(sampleWithRef)
        sampleWGSMetrics(sampleWithRef, false)
        sampleRnaSeqMetrics(sampleWithRef.combine(referenceRefFlat: referenceRefFlatValue))
        sampleInsertSizeMetrics(sampleWithRef)

        def covOut  = sampleGenomeCoverage(sampleMergeResult.sampleBam.combine(genomeSizes: genomeSizesValue))
        def sortOut = sampleBedSort(covOut.combine(genomeSizes: genomeSizesValue))
        sampleBedgraphToBigwig(sortOut.combine(genomeSizes: genomeSizesValue))

    emit:
        bams        = mergeResult.mergedBam
        sampleBams  = sampleMergeResult.sampleBam
}
