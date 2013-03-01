#! /usr/bin/env bash 

TOP_DIR=$(cd $(dirname "$0") && pwd)
source ${TOP_DIR}/../install-common.sh

myT2 "Begin Install Test!"

myT3 "Test Cinder"
ls -l /dev/${CINDER_VD}
if [ $? -ne 0 ];then
    myEcho "Couldn't find cinder volume disk: /dev/${CINDER_VD}!"
    myEcho "sudo fdisk /dev/${CINDER_VD}, n, t/8e, w"
    read stopFlag
fi

myT3 "Test Network"
if [ "${USE_QUANTUM}" = "yes" ];then
    myEcho "Quantum"
	sudo ovs-vsctl show | grep "Bridge br-"
	if [ $? -ne 0 ];then
		cat << QUANTUM_CONF
---------------------------------
sudo apt-get install openvswitch-switch -y
---------------------------------
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
address ${MGT_IP}
netmask 255.255.255.0
gateway ${MGT_GW}

auto eth1
iface eth1 inet dhcp

auto eth2
iface eth2 inet dhcp
---------------------------------
QUANTUM_CONF
	fi
else
    ifconfig br100 | grep ${MGT_IP}
    if [ $? -ne 0 ];then
        myEcho "br100 ipAddr not ${MGT_IP}!"
        cat << NETWORK_CONF
---------------------------------
sudo apt-get install bridge-utils -y
---------------------------------
auto lo
iface lo inet loopback

auto br100
iface br100 inet static
address ${MGT_IP}
netmask 255.255.255.0
gateway ${MGT_GW}
bridge_ports eth0
bridge_stp off
bridge_fd 0
---------------------------------
NETWORK_CONF
        read stopFlag
    fi
fi

myT2 "End Install Test!"
