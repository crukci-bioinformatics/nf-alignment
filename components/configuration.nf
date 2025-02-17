/*
 * Functions used in checking the configuration of the pipeline before it starts.
 */

import java.nio.file.Files
import org.apache.commons.csv.*

include { logException } from '../modules/nextflow-support/debugging'

include {
    fastaReferencePath; genomeSizesPath; referenceRefFlatPath;
    bwaIndexPath; bwamem2IndexPath; bowtie2IndexPath; starIndexPath;
    pairedEnd; rnaseqStrandSpecificity
} from "./defaults"

/*
 * Check the parameters are set and valid.
 */
def checkParameters(params)
{
    def errors = false
    def referenceRootWarned = false
    def referenceRootWarning = 'Reference data root directory not set. Use --referenceRoot with path to the top of the reference structure.'

    params.with
    {
        // Basic settings

        if (!containsKey('aligner'))
        {
            log.error "Aligner not specified. Use --aligner with one of 'bwa', 'bwamem', 'bowtie', 'star'."
            errors = true
        }
        if (!containsKey('endType'))
        {
            log.error "Sequencing method not set. Use --endType with 'se' (single read) or 'pe' (paired end)."
            errors = true
        }
        if (!containsKey('species'))
        {
            log.error 'Species folder not set. Use --species and give the species name with underscores in place of spaces, eg. "homo_sapiens".'
            errors = true
        }
        if (!containsKey('shortSpecies'))
        {
            log.error 'Species abbreviation not set. Use --shortSpecies with the abbreviation, eg. "hsa", "mmu".'
            errors = true
        }
        if (!containsKey('assembly'))
        {
            log.error 'Genome assembly not set. Use --assembly with the genome version, eg. "GRCh38".'
            errors = true
        }

        if (errors)
        {
            log.warn "Missing arguments can also be added to nextflow.config instead of being supplied on the command line."
            return false
        }

        switch (aligner.toLowerCase())
        {
            case 'bwa':
                if (!containsKey('bwaIndex'))
                {
                    if (!containsKey('referenceRoot'))
                    {
                        if (!referenceRootWarned)
                        {
                            log.error referenceRootWarning
                            referenceRootWarned = true
                        }
                        errors = true
                    }
                }
                break

            case 'bwamem':
            case 'bwa_mem':
            case 'bwamem2':
            case 'bwa_mem2':
                if (!containsKey('bwamem2Index'))
                {
                    if (!containsKey('referenceRoot'))
                    {
                        if (!referenceRootWarned)
                        {
                            log.error referenceRootWarning
                            referenceRootWarned = true
                        }
                        errors = true
                    }
                }
                break

            case 'bowtie':
            case 'bowtie2':
                if (!containsKey('bowtie2Index'))
                {
                    if (!containsKey('referenceRoot'))
                    {
                        if (!referenceRootWarned)
                        {
                            log.error referenceRootWarning
                            referenceRootWarned = true
                        }
                        errors = true
                    }
                }
                break

            case 'star':
                if (!containsKey('starIndex'))
                {
                    if (!containsKey('referenceRoot'))
                    {
                        if (!referenceRootWarned)
                        {
                            log.error referenceRootWarning
                            referenceRootWarned = true
                        }
                        errors = true
                    }
                }
                break

            default:
                log.error "Aligner must be one of 'bwa', 'bwamem' or 'star'."
                errors = true
                break
        }
    }

    // Decipher single read or paired end and check the aligner is supported.

    try
    {
        pairedEnd()
    }
    catch (IllegalArgumentException e)
    {
        log.error e.message
        errors = true
    }

    params.with
    {
        // Check if reference files and directories are set. If not, default to our
        // standard structure.

        if (!containsKey('referenceFasta'))
        {
            if (!containsKey('referenceRoot'))
            {
                if (!referenceRootWarned)
                {
                    log.error referenceRootWarning
                    referenceRootWarned = true
                }
                errors = true
            }
        }

        if (createCoverage && !containsKey('genomeSizes'))
        {
            if (!containsKey('referenceRoot'))
            {
                if (!referenceRootWarned)
                {
                    log.error referenceRootWarning
                    referenceRootWarned = true
                }
                errors = true
            }
        }

        if (rnaseqMetrics)
        {
            if (!containsKey('referenceRefFlat'))
            {
                if (!containsKey('referenceRoot'))
                {
                    if (!referenceRootWarned)
                    {
                        log.error referenceRootWarning
                        referenceRootWarned = true
                    }
                    errors = true
                }
            }

            switch (rnaseqStrandSpecificity.toUpperCase())
            {
                // When none explicitly set, a default according to paired end or single read is supplied.
                // Otherwise these are acceptable values.
                case '':
                case 'NONE':
                case 'FIRST_READ_TRANSCRIPTION_STRAND':
                case 'SECOND_READ_TRANSCRIPTION_STRAND':
                    break

                default:
                    log.error "RNA Seq strand specificity invalid [rnaseqStrandSpecificity]. " +
                              "Must be one of NONE, FIRST_READ_TRANSCRIPTION_STRAND, SECOND_READ_TRANSCRIPTION_STRAND"
                    errors = true
            }
        }
    }

    if (errors)
    {
        return false
    }

    // Make sure required reference files are available.

    if (!Files.exists(file(fastaReferencePath())))
    {
        log.error "FASTQ reference file '${fastaReferencePath()}' does not exist."
        errors = true
    }
    if (params.createCoverage && !Files.exists(file(genomeSizesPath())))
    {
        log.error "Genome sizes file '${genomeSizesPath()}' does not exist."
        errors = true
    }
    if (params.rnaseqMetrics && !Files.exists(file(referenceRefFlatPath())))
    {
        log.error "Reference annotation refflat file '${referenceRefFlatPath()}' does not exist."
        errors = true
    }
    switch (params.aligner)
    {
        case 'bwa':
            if (!Files.exists(file("${bwaIndexPath()}.pac")))
            {
                log.error "BWA index files '${bwaIndexPath()}' do not exist."
                errors = true
            }
            break

        case 'bwamem':
        case 'bwa_mem':
        case 'bwamem2':
        case 'bwa_mem2':
            if (!Files.exists(file("${bwamem2IndexPath()}.pac")))
            {
                log.error "BWAmem index files '${bwamem2IndexPath()}' do not exist."
                errors = true
            }
            break

        case 'bowtie':
        case 'bowtie2':
            if (!Files.exists(file("${bowtie2IndexPath()}.1.bt2")) &&
                !Files.exists(file("${bowtie2IndexPath()}.1.bt2l")))
            {
                log.error "Bowtie index files '${bowtie2IndexPath()}*' do not exist."
                errors = true
            }
            break

        case 'star':
            if (!Files.isDirectory(file(starIndexPath())))
            {
                log.error "STAR genome directory '${starIndexPath()}' does not exist."
                errors = true
            }
            break
    }

    return !errors
}

