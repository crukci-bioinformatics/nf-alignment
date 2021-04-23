include {
    picard_sortsam; picard_markduplicates; picard_addreadgroups;
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
        picard_sortsam(alignment_channel)

        // Group the outputs by base name.
        picard_markduplicates(picard_sortsam.out.groupTuple())

        picard_alignmentmetrics(picard_markduplicates.out.merged_bam)
        picard_wgsmetrics(picard_markduplicates.out.merged_bam, true)

        // Add sequencing info back to the channel for read groups.
        // It is available from sequencing_info_channel, the rows from the CSV file.
        read_groups_channel =
            picard_markduplicates.out.merged_bam
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
        sample_wgsmetrics(sample_merge_or_markduplicates.out.sample_bam, true)

        sample_genomecoverage(sample_merge_or_markduplicates.out.sample_bam) | sample_bedsort | sample_bedgraphtobigwig
}
