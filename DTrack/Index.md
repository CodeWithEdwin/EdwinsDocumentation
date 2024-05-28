<< [Home](https://codewithedwin.github.io/EdwinsDocumentation/)

Volledige documentatie is te vinden via [Dependency Track docs](https://docs.dependencytrack.org/).

## Inleiding
----
Voor het scannen van packages binnen de broncode is [Dependency Track](https://dependencytrack.org/) geschikt. Dependency Track (DTrack) zorgt voor het scannen op vulnerabilities van gebruikte client en back-end libraries binnen de broncode. 

## Belangrijk om te weten
---
Er zijn een aantal aandachtspunten bij DTrack.

**Er zijn geen resultaten beschikbaar na een scan.**
De scan duurt soms een paar minuten en de resultaten zullen geleidelijk beschikbaar komen in de portal.

**Analyseert alleen packages**
Het is belangrijk te weten dat de analyse enkel de packages (nuget, npm, etc.) laat zien in DTrack. Handmatig geïnstalleerde onderdelen zullen **niet** worden getoond in Dtrack. Dit is geen packages en dus kan deze niet gevonden worden door de analyzer CycloneDX.

**Wanneer is een packages up-to-date volgens DTrack?**
Een packages is up-to-date als het package de laatste versie die op nuget, npm, etc. staat. Het kan dus zijn dat een nieuwere versie wel beschikbaar is, maar deze niet (of nog niet) als packages beschikbaar is.

**Wanneer wordt een vulnerability meldingen getoond?**
Pas als een vulnerability ook daadwerkelijk bekend is een van de onderstaande zal deze getoond kunnen worden in DTrack.
- [National Vulnerability Database](https://nvd.nist.gov/) 
- [Ossindex](https://ossindex.sonatype.org/)
- [GitHub Advisory](https://github.com/advisories)

### Known Issues
----

- Het dashboard toont meer informatie dan alleen de projecten waar je voor geautoriseerd bent e.g. een totale portfolio view. Dit kan verwarrend zijn omdat de getallen veel hoger kunnen zijn dan verwacht, het is dus een totaal van alle projecten. Oplossing; Navigeren naar een specifiek project zorgt voor een dashboard voor het betreffende project. **_[Fix in volgende release]_**


## Hoe werkt het?
---
Er wordt een analyse uitgevoerd door [CycloneDX](https://github.com/CycloneDX) op de sources vanwaar uit een [Software Bill of Materials (SBOM)](https://owasp.org/www-community/Component_Analysis#software-bill-of-materials-sbom) bestand gegenereerd wordt. Indien meerdere projecten kan het zijn dat je SBOM bestanden moet [samenvoegen](/BPS-WIKI/Microsoft/Dependency-Track#voorbeeld-sbom-genereren-(handmatig)). Vervolgens wordt dit SBOM bestand geupload naar DTrack en is het overzicht in DTrack beschikbaar.

### Ondersteunde Ecosystems
---
- Cargo (Rust)
- Composer (PHP)
- Gems (Ruby)
- Hex (Erlang/Elixir)
- Maven (Java)
- NPM (Javascript)
- NuGet (.NET)
- Pypi (Python)

## DTrack gebruiken
---
DTrack bestaat uit een webportal en API waarbij de portal dashboards heeft met informatie over het project en de API gebruikt kan worden voor het integreren in DevOps-straten e.d.. Voor het gebruik van de API is een API key nodig.
Om toegang tot DTrack te krijgen dient men eenmalig met het  account in te loggen.

**Na de redirect zal binnen 1 sec het dashboard getoond worden.**
Vervolgens dient een project aangevraagd te worden. Geef hierbij aan om welk project en klant het gaat (Klant.Project) en of een API key gewenst is. De aanvrager zal direct rechten krijgen op het project en krijgt een Project Guid + Api key retour. Mochten andere teamleden bij het dashboard moeten kunnen dan kunnen zijn ook eenmalig inloggen en rechten op het project via [Ordina BPS DevOps](mailto:devops@ordina.nl) aanvragen. Als de bevestiging van de aanvraag terug komt bij de aanvrager kan het mogelijk zijn dat men opnieuw moet inloggen om de nieuwe projecten te zien.

Naast het integreren in DevOps straten is het ook mogelijk om handmatig een SBOM file te uploaden.


### Alarmering en scanning
---
DTrack doet een actieve scan van alle projecten op basis van informatie uit de verschillende dependency vulnerability bronnen. Dit betekent dat scans en alarmeringen (email naar hele team) actief plaatsvinden op de volgende momenten:
- Bij het uitvoeren van een scan zoals met een pipeline.
- Gedurende de dag; dit betekent dat de SBOM file die in het systeem staat continue gecontroleerd wordt. Op het moment dat er een nieuwe vulnerability geplaatst wordt in 1 van de bronnen zal DTrack dit matchen met alle projecten en automatisch alerts versturen per mail.


### SBOM genereren
---
Project X is een NPM project en project Y is een .NET project. Om SBOM files te genereren dienen de volgende 3 stappen uitgevoerd te worden dit kan handmatig of in een pipeline zoals in [Azure DevOps full yml](https://dev.azure.com/OrdinaBPSColab/BPS.Maatwerk/_wiki/wikis/BPS.Maatwerk.wiki?wikiVersion=GBwikiMaster&_a=edit&pagePath=/BPS%20WIKI/Microsoft/Dependency%20Track&pageId=55&anchor=volledig-azure-devops-yml-voorbeeld).

**1. Project X - NPM project**
- Restore packages:
`NPM install`
-  Installeer de node-modules CycloneDX tool:
`npm install -g @cyclonedx/bom`
- Voer dit commando in de root van het project uit waarmee een SBOM file gemaakt wordt: 
`cyclonedx-bom -o C:\Temp\CycloneDX\bomNpmProj.json` **Use --include-dev for dev dependencies inclusion**

**2. Project Y - .NET project**
- Installeer de .NET CycloneDX tool ([documenatie](https://github.com/CycloneDX/cyclonedx-dotnet))
`dotnet tool install --global CycloneDX`
- _SBOM aanmaken_
  Restore de NUGet packages voor de hele solution en maak een SBOM file aan. 
  Output filename is altijd **bom.json**
   - _Op basis van specifieke *.sln file._ 
     Vervang _{CompletePath.sln_} door het volledige path van de sln-file (incl. sln file naam zelf).
     `dotnet CycloneDX "{CompletePath.sln}" -o C:\Temp\CycloneDX\CycloneDX\sln -j`
   - _Recursief een map doorlopen op zoek naar packages.config files._ 
     Vervang _{Path}_ door het path dat recursief doorzocht moet worden    
     `dotnet CycloneDX "{Path}" -o C:\Temp\CycloneDX\CycloneDX\sln -j`

**3. Combineer SBOM files Project X en Project Y**
- Download en installeer de [CycloneDX-CLI tool](https://dtrackordinasa.blob.core.windows.net/cyclonedx-cli/cyclonedx.exe?sp=r&st=2021-12-06T10:28:49Z&se=2030-12-06T18:28:49Z&spr=https&sv=2020-08-04&sr=b&sig=mU0T4oq8iKSuX6d0HVn7NJ7CJi8sVjSodfyF07IXZIs%3D)
- Merge alle bestanden die ingevoerd zijn tot 1 SBOM file:
  `cyclonedx.exe merge --input-files C:\Temp\CycloneDX\bomNpmProj.json C:\Temp\CycloneDX\sln\bom.json --output-file C:\Temp\CycloneDX\sbomall.json`


### SBOM uploaden naar DTrack
---
Upload van SBOM naar DTrack kan op verschillende manieren:

**Powershell**
```
      try {
          $filecontent = Get-Content ("C:\Temp\CycloneDX\sbomall.json") –Raw
          $ProjectGuid = "ProjectGuid"
          $ApiKey = "API KEY"
          $Uri = "{URL Dtrack}"
      
          $Body = ([PSCustomObject] @{
                  project = $ProjectGuid
                  bom     = ([Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($filecontent)))
              } | ConvertTo-Json)
      
          $Header = @{ 'X-API-Key' = $ApiKey }
      
          Invoke-RestMethod –Method Put –Uri "$Uri/api/v1/bom" –Headers $Header  –ContentType "application/json" –Body $Body
      }
      catch {
          Write-Host $_
      }
```

**Azure DevOps Pipeline**
De DevOps [extensie](https://marketplace.visualstudio.com/items?itemName=GSoft.dependency-track-vsts) kan als task in de pipeline opgenomen worden. Genereer eerst de SBOM file zoals beschreven bij [SBOM genereren](https://dev.azure.com/OrdinaBPSColab/BPS.Maatwerk/_wiki/wikis/BPS.Maatwerk.wiki?wikiVersion=GBwikiMaster&pagePath=/BPS%20WIKI/Microsoft/Dependency%20Track&pageId=55&_a=edit#sbom-genereren).
```
~~~~~
- task: upload-bom-dtrack-task@1
  inputs:
    bomFilePath: '$(System.DefaultWorkingDirectory)\CycloneDX\sbomall.json'
    dtrackProjId: 'ProjectGuid'
    dtrackAPIKey: 'API KEY'
    dtrackURI: '{URL Dtrack}'
    thresholdCritical: '0'
    thresholdHigh: '0'
    thresholdMedium: '10'
```

### Volledig Azure DevOps yml voorbeeld 
----
```
trigger:
- master

pool:
  vmImage: 'windows-latest'

variables:
  buildPlatform: 'Any CPU'
  buildConfiguration: 'Release'

steps:
- task: Npm@1
  displayName: 'npm install Web'
  inputs:
    workingDir: Web
    verbose: false

- task: Npm@1
  displayName: 'npm install Web2'
  inputs:
    workingDir: Web2
    verbose: false

- task: CmdLine@2
  displayName: 'dotnet install CycloneDX'
  inputs:
    script: 'dotnet tool install --global CycloneDX'

- task: CmdLine@2
  displayName: 'npm install cyclonedx/bom'
  inputs:
    script: 'npm install -g @cyclonedx/bom'

- task: PowerShell@2
  displayName: 'Download cyclonecli tool'
  inputs:
    targetType: 'inline'
    script: 'azcopy cp "https://dtrackordinasa.blob.core.windows.net/cyclonedx-cli/cyclonedx.exe?sp=r&st=2021-12-06T10:28:49Z&se=2030-12-06T18:28:49Z&spr=https&sv=2020-08-04&sr=b&sig=mU0T4oq8iKSuX6d0HVn7NJ7CJi8sVjSodfyF07IXZIs%3D" "$(System.DefaultWorkingDirectory)\CycloneDX\cyclonedx.exe"'

- task: PowerShell@2
  displayName: 'Create NPM SBom file'
  inputs:
    targetType: 'inline'
    script: 'cyclonedx-bom -o $(System.DefaultWorkingDirectory)\CycloneDX\Web.json' #Use --include-dev for dev dependencies inclusion
    workingDirectory: 'Web'

- task: PowerShell@2
  displayName: 'Create NPM SBom file'
  inputs:
    targetType: 'inline'
    script: 'cyclonedx-bom -o $(System.DefaultWorkingDirectory)\CycloneDX\Web2.json' #Use --include-dev for dev dependencies inclusion
    workingDirectory: 'Web2'

- task: PowerShell@2
  displayName: 'Create dotnet sln SBom file'
  inputs:
    targetType: 'inline'
    script: 'dotnet CycloneDX all.sln -o $(System.DefaultWorkingDirectory)\CycloneDX\sln -j'
    workingDirectory: '$(System.DefaultWorkingDirectory)\CycloneDX'

- task: PowerShell@2
  displayName: 'Merge SBom files'
  inputs:
    targetType: 'inline'
    script: './cyclonedx.exe merge --input-files $(System.DefaultWorkingDirectory)\CycloneDX\Web.json $(System.DefaultWorkingDirectory)\CycloneDX\Web2.json $(System.DefaultWorkingDirectory)\CycloneDX\sln\bom.json --output-file $(System.DefaultWorkingDirectory)\CycloneDX\sbomall.json'
    workingDirectory: '$(System.DefaultWorkingDirectory)\CycloneDX'

- task: upload-bom-dtrack-task@1
  inputs:
    bomFilePath: '$(System.DefaultWorkingDirectory)\CycloneDX\sbomall.json'
    dtrackProjId: 'ProjectGuid'
    dtrackAPIKey: 'API Key'
    dtrackURI: '{URL Dtrack}'
    thresholdCritical: '0'
    thresholdHigh: '0'
    thresholdMedium: '10'
```


# Dependency zoeken
Het kan soms lastig zijn om na te gaan in welk project het vulnerable package staat.
Soms kan je dit in Visual Studio niet herleiden omdat het vulnerable package een onderdeel is van een ander package.
Dit kan recursief meerdere lagen diep zitten:

-- Package 1 (gebruikt in project)
---- Package 2
------ Package 3
--------- Package 4 (vulnerable package)

Om toch te onderzoeken in welke projecten het package gebruikt wordt is het handig om een zgn. bom file per project te laten genereren. Zodat je kan onderzoeken (bijv. met [Agent Ransack](https://www.mythicsoft.com/agentransack/)) in welke projecten het vulnerabile package voor komt.

Sla onderstaand script op als *.cmd bestand in een map vanwaar het script zelf recursief (dus dieper) alle *.csproj en *.vbproj files kan vinden.
Bij het starten van onderstaand *.cmd script geeft je op in welke map alle bom files terecht moeten komen. 
Per project krijg je dan daar de *.json files te staan. De naam van het json-bestand is de naam van het projectfile bestand waarbij alle punten vervangen zijn door underscores: _mijn.project.csproj_ wordt _mijn_project_csproj.json_.

Het cmd script:
```
@echo off
setlocal EnableDelayedExpansion

SET /p outputdir="Output directory: "

ECHO ********* INSTALL CycloneDX *********
dotnet tool install --global CycloneDX

ECHO ********* UPDATE CycloneDX *********
dotnet tool update --global CycloneDX

if exist "%outputdir%" del "%outputdir%" /q
if exist projects.out del projects.out /q

dir "*.csproj" /S /B >> projects.out
dir "*.vbproj" /S /B >> projects.out

for /F " " %%i in (projects.out) do (
	call :GetFileName %%i	 	
	ECHO.
	ECHO.
	ECHO ********* !FileName! *********
	SET filename=!FileName:.=_!
	::disable the github lincense, so it will not fail on "GitHub API rate limit exceeded"
	dotnet CycloneDX "%%i" -o "%outputdir%" -j -dgl
	ren  "%outputdir%\bom.json" "!filename!.json"
)

del projects.out

ECHO.
ECHO.
ECHO.
ECHO.
ECHO ********* DONE *********
pause

Goto :EOF


:GetFileName
Set filename=%1
For %%A in ("%filename%") do (
    Set FileName=%%~nxA
)
Goto :EOF
```

