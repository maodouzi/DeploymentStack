#! /usr/bin/env bash 

TOP_DIR=$(cd $(dirname "$0") && pwd)
source ${TOP_DIR}/../../install-common.sh

myT2 "Init Quantum!"

myT3 "Run Quantum"
stopQuantum
startQuantumCtrl

myT3 "Check Quantum Type"
quantum --os-username admin --os-password ${REMOTE_PASSWD} --os-tenant-name admin --os-auth-url http://${KEYSTONE_IP}:5000/v2.0 net-list

myT2 "End Init Quantum!"

