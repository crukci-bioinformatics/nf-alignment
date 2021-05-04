/*
 * Functions used in checking the configuration of the pipeline before it starts.
 */

@Grab('org.apache.commons:commons-csv:1.8')
import java.nio.file.Files
import org.apache.commons.csv.*

include { logException } from './debugging'

/*
 * Check the parameters from alignment.config and the command line are
 * set and valid.
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
            log.error "Aligner not specified. Use --aligner with one of 'bwa', 'bwamem', 'star'."
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
            log.warn "Missing arguments can also be added to alignment.config instead of being supplied on the command line."
            return false
        }

        aligner = aligner.toLowerCase()
        assemblyPrefix = "${shortSpecies}.${assembly}"

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
            else
            {
                referenceFasta = "${referenceRoot}/${species}/${assembly}/fasta/${assemblyPrefix}.fa"
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
            else
            {
                genomeSizes = "${referenceRoot}/${species}/${assembly}/fasta/${assemblyPrefix}.sizes"
            }
        }

        if (rnaseqMetrics && !containsKey('referenceRefFlat'))
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
            else
            {
                referenceRefFlat = "${referenceRoot}/${species}/${assembly}/annotation/${assemblyPrefix}.txt"
            }
        }

        // Decipher single read or paired end and check the aligner is supported.

        switch (endType.toLowerCase()[0])
        {
            case 's':
                pairedEnd = false
                break

            case 'p':
                pairedEnd = true
                break

            default:
                log.error "End type must be given to indicate single read (se/sr) or paired end (pe)."
                errors = true
                break
        }

        switch (aligner)
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
                    else
                    {
                        bwaIndex = "${referenceRoot}/${species}/${assembly}/bwa-${bwaVersion}/${assemblyPrefix}"
                    }
                }
                break

            case 'bwamem':
            case 'bwa_mem':
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
                    else
                    {
                        bwamem2Index = "${referenceRoot}/${species}/${assembly}/bwamem2-${bwamem2Version}/${assemblyPrefix}"
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
                    else
                    {
                        starIndex = "${referenceRoot}/${species}/${assembly}/star-${starVersion}"
                    }
                }
                break

            default:
                log.error "Aligner must be one of 'bwa', 'bwamem' or 'star'."
                errors = true
                break
        }

        if (errors)
        {
            return false
        }

        // Make sure required reference files are available.

        if (!Files.exists(file(referenceFasta)))
        {
            log.error "FASTQ reference file '${referenceFasta}' does not exist."
            errors = true
        }
        if (createCoverage && !Files.exists(file(genomeSizes)))
        {
            log.error "Genome sizes file '${genomeSizes}' does not exist."
            errors = true
        }
        if (rnaseqMetrics && !Files.exists(file(referenceRefFlat)))
        {
            log.error "Reference annotation refflat file '${referenceRefFlat}' does not exist."
            errors = true
        }
        switch (aligner)
        {
            case 'bwa':
                if (!Files.exists(file("${bwaIndex}.pac")))
                {
                    log.error "BWA index files '${referenceFasta}' do not exist."
                    errors = true
                }
                break

            case 'bwamem':
            case 'bwa_mem':
                if (!Files.exists(file("${bwamem2Index}.pac")))
                {
                    log.error "BWAmem index files '${bwamem2Index}' do not exist."
                    errors = true
                }
                break

            case 'star':
                if (!Files.isDirectory(file(starIndex)))
                {
                    log.error "STAR genome directory '${starIndex}' does not exist."
                    errors = true
                }
                break
        }
    }

    return !errors
}

/*
 * Write a log message summarising how the pipeline is configured and the
 * locations of reference files that will be used.
 */
def displayParameters(params)
{
    params.with
    {
        log.info "${pairedEnd ? 'Paired end' : 'Single read'} alignment against ${species} ${assembly} using ${aligner.toUpperCase()}."
        log.info "FASTQ file: ${referenceFasta}"
        if (createCoverage)
        {
            log.info "Genome sizes: ${genomeSizes}"
        }
        if (rnaseqMetrics)
        {
            log.info "Reference annotations (refflat): ${referenceRefFlat}"
        }
        switch (aligner)
        {
            case 'bwa':
                log.info "BWA index: ${bwaIndex}"
                break

            case 'bwamem':
            case 'bwa_mem':
                log.info "BWAmem index: ${bwamem2Index}"
                break

            case 'star':
                log.info "STAR index: ${starIndex}"
                break
        }
    }
}

/*
 * Check the alignment CSV file has the necessary minimum columns to run
 * in the configured mode and that each line in the file has those mandatory
 * values set.
 */
def checkAlignmentCSV(params)
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
                    if (params.pairedEnd && !record.isMapped('Read2'))
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
                if (params.pairedEnd && !record.get('Read2'))
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
