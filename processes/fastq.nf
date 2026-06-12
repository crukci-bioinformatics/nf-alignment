/*
 * Generic FASTQ processes.
 */

nextflow.enable.types = true

/*
 * Split FASTQ file into chunks.
 */
process splitFastq
{
    memory '1GB'
    time { 12.hour + 1.hour * task.attempt }

    input:
        record(basename: String, read: Integer, fastqFile: Path)

    output:
        record(basename: basename, read: read, fastqFiles: files("*-S??????.fq.gz"))

    shell:
        template "fastq/splitFastq.sh"
}
