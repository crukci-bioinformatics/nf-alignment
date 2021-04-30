#!/bin/bash

set -o pipefail

!{params.bwa} \
    sampe \
    "!{bwaIndexDir}/!{bwaIndexPrefix}" \
    !{saiFiles} \
    !{fastqFiles} | \
!{params.samtools} \
    view -b -h \
    -o "!{outBam}"
