
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

=================

kubectl create ns registry
kubectl create secret tls registry-cert --cert=/home/msevinc/registry/registry.crt --key=/home/msevinc/registry/registry.key -n registry
kubectl create secret docker-registry registry-credential --docker-server=10.233.55.68:5000 --docker-username=mehmet --docker-password=Mehmet123 --docker-email="m.ihsansevinc@gmail.com" --namespace=registry
kubectl apply -f https://raw.githubusercontent.com/mehmetihsansevinc/decice/main/registry-deployment-with-credentials.yaml


[msevinc@cn03 registry]$ curl --cacert /home/msevinc/registry/registry.crt https://10.233.55.68:5000/v2/_catalog
{"repositories":["alpine"]}

[msevinc@cn03 registry]$ curl --cacert /home/msevinc/registry/registry.crt -u mehmet:Mehmet123 https://registry-test.com:5000/v2/_catalog
{"repositories":["alpine"]}

sudo mkdir -p /etc/docker/certs.d/10.233.55.68:5000
sudo cp /home/msevinc/registry/registry.crt /etc/docker/certs.d/10.233.55.68:5000/ca.crt
sudo systemctl restart docker

sudo mkdir -p /etc/docker
sudo nano /etc/docker/daemon.json
{
  "insecure-registries": ["10.233.55.68:5000"]
}

==================

[msevinc@cn03 registry]$ docker login 10.233.55.68:5000
Username: mehmet
Password:
WARNING! Your password will be stored unencrypted in /home/msevinc/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credentials-store

Login Succeeded
[msevinc@cn03 registry]$

==================

The problem that we are facing is about a self signed certificate.
Events:
  Type     Reason     Age                From               Message
  ----     ------     ----               ----               -------
  Normal   Scheduled  26s                default-scheduler  Successfully assigned registry/alpine-test to cn03
  Normal   BackOff    25s                kubelet            Back-off pulling image "10.233.55.68:5000/alpine:latest"
  Warning  Failed     25s                kubelet            Error: ImagePullBackOff
  Normal   Pulling    12s (x2 over 26s)  kubelet            Pulling image "10.233.55.68:5000/alpine:latest"
  Warning  Failed     12s (x2 over 26s)  kubelet            Failed to pull image "10.233.55.68:5000/alpine:latest": rpc error: code = Unknown desc = failed to pull and unpack image "10.233.55.68:5000/alpine:latest": failed to resolve reference "10.233.55.68:5000/alpine:latest": failed to do request: Head "https://10.233.55.68:5000/v2/alpine/manifests/latest": tls: failed to verify certificate: x509: certificate signed by unknown authority
  Warning  Failed     12s (x2 over 26s)  kubelet            Error: ErrImagePull
