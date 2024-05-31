/*
 * Processes for running BWA-mem.
 */

import nextflow.util.BlankSeparatedList

include { extractChunkNumber } from '../components/functions'

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
        tuple val(basename), path(sequenceFiles), path(bwamem2IndexDir), val(bwamem2IndexPrefix)

    output:
        tuple val(basename), val(chunk), path(outBam)

    shell:
        chunk = extractChunkNumber(sequenceFiles[0])

        outBam = "${basename}.bwamem.${chunk}.bam"
        template "bwa/bwamem.sh"
}
