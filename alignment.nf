#!/usr/bin/env nextflow

/*
 * Main alignment work flow.
 */

include { validateParameters } from 'plugin/nf-schema'

include { checkParameters; checkAlignmentCSV; displayParameters } from "./components/configuration"
include { pairedEnd } from "./components/defaults"

include { bwa_pe_wf } from "./pipelines/bwa_pe"
include { bwa_se_wf } from "./pipelines/bwa_se"
include { bwamem_pe_wf } from "./pipelines/bwamem_pe"
include { bwamem_se_wf } from "./pipelines/bwamem_se"
include { bowtie_pe_wf } from "./pipelines/bowtie_pe"
include { bowtie_se_wf } from "./pipelines/bowtie_se"
include { star_pe_wf } from "./pipelines/star_pe"
include { star_se_wf } from "./pipelines/star_se"

// Validate parameters against the schema, then check business logic and the alignment.csv file.

validateParameters()

if (!checkParameters(params))
{
    exit 1
}
if (!checkAlignmentCSV())
{
    exit 1
}

displayParameters()


/*
 * Main work flow. For each line in alignment.csv, start aligning.
 * The aligner and end type are validated by checkParameters() above,
 * so the else-if chain below is exhaustive for all legal combinations.
 */
workflow
{
    csv_channel = channel
        .fromPath(params.alignmentCSV)
        .splitCsv(header: true, quote: '"', strip: true)

    def aligner = params.aligner.toLowerCase()
    def paired  = pairedEnd()

    if (aligner == 'bwa')
    {
        if (paired)
        {
            bwa_pe_wf(csv_channel)
        }
        else
        {
            bwa_se_wf(csv_channel)
        }
    }
    else if (aligner in ['bwamem', 'bwa_mem', 'bwamem2', 'bwa_mem2'])
    {
        if (paired)
        {
            bwamem_pe_wf(csv_channel)
        }
        else
        {
            bwamem_se_wf(csv_channel)
        }
    }
    else if (aligner in ['bowtie', 'bowtie2'])
    {
        if (paired)
        {
            bowtie_pe_wf(csv_channel)
        }
        else
        {
            bowtie_se_wf(csv_channel)
        }
    }
    else if (aligner == 'star')
    {
        if (paired)
        {
            star_pe_wf(csv_channel)
        }
        else
        {
            star_se_wf(csv_channel)
        }
    }
    else
    {
        error "Aligner must be one of 'bwa', 'bwamem', 'bowtie' or 'star'."
    }
}
