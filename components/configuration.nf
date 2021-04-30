import java.nio.file.Files

def checkParameters(params)
{
    def errors = false
    def referenceRootWarned = false
    def referenceRootWarning = 'Reference data root directory not set. Use --referenceRoot with path to the top of the reference structure.'

    params.with
    {
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
