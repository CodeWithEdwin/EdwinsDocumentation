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

# Bestanden
De volgende bestanden zijn nodig om de SerilogLogTester vorm te geven:
- [SerilogLogTester_Core.cs](./SerilogLogTester/SerilogLogTester_Core.cs)
- [SerilogLogTester_Validations.cs](./SerilogLogTester/SerilogLogTester_Validations.cs)
- [SerilogLogTesterEvent.cs](./SerilogLogTester/SerilogLogTesterEvent.cs)
- [PushPropertyLogEventSink.cs](./SerilogLogTester/PushPropertyLogEventSink.cs)

De volgende nuget packages zijn hiervoor nodig:
- SeriLog
- Shouldly

# SerilogLogTester
De `SerilogLogTester` class is geintroduceerd omdat het niet mogelijk is met huidige oplossingen om de functie `BeginScope` afdoende te testen.
Met `SerilogLogTester` is het mogelijk om zowel logmessages als `BeginScope` te verifiëren.
Met de `SerilogLogTester` class wordt een `Ilogger` gemaakt, het is hierdoor mogelijk deze te gebruiken als mock voor de serilog in bijv. unittesten.
Hieronder is beschreven per functie hoe deze werkt/wat deze doet.

## Validatie functies
De `SerilogLogTester` heeft een aantal validatiefuncties.

Het is hierbij belangrijk te begrijpen wat het verschil is tussen de log message en het message template.

Stel de volgende logregel wordt weggeschreven: 
```Csharp
 logger.LogWarning("Logmessage {property}", "propertyWaarde");
```
Het message template (in splunk de property @mt) is hierbij: _Logmessage {property}_.
De log message hierbij is het template gevuld met waarden (denk aan string.format), de log message is dan: _Logmessage propertyWaarde_.

De volgende validatie functies:
| Functie | Toelichting |
|--|--|
| VerifyNoLogging() | Hiermee wordt gevalideerd dat er geen enkele logregel is weggeschreven. |
| VerifyNoScopeLogProperties() | Hiermee wordt gevalideerd dat er geen enkele BeginScope properties zijn weggeschreven. |
| VerifyLogEventByMessage(LogLevel loglevel, string message, Exception exception, params KeyValuePair<string, string>[]? expectedLogProperties) | Hiermee kan een logregel op basis van het message met een exception gevalideerd worden.|
| VerifyLogEventByMessage(LogLevel loglevel, string message, params KeyValuePair<string, string>[]? expectedLogProperties) | Hiermee kan een logregel op basis van het message zonder een exception gevalideerd worden.|
| VerifyLogEventByMessageTemplate(LogLevel loglevel, Exception exception, string message,params KeyValuePair<string, string>[]? expectedLogProperties) | Hiermee kan een logregel op basis van het message template met een exception gevalideerd worden.|
| VerifyLogEventByMessageTemplate(LogLevel loglevel, string message, params KeyValuePair<string, string>[]? expectedLogProperties) | Hiermee kan een logregel op basis van het message template zonder een exception gevalideerd worden.|
| VerifyNumberOfLogEvents(int numberOfLogEvents) | Hiermee kan het totaal aantal logregels die geschreven zijn gevalideerd worden.|
| VerifyNumberOfScopeLogProperties(int numberOfLogEvents) | Hiermee wordt gevalideerd hoeveel properties er met BeginScope zijn weggeschreven. |

## BeginScope
Bij iedere aanroep van BeginScope wordt in de `SerilogLogTester` de waarden opgeslagen in de vorm van van keyvaluepairs, die vervolgens weer te valideren zijn.
Normaliter in serilog worden de BeginScope waarden toegevoegd aan de logmessages, zolang de BeginScope niet disposed is.
De `SerilogLogTester` handelt anders, iedere aanroep van BeginScope wordt los van de logmessages geregisteerd.
De logmessage en BeginScope zijn onafhankelijke events, waardoor het niet mogelijk is deze te combineren in de `SerilogLogTester`. 
Het is namelijk niet mogelijk te traceren wanneer de BeginScope disposed is of niet.
Bij de BeginScope van serilog zijn verschillende aanroepen mogelijk. De `SerilogLogTester` vangt er een aantal op, die hier toegelicht worden.

### Ilogger.BeginScope(string messageFormat, params object[]? args)
Met deze functie kan een bepaald message toegevoegd worden aan de logregels door een `messageFormat` te gebruiken en de waarden te vullen in via de `args`.
Een voorbeeld:

```Csharp
var propertyWaarde = "propertyWaarde"
using var _ = logger.BeginScope("De waarde is: {propertyName}", propertyWaarde);
``` 
In de `SerilogLogTester` kan deze `BeginScope` gevalideerd worden door:

```csharp
serilogLogTester.VerifyScopeProperties([new("{MessageFormat}", "De waarde is: {propertyName}"), new("propertyName", "propertyWaarde")]);
```
Door de `SerilogLogTester` wordt het messageFormat opgeslagen met de key `{MessageFormat}`.

### Ilogger.BeginScope<Dictionary<string, string>>(Dictionary<string, string> state)
Met deze functie kunnen properties en waarden toegevoegd worden aan de logregels.
Een voorbeeld:
```Csharp
 var scope = new Dictionary<string, string>
 {
     { "property1", "propertyWaarde1" },
     { "property2", "propertyWaarde2" }
 };

 using var _ = logger.BeginScope(scope);
```

In de `SerilogLogTester` kan deze `BeginScope` gevalideerd worden door:

