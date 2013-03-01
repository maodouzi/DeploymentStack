#! /usr/bin/env bash 

TOP_DIR=$(cd $(dirname "$0") && pwd)
source ${TOP_DIR}/../../install-common.sh

myT2 "Init Nova!"

myT3 "Run Nova"
stopNova
startNovaCompute

for i in 1 2 3 4 5 6 7 8 9 10; do
	sleep 3
	novaState=$(nova-manage service list | awk '{print $5}' | grep -v State | grep -v ":-)")
	if [ "x${novaState}" = "x" ];then
		novaState2=$(nova-manage service list | awk '{print $6}' | grep -v Updated_At | grep -P -v "\d{4}-\d{1,2}-\d{1,2}")
		if [ "x${novaState2}" = "x" ];then
			break
		fi
	fi
done
sleep 5
nova-manage service list 

myT3 "Check Nova"
nova --os-username admin --os-password ${REMOTE_PASSWD} --os-tenant-name admin --os-auth-url http://${KEYSTONE_IP}:5000/v2.0 image-list
nova --os-username admin --os-password ${REMOTE_PASSWD} --os-tenant-name admin --os-auth-url http://${KEYSTONE_IP}:5000/v2.0 list

myEcho "try root log in"

myT2 "End Init Nova!"
