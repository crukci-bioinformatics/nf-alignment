/*
 * Post alignment work flow for paired end alignment.
 * The input to this work flow should be the aligned BAM files from the aligner work flow.
 */

include {
    picard_fixmate; picard_merge_or_markduplicates; picard_addreadgroups;
    picard_alignmentmetrics; picard_wgsmetrics; picard_rnaseqmetrics; picard_insertmetrics;
    sample_merge_or_markduplicates;
    sample_alignmentmetrics; sample_wgsmetrics; sample_rnaseqmetrics; sample_insertmetrics
} from "../processes/picard"

include { make_safe_for_merging } from "../processes/premerging"

include {
    sample_genomecoverage; sample_bedsort; sample_bedgraphtobigwig
} from "../processes/coverage"

include { basenameExtractor } from "../components/functions"

workflow pairedend
{
    take:
        alignment_channel
        sequencing_info_channel
        chunk_count_channel

    main:
        reference_fasta_channel = channel.fromPath(params.referenceFasta)
        genome_sizes_channel = params.containsKey('genomeSizes') ? channel.fromPath(params.genomeSizes) : channel.empty()
        reference_refflat_channel = params.containsKey('referenceRefFlat') ? channel.fromPath(params.referenceRefFlat) : channel.empty()

        // Add sequencing info back to the channel for read groups.
        // It is available from sequencing_info_channel, the rows from the CSV file.
        read_groups_channel =
            alignment_channel
            .combine(sequencing_info_channel.map { tuple basenameExtractor(it.Read1), it }, by: 0)

        picard_addreadgroups(read_groups_channel) | picard_fixmate

        // Group the outputs by base name. Use the groupKey function to
        // allow things to run when each group is complete, rather than
        // waiting for everything.

        merge_channel =
            picard_fixmate.out
            .join(chunk_count_channel)
            .map {
                basename, bam, chunkCount ->
                tuple groupKey(basename, chunkCount), bam
            }
            .groupTuple()

        picard_merge_or_markduplicates(merge_channel)

        picard_with_reference = picard_merge_or_markduplicates.out.merged_bam.combine(reference_fasta_channel)

        picard_alignmentmetrics(picard_with_reference)
        picard_wgsmetrics(picard_with_reference, false)
        picard_rnaseqmetrics(picard_with_reference.combine(reference_refflat_channel))
        picard_insertmetrics(picard_with_reference)

        make_safe_for_merging(picard_merge_or_markduplicates.out.merged_bam)

        // Join the output of merge or mark duplicates with the sequencing info
        // by base name and map to the sample name and BAM files.
        by_sample_channel =
            make_safe_for_merging.out
            .join(
                sequencing_info_channel.map { tuple basenameExtractor(it.Read1), it },
                failOnDuplicate: true, failOnMismatch: false
            )
            .map {
                basename, bam, sequencingInfo ->
                tuple sequencingInfo.SampleName, bam
            }

        // Get the number of files for each sample and provide a groupKey for merging
        // so it can start each group once all the files are received.

        sample_count_channel =
            sequencing_info_channel
            .map { tuple it.SampleName, it.Read1 }
            .groupTuple()
            .map {
                sampleName, readFiles ->
                tuple sampleName, readFiles.size()
            }

        sample_merge_channel =
            by_sample_channel
            .join(sample_count_channel)
            .map {
                sampleName, bam, filesPerSample ->
                tuple groupKey(sampleName, filesPerSample), bam
            }
            .groupTuple()

        sample_merge_or_markduplicates(sample_merge_channel)

        sample_with_reference = sample_merge_or_markduplicates.out.sample_bam.combine(reference_fasta_channel)

        sample_alignmentmetrics(sample_with_reference)
        sample_wgsmetrics(sample_with_reference, false)
        sample_rnaseqmetrics(sample_with_reference.combine(reference_refflat_channel))
        sample_insertmetrics(sample_with_reference)

        sample_with_sizes = sample_merge_or_markduplicates.out.sample_bam.combine(genome_sizes_channel)

        sample_genomecoverage(sample_with_sizes) | sample_bedsort | sample_bedgraphtobigwig
}
