# Tyk Pro Streams Demo using Docker and Kafka

This repo will show you how to use kafka with Tyk streams

## Docker images included in this repo
1. Kafka and zookeeper - to run kafka exposed at either (localhost:9093 - if you want to connect from outside or kafka:9092 if you want to connect from a container in the same network as kafka)
2. publisher - A golang program that publishes  orders to kafka's instrument.json.AMZN topic every 2 seconds the json published looks as follows:
  ```json
{
  "customer_id": "fe5df941-c9bc-405e-82c6-1ffd8d434626",
  "order_value": 1492,
  "timestamp": 1717737432
}
```
3. tyk-dashboard - Tyk dashboard to manage you apis
4. tyk-ent-portal - Tyk enterprice developer portal
5. tyk-gateway - tyk gateway
6. 
       

## Quick start

### Prerequisites

1. Install [Docker](https://docs.docker.com/get-docker/)
2. Get a license for [Tyk Self-Managed](https://tyk.io/sign-up/) (choose "on your infrastructure"). This is a self-service option!


### Deploying Tyk

1. Clone the repo and checkout to the kafka branch: `git clone https://github.com/TykTechnologies/tyk-pro-docker-demo && cd tyk-pro-docker-demo && git checkout kafka`

2. For a bootstrapped install, run `up.sh`
OR
2. Add your Tyk Dashboard license to .env (see .env.example) and run `docker-compose up`

**gotcha:** you may need to give the executable permissions if you have an error:
`chmod +x up.sh`


3. The script sends to the STDOUT the details you need to open and log in to Tyk Dashobard:
```
---------------------------
Please sign in at http://localhost:3000

user: dev@tyk.io
pw: topsecret

Your Tyk Gateway is found at http://localhost:8080

Press Enter to exit
```

###  Configuring a Kafka stream
- In the Tyk Dashboard, create a new API (For the api style select OpenApi). Click the +CONFIGURE API button to continue.
- Navigate to the Streaming section and click on Add Stream.
- Provide a name for your stream in the Stream name textbox
- In the Stream configuration, define your stream input and output as follows:

```yaml
input:
  kafka:
    addresses:
      - kafka:9092
    consumer_group: tyk
    topics:
      - instrument.json.AMZN
output:
  http_server:
    allowed_verbs:
      - GET
    path: /instruments
    stream_path: /instruments/stream
    ws_path: /instruments/subscribe
pipeline:
  processors:
    - bloblang: |
        root = if this.order_value > 1000 {
          this
        } else {
          deleted()
        }
    - branch:
        processors:
          - http:
              headers:
                Content-Type: application/json
              url: https://httpbin.org/ip
              verb: GET
        request_map: root = ""
        result_map: root.origin = this.origin
    - bloblang: |
        root.high_order = true
        root = this.merge({ "high_value_order": true })
```
- save you api definition

### Testing Your API
Let's test the API we just created.
1. Send the request below using curl to stream orders
  curl http://localhost:8080/kafka/instruments/stream

After you send this request you will start receiving streams messages like below:


