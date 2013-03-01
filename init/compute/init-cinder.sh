#! /usr/bin/env bash 

TOP_DIR=$(cd $(dirname "$0") && pwd)
source ${TOP_DIR}/../../install-common.sh

myT2 "Init Cinder!"

cinder --os-username admin --os-password ${REMOTE_PASSWD} --os-tenant-name admin --os-auth-url http://${KEYSTONE_IP}:35357/v2.0 type-list

myT2 "End Init Cinder!"

