#!/bin/bash

set -o pipefail

bwa-mem2 mem \
    !{params.bwamem2Options} \
    -t !{task.cpus} \
    "!{bwamem2IndexDir}/!{bwamem2IndexPrefix}" \
    !{sequenceFiles} | \
samtools \
    view -b -h \
    -o "!{outBam}"
