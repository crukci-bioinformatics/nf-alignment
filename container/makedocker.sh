#!/bin/sh

TAG="4.0.5"
REPO="crukcibioinformatics/alignment:$TAG"

sudo docker build --tag "$REPO" --file Dockerfile .
sudo docker push "$REPO"
