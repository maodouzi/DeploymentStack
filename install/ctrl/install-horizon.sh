#! /usr/bin/env bash 

TOP_DIR=$(cd $(dirname "$0") && pwd)
source ${TOP_DIR}/../../install-common.sh

myT2 "Begin Install Horizon!"

myT3 "Install Dep Pkgs"
sudo apt-get install build-essential git python-dev python-setuptools python-pip memcached python-netaddr nodejs -y 

myT3 "Install Horizon"
gitCloneModule horizon
cd ${REMOTE_SRC_DIR}/horizon
sudo pip install --index-url=${PIP_MIRROR} -r tools/pip-requires

myT3 "Config Horizon"
cd ${REMOTE_SRC_DIR}/horizon/openstack_dashboard/local
cp local_settings.py.example local_settings.py 

sed -i "s/OPENSTACK_HOST = \"127.0.0.1\"/OPENSTACK_HOST = \"${KEYSTONE_IP}\"/" ${REMOTE_SRC_DIR}/horizon/openstack_dashboard/local/local_settings.py 
sed -i 's/OPENSTACK_KEYSTONE_DEFAULT_ROLE = \"Member\"/OPENSTACK_KEYSTONE_DEFAULT_ROLE = \"admin\"/' ${REMOTE_SRC_DIR}/horizon/openstack_dashboard/local/local_settings.py  

myT2 "End Install Horizon!"
