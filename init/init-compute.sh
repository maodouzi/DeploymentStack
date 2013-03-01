#! /usr/bin/env bash

if [ $# -ne 1 ];then
    echo "$0 <remote_ipaddr>" 
    exit
fi

TOP_DIR=$(cd $(dirname "$0") && pwd)
source ${TOP_DIR}/../install-common.sh

REMOTE_IP=$1

myT1 "Screen Wipe"
	sudo screen -wipe

myT1 "Run Install Scripts in Remote VM"
moduleList="keystone glance nova cinder quantum"
for module in ${moduleList};do
	${REMOTE_INSTALL_DIR}/init/compute/init-${module}.sh ${REMOTE_IP}
done
