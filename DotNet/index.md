<< [Home](https://codewithedwin.github.io/EdwinsDocumentation/)

# .Net versie controle
Controleren of het .Net Framework versie 4.8 aanwezig is kan door het volgende commando uit te voeren in PowerShell:
```
(Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full").Release -ge 528040
```
Uitkomst: 

* True – .Net Framework versie 4.8 is minimaal geïnstalleerd
* False – .Net Framework versie 4.8 is niet geïnstalleerd

Bron: [Microsoft](https://learn.microsoft.com/en-us/dotnet/framework/migration-guide/how-to-determine-which-versions-are-installed)

# IIS installeren voor .NET
Installeer de web server op de volgende manier: 
* Open Server Manager (Start > Administrative Tools > Server Manager).
* Kies ‘Add Roles and features’
* Selecteer ‘Role-based or feature based installation’, Next
* selecteer deze server uit de server pool en klik Next
* Selecteer de rol ‘Web Server (IIS)’
* Klik ‘Add Features’ in het popup window
* Klik Next
* Selecteer bij Features ‘HTTP Activation’, ‘TCP Activation’ en ‘TCP Port Sharing’ onder ‘.Net Framework 4.6 Features > WCF Services’ en accepteer de extra features die hij wil installeren.
* Klik 2x Next
* Selecteer:
	- ‘WebServer (IIS) > Web Server > Security > Windows Authentication’
	- ‘WebServer (IIS) > Management tools -> IIS Management Console’
	- ‘WebServer (IIS) > Management tools -> Management Service’
	- ‘WebServer (IIS) > Management tools -> IIS Management Scripts and Tools’
* Klik weer ‘Next’.
* Klik op Install