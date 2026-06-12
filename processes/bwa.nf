/*
 * Processes for running classic BWA.
 *
 * BlankSeparatedList is accessed via APUtils.blankSepList() in lib/APUtils.groovy
 * because import declarations are not permitted in strict-parser Nextflow scripts.
 */

nextflow.enable.types = true

include { extractChunkNumber } from '../components/functions'

/*
 * Align a single fastq file.
 */
process bwaAln
{
    label 'bwa'

    input:
        record(basename: String, read: Integer, fastqFile: Path, bwaIndexDir: Path, bwaIndexPrefix: String)

    output:
        record(basename: basename, chunk: chunk,
               saiFile: file("${basename}.r_${read}.${chunk}.sai"),
               fastqFile: file(outFastq))

    shell:
        chunk = extractChunkNumber(fastqFile)
        outFastq = fastqFile.name
        outSai = "${basename}.r_${read}.${chunk}.sai"
        template "bwa/bwaaln.sh"
}

/*
 * Create BAM file for a BWA SAI file and its corresponding fastq file.
 */
process bwaSamSE
{
    label 'bwa'
    cpus 2

    input:
        record(basename: String, chunk: String, saiFile: Path, fastqFile: Path, bwaIndexDir: Path, bwaIndexPrefix: String)

    output:
        record(basename: basename, chunk: chunk, bam: file("${basename}.bwa.${chunk}.bam"))

    shell:
        outBam = "${basename}.bwa.${chunk}.bam"
        template "bwa/bwasamse.sh"
}

/*
 * Create BAM file for a two pairs of BWA SAI file the corresponding fastq file.
 */
process bwaSamPE
{
    label 'bwa'
    cpus 2

    input:
        record(basename: String, chunk: String,
               saiFile1: Path, fastqFile1: Path,
               saiFile2: Path, fastqFile2: Path,
               bwaIndexDir: Path, bwaIndexPrefix: String)

    output:
        record(basename: basename, chunk: chunk, bam: file("${basename}.bwa.${chunk}.bam"))

    shell:
        saiFiles = [ saiFile1, saiFile2 ]
        fastqFiles = [ fastqFile1, fastqFile2 ]
        outBam = "${basename}.bwa.${chunk}.bam"
        template "bwa/bwasampe.sh"
}
