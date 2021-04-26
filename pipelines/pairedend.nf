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
        // Add sequencing info back to the channel for read groups.
        // It is available from sequencing_info_channel, the rows from the CSV file.
        read_groups_channel =
            alignment_channel
            .combine(sequencing_info_channel.map { tuple basenameExtractor(it.Read1), it }, by: 0)

        picard_addreadgroups(read_groups_channel) | picard_fixmate

        // Group the outputs by base name.
        picard_merge_or_markduplicates(picard_fixmate.out.groupTuple())
        picard_alignmentmetrics(picard_merge_or_markduplicates.out.merged_bam)
        picard_wgsmetrics(picard_merge_or_markduplicates.out.merged_bam, false)
        picard_insertmetrics(picard_merge_or_markduplicates.out.merged_bam)

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
        sample_alignmentmetrics(sample_merge_or_markduplicates.out.sample_bam)
        sample_wgsmetrics(sample_merge_or_markduplicates.out.sample_bam, false)
        sample_insertmetrics(sample_merge_or_markduplicates.out.sample_bam)

        sample_genomecoverage(sample_merge_or_markduplicates.out.sample_bam) | sample_bedsort | sample_bedgraphtobigwig
}
