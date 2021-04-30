#!/bin/bash

set -o pipefail

!{params.bwa} \
    samse \
    "!{bwaIndexDir}/!{bwaIndexPrefix}" \
    !{saiFile} \
    !{fastqFile} | \
!{params.samtools} \
    view -b -h \
    -o "!{outBam}"
