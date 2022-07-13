/*
 * Generic FASTQ processes.
 */

/*
 * Split FASTQ file into chunks.
 */
process split_fastq
{
    cpus 1
    memory '8MB'
    time { 12.hour + 1.hour * task.attempt }

    input:
        tuple val(basename), val(read), path(fastqFile)

    output:
        tuple val(basename), val(read), path("*-S??????.fq.gz")

    shell:
        template "fastq/split_fastq.sh"
}
