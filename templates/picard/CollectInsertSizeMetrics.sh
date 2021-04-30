# Documentation: http://broadinstitute.github.io/picard/command-line-overview.html#CollectInsertSizeMetrics
#
# This tool provides useful metrics for validating library construction including the insert size
# distribution and read orientation of paired-end libraries.
#
# The expected proportions of these metrics vary depending on the type of library preparation used,
# resulting from technical differences between pair-end libraries and mate-pair libraries. For a brief
# primer on paired-end sequencing and mate-pair reads, see the GATK Dictionary
# (https://www.broadinstitute.org/gatk/guide/article?id=6327).
#
# The CollectInsertSizeMetrics tool outputs the percentages of read pairs in each of the three
# orientations (FR, RF, and TANDEM) as a histogram. In addition, the insert size distribution is output
# as both a histogram PDF and as a data table.
#
# Note: Metrics labeled as percentages are actually expressed as fractions!


export TMPDIR=temp
mkdir -p "$TMPDIR"

function clean_up
{
    rm -rf "$TMPDIR"
    exit $1
}

trap clean_up SIGHUP SIGINT SIGTERM

!{params.java} -Djava.io.tmpdir="$TMPDIR" \
-Xms!{javaMem}m -Xmx!{javaMem}m \
-jar !{params.picard} CollectInsertSizeMetrics \
INPUT=!{inBam} \
OUTPUT="!{metrics}" \
HISTOGRAM_FILE="!{plot}" \
REFERENCE_SEQUENCE="!{referenceFasta}" \
ASSUME_SORTED=true \
VALIDATION_STRINGENCY=SILENT \
TMP_DIR="$TMPDIR"

clean_up $?
