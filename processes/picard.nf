include { alignedFileName } from '../components/functions'

/**
 * Give a number for the Java heap size based on the task memory, allowing for
 * some overhead for the JVM itself from the total allowed.
 */
def javaMemMB(task)
{
    return task.memory.toMega() - 128
}

/**
 * Calculate the maximum number of reads to hold in RAM for Picard sorting
 * tasks based on memory allocated to the task and the read length.
 */
def maxReadsInRam(availableMB, readLength)
{
    /*
     * See http://broadinstitute.github.io/picard/faq.html question 2 for notes
     * on the RAM and maxRecordsInRAM balance.
     *
     * From those figures, we have 250,000 reads per GB at 100bp reads.
     * With the longer indexing, a read of 100bp is 272 bytes (characters),
     * of which 100 is the sequence, 100 is the quality and 72 is everything else.
     *
     * Using a "proper" GB (1000^3), that allows us 4000 bytes per read at 100bp.
     *
     * Dividing that up between the overhead and the sequence & quality, we have
     * overhead = 4000 * 72 / 272 = 1059 bytes of the 4000 and
     * sequence = 4000 * 200 / 272 = 2941 bytes of the 4000.
     *
     * We therefore 2941 bytes available per read for the sequence data, and since
     * that number is for 100bp reads, that gives 29.41 bytes per base.
     *
     * We can then go backwards. For 50 bp reads, the allocation necessary is
     * 1059 + 50 * 29.41 = 2530 bytes necessary for the read and for 150 bp reads
     * 1059 + 150 * 29.41 = 5471 bytes required.
     *
     * Going back to the 4000 bytes available for 100bp reads, we can then get a
     * ratio for reads per allocation (how many reads at the read length will fit
     * into the 4000 byte allocation).
     *
     * At 50bp:
     * 4000 / 2530 = 1.581 reads per allocation
     * At 100bp:
     * 4000 / 4000 = 1 read per allocation (how we started)
     * At 150bp:
     * 4000 / 5471 = 0.7311 reads per allocation.
     *
     * That multiplier gives us the answer we need for reads per GB, and so maximum
     * reads in RAM.
     *
     * 50bp:
     * 250,000 * 1.581 = 395257 per GB
     * 150bp:
     * 250,000 * 0.7311 = 182782 per GB
     *
     * That number then just needs to be multiplied up by the memory available. We
     * scale for megabytes as we shouldn't assume a round number of GB for the task.
     */

    final def allocationPerRead = 4000.0  // bytes
    final def bytesPerBase = 29.41176
    final def overheadPerRead = 1059.0    // bytes

    final def allocationForReadLength = overheadPerRead + bytesPerBase * readLength  // bytes
    final def allocationRatio = allocationPerRead / allocationForReadLength

    final def readsPerGB = 250000 * allocationRatio    // reads / gb
    final def readsPerMB = readsPerGB / 1024           // reads / mb
    final def totalReads = availableMB * readsPerMB    // mb * reads/mb to give reads

    return totalReads as long
}


process picard_addreadgroups
{
    label "picard"

    publishDir params.bamDir, mode: "link"

    input:
        tuple val(basename), val(chunk), path(inBam), val(sequencingInfo)

    output:
        tuple val(basename), val(chunk), path(outBam)

    shell:
        outBam = "${basename}.readgroups.${chunk}.bam"
        javaMem = javaMemMB(task)

        template "picard/AddReadGroups.sh"
}

process picard_sortsam
{
    label "picard"

    input:
        tuple val(basename), val(chunk), path(inBam)

    output:
        tuple val(basename), path(outBam)

    shell:
        outBam = "${basename}.sorted.${chunk}.bam"
        javaMem = javaMemMB(task)
        readsInRam = maxReadsInRam(javaMem, 100)

        template "picard/SortSam.sh"
}

process picard_fixmate
{
    label "picard"

    input:
        tuple val(basename), val(chunk), path(inBam)

    output:
        tuple val(basename), path(outBam)

    shell:
        outBam = "${basename}.fixed.${chunk}.bam"
        javaMem = javaMemMB(task)
        readsInRam = maxReadsInRam(javaMem, 100)

        template "picard/FixMateInformation.sh"
}

