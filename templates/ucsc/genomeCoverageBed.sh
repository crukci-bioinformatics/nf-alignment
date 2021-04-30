#!/bin/bash

!{params.bedtools}/genomeCoverageBed \
-bga \
-ibam !{inBam} \
-g "!{genomeSizes}" \
> "!{bedgraph}"
