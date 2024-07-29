curl -s https://raw.githubusercontent.com/mehmetihsansevinc/decice/main/registry-cert.sh | sh
kubectl create ns registry
kubectl create secret tls registry-cert --cert=/home/msevinc/registry/registry.crt --key=/home/msevinc/registry/registry.key -n registry
kubectl apply -f https://raw.githubusercontent.com/mehmetihsansevinc/decice/main/registry-deployment.yaml


We need authorized certificate. Self signed certificate leads to:
- curl: (60) SSL certificate problem: self signed certificate
- Error: trying to reuse blob sha256:9110f7b5208f035f4d4f99b5169338169e1df9bb2519d1b047f50f54430bacc2 at destination: pinging container registry 192.168.23.13:30121: Get "https://192.168.23.13:30121/v2/": tls: failed to verify certificate: x509: certificate signed by unknown authority
Because of that we used "--tls-verify=false"


[msevinc@cn03 registry]$ sudo docker push 192.168.23.13:30121/alpine:latest --tls-verify=false
Emulate Docker CLI using podman. Create /etc/containers/nodocker to quiet msg.
Getting image source signatures
Copying blob 9110f7b5208f done   |
Copying config 0b4426ad4b done   |
Writing manifest to image destination
[msevinc@cn03 registry]$


[msevinc@cn03 registry]$ curl -k https://192.168.23.13:30121/v2/_catalog
{"repositories":["alpine"]}
