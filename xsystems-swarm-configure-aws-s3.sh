#!/bin/sh

usage() {
  echo "xsystems-swarm-configure-aws-s3.sh manager"
}

install_plugin_aws_s3() {
  docker-machine ssh $1 <<EOF
    docker plugin install --grant-all-permissions \
                          rexray/s3fs \
                          S3FS_ACCESSKEY=${AWS_ACCESSKEY} \
                          S3FS_SECRETKEY=${AWS_SECRETKEY}
EOF
}

if [ "$1" ] ; then
  NODES=$(docker-machine ssh "$1" docker node ls --format "{{.Hostname}}")
else
  usage; exit
fi

for NODE in ${NODES} ; do
  install_plugin_aws_s3 ${NODE}
done
