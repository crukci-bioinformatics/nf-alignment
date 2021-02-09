#!/bin/bash

!{params.bwa} \
aln \
-f "!{outSai}" \
"!{params.bwaIndex}" \
!{fastqFile}
