<< [Home](https://codewithedwin.github.io/EdwinsDocumentation/)

# Certificaat uitlezen
```
RsaSecurityKey GetPrivateKeyFromCertificate(IConfiguration configuration)
{
    var storeName = configuration.GetSection("Certificate:Store:Name")?.Get<StoreName>() ?? StoreName.My;
    var storeLocation = configuration.GetSection("Certificate:Store:Location")?.Get<StoreLocation>() ?? StoreLocation.LocalMachine;
    var thumbprint = configuration["Certificate:Thumbprint"];

    using var store = new X509Store(storeName, storeLocation);
    store.Open(OpenFlags.ReadOnly);
    var certificate = store.Certificates
            .Find(X509FindType.FindByThumbprint, thumbprint!, false)
            .OfType<X509Certificate2>()
            .First();
			
    var privateKey = certificate.GetRSAPrivateKey();
	var publicKey = certificate.GetRSAPublicKey();

    return new RsaSecurityKey(privateKey);
}
```

Let op: Voor de private key zijn rechten nodig om deze uit te lezen.