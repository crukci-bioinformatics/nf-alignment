#!/bin/bash

# Documentation: http://broadinstitute.github.io/picard/command-line-overview.html#MergeSamFiles
#
# Merges multiple SAM and/or BAM files into a single file.  This tool is used for combining
# SAM and/or BAM files from different runs or read groups, similarly to the "merge" function
# of Samtools (http://www.htslib.org/doc/samtools.html).
#
# Note that to prevent errors in downstream processing, it is critical to identify/label read
# groups appropriately. If different samples contain identical read group IDs, this tool will
# avoid collisions by modifying the read group IDs to be unique. For more information about
# read groups, see the GATK Dictionary entry. (https://www.broadinstitute.org/gatk/guide/article?id=6472)


!{params.java} \
-Xms!{task.memory.toMega()}m -Xmx!{task.memory.toMega()}m \
-jar !{params.picard} MergeSamFiles \
!{'INPUT=' + inBams.join(' INPUT=')} \
OUTPUT="!{outBam}" \
ASSUME_SORTED=true \
CREATE_INDEX=true \
COMPRESSION_LEVEL=5 \
VALIDATION_STRINGENCY=LENIENT \
TMP_DIR=!{workDir}
