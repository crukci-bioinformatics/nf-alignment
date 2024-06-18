#!/bin/sh

TAG="4.2.1"
REPO="crukcibioinformatics/alignment:$TAG"

sudo docker build --tag "$REPO" --file Dockerfile .
if [ $? -eq 0 ]
then
    sudo docker push "$REPO"
fi
