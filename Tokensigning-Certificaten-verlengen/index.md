<< [Home](https://codewithedwin.github.io/EdwinsDocumentation/)


Als het token-signing certificaat verlopen is kan de volgende melding getoond worden bij het starten van de website:
![TokenSigingVerlopen.png](https://codewithedwin.github.io/EdwinsDocumentation/Tokensigning-Certificaten-verlengen/TokenSigingVerlopen.png)

Als je self-signed certificaten gebruikt kan je deze met PowerShell vernieuwd worden. Dit blijkt overigens alleen te kunnen wanneer de ADFS running is (zie de N.B. onderaan).

Controleren of certificaat verlopen is:
Voer in een PowerShell (run as administrator) het volgende commando:
```Get-ADFSCertificate –CertificateType token-signing```
Hieronder een voorbeeld:
![ADFS_CertificaatContole.png](https://codewithedwin.github.io/EdwinsDocumentation/Tokensigning-Certificaten-verlengen/ADFS_CertificaatContole.png)

De Thumbprint die bij CERTIFICATE getoond wordt, dient gebruikt te worden in de web.config.
**Let op: gebruik de Thumbprint van het certificaat IsPrimary: true.**

Het vernieuwen van de certificaten kan door het volgende commando uit te voeren: 
```Update-ADFSCertificate –CertificateType token-signing```

Door nu weer het ```Get-ADFSCertificate –CertificateType token-signing``` commando uit te voeren kan gecontroleerd worden wat de nieuwe thumbprint moet zijn.

```Get-ADFSCertificate –CertificateType token-decrypting``` om het decrypting token op dezelfde manier te updaten met:
```Update-ADFSCertificate –CertificateType token-decrypting```

Voeg bij de update commando's eventueel de optie -Urgent toe als de foutmelding dit aangeeft.

Het e.e.a. staat ook beschreven op 
[microsoft](https://docs.microsoft.com/en-us/windows-server/identity/ad-fs/operations/configure-ts-td-certs-ad-fs)

N.B. In januari 2023 kwamen we er achter dat PowerShell-commando's als "Get-ADFSCertificate" uitsluitend werken als de ADFS running is. Als het certificaat al langer is verlopen dan is ADFS niet meer op te starten en werkt dit niet meer. Het verlopen was mogelijk niet opgetreden wanneer voor het verlengen van een certificaat "AutoUpdate" was ingesteld. E.e.a. moet nog nader onderzocht worden.


