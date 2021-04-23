params.aligner = "star"

include { basenameExtractor } from "../components/functions"
include { STAR } from "../processes/star"
include { pairedend } from "./pairedend"

workflow star_pe
{
    take:
        csv_channel

    main:
        fastq_channel =
            csv_channel
            .map
            {
                row ->
                tuple basenameExtractor(row.Read1), [ file("${params.fastqDir}/${row.Read1}"), file("${params.fastqDir}/${row.Read2}") ]
            }

        STAR(fastq_channel)
        pairedend(STAR.out, csv_channel)
}
