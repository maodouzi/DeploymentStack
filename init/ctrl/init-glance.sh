#! /usr/bin/env bash 

TOP_DIR=$(cd $(dirname "$0") && pwd)
source ${TOP_DIR}/../../install-common.sh

myT2 "Init Glance!"

myT3 "Run Glance"
stopGlance
startGlance

myT3 "Check Glance Index"
TENANT_ID=$(get_tenant_id admin)

kernelId=$(get_glance_index_id tty-kernel)
if [ "x${kernelId}" = "x" ];then
    glance --os-username admin --os-password ${REMOTE_PASSWD} --os-tenant-id ${TENANT_ID} --os-auth-url http://${KEYSTONE_IP}:5000/v2.0 image-create --name "tty-kernel" --disk-format=aki --container-format=aki --file ~/images/ttylinux-uec-amd64-12.1_2.6.35-22_1-vmlinuz --is-public true
	kernelId=$(get_glance_index_id tty-kernel)
fi

ramdiskId=$(get_glance_index_id tty-ramdisk)
if [ "x${ramdiskId}" = "x" ];then
	glance --os-username admin --os-password ${REMOTE_PASSWD} --os-tenant-id ${TENANT_ID} --os-auth-url http://${KEYSTONE_IP}:5000/v2.0 image-create --name "tty-ramdisk" --disk-format=ari --container-format=ari --file ~/images/ttylinux-uec-amd64-12.1_2.6.35-22_1-loader --is-public true
	ramdiskId=$(get_glance_index_id tty-ramdisk)
fi

imageId=$(get_glance_index_id tty-linux)
if [ "x${imageId}" = "x" ];then
	glance --os-username admin --os-password ${REMOTE_PASSWD} --os-tenant-id ${TENANT_ID} --os-auth-url http://${KEYSTONE_IP}:5000/v2.0 image-create --name="tty-linux" --property kernel_id=${kernelId} --property ramdisk_id=${ramdiskId} --disk-format ami --container-format ami --file ~/images/ttylinux-uec-amd64-12.1_2.6.35-22_1.img --is-public true
	imageId=$(get_glance_index_id tty-linux)
fi

testUbuntuId=$(get_glance_index_id testUbuntu)
if [ "x${testUbuntuId}" = "x" ];then
    glance --os-username admin --os-password  ${REMOTE_PASSWD}  --os-tenant-id ${TENANT_ID} --os-auth-url http://${KEYSTONE_IP}:5000/v2.0 image-create --location http://uec-images.ubuntu.com/releases/12.04/release/ubuntu-12.04-server-cloudimg-amd64-disk1.img --is-public true --disk-format qcow2 --container-format bare --name "testUbuntu"
fi
glance --os-username admin --os-password ${REMOTE_PASSWD} --os-tenant-id ${TENANT_ID} --os-auth-url http://${KEYSTONE_IP}:5000/v2.0 index

myT2 "End Init Glance!"

