/*
 * Miscellaneous helper functions used all over the pipeline.
 */

/*
 * Get the base name from a file name, using the extract pattern and capture
 * group set in the parameters.
 */
String basenameExtractor(CharSequence filename)
{
    def m = filename =~ params.basenameExtractPattern
    assert m.matches() : "Cannot extract base name from ${filename} using the pattern ${params.basenameExtractPattern}"
    m[0][params.basenameCaptureGroup]
}

/*
 * Standard function for the base of an aligned file. It is the base name
 * plus aligner and reference species.
 */
String alignedFileName(Object basename)
{
    "${basename}.${params.aligner}.${params.species}"
}

/*
 * Extract the chunk number from a file produced by splitFastq. It is the
 * six digits just before the .fq or .fq.gz suffix.
 * Note it is returned as a string with the full six digits, not a number.
 * This helps with sorting by name, as we don't have to sort numerically
 * aware: we have the zeroes that do the work!
 */
String extractChunkNumber(Path f)
{
    def m = f.name =~ /.+-S(\d{6})\.fq(\.gz)?$/
    assert m : "Don't have file pattern with chunk numbers: '${f.name}'"
    return m[0][1]
}
