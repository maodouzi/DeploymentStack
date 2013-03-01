#! /usr/bin/env bash 

if [ $# -ne 1 ];then
    echo "$0 <remote_ipaddr>" 
    exit
fi

TOP_DIR=$(cd $(dirname "$0") && pwd)
source ${TOP_DIR}/../../install-common.sh

REMOTE_IP=$1

myT2 "Begin Install SwiftNode!"

myT3 "Config VD"
if [ -d /srv/node/${SWIFT_VD} ];then
    sudo umount /srv/node/${SWIFT_VD}
fi
sudo mkfs.xfs -f -i size=1024 /dev/${SWIFT_VD}
sudo chmod 777 /etc/fstab
sed -i "/${NEVER_MATCH}/d" /etc/fstab
echo "/dev/${SWIFT_VD} /srv/node/${SWIFT_VD} xfs noatime,nodiratime,nobarrier,logbufs=8 0 0 #${NEVER_MATCH}" >> /etc/fstab
sudo chmod 644 /etc/fstab
sudo mkdir -p /srv/node/${SWIFT_VD}
sudo mount /srv/node/${SWIFT_VD}
sudo chown -R ${REMOTE_USER}:${REMOTE_USER} /srv/node

myT3 "Install Dep Pkgs"
sudo apt-get install libldap2-dev build-essential git python-dev python-setuptools python-pip libxml2-dev libxslt-dev openssl xfsprogs -y   

myT3 "Install Swift & Client"
gitCloneModule swift install
gitCloneModule python-swiftclient install

myT3 "Copy Config File from proxy"
sudo mkdir -p /etc/swift
rm -rf /tmp/swift
scp -r ${REMOTE_USER}@${SWIFT_PROXY_IP}:/etc/swift /tmp
sudo cp -r /tmp/swift/* /etc/swift/

myT3 "Config rsync"
sudo touch /etc/rsyncd.conf
sudo chmod 777 /etc/rsyncd.conf
echo "uid = ${REMOTE_USER}
gid = ${REMOTE_USER}
log file = /var/log/rsyncd.log
pid file = /var/run/rsyncd.pid
address = ${REMOTE_IP}

[account]
max_connections = 2
path = /srv/node/
read only = false
lock file = /var/lock/account.lock

[container]
max_connections = 2
path = /srv/node/
read only = false
lock file = /var/lock/container.lock

[object]
max_connections = 2
path = /srv/node/
read only = false
lock file = /var/lock/object.lock
" > /etc/rsyncd.conf
sudo chmod 644 /etc/rsyncd.conf
sudo sed -i 's/RSYNC_ENABLE=false/RSYNC_ENABLE=true/g' /etc/default/rsync
sudo service rsync start

myT3 "Server Config Files"
sudo mkdir -p /opt/stack/data/cache

sudo touch /etc/swift/account-server.conf /etc/swift/container-server.conf /etc/swift/object-server.conf
sudo chmod 777 /etc/swift/account-server.conf
echo "[DEFAULT]
bind_ip = 0.0.0.0
bind_port = 6012
workers = 1
user = ${REMOTE_USER}
swift_dir = /etc/swift
devices = /srv/node
mount_check = false
log_facility = LOG_LOCAL0

[pipeline:main]
pipeline = healthcheck recon account-server

[app:account-server]
use = egg:swift#account

[filter:healthcheck]
use = egg:swift#healthcheck

[filter:recon]
use = egg:swift#recon
recon_cache_path = /opt/stack/data/cache

[account-replicator]
recon_cache_path = /opt/stack/data/cache

[account-auditor]
recon_cache_path = /opt/stack/data/cache

[account-reaper]

[-replicator]
vm_test_mode = yes
" > /etc/swift/account-server.conf
sudo chmod 644 /etc/swift/account-server.conf

sudo chmod 777 /etc/swift/container-server.conf
echo "[DEFAULT]
bind_ip = 0.0.0.0
bind_port = 6011
workers = 1
user = ${REMOTE_USER}
swift_dir = /etc/swift
devices = /srv/node
mount_check = false
log_facility = LOG_LOCAL0

[pipeline:main]
pipeline = healthcheck recon container-server

[app:container-server]
use = egg:swift#container
allow_versions = true

[filter:healthcheck]
use = egg:swift#healthcheck

[filter:recon]
use = egg:swift#recon
recon_cache_path = /opt/stack/data/cache

[container-replicator]
recon_cache_path = /opt/stack/data/cache

[container-updater]
recon_cache_path = /opt/stack/data/cache

[container-auditor]
recon_cache_path = /opt/stack/data/cache

[container-sync]

[-replicator]
vm_test_mode = yes" > /etc/swift/container-server.conf
sudo chmod 644 /etc/swift/container-server.conf

sudo chmod 777 /etc/swift/object-server.conf
echo "[DEFAULT]
bind_ip = 0.0.0.0
bind_port = 6010
workers = 1
user = ${REMOTE_USER}
swift_dir = /etc/swift
devices = /srv/node
mount_check = false
log_facility = LOG_LOCAL0

[pipeline:main]
pipeline = healthcheck recon object-server

[app:object-server]
use = egg:swift#object

[filter:healthcheck]
use = egg:swift#healthcheck

[filter:recon]
recon_cache_path = /opt/stack/data/cache
use = egg:swift#recon
recon_cache_path = /opt/stack/data/cache

[object-replicator]
recon_cache_path = /opt/stack/data/cache

[object-updater]
recon_cache_path = /opt/stack/data/cache

[object-auditor]
recon_cache_path = /opt/stack/data/cache

[-replicator]
vm_test_mode = yes
" > /etc/swift/object-server.conf
sudo chmod 644 /etc/swift/object-server.conf

myT2 "End Install SwiftNode!"
