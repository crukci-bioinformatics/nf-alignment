#!/bin/bash

bwa aln \
-f "!{outSai}" \
"!{bwaIndexDir}/!{bwaIndexPrefix}" \
!{fastqFile}
