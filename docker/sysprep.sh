#!/bin/bash

docker network create --driver bridge \
    --subnet 10.10.90.0/24 --gateway 10.10.90.1 public_network
docker network create --driver bridge \
    --subnet 10.10.91.0/24 --gateway 10.10.91.1 --internal private_network

DIR="/mnt/sdb/volumes"
mkdir -p $DIR && chown root:root $DIR && chmod 711 $DIR
systemctl stop docker
cat > /etc/docker/daemon.json <<EOF
{
  "data-root": "/mnt/volumes"
}
EOF

if [ -d /var/lib/docker ]; then
    rsync -aP /var/lib/docker/ /mnt/volumes/
fi

systemctl daemon-reexec && systemctl start docker
