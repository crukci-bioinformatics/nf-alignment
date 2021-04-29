#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { checkParameters; displayParameters } from "./components/configuration"

if (!checkParameters(params))
{
    exit 1
}

displayParameters(params)

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
    csv_channel =
        channel
            .fromPath(params.alignmentCSV)
            .splitCsv(header: true, quote: '"', strip: true)

    alignment(csv_channel)
}
