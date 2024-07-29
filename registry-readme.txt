curl -s https://raw.githubusercontent.com/mehmetihsansevinc/decice/main/registry-cert.sh | sh
kubectl create ns registry
kubectl create secret tls registry-cert --cert=/home/msevinc/registry/registry.crt --key=/home/msevinc/registry/registry.key -n registry
kubectl create secret docker-registry registry-credential --docker-server=10.233.55.68:5000 --docker-username=mehmet --docker-password=Mehmet123 --docker-email="m.ihsansevinc@gmail.com" --namespace=registry
kubectl apply -f https://raw.githubusercontent.com/mehmetihsansevinc/decice/main/registry-deployment-with-credentials.yaml


We need authorized certificate. Self signed certificate leads to:
- curl: (60) SSL certificate problem: self signed certificate
- Error: trying to reuse blob sha256:9110f7b5208f035f4d4f99b5169338169e1df9bb2519d1b047f50f54430bacc2 at destination: pinging container registry 192.168.23.13:30121: Get "https://192.168.23.13:30121/v2/": tls: failed to verify certificate: x509: certificate signed by unknown authority
- [msevinc@cn03 registry]$ curl https://10.233.55.68:5000/v2/_catalog
                           curl: (60) SSL certificate problem: self signed certificate
                           More details here: https://curl.haxx.se/docs/sslcerts.html
Because of that we used "--tls-verify=false"

[msevinc@cn03 registry]$ curl --cacert /home/msevinc/registry/registry.crt https://10.233.55.68:5000/v2/_catalog
curl: (35) SSL: couldn't get X509-issuer name!

sudo docker pull alpine
sudo docker tag alpine 10.233.55.68:5000/alpine:latest
sudo docker push 10.233.55.68:5000/alpine:latest --tls-verify=false
curl -k https://10.233.55.68:5000/v2/_catalog
