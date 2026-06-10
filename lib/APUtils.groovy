/**
 * Utilities for the alignment pipeline.
 *
 * <p>
 * Java/Groovy imports are not permitted in strict-parser Nextflow scripts,
 * so the Apache Commons CSV logic that validates the alignment.csv file lives
 * here and is called as a static method from configuration.nf.
 * </p>
 */

import nextflow.util.BlankSeparatedList
import org.apache.commons.csv.CSVFormat
import org.apache.commons.csv.CSVParser

class APUtils
{
    /**
     * Check that the alignment CSV file exists, is readable, and contains the
     * columns required by the current pipeline configuration.
     *
     * @param params      The Nextflow params object.
     * @param pairedEnd   {@code true} when running in paired-end mode.
     * @param log         The Nextflow log object for error reporting.
     * @return {@code true} when the file passes all checks, {@code false} otherwise.
     */
    static boolean checkAlignmentCSV(params, boolean pairedEnd, log)
    {
        def ok = true

        try
        {
            def driverFile = new File(params.alignmentCSV.toString())

            driverFile.withReader('UTF-8')
            {
                stream ->

                def parser = CSVParser.parse(stream, CSVFormat.DEFAULT.withHeader())
                def first = true

                for (record in parser)
                {
                    if (first)
                    {
                        if (!record.isMapped('Read1'))
                        {
                            log.error "${params.alignmentCSV} must contain a column 'Read1'."
                            ok = false
                        }
                        if (pairedEnd && !record.isMapped('Read2'))
                        {
                            log.error "${params.alignmentCSV} must contain a column 'Read2' for aligning paired end."
                            ok = false
                        }
                        if (params.mergeSamples && !record.isMapped('SampleName'))
                        {
                            log.error "${params.alignmentCSV} must contain a column 'SampleName' when sample merging is requested."
                            ok = false
                        }
                        first = false
                        if (!ok)
                        {
                            break
                        }
                    }

                    def rowNum = parser.recordNumber + 1
                    if (!record.get('Read1'))
                    {
                        log.error "No 'Read1' file name set on line ${rowNum}."
                        ok = false
                    }
                    if (pairedEnd && !record.get('Read2'))
                    {
                        log.error "No 'Read2' file name set on line ${rowNum}."
                        ok = false
                    }
                    if (params.mergeSamples && !record.get('SampleName'))
                    {
                        log.error "No 'SampleName' defined on line ${rowNum}."
                        ok = false
                    }
                }
            }
        }
        catch (Exception e)
        {
            log.error "Error reading alignment CSV '${params.alignmentCSV}': ${e.message}"
            ok = false
        }

        return ok
    }

    /**
     * Create a {@link BlankSeparatedList} from the given items.
     *
     * <p>Used in BWA shell templates where file lists must be rendered as
     * space-separated strings without the square brackets that a regular
     * Groovy list would produce.</p>
     *
     * @param items The items to collect into a blank-separated list.
     * @return A {@code BlankSeparatedList} wrapping the given items.
     */
    static BlankSeparatedList blankSepList(Object... items)
    {
        return new BlankSeparatedList(items)
    }
}
