/*
 * Processes for calculating genome coverage.
 */

include { alignedFileName; safeName } from "../components/functions"

/*
 * Run UCSC 'genomeCoverageBed' tool to calculate coverage from a BAM file.
 * Produces a bedgraph.
 */
process sample_genomecoverage
{
    label 'coverage'

    publishDir params.sampleBamDir, mode: "link", pattern: "*.bedgraph"

    when:
        params.createCoverage

    input:
        tuple val(sampleName), path(inBam), path(genomeSizes)

    output:
        tuple val(sampleName), path(bedgraph), path(genomeSizes)

    shell:
        safeSampleName = safeName(sampleName)
        bedgraph = "${alignedFileName(safeSampleName)}.bedgraph"
        template "ucsc/genomeCoverageBed.sh"
}

/*
 * Sort a bedgraph file into a sorted bed with Bedtools' 'bedSort'.
 */
process sample_bedsort
{
    label 'coverage'

    input:
        tuple val(sampleName), path(bedgraph), path(genomeSizes)

    output:
        tuple val(sampleName), path(sortedBed), path(genomeSizes)

    shell:
        safeSampleName = safeName(sampleName)
        sortedBed = "${alignedFileName(safeSampleName)}.sorted.bed"
        template "bedtools/bedSort.sh"
}

/*
 * Convert a bedgraph file to bigwig with the UCSC 'bedGraphToBigWig' tool.
 */
process sample_bedgraphtobigwig
{
    label 'coverage'

    publishDir params.sampleBamDir, mode: "link", pattern: "*.bigwig"

    input:
        tuple val(sampleName), path(sortedBed), path(genomeSizes)

    output:
        tuple val(sampleName), path(bigwig)

    shell:
        safeSampleName = safeName(sampleName)
        bigwig = "${alignedFileName(safeSampleName)}.bigwig"
        template "ucsc/bedGraphToBigWig.sh"
}
