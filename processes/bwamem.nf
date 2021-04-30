import nextflow.util.BlankSeparatedList

include { extractChunkNumber } from '../components/functions'

/*
 * BWAmem.
 */

process bwa_mem
{
    cpus 4
    memory { 8.GB * task.attempt }
    time 8.hour
    maxRetries 2

    input:
        tuple val(basename), file(sequenceFiles)

    output:
        tuple val(basename), val(chunk), path(outBam)

    shell:
        chunk = extractChunkNumber(sequenceFiles[0])

        outBam = "${basename}.bwamem.${chunk}.bam"
        template "bwa/bwamem.sh"
}
