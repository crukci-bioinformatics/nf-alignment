#!/bin/bash

set -o pipefail

!{params.bwamem2} \
    mem \
    -t !{task.cpus} \
    "!{bwamem2IndexDir}/!{bwamem2IndexPrefix}" \
    !{sequenceFiles} | \
!{params.samtools} \
    view -b -h \
    -o "!{outBam}"
