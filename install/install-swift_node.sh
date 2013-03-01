#! /usr/bin/env bash

if [ $# -ne 1 ];then
    echo "$0 <remote_ipaddr>" 
    exit
fi

TOP_DIR=$(cd $(dirname "$0") && pwd)
source ${TOP_DIR}/../install-common.sh

REMOTE_IP=$1

myT1 "Install All"
moduleList="swift_node"
for module in ${moduleList};do
	${REMOTE_INSTALL_DIR}/install/compute/install-${module}.sh ${REMOTE_IP}
done
