# docker

The following setup allows you to spin up a FoundationDB cluster on docker-compose.

The goal is to be able to connect from your host machine. 

Connections work on a single node. Not currently working on multiple nodes.

See: [https://github.com/apple/foundationdb/issues/222](https://github.com/apple/foundationdb/issues/222)


## Single Node

To start a single node:

- `./fdb-cluster.sh up 1 single memory`

Restart:

- `./fdb-cluster.sh restart 1 single memory`

Stop the node:

- `./fdb-cluster.sh down`

## Operating the cluster

To start the cluster:

- `./fdb-cluster.sh up`

Restart the cluster:

- `./fdb-cluster.sh restart`

Stop the cluster:

- `./fdb-cluster.sh down`

NOTE: Right now foundationdb is running in memory so nothing is saved on restart.

TODO: Add volume mounts for data to save the DB data

## Connecting to the single node

Use this on the host machine as *fdb.cluster*: `fdb:fdb@127.0.0.1:4500`

## Connecting to the cluster

NOT WORKING from outside docker.

## General docker commands

to see what is running (or failed):

- `docker ps -a`

to get logs for a container:

- `docker logs -f <container_name>`

to enter a container:

- `docker exec -it <container_name> bash`

