import nextflow.util.BlankSeparatedList

include { extractChunkNumber } from '../components/functions'

/*
 * Classic BWA.
 */

process bwa_aln
{
    label 'bwa'

    input:
        tuple val(basename), val(read), path(fastqFile), path(bwaIndexDir), val(bwaIndexPrefix)

    output:
        tuple val(basename), val(chunk), path(outSai), path(outFastq)

    shell:
        chunk = extractChunkNumber(fastqFile)

        outFastq = fastqFile.name
        outSai = "${basename}.r_${read}.${chunk}.sai"
        template "bwa/bwaaln.sh"
}

process bwa_samse
{
    label 'bwa'
    cpus 2

    input:
        tuple val(basename), val(chunk), path(saiFile), path(fastqFile), path(bwaIndexDir), val(bwaIndexPrefix)

    output:
        tuple val(basename), val(chunk), path(outBam)

    shell:
        outBam = "${basename}.bwa.${chunk}.bam"
        template "bwa/bwasamse.sh"
}

process bwa_sampe
{
    label 'bwa'
    cpus 2

    input:
        tuple val(basename), val(chunk),
              path(saiFile1), path(fastqFile1),
              path(saiFile2), path(fastqFile2),
              path(bwaIndexDir), val(bwaIndexPrefix)

    output:
        tuple val(basename), val(chunk), path(outBam)

    shell:
        // Lists need to explicitly be BlankSeparatedLists to render correctly
        // in the expansion of the sampe template. Regular lists add square brackets.

        saiFiles = new BlankSeparatedList(saiFile1, saiFile2)
        fastqFiles = new BlankSeparatedList(fastqFile1, fastqFile2)
        outBam = "${basename}.bwa.${chunk}.bam"
        template "bwa/bwasampe.sh"
}
