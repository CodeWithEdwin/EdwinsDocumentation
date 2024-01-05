<< [Home](https://codewithedwin.github.io/EdwinsDocumentation/)

# Opgeslagen wifi wachtwoorden

Open een commandpompt en toon alle profielen:
```
netsh wlan show profile
```

Van een enkel profiel kan je het wachtwoord dan zo opvragen:
```
netsh wlan show profile name=[Profile] key=clear | findstr Key
```