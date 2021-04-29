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
