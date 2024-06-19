/*
 * Processes for running BWA-mem.
 */

/*
 * Align with BWAmem (single read or paired end).
 * Needs a list of one or two FASTQ files for alignment in each tuple.
 */
process bwa_mem
{
    cpus 4
    memory { 16.GB * task.attempt }
    time 8.hour
    maxRetries 2

    input:
        tuple val(basename), val(chunk), path(sequenceFiles), path(bwamem2IndexDir), val(bwamem2IndexPrefix)

    output:
        tuple val(basename), val(chunk), path(outBam)

    shell:
        outBam = "${basename}.bwamem.${chunk}.bam"
        template "bwa/bwamem.sh"
}
