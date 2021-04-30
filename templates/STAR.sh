#!/bin/bash

function clean_up
{
    rm -rf "temp"
    exit $1
}

trap clean_up SIGHUP SIGINT SIGTERM

mkdir -p "!{basename}"

!{params.star} \
    --runMode alignReads \
    --runThreadN !{task.cpus} \
    --outBAMcompression 5 \
    --outSAMmapqUnique 60 \
    --outSAMunmapped Within \
    --genomeLoad NoSharedMemory \
    --readFilesCommand zcat \
    --outSAMtype BAM Unsorted \
    --genomeDir "!{starIndex}" \
    --outTmpDir "temp" \
    --outFileNamePrefix "!{basename}/" \
    --readFilesIn !{sequenceFiles}


STATUS=$?
if [[ $STATUS -ne 0 ]]
then
    rm -rf "!{basename}"
fi

clean_up $STATUS
