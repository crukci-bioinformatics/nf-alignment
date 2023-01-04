## CRUK-CI Bioinformatics Alignment Pipeline - Nextflow version

This project is a rewrite of our alignment pipeline to perform the same tasks as
before but using Nextflow rather than our home-grown work flow system.

_There are links in this document that will only work from within CRUK-CI. It is
not intended for external use._

### What It Does

This pipeline will align a set of FASTQ files using BWA, BWA-mem or STAR, single
read or paired end. It is supplied with a Singularity image to run the necessary
software. It requires a reference data structure for the genomes to align to as
documented [in the documentation for our reference data pipeline](https://internal-bioinformatics.cruk.cam.ac.uk/docs/referencegenomes/main.html).

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
[kick start application](https://internal-bioinformatics.cruk.cam.ac.uk/docs/nf-kickstart)
will fetch FASTQ files from the sequencing archive onto local disk and create a
CSV file with the information about the files in the project directory (a file called
`alignment.csv`) necessary to run this p1ipeline.

Alternatively, one can create a folder structure containing a folder `fastq`, into
which the FASTQ files should be put. The kick start application can be run in
"stand alone" mode, which will extract groups and some information from the files'
names to create the CSV file for this pipeline.

After assembling the data, the alignment pipeline needs a little more configuration.
Create a file `nextflow.config` in the project directory. This is additional Nextflow
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

With the FASTQ data available, `alignment.csv` created and `nextflow.config`
set the pipeline can actually be run.

```
nextflow run crukci-bioinformatics/nf-alignment
```

That is it. It will align all the FASTQ files (or file pairs) into BAM files, placing
them into a directory `bam` in the project directory.

**Note** `nextflow.config` is the default file for folder specific configuration.
You can have any number of these with different names and can select them with
Nextflow's `-c` option on the `run` command.

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
merging and coverage file creation. These can be added to `nextflow.config` thus
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

Sample bam files are put into a directory `samplebam` in the project directory. The
coverage files are also put into this directory alongside the BAM files.

Additional metrics are available for the aligned files. The pipeline can be configured
to provide alignment metrics, insert size metrics, RNA-seq metrics
and whole genome sequencing (WGS) metrics. These are controlled by additional parameters
in `nextflow.config`.

```
    alignmentMetrics =  true | false   /* Default true  */
    insertSizeMetrics = true | false   /* Default true  */
    rnaseqMetrics =     true | false   /* Default false */
    wgsMetrics =        true | false   /* Default false */
```

Insert size metrics are only relevant for paired end alignments, so when aligning
single end the switch above has no effect: they will not be produced.

#### Command Line Switches

All of the parameters defined in `nextflow.config` can be overridden on the command
line. Nextflow accepts double dash switches to set parameters using the same names as
provided in `nextflow.config`. For example, to turn on sample BAM creation as a one
off, one can use:

```
nextflow run crukci-bioinformatics/nf-alignment --mergeSamples=true
```

Command line switches override values defined in `nextflow.config`.

#### Further Configuration

`nextflow.config` is a full part of the
[Nextflow configuration](https://www.nextflow.io/docs/latest/config.html).
As such, and assuming one knows what one is doing, it can include any additional
configuration documented in the Nextflow pages, such as
[email notification](https://www.nextflow.io/docs/latest/config.html#scope-mail),
[tuning processes](https://www.nextflow.io/docs/latest/config.html#scope-process) or
[custom profiles](https://www.nextflow.io/docs/latest/config.html#config-profiles).


### Reference Data

The pipeline expects reference data to be set up in the structure defined by
[our reference data pipeline](https://internal-bioinformatics.cruk.cam.ac.uk/docs/referencegenomes/main.html).
The profiles have default paths for the root location of this structure for use on our
cluster and Bioinformatics core server. For the "standard" profile on one's local
machine, the reference root should be defined in `nextflow.config`.

```
params {
    referenceRoot = '/home/reference_data'
}
```

The default "standard" location is the cluster references, which require the directories
to be network mounted on one's desktop. That is a handy short cut but not suitable for
all.

One can set explicit parameters outside a standard structure for reference data:

1. `referenceFasta`: The path to the reference FASTA file. Always needed.
2. `genomeSizes`: The path to the file listing the sizes of the chromosomes and contigs
in the reference. Only needed if creating coverage files.
3. `referenceRefFlat`: Annotations for the reference FASTA file in RefFlat format.
Only needed if calculating RNA-seq metrics.
4. `bwaIndex`: The path and prefix to the BWA reference. Only needed when running classic BWA.
5. `bwamem2Index`: The path and prefix to the BWAmem2 reference. Only needed when running BWAmem2.
6. `starIndex`: The path to the STAR reference directory. Only needed when running STAR.

### Singularity Cache

The alignment pipeline will fetch the container image it needs from DockerHub automatically.
It is placed in Nextflow's `work` directory by default for each project where you are using
the alignment pipeline. It is better to create a common directory elsewhere for Nextflow to
use so it doesn't fetch the (not small) image every time. This can be done by setting the
`NXF_SINGULARITY_CACHEDIR` environment variable on the command line, or more practically
in your `.bash_profile`.

```
export NXF_SINGULARITY_CACHEDIR=/data/my_nextflow_singularity_cache
```

### Content of `alignment.csv`

The `alignment.csv` file drives the alignment pipeline. It lists FASTQ files or file
pairs, samples to whom those files belong, and additional information that can be added
to the aligned files as read group annotations.

At CRUK-CI, we have the
[kick start application](https://internal-bioinformatics.cruk.cam.ac.uk/docs/nf-kickstart)
to help with this.

#### `alignment.csv` Columns

The order of the columns does not matter in this file, but the name of the columns
(the first row) is required. There may be additional columns in this file but these
are the ones used by the pipeline.

##### "Read1", "Read2"

These columns are required. "Read1" is the name of the single or first read FASTQ files;
"Read2" is the name of the second read for paired end data. "Read2" can be left blank
for single read data (it will not be read).

##### "SampleName"

The "SampleName" column defines the sample name each FASTQ file belongs to. This column
becomes required when the `--mergeSamples` option is used. All aligned files that
have the same sample name can be merged together into one BAM file for that sample.
Ideally, one should avoid special characters in sample names: the sample name becomes
the base of the file name.

##### "ReadGroup"

The read group id for the file. If not defined, a default of "Z" is used.

##### "Library"

Read group library id. Defaults to "Unknown" if not set.

##### "SourceMaterial"

Read group source material, or sample. Defaults to "Not available" if not set.

##### "PlatformUnit"

Read group platform unit. Defaults to "Not available" if not set.

##### "SequencingPlatform"

Read group sequencing platform. Defaults to "Unknown" if not set.

##### "PlatformModel"

Read group platform model. Optional.

##### "SequencingCentre"

Read group sequencing centre. Optional.

##### "SequencingDate"

Read group sequencing date. Optional. If given, is must be in the format `yyyy-mm-dd`.
