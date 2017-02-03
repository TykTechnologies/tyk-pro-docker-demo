# Tyk Pro Demo using Docker

This compose file is designed to provide a quick, simple demo of the Tyk stack, this includes the gateway, the dashboard and the portal.

## Step 1:

Set up your `/etc/hosts` file to include the IP of your docker daemon:

```
127.0.0.1 www.tyk-portal-test.com
127.0.0.1 www.tyk-test.com
```

Note that the IP may be different depending on your installation, Windows users may find it running on `10.x.x.x`, it is important the URL stays the same because our `setup.sh` assumes this is the one you are using.

## Step 2: Add your dashboard license

Open the `tyk_analytics.conf` file in the `confs/` folder and add your license string to the `"license_key": ""` section.

## Step 2:

Run docker compose:

```
docker-compose up
```

This will run in non-daemonised mode so you can see all the output. For the next step, open a new shell:

# Step 3:

Bootstrap the instance:

```
chmod +x setup.sh 
./setup.sh 
```

# Step 4: Log in with the credentials provided.

The setup script will provide a username and password, as well as the URL of your portal, please note that this will be running on port 3000, not port 80.
