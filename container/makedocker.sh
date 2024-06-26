#!/bin/sh

TAG="4.3.0"
REPO="crukcibioinformatics/alignment:$TAG"

sudo docker build --tag "$REPO" --file Dockerfile .
if [ $? -eq 0 ]
then
    sudo docker push "$REPO"
fi
