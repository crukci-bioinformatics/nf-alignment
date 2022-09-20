#!/bin/sh

TAG="4.0.4"
REPO="crukcibioinformatics/alignment:$TAG"

sudo rm -rf alignment-${TAG}.sif

sudo singularity build alignment-${TAG}.sif docker-daemon://${REPO}
chmod a-x alignment-${TAG}.sif

