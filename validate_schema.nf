#!/usr/bin/env nextflow

/*
 * Minimal script to validate nextflow_schema.json using the nf-schema plugin.
 * Run with required parameters to check that the schema accepts valid input:
 *
 *   nextflow run validate_schema.nf \
 *       --aligner bwa --endType pe \
 *       --species homo_sapiens --shortSpecies hsa --assembly GRCh38
 */

include { validateParameters } from 'plugin/nf-schema'

validateParameters()

workflow {}
