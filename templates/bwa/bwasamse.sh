#!/bin/bash

set -o pipefail

!{params.bwa} \
    samse \
    "!{params.bwaIndex}" \
    !{saiFile} \
    !{fastqFile} | \
!{params.samtools} \
    view -b -h \
    -o "!{outBam}"
