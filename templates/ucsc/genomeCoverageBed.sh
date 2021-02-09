#!/bin/bash

!{params.bedtools}/genomeCoverageBed \
-bga \
-ibam !{inBam} \
-g "!{params.genomeSizes}" \
> "!{bedgraph}"
