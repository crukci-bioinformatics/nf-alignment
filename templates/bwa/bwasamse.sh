#!/bin/bash

set -o pipefail

bwa samse \
    !{params.bwaSamOptions} \
    "!{bwaIndexDir}/!{bwaIndexPrefix}" \
    !{saiFile} \
    !{fastqFile} | \
samtools \
    view -b -h \
    -o "!{outBam}"
