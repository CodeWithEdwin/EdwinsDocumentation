[[_TOC_]]

# Probleem
-----------------------------------------------------
Voor gebruiken we self-signed certificaten en deze kunnen met PowerShell vernieuwd worden. Dit blijkt  alleen te kunnen wanneer de _Active Directory Federation Services_ draait.

Als het token-signing certificaat verlopen is kan de volgende melding getoond worden bij het starten van de website:
![TokenSigingVerlopen.png](https://codewithedwin.github.io/EdwinsDocumentation/Tokensigning-Certificaten-verlengen/TokenSigingVerlopen-19015023-b059-4da9-bd1a-e7f1f1b3756c.png)
<small>Wellicht een andere melding als de _Active Directory Federation Services_ niet draait.<small>

Als het certificaat al langere tijd is verlopen, dan is de _Active Directory Federation Services_ niet meer op te starten en is het updaten niet langer mogelijk. Deze melding wordt dan getoond bij het starten van de service:
![image.png](https://codewithedwin.github.io/EdwinsDocumentation/Tokensigning-Certificaten-verlengen/image-625cf974-edff-448b-b0b3-83708f18f54f.png) 

In de event viewer zie je dan de volgende meldingen:
![image.png](https://codewithedwin.github.io/EdwinsDocumentation/Tokensigning-Certificaten-verlengen/image-1b2997eb-e449-468c-8c86-1e25ddba428d.png)


# Start ADFS-service
-----------------------------------------------------
Als de _Active Directory Federation Services_ niet meer start volg de onderstaande stappen.

1. Login als administator op de ADFS-machine
1. Open services.msc en Stop _Hyper-V Time Synchronization Service_
   Wanneer je de datum/tijd op de server terugzet dan wordt die automatisch weer naar de juiste datum/tijd terugzet. 
   Dit komt door de _Hyper-V Time Synchronization Service_. Zet deze service service tijdelijk uit.
1. Zet de windows tijd 9 manden terug
1. Open services.msc en Start _Active Directory Federation Services_
1. Verleng de certificaten zie paragraaf [Verleng Certificaten](#Verleng-Certificaten)
1. Open services.msc en start _Hyper-V Time Synchronization Service_
1. Controleer dat de windows tijd weer op NU staat
1. Verleng de certificaten nogmaals zie paragraaf [Verleng Certificaten](#Verleng-Certificaten)
   In eerdere stappen wordt een nieuw certficaat aangemaakt die 1 jaar geldig is vanaf de windows tijd.
   Daarom in deze stap nogmaals doen, zodat het certificaat vanaf het nu 1 jaar geldig is.

# Verleng Certificaten
-----------------------------------------------------
Er zijn twee soorten certificaten die kunnen verlopen. 
- Token-signing
- token-decrypting

## Token-igning certificaat controleren met Powershell
-----------------------------------------------------
1. Open PowerShell als administrator
1. Voer het volgende commando in:
   ```Get-ADFSCertificate –CertificateType token-signing```
   Hieronder een voorbeeld:
   ![image.png](https://codewithedwin.github.io/EdwinsDocumentation/Tokensigning-Certificaten-verlengen/image-4e554c2f-9f87-46cf-a0bc-3bafccc2d8e8.png)
1. Controleer dat de certificaten verlopen zijn


## Token-decrypting certificaat controleren met Powershell
-----------------------------------------------------
1. Open PowerShell als administrator
1. Voer het volgende commando in:
   ```Get-ADFSCertificate –CertificateType token-decrypting```
   Hieronder een voorbeeld:
   ![image.png](https://codewithedwin.github.io/EdwinsDocumentation/Tokensigning-Certificaten-verlengen/image-f0371d8a-97ed-40f4-afe4-39edfea0cf1a.png)
1. Controleer dat de certificaten verlopen zijn

## Vernieuw Token-signing certificaat 
-----------------------------------------------------
1. Open PowerShell als administrator
1. Voer het volgende commando in:
   ```Update-ADFSCertificate –CertificateType token-signing```
   Hieronder een voorbeeld:
   ![image.png](https://codewithedwin.github.io/EdwinsDocumentation/Tokensigning-Certificaten-verlengen/image-ad1897be-c21f-46f7-97fe-4e1af217a93a.png)

## Vernieuw Token-decrypting certificaat
-----------------------------------------------------
1. Open PowerShell als administrator
1. Voer het volgende commando in:
   ```Update-ADFSCertificate –CertificateType token-decrypting```
   Hieronder een voorbeeld:
   ![image.png](https://codewithedwin.github.io/EdwinsDocumentation/Tokensigning-Certificaten-verlengen/image-09d313dd-aa15-4756-bd65-c8a8a478bdde.png)

# Web.config aanpassen
-----------------------------------------------------
1. Open PowerShell als administrator
1. Voer het volgende commando in:
   ```Get-ADFSCertificate –CertificateType token-signing```
   Hieronder een voorbeeld:
   ![image.png](https://codewithedwin.github.io/EdwinsDocumentation/Tokensigning-Certificaten-verlengen/image-4e554c2f-9f87-46cf-a0bc-3bafccc2d8e8.png)
1. Kopieer de thumbprint van het certificaat waarbij _IsPrimary: True_ staat.
1. Zet deze Thumprint in de web.config in het thumbprint-attribuut onder _trustedIssuers_
   ![image.png](https://codewithedwin.github.io/EdwinsDocumentation/Tokensigning-Certificaten-verlengen/image-f411ecf2-eb78-4899-8dfc-56763a16dafe.png)

De Thumbprint dient gebruikt te worden in de web.config's van de development machines (onder zowel IIS als bij debuggen in VS) en daarnaast in de web.config bestanden van de test-machines.

# Notes
-----------------------------------------------------
N.B. Voor het verlengen van een certificaat is mogelijk "AutoUpdate" in te stellen. Dit kan t.z.t. nader onderzocht worden.

In januari 2024 was voorafgaande aan het tijdelijke terugzetten van de datumtijd en de genoemde update acties, al het PowerShell commando ```certutil -repairstore my *``` uitgevoerd. Hierdoor stond er al een nieuw certificaat in de Windows Internal Database. Als de eerdere acties niet werken, zoek dan het gebruik van het commando ```certutil``` nader uit en kijk of dit een oplossing is.

## Certificaten in AD FS Management tonen
-----------------------------------------------------
Controleren of certificaat verlopen is:
1. Open de _AD FS Management_:
![image.png](https://codewithedwin.github.io/EdwinsDocumentation/Tokensigning-Certificaten-verlengen/image-6936b721-d71f-4856-8852-29fe9507667a.png)
1. Ga naar Services -> Certificates
![image.png](https://codewithedwin.github.io/EdwinsDocumentation/Tokensigning-Certificaten-verlengen/image-adf96605-f3e5-4ac2-9e36-41198369297a.png)
1. Controleer dat de certificaten verlopen zijn


# Bronnen
-----------------------------------------------------
[microsoft / configure-ts-td-certs-ad-fs](https://docs.microsoft.com/en-us/windows-server/identity/ad-fs/operations/configure-ts-td-certs-ad-fs)