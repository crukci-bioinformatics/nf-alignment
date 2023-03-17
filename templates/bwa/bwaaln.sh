#!/bin/bash

bwa aln \
    !{params.bwaAlnOptions} \
    -f "!{outSai}" \
    "!{bwaIndexDir}/!{bwaIndexPrefix}" \
    !{fastqFile}
