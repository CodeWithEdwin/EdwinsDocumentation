using Microsoft.Extensions.Logging;
using Serilog;
using Serilog.Events;
using Serilog.Parsing;
using System.Collections.Concurrent;

namespace SerilogLogTester;

/// <summary>
/// Deze class is in het leven geroepen omdat het met huidge oplossingen niet mogelijk is
/// om aanroepen naar logger.BeginScope() en de bijbehorende waarden in diverse testen te kunnen valideren
/// </summary>
/// <typeparam name="T"></typeparam>
public partial class SerilogLogTester<T> : ILogger<T>
{
    private const string MessageTemplateKey = "{OriginalFormat}";
    private const string UnknownPlaceholder = "<Unknown>";
    private readonly ConcurrentBag<SerilogLogTesterEvent> _loggedEvents = [];
    private readonly ConcurrentBag<KeyValuePair<string, string?>> _loggedScopes = [];

    /// <summary>
    /// alle loglevels tonen
    /// </summary>
    /// <param name="logLevel"></param>
    /// <returns></returns>
    public bool IsEnabled(LogLevel logLevel) => true;

    /// <summary>
    /// Beginscope properties worden apart geregisteerd
    /// Normaliter zijn dit properties die serilog toevoegt aan logmeldingen
    /// </summary>
    /// <typeparam name="TState"></typeparam>
    /// <param name="state"></param>
    /// <returns></returns>
    public IDisposable BeginScope<TState>(TState state) where TState : notnull
    {
        switch (state)
        {
            case Dictionary<string, string> stateDictionary:
                stateDictionary.ToList().ForEach(kv => _loggedScopes.Add(new(kv.Key, kv.Value)));
                break;

            case string stateString:
                _loggedScopes.Add(new("{Message}", stateString));
                break;

            case IReadOnlyList<KeyValuePair<string, object?>> stateFormattedValues:
                stateFormattedValues.ToList().ForEach(kv =>
                _loggedScopes.Add(new(kv.Key.Replace(MessageTemplateKey, "{MessageFormat}"), kv.Value == null ? null : $"{kv.Value}")));
                break;
        }

        return Stream.Null;
    }

    /// <summary>
    /// Registeer de logmelding
    /// </summary>
    /// <typeparam name="TState"></typeparam>
    /// <param name="logLevel"></param>
    /// <param name="eventId"></param>
    /// <param name="state"></param>
    /// <param name="exception"></param>
    /// <param name="formatter"></param>
    public void Log<TState>(LogLevel logLevel, EventId eventId, TState state, Exception? exception,
        Func<TState, Exception?, string> formatter)
    {
        if (state == null! || string.IsNullOrWhiteSpace(state.ToString()))
        {
            return;
        }

        var properties = GetLogProperties(logLevel, state, exception, formatter);
        var logMessage = new MessageTemplateParser().Parse(state.ToString() ?? "");

        var logEvent = new SerilogLogTesterEvent(
            DateTimeOffset.Now,
            logLevel,
            exception,
            GetMessageTemplateFromProperties(properties),
            logMessage.ToString(),
            [.. properties.Where(p => p.Name != MessageTemplateKey)]
        );

        _loggedEvents.Add(logEvent);
    }

    private static string GetMessageTemplateFromProperties(List<LogEventProperty> logProperties)
    {
        // In {OriginalFormat} staat het messagetemplate
        var propertyItem = logProperties.FirstOrDefault(f => f.Name == MessageTemplateKey);
        if (propertyItem != null && propertyItem.Value != null)
        {
            // ScalarValue gebruiken omdat een string anders een string met quotes en escapse bevat
            //We willen niet terug krijgen "\"waarde\"" maar "waarde"
            return ((ScalarValue)propertyItem.Value).Value?.ToString() ?? UnknownPlaceholder;
        }

        return UnknownPlaceholder;
    }

    private static List<LogEventProperty> GetLogProperties<TState>(LogLevel logLevel, TState state,
        Exception? exception, Func<TState, Exception?, string> formatter)
    {
        var properties = GetPushedProperties(logLevel, state, exception, formatter);
        if (state is IEnumerable<KeyValuePair<string, object>> kvps)
        {
            properties.AddRange(
                 kvps
                 .Select(kvp => new LogEventProperty(kvp.Key, new ScalarValue(kvp.Value)))
             );
        }

        return properties;
    }

    /// <summary>
    /// Via LogContext.PushProperty kunnen properties toegevoegd worden aan de serilog logging
    /// Deze halen we hier op voor de specifieke logregel
    /// </summary>
    /// <typeparam name="TState"></typeparam>
    /// <param name="logLevel"></param>
    /// <param name="state"></param>
    /// <param name="exception"></param>
    /// <param name="formatter"></param>
    /// <returns></returns>
    private static List<LogEventProperty> GetPushedProperties<TState>(LogLevel logLevel, TState state,
        Exception? exception, Func<TState, Exception?, string> formatter)
    {
        //We maken een sink aan in die sink schrijven we de logging weg,
        //daarmee voegt Serilog zelf de properties uit LogContext.PushProperty toe
        //we doen dit in deze functie om thread-safe te zijn
        PushPropertyLogEventSink pushPropertySink = new();
        var logger = new LoggerConfiguration()
            .Enrich.FromLogContext()
            .WriteTo.Sink(pushPropertySink)
            .CreateLogger();

        logger.Write((LogEventLevel)logLevel, exception, formatter(state, exception));

        //hier halen we de properties uit de sink die door serilog toegevoegd zijn
        return pushPropertySink.Properties;
    }
}
