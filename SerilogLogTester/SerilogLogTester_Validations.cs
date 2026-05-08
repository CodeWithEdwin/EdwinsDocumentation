using Microsoft.Extensions.Logging;
using Serilog.Events;
using Shouldly;

namespace SerilogLogTester;

public partial class SerilogLogTester<T>
{
    public void VerifyLogEventByMessage(LogLevel loglevel,
                            string message,
                            Exception exception,
                            params KeyValuePair<string, string?>[]? expectedLogProperties)
    {
        expectedLogProperties ??= [];
        var expectedLogPropertiesList = expectedLogProperties.ToList();
        _loggedEvents.ShouldContain(s => s.LogLevel.Equals(loglevel)
                                     && s.Message.Equals(message)
                                     && s.Exception != null
                                     && s.Exception.GetType() == exception.GetType()
                                     && s.Exception.Message.ToString().Equals(exception.Message)
                                     && PropertiesAreEqual(s.Properties, expectedLogPropertiesList));
    }

    public void VerifyLogEventByMessage(LogLevel loglevel,
                         string message,
                         params KeyValuePair<string, string?>[]? expectedLogProperties)
    {
        expectedLogProperties ??= [];
        var expectedLogPropertiesList = expectedLogProperties.ToList();
        _loggedEvents.ShouldContain(s => s.LogLevel.Equals(loglevel)
            && s.Message.Equals(message)
            && PropertiesAreEqual(s.Properties, expectedLogPropertiesList));
    }

    public void VerifyLogEventByMessageTemplate(LogLevel loglevel,
                       string messageTemplate,
                       params KeyValuePair<string, string?>[]? expectedLogProperties)
    {
        expectedLogProperties ??= [];
        var expectedLogPropertiesList = expectedLogProperties.ToList();
        _loggedEvents.ShouldContain(s => s.LogLevel.Equals(loglevel)
            && s.MessageTemplate.Equals(messageTemplate)
            && PropertiesAreEqual(s.Properties, expectedLogPropertiesList));
    }

    public void VerifyLogEventByMessageTemplate(LogLevel loglevel,
                            string messageTemplate,
                            Exception exception,
                            params KeyValuePair<string, string?>[]? expectedLogProperties)
    {
        expectedLogProperties ??= [];
        var expectedLogPropertiesList = expectedLogProperties.ToList();
        _loggedEvents.ShouldContain(s => s.LogLevel.Equals(loglevel)
                                     && s.MessageTemplate.Equals(messageTemplate)
                                     && s.Exception != null
                                     && s.Exception.GetType() == exception.GetType()
                                     && s.Exception.Message.ToString().Equals(exception.Message)
                                     && PropertiesAreEqual(s.Properties, expectedLogPropertiesList));
    }

    public void VerifyNumberOfLogEvents(int numberOfLogEvents) =>
        _loggedEvents.Count.ShouldBe(numberOfLogEvents);

    public void VerifyNoLogging() => _loggedEvents.Count.ShouldBe(0);

    public void VerifyScopeProperties(params KeyValuePair<string, string?>[] expected) =>
        expected.All(kv => _loggedScopes.Any(s => s.Key == kv.Key && s.Value == kv.Value))
        .ShouldBeTrue();

    public void VerifyNumberOfScopeLogProperties(int numberOfLogEvents) =>
        _loggedScopes.Count.ShouldBe(numberOfLogEvents);

    public void VerifyNoScopeLogProperties() => _loggedScopes.Count.ShouldBe(0);

    private static bool PropertiesAreEqual(List<LogEventProperty> memoryLogProperties, List<KeyValuePair<string, string?>> expectedLogProperties)
    {
        var memoryLogPropertiesList = memoryLogProperties
                                .Where(w => w.Name is not "SourceContext" and not "Scope")
                                //SourceContext wordt automatisch gevuld door de logger en kan geskiped worden
                                .Select(kv => new KeyValuePair<string, string?>(kv.Name,

                                        //ScalarValue gebruiken omdat een string anders een string met quotes en escapse bevat
                                        //We willen niet terug krijgen "\"waarde\"" maar "waarde"
                                        ((ScalarValue)kv.Value).Value?.ToString() ?? null))
                                .ToList();

        return memoryLogPropertiesList.Count == expectedLogProperties.Count &&
            !memoryLogPropertiesList.Except(expectedLogProperties).Any() &&
            !expectedLogProperties.Except(memoryLogPropertiesList).Any();
    }
}
