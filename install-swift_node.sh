#! /usr/bin/env bash

if [ $# -ne 1 ];then
	echo "$0 <remote_ipaddr>" 
	exit
fi

TOP_DIR=$(cd $(dirname "$0") && pwd)
source ${TOP_DIR}/install-common.sh

REMOTE_IP=$1

myT1 "1. Copy Scripts"
syncScripts2vm ${REMOTE_IP}

ssh ${REMOTE_USER}@${REMOTE_IP} "ssh-keygen -t dsa"
scp ${REMOTE_USER}@${REMOTE_IP}:/home/${REMOTE_USER}/.ssh/id_dsa.pub /tmp/${REMOTE_IP}.id_dsa.pub
scp /tmp/${REMOTE_IP}.id_dsa.pub ${REMOTE_USER}@${SWIFT_PROXY_IP}:/tmp/
ssh ${REMOTE_USER}@${SWIFT_PROXY_IP} "mkdir -p ~/.ssh && cat /tmp/${REMOTE_IP}.id_dsa.pub >> ~/.ssh/authorized_keys"
ssh root@${SWIFT_PROXY_IP} "mkdir -p ~/.ssh && cat /tmp/${REMOTE_IP}.id_dsa.pub >> ~/.ssh/authorized_keys"

myT1 "2. Run All Install Scripts in Remote VM"
ssh ${REMOTE_USER}@${REMOTE_IP} "${REMOTE_INSTALL_DIR}/install/swiftnode/install-swift_node.sh ${REMOTE_IP}"
