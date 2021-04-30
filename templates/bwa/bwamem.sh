#!/bin/bash

set -o pipefail

!{params.bwamem2} \
    mem \
    -t !{Math.max(1, task.cpus - 1)} \
    "!{bwamem2IndexDir}/!{bwamem2IndexPrefix}" \
    !{sequenceFiles} | \
!{params.samtools} \
    view -b -h \
    -o "!{outBam}"
