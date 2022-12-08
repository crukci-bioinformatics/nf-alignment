/*
 * Processes to make sure things are ok going between unit level processing
 * and merging into sample bams.
 */

include { alignedFileName } from '../components/functions'

process make_safe_for_merging
{
    executor 'local'

    memory 1.MB
    time   1.minute

    when:
        params.mergeSamples

    input:
        tuple val(basename), path(inBam), val(sequencingInfo)

    output:
        tuple val(basename), path(outBam), val(sequencingInfo)

    shell:
        outBam = "${alignedFileName(basename)}.forsamplemerging.bam"

        """
        ln -s "${inBam}" "${outBam}"
        """
}
