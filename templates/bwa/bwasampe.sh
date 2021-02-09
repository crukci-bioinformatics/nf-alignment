#!/bin/bash

set -o pipefail

!{params.bwa} \
    sampe \
    "!{params.bwaIndex}" \
    !{saiFiles} \
    !{fastqFiles} | \
!{params.samtools} \
    view -b -h \
    -o "!{outBam}"
