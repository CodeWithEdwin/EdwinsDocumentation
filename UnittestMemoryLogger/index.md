<< [Home](https://codewithedwin.github.io/EdwinsDocumentation/)

# SeriLog Logging unittesten
Als je in de code properties toevoegd aan de logging zoals hieronder:

```
using var _ = LogContext.PushProperty("Regel", lineNumber);
```
OF 

```
using var temp = LogContext.PushProperty("ResponseHttpStatusCode", httpStatusCode);
```

OF

```
using var _ = _logger.BeginScope(new Dictionary<string, object>
 {
     ["test"] = "aap"
 });
```

Dan kun je deze niet testen met een Mock, die ondersteunt dit niet.
Met de zgn [Fakelogger](https://learn.microsoft.com/en-us/dotnet/api/microsoft.extensions.logging.testing.fakelogger-1?view=net-9.0-pp) kunnen deze properties ook niet uitgelezen worden:

![image.png](https://codewithedwin.github.io/EdwinsDocumentation/UnittestMemoryLogger/FakeLogger.png)

Daarvoor kun je dit testen door de logging op te vangen in een class en deze vervolgens te gaan testen.
Dat gaat op de volgende manier

## MemoryClass
Dit is een class die de logevents opvangt. De class is opgedeeld in partial classes.
Alle verify functies zijn nu specifiek om de Regel en ResponseHttpStatusCode properties te kunnen testen.

###  MemoryLoggerCore.cs
```
using Microsoft.Extensions.Logging;
using Serilog.Events;
using Serilog.Parsing;
using System.Collections.Concurrent;
using System.Diagnostics.CodeAnalysis;

namespace KBS.TSK.Tests.Common.Logger;

[ExcludeFromCodeCoverage]
public partial class MemoryLogger<T> : ILogger<T>
{
    internal ConcurrentBag<MemoryLoggerEvent> LoggedEvents = [];
    internal ConcurrentBag<KeyValuePair<string, string>> Scopes = [];

    public IDisposable BeginScope<TState>(TState state) where TState : notnull
    {
        if (state is Dictionary<string, string> dict)
        {
            dict.ToList().ForEach(kv => Scopes.Add(new KeyValuePair<string, string>(kv.Key, kv.Value)));
        }

        return Stream.Null;
    }

    public void Log<TState>(LogLevel logLevel, EventId eventId, TState state, Exception? exception,
        Func<TState, Exception?, string> formatter) => CaptureLog(logLevel, state, exception);

    internal void CaptureLog<TState>(LogLevel level, TState state, Exception? exception)
    {
        if (state == null! || string.IsNullOrWhiteSpace(state.ToString()))
        {
            return;
        }

        var properties = new List<LogEventProperty>();
        if (state is IEnumerable<KeyValuePair<string, object>> kvps)
        {
            properties.AddRange(
                kvps
                .Where(kvp => kvp.Key != "{OriginalFormat}")
                .Select(kvp => new LogEventProperty(kvp.Key, new ScalarValue(kvp.Value)))
            );
        }

        var message = new MessageTemplateParser().Parse(state.ToString() ?? "");

        var logEvent = new MemoryLoggerEvent(
            DateTimeOffset.Now,
            level,
            exception,
            message,
            properties
        );

        LoggedEvents.Add(logEvent);
    }

    public bool IsEnabled(LogLevel logLevel) => true;
}
```

### MemoryLoggerValidation.cs
```
using Microsoft.Extensions.Logging;
using Serilog.Events;
using Shouldly;

namespace KBS.TSK.Tests.Common.Logger;

public partial class MemoryLogger<T>
{
    public void VerifyLoggingEvent(LogLevel loglevel,
                         string messageTemplate,
                         params KeyValuePair<string, string>[]? expectedLogProperties)
    {
        expectedLogProperties ??= [];
        var expectedLogPropertiesList = expectedLogProperties.ToList();
        LoggedEvents.ShouldContain(s => s.LogLevel.Equals(loglevel)
            && s.MessageTemplate.ToString().Equals(messageTemplate)
            && PropertiesAreEqual(s.Properties, expectedLogPropertiesList));
    }

    public void VerifyLoggingEvent(LogLevel loglevel,
                             string messageTemplate,
                             string exceptionMessage,
                             params KeyValuePair<string, string>[]? expectedLogProperties)
    {
        expectedLogProperties ??= [];
        var expectedLogPropertiesList = expectedLogProperties.ToList();
        LoggedEvents.ShouldContain(s => s.LogLevel.Equals(loglevel)
                                     && s.MessageTemplate.ToString().Equals(messageTemplate)
                                     && s.Exception != null
                                     && s.Exception.Message.ToString().Equals(exceptionMessage)
                                     && PropertiesAreEqual(s.Properties, expectedLogPropertiesList));
    }

    public void VerifyNumberOfLogEvents(int numberOfLogEvents) => LoggedEvents.Count.ShouldBe(numberOfLogEvents);

    public void VerifyNoLogging() => LoggedEvents.Count.ShouldBe(0);

    public void VerifyScopeProperties(Dictionary<string, string> expected) => expected.All(kv =>
        Scopes.Any(s => s.Key == kv.Key && s.Value == kv.Value)).ShouldBeTrue();

    public void VerifyNumberOfScopeLogs(int numberOfLogEvents) => Scopes.Count.ShouldBe(numberOfLogEvents);

    public void VerifyNoScope() => Scopes.Count.ShouldBe(0);

    private static bool PropertiesAreEqual(List<LogEventProperty> memoryLogProperties, List<KeyValuePair<string, string>> expectedLogProperties)
    {
        var memoryLogPropertiesList = memoryLogProperties
                                .Where(w => w.Name is not "SourceContext" and not "Scope")
                                //SourceContext wordt automatisch gevuld door de logger en kan geskiped worden
                                .Select(kv => new KeyValuePair<string, string>(kv.Name,

                                        //ScalarValue gebruiken omdat een string anders een string met quotes en escapse bevat
                                        //We willen niet terug krijgen "\"waarde\"" maar "waarde"
                                        ((ScalarValue)kv.Value).Value?.ToString() ?? "<Geen Waarde>"))
                                .ToList();

        return memoryLogPropertiesList.Count == expectedLogProperties.Count &&
            !memoryLogPropertiesList.Except(expectedLogProperties).Any() &&
            !expectedLogProperties.Except(memoryLogPropertiesList).Any();
    }
}
```

### MemoryLoggerEvent.cs
```
using Microsoft.Extensions.Logging;
using Serilog.Events;
using System.Diagnostics.CodeAnalysis;

namespace KBS.TSK.Tests.Common.Logger;

[ExcludeFromCodeCoverage]
public class MemoryLoggerEvent
{
    public MemoryLoggerEvent(DateTimeOffset timestamp, LogLevel logLevel, Exception? exception,
        MessageTemplate messageTemplate, List<LogEventProperty> properties)
    {
        Timestamp = timestamp;
        LogLevel = logLevel;
        Exception = exception;
        MessageTemplate = messageTemplate;
        Properties = properties;
    }

    public DateTimeOffset Timestamp { get; set; }
    public LogLevel LogLevel { get; set; }
    public Exception? Exception { get; set; }
    public MessageTemplate MessageTemplate { get; set; }
    public List<LogEventProperty> Properties { get; set; }
}
```

### LET OP!
Bij gebruik van bijv. de BeginScope wordt hetgeen gedefinieerd toegevoegd aan de logging zolang deze in scope is.
```
using var _ = _logger.BeginScope(new Dictionary<string, object>
 {
     ["test"] = "aap"
 });
```

Bij de Memorylogger wordt er geen rekening gehouden of deze wel of niet in scope is.
Dat wil zeggen dat zodra de BeginScope aangeroepen wordt, wordt dit in de MemoryLogger geregistreerd en daar blijft het staan.
Er vindt alleen maar een registratie plaats dat scope is aangeroepen.