#!/bin/sh

sudo docker build --tag "crukcibioinformatics/alignment:4.0.2" --file Dockerfile .
sudo docker push crukcibioinformatics/alignment:4.0.2
