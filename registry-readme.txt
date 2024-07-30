curl -s https://raw.githubusercontent.com/mehmetihsansevinc/decice/main/registry-cert.sh | sh
kubectl create ns registry
kubectl create secret tls registry-cert --cert=/home/msevinc/registry/registry.crt --key=/home/msevinc/registry/registry.key -n registry
kubectl create secret docker-registry registry-credential --docker-server=10.233.55.68:5000 --docker-username=mehmet --docker-password=Mehmet123 --docker-email="m.ihsansevinc@gmail.com" --namespace=registry
kubectl apply -f https://raw.githubusercontent.com/mehmetihsansevinc/decice/main/registry-deployment-with-credentials.yaml


[msevinc@cn03 registry]$ curl --cacert /home/msevinc/registry/registry.crt https://10.233.55.68:5000/v2/_catalog
{"repositories":["alpine"]}

sudo mkdir -p /etc/docker/certs.d/10.233.55.68:5000
sudo cp /home/msevinc/registry/registry.crt /etc/docker/certs.d/10.233.55.68:5000/ca.crt
sudo systemctl restart docker

sudo mkdir -p /etc/docker
sudo nano /etc/docker/daemon.json
{
  "insecure-registries": ["10.233.55.68:5000"]
}

========================

- sudo nano openssl.cnf
[ req ]
default_bits        = 2048
default_md          = sha256
distinguished_name  = req_distinguished_name
req_extensions      = req_ext

[ req_distinguished_name ]
countryName                 = CN
countryName_default         = CN
stateOrProvinceName         = Beijing
stateOrProvinceName_default = Beijing
localityName                = Beijing
localityName_default        = Beijing
organizationName            = Huawei
organizationName_default    = Huawei
commonName                  = 10.233.55.68
commonName_default          = 10.233.55.68
commonName_max              = 64

[ req_ext ]
subjectAltName = DNS:registry-test.com, IP:10.233.55.68
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth


# Generate Private Key
openssl genpkey -algorithm RSA -out registry.key -pkeyopt rsa_keygen_bits:2048

# Generate CSR
openssl req -new -key registry.key -out registry.csr -subj "/C=CN/ST=Beijing/L=Beijing/O=Huawei/CN=10.233.55.68" -addext "subjectAltName=DNS:registry-test.com,IP:10.233.55.68"

# Generate self-signed certificate
openssl x509 -req -in registry.csr -signkey registry.key -out registry.crt -days 365 -extfile openssl.cnf -extensions req_ext

To verify:
openssl x509 -in registry.crt -noout -text | grep -A 1 "Subject:"
openssl x509 -in registry.crt -noout -text | grep -A 1 "Subject Alternative Name:"


