#! /usr/bin/env bash

TOP_DIR=$(cd $(dirname "$0") && pwd)
source ${TOP_DIR}/install-common.sh

myT1 "1. Copy Installation Scripts"
syncScripts2vm ${MGT_NETWORK_IP}

myT1 "2. Init Ctrl"
ssh ${REMOTE_USER}@${MGT_NETWORK_IP} "${REMOTE_INSTALL_DIR}/init/init-network.sh"
