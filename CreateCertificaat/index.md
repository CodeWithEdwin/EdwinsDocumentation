<< [Home](https://codewithedwin.github.io/EdwinsDocumentation/)

# Algemeen
De AAG heeft voor het valideren van de BSN-JWT die de MADStub terug geeft een certificaat nodig met een Public key.
De MADStub moet de Private key hebben om het BSN-JWT aan te kunnen maken. Hier staat beschreven hoe je een private key kunt aanmaken met het bij behorende certificaat.

Het certificaat moet je vervolgens installeren in de Certificaat store van Windows. De Thumbprint van het certificaat moet in de AAG opgenomen worden in de appsettings.

# Certificaat maken

## 1. Openssl op VDI
Om een certificaat aan te maken is Openssl nodig.
Deze kan je installeren vanaf: https://slproweb.com/products/Win32OpenSSL.html

## 2. Start openssl
In de installatie map van openssl staat het bestand _start.bat_: 
`C:\Program Files\OpenSSL-Win64\start.bat`
Door deze te starten kun je openssl commando's ingeven.


## 3. Private key aanmaken
Voer het volgende command uit om een private key aan te maken:
`openssl genrsa -traditional -out c:\PrivateKey.pem 2048`

<div style="color: #664d03; background-color: #fff3cd; padding: 1rem 1rem;">

![LetOpIcon.png](/.attachments/LetOpIcon-56b7dedd-e877-4f2f-b8be-bc9d38f36523.png =25x25) _traditional_ parameter is nodig om een _BEGIN RSA PRIVATE KEY_ pem file te genereren.
Zonder deze parameter wordt het een _BEGIN PRIVATE KEY_ en dat gaat mis in de MADStub.
</div></br>

<small>bron: [openssl genrsa](https://www.openssl.org/docs/manmaster/man1/genrsa.html)</small>

## 4. Public key aanmaken
Voer het volgende command uit om een public key aan te maken:
`openssl rsa -pubout -in c:\PrivateKey.pem -out c:\PublicKey.pem`

<small>bron: [openssl rsa](https://www.openssl.org/docs/manmaster/man1/rsa.html)</small>

## 5. Certificaat aanvraag maken
Voor het aanvragen van een SSL certificaat heb je een CSR (Certificate Signing Request) nodig. Dit is een stukje gecodeerde tekst met daarin informatie van het aan te vragen certificaat.

Voer het volgende command uit om een Certificate Signing Request aan te maken:
`openssl req -new -key c:\PrivateKey.pem -out c:\Request.csr`

<small>bron: [openssl req](https://www.openssl.org/docs/manmaster/man1/req.html)</small>

Er worden nu enkele gegevens gevraagd, die ingevuld moeten worden om een certificaat aanvraag te maken.

Als er gevraagd word _Common Name (e.g. server FQDN or YOUR name)_, vul dan een herkenbare naam in, bijv. MAD-Stub.
Dit is de naam waaraan het certificaat herkend kan worden.

Als er gevraagd word _A challenge password_ laat deze dan leeg.

## 6. Certificaat maken
Voer het volgende command uit om een certificaat file aan te maken:
`openssl x509 -req -days 3650 -in c:\Request.csr -signkey c:\PrivateKey.pem -out c:\Certificate.cer`

<small>bron: [openssl x509](https://www.openssl.org/docs/manmaster/man1/x509.html)</small>


# Certificaat installeren
TODO
