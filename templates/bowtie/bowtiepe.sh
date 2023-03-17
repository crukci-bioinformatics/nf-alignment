#!/bin/bash

set -o pipefail

bowtie2 \
    !{params.bowtie2Options} \
    -p !{task.cpus} \
    -x "!{bowtie2IndexDir}/!{bowtie2IndexPrefix}" \
    -1 !{read1} \
    -2 !{read2} | \
samtools \
    view -b -h \
    -o "!{outBam}"
