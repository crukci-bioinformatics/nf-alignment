include { alignedFileName } from "../components/functions"

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
