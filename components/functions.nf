import java.nio.file.Files

def fetchContainer()
{
    def containerName = file(workflow.container).name
    def containerFile = file("${workDir}/${containerName}")

    if (!Files.exists(containerFile))
    {
        def remote = file("http://internal-bioinformatics.cruk.cam.ac.uk/containers/alignment40.sif")
        log.warn "Fetching Singularity container..."
        remote.copyTo(containerFile)
    }
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
