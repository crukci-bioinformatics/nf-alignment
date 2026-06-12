/*
 * Processes for running STAR.
 */

nextflow.enable.types = true

/*
 * Align with STAR (single read or paired end).
 * Needs a list of one or two FASTQ files for alignment in each record.
 */
process STAR
{
    cpus 8
    memory { 64.GB * 2 ** (task.attempt - 1) }
    time { 6.hour * task.attempt }
    maxRetries 2

    input:
        record(basename: String, chunk: String, sequenceFiles: List<Path>, starIndex: Path)

    output:
        record(basename: basename, chunk: chunk, bam: file("${basename}/Aligned.out.bam"))

    shell:
        outBam = "${basename}/Aligned.out.bam"
        template "STAR.sh"
}
