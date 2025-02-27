#!/bin/sh

TAG="4.3.1"
REPO="crukcibioinformatics/alignment:$TAG"
IMAGE="alignment-${TAG}.sif"

sudo rm -f "$IMAGE"

sudo singularity build "$IMAGE" docker-daemon://${REPO}
sudo chown $USER "$IMAGE"
chmod a-x "$IMAGE"
