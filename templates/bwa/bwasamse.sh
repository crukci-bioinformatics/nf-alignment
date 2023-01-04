#!/bin/bash

set -o pipefail

bwa samse \
    "!{bwaIndexDir}/!{bwaIndexPrefix}" \
    !{saiFile} \
    !{fastqFile} | \
samtools \
    view -b -h \
    -o "!{outBam}"
