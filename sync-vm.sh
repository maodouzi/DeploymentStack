#! /usr/bin/env bash

if [ $# -ge 3 ];then
	echo "$0 <remote_ipaddr> [<-a>]" 
	exit
fi

TOP_DIR=$(cd $(dirname "$0") && pwd)
source ${TOP_DIR}/install-common.sh

REMOTE_IP=$1
ALL_FLAG=$2

myT1 "1. Copy Scripts"
syncScripts2vm ${REMOTE_IP} ${ALL_FLAG}
