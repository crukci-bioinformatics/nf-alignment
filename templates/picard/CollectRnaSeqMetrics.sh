#!/bin/bash

# Documentation: http://broadinstitute.github.io/picard/command-line-overview.html#CollectRnaSeqMetrics
#
# Produces RNA alignment metrics for a SAM or BAM file.
# This tool takes a SAM/BAM file containing the aligned reads from an RNAseq experiment and produces
# metrics describing the distribution of the bases within the transcripts. It calculates the total
# numbers and the fractions of nucleotides within specific genomic regions including untranslated
# regions (UTRs), introns, intergenic sequences (between discrete genes), and peptide-coding sequences
# (exons). This tool also determines the numbers of bases that pass quality filters that are specific
# to Illumina data (PF_BASES). For more information please see the corresponding GATK Dictionary
# (https://www.broadinstitute.org/gatk/guide/article?id=6329) entry.
#
# Other metrics include the median coverage (depth), the ratios of 5 prime/3 prime-biases, and the
# numbers of reads with the correct/incorrect strand designation. The 5 prime/3 prime-bias results
# from errors introduced by reverse transcriptase enzymes during library construction, ultimately
# leading to the over-representation of either the 5 prime or 3 prime ends of transcripts.
# Please see the CollectRnaSeqMetrics definitions
# (http://broadinstitute.github.io/picard/picard-metric-definitions.html#RnaSeqMetrics)
# for details on how these biases are calculated.
#
# The sequence input must be a valid SAM/BAM file containing RNAseq data aligned by an RNAseq-aware
# genome aligner such a STAR (http://github.com/alexdobin/STAR) or
# TopHat (http://ccb.jhu.edu/software/tophat/index.shtml). The tool also requires a REF_FLAT file,
# a tab-delimited file containing information about the location of RNA transcripts, exon start and
# stop sites, etc. For more information on the REF_FLAT format, see the following description
# (http://genome.ucsc.edu/goldenPath/gbdDescriptionsOld.html#RefFlat). Build-specific REF_FLAT files
# can be obtained here (http://hgdownload.cse.ucsc.edu/goldenPath/).
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
-jar !{params.picard} CollectRnaSeqMetrics \
INPUT="!{inBam}" \
OUTPUT="!{metrics}" \
REFERENCE_SEQUENCE="!{referenceFasta}" \
REF_FLAT="!{referenceRefFlat}" \
ASSUME_SORTED=true \
STRAND_SPECIFICITY=FIRST_READ_TRANSCRIPTION_STRAND \
VALIDATION_STRINGENCY=SILENT \
TMP_DIR="$TMPDIR"

clean_up $?
