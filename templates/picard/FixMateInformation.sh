#!/bin/bash

# Documentation: http://broadinstitute.github.io/picard/command-line-overview.html#FixMateInformation

# Verify mate-pair information between mates and fix if needed.This tool ensures that
# all mate-pair information is in sync between each read and its mate pair.
# If no OUTPUT file is supplied then the output is written to a temporary file and
# then copied over the INPUT file.  Reads marked with the secondary alignment flag
# are written to the output file unchanged.


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
-jar /usr/local/lib/picard.jar FixMateInformation \
INPUT=!{inBam} \
OUTPUT="!{outBam}" \
SORT_ORDER=coordinate \
MAX_RECORDS_IN_RAM=!{readsInRam} \
CREATE_INDEX=true \
COMPRESSION_LEVEL=1 \
VALIDATION_STRINGENCY=SILENT \
TMP_DIR="$TMPDIR"

groovy "!{projectDir}/modules/nextflow-support/outOfMemoryCheck.groovy" $?

clean_up $?
