#!/bin/bash

bedGraphToBigWig \
!{sortedBed} \
"!{genomeSizes}" \
"!{bigwig}"
