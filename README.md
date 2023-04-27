# Tyk Pro Demo using Docker

This compose file is designed to provide a quick, simple demo of the Tyk stack. It stands up instances of Tyk Gateway, Tyk Dashboard, Tyk Pump, Redis, and Mongo or PostgreSQL.

> **Note**: This demo no longer gives you access to the Tyk Portal

This repo is great for proof of concept and demo purposes, but if you want to test performance, we strongly recommend that you move each component to a separate machine, following our documentation https://tyk.io/docs/.

## Step 1: Add your dashboard license

Create `.env` file `cp .env.example .env`. Then add your Tyk Dashboard license string to `TYK_DB_LICENSEKEY` within your new `.env`.

## Step 2: Initialise the Docker containers

Run Docker compose:

With a `PostgreSQL` database:
```
$ docker-compose up
```

With a `Mongo` database:
```
$ docker-compose -f ./docker-compose.yml -f ./docker-compose.mongo.yml up
```

Please note that this command may take a while to complete, as Docker needs to download and provision all of the containers.

This will run in non-daemonised mode so you can see all the output. 

## Step 3: Bootstrap the Tyk installation

Bootstrap the instance:

Open your browser to http://localhost:3000.  You will be presented with the Bootstrap UI to create your first organisation and admin user.

Enjoy exploring the power of Tyk!

## Tear down

To delete all containers as well as remove all volumes from your host:

PostgreSQL:
```
$ docker-compose down -v
```

MongoDB:
```
$ docker-compose -f ./docker-compose.yml -f ./docker-compose.mongo.yml down -v
```


## How to enable TLS in Tyk Gateway and Tyk Dashboard

If required, generate self-signed certs for Dashboard and Gateway, e.g.

```
$ openssl req -x509 -newkey rsa:4096 -keyout tyk-gateway-private-key.pem -out tyk-gateway-certificate.pem -subj "/CN=*.localhost,tyk-*" -days 365 -nodes

$ openssl req -x509 -newkey rsa:4096 -keyout tyk-dashboard-private-key.pem -out tyk-dashboard-certificate.pem -subj "/CN=*.localhost,tyk-*" -days 365 -nodes
```

### Enable TLS in Gateway conf (`tyk.env`)
```
TYK_GW_POLICIES_POLICYCONNECTIONSTRING=https://tyk-dashboard:3000
TYK_GW_DBAPPCONFOPTIONS_CONNECTIONSTRING=https://tyk-dashboard:3000
TYK_GW_HTTPSERVEROPTIONS_USESSL=true
TYK_GW_HTTPSERVEROPTIONS_CERTIFICATES=[{"domain_name":"localhost","cert_file":"certs/tyk-gateway-certificate.pem","key_file":"certs/tyk-gateway-private-key.pem"}]
TYK_GW_HTTPSERVEROPTIONS_SSLINSECURESKIPVERIFY=true
```

### Enable TLS in Dashboard conf (`tyk_analytics.env`)
```
TYK_DB_TYKAPI_HOST=https://tyk-gateway
TYK_DB_HTTPSERVEROPTIONS_USESSL=true
TYK_DB_HTTPSERVEROPTIONS_CERTIFICATES=[{"domain_name":"localhost","cert_file":"certs/tyk-dashboard-certificate.pem","key_file":"certs/tyk-dashboard-private-key.pem"}]
TYK_DB_HTTPSERVEROPTIONS_SSLINSECURESKIPVERIFY=true
```

### Update docker compose to add certificate volume mounts

`tyk-dashboard`
```
volumes:
   - ./certs/tyk-dashboard-certificate.pem/:/opt/tyk-dashboard/certs/tyk-dashboard-certificate.pem
   - ./certs/tyk-dashboard-private-key.pem/:/opt/tyk-dashboard/certs/tyk-dashboard-private-key.pem
```

`tyk-gateway`
```
volumes:
   - ./certs/tyk-gateway-certificate.pem/:/opt/tyk-gateway/certs/tyk-gateway-certificate.pem
   - ./certs/tyk-gateway-private-key.pem/:/opt/tyk-gateway/certs/tyk-gateway-private-key.pem
```
