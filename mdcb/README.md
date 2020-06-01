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

B) Add tyk pro license to tyk_analytics.conf


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
-Add MDCB license to tyk_sink.conf
-Update RedisPort to 6380

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

5. Enable Hybrid on Master DC

A) export DASH_ADMIN_SECRET=12345
B) export DASH_URL=localhost:3000
C) export ORG_ID=<YOUR_ORG_ID>
D) curl $DASH_URL/admin/organisations/$ORG_ID -H "Admin-Auth: $DASH_ADMIN_SECRET" | python -mjson.tool > myorg.json

E) Edit myorg.json to add this bit:
''
"hybrid_enabled": true,
  "event_options": {
    "key_event": {
      "redis": true
    },
    "hashed_key_event": {
      "redis": true
    }
  },

“

F) Update org with new settings
$ curl -X PUT $DASH_URL/admin/organisations/$ORG_ID -H "Admin-Auth: $DASH_ADMIN_SECRET" -d @myorg.json

Response:
{"Status":"OK","Message":"Org updated","Meta":null}

5. Run tyk slave gw on LOCAL
A) go to worker folder
ADD to tyk.conf
- RPC key
- API key
- connection_string
Docker-compose up -d

6. Run tyk slave gw on REMOTE
A) install the shit
git clone https://github.com/TykTechnologies/tyk-pro-docker-demo
cd tyk-pro-docker-demo/
git checkout mdcb
Cd worker

B) ADD to tyk.conf
- RPC key
- API key
- connection_string

C) Run The GW cluster
`docker-compose up -d`


7. Install & Run Tib

A) Run the stack
`docker-compose -f docker-compose-tib.yml up -d`

B) Modify nginx/index.html and use the right IP instead of "localhost"

C) Modify confs/profile.json with correct
----- `"OrgID"`
----- `"IdentityHandlerConfig.DashboardCredential"` --- This is your User's API Key
