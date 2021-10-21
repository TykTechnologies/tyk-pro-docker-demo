# This demo is NOT designed for production use or performance testing
Tyk API Gateway is fully on-premise solution, which include gateway, dashboard and analytics processing pipeline.

This demo will run Tyk On-premise on your machine, which contains 5 containers: Tyk Gateway, Tyk Dashboard, Tyk Pump, Redis and Mongodb.

This repo great for proof of concept and demo purpose, but if you want test performance, you need to move each component to separate machine, following our documentation https://tyk.io/docs/.

# Tyk Pro Demo using Docker

This compose file is designed to provide a quick, simple demo of the Tyk stack, this includes the gateway, the dashboard and the portal.

## Step 1: Add your dashboard license

Open the `tyk_analytics.env` file in the `confs/` folder and add your license string to the first line.

## Step 2: Initialise the Docker containers

Run docker compose:

```
docker-compose up
```

Please note that this command may take a while to complete, as Docker needs to download and provision all of the containers.

This will run in non-daemonised mode so you can see all the output. For the next step, once this step is complete, open a new shell:

## Step 3: Bootstrap the Tyk installation

Bootstrap the instance:

Open your browser to http://www.tyk-test.com:3000.  You will be presented with the Bootstrap UI to create your first organisation and admin user.

## Bringing down

To delete all containers as well as remove all volumes from your host:
```
$ docker-compose down -v
```