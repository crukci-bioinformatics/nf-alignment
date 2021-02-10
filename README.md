## CRUK-CI Bioinformatics Alignment Pipeline - Nextflow version

This project is a rewrite of our alignment pipeline to perform the same tasks as
before but using Nextflow rather than our home-grown work flow system.

There are links in this document that will only work from within CRUK-CI. It is
not intended for external use.

### What It Does

This pipeline will align a set of FASTQ files using BWA, BWA-mem or STAR, single
read or paired end. It is supplied with a Singularity image to run the necessary
software. It requires a reference data structure for the genomes to align to as
documented [in the documentation for our reference data pipeline](http://internal-bioinformatics.cruk.cam.ac.uk/docs/referencegenomes/main.html).

### How It Works

Files are aligned using the requested aligner into BAM files, sorted by co-ordinate,
PCR duplicates marked (optional), and alignment metrics calculated. The pipeline can
then optionally merge files belonging to the same sample into one BAM per sample,
which then also have alignment metrics generated for them. Then, optionally,
_bedgraph_ and _bigwig_ coverage files are generated.

### Running the Pipeline

The pipeline requires Nextflow to be available on your system. Instructions for
installing Nextflow can be [found on the Nextflow web site](https://www.nextflow.io/docs/latest/getstarted.html#installation).
The rest of this document assumes the downloaded `nextflow` script is on the path.

Within CRUK-CI we have tools for helping with assembling FASTQ files. The
[kick start application](http://internal-bioinformatics.cruk.cam.ac.uk/docs/kickstart)
will fetch FASTQ files from the sequencing archive onto local disk and create a
CSV file with the information about the files in the project directory (a file called
`alignment.csv`) necessary to run this pipeline.

Alternatively, one can create a folder structure containing a folder `fastq`, into
which the FASTQ files should be put. The kick start application can be run in
"stand alone" mode, which will extract groups and some information from the files'
names to create the CSV file for this pipeline.

After assembling the data, the alignment pipeline needs a little more configuration.
Create a file `alignment.config` in the project directory. This is additional Nextflow
configuration that cannot be defined in the main pipeline, as it is specific to your
data. The file should contain:

```
params {
    species = <species folder name>
    shortSpecies = <species abbreviation>
    assembly = <assembly name>

    aligner = <aligner name>
    endType = <single | paired>
}
```

This is the minimal information needed by the pipeline to run. It defines the genome
to align to, the aligner to use, and whether to do single or paired end alignment.

With the FASTQ data available, `alignment.csv` created and `alignment.config`
set the pipeline can actually be run.

```
nextflow run crukci-bioinformatics/nf-alignment
```

That is it. It will align all the FASTQ files (or file pairs) into BAM files, placing
them into a directory `bams` in the project directory.


### Controlling the Pipeline

This simple case is the minimum one can run to turn FASTQ into BAM. However, it is
unlikely to be exactly as one wants, nor will it run by the best method available.

#### Profiles

With no other option provided, the pipeline runs using the "standard" profile. This is
suitable for a reasonably beefy desktop machine, and was set based on my personal Linux
desktop PC (20 out of 32GB RAM, 6 out of 8 cores). This profile will be used when no
alternative is selected.

There are two other profiles defined. "bioinf" is for our (Bioinformatics core)
_bioinf-srv008_ server, allowing the pipeline 28 cores and up to 180GB RAM. "cluster" is
for the CRUK-CI cluster, using Slurm to run parallel jobs across the cluster.

Add the `-profile` Nextflow command line option to choose the profile. Thus the command
line might become:

```
nextflow run crukci-bioinformatics/nf-alignment -profile cluster
```

#### Additional Configuration

The first flags that one can change are the controls for PCR duplicate marking, sample
merging and coverage file creation. These can be added to `alignment.config` thus
(between the curly brackets):

```
    markDuplicates = true | false
    mergeSamples =   true | false
    createCoverage = true | false
```

`markDuplicates` simply turns on or off PCR duplicate marking. `mergeSamples`, when
turned on, extends the pipeline to merge FASTQ files into a file per unique sample
in `alignment.csv`. `createCoverage` only applies after sample merging and creates
_bedgraph_ and _bigwig_ files for each sample BAM file.

Sample bam files are put into a directory `samplebams` in the project directory. The
coverage files are also put into this directory alongside the BAM files.

#### Command Line Switches

All of the parameters defined in `alignment.config` can be overridden on the command
line. Nextflow accepts double dash switches to set parameters using the same names as
provided in `alignment.config`. For example, to turn on sample BAM creation as a one
off, one can use:

```
nextflow run crukci-bioinformatics/nf-alignment --mergeSamples=true
```

Command line switches override values defined in `alignment.config`.

