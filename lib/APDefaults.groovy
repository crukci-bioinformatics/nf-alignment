/**
 * The methods in this class are a way of defaulting parameters. The params object is immutable
 * in code, so we need to test and resolve each time the value is asked for.
 */
class APDefaults
{
    /**
     * Function for determining whether single or paired end.
     * 
     * @param params The Nextflow params object.
     * return True if the alignment is paired end, false if single read.
     */
    boolean pairedEnd(params)
    {
        char first = params.endType.toLowerCase()[0]
    
        if (first == 's')
        {
            return false
        }
        else if (first == 'p')
        {
            return true
        }
        else
        {
            throw new IllegalArgumentException("End type must be given to indicate single read (se/sr) or paired end (pe).")
        }
    }
    
    /**
     * Function for getting RNA-Seq strand specificity. When there is nothing
     * defined (the default), defaults to the appropriate value for single
     * or paired end. When explicitly defined, return that.
     * 
     * @param params The Nextflow params object.
     * @return The RNA-Seq strand specificity for Picard.
     */
    String rnaseqStrandSpecificity(params)
    {
        if (params.rnaseqStrandSpecificity == '')
        {
            return pairedEnd() ? 'SECOND_READ_TRANSCRIPTION_STRAND' : 'FIRST_READ_TRANSCRIPTION_STRAND'
        }
        return params.rnaseqStrandSpecificity.toUpperCase()
    }
    
    
    /**
     * Get the path to the reference FASTA file.
     * 
     * @param params The Nextflow params object.
     * @return The FASTQ reference path.
     */
    String fastaReferencePath(params)
    {
        if (params.containsKey('referenceFasta'))
        {
            return params.referenceFasta
        }
    
        params.with
        {
            return "${referenceRoot}/${species}/${assembly}/fasta/${shortSpecies}.${assembly}.fa"
        }
    }
    
    /**
     * Get the path to the genome sizes file.
     * 
     * @param params The Nextflow params object.
     * @return The genome sizes path.
     */
    String genomeSizesPath(params)
    {
        if (params.containsKey('genomeSizes'))
        {
            return params.genomeSizes
        }
    
        params.with
        {
            return "${referenceRoot}/${species}/${assembly}/fasta/${shortSpecies}.${assembly}.sizes"
        }
    }
    
    /**
     * Get the path to the reference RefFlat file.
     * 
     * @param params The Nextflow params object.
     * @return The RefFlat path.
     */
    String referenceRefFlatPath(params)
    {
        if (params.containsKey('referenceRefFlat'))
        {
            return params.referenceRefFlat
        }
    
        params.with
        {
            return "${referenceRoot}/${species}/${assembly}/annotation/${shortSpecies}.${assembly}.txt"
        }
    }
    
    /**
     * Get the path to the BWA index file.
     * 
     * @param params The Nextflow params object.
     * @return The BWA index path.
     */
    String bwaIndexPath(params)
    {
        if (params.containsKey('bwaIndex'))
        {
            return params.bwaIndex
        }
    
        params.with
        {
            return "${referenceRoot}/${species}/${assembly}/bwa-${bwaVersion}/${shortSpecies}.${assembly}"
        }
    }
    
    /**
     * Get the path to the BWA-mem2 index file.
     * 
     * @param params The Nextflow params object.
     * @return The BWA-mem2 index path.
     */
    String bwamem2IndexPath(params)
    {
        if (params.containsKey('bwamem2Index'))
        {
            return params.bwamem2Index
        }
    
        params.with
        {
            return "${referenceRoot}/${species}/${assembly}/bwamem2-${bwamem2Version}/${shortSpecies}.${assembly}"
        }
    }
    
    /**
     * Get the path to the Bowtie2 index file.
     * 
     * @param params The Nextflow params object.
     * @return The Bowtie2 index path.
     */
    String bowtie2IndexPath(params)
    {
        if (params.containsKey('bowtie2Index'))
        {
            return params.bwamem2Index
        }
    
        params.with
        {
            return "${referenceRoot}/${species}/${assembly}/bowtie2-${bowtie2Version}/${shortSpecies}.${assembly}"
        }
    }
    
    /**
     * Get the path to the STAR index directory.
     * 
     * @param params The Nextflow params object.
     * @return The STAR index path.
     */
    String starIndexPath(params)
    {
        if (params.containsKey('starIndex'))
        {
            return params.starIndex
        }
    
        params.with
        {
            return "${referenceRoot}/${species}/${assembly}/star-${starVersion}"
        }
    }
}
