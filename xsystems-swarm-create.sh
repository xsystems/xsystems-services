#!/bin/sh

usage() {
  echo "xsystems-swarm-create.sh size (virtualbox|digitalocean) [manager]"
}

create_machine_virtualbox() {
  docker-machine create --driver=virtualbox \
                        --virtualbox-memory ${VIRTUALBOX_MEMORY_SIZE:-512} \
                        --virtualbox-disk-size ${VIRTUALBOX_DISK_SIZE:-10000} \
                        $1
}

create_machine_digitalocean() {
  docker-machine create --driver=digitalocean \
                        --digitalocean-access-token ${DIGITALOCEAN_ACCESS_TOKEN} \
                        --digitalocean-size ${DIGITALOCEAN_SIZE:-512mb} \
                        --digitalocean-region ${DIGITALOCEAN_REGION:-ams3} \
                        $1
}

if [ "$3" ] ; then
  JOIN_IP=$(docker-machine ip "$3")
  JOIN_TOKEN=$(docker-machine ssh "$3" docker swarm join-token --quiet manager)
  NODE_INDEX_FIRST=$(docker-machine ssh "$3" docker info --format "{{.Swarm.Nodes}}")
else
  NODE_INDEX_FIRST=0
fi

if [ "$1" ] ; then
  NODE_INDEX_LAST=$((${NODE_INDEX_FIRST}+"$1"-1))
else
  usage; exit
fi

MACHINE_PROVIDER="$2"

for i in `seq ${NODE_INDEX_FIRST} ${NODE_INDEX_LAST}` ; do
  NODE_NAME="xsystems-docker-node-${MACHINE_PROVIDER}-${i}"

  case ${MACHINE_PROVIDER} in
    "virtualbox")   create_machine_virtualbox ${NODE_NAME} ;;
    "digitalocean") create_machine_digitalocean ${NODE_NAME} ;;
    *)              usage; exit ;;
  esac

  if [ -v JOIN_TOKEN ] ; then
    docker-machine ssh ${NODE_NAME} docker swarm join --token $JOIN_TOKEN \
                                                      ${JOIN_IP}:2377
  else
    JOIN_IP=$(docker-machine ip ${NODE_NAME})
    docker-machine ssh ${NODE_NAME} docker swarm init --advertise-addr ${JOIN_IP}
    JOIN_TOKEN=$(docker-machine ssh ${NODE_NAME} docker swarm join-token --quiet manager)
  fi
done
