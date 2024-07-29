curl -s https://raw.githubusercontent.com/mehmetihsansevinc/decice/main/registry-cert.sh | sh
kubectl create ns registry
kubectl create secret tls registry-cert --cert=/home/msevinc/registry/registry.crt --key=/home/msevinc/registry/registry.key -n registry
kubectl apply -f registry-deployment.yaml


We need authorized certificate. Self signed certificate leads to:
- curl: (60) SSL certificate problem: self signed certificate
- Error: trying to reuse blob sha256:9110f7b5208f035f4d4f99b5169338169e1df9bb2519d1b047f50f54430bacc2 at destination: pinging container registry 192.168.23.13:30121: Get "https://192.168.23.13:30121/v2/": tls: failed to verify certificate: x509: certificate signed by unknown authority
- [msevinc@cn03 registry]$ curl https://10.233.55.68:5000/v2/_catalog
                           curl: (60) SSL certificate problem: self signed certificate
                           More details here: https://curl.haxx.se/docs/sslcerts.html
Because of that we used "--tls-verify=false"

[msevinc@cn03 registry]$ curl --cacert /home/msevinc/registry/registry.crt https://10.233.55.68:5000/v2/_catalog
curl: (35) SSL: couldn't get X509-issuer name!
- ignoring certs works.
[msevinc@cn03 registry]$ curl -k --cacert /home/msevinc/registry/registry.crt https://10.233.55.68:5000/v2/_catalog
{"repositories":["alpine"]}

sudo docker pull alpine
sudo docker tag alpine 10.233.55.68:5000/alpine:latest
sudo docker push 10.233.55.68:5000/alpine:latest --tls-verify=false
curl -k https://10.233.55.68:5000/v2/_catalog



========================

- sudo nano openssl.cnf
[ req ]
default_bits        = 2048
default_md          = sha256
distinguished_name  = req_distinguished_name
req_extensions      = req_ext

[ req_distinguished_name ]
countryName                 = Country Name (2 letter code)
countryName_default         = US
stateOrProvinceName         = State or Province Name (full name)
stateOrProvinceName_default = California
localityName                = Locality Name (eg, city)
localityName_default        = San Francisco
organizationName            = Organization Name (eg, company)
organizationName_default    = My Company
commonName                  = Common Name (e.g. server FQDN or YOUR name)
commonName_max              = 64

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
IP.1 = 192.168.23.13
IP.2 = 192.168.23.18
IP.3 = 141.2.112.17
IP.4 = 10.233.55.68

- openssl req -new -x509 -days 365 -nodes -out registry.crt -keyout registry.key -config openssl.cnf





