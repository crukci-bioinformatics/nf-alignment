import nextflow.util.BlankSeparatedList
import org.apache.commons.csv.CSVFormat
import org.apache.commons.csv.CSVParser

/**
 * Utilities for the alignment pipeline.
 *
 * <p>
 * Java/Groovy imports are not permitted in strict-parser Nextflow scripts,
 * so the Apache Commons CSV logic that validates the alignment.csv file lives
 * here and is called as a static method from configuration.nf.
 * </p>
 */
class APUtils
{
    /**
     * Check the parameters are set and valid.
     * 
     * @param params The Nextflow parameters.
     * @param log The Nextflow logger.
     * 
     * @return True if all is well and the pipeline can run, false otherwise.
     */
    static boolean checkParameters(params, log)
    {
        log.info("params is a ${params.class.name}")
        log.info("log is a ${log.class.name}")
        
        boolean errors = false
        boolean referenceRootWarned = false
        String referenceRootWarning = 'Reference data root directory not set. Use --referenceRoot with path to the top of the reference structure.'
    
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
                    if (!containsKey('bwaIndex') && !containsKey('referenceRoot'))
                    {
                        if (!referenceRootWarned)
                        {
                            log.error referenceRootWarning
                            referenceRootWarned = true
                        }
                        errors = true
                    }
                    break
    
                case 'bwamem':
                case 'bwa_mem':
                case 'bwamem2':
                case 'bwa_mem2':
                    if (!containsKey('bwamem2Index') && !containsKey('referenceRoot'))
                    {
                        if (!referenceRootWarned)
                        {
                            log.error referenceRootWarning
                            referenceRootWarned = true
                        }
                        errors = true
                    }
                    break
    
                case 'bowtie':
                case 'bowtie2':
                    if (!containsKey('bowtie2Index') && !containsKey('referenceRoot'))
                    {
                        if (!referenceRootWarned)
                        {
                            log.error referenceRootWarning
                            referenceRootWarned = true
                        }
                        errors = true
                    }
                    break
    
                case 'star':
                    if (!containsKey('starIndex') && !containsKey('referenceRoot'))
                    {
                        if (!referenceRootWarned)
                        {
                            log.error referenceRootWarning
                            referenceRootWarned = true
                        }
                        errors = true
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
            APDefaults.pairedEnd(params)
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
        switch (params.aligner)
        {
            case 'bwa':
                if (!file("${bwaIndexPath()}.pac").exists())
                {
                    log.error "BWA index files '${bwaIndexPath()}' do not exist."
                    errors = true
                }
                break
    
            case 'bwamem':
            case 'bwa_mem':
            case 'bwamem2':
            case 'bwa_mem2':
                if (!file("${bwamem2IndexPath()}.pac").exists())
                {
                    log.error "BWAmem index files '${bwamem2IndexPath()}' do not exist."
                    errors = true
                }
                break
    
            case 'bowtie':
            case 'bowtie2':
                if (!file("${bowtie2IndexPath()}.1.bt2").exists() &&
                    !file("${bowtie2IndexPath()}.1.bt2l").exists())
                {
                    log.error "Bowtie index files '${bowtie2IndexPath()}*' do not exist."
                    errors = true
                }
                break
    
            case 'star':
                if (!file(starIndexPath()).isDirectory())
                {
                    log.error "STAR genome directory '${starIndexPath()}' does not exist."
                    errors = true
                }
                break
        }
    
        return !errors
    }
    
    /**
     * Write a log message summarising how the pipeline is configured and the
     * locations of reference files that will be used.
     * 
     * @param params The Nextflow parameters.
     * @param log The Nextflow logger.
     */
    static void displayParameters(params)
    {
        boolean pairedEnd = APDefaults.pairedEnd(params)
        
        log.info "${pairedEnd ? 'Paired end' : 'Single read'} alignment against ${params.species} ${params.assembly} using ${params.aligner.toUpperCase()}."
        log.info "FASTQ directory: ${params.fastqDir}"
        log.info "FASTA file: ${APDefaults.fastaReferencePath(params)}"
        if (params.createCoverage)
        {
            log.info "Genome sizes: ${APDefaults.genomeSizesPath(params)}"
        }
        if (params.rnaseqMetrics)
        {
            log.info "Reference annotations (refflat): ${APDefaults.referenceRefFlatPath(params)}"
            log.info "Strand specificity: ${APDefaults.rnaseqStrandSpecificity(params)}"
        }
        switch (params.aligner.toLowerCase())
        {
            case 'bwa':
                log.info "BWA index: ${APDefaults.bwaIndexPath(params)}*"
                break
    
            case 'bwamem':
            case 'bwa_mem':
            case 'bwamem2':
            case 'bwa_mem2':
                log.info "BWAmem2 index: ${APDefaults.bwamem2IndexPath(params)}*"
                break
    
            case 'bowtie':
            case 'bowtie2':
                log.info "Bowtie2 index: ${APDefaults.bowtie2IndexPath(params)}*"
                break
    
            case 'star':
                log.info "STAR index: ${APDefaults.starIndexPath(params)}"
                break
        }
    }
    
    /**
     * Check the alignment CSV file has the necessary minimum columns to run
     * in the configured mode and that each line in the file has those mandatory
     * values set.
     * 
     * @param params The Nextflow parameters.
     * @param log The Nextflow logger.
     * 
     * @return True if all is well and the pipeline can run, false otherwise.
     */
    static boolean checkAlignmentCSV(params, log)
    {
        boolean ok = true
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

    /**
     * Create a {@link BlankSeparatedList} from the given items.
     *
     * <p>Used in BWA shell templates where file lists must be rendered as
     * space-separated strings without the square brackets that a regular
     * Groovy list would produce.</p>
     *
     * @param items The items to collect into a blank-separated list.
     * @return A {@code BlankSeparatedList} wrapping the given items.
     */
    static BlankSeparatedList blankSepList(Object... items)
    {
        return new BlankSeparatedList(items)
    }
}
