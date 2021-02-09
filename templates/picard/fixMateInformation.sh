#!/bin/bash

# Documentation: http://broadinstitute.github.io/picard/command-line-overview.html#FixMateInformation

# Verify mate-pair information between mates and fix if needed.This tool ensures that
# all mate-pair information is in sync between each read and its mate pair.
# If no OUTPUT file is supplied then the output is written to a temporary file and
# then copied over the INPUT file.  Reads marked with the secondary alignment flag
# are written to the output file unchanged.


!{params.java} \
-Xms!{task.memory.toMega()}m -Xmx!{task.memory.toMega()}m \
-jar !{params.picard} FixMateInformation \
INPUT=!{inBam} \
OUTPUT="!{outBam}" \
SORT_ORDER=coordinate \
CREATE_INDEX=false \
COMPRESSION_LEVEL=1 \
VALIDATION_STRINGENCY=LENIENT \
TMP_DIR=!{workDir}
