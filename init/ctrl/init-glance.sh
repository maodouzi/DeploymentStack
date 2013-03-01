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
	glance --os-username admin --os-password  ${REMOTE_PASSWD}  --os-tenant-id ${TENANT_ID} --os-auth-url http://${KEYSTONE_IP}:5000/v2.0 add name="tty-kernel" disk_format=aki container_format=aki < ~/images/ttylinux-uec-${ARCH_TYPE}-12.1_2.6.35-22_1-vmlinuz
	kernelId=$(get_glance_index_id tty-kernel)
fi

ramdiskId=$(get_glance_index_id tty-ramdisk)
if [ "x${ramdiskId}" = "x" ];then
	glance --os-username admin --os-password  ${REMOTE_PASSWD}  --os-tenant-id ${TENANT_ID} --os-auth-url http://${KEYSTONE_IP}:5000/v2.0 add name="tty-ramdisk" disk_format=ari container_format=ari < ~/images/ttylinux-uec-${ARCH_TYPE}-12.1_2.6.35-22_1-loader
	ramdiskId=$(get_glance_index_id tty-ramdisk)
fi

imageId=$(get_glance_index_id tty-linux)
if [ "x${imageId}" = "x" ];then
	glance --os-username admin --os-password  ${REMOTE_PASSWD}  --os-tenant-id ${TENANT_ID} --os-auth-url http://${KEYSTONE_IP}:5000/v2.0 add name="tty-linux" kernel_id=${kernelId} ramdisk_id=${ramdiskId} disk_format=ami container_format=ami < ~/images/ttylinux-uec-${ARCH_TYPE}-12.1_2.6.35-22_1.img
	imageId=$(get_glance_index_id tty-linux)
fi

glance --os-username admin --os-password ${REMOTE_PASSWD} --os-tenant-id ${TENANT_ID} --os-auth-url http://${KEYSTONE_IP}:5000/v2.0 index

myT2 "End Init Glance!"

