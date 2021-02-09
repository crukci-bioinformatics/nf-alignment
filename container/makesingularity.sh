#!/bin/sh

sudo singularity build alignment40.sif singularity_spec.txt
chmod a-x alignment40.sif
