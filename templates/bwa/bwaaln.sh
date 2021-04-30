#!/bin/bash

!{params.bwa} \
aln \
-f "!{outSai}" \
"!{bwaIndexDir}/!{bwaIndexPrefix}" \
!{fastqFile}
