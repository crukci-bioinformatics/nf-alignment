/*
 * Post alignment work flow for single read alignment.
 * The input to this work flow should be the aligned BAM files from the aligner work flow.
 */

include {
    picard_sortsam; picard_merge_or_markduplicates; picard_addreadgroups;
    picard_alignmentmetrics; picard_wgsmetrics; picard_rnaseqmetrics;
    sample_merge_or_markduplicates;
    sample_alignmentmetrics; sample_wgsmetrics; sample_rnaseqmetrics
} from "../processes/picard"

include { make_safe_for_merging } from "../processes/premerging"

include {
    sample_genomecoverage; sample_bedsort; sample_bedgraphtobigwig
} from "../processes/coverage"

include { basenameExtractor } from "../components/functions"

workflow singleread
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

        picard_addreadgroups(read_groups_channel) | picard_sortsam

        // Group the outputs by base name. Use the groupKey function to
        // allow things to run when each group is complete, rather than
        // waiting for everything.

        merge_channel =
            picard_sortsam.out
            .combine(chunk_count_channel, by: 0)
            .map {
                basename, bam, chunkCount ->
                tuple groupKey(basename, chunkCount), bam
            }
            .groupTuple()

        picard_merge_or_markduplicates(merge_channel)

        picard_with_reference = picard_merge_or_markduplicates.out.merged_bam.combine(reference_fasta_channel)

        picard_alignmentmetrics(picard_with_reference)
        picard_wgsmetrics(picard_with_reference, true)
        picard_rnaseqmetrics(picard_with_reference.combine(reference_refflat_channel))

        // Join the output of merge or mark duplicates with the sequencing info
        // by base name.
        with_info_channel =
            picard_merge_or_markduplicates.out.merged_bam
            .combine(sequencing_info_channel.map { tuple basenameExtractor(it.Read1), it }, by: 0)

        make_safe_for_merging(with_info_channel)

        // Map to the sample name and collection BAM files for that sample.
        safe_sample_channel = make_safe_for_merging.out
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
            safe_sample_channel
            .combine(sample_count_channel, by: 0)
            .map {
                sampleName, bam, filesPerSample ->
                tuple groupKey(sampleName, filesPerSample), bam
            }
            .groupTuple()

        sample_merge_or_markduplicates(sample_merge_channel)

        sample_with_reference = sample_merge_or_markduplicates.out.sample_bam.combine(reference_fasta_channel)

        sample_alignmentmetrics(sample_with_reference)
        sample_wgsmetrics(sample_with_reference, true)
        sample_rnaseqmetrics(sample_with_reference.combine(reference_refflat_channel))

        sample_with_sizes = sample_merge_or_markduplicates.out.sample_bam.combine(genome_sizes_channel)

        sample_genomecoverage(sample_with_sizes) | sample_bedsort | sample_bedgraphtobigwig
}
