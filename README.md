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
