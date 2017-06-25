#!/bin/sh

for i in {0..2} ; do
  NODE_NAME="xsystems-docker-node-${i}"

  docker-machine create --driver=virtualbox \
                        --virtualbox-memory ${VIRTUALBOX_MEMORY_SIZE:-512} \
                        --virtualbox-disk-size ${VIRTUALBOX_DISK_SIZE:-10000} \
                        ${NODE_NAME}

  if [ -v SWARM_JOIN_TOKEN ] ; then
    docker-machine ssh ${NODE_NAME} docker swarm join --token $SWARM_JOIN_TOKEN \
                                                      ${SWARM_JOIN_IP}:2377
  else
    SWARM_JOIN_IP=$(docker-machine ip ${NODE_NAME})
    docker-machine ssh ${NODE_NAME} docker swarm init --advertise-addr ${SWARM_JOIN_IP}
    SWARM_JOIN_TOKEN=$(docker-machine ssh ${NODE_NAME} docker swarm join-token --quiet manager)
  fi
done
