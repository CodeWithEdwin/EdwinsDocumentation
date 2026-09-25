using Microsoft.Extensions.Logging;
using Shouldly;

namespace SerilogLogTester;

public static class SerilogLogTesterExtenstions
{
    public static void VerifyLogEventByMessage(this IEnumerable<ISerilogLogTester> serilogLoggers,
                                                LogLevel loglevel,
                                                string message)
        => VerifySerilogLog(serilogLoggers, serilogLogger => serilogLogger.VerifyLogEventByMessage(loglevel, message));


    public static void VerifyLogEventByMessage(this IEnumerable<ISerilogLogTester> serilogLoggers,
                                                LogLevel loglevel,
                                                string message,
                                                Exception exception)
        => VerifySerilogLog(serilogLoggers, serilogLogger => serilogLogger.VerifyLogEventByMessage(loglevel, message, exception));


    public static void VerifyLogEventByMessageTemplate(this IEnumerable<ISerilogLogTester> serilogLoggers,
                                                        LogLevel loglevel,
                                                        string message,
                                                        params KeyValuePair<string, object?>[]? expectedLogProperties)
        => VerifySerilogLog(serilogLoggers, serilogLogger => serilogLogger.VerifyLogEventByMessageTemplate(loglevel, message, expectedLogProperties));


    public static void VerifyLogEventByMessageTemplate(this IEnumerable<ISerilogLogTester> serilogLoggers,
                                                        LogLevel loglevel,
                                                        string message,
                                                        Exception exception,
                                                        params KeyValuePair<string, object?>[]? expectedLogProperties)
        => VerifySerilogLog(serilogLoggers, serilogLogger => serilogLogger.VerifyLogEventByMessageTemplate(loglevel, message, exception, expectedLogProperties));

    public static void VerifyScopeProperties(this IEnumerable<ISerilogLogTester> serilogLoggers,
                                            params KeyValuePair<object, object?>[] expected)
         => VerifySerilogLog(serilogLoggers, serilogLogger => serilogLogger.VerifyScopeProperties(expected));

    private static void VerifySerilogLog(
                            IEnumerable<ISerilogLogTester> serilogLoggers,
                            Action<ISerilogLogTester> verifyAction)
    {
        var found = false;
        foreach (var serilogLogger in serilogLoggers)
        {
            try
            {
                verifyAction(serilogLogger);
            }
            catch (ShouldAssertException)
            {
                continue;
            }

            found.ShouldBeFalse();
            found = true;
        }

        found.ShouldBeTrue();
    }
}