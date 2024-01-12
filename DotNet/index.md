<< [Home](https://codewithedwin.github.io/EdwinsDocumentation/)

# .Net versie controle
Controleren of het .Net Framework versie 4.8 aanwezig is kan door het volgende commando uit te voeren in PowerShell:
(Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full").Release -ge 528040

Uitkomst: 
True – .Net Framework versie 4.8 is minimaal geïnstalleerd
False – .Net Framework versie 4.8 is niet geïnstalleerd

Bron: [Microsoft][https://learn.microsoft.com/en-us/dotnet/framework/migration-guide/how-to-determine-which-versions-are-installed]
