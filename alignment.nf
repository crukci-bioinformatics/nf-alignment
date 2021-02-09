#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

if (!params.aligner)
{
    exit 1, "Aligner not specified. Use --aligner with one of 'bwa', 'bwamem', 'star'."
}

if (!params.endType)
{
    exit 1, "Sequencing method not set. Use --endType with 'se' (single read) or 'pe' (paired end)."
}

def pairedEnd

switch (params.endType.toLowerCase()[0])
{
    case 's':
        pairedEnd = false
        break

    case 'p':
        pairedEnd = true
        break

    default:
        exit 1, "End type must be given to indicate single read (se/sr) or paired end (pe)."
}

switch (params.aligner.toLowerCase())
{
    case 'bwa':
        if (pairedEnd)
        {
            include { bwa_pe as alignment } from "./pipelines/bwa_pe"
        }
        else
        {
            include { bwa_se as alignment } from "./pipelines/bwa_se"
        }
        break

    case 'bwamem':
    case 'bwa_mem':
        if (pairedEnd)
        {
            include { bwamem_pe as alignment } from "./pipelines/bwamem_pe"
        }
        else
        {
            include { bwamem_se as alignment } from "./pipelines/bwamem_se"
        }
        break

    case 'star':
        if (pairedEnd)
        {
            include { star_pe as alignment } from "./pipelines/star_pe"
        }
        else
        {
            include { star_se as alignment } from "./pipelines/star_se"
        }
        break

    default:
        exit 1, "Aligner must be one of 'bwa', 'bwamem' or 'star'."
}

include { fetchContainer } from "./components/functions"

workflow
{
    fetchContainer()

    csv_channel =
        channel
            .fromPath("alignment.csv")
            .splitCsv(header: true, quote: '"')

    alignment(csv_channel)
}
