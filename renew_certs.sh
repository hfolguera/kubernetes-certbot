#!/bin/bash

# Variables
EMAIL="hfolguera@gmail.com"
DOMAIN="calfolguera.duckdns.org"

# Create backup directory
mkdir -p backups

# Backup current certificate
mv -f fullchain.pem backups/
mv -f privkey.pem backups/

# Obtain duckdns token
DDNS_TOKEN=`cat duckdns.ini | cut -d = -f 2`

# Get new Certificates
docker run -v "/etc/letsencrypt:/etc/letsencrypt" -v "/var/log/letsencrypt:/var/log/letsencrypt" infinityofspace/certbot_dns_duckdns:latest \
   certonly \
     --non-interactive \
     --agree-tos \
     --email ${EMAIL} \
     --preferred-challenges dns \
     --authenticator dns-duckdns \
     --dns-duckdns-token ${DDNS_TOKEN} \
     --dns-duckdns-propagation-seconds 60 \
     -d "*.${DOMAIN}"

# Move new certificates to current folder
mv /etc/letsencrypt/live/${DOMAIN}/fullchain.pem .
mv /etc/letsencrypt/live/${DOMAIN}/privkey.pem .

# Update k8s secret
kubectl delete secret default-server-secret -n ingress-nginx
kubectl create secret tls default-server-secret --key privkey.pem --cert fullchain.pem -n ingress-nginx


