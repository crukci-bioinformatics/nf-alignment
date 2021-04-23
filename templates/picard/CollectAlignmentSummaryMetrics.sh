#!/bin/bash

# Documentation: http://broadinstitute.github.io/picard/command-line-overview.html#CollectAlignmentSummaryMetrics
#
# Produces a summary of alignment metrics from a SAM or BAM file.
# This tool takes a SAM/BAM file input and produces metrics detailing the quality of the read alignments
# as well as the proportion of the reads that passed machine signal-to-noise threshold quality filters.
# Note that these quality filters are specific to Illumina data; for additional information, please see
# the corresponding GATK Dictionary entry (https://www.broadinstitute.org/gatk/guide/article?id=6329).
#
# Note: Metrics labeled as percentages are actually expressed as fractions!


export TMPDIR=temp
mkdir -p "$TMPDIR"

function clean_up
{
    rm -rf "$TMPDIR"
    exit $1
}

trap clean_up SIGHUP SIGINT SIGTERM

!{params.java} -Djava.io.tmpdir="$TMPDIR" \
-Xms!{javaMem}m -Xmx!{javaMem}m \
-jar !{params.picard} CollectAlignmentSummaryMetrics \
INPUT=!{inBam} \
OUTPUT="!{metrics}" \
REFERENCE_SEQUENCE="!{params.referenceFasta}" \
VALIDATION_STRINGENCY=SILENT \
TMP_DIR="$TMPDIR"

clean_up $?
