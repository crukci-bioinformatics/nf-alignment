/*
 * Miscellaneous helper functions used all over the pipeline.
 */

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
 * Function for getting RNA-Seq strand specificity. When there is nothing
 * defined (the default), defaults to the appropriate value for single
 * or paired end. When explicitly defined, return that.
 */
def rnaseqStrandSpecificity(params)
{
    if (params.rnaseqStrandSpecificity == '')
    {
        return params.pairedEnd ? 'SECOND_READ_TRANSCRIPTION_STRAND' : 'FIRST_READ_TRANSCRIPTION_STRAND'
    }
    return params.rnaseqStrandSpecificity.toUpperCase()
}
