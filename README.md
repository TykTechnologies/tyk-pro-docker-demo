# Tyk Pro Demo using Docker

This compose file is designed to provide a quick, simple demo of the Tyk stack, this includes Tyk Gateway, Tyk Dashboard, Tyk Portal, Mongo, & Redis.

This repo great for proof of concept and demo purpose, but if you want test performance, you need to move each component to separate machine, following our documentation https://tyk.io/docs/.

## Step 1: Add your dashboard license

Open the `tyk_analytics.env` file in the `confs/` folder and add your license string to the first line.

## Step 2: Initialise the Docker containers

Run docker compose:

```
$ docker-compose -f ./docker-compose.yml -f ./docker-compose.`database_type`.yml up
```

`database_type`: can be `mongo` or `postgres`

Please note that this command may take a while to complete, as Docker needs to download and provision all of the containers.

This will run in non-daemonised mode so you can see all the output.

## Step 3: Bootstrap the Tyk installation

Bootstrap the instance:

Open your browser to http://localhost:3000.  You will be presented with the Bootstrap UI to create your first organisation and admin user.

## Bringing down

To delete all containers as well as remove all volumes from your host:
```
$ docker-compose -f ./docker-compose.yml -f ./docker-compose.`database_type`.yml down -v
```