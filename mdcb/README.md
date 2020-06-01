# MDCB setup guide

### 0. Prequisites
Note -> These instructions are run on Linux. (AWS Linux 2)

Run these to install Docker, Docker-Compose & Git
```
sudo yum update -y
sudo yum install git -y
sudo yum install -y docker
sudo service docker start
sudo usermod -aG docker ec2-user
sudo su
sudo curl -L "https://github.com/docker/compose/releases/download/1.25.5/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
docker ps
```

### 1. Install tyk pro

A) Clone repo and checkout branch, go to mdcb folder
```
git clone https://github.com/TykTechnologies/tyk-pro-docker-demo
cd tyk-pro-docker-demo/
git checkout mdcb
cd mdcb
```

B) Add tyk pro license to `confs/tyk_analytics.conf` to the `license_key` variable.

### 2. Run Stack
`docker-compose up -d`

### 3. Bootstrap the install
Log on to the Dashboard via `http://<your-host>:3000`

### 4. RUN MDCB from RPM
A) Download the MDCB package

`curl -s https://TOKEN:@packagecloud.io/install/repositories/tyk/tyk-mdcb/script.rpm.sh | sudo bash`

B) Install It

`sudo yum install tyk-sink`

C) Edit /opt/tyk-sink/tyk_sink.conf

-Add your MDCB license to `license`

-Update `storage.port` to `6380`

D) Run the Service
```
sudo systemctl start tyk-sink
sudo systemctl enable tyk-sink
```

Check it's running:
```
sudo journalctl -u tyk-sink 
```
Output:

<response>

### 5. Enable Hybrid on Master DC

Export the defaults
```
export DASH_ADMIN_SECRET=12345
export DASH_URL=localhost:3000
```

Export your Dashboard's ORG ID
```
export ORG_ID=<YOUR_ORG_ID>
```

Download Org object
```
curl $DASH_URL/admin/organisations/$ORG_ID -H "Admin-Auth: $DASH_ADMIN_SECRET" | python -mjson.tool > myorg.json
```

Edit myorg.json to add this bit (replace existing ones")
```
"hybrid_enabled": true,
"event_options": {
    "key_event": {
        "redis": true
    },
    "hashed_key_event": {
        "redis": true
    }
},
```

Update org with new settings
```
curl -X PUT $DASH_URL/admin/organisations/$ORG_ID -H "Admin-Auth: $DASH_ADMIN_SECRET" -d @myorg.json
```

Response:
```
{"Status":"OK","Message":"Org updated","Meta":null}
```

### 6. Run tyk slave gw on LOCAL
A) go to worker folder

B) Add these to tyk_worker.conf
- RPC key (org ID) to `slave_options.rpc_key`
- API key (user API key) `slave_options.api_key`
- connection_string (of VM) plus port 9090 to `slave_options.connection_string`, ie `10.45.166.51:9090`

C) run
```
docker-compose up -d
```

### 7. Run tyk slave gw on REMOTE
A) install the following
```
git clone https://github.com/TykTechnologies/tyk-pro-docker-demo
cd tyk-pro-docker-demo/
git checkout mdcb
cd worker
```

B) ADD to `tyk_worker.conf`, get these from the Dashboard's User Profile
- RPC key
- API key
- connection_string

C) Run The GW cluster
`docker-compose up -d`

### 8. Install & Run Tib

A) Run the stack
`docker-compose -f docker-compose-tib.yml up -d`

B) Modify nginx/index.html and use the right IP instead of "localhost"

C) Modify confs/profile.json with correct
```
----- `"OrgID"`
----- `"IdentityHandlerConfig.DashboardCredential"` --- This is your User's API Key
```