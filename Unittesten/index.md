<< [Home](https://codewithedwin.github.io/EdwinsDocumentation/)

# Logging
## Validate Scope

Extension method:
```
  internal static void ValidateScope<T>(this Mock<ILogger<T>> logger, Dictionary<string, object> scope)
    {
        var invocationScopeCount = logger.Invocations.Count(i => i.Arguments.Any(i1 => i1.Compare(scope)));
        Assert.AreEqual(1, invocationScopeCount);
    }
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
    internal static void Validate<T>(this Mock<ILogger<T>> logger, LogLevel logLevel, string message)
    {
        var invocationsWithMessageCount = logger.Invocations.Count(i =>
            i.Arguments.Contains(logLevel) &&
            ((IReadOnlyList<KeyValuePair<string, object>>)i.Arguments[2]).Contains(
                new KeyValuePair<string, object>("{OriginalFormat}", message)));

        Assert.AreEqual(1, invocationsWithMessageCount);
    }
```