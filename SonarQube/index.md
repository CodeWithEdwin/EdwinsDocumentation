<< [Home](https://codewithedwin.github.io/EdwinsDocumentation/)

# Toelichting
---

Op deze pagina wordt de inrichting van Pull Request decoration binnen de _organisatieX_ organisatie beschreven. Het gaat daarbij om de Azure Devops projecten die binnen _organisatieX_ staan.

# Hoe werkt het
---

Eenmaal ingericht worden de Sonarqube meldingen als comments weergegeven in een pull request. Op deze manier heb je voor het mergen al de mogelijkheid om de code in orde te maken. Dit is de meest complete oplossing die we kunnen aanbieden.

Het is hierbij mogelijk om te verplichten dat er bij een pull request geen nieuwe sonarqube bevindingen worden gevonden, pas als er geen sonarqube bevindingen zijn is het mogelijk de pull request te completen.

Ook is het mogelijk om de sonarqube bevindingen wel te tonen, maar gewoon de pull request te kunnen completen al zijn er sonarqube bevindingen.

# Uitgangspunt
---

Het uitgangspunt is dat er bij het mergen naar de `master` via een pull request een sonarqube controle plaats vindt. Alles in dit inrichting voorbeeld/uitleg gaat uit van de `master`, wil je de controles op een andere branch laten plaatsvinden. Dan die je die branche die kiezen daar waar in deze uitleg de `master` gebruikt wordt. Dat is ook de reden dat de `master` met een grijze achtergrond wordt weergegeven.

# Sonarqube instellen
---

Om te beginnen moet je in Sonarqube naar _SQ project -> General Settings -> Pull Request Decoration_ aldaar dien je te kiezen voor de _Configuration name_ _organisatieX_ en de naam van het project en de naam van de repository zoals die in Azure Devops gebruikt worden in te vullen.

![image.png](https://codewithedwin.github.io/EdwinsDocumentation/SonarQube/GeneralSettings.png)

## SonarQube Pipeline
Vervolgens dien je een pipeline in Azure Devops aan te maken die een sonarqube analyse doet.
Wellicht heb je al een pipeline voor sonarqube. Deze pipeline kunnen we hergebruiken maar controleer wel of onderstaande taken in de pipeline gebruikt worden.

De Sonarqube pipeline **moet** de volgende taken bevatten:
- Prepare Analysis Configuration
- Run Code Analysis
- Publish Quality Gate Result

_Gebruik bijvoorkeur de laatste versie van deze taken_
Deze pipeline gaan we gebruiken bij een Pull request. Het maakt hierbij niet uit welke sources gebruikt worden, doordat we deze pipeline gaan gebruiken voor een pull request zorgt Azure er voor dat de sources van source branche van de pull request worden opgehaald en dus gebruikt worden voor de analyse.

## Build validation
Om er voor te zorgen dat SonarQube de Pullrequest data ontvangt dient een Build validation toegevoegd te worden.
Ga hiervoor naar _Branches -> `master` -> Branch Policies_:
![image.png](https://codewithedwin.github.io/EdwinsDocumentation/SonarQube/BranchePolicies.png)

Klik op de + bij _Build Validation_ en selecteer de SonarQube Pipeline. Maak deze required, zodat de de sources altijd compileren en SonarQube hier later mee overweg kan.

![image.png](https://codewithedwin.github.io/EdwinsDocumentation/SonarQube/AddPolicy.png)

Later gaan we terug naar deze pagina(_Branche Policies_) om een _Status Check_ toe te voegen, dit kan op dit moment niet omdat deze nog niet beschikbaar is. Deze wordt automatisch toegevoegd, maar daarvoor moeten we eerst een build doen.

## Pull request - tijdelijk
Om er voor te zorgen dat we de sonarqube analyse kunnen opnemen in de _Branche Policies_ moeten we nu een pull request aanmekn.

Maak nu een branche van de `master` en noem deze bijv. _SQ-PR-test_. In deze branch maak je een (simpele) wijziging en maak daar een pull request van om hem terug te mergen, echt terug mergen gaan we niet doen. We hebben de pull request alleen nodig om er voor te zorgen dat we een _Status Check_ kunnen toevoegen voor SonarQube.

Je zult nu zien dat er 2 controles gedaan worden (naast de merge conflicts):
![image.png](https://codewithedwin.github.io/EdwinsDocumentation/SonarQube/PRControle.png)

Nu is de optionele Coverage check van SonarQube toegevoegd:
![image.png](https://codewithedwin.github.io/EdwinsDocumentation/SonarQube/PRchecks.png)

## Status check
Ga hiervoor naar _Branches -> `master` -> Branch Policies_:
![image.png](https://codewithedwin.github.io/EdwinsDocumentation/SonarQube/BranchePolicies.png)

Klik op de + bij _Status check_ en selecteer de codecoverage.
![image.png](https://codewithedwin.github.io/EdwinsDocumentation/SonarQube/StatusPolicy.png)

Alhier kun je kiezen voor:
- **Required**: Er mogen geen SonarQube meldingen zijn alvorens de pull request te kunnen mergen. Mochten er wel SonarQube meldingen zijn dan dienen deze opgelost te worden.
- **Optional**: Sonarqube meldingen worden getoond, maar hoeven niet opgelost te worden alvorens de pull request te kunnen mergen

## Comments verplicht opgelost
Als laatste dient aangezet te worden dat alle commentaren opgelost moeten zijn alvorens een pull request gecomplete kan worden.
Dit is nodig om er voor te zorgen dat sonarqube meldingen niet genegeerd worden bij het gebruik van de autocomplete van een pullrequest. Bij een autocomplete wordt nl. een merge gedaan als aan alle voorwaarden voldaan is. In het geval dat de Status check als optioneel ingesteld is worden de sonarqube meldingen genegeerd. Dit komt omdat de sonarqube meldingen als comments in de pull request verschijnen.

Ga hiervoor naar _Branches -> `master` -> Branch Policies_ (indien deze niet reeds open staat):
![image.png](https://codewithedwin.github.io/EdwinsDocumentation/SonarQube/BranchePolicies.png)

We zetten de _Check for comment resolution_ aan en selecteren _Required_.
![image.png](https://codewithedwin.github.io/EdwinsDocumentation/SonarQube/CommitResolution.png)


## Afronden
Gooi de pull request weg en zo ook de aangemaakte branche. Deze zijn nu niet meer nodig.

## Backdating
Als er updates uitgevoerd worden aan Sonarqube kan het zo zijn dat er aanpassingen komen aan de Quality Profiles. Dit kan dan zorgen voor dat nieuwe bevindingen niet in de new code - de delta - te zien zijn, maar wel in het totaal overzicht. Dit komt door backdating.

Backdating is simpel gezegd de creation datetime van nieuwe sonarqube bevindingen zetten op het tijdstip van laatste wijziging van de betreffende regel code.

[Sonarqube.org: Uitleg backdating versie 7.9](https://docs.sonarqube.org/7.9/user-guide/issues/#header-4)
[Sonarqube.ordina.nl: Uitleg backdating](https://sonarqube.ordina.nl/documentation/user-guide/issues/#understanding-issue-backdating)