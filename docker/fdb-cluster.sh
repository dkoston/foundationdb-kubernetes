#!/usr/bin/env bash
set -e

####### CONFIGURATION ########
MAX_HEALTH_CHECKS=20    # Maximum times to check the health of each fdb node before failing
HEALTH_CHECK_DELAY=5    # seconds to wait between health checks
#############################

DEFAULT_NODE_COUNT=3
DEFAULT_REDUNDANCY_MODE=double
DEFAULT_STORAGE_ENGINE=memory
HEALTH_CHECK_COUNT=0
NAME="[fdb-cluster]: "


COMMAND=$1
DESIRED_NODE_COUNT=$2
REDUNDANCY_MODE=$3
STORAGE_ENGINE=$4

log() {
    echo "${NAME} $1"
}

verifyHealth() {
    local REGEX='^[0-9]+$'

    local NODE_NUMBER=$1

    if ! [[ ${NODE_NUMBER} =~ ${REGEX} ]]; then
        log "verifyHealth() must be called with an integer"
        exit 4
    fi

    local CURRENT_DIRECTORY=${PWD##*/}
    local CONTAINER_NAME="${CURRENT_DIRECTORY}_fdb_${NODE_NUMBER}"

    let HEALTH_CHECK_COUNT+=1

    local STATUS=$(docker exec -it ${CONTAINER_NAME} sh -c 'fdbcli --exec status | grep "Replication health"')
    local FDB_STATUS=$(echo ${STATUS} | awk '{print $4}')

    local HEALTHY_REGEX='^Healthy'
    if [[ ${FDB_STATUS} =~ ${HEALTHY_REGEX} ]]; then
        log "fdb replication healthy on ${CONTAINER_NAME}"
        return
    fi

    if (( "${HEALTH_CHECK_COUNT}" >= "${MAX_HEALTH_CHECKS}" )); then
        log "fdb replication failed to initialize"
        exit 3
    fi


    log "Waiting for fdb replication on ${CONTAINER_NAME}....."
    sleep ${HEALTH_CHECK_DELAY}
    verifyHealth ${NODE_NUMBER}
}


verifyContainerHealth() {
    sleep 2
    local REGEX='^[0-9]+$'

    if ! [[ $1 =~ ${REGEX} ]]; then
        log "verifyContainer() must be called with integers"
        exit 4
    fi

    local NODE_NUMBER=$1
    local CURRENT_DIRECTORY=${PWD##*/}
    local CONTAINER_NAME=${CURRENT_DIRECTORY}_fdb_${NODE_NUMBER}
    local CONTAINER_STATUS=$(docker ps -a --format '{{.Names}} {{.Status}}' | grep "${CONTAINER_NAME}" | awk '{print $2}')
    local STATUS_REGEX='^Up'
    if ! [[ "${CONTAINER_STATUS}" =~ ${STATUS_REGEX} ]]; then
        log "Docker container failed: ${CONTAINER_STATUS}"
        exit 5
    fi
    log "${CONTAINER_NAME} is running"
}

scaleCluster() {
    local REGEX='^[0-9]+$'

    if ! [[ $1 =~ ${REGEX} ]]; then
        log "scaleCluster() must be called with an integer"
        exit 2
    fi

    local NODES=$1

    log "Scaling cluster to ${NODES} nodes"
    docker-compose up -d --scale fdb=${NODES}
    verifyHealth ${NODES}
    verifyContainerHealth ${NODES}
}

setCoordinators() {
    local REGEX='^[0-9]+$'

    local NODES=$1

    if ! [[ ${NODES} =~ ${REGEX} ]]; then
        log "setCoordinators() must be called with an integer"
        exit 2
    fi

    local COORDINATORS=""

    for (( n=1; n<=$1; n++ )); do
        local CONTAINER_NAME="docker_fdb_$n"
        local IP_ADDRESS=$(docker inspect -f "{{ .NetworkSettings.Networks.docker_default.IPAddress }}" ${CONTAINER_NAME})
        COORDINATORS="$COORDINATORS ${IP_ADDRESS}:4500"
    done

    log "Setting coordinators to: ${COORDINATORS}"
    docker exec -it docker_fdb_1 sh -c "fdbcli --exec 'coordinators ${COORDINATORS}'"
    HEALTH_CHECK_COUNT=0
    verifyHealth ${NODES}
}

configureReplication() {
    local REGEX='^[0-9]+$'

    if ! [[ $1 =~ ${REGEX} ]]; then
        log "configureReplication() must be called with an integer"
        exit 2
    fi

    log "Setting replication to ${REDUNDANCY_MODE} ${STORAGE_ENGINE}"
    docker-compose exec fdb fdbcli --exec "configure ${REDUNDANCY_MODE} ${STORAGE_ENGINE}"
    HEALTH_CHECK_COUNT=0
    verifyHealth 1
    setCoordinators 3
}

startFirstNode() {
    local CURRENT_DIRECTORY=${PWD##*/}
    local CONTAINER_NAME="${CURRENT_DIRECTORY}_fdb_1"
    local CONTAINER_EXISTS=$(docker ps -a --format '{{.Names}}' | grep "${CONTAINER_NAME}")

    if [[ "$CONTAINER_EXISTS" == "$CONTAINER_NAME" ]]; then
        log "First node already live"
        verifyHealth 1
        return
    fi

    log "Starting first node"
    docker-compose up -d --build
    verifyContainerHealth 1

    log "Configuring database on ${CONTAINER_NAME}"
    docker exec -it ${CONTAINER_NAME} sh -c 'fdbcli --exec "configure new single memory"'
    verifyHealth 1
}


startCluster() {
    log "Starting FoundationDB cluster via docker-compose"
    log "Cluster details:"
    log "-----------------------"
    log "NODES: $DESIRED_NODE_COUNT"
    log "REDUNDANCY: $REDUNDANCY_MODE"
    log "STORAGE ENGINE: $STORAGE_ENGINE"
    log "-----------------------"

    startFirstNode
    local SIZE=1

    for (( n=1; n<${DESIRED_NODE_COUNT}; n++ )); do
        HEALTH_CHECK_COUNT=0
        let SIZE=${n}+1
        scaleCluster ${SIZE}
    done


    if ! [[ "$REDUNDANCY_MODE" == "single" ]]; then
        configureReplication ${DESIRED_NODE_COUNT}
        return
    fi

    if ! [[ "$STORAGE_ENGINE" == "memory" ]]; then
        if ! [[ "$REDUNDANCY_MODE" == "single" ]]; then
            configureReplication ${DESIRED_NODE_COUNT}
        fi
    fi
}

stopCluster() {
    docker-compose down
}

if [[ "$DESIRED_NODE_COUNT" == "" ]]; then
    DESIRED_NODE_COUNT=${DEFAULT_NODE_COUNT}
fi

if [[ "$REDUNDANCY_MODE" == "" ]]; then
    REDUNDANCY_MODE=${DEFAULT_REDUNDANCY_MODE}
fi

if [[ "$STORAGE_ENGINE" == "" ]]; then
    STORAGE_ENGINE=${DEFAULT_STORAGE_ENGINE}
fi

if [[ "$COMMAND" == "up" ]]; then
    startCluster
elif [[ "$COMMAND" == "down" ]]; then
    stopCluster
elif [[ "$COMMAND" == "restart" ]]; then
    stopCluster
    startCluster
else
    echo "Usage: ./fdb-cluster.sh <up|down|restart> <node_count> <redundancy_mode> <storage_engine>"
fi

