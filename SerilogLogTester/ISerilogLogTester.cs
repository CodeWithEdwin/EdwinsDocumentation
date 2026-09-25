using Microsoft.Extensions.Logging;

namespace SerilogLogTester;

public interface ISerilogLogTester
{
    public void VerifyLogEventByMessage(LogLevel loglevel, string message);

    public void VerifyLogEventByMessage(LogLevel loglevel, string message, Exception exception);

    public void VerifyLogEventByMessageTemplate(LogLevel loglevel,
                      string messageTemplate,
                      params KeyValuePair<string, object?>[]? expectedLogProperties);

    public void VerifyLogEventByMessageTemplate(LogLevel loglevel,
                            string messageTemplate,
                            Exception exception,
                            params KeyValuePair<string, object?>[]? expectedLogProperties);

    public void VerifyScopeProperties(params KeyValuePair<object, object?>[] expected);
}