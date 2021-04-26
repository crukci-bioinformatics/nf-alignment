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

RGCN="!{sequencingInfo['SequencingCentre']}"
if [ "x$RGCN" == "x" ]
then
    RGCN="null"
fi

RGDT="!{sequencingInfo['SequencingDate']}"
if [ "x$RGDT" == "x" ]
then
    RGDT="null"
fi

RGID="!{sequencingInfo['ReadGroup']}"
if [ "x$RGID" == "x" ]
then
    RGID="Z"
fi

RGLB="!{sequencingInfo['Library']}"
if [ "x$RGLB" == "x" ]
then
    RGPL="Unknown"
fi

RGPL="!{sequencingInfo['SequencingPlatform']}"
if [ "x$RGPL" == "x" ]
then
    RGPL="Unknown"
fi

RGPM="!{sequencingInfo['PlatformModel']}"
if [ "x$RGPM" == "x" ]
then
    RGPM="null"
fi

RGPU="!{sequencingInfo['PlatformUnit']}"
if [ "x$RGPU" == "x" ]
then
    RGPU="Not available"
fi

RGSM="!{sequencingInfo['SourceMaterial']}"
if [ "x$RGSM" == "x" ]
then
    RGSM="Not available"
fi

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
-jar !{params.picard} AddOrReplaceReadGroups \
INPUT=!{inBam} \
OUTPUT="!{outBam}" \
RGCN="$RGCN" \
RGDT="$RGDT" \
RGID="$RGID" \
RGLB="$RGLB" \
RGPL="$RGPL" \
RGPM="$RGPM" \
RGPU="$RGPU" \
RGSM="$RGSM" \
CREATE_INDEX=false \
COMPRESSION_LEVEL=5 \
VALIDATION_STRINGENCY=SILENT \
TMP_DIR="$TMPDIR"

clean_up $?
