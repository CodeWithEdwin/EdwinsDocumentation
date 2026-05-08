using Microsoft.Extensions.Logging;
using Serilog.Events;

namespace SerilogLogTester;

public class SerilogLogTesterEvent(DateTimeOffset timestamp, LogLevel logLevel, Exception? exception,
    string messageTemplate, string message, List<LogEventProperty> properties)
{
    public DateTimeOffset Timestamp { get; set; } = timestamp;
    public LogLevel LogLevel { get; set; } = logLevel;
    public Exception? Exception { get; set; } = exception;
    public string MessageTemplate { get; set; } = messageTemplate;

    public string Message { get; set; } = message;
    public List<LogEventProperty> Properties { get; set; } = properties;
}
