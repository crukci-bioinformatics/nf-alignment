#!/bin/bash

!{params.ucsctools}/bedGraphToBigWig \
!{sortedBed} \
"!{genomeSizes}" \
"!{bigwig}"
