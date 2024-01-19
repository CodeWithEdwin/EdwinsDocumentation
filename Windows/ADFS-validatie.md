<< [Home](https://codewithedwin.github.io/EdwinsDocumentation/)


#ADFS
 = Active Directory Federation Services

#Algemeen
Uit veiligheidsoogpunt wordt kunnen de certificaten bij het inloggen op de ADFS gecontroleerd worden.
Deze controles zijn mogenlijk:
![ADFS validatie opties](https://codewithedwin.github.io/EdwinsDocumentation/Windows/ADFS-validatie_opties.png)

Bron: https://docs.microsoft.com/en-us/dotnet/api/system.servicemodel.security.x509certificatevalidationmode?view=dotnet-plat-ext-5.0

Een Certificaat is alleen valide als:
Het certificaat uitgegeven is door een Certification authority (CA)
Het corresonderende root certificaat van de CA is geinstalleerd in Trusted Root Certification Authorities certificate store:
![image.png](https://codewithedwin.github.io/EdwinsDocumentation/Windows/certificaatStore.png)
Standaard is een publieke set van de Trusted Root Certification Authorities certificates opgenomen in Windows die voldoen aan het Microsoft Root Certificate Program. 
Systeembeheerders kunnen deze standaard set aanpassen en hun eigen CA hier in opnemen.

Dit wil dus zeggen dat de Trusted root store zowieso een juiste keuze is. Nu is de vraag wat doet de Trusted people store.

De Trusted people store is er voor om mensen en resouces te vertrouwen.

bronnen: 
https://docs.microsoft.com/en-us/windows-hardware/drivers/install/trusted-root-certification-authorities-certificate-store
https://docs.microsoft.com/en-us/dotnet/api/system.security.cryptography.x509certificates.storename?view=net-6.0

-------
#Opties

##ChainTrust
Deze optie is de meest vertrouwde methode omdat de keten van certificaten uiteindelijk uit moet komen bij een certificaat dat opgenomen in Trusted Root Certification Authorities certificate store. 
Mocht het nodig zijn kunnen systeembeheerder zelf ook certificaten toevoegen aan de Trusted Root Certification Authorities certificate store, er is daarmee altijd een mogelijkheid om een certificaat in vertrouwen te nemen.

##PeerTrust
Voor deze optie geldt dat certificaten alleen als valide worden beschouwd als die aanwezig zijn in de Trusted people store. 


##PeerOrChainTrust
Dit is de combinatie van ChainTrust en PeerTrust. Of het certificaat wordt vertrouwd als de keten van certificaten uiteindelijk uit komt bij een certificaat dat opgenomen in Trusted Root Certification Authorities 
certificate store. Of als het certificaat opgenomen is in de Trusted people store.




