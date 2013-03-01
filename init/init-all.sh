#! /usr/bin/env bash

TOP_DIR=$(cd $(dirname "$0") && pwd)
source ${TOP_DIR}/../install-common.sh

myT1 "Screen Wipe"
	sudo screen -wipe

myT1 "Run Install Scripts in Remote VM"
#moduleList="keystone swift_proxy glance nova cinder quantum"
if [ ${USE_QUANTUM} = "yes" ];then
    moduleList="keystone glance nova cinder horizon quantum"
else
    moduleList="keystone glance nova cinder horizon"
fi
for module in ${moduleList};do
	${REMOTE_INSTALL_DIR}/init/init-${module}.sh
done
