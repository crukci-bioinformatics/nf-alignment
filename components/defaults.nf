/*
 * The following are a way of defaulting parameters. The params object is immutable
 * in code, so we need to test and resolve each time the value is asked for.
 */


/*
 * Function for determining whether single or paired end.
 */
def pairedEnd()
{
    switch (params.endType.toLowerCase()[0])
    {
        case 's':
            return false

        case 'p':
            return true

        default:
            throw new IllegalArgumentException("End type must be given to indicate single read (se/sr) or paired end (pe).")
    }
}

/*
 * Function for getting RNA-Seq strand specificity. When there is nothing
 * defined (the default), defaults to the appropriate value for single
 * or paired end. When explicitly defined, return that.
 */
def rnaseqStrandSpecificity()
{
    if (params.rnaseqStrandSpecificity == '')
    {
        return pairedEnd() ? 'SECOND_READ_TRANSCRIPTION_STRAND' : 'FIRST_READ_TRANSCRIPTION_STRAND'
    }
    return params.rnaseqStrandSpecificity.toUpperCase()
}


/*
 * Get the path to the reference FASTA file.
 */
def fastaReferencePath()
{
    if (params.containsKey('referenceFasta'))
    {
        return params.referenceFasta
    }

    params.with
    {
        return "${referenceRoot}/${species}/${assembly}/fasta/${shortSpecies}.${assembly}.fa"
    }
}

/*
 * Get the path to the genome sizes file.
 */
def genomeSizesPath()
{
    if (params.containsKey('genomeSizes'))
    {
        return params.genomeSizes
    }

    params.with
    {
        return "${referenceRoot}/${species}/${assembly}/fasta/${shortSpecies}.${assembly}.sizes"
    }
}

/*
 * Get the path to the genome sizes file.
 */
def referenceRefFlatPath()
{
    if (params.containsKey('referenceRefFlat'))
    {
        return params.referenceRefFlat
    }

    params.with
    {
        return "${referenceRoot}/${species}/${assembly}/annotation/${shortSpecies}.${assembly}.txt"
    }
}

/*
 * Get the path to the BWA index file.
 */
def bwaIndexPath()
{
    if (params.containsKey('bwaIndex'))
    {
        return params.bwaIndex
    }

    params.with
    {
        return "${referenceRoot}/${species}/${assembly}/bwa-${bwaVersion}/${shortSpecies}.${assembly}"
    }
}

/*
 * Get the path to the BWAmem2 index file.
 */
def bwamem2IndexPath()
{
    if (params.containsKey('bwamem2Index'))
    {
        return params.bwamem2Index
    }

    params.with
    {
        return "${referenceRoot}/${species}/${assembly}/bwamem2-${bwamem2Version}/${shortSpecies}.${assembly}"
    }
}

/*
 * Get the path to the STAR index directory.
 */
def starIndexPath()
{
    if (params.containsKey('starIndex'))
    {
        return params.starIndex
    }

    params.with
    {
        return "${referenceRoot}/${species}/${assembly}/star-${starVersion}"
    }
}