```Csharp
 serilogLogTester.VerifyScopeProperties([new("property1", "propertyWaarde1"),
                                         new("property2", "propertyWaarde2")]);
```

### Ilogger.BeginScope(string state)
Met deze functie kan een specifieke string toegevoegd worden aan de logregels.
Een voorbeeld:
```Csharp
using var _ = logger.BeginScope("LogScopeMessage");
```
In de `SerilogLogTester` kan deze `BeginScope` gevalideerd worden door:

```Csharp
serilogLogTester.VerifyScopeProperties([new("{Message}", "LogScopeMessage")]);
```
Door de `SerilogLogTester` wordt de string opgeslagen met een key `{Message}`.

## LogContext.PushProperty
Met serilog is het ook mogelijk om properties toe te voegen aan logregels door gebruik te maken van de functie `LogContext.PushProperty`.
Normaliter in serilog worden de PushProperty waarden toegevoegd aan de logmessages, zolang de PushProperty niet disposed is.
De `SerilogLogTester` registeert PushProperty, in tegenstelling tot de BeginScope, pas als er ook daadwerkelijk een logregel wordt weggeschreven.
Er kan geen event opgevangen worden om deze `LogContext.PushProperty` specifiek te registeren.
Het property dat toegevoegd wordt door `LogContext.PushProperty` wordt in de `SerilogLogTester` geregistreerd, bij het logmessage, zolang deze niet disposed is.

In onderstaand voorbeeld registeert de `SerilogLogTester` de `LogContext.PushProperty`doordat er een logregel wordt weggeschreven:
```Csharp
 using (LogContext.PushProperty("property", "propertyWaarde"))
 {
     logger.LogInformation("Logmessage {Nummer}","1");
 }
 ```

De `LogContext.PushProperty` kan met  `SerilogLogTester` op de volgende manieren gecontroleerd worden:
```Csharp
serilogLogTester.VerifyLogEventByMessageTemplate(LogLevel.Information, "Logmessage {Nummer}", [new("property", "propertyWaarde"),new("Nummer", "1")]);
serilogLogTester.VerifyLogEventByMessage(LogLevel.Information, "Logmessage 1", [new("property", "propertyWaarde"),new("Nummer", "1")]);
 ```

In onderstaand voorbeeld registeert de `SerilogLogTester` de `LogContext.PushProperty` *niet* door het ontbreken van een logregel binnen de using:
```Csharp
 using (LogContext.PushProperty("property", "propertyWaarde"))
 {

 }

logger.LogInformation("Logmessage {Nummer}", "1");
 ```

Met `SerilogLogTester` ziet `LogContext.PushProperty`*niet*:
```Csharp
serilogLogTester.VerifyLogEventByMessageTemplate(LogLevel.Information, "Logmessage {Nummer}", [new("Nummer", "1")]);
serilogLogTester.VerifyLogEventByMessage(LogLevel.Information, "Logmessage 1", [new("Nummer", "1")]);
 ```

## Voorbeelden

### Logwarning zonder exception
Als de volgende logregel wordt weggeschreven:
```Csharp
 logger.LogWarning("Logmessage {property}", "propertyWaarde");
```
Kan deze met de `SerilogLogTester` op de volgende manieren gevalideerd worden:

```Csharp
serilogLogTester.VerifyNumberOfLogEvents(1);
serilogLogTester.VerifyLogEventByMessageTemplate(LogLevel.Warning, "Logmessage {property}", [new("property", "propertyWaarde")]);
serilogLogTester.VerifyLogEventByMessage(LogLevel.Warning, "Logmessage propertyWaarde", [new("property", "propertyWaarde")]);
```

### Logwarning met exception
Als de volgende logregel wordt weggeschreven:
```Csharp
var exception = new NotImplementedException("No content");
logger.LogWarning(exception, "Logmessage {property}", "propertyWaarde");
```
Kan deze met de `SerilogLogTester` op de volgende manieren gevalideerd worden:

```Csharp
var exception = new NotImplementedException("No content");
serilogLogTester.VerifyNumberOfLogEvents(1);
serilogLogTester.VerifyLogEventByMessageTemplate(LogLevel.Warning, "Logmessage {property}", exception, [new("property", "propertyWaarde")]);
serilogLogTester.VerifyLogEventByMessage(LogLevel.Warning, "Logmessage propertyWaarde", exception, [new("property", "propertyWaarde")]);
```

### BeginScope
Als het volgende wordt weggeschreven:
```Csharp
 var scope = new Dictionary<string, string>
 {
     { "property", "propertyWaarde" }
 };

 //Act
 using (logger.BeginScope(scope))
 {

 }
 ```
 Kan deze met de `SerilogLogTester` op de volgende manieren gevalideerd worden:

```Csharp
serilogLogTester.VerifyNumberOfScopeLogProperties(1);
serilogLogTester.VerifyScopeProperties([new("property", "propertyWaarde")]);
```

### LogContext.PushProperty
Als het volgende wordt weggeschreven:
```Csharp
 using (LogContext.PushProperty("property", "propertyWaarde"))
 {
     serilogLogTester.LogInformation("Logmessage 1");
 }
 ```
 Kan deze met de `SerilogLogTester` op de volgende manieren gevalideerd worden:

```Csharp
serilogLogTester.VerifyNumberOfLogEvents(1);
serilogLogTester.VerifyLogEventByMessageTemplate(LogLevel.Information, "Logmessage 1", [new("property", "propertyWaarde")]);
serilogLogTester.VerifyLogEventByMessage(LogLevel.Information, "Logmessage 1", [new("property", "propertyWaarde")]);
```