/*
 * Write a log message summarising how the pipeline is configured and the
 * locations of reference files that will be used.
 */
def displayParameters()
{
    log.info "${pairedEnd() ? 'Paired end' : 'Single read'} alignment against ${params.species} ${params.assembly} using ${params.aligner.toUpperCase()}."
    log.info "FASTQ directory: ${params.fastqDir}"
    log.info "FASTA file: ${fastaReferencePath()}"
    if (params.createCoverage)
    {
        log.info "Genome sizes: ${genomeSizesPath()}"
    }
    if (params.rnaseqMetrics)
    {
        log.info "Reference annotations (refflat): ${referenceRefFlatPath()}"
        log.info "Strand specificity: ${rnaseqStrandSpecificity()}"
    }
    switch (params.aligner.toLowerCase())
    {
        case 'bwa':
            log.info "BWA index: ${bwaIndexPath()}*"
            break

        case 'bwamem':
        case 'bwa_mem':
        case 'bwamem2':
        case 'bwa_mem2':
            log.info "BWAmem2 index: ${bwamem2IndexPath()}*"
            break

        case 'bowtie':
        case 'bowtie2':
            log.info "Bowtie2 index: ${bowtie2IndexPath()}*"
            break

        case 'star':
            log.info "STAR index: ${starIndexPath()}"
            break
    }
}

/*
 * Check the alignment CSV file has the necessary minimum columns to run
 * in the configured mode and that each line in the file has those mandatory
 * values set.
 */
def checkAlignmentCSV()
{
    def ok = true
    try
    {
        def driverFile = file(params.alignmentCSV)
        driverFile.withReader('UTF-8')
        {
            stream ->
            def parser = CSVParser.parse(stream, CSVFormat.DEFAULT.withHeader())
            def first = true

            for (record in parser)
            {
                if (first)
                {
                    if (!record.isMapped('Read1'))
                    {
                        log.error "${params.alignmentCSV} must contain a column 'Read1'."
                        ok = false
                    }
                    if (pairedEnd() && !record.isMapped('Read2'))
                    {
                        log.error "${params.alignmentCSV} must contain a column 'Read2' for aligning paired end."
                        ok = false
                    }
                    if (params.mergeSamples && !record.isMapped('SampleName'))
                    {
                        log.error "${params.alignmentCSV} must contain a column 'SampleName' when sample merging is requested."
                        ok = false
                    }
                    first = false
                    if (!ok)
                    {
                        break
                    }
                }

                def rowNum = parser.recordNumber + 1
                if (!record.get('Read1'))
                {
                    log.error "No 'Read1' file name set on line ${rowNum}."
                    ok = false
                }
                if (pairedEnd() && !record.get('Read2'))
                {
                    log.error "No 'Read2' file name set on line ${rowNum}."
                    ok = false
                }
                if (params.mergeSamples && !record.get('SampleName'))
                {
                    log.error "No 'SampleName' defined on line ${rowNum}."
                    ok = false
                }
            }
        }
    }
    catch (Exception e)
    {
        logException(e)
        ok = false
    }

    return ok
}
