# docker

The following setup allows you to spin up a FoundationDB cluster on docker-compose

# Running a single node

- `./fdb-cluster.sh up 1 single memory`

Restart the node:

- `./fdb-cluster.sh restart 1 single memory`

Stop the node:

- `./fdb-cluster.sh down`

## Operating the cluster

By default, there's a 3 node cluster using `double memory`

To start the cluster:

- `npm start` or `./fdb-cluster.sh up 3 double memory`

Restart:

- `npm run restart` or `./fdb-cluster.sh restart 3 double memory`

Stop the cluster:

- `npm stop` or `./fdb-cluster.sh down`

NOTE: Right now foundationdb is running in memory so nothing is saved on restart.

TODO: Add volume mounts for data to save the DB data

## Connecting to the cluster

Use this as *fdb.cluster*: `fdb:fdb@127.0.0.1:4500`


## General docker commands

to see what is running (or failed):

- `docker ps -a`

to get logs for a container:

- `docker logs -f <container_name>`

to enter a container:

- `docker exec -it <container_name> bash`

