#!/bin/sh

TAG="4.0.6"
REPO="crukcibioinformatics/alignment:$TAG"

sudo rm -f alignment-${TAG}.sif

sudo singularity build alignment-${TAG}.sif docker-daemon://${REPO}
sudo chown $USER alignment-${TAG}.sif
chmod a-x alignment-${TAG}.sif

