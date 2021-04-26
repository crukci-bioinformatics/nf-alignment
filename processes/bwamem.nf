import nextflow.util.BlankSeparatedList

include { extractChunkNumber } from '../components/functions'


/*
 * Fastq Splitter.
 */

def splitToPerChunkChannel(splitChannel)
{
    return splitChannel.flatMap
    {
        basename, read, chunks ->
        if (chunks instanceof Collection)
        {
            return chunks.collect { tuple basename, extractChunkNumber(it), it }
        }

        assert chunks instanceof java.nio.file.Path : "chunks is not a Path for ${basename} read ${read}"
        Collections.singletonList(tuple basename, extractChunkNumber(chunks), chunks)
    }
}

/*
 * BWAmem.
 */

process bwa_mem
{
    cpus 4
    memory { 8.GB * task.attempt }
    time 8.hour
    maxRetries 2

    input:
        tuple val(basename), file(sequenceFiles)

    output:
        tuple val(basename), val(chunk), path(outBam)

    shell:
        chunk = extractChunkNumber(sequenceFiles[0])

        outBam = "${basename}.bwamem.${chunk}.bam"
        template "bwa/bwamem.sh"
}
