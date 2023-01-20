#!/bin/bash

# Documentation: http://broadinstitute.github.io/picard/command-line-overview.html#AddOrReplaceReadGroups
#
# Replace read groups in a BAM file.
# This tool enables the user to replace all read groups in the INPUT file with a single new read group
# and assign all reads to this read group in the OUTPUT BAM file.
#
# For more information about read groups, see the GATK Dictionary entry.
# (https://www.broadinstitute.org/gatk/guide/article?id=6472)
#
# This tool accepts INPUT BAM and SAM files or URLs from the Global Alliance for Genomics and Health (GA4GH)
# (see http://ga4gh.org/#/documentation).

export TMPDIR=temp
mkdir -p "$TMPDIR"

function clean_up
{
    rm -rf "$TMPDIR"
    exit $1
}

trap clean_up SIGHUP SIGINT SIGTERM

java -Djava.io.tmpdir="$TMPDIR" \
-Xms!{javaMem}m -Xmx!{javaMem}m \
-jar /usr/local/lib/picard.jar AddOrReplaceReadGroups \
INPUT=!{inBam} \
OUTPUT="!{outBam}" \
!{RGCN} \
!{RGDT} \
!{RGID} \
!{RGLB} \
!{RGPL} \
!{RGPM} \
!{RGPU} \
!{RGSM} \
CREATE_INDEX=true \
COMPRESSION_LEVEL=5 \
VALIDATION_STRINGENCY=SILENT \
TMP_DIR="$TMPDIR"

groovy "!{projectDir}/modules/nextflow-support/outOfMemoryCheck.groovy" $?

clean_up $?
