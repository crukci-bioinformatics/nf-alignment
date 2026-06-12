#!/bin/bash

set -o pipefail

bwa sampe \
    !{params.bwaSamOptions} \
    "!{bwaIndexDir}/!{bwaIndexPrefix}" \
    !{saiFiles.join(' ')} \
    !{fastqFiles.join(' ')} | \
samtools \
    view -b -h \
    -o "!{outBam}"
