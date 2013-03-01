#! /usr/bin/env bash

TOP_DIR=$(cd $(dirname "$0") && pwd)
source ${TOP_DIR}/install-common.sh

myT1 "1. Copy Installation Scripts"
syncScripts2vm ${MGT_KEYSTONE_IP}
if [ "${SWIFT_ENABLE}" = "yes" ];then
    syncScripts2vm ${MGT_SWIFT_PROXY_IP}
fi
syncScripts2vm ${MGT_CTRL_IP}

myT1 "2. Init Ctrl"
ssh ${REMOTE_USER}@${MGT_KEYSTONE_IP} "${REMOTE_INSTALL_DIR}/init/init-keystone.sh"
if [ "${SWIFT_ENABLE}" = "yes" ];then
    ssh ${REMOTE_USER}@${MGT_SWIFT_PROXY_IP} "${REMOTE_INSTALL_DIR}/init/init-swift_proxy.sh"
fi
ssh ${REMOTE_USER}@${MGT_CTRL_IP} "${REMOTE_INSTALL_DIR}/init/init-ctrl.sh"
