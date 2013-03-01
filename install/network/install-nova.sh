#! /usr/bin/env bash 

TOP_DIR=$(cd $(dirname "$0") && pwd)
source ${TOP_DIR}/../../install-common.sh

myT2 "Begin Install Nova!"

myT3 "Install Dep Pkgs"
#sudo apt-get install build-essential git python-dev python-setuptools python-pip python-mysqldb python-psycopg2 libxml2-dev libxslt-dev bridge-utils lvm2 iscsitarget open-iscsi iscsitarget-source iscsitarget-dkms tgt libhivex0 btrfs-tools cryptsetup diff libaugeas0 reiserfsprogs zfs-fuse jfsutils scrub xfsprogs zerofree libfuse2 qemu libvirt-bin libvirt-dev python-libvirt kvm ebtables nbd-server nbd-client -y

#sudo apt-get install testrepository libxml2 libxslt1-dev libmysqlclient-dev -y #for unit test: ./runtest.sh

myT3 "Install Nova Client"
gitCloneModule python-novaclient install

myT2 "End Install Nova!"
