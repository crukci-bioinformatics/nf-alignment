#!/bin/bash

set -o pipefail

bwa sampe \
    !{params.bwaSamOptions} \
    "!{bwaIndexDir}/!{bwaIndexPrefix}" \
    !{saiFiles} \
    !{fastqFiles} | \
samtools \
    view -b -h \
    -o "!{outBam}"
