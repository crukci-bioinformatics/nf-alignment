/*
 * Processes for running Bowtie 2.
 */

import nextflow.util.BlankSeparatedList


/*
 * Align with Bowtie 2 single end.
 */
process bowtie_se
{
    cpus 4
    memory { 8.GB * task.attempt }
    time 8.hour
    maxRetries 2

    input:
        tuple val(basename), val(chunk), path(read1), path(bowtie2IndexDir), val(bowtie2IndexPrefix)

    output:
        tuple val(basename), val(chunk), path(outBam)

    shell:
        outBam = "${basename}.bowtie.${chunk}.bam"
        template "bowtie/bowtiese.sh"
}

/*
 * Align with Bowtie 2 paired end.
 */
process bowtie_pe
{
    cpus 4
    memory { 8.GB * task.attempt }
    time 8.hour
    maxRetries 2

    input:
        tuple val(basename), val(chunk), path(read1), path(read2), path(bowtie2IndexDir), val(bowtie2IndexPrefix)

    output:
        tuple val(basename), val(chunk), path(outBam)

    shell:
        outBam = "${basename}.bowtie.${chunk}.bam"
        template "bowtie/bowtiepe.sh"
}
