import nextflow.util.BlankSeparatedList

/**
 * Utilities for the alignment pipeline.
 */
class APUtils
{
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
