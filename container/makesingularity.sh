#!/bin/sh

if [[ -d spython ]]
then
    source spython/bin/activate
else
    python3 -m venv spython
    source spython/bin/activate
    pip install spython
fi

spython recipe Dockerfile > singularity_spec.txt

sudo singularity build alignment40.2.sif singularity_spec.txt
chmod a-x alignment40.2.sif

