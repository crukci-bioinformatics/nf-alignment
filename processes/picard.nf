/*
 * Picard tools.
 */

import static org.apache.commons.lang3.StringUtils.trimToNull

include { javaMemoryOptions; sizeOf; safeName } from "../modules/nextflow-support/functions"
include { alignedFileName } from '../components/functions'
include { rnaseqStrandSpecificity } from '../components/defaults'

/**
 * Calculate the maximum number of reads to hold in RAM for Picard sorting
 * tasks based on memory allocated to the task and the read length.
 */
def maxReadsInRam(availableMB, readLength)
{
    /*
     * See http://broadinstitute.github.io/picard/faq.html question 2 for notes
     * on the RAM and maxRecordsInRAM balance.
     *
     * From those figures, we have 250,000 reads per GB at 100bp reads.
     * With the longer indexing, a read of 100bp is 272 bytes (characters),
     * of which 100 is the sequence, 100 is the quality and 72 is everything else.
     *
     * Using a "proper" GB (1000^3), that allows us 4000 bytes per read at 100bp.
     *
     * Dividing that up between the overhead and the sequence & quality, we have
     * overhead = 4000 * 72 / 272 = 1059 bytes of the 4000 and
     * sequence = 4000 * 200 / 272 = 2941 bytes of the 4000.
     *
     * We therefore 2941 bytes available per read for the sequence data, and since
     * that number is for 100bp reads, that gives 29.41 bytes per base.
     *
     * We can then go backwards. For 50 bp reads, the allocation necessary is
     * 1059 + 50 * 29.41 = 2530 bytes necessary for the read and for 150 bp reads
     * 1059 + 150 * 29.41 = 5471 bytes required.
     *
     * Going back to the 4000 bytes available for 100bp reads, we can then get a
     * ratio for reads per allocation (how many reads at the read length will fit
     * into the 4000 byte allocation).
     *
     * At 50bp:
     * 4000 / 2530 = 1.581 reads per allocation
     * At 100bp:
     * 4000 / 4000 = 1 read per allocation (how we started)
     * At 150bp:
     * 4000 / 5471 = 0.7311 reads per allocation.
     *
     * That multiplier gives us the answer we need for reads per GB, and so maximum
     * reads in RAM.
     *
     * 50bp:
     * 250,000 * 1.581 = 395257 per GB
     * 150bp:
     * 250,000 * 0.7311 = 182782 per GB
     *
     * That number then just needs to be multiplied up by the memory available. We
     * scale for megabytes as we shouldn't assume a round number of GB for the task.
     */

    final def allocationPerRead = 4000.0  // bytes
    final def bytesPerBase = 29.41176
    final def overheadPerRead = 1059.0    // bytes

    final def allocationForReadLength = overheadPerRead + bytesPerBase * readLength  // bytes
    final def allocationRatio = allocationPerRead / allocationForReadLength

    final def readsPerGB = 250000 * allocationRatio    // reads / gb
    final def readsPerMB = readsPerGB / 1024           // reads / mb
    final def totalReads = availableMB * readsPerMB    // mb * reads/mb to give reads

    return totalReads as long
}

/*
 * Run Picard's 'AddOrReplaceReadGroups' to add read group information to an aligned
 * BAM file. Defaults are provided if the alignment.csv file is missing values.
 */
process picard_addreadgroups
{
    label "picardSmall"

    input:
        tuple val(basename), val(chunk), path(inBam), val(sequencingInfo)

    output:
        tuple val(basename), val(chunk), path(outBam)

    shell:
        outBam = "${basename}.readgroups.${chunk}.bam"
        javaMem = javaMemoryOptions(task).jvmOpts

        def rgcn = trimToNull(sequencingInfo['SequencingCentre'])
        RGCN = !rgcn ? "" : "RGCN=\"${rgcn}\""

        def rgdt = trimToNull(sequencingInfo['SequencingDate'])
        RGDT = !rgdt ? "" : "RGDT=\"${rgdt}\""

        def rgid = trimToNull(sequencingInfo['ReadGroup'])
        RGID = !rgid ? "RGID=Z" : "RGID=\"${rgid}\""

        def rglb = trimToNull(sequencingInfo['Library'])
        RGLB = !rglb ? "RGLB=Unknown" : "RGLB=\"${rglb}\""

        def rgpl = trimToNull(sequencingInfo['SequencingPlatform'])
        RGPL = !rgpl ? "RGPL=Unknown" : "RGPL=\"${rgpl}\""

        def rgpm = trimToNull(sequencingInfo['PlatformModel'])
        RGPM = !rgpm ? "" : "RGPM=\"${rgpm}\""

        def rgpu = trimToNull(sequencingInfo['PlatformUnit'])
        RGPU = !rgpu ? /RGPU="Not available"/ : "RGPU=\"${rgpu}\""

        def rgsm = trimToNull(sequencingInfo['SourceMaterial'])
        RGSM = !rgsm ? /RGSM="Not available"/ : "RGSM=\"${rgsm}\""

        template "picard/AddReadGroups.sh"
}

