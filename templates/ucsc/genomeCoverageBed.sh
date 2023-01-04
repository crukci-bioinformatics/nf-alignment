#!/bin/bash

genomeCoverageBed \
-bga \
-ibam !{inBam} \
-g "!{genomeSizes}" \
> "!{bedgraph}"
