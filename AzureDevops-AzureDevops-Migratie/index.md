Migratie van de ene Azure Devops project naar de andere Azure Devops project kan in een aantal stappen gedaan worden.
Omdat het e.e.a. wisselt per project staan hier slechts enkele stappen beschreven.

# Wiki

Wiki's die gepublished as code zijn, zitten als onderdeel in de Repository waar ook de Code van de applicatie staat. Die komen met de migratie van de code repository direct mee.
De zgn. Project wiki's zitten in een eigen repository.

Door zowel de repository van de project wiki van het bron azure devops project en het doel azure devops project te clonen, kunnen de bestanden van de bron overgezet worden naar de doel en deze op de doel in checken.

Is er in het doel azure devops project nog geen wiki aanwezig, maak deze dan eerst aan door bijv. een lege test pagina te maken. Bij het kopiëren van de bestanden kan deze pagina verwijderd worden (incl. de .order file).

# Repository

De repository met code kan je importeren.
Hiermee komen de sources over en de zgn. Tags.
![ImportRepositoy](https://codewithedwin.github.io/EdwinsDocumenation/AzureDevops-AzureDevops-Migratie/ImportRepositoy.png)

# Work Items

De work items kun je migreren met de tool:
[https://nkdagility.com/learn/azure-devops-migration-tools/](https://nkdagility.com/learn/azure-devops-migration-tools/)

Deze omschrijving gaat uit van versie 13.0.9 van deze tool.
[Hier](https://www.youtube.com/watch?v=B9_jUwwQ1OI) is ook een link naar een interview met een MVP-er die de deze tool in den beginsel heeft ontwikkeld.

## Laatste versie

De laatste versie staat op Github:
[https://github.com/nkdAgility/azure-devops-migration-tools/releases](https://github.com/nkdAgility/azure-devops-migration-tools/releases)
Dit is eenvoudiger dan deze met Chocolatey te installeren (wat hun aanbevolen methode is).
De *.zip file kan je nu uitpakken en daarmee kan je aan de slag.

## Process

In de doel azure Devops omgeving moet het process gelijk zijn aan die van het bron azure devops project.
Met als aanvulling dat in het doel azure devops project het custom field ‘ReflectedWorkItemId’ aanwezig moet zijn.
Deze kan je (laten) aanmaken zoals beschreven is op [https://nkdagility.com/learn/azure-devops-migration-tools/server-configuration/](https://nkdagility.com/learn/azure-devops-migration-tools/server-configuration/).
Die verwijst weer door naar de documentatie van [microsoft](https://learn.microsoft.com/en-us/azure/devops/organizations/settings/work/add-custom-field?view=azure-devops).
**Let op: maak dit veld optioneel (dus niet Required).**

## Configuration file aanmaken

De tool moet nu geconfigureerd worden. Dit doe je via de json file _configuration.json_.

Je kunt de tool zelf een standaard configuratie laten maken door dit cmd commando uit te voeren:
`migration.exe init`

## Configuration.json instellen

De tool kan je configureren via de _configuration.json_. Hieronder de toelichting voor migreren van een azure devops project met het Scrum process.

### Toegang azure devops

Nu moet deze tool ook toegang hebben tot beide projecten. De aanbevolen manier is via Accesstokens.
`"AuthenticationMode": "AccessToken"`

Gebleken is dat enkele functies alleen werken bij gebruik van Accesstokens.

Maak in de bron en het doel azure devops project een nieuwe accesstoken aan die **volledige rechten** heeft.
Vul de accesstoken in bij _PersonalAccessToken_.
Vul bij _Collection_ de URL in van de organisatie waarin het project zich bevindt:
`https://dev.azure.com/[Organisatie]/`
Vul bij _Project_ de naam van het project in.

### ReflectedWorkItemIDFieldName

Vul in de het custom field ‘ReflectedWorkItemId’ in bij 
`"ReflectedWorkItemIDFieldName": "Custom.ReflectedWorkItemId"`

De tip die hierbij wordt vermeld op [https://nkdagility.com/learn/azure-devops-migration-tools/server-configuration/](https://nkdagility.com/learn/azure-devops-migration-tools/server-configuration/) is:

![ImportRepositoy](https://codewithedwin.github.io/EdwinsDocumenation/AzureDevops-AzureDevops-Migratie/ReflectedWorkItemId.png)

### FieldMaps

Om de juiste status van de work items over te zetten naar het doel Azure devops project moet de mapping van de statussen goed zijn. Standaard is er 1 mapping aanwezig in de configuration.json:

```
{
      "$type": "FieldValueMapConfig",
      "WorkItemTypeName": "*",
      "sourceField": "System.State",
      "targetField": "System.State",
      "defaultValue": "New",
      "valueMapping": {
        "Approved": "New",
        "New": "New",
        "Committed": "Active",
        "In Progress": "Active",
        "To Do": "New",
        "Done": "Closed",
        "Removed": "Removed"
      }
}
```

Dit bleek niet juist te zijn voor het standaard Scrum process. Daarom is de aanpassing gemaakt om deze per work item type op te splitsen in:


```
{
      "$type": "FieldValueMapConfig",
      "WorkItemTypeName": "Product Backlog Item",
      "sourceField": "System.State",
      "targetField": "System.State",
      "defaultValue": "New",
      "valueMapping": {       
        "New": "New",
	"Approved": "Approved",
        "Committed": "Committed",
        "Done": "Done",
        "Removed": "Removed"
      }
    },
	 {
      "$type": "FieldValueMapConfig",
      "WorkItemTypeName": "Bug",
      "sourceField": "System.State",
      "targetField": "System.State",
      "defaultValue": "New",
      "valueMapping": {       
        "New": "New",
	"Approved": "Approved",
        "Committed": "Committed",
        "Done": "Done",
        "Removed": "Removed"
      }
    },
	{
      "$type": "FieldValueMapConfig",
      "WorkItemTypeName": "Task",
      "sourceField": "System.State",
      "targetField": "System.State",
      "defaultValue": "New",
      "valueMapping": {       
        "To Do": "To Do",
	"In Progress": "In Progress",
        "Done": "Done"
      }
    }
```

### FieldMergeMapConfig

Standaard worden work items gemigreerd door deze instelling:
```
{
  "$type": "FieldMergeMapConfig",
      "WorkItemTypeName": "*",						
      "sourceFields": [
        "System.Description",
        "Microsoft.VSTS.Common.AcceptanceCriteria"
      ],
      "targetField": "System.Description",
      "formatExpression": "{0} <br/><br/><h3>Acceptance Criteria</h3>{1}"
 }
```
Bij het Scrum process hebben taken geen Acceptatie criteria. Daarom de volgende aanpassing:
 
```
{
      "$type": "FieldMergeMapConfig",
      "WorkItemTypeName": "Product Backlog Item",
      "sourceFields": [
        "System.Description",
        "Microsoft.VSTS.Common.AcceptanceCriteria"
      ],
      "targetField": "System.Description",
      "formatExpression": "{0} <br/><br/><h3>Acceptance Criteria</h3>{1}"
    },
	{
      "$type": "FieldMergeMapConfig",
      "WorkItemTypeName": "Bug",
      "sourceFields": [
        "System.Description",
        "Microsoft.VSTS.Common.AcceptanceCriteria"
      ],
      "targetField": "System.Description",
      "formatExpression": "{0} <br/><br/><h3>Acceptance Criteria</h3>{1}"
    },
	{
      "$type": "FieldMergeMapConfig",
      "WorkItemTypeName": "Task",
      "sourceFields": [
        "System.Description"
      ],
      "targetField": "System.Description",
      "formatExpression": "{0}"
    }
```


### WorkItemMigrationConfig processor

In de processors staat standaard de processor WorkItemMigrationConfig:
`"$type": "WorkItemMigrationConfig"`
Dit is prima voor de migratie.

Deze processor staat standaard uit, zet deze dus altijd aan:
`"Enabled": true`

### Iterations

Om de juiste iterations (in _Project settings_ > _Project configuration_ ) over te zetten dienen deze gespecificeerd te worden in _NodeBasePaths_.

Als voorbeeld staan in het configuration.json een aantal opgenoemd:
  
```
"NodeBasePaths": [
        "Product\\Area\\Path1",
        "Product\\Area\\Path2"
      ]
```

Je kunt ook het Product en de Area vermelden. Alle path's onder de Area worden dan gemigreerd.


### Query

Om te migreren kan je ook de work items in stappen over zetten door een set aan work items eerst te migreren.
Dit kun je doen door een query in te vullen. Standaard staat hier:

```
"WIQLQueryBit": "AND  [Microsoft.VSTS.Common.ClosedDate] = '' AND [System.WorkItemType] NOT IN ('Test Suite', 'Test Plan','Shared Steps','Shared Parameter','Feedback Request')"
```
**let op**
Als je hier een query invult begin altijd met AND. De query is nl. een aanvulling op een Query die de tool gebruikt.

Als je alle work items in een keer wilt migreren dan is het aanbevolen om deze leeg te laten.

Ook kun je een sortering bepalen:
`"WIQLOrderBit": "[System.ChangedDate] desc"`

Aanbevolen is om deze te gebruiken:
`"WIQLOrderBit": "[System.Id] asc"`
Op deze manier worden de work items toegevoegd in de volgorde zoals ze ook toegevoegd zijn in het bron azure devops project.

### Html attachment links

In de description in work items kunnen afbeeldingen zijn opgenomen. Om deze juist te migreren dient de instelling aan te staan:
`"FixHtmlAttachmentLinks": true`

![FixHtmlAttachmentLinks](https://codewithedwin.github.io/EdwinsDocumenation/AzureDevops-AzureDevops-Migratie/FixHtmlAttachmentLinks.png)

Het betreft hier een beta functie, maar dit levert wel op dat de afbeeldingen ook overgezet worden in de Description.

### Attachments

Bijlagen bij work items worden eerst op schijf opgeslagen uit de bron work item om ze vervolgens over te zetten naar het doel work item. Om deze bijlagen eerst op te slaan vul hier een map in die de tool aan kan maken:
`"AttachmentWorkingPath": "c:\\temp\\WorkItemAttachmentWorkingFolder\\"`

### Final Revised Work item type

Gebleken is dat work items onjuist overgezet worden op het moment dat de instelling _SkipToFinalRevisedWorkItemType_ aan staat. Alle work items die ooit een keer van type zijn gewijzigd levert fouten op tijdens de migratie. Zet deze instelling daarom uit:
`"SkipToFinalRevisedWorkItemType": false`

![SkipToFinalRevisedWorkItemType](https://codewithedwin.github.io/EdwinsDocumenation/AzureDevops-AzureDevops-Migratie/SkipToFinalRevisedWorkItemType.png)



## Start tool met behoud van logging

Als de tool gestart wordt op de aanbevolen manier:
`migration.exe execute --config .\configuration.json`
Dan zie je enkel en alleen de logging in het command prompt verschijnen.
Het is dan lastig om de logging te doorzoeken.

Daarom is het aanbevolen om de tool te starten op deze manier:
`migration.exe execute --config .\configuration.json >> MigrationOutput.txt`

In het command prompt window zie je na het uitvoeren geen logging meer, deze wordt nu weggeschreven in het bestand MigrationOutput.txt. Op deze manier behoud je de logging en kan je het e.e.a. nazoeken.

Als je het bestand MigrationOutput.txt opent met [WinTail.exe](https://www.baremetalsoft.com/wintail/) tijdens het uitvoeren van de tool, zie je direct alle logging voorbij komen.


 