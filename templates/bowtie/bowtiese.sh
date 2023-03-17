#!/bin/bash

set -o pipefail

bowtie2 \
    !{params.bowtie2Options} \
    -p !{task.cpus} \
    -x "!{bowtie2IndexDir}/!{bowtie2IndexPrefix}" \
    -U !{read1} | \
samtools \
    view -b -h \
    -o "!{outBam}"
