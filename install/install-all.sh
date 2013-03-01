#! /usr/bin/env bash

TOP_DIR=$(cd $(dirname "$0") && pwd)
source ${TOP_DIR}/../install-common.sh

myT1 "Install All"
if [ "${USE_QUANTUM}" = "yes" ];then
    moduleList="keystone glance nova cinder horizon quantum"
else
    moduleList="keystone glance nova cinder horizon"
fi
for module in ${moduleList};do
	${REMOTE_INSTALL_DIR}/install/install-${module}.sh
done
