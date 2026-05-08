using Serilog.Core;
using Serilog.Events;

namespace SerilogLogTester;

public class PushPropertyLogEventSink() : ILogEventSink
{
    public List<LogEventProperty> Properties = [];

    public void Emit(LogEvent logEvent)
    {
        Properties = [.. logEvent.Properties.Select(p => new LogEventProperty(p.Key, p.Value))];
    }
}
