#! /usr/bin/env bash

TOP_DIR=$(cd $(dirname "$0") && pwd)
source ${TOP_DIR}/../install-common.sh

myT1 "Screen Wipe"
	sudo screen -wipe

myT1 "Run Install Scripts in Remote VM"
#moduleList="keystone glance nova cinder horizon quantum"
moduleList="keystone glance nova cinder quantum"
for module in ${moduleList};do
	${REMOTE_INSTALL_DIR}/init/network/init-${module}.sh
done
