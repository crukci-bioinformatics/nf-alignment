#!/bin/bash

set -o pipefail

!{params.bwamem2} \
    mem \
    -t !{task.cpus} \
    "!{params.bwamem2Index}" \
    !{sequenceFiles} | \
!{params.samtools} \
    view -b -h \
    -o "!{outBam}"
