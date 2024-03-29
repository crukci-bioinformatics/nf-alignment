#!/usr/bin/env nextflow

/*
 * Main alignment work flow.
 */

nextflow.enable.dsl = 2

include { checkParameters; checkAlignmentCSV; displayParameters } from "./components/configuration"
include { pairedEnd } from "./components/defaults"

// Check all is well with the parameters and the alignment.csv file.

if (!checkParameters(params))
{
    exit 1
}
if (!checkAlignmentCSV())
{
    exit 1
}

switch (params.aligner.toLowerCase())
{
    case 'bwa':
        if (pairedEnd())
        {
            include { bwa_pe_wf as alignment } from "./pipelines/bwa_pe"
        }
        else
        {
            include { bwa_se_wf as alignment } from "./pipelines/bwa_se"
        }
        break

    case 'bwamem':
    case 'bwa_mem':
    case 'bwamem2':
    case 'bwa_mem2':
        if (pairedEnd())
        {
            include { bwamem_pe_wf as alignment } from "./pipelines/bwamem_pe"
        }
        else
        {
            include { bwamem_se_wf as alignment } from "./pipelines/bwamem_se"
        }
        break

    case 'bowtie':
    case 'bowtie2':
        if (pairedEnd())
        {
            include { bowtie_pe_wf as alignment } from "./pipelines/bowtie_pe"
        }
        else
        {
            include { bowtie_se_wf as alignment } from "./pipelines/bowtie_se"
        }
        break

    case 'star':
        if (pairedEnd())
        {
            include { star_pe_wf as alignment } from "./pipelines/star_pe"
        }
        else
        {
            include { star_se_wf as alignment } from "./pipelines/star_se"
        }
        break

    default:
        exit 1, "Aligner must be one of 'bwa', 'bwamem', 'bowtie' or 'star'."
}

displayParameters()


/*
 * Main work flow. For each line in alignment.csv, start aligning.
 */
workflow
{
    csv_channel = channel
        .fromPath(params.alignmentCSV)
        .splitCsv(header: true, quote: '"', strip: true)

    alignment(csv_channel)
}
