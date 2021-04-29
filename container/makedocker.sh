#!/bin/sh

sudo docker build --tag "crukcibioinformatics/alignment:40" --file Dockerfile .
docker push crukcibioinformatics/alignment:40
