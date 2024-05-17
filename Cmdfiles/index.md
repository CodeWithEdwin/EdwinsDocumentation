<< [Home](https://codewithedwin.github.io/EdwinsDocumentation/)

# Karakterset: gebruik UTF-8(zonder BOM) en niet UTF-8-BOM 
Installatie-bestanden met de extensie *.cmd zijn tekstbestanden. 
Het uitvoeren van deze bestanden kan problemen veroorzaken wanneer als Karakterset UTF-8-BOM gebruikt.
Bij deze instellingen worden er bij het begin van het bestand de hexadecimale “ee bb bf” als eerste tekens toegevoegd. 
Deze tekens zijn alleen te zien met een HexEditor maar zorgen wel voor problemen met het uitvoeren van *.cmd bestanden. 
Dan worden alle regels op het scherm getoond en is onduidelijk wat er precies wordt uitgevoerd.  

De karakterset zal default goed staan maar ga dit niet per ongelijk veranderen. 

 