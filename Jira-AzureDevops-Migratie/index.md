# Overstappen

Om over te gaan van het Jira ticket systeem naar Azure Devops is het natuurlijk het fijnste als alle Jira-issues ook beschikbaar komen in Azure Devops.

De tool [jira-azuredevops-migrator](https://github.com/solidify/jira-azuredevops-migrator) biedt hiervoor uitkomst.
De migratie gaat in de volgende stappen:
- Configureren v/d migratie
- Export van Jira naar lokale map
- Import naar Azure Devops.

Met deze stappen worden de Jira issues omgezet naar Azure Devops, waarbij in de titel het Jira issue nummer vermeld wordt tussen blokhaken: _[Jira-1] Dit is een test issue_

Dit document geeft een beschrijving op basis van versie _v2.3.117_ in nieuwere versie kan het e.e.a. verbeterd zijn en/of aangepast. Werk deze pagina dan bij met de meest recente gegevens / aanpassingen.

# Configuratie

##  json configuratie
Bij het downloaden van de tool worden 3 configuratie *.json Samples geleverd. Welke gebruikt moet worden hangt af van het type van het Azure Devops project. Het type kun je terug vinden in Azure Devops onder _Project Settings_ -> _General_ -> _Overview_ onder de kop _Process_.
Kopieer de *.json in de root map van de tool. Pas deze zonodig nog aan.


Hoe je het e.e.a. moet configureren hangt af van hoe je Azure Devops ingericht hebt en hoe je deze wilt inrichten.
In de [configuratie documentatie](https://github.com/solidify/jira-azuredevops-migrator/blob/master/docs/config.md) kan je terug vinden wat je kunt configureren.

##  Users

In Jira worden gebruikers (e-mailadressen) gebruikt waarop tickets en comments aan gerelateerd worden. Omdat het e.e.a. in Azure Devops af kan wijken dien je een _Users.txt_ bestand aan te maken in de root map van de tool. Dit bestand maakt de mapping van Jira gebruiker naar Azure Devops gebruikers. De inhoudt kan er bijv. als volgt uit zien:

```
User1@jira.nl=User1@AzureDevops.nl
User2@jira.nl=User2@AzureDevops.nl
```

# Export

De export exporteert de Jira issues (incl. bijlagen en comments). Dit kan je eenvoudig doen door het volgende CMD commando uit te voeren:

`jira-export -u jiraaccount@some.domain -p xxxxxxx --url https://my.jira.url --config config-scrum.json --force`

_jiraaccount@some.domain_ = jou e-mail adres die gebruikt wordt in Jira om in te logggen
_xxxxxxx_ = jou wachtwoord om in Jira in te loggen
_https://my.jira.url_ = de Url van Jira
_config-scrum.json_ = de json file die je wilt gebruiken die de configuratie bevat

**Let op:** verstandig is om de export map (zie *.json configuratie file) alvast aan te maken en daar alvast de users.txt in te zetten. Het kan anders zijn dat de export een melding geeft dat de users.txt niet gevonden is.

In de export map wordt een export-logfile weggeschreven, zodat je altijd na kunt gaan wat je op je scherm te zien hebt gekregen.

# Import

De import importeert de export Jira issues naar Azure Devops. Dit kan je eenvoudig doen door het volgende CMD commando uit te voeren:

`wi-import --token myAccessToken --url https://my.azuredevops.url --config config-scrum.json --force`

_myAccessToken_ = een accesstoken met **Full access** rechten. Dit is nodig omdat de tool het e.e.a. aan iteraties aan gaat maken.
_https://my.azuredevops.url_ = de Url van Azure Devops
_config-scrum.json_ = de json file die je wilt gebruiken die de configuratie bevat

**Let op:** verstandig is de jira export map het bestand users.txt te zetten. Het kan anders zijn dat de export een melding geeft dat de users.txt niet gevonden is.

In de export map wordt een import-logfile weggeschreven, zodat je altijd na kunt gaan wat je op je scherm te zien hebt gekregen.

# Configuratie aanpassingen na run

Indien er ergens iets niet goed gaat bij ofwel de export ofwel de import is het verstandig om na een configuratie wijziging **altijd** de export en import volledig opnieuw te draaien. Gezien het onbekend is hoe de configuratie exact gebruikt wordt. Verwijder wel altijd eerst de in Azure Devops aangemaakte issues, zodat er geen duplicaten ontstaan.

# Fouten

##  Bijlagen

Het kan voorkomen dat de volgende fout getoond wordt bij de export:
`Cannot find info for attachment '25662', skipping. Reason 'Response Content: {"errorMessages":["The attachment with id '25662' does not exist"],"errors":{}}'.`

Deze melding heb ik (Edwin) gecontroleerd in een 2-tal issues. Alle attachments zijn netjes opgenomen in de export.
Wellicht dat dit attachments zijn die opgenomen waren en later weer verwijderd zijn en dus in een bepaalde revisie aanwezig waren.

Dit resulteert bij de import in de melding:
`Could not find migrated attachment '[Removed] 25662/'.`

Deze kunnen dus genegeerd worden.

##  Jira Epics

Het blijkt dat de in Jira genoemde Epics niet altijd juist gelinkt worden in Azure Devops.

Dit kan bij de export resulteren in de melding:

```
[E][11:51:01] [Microsoft.TeamFoundation.WorkItemTracking.Client.WorkItemLinkValidationException] TF201065: You can not add a Parent link to this work item because a work item can have only one link of this type.. Link Source: 33832, Target: 33828 in 'LOA-8', rev 4 will be skipped.
[Microsoft.TeamFoundation.WorkItemTracking.Client.WorkItemLinkValidationException] Microsoft.TeamFoundation.WorkItemTracking.Client.WorkItemLinkValidationException: TF201065: You can not add a Parent link to this work item because a work item can have only one link of this type. ---> System.Web.Services.Protocols.SoapException: TF201036: You cannot add a Parent link between work items 33832 and 33828 because a work item can have only one Parent link.
   bij Microsoft.TeamFoundation.WorkItemTracking.Proxy.RetryHandler.HandleSoapException(SoapException se)
   bij Microsoft.TeamFoundation.WorkItemTracking.Proxy.WorkItemServer.Update(String requestId, XmlElement package, XmlElement& result, MetadataTableHaveEntry[] metadataHave, String& dbStamp, IMetadataRowSets& metadata)
   bij Microsoft.TeamFoundation.WorkItemTracking.Client.WorkItemStore.SendUpdatePackage(XmlElement package, XmlElement& result, Boolean bulk)
   --- Einde van intern uitzonderingsstackpad ---
   bij Microsoft.TeamFoundation.WorkItemTracking.Client.WorkItem.Save(SaveFlags saveFlags)
   bij WorkItemImport.Agent.SaveWorkItem(WiRevision rev, WorkItem newWorkItem): 
   bij Microsoft.TeamFoundation.WorkItemTracking.Client.WorkItem.Save(SaveFlags saveFlags)
   bij WorkItemImport.Agent.SaveWorkItem(WiRevision rev, WorkItem newWorkItem)
```

In de voorgaande log melding staat om welk Jira issue nummer het gaat. Zoek deze op in Azure Devops en loop alle gelinkte items na.

# Links

* [Tool jira-azuredevops-migrator](https://github.com/solidify/jira-azuredevops-migrator)
* [Tool download](https://github.com/solidify/jira-azuredevops-migrator/releases)
* [Officiële toelichting tool](https://solidify.se/blog/jira-azure-devops-migration)
* [Toelichting tool](https://peterrombouts.nl/2019/08/09/migrating-from-jira-to-azure-devops/)
* [Configuratie uitleg](https://github.com/solidify/jira-azuredevops-migrator/blob/master/docs/config.md)
