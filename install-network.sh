#! /usr/bin/env bash

TOP_DIR=$(cd $(dirname "$0") && pwd)
source ${TOP_DIR}/install-common.sh

myT1 "1. Copy Scripts"
syncScripts2vm ${MGT_NETWORK_IP}

myT1 "2. Run All Install Scripts in Remote VM"
ssh ${REMOTE_USER}@${MGT_NETWORK_IP} "${REMOTE_INSTALL_DIR}/install/install-network.sh"
