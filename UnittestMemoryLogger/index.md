<< [Home](https://codewithedwin.github.io/EdwinsDocumentation/)

# SeriLog Logging unittesten
Als je in de code properties toevoegd aan de logging zoals hieronder:

`using var _ = LogContext.PushProperty("Regel", lineNumber);`

OF 

`using var temp = LogContext.PushProperty("ResponseHttpStatusCode", httpStatusCode);`

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
Dit is de class die de logevents opvangt.
Alle verify functies zijn nu specifiek om de Regel en ResponseHttpStatusCode properties te kunnen testen.
```
public class MemoryLogger : ILogEventSink
{
    private readonly ConcurrentBag<LogEvent> _loggedEvents = [];

    public void Emit(LogEvent logEvent)
    {
        _loggedEvents.Add(logEvent);
    }

    public List<LogEvent> LoggedEvents => [.. _loggedEvents];

    public void VerifyNumberOfLogEvents(int numberOfLogEvents) => _loggedEvents.Count.ShouldBe(numberOfLogEvents);

    public void VerifyLoggingExeption(LogLevel loglevel,
                             string messageTemplate,
                             string exceptionMessage,
                             params KeyValuePair<string, string>[]? expectedLogProperties)
    {
        expectedLogProperties ??= [];
        var expectedLogPropertiesList = expectedLogProperties.ToList();
        LoggedEvents.ShouldContain(s => s.Level.ToString().Equals(loglevel.ToString())
                                     && s.MessageTemplate.ToString().Equals(messageTemplate)
                                     && s.Exception != null
                                     && s.Exception.Message.ToString().Equals(exceptionMessage)
                                     && PropertiesAreEqual(s.Properties, expectedLogPropertiesList, false, false));
    }

    public void VerifyLoggingEvent(LogLevel loglevel,
                             string messageTemplate)
    {
        LoggedEvents.ShouldContain(s => s.Level.ToString().Equals(loglevel.ToString())
                                     && s.MessageTemplate.ToString().Equals(messageTemplate));
    }

    public void VerifyLoggingEvent(LogLevel loglevel,
                             string messageTemplate,
                             params KeyValuePair<string, string>[]? expectedLogProperties)
    {
        expectedLogProperties ??= [];
        var expectedLogPropertiesList = expectedLogProperties.ToList();
        LoggedEvents.ShouldContain(s => s.Level.ToString().Equals(loglevel.ToString())
                                     && s.MessageTemplate.ToString().Equals(messageTemplate)
                                     && PropertiesAreEqual(s.Properties, expectedLogPropertiesList, false, false));
    }

    public void VerifyLoggingEvent(LogLevel loglevel,
                          string messageTemplate,
                          HttpStatusCode responseHttpStatusCode,
                          params KeyValuePair<string, string>[]? expectedLogProperties)
    {
        expectedLogProperties ??= [];
        var expectedLogPropertiesList = expectedLogProperties.ToList();
        expectedLogPropertiesList.Add(new("ResponseHttpStatusCode", $"{responseHttpStatusCode}"));

        LoggedEvents.ShouldContain(s => s.Level.ToString().Equals(loglevel.ToString())
                                     && s.MessageTemplate.ToString().Equals(messageTemplate)
                                     && PropertiesAreEqual(s.Properties, expectedLogPropertiesList, true, false));
    }

    /// <summary>
    /// Let op: bewust gebruiken om een regelnummer te testen
    /// Deze wil je niet te vaak gaan gebruiken omdat iedere code aanpassing ertoe kan leiden dat heel veel testen omvallen
    /// </summary>
    /// <param name="loglevel"></param>
    /// <param name="messageTemplate"></param>
    /// <param name="regelnummer"></param>
    /// <param name="responseHttpStatusCode"></param>
    /// <param name="expectedLogProperties"></param>
    public void VerifyLoggingEvent(LogLevel loglevel,
                              string messageTemplate,
                              int regelnummer,
                              HttpStatusCode responseHttpStatusCode,
                              params KeyValuePair<string, string>[]? expectedLogProperties)
    {
        expectedLogProperties ??= [];
        var expectedLogPropertiesList = expectedLogProperties.ToList();
        expectedLogPropertiesList.Add(new("Regel", $"{regelnummer}"));
        expectedLogPropertiesList.Add(new("ResponseHttpStatusCode", $"{responseHttpStatusCode}"));

        LoggedEvents.ShouldContain(s => s.Level.ToString().Equals(loglevel.ToString())
                                     && s.MessageTemplate.ToString().Equals(messageTemplate)
                                     && PropertiesAreEqual(s.Properties, expectedLogPropertiesList, true, true));
    }

    public void VerifyNoLogging() => LoggedEvents.Count.ShouldBe(0);

    private static bool PropertiesAreEqual(IReadOnlyDictionary<string, LogEventPropertyValue> memoryLogProperties, List<KeyValuePair<string, string>> expectedLogProperties, bool verifyIfRegelnummerExists, bool verifyRegelnummerValue)
    {
        var memoryLogPropertiesList = memoryLogProperties
                                .Where(w => w.Key != "SourceContext") //SourceContext wordt automatisch gevuld door de logger en kan geskiped worden
                                .Select(kv => new KeyValuePair<string, string>(kv.Key,

                                        //ScalarValue gebruiken omdat een string anders een string met quotes en escapse bevat
                                        //We willen niet terug krijgen "\"waarde\"" maar "waarde"
                                        ((ScalarValue)kv.Value).Value?.ToString() ?? "<Geen Waarde>"))
                                .ToList();

        if (verifyIfRegelnummerExists && !verifyRegelnummerValue)
        {
            memoryLogPropertiesList.ShouldContain(l => l.Key == "Regel");
            memoryLogPropertiesList.Remove(memoryLogPropertiesList.First(l => l.Key == "Regel"));
        }

        return memoryLogPropertiesList.Count == expectedLogProperties.Count &&
            !memoryLogPropertiesList.Except(expectedLogProperties).Any() &&
            !expectedLogProperties.Except(memoryLogPropertiesList).Any();
    }
}
```

## MemoryLoggerHelper
Dit is een helper die er voor zorgt dat de MemoryLogger aan de Serilogging gekoppeld wordt en er een ILogger class wordt aangemaakt.
De Ilogger class moet je dan meegeven aan de functie, zoals dat met dependency injection ook normaliter gebeurt.
De MemoryLogger class moet gebruikt worden om de logging daadwerkelijk te controleren.

```
public class MemoryLoggerHelper
{
    public static ILogger<T> CreateMemoryLogger<T>(out MemoryLogger memoryLogger)
    {
        memoryLogger = new MemoryLogger();

        var serilogLogger = new LoggerConfiguration()
            .Enrich.FromLogContext()
            .WriteTo.Sink(memoryLogger)
            .CreateLogger();

        var loggerFactory = new LoggerFactory().AddSerilog(serilogLogger);
        return loggerFactory.CreateLogger<T>();
    }
}
```

## Voorbeeld TestMethode 
```
 [TestMethod]
 public void TryGetGeldigDeeljaarOpVoorOfNaPeildatum_WhenInputIsEmptyList_ReturnsFalseAndLogsWarning()
 {
     var _iLogger = MemoryLoggerHelper.CreateMemoryLogger<ToeslagenServiceHelper>(out var _memoryLogger);
     var serviceHelper = new ServiceHelper(_iLogger);
     var result = serviceHelper.TryGetGeldigDeeljaarOpVoorOfNaPeildatum([], _testHelper.PeildatumDateTime, ToeslagType.Huur, out var deeljaar, out var code);

     result.ShouldBe(false);
     deeljaar.ShouldBeNull();
     code.ShouldBe(HttpStatusCode.UnprocessableContent);

     _memoryLogger.VerifyNumberOfLogEvents(1);
     _memoryLogger.VerifyLoggingEvent(LogLevel.Warning,
       "Burger heeft geen toeslag van type {ToeslagType}. Er zijn geen relevante deeljaren gevonden.",
       HttpStatusCode.UnprocessableContent,
       new KeyValuePair<string, string>("ToeslagType", "Huur"));
 }
```

![image.png](https://codewithedwin.github.io/EdwinsDocumentation/UnittestMemoryLogger/WatchMemoryLogger.PNG)