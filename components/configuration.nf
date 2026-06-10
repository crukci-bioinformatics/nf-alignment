/*
 * Functions used in checking the configuration of the pipeline before it starts.
 *
 * Java/Groovy imports are not permitted in strict-parser Nextflow scripts.
 * Code that requires third-party classes (Apache Commons CSV, java.nio.file.Files)
 * lives in lib/APUtils.groovy and is called as static methods below.
 */

include { logException } from "plugin/nf-crukci-support"

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

        def alignerLc = aligner.toLowerCase()

        if (alignerLc == 'bwa')
        {
            if (!containsKey('bwaIndex') && !containsKey('referenceRoot'))
            {
                if (!referenceRootWarned)
                {
                    log.error referenceRootWarning
                    referenceRootWarned = true
                }
                errors = true
            }
        }
        else if (alignerLc in ['bwamem', 'bwa_mem', 'bwamem2', 'bwa_mem2'])
        {
            if (!containsKey('bwamem2Index') && !containsKey('referenceRoot'))
            {
                if (!referenceRootWarned)
                {
                    log.error referenceRootWarning
                    referenceRootWarned = true
                }
                errors = true
            }
        }
        else if (alignerLc in ['bowtie', 'bowtie2'])
        {
            if (!containsKey('bowtie2Index') && !containsKey('referenceRoot'))
            {
                if (!referenceRootWarned)
                {
                    log.error referenceRootWarning
                    referenceRootWarned = true
                }
                errors = true
            }
        }
        else if (alignerLc == 'star')
        {
            if (!containsKey('starIndex') && !containsKey('referenceRoot'))
            {
                if (!referenceRootWarned)
                {
                    log.error referenceRootWarning
                    referenceRootWarned = true
                }
                errors = true
            }
        }
        else
        {
            log.error "Aligner must be one of 'bwa', 'bwamem', 'bowtie' or 'star'."
            errors = true
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

        if (!containsKey('referenceFasta') && !containsKey('referenceRoot'))
        {
            if (!referenceRootWarned)
            {
                log.error referenceRootWarning
                referenceRootWarned = true
            }
            errors = true
        }

        if (createCoverage && !containsKey('genomeSizes') && !containsKey('referenceRoot'))
        {
            if (!referenceRootWarned)
            {
                log.error referenceRootWarning
                referenceRootWarned = true
            }
            errors = true
        }

        if (rnaseqMetrics)
        {
            if (!containsKey('referenceRefFlat') && !containsKey('referenceRoot'))
            {
                if (!referenceRootWarned)
                {
                    log.error referenceRootWarning
                    referenceRootWarned = true
                }
                errors = true
            }

            def validStrand = [ 'NONE', 'FIRST_READ_TRANSCRIPTION_STRAND', 'SECOND_READ_TRANSCRIPTION_STRAND' ]
            def validStrandValues = [ '', validStrand ].flatten()
            if (!validStrandValues.contains(rnaseqStrandSpecificity.toUpperCase()))
            {
                log.error "RNA Seq strand specificity invalid [rnaseqStrandSpecificity]. Must be one of ${validStrand.join(', ')}."
                errors = true
            }
        }
    }

    if (errors)
    {
        return false
    }

    // Make sure required reference files are available.

    if (!file(fastaReferencePath()).exists())
    {
        log.error "FASTQ reference file '${fastaReferencePath()}' does not exist."
        errors = true
    }
    if (params.createCoverage && !file(genomeSizesPath()).exists())
    {
        log.error "Genome sizes file '${genomeSizesPath()}' does not exist."
        errors = true
    }
    if (params.rnaseqMetrics && !file(referenceRefFlatPath()).exists())
    {
        log.error "Reference annotation refflat file '${referenceRefFlatPath()}' does not exist."
        errors = true
    }

    def alignerLc = params.aligner.toLowerCase()

    if (alignerLc == 'bwa')
    {
        if (!file("${bwaIndexPath()}.pac").exists())
        {
            log.error "BWA index files '${bwaIndexPath()}' do not exist."
            errors = true
        }
    }
    else if (alignerLc in ['bwamem', 'bwa_mem', 'bwamem2', 'bwa_mem2'])
    {
        if (!file("${bwamem2IndexPath()}.pac").exists())
        {
            log.error "BWAmem index files '${bwamem2IndexPath()}' do not exist."
            errors = true
        }
    }
    else if (alignerLc in ['bowtie', 'bowtie2'])
    {
        if (!file("${bowtie2IndexPath()}.1.bt2").exists() &&
            !file("${bowtie2IndexPath()}.1.bt2l").exists())
        {
            log.error "Bowtie index files '${bowtie2IndexPath()}*' do not exist."
            errors = true
        }
    }
    else if (alignerLc == 'star')
    {
        if (!file(starIndexPath()).isDirectory())
        {
            log.error "STAR genome directory '${starIndexPath()}' does not exist."
            errors = true
        }
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

    def alignerLc = params.aligner.toLowerCase()

    if (alignerLc == 'bwa')
    {
        log.info "BWA index: ${bwaIndexPath()}*"
    }
    else if (alignerLc in ['bwamem', 'bwa_mem', 'bwamem2', 'bwa_mem2'])
    {
        log.info "BWAmem2 index: ${bwamem2IndexPath()}*"
    }
    else if (alignerLc in ['bowtie', 'bowtie2'])
    {
        log.info "Bowtie2 index: ${bowtie2IndexPath()}*"
    }
    else if (alignerLc == 'star')
    {
        log.info "STAR index: ${starIndexPath()}"
    }
}

/*
 * Check the alignment CSV file has the necessary minimum columns to run
 * in the configured mode and that each line in the file has those mandatory
 * values set.
 *
 * CSV parsing (Apache Commons CSV) requires Java imports that are not permitted
 * in strict-parser NF scripts; the logic is delegated to lib/CsvUtils.groovy.
 */
def checkAlignmentCSV()
{
    try
    {
        return APUtils.checkAlignmentCSV(params, pairedEnd(), log)
    }
    catch (Exception e)
    {
        logException(e)
        return false
    }
}
