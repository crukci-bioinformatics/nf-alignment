import java.nio.file.Files

def checkParameters(params)
{
    def errors = false

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
        if (!containsKey('referenceRoot'))
        {
            log.error 'Reference data root directory not set. Use --referenceRoot with path to the top of the reference structure.'
            errors = true
        }

        if (errors)
        {
            log.warn "Missing arguments can also be added to alignment.config instead of being supplied on the command line."
        }
        else
        {
            // The reference paths are as they exist inside the container. These need to be set
            // here as they're only usable if all necessary parameters are valid.

            assemblyPrefix = "${shortSpecies}.${assembly}"
            referenceFasta = "/reference_data/${species}/${assembly}/fasta/${assemblyPrefix}.fa"
            genomeSizes = "/reference_data/${species}/${assembly}/fasta/${assemblyPrefix}.sizes"
            bwaIndex = "/reference_data/${species}/${assembly}/bwa-${bwaVersion}/${assemblyPrefix}"
            bwamem2Index = "/reference_data/${species}/${assembly}/bwamem2-${bwamem2Version}/${assemblyPrefix}"
            starIndex = "/reference_data/${species}/${assembly}/star-${starVersion}"

            aligner = aligner.toLowerCase()

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
                case 'bwamem':
                case 'bwa_mem':
                case 'star':
                    break

                default:
                    log.error "Aligner must be one of 'bwa', 'bwamem' or 'star'."
                    errors = true
                    break
            }

            def refRootFile = file(referenceRoot)
            if (!Files.isDirectory(refRootFile))
            {
                log.error "Reference data root directory '${refRootFile}' does not exist."
                errors = true
            }
        }

        if (!errors)
        {
            log.info "${pairedEnd ? 'Paired end' : 'Single read'} alignment against ${species} ${assembly} using ${aligner.toUpperCase()}."
        }
    }

    return !errors
}

def basenameExtractor(filename)
{
    def m = filename =~ params.basenameExtractPattern
    assert m.matches() : "Cannot extract base name from ${filename} using the pattern ${params.basenameExtractPattern}"
    m[0][params.basenameCaptureGroup]
}

def alignedFileName(basename)
{
    "${basename}.${params.aligner}.${params.species}"
}

def extractChunkNumber(f)
{
    def m = f.name =~ /.+-S(\d{6})\.fq(\.gz)?$/
    assert m : "Don't have file pattern with chunk numbers: '${f.name}'"
    return m[0][1]
}
