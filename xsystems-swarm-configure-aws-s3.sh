#!/bin/sh

usage() {
  echo "xsystems-swarm-configure-aws-s3.sh manager"
}

install_plugin_aws_s3() {
  ssh root@$1 <<EOF
    docker plugin install --grant-all-permissions \
                          rexray/s3fs:0.11.1 \
                          S3FS_ACCESSKEY=${AWS_ACCESSKEY} \
                          S3FS_SECRETKEY=${AWS_SECRETKEY}
EOF
}

MANAGER_NODE="$1"

if [ $MANAGER_NODE ] ; then
  NODES=$(ssh root@$MANAGER_NODE docker node ls --format "{{.Hostname}}")
else
  usage; exit
fi

for NODE in ${NODES} ; do
  NODE_ADDR=$(ssh root@$MANAGER_NODE docker node inspect "$NODE" --format "{{.Status.Addr}}")
  install_plugin_aws_s3 ${NODE_ADDR}
done
