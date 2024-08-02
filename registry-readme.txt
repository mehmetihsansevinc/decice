
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

================

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


[msevinc@cn03 10.233.55.68:5000]$ kubectl get all -n registry
NAME                            READY   STATUS    RESTARTS   AGE
pod/registry-744846f877-mtxlx   1/1     Running   0          52m
pod/registry-744846f877-tdvx7   1/1     Running   0          52m

NAME                       TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
service/registry-service   ClusterIP   10.233.55.68   <none>        5000/TCP   52m

NAME                       READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/registry   2/2     2            2           52m

NAME                                  DESIRED   CURRENT   READY   AGE
replicaset.apps/registry-744846f877   2         2         2       52m

================

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


[msevinc@cn03 registry]$ sudo docker push 10.233.55.68:5000/nginx:latest
The push refers to repository [10.233.55.68:5000/nginx]
eafc6949fd76: Pushing [==================================================>]  7.168kB
43968a0056df: Layer already exists
75a823baa0a4: Pushed
0883bbc807e8: Layer already exists
6ad832e35023: Pushed
79c99d84246d: Pushing [=>                                                 ]  2.749MB/95.88MB
58007152def9: Pushing [=>                                                 ]  3.236MB/97.11MB
blob upload unknown
[msevinc@cn03 registry]$
[msevinc@cn03 registry]$ curl --cacert registry.crt https://10.233.55.68:5000/v2/_catalog
{"repositories":["alpine","nginx"]}
[msevinc@cn03 registry]$

============================================================================================================================================================================================================================
============================================================================================================================================================================================================================
========================================================================================================================================================================================================================================================================================================================================================================================================================================================
============================================================================================================================================================================================================================
============================================================================================================================================================================================================================

Below aexample refers to 
[msevinc@cn03 pv]$ ll
total 20
-rw-r--r--. 1 root root 189 Aug  2 12:29 pvc-test.yaml
-rw-r--r--. 1 root root 339 Aug  2 13:01 pv-pod-test.yaml
-rw-r--r--. 1 root root 220 Aug  2 12:29 pv-test.yaml
drwxrwxr-x. 3 root root  28 Aug  2 12:59 registry
-rw-r--r--. 1 root root 232 Aug  2 12:51 svc-registry.yaml
-rw-r--r--. 1 root root 593 Aug  2 12:50 test-registry.yaml



[msevinc@cn03 pv]$ sudo docker pull 10.233.29.160:5000/alpine:latest
latest: Pulling from alpine
Digest: sha256:24ba417e25e780ff13c888ccb1badec5b027944666ff695681909bafe09a3944
Status: Image is up to date for 10.233.29.160:5000/alpine:latest
10.233.29.160:5000/alpine:latest


[msevinc@cn03 pv]$ sudo docker push 10.233.29.160:5000/alpine:latest
The push refers to repository [10.233.29.160:5000/alpine]
9110f7b5208f: Pushing [==================================================>] 
latest: digest: sha256:24ba417e25e780ff13c888ccb1badec5b027944666ff695681909bafe09a3944 size: 528


[msevinc@cn03 pv]$ curl http://192.168.23.13:32766/v2/_catalog
{"repositories":["alpine"]}


[msevinc@cn03 pv]$ kubectl get all
NAME                            READY   STATUS         RESTARTS   AGE
pod/my-pod                      0/1     ErrImagePull   0          3s
pod/registry-6b8c96679f-pblvw   1/1     Running        0          24m

NAME                       TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
service/kubernetes         ClusterIP   10.233.0.1      <none>        443/TCP          4d7h
service/registry-service   NodePort    10.233.29.160   <none>        5000:32766/TCP   23m

NAME                       READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/registry   1/1     1            1           24m

NAME                                  DESIRED   CURRENT   READY   AGE
replicaset.apps/registry-6b8c96679f   1         1         1       24m


[msevinc@cn03 pv]$ kubectl logs my-pod
Error from server (BadRequest): container "my-container" in pod "my-pod" is waiting to start: image can't be pulled









