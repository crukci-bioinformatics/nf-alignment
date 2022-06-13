#!/bin/sh

sudo docker build --tag "crukcibioinformatics/alignment:40.2" --file Dockerfile .
sudo docker push crukcibioinformatics/alignment:40.2
