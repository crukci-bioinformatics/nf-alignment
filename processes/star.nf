/*
 * Processes for running STAR.
 */

/*
 * Align with STAR (single read or paired end).
 */
process STAR
{
    cpus 8
    memory { 64.GB * 2 ** (task.attempt - 1) }
    time { 6.hour * task.attempt }
    maxRetries 2

    input:
        tuple val(basename), val(chunk), path(sequenceFiles), path(starIndex)

    output:
        tuple val(basename), val(chunk), path(outBam)

    shell:
        outBam = "${basename}/Aligned.out.bam"
        template "STAR.sh"
}
