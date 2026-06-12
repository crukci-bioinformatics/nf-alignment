/*
 * Processes to make sure things are ok going between unit level processing
 * and merging into sample bams.
 */

nextflow.enable.types = true

include { alignedFileName } from '../components/functions'

process makeSafeForMerging
{
    executor 'local'

    memory 1.MB
    time   1.minute

    input:
        record(basename: String, bam: Path, sequencingInfo: Map)

    output:
        record(basename: basename, bam: file(outBam), sequencingInfo: sequencingInfo)

    when:
        params.mergeSamples

    shell:
        inBam = bam
        outBam = "${alignedFileName(basename)}.forsamplemerging.bam"

        """
        ln -s "${inBam}" "${outBam}"
        """
}
