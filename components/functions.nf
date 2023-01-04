/*
 * Miscellaneous helper functions used all over the pipeline.
 */

@Grab('org.apache.commons:commons-lang3:3.12.0')

import static org.apache.commons.lang3.CharUtils.isAsciiAlphanumeric

import java.text.*

/*
 * Get the base name from a file name, using the extract pattern and capture
 * group set in the parameters.
 */
def basenameExtractor(filename)
{
    def m = filename =~ params.basenameExtractPattern
    assert m.matches() : "Cannot extract base name from ${filename} using the pattern ${params.basenameExtractPattern}"
    m[0][params.basenameCaptureGroup]
}

/*
 * Standard function for the base of an aligned file. It is the base name
 * plus aligner and reference species.
 */
def alignedFileName(basename)
{
    "${basename}.${params.aligner}.${params.species}"
}

/*
 * Extract the chunk number from a file produced by splitFastq. It is the
 * six digits just before the .fq or .fq.gz suffix.
 */
def extractChunkNumber(f)
{
    def m = f.name =~ /.+-S(\d{6})\.fq(\.gz)?$/
    assert m : "Don't have file pattern with chunk numbers: '${f.name}'"
    return m[0][1]
}

/*
 * Make a name safe to be used as a file name. Everything that's not
 * alphanumeric, dot, underscore or hyphen is converted to an underscore.
 */
def safeName(name)
{
    def nameStr = name.toString()
    def safe = new StringBuilder(nameStr.length())
    def iter = new StringCharacterIterator(nameStr)

    for (def c = iter.first(); c != CharacterIterator.DONE; c = iter.next())
    {
        switch (c)
        {
            case { isAsciiAlphanumeric(it) }:
            case '_':
            case '-':
            case '.':
                safe << c
                break

            default:
                safe << '_'
                break
        }
    }

    return safe.toString()
}

/*
 * Get the size of a collection of things. It might be that the thing
 * passed in isn't a collection or map, in which case the size is 1.
 *
 * See https://github.com/nextflow-io/nextflow/issues/2425
 */
def sizeOf(thing)
{
    return (thing instanceof Collection || thing instanceof Map) ? thing.size() : 1
}

// ====================================================
// The following are a way of defaulting parameters. The params object is immutable
// in code, so we need to test and resolve each time the value is asked for.
// ====================================================

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
