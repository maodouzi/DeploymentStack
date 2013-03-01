#! /usr/bin/env bash

if [ $# -ne 1 ];then
	echo "$0 <remote_ipaddr>" 
	exit
fi

TOP_DIR=$(cd $(dirname "$0") && pwd)
source ${TOP_DIR}/install-common.sh

REMOTE_IP=$1

myT1 "1. Copy Installation Scripts"
syncScripts2vm ${REMOTE_IP}

myT1 "2. Run Start Scripts in VM"
ssh ${REMOTE_USER}@${REMOTE_IP} "${REMOTE_INSTALL_DIR}/start/stop-all.sh"