/*
 * Sort a BAM file using Picard's 'SortSam' tool. Used for sorting single read files.
 */
process picard_sortsam
{
    label "picard"

    input:
        tuple val(basename), val(chunk), path(inBam)

    output:
        tuple val(basename), path(outBam)

    shell:
        outBam = "${basename}.sorted.${chunk}.bam"

        def memoryInfo = javaMemoryOptions(task)
        javaMem = memoryInfo.jvmOpts
        readsInRam = maxReadsInRam(memoryInfo.heap, 100)

        template "picard/SortSam.sh"
}

/*
 * Sort a BAM file and fix mate pair information using Picard's
 * 'FixMateInformation' tool. Used for sorting and fixing paired end files.
 */
process picard_fixmate
{
    label "picard"

    cpus 2

    input:
        tuple val(basename), val(chunk), path(inBam)

    output:
        tuple val(basename), path(outBam)

    shell:
        outBam = "${basename}.fixed.${chunk}.bam"

        def memoryInfo = javaMemoryOptions(task)
        javaMem = memoryInfo.jvmOpts
        readsInRam = maxReadsInRam(memoryInfo.heap, 100)

        template "picard/FixMateInformation.sh"
}

/*
 * Merge aligned BAM files that are chunks of the whole, optionally marking
 * PCR duplicates. Uses Picard's 'MergeSamFiles' for simple merging and
 * 'MarkDuplicates' for duplicate marking.
 */
process picard_merge_or_markduplicates
{
    label "picard"

    publishDir params.bamDir, mode: "link"

    input:
        tuple val(basename), path(inBams)

    output:
        tuple val(basename), path(outBam), emit: merged_bam
        path outBai
        path metrics optional true

    shell:
        outBam = "${alignedFileName(basename)}.bam"
        outBai = "${alignedFileName(basename)}.bai"
        metrics = "${alignedFileName(basename)}.duplication.txt"

        def memoryInfo = javaMemoryOptions(task)
        javaMem = memoryInfo.jvmOpts
        readsInRam = maxReadsInRam(memoryInfo.heap, 100)

        if (params.markDuplicates)
        {
            template "picard/MarkDuplicates.sh"
        }
        else
        {
            // Even if there is only one file, run in through MergeSamFiles to create the index.
            template "picard/MergeSamFiles.sh"
        }
}

/*
 * Calculate alignment metrics with Picard's 'CollectAlignmentSummaryMetrics'.
 */
process picard_alignmentmetrics
{
    label "picard"
    label "metrics"

    publishDir params.bamDir, mode: "link"

    when:
        params.alignmentMetrics

    input:
        tuple val(basename), path(inBam), path(referenceFasta)

    output:
        path metrics

    shell:
        metrics = "${alignedFileName(basename)}.alignment.txt"
        javaMem = javaMemoryOptions(task).jvmOpts

        template "picard/CollectAlignmentSummaryMetrics.sh"
}

/*
 * Calculate whole genome sequencing metrics with Picard's 'CollectWgsMetrics'.
 * Note that this process can take a fair while.
 */
process picard_wgsmetrics
{
    label "picard"
    label "metrics"

    publishDir params.bamDir, mode: "link"

    when:
        params.wgsMetrics

    input:
        tuple val(basename), path(inBam), path(referenceFasta)
        val(countUnpairedReads)

    output:
        path metrics

    shell:
        metrics = "${alignedFileName(basename)}.wgs.txt"
        javaMem = javaMemoryOptions(task).jvmOpts

        template "picard/CollectWgsMetrics.sh"
}

/*
 * Calculate whole genome sequencing metrics with Picard's 'CollectRnaSeqMetrics'.
 */
process picard_rnaseqmetrics
{
    label "picard"
    label "metrics"

    publishDir params.bamDir, mode: "link"

    when:
        params.rnaseqMetrics

    input:
        tuple val(basename), path(inBam), path(referenceFasta), path(referenceRefFlat)

    output:
        path metrics

    shell:
        metrics = "${alignedFileName(basename)}.rnaseq.txt"
        strandSpecificity = rnaseqStrandSpecificity()

        javaMem = javaMemoryOptions(task).jvmOpts

        template "picard/CollectRnaSeqMetrics.sh"
}

/*
 * Calculate insert size metrics with Picard's 'CollectInsertSizeMetrics'.
 * This can only be used on paired end alignments.
 */
