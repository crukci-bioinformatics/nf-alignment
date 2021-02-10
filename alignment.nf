#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { checkParameters; fetchContainer } from "./components/functions"

if (!checkParameters(params))
{
    exit 1
}

switch (params.aligner)
{
    case 'bwa':
        if (params.pairedEnd)
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
        if (params.pairedEnd)
        {
            include { bwamem_pe as alignment } from "./pipelines/bwamem_pe"
        }
        else
        {
            include { bwamem_se as alignment } from "./pipelines/bwamem_se"
        }
        break

    case 'star':
        if (params.pairedEnd)
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

workflow
{
    fetchContainer()

    csv_channel =
        channel
            .fromPath(params.aligmentCSV)
            .splitCsv(header: true, quote: '"')

    alignment(csv_channel)
}
