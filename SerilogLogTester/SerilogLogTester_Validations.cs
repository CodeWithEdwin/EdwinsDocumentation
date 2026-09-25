using Microsoft.Extensions.Logging;
using Serilog.Events;
using Shouldly;

namespace SerilogLogTester;

public partial class SerilogLogTester<T>
{
    public void VerifyLogEventByMessage(LogLevel loglevel, string message, Exception exception)
        => _loggedEvents.Any(s => s.LogLevel.Equals(loglevel)
                               && s.Message.Equals(message)
                               && s.Exception != null
                               && s.Exception.GetType() == exception.GetType()
                               && s.Exception.Message.ToString().Equals(exception.Message))
                        .ShouldBeTrue();

    public void VerifyLogEventByMessage(LogLevel loglevel, string message)
        => _loggedEvents.Any(s => s.LogLevel.Equals(loglevel) && s.Message.Equals(message)).ShouldBeTrue();


    public void VerifyLogEventByMessageTemplate(LogLevel loglevel,
                       string messageTemplate,
                       params KeyValuePair<string, object?>[]? expectedLogProperties)
    {
        expectedLogProperties ??= [];
        var expectedLogPropertiesList = expectedLogProperties.ToList();
        _loggedEvents.Any(s => s.LogLevel.Equals(loglevel)
            && s.MessageTemplate.Equals(messageTemplate)
            && PropertiesAreEqual(s.Properties, expectedLogPropertiesList)).ShouldBeTrue();
    }


    public void VerifyLogEventByMessageTemplate(LogLevel loglevel,
                            string messageTemplate,
                            Exception exception,
                            params KeyValuePair<string, object?>[]? expectedLogProperties)
    {
        expectedLogProperties ??= [];
        var expectedLogPropertiesList = expectedLogProperties.ToList();
        _loggedEvents.Any(s => s.LogLevel.Equals(loglevel)
                                     && s.MessageTemplate.Equals(messageTemplate)
                                     && s.Exception != null
                                     && s.Exception.GetType() == exception.GetType()
                                     && s.Exception.Message.ToString().Equals(exception.Message)
                                     && PropertiesAreEqual(s.Properties, expectedLogPropertiesList)).ShouldBeTrue(); ;
    }

    public void VerifyNumberOfLogEvents(int numberOfLogEvents)
        => _loggedEvents.Count.ShouldBe(numberOfLogEvents);

    public void VerifyNoLogging()
        => _loggedEvents.Count.ShouldBe(0);

    public void VerifyScopeProperties(params KeyValuePair<object, object?>[] expected)
        => expected.All(kv => _loggedScopes.Any(s =>
                                                    (
                                                        (s.PropertyName == null && kv.Key == null)
                                                        || (s.PropertyName != null && s.PropertyName.Equals(kv.Key) && s.PropertyName.GetType() == s.PropertyName.GetType())
                                                    )
                                                    && (
                                                        (s.PropertyValue == null && kv.Value == null)
                                                        || (s.PropertyValue != null && s.PropertyValue.Equals(kv.Value) && s.PropertyValue.GetType() == kv.Value.GetType())
                                                    )
                                               )
                       ).ShouldBeTrue();

    public void VerifyNumberOfScopeLogProperties(int numberOfLogEvents)
        => _loggedScopes.Count.ShouldBe(numberOfLogEvents);

    public void VerifyNoScopeLogProperties()
        => _loggedScopes.Count.ShouldBe(0);

    private static bool PropertiesAreEqual(List<LogEventProperty> memoryLogProperties, List<KeyValuePair<string, object?>> expectedLogProperties)
    {
        var memoryLogPropertiesList = memoryLogProperties
                                .Where(w => w.Name is not "SourceContext" and not "Scope")
                                //SourceContext wordt automatisch gevuld door de logger en kan geskiped worden
                                .Select(kv => new KeyValuePair<string, object?>(kv.Name,

                                        //ScalarValue gebruiken omdat een string anders een string met quotes en escapse bevat
                                        //We willen niet terug krijgen "\"waarde\"" maar "waarde"
                                        ((ScalarValue)kv.Value).Value ?? null))
                                .ToList();

        return memoryLogPropertiesList.Count == expectedLogProperties.Count &&
            !memoryLogPropertiesList.Except(expectedLogProperties).Any() &&
            !expectedLogProperties.Except(memoryLogPropertiesList).Any();
    }
}