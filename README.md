# Tyk Pro Demo using Docker

This compose file is designed to provide a quick, simple demo of the Tyk stack, this includes Tyk Gateway, Tyk Dashboard,  Mongo, & Redis.

> **Note**: This demo no longer gives you access to the Tyk Portal

This repo great for proof of concept and demo purpose, but if you want test performance, you need to move each component to separate machine, following our documentation https://tyk.io/docs/.

## Step 1: Add your dashboard license

Create `.env` file `cp .env.example .env`. Then add your license string to `TYK_DB_LICENSEKEY`.

## Step 2: Initialise the Docker containers

Run docker compose:

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

## Step 4: Bootstrap the Portal


1. Add an /etc/hosts entry for "tyk-portal.localhost" to resolve to "127.0.0.1".
2. Get your "Tyk Dashboard API Access Credential" and your "Organisation ID" from your User Profile  in the Dashboard and add them to `./scripts/portal_bootstrap.sh"
3. Run `./portal_bootstrap.sh` from terminal
4. Restart the Tyk Dashboard container:
```
$ docker restart tyk-dashboard
```

5. Now you can access your Portal on "tyk-portal.localhost:3000/portal"

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
