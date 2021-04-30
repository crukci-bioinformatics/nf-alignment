#!/bin/bash

# Documentation: http://broadinstitute.github.io/picard/command-line-overview.html#CollectWgsMetrics
#
# Collect metrics about coverage and performance of whole genome sequencing (WGS) experiments.
# This tool collects metrics about the fractions of reads that pass base- and mapping-quality filters
# as well as coverage (read-depth) levels for WGS analyses. Both minimum base- and mapping-quality
# values as well as the maximum read depths (coverage cap) are user defined.
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
-jar !{params.picard} CollectWgsMetrics \
INPUT=!{inBam} \
OUTPUT="!{metrics}" \
REFERENCE_SEQUENCE="!{referenceFasta}" \
MINIMUM_MAPPING_QUALITY=20 \
MINIMUM_BASE_QUALITY=20 \
COVERAGE_CAP=250 \
LOCUS_ACCUMULATION_CAP=100000 \
COUNT_UNPAIRED=!{countUnpairedReads} \
VALIDATION_STRINGENCY=SILENT \
TMP_DIR="$TMPDIR"

clean_up $?
