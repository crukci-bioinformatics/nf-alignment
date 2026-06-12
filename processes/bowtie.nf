/*
 * Processes for running Bowtie 2.
 */

nextflow.enable.types = true

/*
 * Align with Bowtie 2 single end.
 */
process bowtieSE
{
    cpus 4
    memory { 8.GB * task.attempt }
    time 8.hour
    maxRetries 2

    input:
        record(basename: String, chunk: String, read1: Path, bowtie2IndexDir: Path, bowtie2IndexPrefix: String)

    output:
        record(basename: basename, chunk: chunk, bam: file("${basename}.bowtie.${chunk}.bam"))

    shell:
        outBam = "${basename}.bowtie.${chunk}.bam"
        template "bowtie/bowtiese.sh"
}

/*
 * Align with Bowtie 2 paired end.
 */
process bowtiePE
{
    cpus 4
    memory { 8.GB * task.attempt }
    time 8.hour
    maxRetries 2

    input:
        record(basename: String, chunk: String, read1: Path, read2: Path, bowtie2IndexDir: Path, bowtie2IndexPrefix: String)

    output:
        record(basename: basename, chunk: chunk, bam: file("${basename}.bowtie.${chunk}.bam"))

    shell:
        outBam = "${basename}.bowtie.${chunk}.bam"
        template "bowtie/bowtiepe.sh"
}
