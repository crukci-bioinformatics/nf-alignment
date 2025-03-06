#!/bin/sh

DIR=$(dirname $0)
source $DIR/settings.sh

sudo rm -f "$IMAGE"

sudo singularity build "$IMAGE" docker-daemon://${REPO}
sudo chown $USER "$IMAGE"
chmod a-x "$IMAGE"
