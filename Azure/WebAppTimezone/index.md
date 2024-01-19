<< [Home](https://codewithedwin.github.io/EdwinsDocumentation/)


Om de tijdzone juist in te stellen in de app services is het noodzakelijk om de tijdzone correct op te geven. Zodat de juiste datum/tijd in gebruikt wordt.
Dit dient gedaan te worden in Azure als applicatie instelling.

Open De app Service.

Ga naar Configuratie:
![AZ-appservice-TimeZone-1.png](https://codewithedwin.github.io/EdwinsDocumentation/Azure/WebAppTimezone/AZ-appservice-TimeZone-1.png)

Voeg een nieuwe Toepassingsinstellingen toe:
![AZ-appservice-TimeZone-2.png](https://codewithedwin.github.io/EdwinsDocumentation/Azure/WebAppTimezone/AZ-appservice-TimeZone-2.png)

Vul de volgende _naam_ en _waarde_ in:
![AZ-appservice-TimeZone-3.png](https://codewithedwin.github.io/EdwinsDocumentation/Azure/WebAppTimezone/AZ-appservice-TimeZone-3.png)

Naam: WEBSITE_TIME_ZONE
Waarde: W. Europe Standard Time

Klik op _Ok_ eb vervolgens op _Opslaan_ en _Doorgaan_.