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

# String template met waarden vullen
```
 /// <summary>
        /// Van template naar string
        /// Vervangen van variablen tussen { en } door opgegeven waarden
        /// eerste variable wordt vervangen door eerste object
        /// Volgorde is dus belangrijk.
        /// </summary>
        /// <param name="template">template string</param>
        /// <param name="replaceValues"></param>
        /// <returns></returns>
        /// <exception cref="ArgumentException"></exception>
        /// <exception cref="Exception"></exception>
        public static string ToString(this string template, params object?[] replaceValues)
        {
            if (string.IsNullOrEmpty(template))
            {
                return template;
            }

            if (template.ToCharArray().Count(c => c.Equals('{')) != replaceValues.Length)
            {
                throw new ArgumentException("Aantal variabelen komen niet overeen met de string interpolation", nameof(replaceValues));
            }

            foreach (var value in replaceValues)
            {
                var start = template.IndexOf("{");
                var length = template[start..].IndexOf("}");
                if (length <= 0)
                {
                    return template;
                }

                var toReplace = template.Substring(start, length + 1);
                template = template.Replace($"{toReplace}", $"{value}");
            }

            return template;
        }
```
