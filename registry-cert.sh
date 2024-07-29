#!/bin/bash

# Get the list of IPs from the kubectl command
ip_list=$(kubectl get nodes -o wide | grep cn | awk '{print $6}')

# Construct the subjectAltName string
subject_alt_name="subjectAltName = "
first_ip=true
for ip in $ip_list; do
    if [ "$first_ip" = true ]; then
        subject_alt_name+="IP:$ip"
        first_ip=false
    else
        subject_alt_name+=",IP:$ip"
    fi
done

# Add additional fixed IP if needed
subject_alt_name+=",IP:141.2.112.17"

# Run the OpenSSL command with the constructed subjectAltName
openssl req \
  -newkey rsa:4096 -nodes -sha256 -keyout /home/msevinc/registry/registry.key \
  -addext "$subject_alt_name" \
  -x509 -days 3650 -out /home/msevinc/registry/registry.crt
