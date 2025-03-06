#!/bin/sh

DIR=$(dirname $0)
source $DIR/settings.sh

sudo docker push "$REPO"
