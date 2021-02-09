include { alignedFileName } from "./functions"

/*
 * SECTION ONE - Alignment processes.
 */

process STAR
{
    cpus 8
    memory { 64.GB * 2 ** (task.attempt - 1) }
    time { 6.hour * task.attempt }
    maxRetries 2

    input:
        tuple val(basename), file(sequenceFiles)

    output:
        tuple val(basename), val(0), path(outBam)

    shell:
        outBam = "${basename}/Aligned.out.bam"
        template "star.sh"
}

/*
 * SECTION TWO - Processing files after alignment.
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
        template "picard/sortSam.sh"
}

process picard_fixmate
{
    label "picard"

    input:
        tuple val(basename), val(chunk), path(inBam)

    output:
        tuple val(basename), path(outBam)

    shell:
        outBam = "${basename}.fixed.${chunk}.bam"
        template "picard/fixMateInformation.sh"
}

process picard_markduplicates
{
    label "picard"

    publishDir params.bamDir, mode: "link", pattern: "*.duplication.txt"

    input:
        tuple val(basename), path(inBams)

    output:
        tuple val(basename), path(outBam), emit: merged_bam
        path metrics optional true

    shell:
        outBam = "${basename}.duplicates.bam"
        metrics = "${basename}.duplication.txt"
        if (params.markDuplicates)
        {
            template "picard/markDuplicates.sh"
        }
        else
        {
            // Sometimes inBams is a single path, others it is a collections of paths.
            // Detect if it is a type of collection, and if so, use its size.
            def numberOfBams = inBams instanceof Collection ? inBams.size() : 1

            if (numberOfBams == 1)
            {
                // When "inBams" is exactly one, there is no need to run the single file
                // through merge. It can just be linked.
                "ln -s ${inBams} \"${outBam}\""
            }
            else
            {
                template "picard/mergeSamFiles.sh"
            }
        }
}

process picard_addreadgroups
{
    label "picard"

    publishDir params.bamDir, mode: "link"

    input:
        tuple val(basename), path(inBam), val(sequencingInfo)

    output:
        tuple val(basename), path(outBam), val(sequencingInfo), emit: final_bam
        path outIndex optional true

    shell:
        outBam = "${alignedFileName(basename)}.bam"
        outIndex = "${alignedFileName(basename)}.bai"
        template "picard/addReadGroups.sh"
}

process picard_alignmentmetrics
{
    label "picard"

    publishDir params.bamDir, mode: "link"

    input:
        tuple val(basename), path(inBam)

    output:
        path metrics

    shell:
        metrics = "${alignedFileName(basename)}.alignment.txt"
        template "picard/collectAlignmentSummaryMetrics.sh"
}

process picard_wgsmetrics
{
    label "picard"

    publishDir params.bamDir, mode: "link"

    when:
        params.wgsMetrics

    input:
        tuple val(basename), path(inBam)
        val(countUnpairedReads)

    output:
        path metrics

    shell:
        metrics = "${alignedFileName(basename)}.wgs.txt"
        template "picard/collectWgsMetrics.sh"
}

process picard_insertmetrics
{
    label "picard"

    publishDir params.bamDir, mode: "link"

    input:
        tuple val(basename), path(inBam)

    output:
        path metrics optional true
        path plot optional true

    shell:
        metrics = "${alignedFileName(basename)}.insertsize.txt"
        plot = "${alignedFileName(basename)}.insertsize.pdf"
        template "picard/collectInsertSizeMetrics.sh"
}

/*
 * SECTION THREE - Sample merging
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
        outBam = "${alignedFileName(sampleName)}.bam"
        outIndex = "${alignedFileName(sampleName)}.bai"
        metrics = "${alignedFileName(sampleName)}.duplication.txt"
        if (params.markDuplicates)
        {
            template "picard/markDuplicates.sh"
        }
        else
        {
            // Sometimes inBams is a single path, others it is a collections of paths.
            // Detect if it is a type of collection, and if so, use its size.
            def numberOfBams = inBams instanceof Collection ? inBams.size() : 1

            if (numberOfBams == 1)
            {
                // When "inBams" is exactly one, there is no need to run the single file
                // through merge. It can just be linked to.
                "ln -s ${inBams} \"${outBam}\""
            }
            else
            {
                template "picard/mergeSamFiles.sh"
            }
        }
}

process sample_alignmentmetrics
{
    label "picard"

    publishDir params.sampleBamDir, mode: "link"

    input:
        tuple val(sampleName), path(inBam)

    output:
        path metrics

    shell:
        metrics = "${alignedFileName(sampleName)}.alignment.txt"
        template "picard/collectAlignmentSummaryMetrics.sh"
}

process sample_wgsmetrics
{
    label "picard"

    publishDir params.sampleBamDir, mode: "link"

    when:
        params.wgsMetrics

    input:
        tuple val(sampleName), path(inBam)
        val(countUnpairedReads)

    output:
        path metrics

    shell:
        metrics = "${alignedFileName(sampleName)}.wgs.txt"
        template "picard/collectWgsMetrics.sh"
}

process sample_insertmetrics
{
    label "picard"

    publishDir params.sampleBamDir, mode: "link"

    input:
        tuple val(sampleName), path(inBam)

    output:
        path metrics optional true
        path plot optional true

    shell:
        metrics = "${alignedFileName(sampleName)}.insertsize.txt"
        plot = "${alignedFileName(sampleName)}.insertsize.pdf"
        template "picard/collectInsertSizeMetrics.sh"
}

/*
 * SECTION FOUR - Sample coverage
 */

process sample_genomecoverage
{
    label 'coverage'

    publishDir params.sampleBamDir, mode: "link"

    when:
        params.createCoverage

    input:
        tuple val(sampleName), path(inBam)

    output:
        tuple val(sampleName), path(bedgraph)

    shell:
        bedgraph = "${alignedFileName(sampleName)}.bedgraph"
        template "ucsc/genomeCoverageBed.sh"
}

process sample_bedsort
{
    label 'coverage'

    input:
        tuple val(sampleName), path(bedgraph)

    output:
        tuple val(sampleName), path(sortedBed)

    shell:
        sortedBed = "${alignedFileName(sampleName)}.sorted.bed"
        template "bedtools/bedSort.sh"
}

process sample_bedgraphtobigwig
{
    label 'coverage'

    publishDir params.sampleBamDir, mode: "link"

    input:
        tuple val(sampleName), path(sortedBed)

    output:
        tuple val(sampleName), path(bigwig)

    shell:
        bigwig = "${alignedFileName(sampleName)}.bigwig"
        template "ucsc/bedGraphToBigWig.sh"
}
