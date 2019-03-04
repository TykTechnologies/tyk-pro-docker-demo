# This demo is NOT designed for production use or performance testing
Tyk API Gateway is fully on-premise solution, which include gateway, dashboard and analytics processing pipeline.
This demo will run Tyk On-premise on your machine, which contains 5 containers: Tyk Gateway, Tyk Dashboard, Tyk Pump, Redis and Mongodb.
This repo great for proof of concept and demo purpose, but if you want test performance, you need to move each component to separate machine, following our documentation https://tyk.io/docs/.


# Tyk Pro Demo using Docker Swarm

Please refer to [docker-swarm.md](docker-swarm.md) for detailed instructions on running this simple deployment on the Docker Swarm with Tyk cluster. Note that in order to have more than one functional gateway node a corresponding license is required.

# Tyk Pro Demo using Docker

This compose file is designed to provide a quick, simple demo of the Tyk stack, this includes the gateway, the dashboard and the portal.

## Step 1: Map hostnames to IP addresses

Set up your `/etc/hosts` file to include the IP of your docker daemon:

```
127.0.0.1 www.tyk-portal-test.com
127.0.0.1 www.tyk-test.com
```

Note that the IP may be different depending on your installation, Windows users may find it running on `10.x.x.x`, it is important the URL stays the same because our `setup.sh` assumes this is the one you are using.

## Step 2: Add your dashboard license

Open the `tyk_analytics.conf` file in the `confs/` folder and add your license string to the `"license_key": ""` section.

## Step 3: Initialise the Docker containers

Run docker compose:

```
docker-compose -f docker-compose.yml -f docker-local.yml up
```

Please note that this command may take a while to complete, as Docker needs to download and provision all of the containers.

This will run in non-daemonised mode so you can see all the output. For the next step, once this step is complete, open a new shell:

## Step 4: Bootstrap the Tyk installation

Bootstrap the instance:

```
chmod +x setup.sh 
./setup.sh 
```

## Step 5: Log in with the credentials provided

The setup script will provide a username and password, as well as the URL of your portal, please note that this will be running on port 3000, not port 80.
