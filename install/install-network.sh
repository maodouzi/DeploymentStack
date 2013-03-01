#! /usr/bin/env bash

TOP_DIR=$(cd $(dirname "$0") && pwd)
source ${TOP_DIR}/../install-common.sh

myT1 "Install All"
moduleList="keystone glance nova cinder quantum"
for module in ${moduleList};do
	${REMOTE_INSTALL_DIR}/install/network/install-${module}.sh
done
