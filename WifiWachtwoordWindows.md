<< [Home](https://codewithedwin.github.io/EdwinsDocumentation/)

# Opgeslagen wifi wachtwoorden

Open een commandpompt en toon alle profielen:

_netsh wlan show profile_


Van een enkel profiel kan je het wachtwoord dan zo opvragen:

_netsh wlan show profile name=[Profile] key=clear | findstr Key_