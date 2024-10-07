#!/bin/bash

# Global variables
DIR_NAME=$(dirname $0)

# Variables
EMAIL="hfolguera@gmail.com"
DOMAIN="calfolguera.duckdns.org"

# Create backup directory
mkdir -p ${DIR_NAME}/backups

# Backup current certificate
mv -f ${DIR_NAME}/fullchain.pem backups/ 2>/dev/null
mv -f ${DIR_NAME}/privkey.pem backups/ 2>/dev/null

# Obtain duckdns token
DDNS_TOKEN=`cat ${DIR_NAME}/duckdns.ini | cut -d = -f 2`

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
cp /etc/letsencrypt/live/${DOMAIN}/fullchain.pem ${DIR_NAME}/.
cp /etc/letsencrypt/live/${DOMAIN}/privkey.pem ${DIR_NAME}/.

# Remove old folders
rm -rf /etc/letsencrypt/archive/${DOMAIN}*
rm -rf /etc/letsencrypt/live/${DOMAIN}*
rm -rf /etc/letsencrypt/renewal/${DOMAIN}*

# Update k8s secret
kubectl delete secret default-server-secret -n ingress-nginx
kubectl create secret tls default-server-secret --key ${DIR_NAME}/privkey.pem --cert ${DIR_NAME}/fullchain.pem -n ingress-nginx


