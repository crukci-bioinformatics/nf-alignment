#!/bin/sh

DIR=$(dirname $0)
source $DIR/settings.sh

sudo docker build --tag "$REPO" --file Dockerfile .
