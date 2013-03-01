#! /usr/bin/env bash

TOP_DIR=$(cd $(dirname "$0") && pwd)
source ${TOP_DIR}/../install-common.sh

myT1 "Screen Wipe"
	sudo screen -wipe

myT1 "Run Install Scripts in Remote VM"
moduleList="glance nova cinder horizon quantum"
for module in ${moduleList};do
	${REMOTE_INSTALL_DIR}/init/ctrl/init-${module}.sh
done
