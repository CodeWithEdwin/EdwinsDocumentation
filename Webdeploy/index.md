<< [Home](https://codewithedwin.github.io/EdwinsDocumentation/)

# Web Deploy installeren

## Controleren aanwezigheid
Alvorens Web Deploy te installeren, dient eerst gecontroleerd te worden of Web Deploy al aanwezig is. Open hiervoor de map _%programfiles%\IIS\_ en controleer of één (of meer) van de volgende mappen aanwezig is:
* Microsoft Web Deploy V3
* Microsoft Web Deploy V2
* Microsoft Web Deploy
Indien geen van deze mappen aanwezig is, dient Web Deploy geïnstalleerd te worden.

## Installeren via Web PI
De volgende stappen kunnen doorlopen worden om Web Deploy te installeren. Mocht het installeren via onderstaande stappen niet succesvol zijn, dan kan men deze handmatig uitvoeren.

1.  Open IIS
2.  Selecteer onder de connecties de geconnecte machine.
3.  Klik op ‘Get new Web Platform components’
4.  Opent er geen website, ga dan verder naar punt 6. Opent er wel een website: klik op ‘Install this extension’. En installeer deze (gedownloade) extensie.
5.  Heropen IIS en klik wederom op ‘Get new Web Platform components’
6.  Er wordt nu een scherm geladen.
7.	Zoek op ‘Web Deploy’
8.	Klik op Add achter ‘Web Deploy 3.6’
9.	Klik op Install
10.	Accepteer de Prerequisites
11.	Na de installatie kan worden aangegeven dat niet alles geïnstalleerd is. Dit is niet erg zolang Web Deploy wel goed geïnstalleerd is.
12.	Klik op Finish en Exit bij het onderliggende scherm
13.	Sluit IIS en start deze opnieuw op, nu zijn de Deploy opties 

Bron: [microsoft](https://docs.microsoft.com/en-us/iis/install/installing-publishing-technologies/installing-and-configuring-web-deploy-on-iis-80-or-later)

## Handmatig installeren
Mocht het onverhoopt niet lukken om Web Deploy te installeren via de Web PI, dan is het altijd nog mogelijk om deze handmatig te installeren. Het nadeel hiervan is dat aanbevolen of benodigde afhankelijke producten niet geïnstalleerd worden. Dit vormt voor de installatie van Monitoring geen problemen.
1.	Ga naar de website van [Web Deploy](https://www.iis.net/downloads/microsoft/web-deploy)
2.	Navigeer naar het onderdeel _[Download Web deploy]( https://www.iis.net/downloads/microsoft/web-deploy#additionalDownloads)_
3.	Download de installatie in de juiste taal en voor het juiste systeem (x86 of x64).
4.	Installeer deze door de installatie wizard te doorlopen, kies hierbij voor de complete installatie methode.

Bron: [microsoft](https://docs.microsoft.com/en-us/iis/install/installing-publishing-technologies/installing-and-configuring-web-deploy-on-iis-80-or-later)