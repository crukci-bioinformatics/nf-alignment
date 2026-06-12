/*
 * Processes for running BWA-mem.
 */

nextflow.enable.types = true

/*
 * Align with BWAmem (single read or paired end).
 * Needs a list of one or two FASTQ files for alignment in each record.
 */
process bwaMem
{
    cpus 4
    memory { 16.GB * task.attempt }
    time 8.hour
    maxRetries 2

    input:
        record(basename: String, chunk: Integer, sequenceFiles: List<Path>, bwamem2IndexDir: Path, bwamem2IndexPrefix: String)

    output:
        record(basename: basename, chunk: chunk, bam: file("${basename}.bwamem.${chunk}.bam"))

    shell:
        outBam = "${basename}.bwamem.${chunk}.bam"
        template "bwa/bwamem.sh"
}
