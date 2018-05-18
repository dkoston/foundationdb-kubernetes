# docker

The following setup allows you to spin up a FoundationDB cluster on docker-compose

To start the cluster:

- `npm start`

Restart:

- `npm run restart`

Stop the cluster:

- `npm stop`

NOTE: Right now foundationdb is running in memory so nothing is saved on restart.

TODO: Add volume mounts for data to save the DB data

to see what is running (or failed):

- `docker ps -a`

to get logs for a container:

- `docker logs -f <container_name>`

to enter a container:

- `docker exec -it <container_name> bash`

