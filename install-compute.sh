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

myT1 "2. Run All Install Scripts in Remote VM"
ssh ${REMOTE_USER}@${REMOTE_IP} "${REMOTE_INSTALL_DIR}/install/install-compute.sh ${REMOTE_IP}"