process picard_insertmetrics
{
    label "picard"
    label "metrics"

    publishDir params.bamDir, mode: "link"

    when:
        params.insertSizeMetrics

    input:
        tuple val(basename), path(inBam), path(referenceFasta)

    output:
        path metrics optional true

    shell:
        metrics = "${alignedFileName(basename)}.insertsize.txt"
        plot = "${alignedFileName(basename)}.insertsize.pdf"

        javaMem = javaMemoryOptions(task).jvmOpts

        template "picard/CollectInsertSizeMetrics.sh"
}

/*
 * Merge aligned BAM files based on sample name, optionally marking
 * PCR duplicates. Uses Picard's 'MergeSamFiles' for simple merging and
 * 'MarkDuplicates' for duplicate marking.
 */
process sample_merge_or_markduplicates
{
    label "picard"

    publishDir params.sampleBamDir, mode: "link"

    when:
        params.mergeSamples

    input:
        tuple val(sampleName), path(inBams)

    output:
        tuple val(sampleName), path(outBam), emit: sample_bam
        path outIndex optional true
        path metrics optional true

    shell:
        safeSampleName = safeName(sampleName)
        outBam = "${alignedFileName(safeSampleName)}.bam"
        outIndex = "${alignedFileName(safeSampleName)}.bai"
        metrics = "${alignedFileName(safeSampleName)}.duplication.txt"

        def memoryInfo = javaMemoryOptions(task)
        javaMem = memoryInfo.jvmOpts
        readsInRam = maxReadsInRam(memoryInfo.heap, 100)

        if (params.markDuplicates)
        {
            template "picard/MarkDuplicates.sh"
        }
        else
        {
            if (sizeOf(inBams) == 1)
            {
                // When "inBams" is exactly one, there is no need to run the single file
                // through merge. It can just be linked to.
                "ln -s ${inBams} \"${outBam}\""
            }
            else
            {
                template "picard/MergeSamFiles.sh"
            }
        }
}

/*
 * Calculate alignment metrics with Picard's 'CollectAlignmentSummaryMetrics'
 * for merged whole sample BAM files.
 */
process sample_alignmentmetrics
{
    label "picard"
    label "metrics"

    publishDir params.sampleBamDir, mode: "link"

    when:
        params.alignmentMetrics

    input:
        tuple val(sampleName), path(inBam), path(referenceFasta)

    output:
        path metrics

    shell:
        safeSampleName = safeName(sampleName)
        metrics = "${alignedFileName(safeSampleName)}.alignment.txt"

        javaMem = javaMemoryOptions(task).jvmOpts

        template "picard/CollectAlignmentSummaryMetrics.sh"
}

/*
 * Calculate whole genome sequencing metrics with Picard's 'CollectWgsMetrics'
 * for merged whole sample BAM files.
 * Note that this process can take a fair while.
 */
process sample_wgsmetrics
{
    label "picard"
    label "metrics"

    publishDir params.sampleBamDir, mode: "link"

    when:
        params.wgsMetrics

    input:
        tuple val(sampleName), path(inBam), path(referenceFasta)
        val(countUnpairedReads)

    output:
        path metrics

    shell:
        safeSampleName = safeName(sampleName)
        metrics = "${alignedFileName(safeSampleName)}.wgs.txt"

        javaMem = javaMemoryOptions(task).jvmOpts

        template "picard/CollectWgsMetrics.sh"
}

/*
 * Calculate whole genome sequencing metrics with Picard's 'CollectRnaSeqMetrics'
 * for merged whole sample BAM files.
 */
process sample_rnaseqmetrics
{
    label "picard"
    label "metrics"

    publishDir params.sampleBamDir, mode: "link"

    when:
        params.rnaseqMetrics

    input:
        tuple val(sampleName), path(inBam), path(referenceFasta), path(referenceRefFlat)

    output:
        path metrics

    shell:
        safeSampleName = safeName(sampleName)
        metrics = "${alignedFileName(safeSampleName)}.rnaseq.txt"
        strandSpecificity = rnaseqStrandSpecificity()

        javaMem = javaMemoryOptions(task).jvmOpts

        template "picard/CollectRnaSeqMetrics.sh"
}

/*
 * Calculate insert size metrics with Picard's 'CollectInsertSizeMetrics'
 * for merged whole sample BAM files.
 * This can only be used on paired end alignments.
 */
process sample_insertmetrics
{
    label "picard"
    label "metrics"

    publishDir params.sampleBamDir, mode: "link"

    when:
        params.insertSizeMetrics

    input:
        tuple val(sampleName), path(inBam), path(referenceFasta)

    output:
        path metrics optional true

    shell:
        safeSampleName = safeName(sampleName)
        metrics = "${alignedFileName(safeSampleName)}.insertsize.txt"
        plot = "${alignedFileName(safeSampleName)}.insertsize.pdf"

        javaMem = javaMemoryOptions(task).jvmOpts

        template "picard/CollectInsertSizeMetrics.sh"
}
