# Tyk Pro Demo using Docker

## Quick start

### Prerequisites

1. Install [Docker](https://docs.docker.com/get-docker/)
2. Get a license for [Tyk Self-Managed](https://tyk.io/sign-up/) (choose "on your infrastructure"). This is a self-service option!


### Deploying Tyk

1. Close the repo: `git clone https://github.com/TykTechnologies/tyk-pro-docker-demo && cd tyk-pro-docker-demo`

2. For a bootstrapped install, run `up.sh`
OR
2. Add your Tyk Dashboard license to .env (see .env.example) and run `docker-compose up`

**gotcha:** you may need to give the executable permissions if you have an error:
`chmod +x up.sh`


4. The script sends to the STDOUT the details you need to open and log in to Tyk Dashobard:
```
---------------------------
Please sign in at http://localhost:3000

user: dev@tyk.io
pw: topsecret

Your Tyk Gateway is found at http://localhost:8080

Press Enter to exit
```

## Advanced

### Use a `Mongo` database:

The quick start uses PostgreSQL database. To use a Mongo database issue the
following command.

```
$ docker-compose -f ./docker-compose.yml -f ./docker-compose.mongo.yml up
```

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
</br>

### Running the Enterprise Developer Portal:

#### Prerequisites - a license

If you have a license for the portal add it as an env var `PORTAL_LICENSEKEY` in `.env`.
If you don't, please contact support@tyk.io
**Note:** The bootstrap process will fail if the licence is not present.


The quick start includes the latest Enterprise Developer Portal or any version defined in `.env` with `PORTAL_VERSION` env var.

Please visit: [http://localhost:3001](http://localhost:3001)
Login with the credentials in `./confs/tyk_portal.env`

</br>

### Enable TLS in Tyk Gateway and Tyk Dashboard

If you need, generate self-signed certificates for Dashboard and Gateway, e.g.

```
$ openssl req -x509 -newkey rsa:4096 -keyout tyk-gateway-private-key.pem -out tyk-gateway-certificate.pem -subj "/CN=*.localhost,tyk-*" -days 365 -nodes

$ openssl req -x509 -newkey rsa:4096 -keyout tyk-dashboard-private-key.pem -out tyk-dashboard-certificate.pem -subj "/CN=*.localhost,tyk-*" -days 365 -nodes
```

#### Enable TLS in Gateway conf (`tyk.env`)

```env
TYK_GW_POLICIES_POLICYCONNECTIONSTRING=https://tyk-dashboard:3000
TYK_GW_DBAPPCONFOPTIONS_CONNECTIONSTRING=https://tyk-dashboard:3000
TYK_GW_HTTPSERVEROPTIONS_USESSL=true
TYK_GW_HTTPSERVEROPTIONS_CERTIFICATES=[{"domain_name":"localhost","cert_file":"certs/tyk-gateway-certificate.pem","key_file":"certs/tyk-gateway-private-key.pem"}]
TYK_GW_HTTPSERVEROPTIONS_SSLINSECURESKIPVERIFY=true
```

#### Enable TLS in Dashboard conf (`tyk_analytics.env`)

```env
TYK_DB_TYKAPI_HOST=https://tyk-gateway
TYK_DB_HTTPSERVEROPTIONS_USESSL=true
TYK_DB_HTTPSERVEROPTIONS_CERTIFICATES=[{"domain_name":"localhost","cert_file":"certs/tyk-dashboard-certificate.pem","key_file":"certs/tyk-dashboard-private-key.pem"}]
TYK_DB_HTTPSERVEROPTIONS_SSLINSECURESKIPVERIFY=true
```

#### Update docker compose to add certificate volume mounts


##### Tyk Dashboard

```
volumes:
   - ./certs/tyk-dashboard-certificate.pem/:/opt/tyk-dashboard/certs/tyk-dashboard-certificate.pem
   - ./certs/tyk-dashboard-private-key.pem/:/opt/tyk-dashboard/certs/tyk-dashboard-private-key.pem
```

##### Tyk Gateway

```
volumes:
   - ./certs/tyk-gateway-certificate.pem/:/opt/tyk-gateway/certs/tyk-gateway-certificate.pem
   - ./certs/tyk-gateway-private-key.pem/:/opt/tyk-gateway/certs/tyk-gateway-private-key.pem
```

</br>

### Tyk Streams
To use Tyk Stream you need to run the deployment with specific versions of Tyk. Update your `.env` file as follows:
```env
GATEWAY_VERSION="v5.4.0-alpha5"
PORTAL_VERSION="v1.10.0-alpha2"
DASHBOARD_VERSION="s5.4.0-alpha1"
```
For details on using Tyk stream please refer to our [official docs](tyk.io/docs)

