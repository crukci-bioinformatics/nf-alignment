include {
    picard_fixmate; picard_merge_or_markduplicates; picard_addreadgroups;
    picard_alignmentmetrics; picard_wgsmetrics; picard_insertmetrics;
    sample_merge_or_markduplicates;
    sample_alignmentmetrics; sample_wgsmetrics; sample_insertmetrics
} from "../processes/picard"

include {
    sample_genomecoverage; sample_bedsort; sample_bedgraphtobigwig
} from "../processes/coverage"

include { basenameExtractor } from "../components/functions"

workflow pairedend
{
    take:
        alignment_channel
        sequencing_info_channel

    main:
        picard_fixmate(alignment_channel)

        // Group the outputs by base name.
        picard_merge_or_markduplicates(picard_fixmate.out.groupTuple())

        picard_alignmentmetrics(picard_merge_or_markduplicates.out.merged_bam)
        picard_wgsmetrics(picard_merge_or_markduplicates.out.merged_bam, false)
        picard_insertmetrics(picard_merge_or_markduplicates.out.merged_bam)

        // Add sequencing info back to the channel for read groups.
        // It is available from sequencing_info_channel, the rows from the CSV file.
        read_groups_channel =
            picard_merge_or_markduplicates.out.merged_bam
            .join(
                sequencing_info_channel.map { tuple basenameExtractor(it.Read1), it },
                failOnDuplicate: true, failOnMismatch: true
            )

        picard_addreadgroups(read_groups_channel)

        // Transform the tuple of base name, BAM and sequencing information from
        // add read groups to a channel of tuples of sample name plus BAM files (plural).
        by_sample_channel =
            picard_addreadgroups.out.final_bam
            .map {
                basename, bam, sequencingInfo ->
                tuple sequencingInfo.SampleName, bam
            }
            .groupTuple()

        sample_merge_or_markduplicates(by_sample_channel)
        sample_alignmentmetrics(sample_merge_or_markduplicates.out.sample_bam)
        sample_wgsmetrics(sample_merge_or_markduplicates.out.sample_bam, false)
        sample_insertmetrics(sample_merge_or_markduplicates.out.sample_bam)

        sample_genomecoverage(sample_merge_or_markduplicates.out.sample_bam) | sample_bedsort | sample_bedgraphtobigwig
}
