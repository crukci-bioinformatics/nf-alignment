def logException(e)
{
    def forLogging = e
    try
    {
        throw e
    }
    catch (java.lang.reflect.InvocationTargetException ite)
    {
        forLogging = e.targetException
    }
    catch (Throwable t)
    {
    }

    def sw = new StringWriter(1000)
    def pw = new PrintWriter(sw)
    forLogging.printStackTrace(pw)
    log.error sw.toString()
    throw e
}
