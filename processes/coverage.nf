include { alignedFileName } from "../components/functions"

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
        bedgraph = "${alignedFileName(sampleName)}.bedgraph"
        template "ucsc/genomeCoverageBed.sh"
}

process sample_bedsort
{
    label 'coverage'

    input:
        tuple val(sampleName), path(bedgraph), path(genomeSizes)

    output:
        tuple val(sampleName), path(sortedBed), path(genomeSizes)

    shell:
        sortedBed = "${alignedFileName(sampleName)}.sorted.bed"
        template "bedtools/bedSort.sh"
}

process sample_bedgraphtobigwig
{
    label 'coverage'

    publishDir params.sampleBamDir, mode: "link", pattern: "*.bigwig"

    input:
        tuple val(sampleName), path(sortedBed), path(genomeSizes)

    output:
        tuple val(sampleName), path(bigwig)

    shell:
        bigwig = "${alignedFileName(sampleName)}.bigwig"
        template "ucsc/bedGraphToBigWig.sh"
}
