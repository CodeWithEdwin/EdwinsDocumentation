<< [Home](https://codewithedwin.github.io/EdwinsDocumentation/)


# ReqNRoll datumformaat
Het mogelijk om het datums te gaan rekenen vanaf het nu (heden).
Zo lopen de ReqNRoll testen nooit achter.

Zo doe je normaal:

`Gegeven een burger met geboortedatum 15-03-2000`

OF

```
Gegeven de volgende burgers:
| Naam        | Geboortedatum |
| Edwin Senior| 15-03-2000    |
| Edwin Junior| 15-03-2015    |
```

Nu staan de geboortedatums altijd vast, deze persoon wordt in de testen ook elk jaar ouder.
Stel je wilt juist een test voor een persoon die 25 en 10 jaar is. Dan je ook zeggen:

`Gegeven een burger met geboortedatum 15-03-(YYYY-25)`

OF

```
Gegeven de volgende burgers:
| Naam        | Geboortedatum |
| Edwin Senior| 15-03(YYYY-25)|
| Edwin Junior| 15-03(YYYY-10)|
```

Dan heb je dus 1 burger die altijd 25 jaar geleden geboren is en 1 burger die 10 jaar geleden geboren is.


## Jaren
Voor de jaren is het mogelijk om in plaats van hardcoded waarden te gebruiken.


| Formaat  | Doel                     |
| -------- | ------------------------ |
| (yyyy)   | Het huidige jaar         |
| (yyyy+X) | Het huidige jaar plus X  |
| (yyyy-X) | Het huidige jaar minus X |

Dit resulteert in een jaartal van 4 cijfers.

## Maanden
Voor de maanden is het mogelijk om in plaats van hardcoded waarden te gebruiken:


| Formaat | Doel                     |
| ------- | ------------------------ |
| (MM)    | De huidige maand         |
| (MM+X)  | De huidige maand plus X  |
| (MM-X)  | De huidige maand minus X |

Dit resulteert in een maand van 2 cijfers.


## Dagen
Voor de dagen is het mogelijk om in plaats van hardcoded waarden te gebruiken:

| Formaat | Doel                                               |
| ------- | -------------------------------------------------- |
| (dd)    | De huidige dag                                     |
| (dd+X)  | De huidige dag plus X                              |
| (dd-X)  | De huidige dag minus X                             |
| (dd>)   | De laatste dag van de maand van de opgegeven datum |

Dit resulteert in een dag van 2 cijfers.

Bij het gebruik van (dd>) is het aanbevolen om het datum formaat op te geven:
(dd>)-12-2024:dd-MM-yyyy
De laatste dag van de maand wordt bepaald op basis van de maand en jaartal als opgegeven in het datumformaat.
Om de laatste dag van de maand te kunnen bepalen zijn het jaartal en de maand dus nodig.
Door het datumformaat op te geven kan beter bepaald worden wat de maand en jaar is, om zo beter te kunnen bepalen wat de laatste dag van die maand is.


## Voorbeelden
Stel vandaag is het 20-07-2025 dan geldt:

| Formaat                          | Doel       |
| -------------------------------- | ---------- |
| (dd)-01-2025                     | 20-01-2025 |
| (dd+5)-01-2025                   | 25-01-2025 |
| (dd-5)                           | 15-01-2025 |
| (dd>)-01-2025                    | 31-01-2025 |
| 01-(MM)-2025                     | 01-07-2025 |
| 01-(MM+3)-2025                   | 01-10-2025 |
| 01-(MM-2)-2025                   | 01-05-2025 |
| 01-02-(yyyy)                     | 01-02-2025 |
| 01-02-(yyyy+1)                   | 01-02-2026 |
| 01-02-(yyyy-1)                   | 01-02-2024 |
| (dd)-(MM)-(yyyy)                 | 20-07-2025 |
| (dd>)-(MM-5)-(yyyy+3):dd-MM-yyyy | 28-02-2028 |

# Code

## Helper class
Dit is de class die alle datum templates om kan zetten naar echte datums.

```
using System.Globalization;
using System.Text.RegularExpressions;

namespace [namespace].Helper;

public partial class DateFormatHelper
{
    /// <summary>
    /// Zet datumplaceholders om naar echte datums
    /// </summary>
    /// <param name="value">e.g. (dd)-(MM)-(yyyy), (dd>)-(MM)-(yyyy):dd-MM-yyyy</param>
    /// <returns></returns>
    public static string ConvertDatumFormat(string value)
    {
        //Splitten om te constateren of de waarde een datumformaat specificatie heeft
        var splitted = value.Split(":");
        string format = "";
        string dateTime = value;

        //Is er een datum formaat gespecificeerd dan die gebruiken
        if (splitted.Length == 2)
        {
            format = splitted[1];
            dateTime = splitted[0];
        }

        //Dag als laatste vervangen omdat daar de maand en jaar nodig kunnen zijn om de laatste dag in de maand te bepalen
        return ReplaceDay(ReplaceMonth(ReplaceYear(dateTime)), format);
    }

    [GeneratedRegex(@"(?<=\(dd[+-]\s*)\d+(?=\))")]
    private static partial Regex GetDayValueRegex();

    [GeneratedRegex(@"(?<=\(dd).{1}")]
    private static partial Regex GetDayOperatorRegex();

    [GeneratedRegex(@"(?<=\(MM[+-]\s*)\d+(?=\))")]
    private static partial Regex GetMonthValueRegex();

    [GeneratedRegex(@"(?<=\(MM).{1}")]
    private static partial Regex GetMonthOperatorRegex();

    [GeneratedRegex(@"(?<=\(yyyy[+-]\s*)\d+(?=\))")]
    private static partial Regex GetYearValueRegex();

    [GeneratedRegex(@"(?<=\(yyyy).{1}")]
    private static partial Regex GetYearOperatorRegex();

    private static string ReplaceDay(string value, string format)
    {
        if (!value.Contains("(dd"))
        {
            return value;
        }

        var day = DateTime.Now.Day;
        if (value.Contains("(dd)"))
        {
            return value.Replace($"(dd)", $"{day}");
        }

        var valueToCalculate = GetDayValueRegex().Match(value).Value;
        var operatorString = GetDayOperatorRegex().Match(value).Value;
        switch (operatorString)
        {
            case "+":
                day += int.Parse(valueToCalculate);
                break;

            case "-":
                day -= int.Parse(valueToCalculate);
                break;

            case ">":
                //Omdat de dag niet bekend is deze eerst vervangen voor 01, zodat het een correct datumformaat is
                var defaultDay = value.Replace($"(dd{operatorString}{valueToCalculate})", $"01");

                //Geen datum formaat aanwezig? dan gewoon parsen en hopen dat hij het juiste formaat pakt
                //Is datum formaat aanwezig? dan parsen naar dat formaat
                var parsedDatetime = string.IsNullOrEmpty(format) ? DateTime.Parse(defaultDay) : DateTime.ParseExact(defaultDay, format, CultureInfo.InvariantCulture);

                //na het parsen kan de laatste dag van de maand bepaald worden
                day = DateTime.DaysInMonth(parsedDatetime.Year, parsedDatetime.Month);
                break;
        }

        return value.Replace($"(dd{operatorString}{valueToCalculate})", $"{day}");
    }

    private static string ReplaceMonth(string value)
    {
        if (!value.Contains("(MM"))
        {
            return value;
        }

        var month = DateTime.Now.Month;
        if (value.Contains("(MM)"))
        {
            return value.Replace($"(MM)", $"{month}");
        }

        var valueToCalculate = int.Parse(GetMonthValueRegex().Match(value).Value);
        var operatorString = GetMonthOperatorRegex().Match(value).Value;
        switch (operatorString)
        {
            case "+":
                month += valueToCalculate;
                break;

            case "-":
                month -= valueToCalculate;
                break;
        }

        return value.Replace($"(MM{operatorString}{valueToCalculate})", $"{month}");
    }

    private static string ReplaceYear(string value)
    {
        if (!value.Contains("(yyyy"))
        {
            return value;
        }

        var year = DateTime.Now.Year;
        if (value.Contains("(yyyy)"))
        {
            return value.Replace($"(yyyy)", $"{year}");
        }

        var valueToCalculate = int.Parse(GetYearValueRegex().Match(value).Value);
        var operatorString = GetYearOperatorRegex().Match(value).Value;
        switch (operatorString)
        {
            case "+":
                year += valueToCalculate;
                break;

            case "-":
                year -= valueToCalculate;
                break;
        }

        return value.Replace($"(yyyy{operatorString}{valueToCalculate})", $"{year}");
    }
}
```

## DateOnlyValueRetriever class
Dit is een retreiver om datum templates om te zetten naar enkel datums (dus zonder tijd).
Er is op dit moment (september 2025) geen default ReqNRoll DateOnly retreiver, daarom is deze custom.
```
internal class DateOnlyValueRetriever : IValueRetriever
{
    private readonly Type targetClassType = typeof(Koo);
    private readonly List<string> targetPropertyTypes = [nameof(Koo.InleesDatum), nameof(Koo.MaandEindDatum), nameof(Koo.ContractStartDatum), nameof(Koo.MaandStartDatum), nameof(Koo.ContractEindDatum)];

    public bool CanRetrieve(KeyValuePair<string, string> keyValuePair, Type targetType, Type propertyType)
    {
        return targetType == targetClassType && targetPropertyTypes.Contains(keyValuePair.Key);
    }

    public object Retrieve(KeyValuePair<string, string> keyValuePair, Type targetType, Type propertyType)
    {
        var value = DateFormatHelper.ConvertDatumFormat(keyValuePair.Value);
        return DateOnly.Parse(value);
    }
}
```

## GenericRetriever class
In reqNRoll zijn standaard retreivers aanwezig, deze class zorgt dat die default retreivers om kunnen gaan met de datum templates.

```
/// <summary>
/// Generic retreiver die een standaard retreiver gebruikt en daaroverheen nog gebruik maakt van de datumformaat conversie
/// </summary>
/// <typeparam name="Retreiver"></typeparam>
public partial class GenericRetriever<Retreiver> : IValueRetriever where Retreiver : IValueRetriever, new()
{
    private readonly Retreiver defaultRetreiver = new();

    public bool CanRetrieve(KeyValuePair<string, string> keyValuePair, Type targetType, Type propertyType)
    {
        return defaultRetreiver.CanRetrieve(keyValuePair, targetType, propertyType);
    }

    public object Retrieve(KeyValuePair<string, string> keyValuePair, Type targetType, Type propertyType)
    {
        var replaced = new KeyValuePair<string, string>(keyValuePair.Key, DateFormatHelper.ConvertDatumFormat(keyValuePair.Value));
        return defaultRetreiver.Retrieve(replaced, targetType, propertyType);
    }
}
```

## BeforeScenario Hook
Dit is de hook om te zorgen dat alles om kan gaan met de datum templates.
Eerst moeten de default retreivers verwijderd worden om vervolgens de aangepaste varianten toe te voegen.
Deze retreivers kunnen dan het datum template ondersteunen.
```
/// <summary>
/// Hook om alle valueRetreivers aan te passen vanwege het te gebruiken datumformaat
/// </summary>
[BeforeScenario(Order = -9999)]
public static void BeforeTestRun()
{
    Service.Instance.ValueRetrievers.Unregister<DateTimeValueRetriever>();
    Service.Instance.ValueRetrievers.Unregister<IntValueRetriever>();
    Service.Instance.ValueRetrievers.Unregister<ShortValueRetriever>();
    Service.Instance.ValueRetrievers.Unregister<StringValueRetriever>();

    //nodig voor het gebruiken van null values in tests
    Service.Instance.ValueRetrievers.Register(new NullValueRetriever("<null>"));
    Service.Instance.ValueRetrievers.Register(new DateOnlyValueRetriever());
    Service.Instance.ValueRetrievers.Register(new GenericRetriever<DateTimeValueRetriever>());
    Service.Instance.ValueRetrievers.Register(new GenericRetriever<IntValueRetriever>());
    Service.Instance.ValueRetrievers.Register(new GenericRetriever<ShortValueRetriever>());
    Service.Instance.ValueRetrievers.Register(new GenericRetriever<StringValueRetriever>());
}
```