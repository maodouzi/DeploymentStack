#! /usr/bin/env bash

if [ $# -ne 2 -a $# -ne 1 ];then
	echo "$0 <remote_ipaddr> <remote_hostname>" 
	exit
fi

TOP_DIR=$(cd $(dirname "$0") && pwd)
source ${TOP_DIR}/install-common.sh

REMOTE_IP=$1
REMOTE_HOSTNAME=$2

myT1 "0. Prepare"
cat<< EOF
# Install SSH server in remote VM
#   >> sudo apt-get install ssh -y
# Get IP@ about remote VM
#   >> ifconfig
# Config su password on remote VM 
#   >> sudo passwd 
EOF

myT1 "1. Config SSH" 
if [ "${DEFAULT_DSA}" = "yes" ];then
    if [ ! -f ~/.ssh/id_dsa.pub ];then
        ssh-keygen -t dsa
    fi
    scp ~/.ssh/id_dsa.pub ${REMOTE_USER}@${REMOTE_IP}:/home/${REMOTE_USER}/
    ssh ${REMOTE_USER}@${REMOTE_IP} "mkdir -p ~/.ssh && cat ~/id_dsa.pub >> ~/.ssh/authorized_keys"
    ssh root@${REMOTE_IP} "mkdir -p ~/.ssh && cat /home/${REMOTE_USER}/id_dsa.pub >> ~/.ssh/authorized_keys"
fi

myT1 "2. Copy Installation Scripts"
syncScripts2vm ${REMOTE_IP}

myT1 "3. Config sudo"
#ssh root@${REMOTE_IP} "chmod u+w /etc/sudoers && sed -i \"/${NEVER_MATCH}/d\" /etc/sudoers && echo \"${REMOTE_USER} ALL=(ALL) NOPASSWD: ALL #${NEVER_MATCH}\" >> /etc/sudoers && chmod u-w /etc/sudoers && grep \"${REMOTE_USER}\" /etc/sudoers"

myT1 "4. Config hostname"
if [ ! "x${REMOTE_HOSTNAME}" = "x" ];then
#    ssh root@${REMOTE_IP} "echo \"${REMOTE_HOSTNAME}\" > /etc/hostname && sed -i \"s/127.0.1.1.*$/127.0.1.1\t${REMOTE_HOSTNAME}/\" /etc/hosts && hostname ${REMOTE_HOSTNAME} && hostname"
    ssh ${REMOTE_USER}@${REMOTE_IP} "sudo chmod o+w /etc/hostname;sudo chmod 777 /etc; echo \"${REMOTE_HOSTNAME}\" > /etc/hostname && sed -i \"s/127.0.1.1.*$/127.0.1.1\t${REMOTE_HOSTNAME}/\" /etc/hosts && sudo hostname ${REMOTE_HOSTNAME} && sudo hostname; sudo chmod o-w /etc/hostname; sudo chmod 755 /etc"
fi

myT1 "5. Run Install Scripts in Remote VM"
ssh ${REMOTE_USER}@${REMOTE_IP} "${REMOTE_INSTALL_DIR}/install/install-tools.sh"
exit

myT1 "7. Add Another NIC: virtio/NAT & 4 virtio qcow2 10G harddisk"
ssh ${REMOTE_USER}@${REMOTE_IP} "echo sudo /etc/init.d/networking restart"
ssh ${REMOTE_USER}@${REMOTE_IP} "ifconfig"
ssh ${REMOTE_USER}@${REMOTE_IP} "ls -al /dev/vd* | grep -v vda"
ssh ${REMOTE_USER}@${REMOTE_IP} "sudo apt-get install xfsprogs -y"
for vdItem in ${VD_LIST};do
	echo -e "\nsudo fdisk /dev/${vdItem}"
	echo -e "\tn/p/DEFAULT/DEFAULT/DEFAULT/w"
	ssh ${REMOTE_USER}@${REMOTE_IP} "if [ ! -b /dev/${vdItem}1 ];then sudo fdisk /dev/${vdItem}; sudo mkfs.xfs -i size=1024 /dev/${vdItem}1; fi"
done


