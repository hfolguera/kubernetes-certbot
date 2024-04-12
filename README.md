# Letsencrypt and Certbot Install and Configuration guide

## Get Letsencrypt certificates for DuckDNS

### Obtain DuckDNS token
Access to DuckDNS console and obtain the token.
Create a file with the following format `duckdns.ini`:
```
dns_duckdns_token=AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE
```

### Docker
Run the following command to obtain a new certificate for Duckdns:
```
docker run -v "/etc/letsencrypt:/etc/letsencrypt" -v "/var/log/letsencrypt:/var/log/letsencrypt" infinityofspace/certbot_dns_duckdns:latest \
   certonly \
     --non-interactive \
     --agree-tos \
     --email hfolguera@gmail.com \
     --preferred-challenges dns \
     --authenticator dns-duckdns \
     --dns-duckdns-token <duckdns_token> \
     --dns-duckdns-propagation-seconds 60 \
     -d "*.calfolguera.duckdns.org"
```

The Duckdns token will be needed in order to configure the certificate. Obtain it from the duckdns home page.

### Create the certificate as k8s secret
Create a new secret in k8s with the following command:
```
kubectl create secret tls default-server-secret --key privkey.pem --cert fullchain.pem -n ingress-nginx
```

## Kubernetes ingress-nginx configuration

### Verify ingress-nginx deployment
Ensure the ingress-nginx deployment has the `--default-ssl-certificate` parameter correctly set:

```
kubectl edit deployment.apps/ingress-nginx-controller -n ingress-nginx
```

If needed, add the following line under the `args` section:
```
- --default-ssl-certificate=ingress-nginx/default-server-secret
```

### Force SSL
To force all connections using SSL certificate edit the configmap:
```
kubectl edit configmap ingress-nginx-controller -n ingress-nginx
```

Add the following line under `data`:
```
force-ssl-redirect: "true"
```

### Disable HSTS
Again, edit the configmap and add the following line under `data`:
```
hsts: "false"
```

## Certificate renew procedure
If your certificates has expired, you can easily renew them executing the following command:
```
./renew_certs.sh
```

Remember to edit the script and adapt the variables to your environment.

You can also automate your certificate renewal adding the previous script to cron `crontab -e`:
```
0 0 1 * * /root/certbot/renew_certs.sh
```