process picard_merge_or_markduplicates
{
    label "picard"

    publishDir params.bamDir, mode: "link", pattern: "*.duplication.txt"

    input:
        tuple val(basename), path(inBams)

    output:
        tuple val(basename), path(outBam), emit: merged_bam
        path metrics optional true

    shell:
        outBam = "${basename}.duplicates.bam"
        metrics = "${basename}.duplication.txt"
        javaMem = javaMemMB(task)
        readsInRam = maxReadsInRam(javaMem, 100)

        if (params.markDuplicates)
        {
            template "picard/MarkDuplicates.sh"
        }
        else
        {
            // Sometimes inBams is a single path, others it is a collections of paths.
            // Detect if it is a type of collection, and if so, use its size.
            def numberOfBams = inBams instanceof Collection ? inBams.size() : 1

            if (numberOfBams == 1)
            {
                // When "inBams" is exactly one, there is no need to run the single file
                // through merge. It can just be linked.
                "ln -s ${inBams} \"${outBam}\""
            }
            else
            {
                template "picard/MergeSamFiles.sh"
            }
        }
}

process picard_alignmentmetrics
{
    label "picard"

    publishDir params.bamDir, mode: "link"

    input:
        tuple val(basename), path(inBam)

    output:
        path metrics

    shell:
        metrics = "${alignedFileName(basename)}.alignment.txt"
        javaMem = javaMemMB(task)

        template "picard/CollectAlignmentSummaryMetrics.sh"
}

process picard_wgsmetrics
{
    label "picard"

    publishDir params.bamDir, mode: "link"

    when:
        params.wgsMetrics

    input:
        tuple val(basename), path(inBam)
        val(countUnpairedReads)

    output:
        path metrics

    shell:
        metrics = "${alignedFileName(basename)}.wgs.txt"
        javaMem = javaMemMB(task)

        template "picard/CollectWgsMetrics.sh"
}

process picard_insertmetrics
{
    label "picard"

    publishDir params.bamDir, mode: "link"

    input:
        tuple val(basename), path(inBam)

    output:
        path metrics optional true
        path plot optional true

    shell:
        metrics = "${alignedFileName(basename)}.insertsize.txt"
        plot = "${alignedFileName(basename)}.insertsize.pdf"
        javaMem = javaMemMB(task)

        template "picard/CollectInsertSizeMetrics.sh"
}

process sample_merge_or_markduplicates
{
    label "picard"

    publishDir params.sampleBamDir, mode: "link"

    when:
        params.mergeSamples

    input:
        tuple val(sampleName), path(inBams)

    output:
        tuple val(sampleName), path(outBam), emit: sample_bam
        path outIndex optional true
        path metrics optional true

    shell:
        outBam = "${alignedFileName(sampleName)}.bam"
        outIndex = "${alignedFileName(sampleName)}.bai"
        metrics = "${alignedFileName(sampleName)}.duplication.txt"
        javaMem = javaMemMB(task)
        readsInRam = maxReadsInRam(javaMem, 100)

        if (params.markDuplicates)
        {
            template "picard/MarkDuplicates.sh"
        }
        else
        {
            // Sometimes inBams is a single path, others it is a collections of paths.
            // Detect if it is a type of collection, and if so, use its size.
            def numberOfBams = inBams instanceof Collection ? inBams.size() : 1

            if (numberOfBams == 1)
            {
                // When "inBams" is exactly one, there is no need to run the single file
                // through merge. It can just be linked to.
                "ln -s ${inBams} \"${outBam}\""
            }
            else
            {
                template "picard/MergeSamFiles.sh"
            }
        }
}

process sample_alignmentmetrics
{
    label "picard"

    publishDir params.sampleBamDir, mode: "link"

    input:
        tuple val(sampleName), path(inBam)

    output:
        path metrics

    shell:
        metrics = "${alignedFileName(sampleName)}.alignment.txt"
        javaMem = javaMemMB(task)

        template "picard/CollectAlignmentSummaryMetrics.sh"
}

process sample_wgsmetrics
{
    label "picard"

    publishDir params.sampleBamDir, mode: "link"

    when:
        params.wgsMetrics

    input:
        tuple val(sampleName), path(inBam)
        val(countUnpairedReads)

    output:
        path metrics

    shell:
        metrics = "${alignedFileName(sampleName)}.wgs.txt"
        javaMem = javaMemMB(task)

        template "picard/CollectWgsMetrics.sh"
}

process sample_insertmetrics
{
    label "picard"

    publishDir params.sampleBamDir, mode: "link"

    input:
        tuple val(sampleName), path(inBam)

    output:
        path metrics optional true
        path plot optional true

    shell:
        metrics = "${alignedFileName(sampleName)}.insertsize.txt"
        plot = "${alignedFileName(sampleName)}.insertsize.pdf"
        javaMem = javaMemMB(task)

        template "picard/CollectInsertSizeMetrics.sh"
}
