/**
 * A script that should be run by Nextflow at start up to make third party JAR files
 * available to the Nextflow pipeline.
 *
 * That's the theory. In practice, this doesn't work at all. The only solution that
 * does is to put the JAR files into the "lib" directory.
 * 
 * See https://nextflow.io/docs/latest/sharing.html#the-lib-directory
 * Also https://github.com/nextflow-io/nextflow/issues/5441
 *      https://github.com/nextflow-io/nextflow/issues/5234
 */

@GrabResolver(name='bioinformatics', root='https://content.cruk.cam.ac.uk/bioinformatics/maven')
@Grab('org.apache.commons:commons-csv:1.10.0')
@Grab('org.apache.commons:commons-lang3:3.17.0')
