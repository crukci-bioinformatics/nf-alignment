#!/bin/bash

!{params.ucsctools}/bedGraphToBigWig \
!{sortedBed} \
"!{params.genomeSizes}" \
"!{bigwig}"
