#!/bin/bash

set -o pipefail

bwa sampe \
    "!{bwaIndexDir}/!{bwaIndexPrefix}" \
    !{saiFiles} \
    !{fastqFiles} | \
samtools \
    view -b -h \
    -o "!{outBam}"
