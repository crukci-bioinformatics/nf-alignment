process STAR
{
    cpus 8
    memory { 64.GB * 2 ** (task.attempt - 1) }
    time { 6.hour * task.attempt }
    maxRetries 2

    input:
        tuple val(basename), file(sequenceFiles)

    output:
        tuple val(basename), val(0), path(outBam)

    shell:
        outBam = "${basename}/Aligned.out.bam"
        template "STAR.sh"
}
