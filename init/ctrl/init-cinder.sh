#! /usr/bin/env bash 

TOP_DIR=$(cd $(dirname "$0") && pwd)
source ${TOP_DIR}/../../install-common.sh

myT2 "Init Cinder!"

myT3 "Run Cinder"
stopCinder
startCinder

myT3 "Check Cinder Type"

typeId=$(get_cinder_type volumeType-1)
if [ "x${typeId}" = "x" ];then
	cinder --os-username admin --os-password ${REMOTE_PASSWD} --os-tenant-name admin --os-auth-url http://${KEYSTONE_IP}:5000/v2.0  type-create volumeType-1
fi
typeId=$(get_cinder_type volumeType-1)

volumeId=$(get_cinder_volume volumeInstance-1)
if [ "x${volumeId}" = "x" ];then
	echo "cinder --os-username admin --os-password ${REMOTE_PASSWD} --os-tenant-name admin --os-auth-url http://${KEYSTONE_IP}:5000/v2.0  create --display-name volumeInstance-1 --volume-type ${typeId} 1"
fi
volumeId=$(get_cinder_volume volumeInstance-1)

myT2 "End Init Cinder!"

