These instructions assume being executed locally on a Linux or macOS machine using the `docker-machine`. Actual separate servers can be utilised as well, just use their IPs when selecting the manager node and joining workers. Also please make sure the latest docker is installed on all those nodes.

## Creating the VMs and initialising the swarm

Create a manager node:
```
$ docker-machine create manager1
```

Create two more worker nodes:
```
$ docker-machine create worker1
$ docker-machine create worker2
```

Make sure all 3 nodes are up and running:
```
$ docker-machine ls
NAME       ACTIVE   DRIVER       STATE     URL                         SWARM   DOCKER        ERRORS
manager1   -        virtualbox   Running   tcp://192.168.99.100:2376           v18.02.0-ce   
worker1    -        virtualbox   Running   tcp://192.168.99.101:2376           v18.02.0-ce   
worker2    -        virtualbox   Running   tcp://192.168.99.102:2376           v18.02.0-ce

```

Get `manager1` IP address, we'll use it to promote the manager node and join the rest to it:
```
$ docker-machine ip manager1
192.168.99.100
```

SSH to the manager machine and init the swarm:
```
$ docker-machine ssh manager1
$ docker swarm init --advertise-addr 192.168.99.100
Swarm initialized: current node (00seko4p1wfide9hgx0hhllfg) is now a manager.

To add a worker to this swarm, run the following command:

    docker swarm join --token SWMTKN-1-25iz6yloiemiadfnig8staiw3llcx45odbnwb3k4spoo94s9ft-4j7no435z27mc32733q8tdqbm 192.168.99.100:2377

To add a manager to this swarm, run 'docker swarm join-token manager' and follow the instructions.

$ docker node ls
ID                            HOSTNAME            STATUS              AVAILABILITY        MANAGER STATUS
00seko4p1wfide9hgx0hhllfg *   manager1            Ready               Active              Leader
```

Make sure to note the token value.

Now let's join worker nodes to the manager (make sure to replace the token and IP with your actual values):
```
$ docker-machine ssh worker1
$ docker swarm join --token SWMTKN-1-25iz6yloiemiadfnig8staiw3llcx45odbnwb3k4spoo94s9ft-4j7no435z27mc327
33q8tdqbm 192.168.99.100:2377
This node joined a swarm as a worker.

$ docker-machine ssh worker2
$ docker swarm join --token SWMTKN-1-25iz6yloiemiadfnig8staiw3llcx45odbnwb3k4spoo94s9ft-4j7no435z27mc327
33q8tdqbm 192.168.99.100:2377
This node joined a swarm as a worker.
```

Let's check that the swarm is configured correctly, from the manager node:
```
$ docker node ls
ID                            HOSTNAME            STATUS              AVAILABILITY        MANAGER STATUS
00seko4p1wfide9hgx0hhllfg *   manager1            Ready               Active              Leader
ofs056wa4y31wtl9fp5rhcswn     worker1             Ready               Active              
6az80xjz05nyhboz59mcl43pc     worker2             Ready               Active
```

From now on, everything will be done on the manager node.

## Deploying the stack and configuration

On the manager node, clone the `TykTechnologies/tyk-pro-docker-demo`:
```
$ git clone https://github.com/TykTechnologies/tyk-pro-docker-demo.git
```

Open the tyk_analytics.conf file in the confs/ folder and add your license string to the "license_key": "" section. Edit any other configurations if needed. By default it's ready for a simple deployment.

Note that Docker Swarm does not work with multiple compose files that build on each other, instead all the desired compose files must be merged in one. We already provide a default in `docker-swarm-merged.yml`, however when doing changes to the base or swarm-specific or your own custom compose files, they need to be merged manually using the `docker-compose` program:
```
$ docker-compose -f docker-compose.yml -f docker-swarm.yml config > docker-swarm-merged.yml
```

The resulting file is the one to be used with the `docker stack` commands. Note that it may contain absolute paths.

Once ready, deploy the stack to the swarm:
```
$ docker stack deploy --compose-file docker-swarm-merged.yml tyk-pro-demo
```

Note that you can update your stack using the same command, unless changes to configs are made because docker treats them as immutable objects. In this case, either the stack needs to be removed and deployed again, or a configuration object needs to be renamed in the docker-compose file.

