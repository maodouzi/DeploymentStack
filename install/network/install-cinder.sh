#! /usr/bin/env bash 

TOP_DIR=$(cd $(dirname "$0") && pwd)
source ${TOP_DIR}/../../install-common.sh

myT2 "Begin Install Cinder!"

myT3 "Install Dep Pkgs"
#sudo apt-get install iscsitarget open-iscsi iscsitarget-dkms -y

myT3 "Install Cinder Client"
gitCloneModule python-cinderclient install

myT2 "End Install Cinder!"
