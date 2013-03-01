#! /usr/bin/env bash

TOP_DIR=$(cd $(dirname "$0") && pwd)
source ${TOP_DIR}/install-common.sh

myT1 "1. Copy Scripts"
syncScripts2vm ${MGT_CTRL_IP}
syncScripts2vm ${MGT_KEYSTONE_IP}
if [ "${SWIFT_ENABLE}" = "yes" ];then
	syncScripts2vm ${MGT_SWIFT_PROXY_IP}
fi
syncScripts2vm ${MGT_DB_IP}

myT1 "2. Init DB"
ssh ${REMOTE_USER}@${MGT_DB_IP} "${REMOTE_INSTALL_DIR}/init/init-db.sh"

myT1 "3. Run All Install Scripts in Remote VM"
ssh ${REMOTE_USER}@${MGT_KEYSTONE_IP} "${REMOTE_INSTALL_DIR}/install/install-keystone.sh"
if [ "${SWIFT_ENABLE}" = "yes" ];then
	ssh ${REMOTE_USER}@${MGT_SWIFT_PROXY_IP} "${REMOTE_INSTALL_DIR}/install/install-swift_proxy.sh"
fi
ssh ${REMOTE_USER}@${MGT_CTRL_IP} "${REMOTE_INSTALL_DIR}/install/install-ctrl.sh"
