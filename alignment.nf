#!/usr/bin/env nextflow

/*
 * Main alignment work flow.
 */

include { validateParameters } from 'plugin/nf-schema'

include { bwaPE_wf as bwaPE } from "./pipelines/bwa_pe"
include { bwaSE_wf as bwaSE } from "./pipelines/bwa_se"
include { bwamemPE_wf as bwamemPE } from "./pipelines/bwamem_pe"
include { bwamemSE_wf as bwamemSE } from "./pipelines/bwamem_se"
include { bowtiePE_wf as bowtiePE } from "./pipelines/bowtie_pe"
include { bowtieSE_wf as bowtieSE } from "./pipelines/bowtie_se"
include { starPE_wf as starPE } from "./pipelines/star_pe"
include { starSE_wf as starSE } from "./pipelines/star_se"

/*
 * Main work flow. For each line in alignment.csv, start aligning.
 * The aligner and end type are validated by checkParameters() above,
 * so the else-if chain below is exhaustive for all legal combinations.
 */
workflow
{
    // Validate parameters against the schema, then check business logic and the alignment.csv file.
    
    validateParameters()
    
    if (!APUtils.checkParameters(params, log))
    {
        exit 1
    }
    if (!APUtils.checkAlignmentCSV(params, log))
    {
        exit 1
    }
    
    APUtils.displayParameters(params, log)
    
    csvChannel = channel
        .fromPath(params.alignmentCSV)
        .splitCsv(header: true, quote: '"', strip: true)

    def aligner = params.aligner.toLowerCase()
    def paired  = APDefaults.pairedEnd(params)

    if (aligner == 'bwa')
    {
        if (paired)
        {
            bwaPE(csvChannel)
        }
        else
        {
            bwaSE(csvChannel)
        }
    }
    else if (aligner in ['bwamem', 'bwa_mem', 'bwamem2', 'bwa_mem2'])
    {
        if (paired)
        {
            bwamemPE(csvChannel)
        }
        else
        {
            bwamemSE(csvChannel)
        }
    }
    else if (aligner in ['bowtie', 'bowtie2'])
    {
        if (paired)
        {
            bowtiePE(csvChannel)
        }
        else
        {
            bowtieSE(csvChannel)
        }
    }
    else if (aligner == 'star')
    {
        if (paired)
        {
            starPE(csvChannel)
        }
        else
        {
            starSE(csvChannel)
        }
    }
    else
    {
        error "Aligner must be one of 'bwa', 'bwamem', 'bowtie' or 'star'."
    }
}
