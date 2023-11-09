# Tyk Pro Demo using Docker

## Quick start

**Prerequisites**

- [Docker](https://docs.docker.com/get-docker/)

Once you have a license, Run these commands:

1. `git clone https://github.com/TykTechnologies/tyk-pro-docker-demo && cd tyk-pro-docker-demo`

2. For a bootstrapped install, run `up.sh`
OR
2. Add your Tyk Dashboard license to .env (see .env.example) and run `docker-compose up`

hint: you may need to give the executable permissions if you have an error:
```bash
chmod +x up.sh
```

Then check the terminal output to log in with your created user.

## Advanced

### Use a `Mongo` database:

The quick start uses PostgreSQL database. To use a Mongo database issue the
following command.

```
$ docker-compose -f ./docker-compose.yml -f ./docker-compose.mongo.yml up
```

### Enterprise Developer Portal:

The quick start includes the latest Enterprise Developer Portal

Please visit: http://localhost:3001
to login with the credentials in `./confs/tyk_portal.env`

### Cleanup Docker Containers

To delete all docker containers as well as remove all volumes from your host:

PostgreSQL:

```
$ docker-compose down -v
```

MongoDB:

```
$ docker-compose -f ./docker-compose.yml -f ./docker-compose.mongo.yml down -v
```

### How to enable TLS in Tyk Gateway and Tyk Dashboard

If required, generate self-signed certs for Dashboard and Gateway, e.g.

```
$ openssl req -x509 -newkey rsa:4096 -keyout tyk-gateway-private-key.pem -out tyk-gateway-certificate.pem -subj "/CN=*.localhost,tyk-*" -days 365 -nodes

$ openssl req -x509 -newkey rsa:4096 -keyout tyk-dashboard-private-key.pem -out tyk-dashboard-certificate.pem -subj "/CN=*.localhost,tyk-*" -days 365 -nodes
```

#### Enable TLS in Gateway conf (`tyk.env`)

```
TYK_GW_POLICIES_POLICYCONNECTIONSTRING=https://tyk-dashboard:3000
TYK_GW_DBAPPCONFOPTIONS_CONNECTIONSTRING=https://tyk-dashboard:3000
TYK_GW_HTTPSERVEROPTIONS_USESSL=true
TYK_GW_HTTPSERVEROPTIONS_CERTIFICATES=[{"domain_name":"localhost","cert_file":"certs/tyk-gateway-certificate.pem","key_file":"certs/tyk-gateway-private-key.pem"}]
TYK_GW_HTTPSERVEROPTIONS_SSLINSECURESKIPVERIFY=true
```

#### Enable TLS in Dashboard conf (`tyk_analytics.env`)

```
TYK_DB_TYKAPI_HOST=https://tyk-gateway
TYK_DB_HTTPSERVEROPTIONS_USESSL=true
TYK_DB_HTTPSERVEROPTIONS_CERTIFICATES=[{"domain_name":"localhost","cert_file":"certs/tyk-dashboard-certificate.pem","key_file":"certs/tyk-dashboard-private-key.pem"}]
TYK_DB_HTTPSERVEROPTIONS_SSLINSECURESKIPVERIFY=true
```

#### Update docker compose to add certificate volume mounts

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
