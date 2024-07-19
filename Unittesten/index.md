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