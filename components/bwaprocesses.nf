import nextflow.util.BlankSeparatedList

/*
 * Old style BWA.
 */

process bwa_aln
{
    label 'bwa'

    input:
        tuple val(basename), val(read), path(fastqFile)

    output:
        tuple val(basename), val(chunk), path(outSai), path(outFastq)

    shell:
        // "def" makes the matcher local scope, so it's not stored in the Nextflow context map
        // and stops the "Cannot serialize context map. Resume will not work on this process" messages.
        def m = fastqFile.name =~ /\.(\d+)\.fq(\.gz)?$/
        assert m : "Don't have file pattern with chunk numbers: '${fastqFile.name}'"
        chunk = m[0][1]

        outFastq = fastqFile.name
        outSai = "${basename}.r_${read}.${chunk}.sai"
        template "bwa/bwaaln.sh"
}

process bwa_samse
{
    label 'bwa'

    input:
        tuple val(basename), val(chunk), path(saiFile), path(fastqFile)

    output:
        tuple val(basename), val(chunk), path(outBam)

    shell:
        outBam = "${basename}.bwa.${chunk}.bam"
        template "bwa/bwasamse.sh"
}

process bwa_sampe
{
    label 'bwa'

    input:
        tuple val(basename), val(chunk),
              path(saiFile1), path(fastqFile1),
              path(saiFile2), path(fastqFile2)

    output:
        tuple val(basename), val(chunk), path(outBam)

    shell:
        // Lists need to explicitly be BlankSeparatedLists to render correctly
        // in the expansion of the sampe template. Regular lists add square brackets.

        saiFiles = new BlankSeparatedList(saiFile1, saiFile2)
        fastqFiles = new BlankSeparatedList(fastqFile1, fastqFile2)
        outBam = "${basename}.bwa.${chunk}.bam"
        template "bwa/bwasampe.sh"
}

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
        def m = sequenceFiles[0].name =~ /\.(\d+)\.fq(\.gz)?$/
        assert m : "Don't have file pattern with chunk numbers: '${sequenceFiles[0].name}'"
        chunk = m[0][1]

        outBam = "${basename}.bwamem.${chunk}.bam"
        template "bwa/bwamem.sh"
}
