/*
 * Post alignment work flow for single read alignment.
 * The input to this work flow should be the aligned BAM files from the aligner work flow.
 */

include {
    picard_sortsam; picard_merge_or_markduplicates; picard_addreadgroups;
    picard_alignmentmetrics; picard_wgsmetrics;
    sample_merge_or_markduplicates;
    sample_alignmentmetrics; sample_wgsmetrics
} from "../processes/picard"

include {
    sample_genomecoverage; sample_bedsort; sample_bedgraphtobigwig
} from "../processes/coverage"

include { basenameExtractor } from "../components/functions"

workflow singleread
{
    take:
        alignment_channel
        sequencing_info_channel

    main:
        reference_fasta_channel = channel.fromPath(params.referenceFasta)
        genome_sizes_channel = params.genomeSizes ? channel.fromPath(params.genomeSizes) : channel.empty

        // Add sequencing info back to the channel for read groups.
        // It is available from sequencing_info_channel, the rows from the CSV file.
        read_groups_channel =
            alignment_channel
            .combine(sequencing_info_channel.map { tuple basenameExtractor(it.Read1), it }, by: 0)

        picard_addreadgroups(read_groups_channel) | picard_sortsam

        // Group the outputs by base name.
        picard_merge_or_markduplicates(picard_sortsam.out.groupTuple())

        picard_with_reference = picard_merge_or_markduplicates.out.merged_bam.combine(reference_fasta_channel)

        picard_alignmentmetrics(picard_with_reference)
        picard_wgsmetrics(picard_with_reference, true)

        // Join the output of merge or mark duplicates with the sequencing info
        // by base name and map to the sample name and BAM files.
        by_sample_channel =
            picard_merge_or_markduplicates.out.merged_bam
            .join(
                sequencing_info_channel.map { tuple basenameExtractor(it.Read1), it },
                failOnDuplicate: true, failOnMismatch: true
            )
            .map {
                basename, bam, sequencingInfo ->
                tuple sequencingInfo.SampleName, bam
            }
            .groupTuple()

        sample_merge_or_markduplicates(by_sample_channel)

        sample_with_reference = sample_merge_or_markduplicates.out.sample_bam.combine(reference_fasta_channel)

        sample_alignmentmetrics(sample_with_reference)
        sample_wgsmetrics(sample_with_reference, true)

        sample_with_sizes = sample_merge_or_markduplicates.out.sample_bam.combine(genome_sizes_channel)

        sample_genomecoverage(sample_with_sizes) | sample_bedsort | sample_bedgraphtobigwig
}
