namespace SerilogLogTester;

internal class LoggedScopeProperties(object? propertyName, object? propertyValue)
{
    public object? PropertyValue { get; init; } = propertyValue;
    public object? PropertyName { get; init; } = propertyName;
}