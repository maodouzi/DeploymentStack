#! /usr/bin/env bash 

TOP_DIR=$(cd $(dirname "$0") && pwd)
source ${TOP_DIR}/../../install-common.sh

myT2 "Init Nova!"

myT3 "Run Nova"
stopNova
startNovaCtrl

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

myT3 "Add Cross Image"
TENANT_ID=$(get_tenant_id admin)
cat << TEST
ttyImageId=$(get_glance_index_id tty-linux)
if [ "x${ttyImageId}" = "x" ];then
	glance --os-username admin --os-password  ${REMOTE_PASSWD}  --os-tenant-id ${TENANT_ID} --os-auth-url http://${KEYSTONE_IP}:5000/v2.0 add name="tty-linux" kernel_id=${kernelId} ramdisk_id=${ramdiskId} disk_format=ami container_format=ami < ~/images/ttylinux-uec-${ARCH_TYPE}-12.1_2.6.35-22_1.img
	ttyImageId=$(get_glance_index_id tty-linux)
fi

keyPairId=$(get_nova_keypair_id mykey)
if [ "x${keyPairId}" = "x" ];then
	nova --os-username admin --os-password  ${REMOTE_PASSWD}  --os-tenant-name admin --os-auth-url http://${KEYSTONE_IP}:5000/v2.0 keypair-add --pub_key ~/.ssh/id_dsa.pub mykey
	keyPairId=$(get_nova_keypair_id mykey)
fi

ttyInstanceId=$(get_nova_instance_id tty-linux)
if [ "x${ttyInstanceId}" = "x" ];then
	echo "nova --os-username admin --os-password  ${REMOTE_PASSWD}  --os-tenant-name admin --os-auth-url http://${KEYSTONE_IP}:5000/v2.0 boot --flavor 1 --image ${ttyImageId} --key_name mykey --security_group default tty-linux"
	ttyInstanceId=$(get_nova_instance_id tty-linux)
fi
TEST
testUbuntuId=$(get_glance_index_id testUbuntu)
if [ "x${testUbuntuId}" = "x" ];then
    glance --os-username admin --os-password  ${REMOTE_PASSWD}  --os-tenant-id ${TENANT_ID} --os-auth-url http://${KEYSTONE_IP}:5000/v2.0 image-create --location http://uec-images.ubuntu.com/releases/12.04/release/ubuntu-12.04-server-cloudimg-amd64-disk1.img --is-public true --disk-format qcow2 --container-format bare --name "testUbuntu"
fi

myT3 "Check Nova"
nova --os-username admin --os-password ${REMOTE_PASSWD} --os-tenant-name admin --os-auth-url http://${KEYSTONE_IP}:5000/v2.0 image-list
nova --os-username admin --os-password ${REMOTE_PASSWD} --os-tenant-name admin --os-auth-url http://${KEYSTONE_IP}:5000/v2.0 list

myEcho "try root log in"

myT2 "End Init Nova!"
