params.aligner = "star"

include { basenameExtractor } from "../components/functions"
include { STAR } from "../components/processes"
include { singleread } from "../components/singleread"

workflow star_se
{
    take:
        csv_channel

    main:
        fastq_channel =
            csv_channel
            .map
            {
                row ->
                tuple basenameExtractor(row.Read1), file("${params.fastqDir}/${row.Read1}")
            }

        STAR(fastq_channel)
        singleread(STAR.out, csv_channel)
}