Eventually, all the containers should be launched and ready:
```
$ docker service ls
ID                  NAME                         MODE                REPLICAS            IMAGE                              PORTS
omzcwm2r01s0        tyk-pro-demo_tyk-dashboard   replicated          2/2                 tykio/tyk-dashboard:latest         *:3000->3000/tcp, *:5000->5000/tcp
poctpcc8xr6t        tyk-pro-demo_tyk-gateway     replicated          2/2                 tykio/tyk-gateway:latest           *:8080->8080/tcp
4p8k5wxn8fgy        tyk-pro-demo_tyk-mongo       replicated          1/1                 mongo:3.2                          *:27017->27017/tcp
vfoh5zjez2fd        tyk-pro-demo_tyk-pump        replicated          2/2                 tykio/tyk-pump-docker-pub:latest   
8bvfjijoqzy6        tyk-pro-demo_tyk-redis       replicated          1/1                 redis:latest                       *:6379->6379/tcp

$ docker stack ps tyk-pro-demo
ID                  NAME                           IMAGE                              NODE                DESIRED STATE       CURRENT STATE            ERROR               PORTS
jnzmgf9n88ug        tyk-pro-demo_tyk-pump.1        tykio/tyk-pump-docker-pub:latest   worker1             Running             Running 15 minutes ago                       
k1dzlwdjogi3        tyk-pro-demo_tyk-gateway.1     tykio/tyk-gateway:latest           worker2             Running             Running 15 minutes ago                       
j6j1162d2mlv        tyk-pro-demo_tyk-dashboard.1   tykio/tyk-dashboard:latest         worker2             Running             Running 15 minutes ago                       
4sm3k3xgcjmf        tyk-pro-demo_tyk-mongo.1       mongo:3.2                          manager1            Running             Running 15 minutes ago                       
6sjb2gde9cl6        tyk-pro-demo_tyk-redis.1       redis:latest                       manager1            Running             Running 15 minutes ago                       
etgp6m07ff13        tyk-pro-demo_tyk-pump.2        tykio/tyk-pump-docker-pub:latest   manager1            Running             Running 15 minutes ago                       
tddoyri3kcw4        tyk-pro-demo_tyk-gateway.2     tykio/tyk-gateway:latest           worker1             Running             Running 15 minutes ago                       
tzpej4dojerm        tyk-pro-demo_tyk-dashboard.2   tykio/tyk-dashboard:latest         worker1             Running             Running 15 minutes ago 
```

Note that for demo purposes in this stack all the services have their ports forwarded. Production must not leave MongoDB and Redis ports open to the world.


It's time to make a demo setup. If running on a manager node created by the `docker-machine`, first install bash and Python2 on it:
```
$ tce-load -wi bash
$ tce-load -wi python
```

Bootstrap the instance:

```
$ chmod +x setup.sh
$ ./setup.sh
Using 127.0.0.1 as Tyk host address.
If this is wrong, please specify the instance IP address (e.g. ./setup.sh 192.168.1.1)
Creating Organisation
ORG ID: 5a96ca383400ac00016851b6
Adding new user
USER AUTH: 0d2abc2d27be405261867f95136891e6
USER ID: 5a96ca282212f1ff6d7c5df1
Setting password
Setting up the Portal catalogue
Creating the Portal Home page
Fixing Portal URL

DONE
====
Login at http://www.tyk-test.com:3000/
Username: test22014@test.com
Password: test123
Portal: http://www.tyk-portal-test.com:3000/portal/
```

Alternatively, run the script on another host that can reach the manager node externally.

If the same demo data is used, make sure to add your manager node to `/etc/hosts` like this:
```
192.168.99.100  www.tyk-test.com www.tyk-portal-test.com
```

The manager node acts as a swarm load balancer and discovery service so it can always be used to access all the services.

This concludes the guide and (if nothing's been changed) you should have a docker swarm of 3 nodes, containing 1 MongoDB, 1 Redis container on the manager node, 2 of each dashboard and gateway spread over the worker nodes and 2 pumps across the swarm.

Note that `docker-machine` VMs only retain the volumes, images, containers and certain docker config files. Everything else will be lost on VM restart unless explicitly saved by the VM provider.

