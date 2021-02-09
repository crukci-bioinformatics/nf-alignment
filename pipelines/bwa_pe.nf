params.aligner = "bwa"

include { basenameExtractor } from "../components/functions"
include { bwa_aln as bwa_aln_1; bwa_aln as bwa_aln_2; bwa_sampe } from "../components/bwaprocesses"
include { pairedend } from "../components/pairedend"

workflow bwa_pe
{
    take:
        csv_channel

    main:
        fastq_channel =
            csv_channel
            .map
            {
                row ->
                tuple basenameExtractor(row.Read1), file("${params.fastqDir}/${row.Read1}"), file("${params.fastqDir}/${row.Read2}")
            }
            .splitFastq(by: params.chunkSize, pe:true, file: true, compress: params.compressSplitFastq)

        // Split into two channels, one read in each, for BWA aln.

        read1_channel =
            fastq_channel
            .map
            {
                base, read1, read2 ->
                tuple base, 1, read1
            }

        read2_channel =
            fastq_channel
            .map
            {
                base, read1, read2 ->
                tuple base, 2, read2
            }

        bwa_aln_1(read1_channel)
        bwa_aln_2(read2_channel)

        // Combine the output of these two channels into one, grouping on base name and chunk number.

        sampe_channel =
            bwa_aln_1.out.join(bwa_aln_2.out, by: [0,1], failOnDuplicate: true, failOnMismatch: true)

        bwa_sampe(sampe_channel)
        pairedend(bwa_sampe.out, csv_channel)
}
