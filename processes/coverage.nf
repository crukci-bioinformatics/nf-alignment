/*
 * Processes for calculating genome coverage.
 */

nextflow.enable.types = true

include { safeName } from "plugin/nf-crukci-support"
include { alignedFileName } from "../components/functions"

/*
 * Run UCSC 'genomeCoverageBed' tool to calculate coverage from a BAM file.
 * Produces a bedgraph.
 */
process sampleGenomeCoverage
{
    label 'coverage'

    publishDir params.sampleBamDir, mode: "link", pattern: "*.bedgraph"

    input:
        record(sampleName: String, bam: Path, genomeSizes: Path)

    output:
        record(sampleName: sampleName, bedgraph: file(bedgraph))

    when:
        params.createCoverage

    shell:
        inBam = bam
        safeSampleName = safeName(sampleName)
        bedgraph = "${alignedFileName(safeSampleName)}.bedgraph"
        template "ucsc/genomeCoverageBed.sh"
}

/*
 * Sort a bedgraph file into a sorted bed with Bedtools' 'bedSort'.
 */
process sampleBedSort
{
    label 'coverage'

    input:
        record(sampleName: String, bedgraph: Path, genomeSizes: Path)

    output:
        record(sampleName: sampleName, sortedBed: file(sortedBed))

    shell:
        safeSampleName = safeName(sampleName)
        sortedBed = "${alignedFileName(safeSampleName)}.sorted.bed"
        template "bedtools/bedSort.sh"
}

/*
 * Convert a bedgraph file to bigwig with the UCSC 'bedGraphToBigWig' tool.
 */
process sampleBedgraphToBigwig
{
    label 'coverage'

    publishDir params.sampleBamDir, mode: "link", pattern: "*.bigwig"

    input:
        record(sampleName: String, sortedBed: Path, genomeSizes: Path)

    output:
        record(sampleName: sampleName, bigwig: file(bigwig))

    shell:
        safeSampleName = safeName(sampleName)
        bigwig = "${alignedFileName(safeSampleName)}.bigwig"
        template "ucsc/bedGraphToBigWig.sh"
}
