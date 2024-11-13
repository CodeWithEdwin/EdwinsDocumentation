<< [Home](https://codewithedwin.github.io/EdwinsDocumentation/)

# Logging
## Validate Scope
```
_mockLogger.Verify(l => l.BeginScope(It.Is<It.IsAnyType>((o, t) =>
				((IReadOnlyDictionary<string, string>)o).Count == 7
				&& ((IReadOnlyDictionary<string, string>)o).Contains(new KeyValuePair<string, string>("RequestId", "unknown"))
				&& ((IReadOnlyDictionary<string, string>)o).Contains(new KeyValuePair<string, string>("AppVersion", "unknown"))
				&& ((IReadOnlyDictionary<string, string>)o).Contains(new KeyValuePair<string, string>("BatchId", "unknown"))
				&& ((IReadOnlyDictionary<string, string>)o).Contains(new KeyValuePair<string, string>("UserAgent", "unknown"))
				&& ((IReadOnlyDictionary<string, string>)o).Contains(new KeyValuePair<string, string>("Mad-Session-Id-DateTime", "unknown"))
				&& ((IReadOnlyDictionary<string, string>)o).Contains(new KeyValuePair<string, string>("Platform", "unknown"))
				&& ((IReadOnlyDictionary<string, string>)o).ContainsKey("X-Correlation-ID")
			)), Times.Exactly(1));

```

```
[ExcludeFromCodeCoverage]
internal static class DictionaryTestExtension
{
    internal static bool Compare(this object valueA, Dictionary<string, object> scope) =>
        valueA is Dictionary<string, string> dicA1
        ? dicA1.Compare(scope)
        : valueA is Dictionary<string, object> dicA2 && dicA2.Compare(scope);

    internal static bool Compare(this Dictionary<string, string> dicA, Dictionary<string, object> dicB) =>
        dicA.All(a => dicB.Any(b => a.Compare(b)))
        && dicB.All(b => dicA.Any(a => a.Compare(b)));

    internal static bool Compare(this KeyValuePair<string, string> kvpA, KeyValuePair<string, object> kpvB) =>
        kpvB.Value is string strValueB && strValueB.Equals(kvpA.Value) && kvpA.Key.Equals(kpvB.Key);

    internal static bool Compare(this Dictionary<string, object> dicA, Dictionary<string, object> dicB) =>
        dicA.All(a => dicB.Any(b => a.Compare(b)))
        && dicB.All(b => dicA.Any(a => a.Compare(b)));

    internal static bool Compare(this KeyValuePair<string, object> kvpA, KeyValuePair<string, object> kvpB) =>
        kvpB.Value is string strValueB && kvpA.Value is string strValueA
        ? strValueB.Equals(strValueA) && kvpA.Key.Equals(kvpB.Key)
        : kvpB.Value is List<string> lstB && kvpA.Value is List<string> lstA
        && kvpA.Key.Equals(kvpB.Key) && lstA.Compare(lstB);

    internal static bool Compare(this List<string> dicA, List<string> dicB) =>
        dicA.All(a => dicB.Any(b => b.Equals(a)))
        && dicB.All(b => dicA.Any(a => a.Equals(b)));
}

```

## Validate logging

Extension method:
```
/// <summary>
/// Verify logging
/// </summary>
/// <typeparam name="T"></typeparam>
/// <param name="mockLog"></param>
/// <param name="logLevel"></param>
/// <param name="logMessageWithPlaceHolder">Use placeholder '%' for unkown variables</param>
/// <param name="exceptionMessage"></param>
public static void VerifyLogging<T>(
	this Mock<ILogger<T>> mockLog,
	LogLevel logLevel,
	string logMessageWithPlaceHolder,
	string exceptionMessage = "none") =>
		mockLog.Verify(x =>
			x.Log(logLevel,
				  It.IsAny<EventId>(),
				  It.Is<It.IsAnyType>((o, t) => CheckLogmessageparts(o.ToString() ?? string.Empty, logMessageWithPlaceHolder)),
				  It.Is<Exception>(ex => exceptionMessage == "none" || ex.Message.Contains(exceptionMessage)),
				  (Func<It.IsAnyType, Exception?, string>)
				  It.IsAny<object>())
			, Times.Once);

private static bool CheckLogmessageparts(string toCheck, string logMessageWithPlaceHolder)
{
	var logMessageParts = logMessageWithPlaceHolder.Split("%");
	foreach (var str in logMessageParts)
	{
		if (!toCheck.Contains(str))
		{
			return false;
		}
	}

	return true;
}

```