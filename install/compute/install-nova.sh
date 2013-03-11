#! /usr/bin/env bash 

if [ $# -ne 1 ];then
    echo "$0 <remote_ipaddr>" 
    exit
fi

TOP_DIR=$(cd $(dirname "$0") && pwd)
source ${TOP_DIR}/../../install-common.sh

REMOTE_IP=$1

myT2 "Begin Install Nova!"

myT3 "Install Dep Pkgs"
sudo apt-get install sysfsutils build-essential git python-dev python-setuptools python-pip python-mysqldb python-psycopg2 libxml2-dev libxslt-dev bridge-utils lvm2 iscsitarget open-iscsi iscsitarget-source iscsitarget-dkms tgt libhivex0 btrfs-tools cryptsetup diff libaugeas0 reiserfsprogs zfs-fuse jfsutils scrub xfsprogs zerofree libfuse2 qemu libvirt-bin libvirt-dev python-libvirt kvm ebtables nbd-server nbd-client -y

sudo apt-get install testrepository libxml2 libxslt1-dev libmysqlclient-dev -y #for unit test: ./runtest.sh

myT3 "Install Nova"
gitCloneModule nova install

myT3 "Install Nova Client"
gitCloneModule python-novaclient install

myT3 "Install Nova VNC"
if [ "${GIT_BASE}" = "${GITHUB_OPENSTACK}" ];then
	gitCloneModule noVNC url https://github.com/kanaka/noVNC.git
else
	gitCloneModule noVNC
fi

myT3 "Config Nova"
sudo mkdir -p /var/log/nova
sudo touch /var/log/nova/nova.log

sudo cp -r ${REMOTE_SRC_DIR}/nova/etc/nova /etc
PASTE_PATH=/etc/nova/api-paste.ini
CONF_PATH=/etc/nova/nova.conf

sudo chmod 777 /etc/nova
sudo touch ${PASTE_PATH} ${CONF_PATH}
sudo chmod o+w ${PASTE_PATH}
sudo chmod o+w ${CONF_PATH}

iniset ${PASTE_PATH} filter:authtoken auth_host ${KEYSTONE_IP}
iniset ${PASTE_PATH} filter:authtoken admin_tenant_name admin
iniset ${PASTE_PATH} filter:authtoken admin_user admin
iniset ${PASTE_PATH} filter:authtoken admin_password ${REMOTE_PASSWD}

if [ ! -f /etc/network/interfaces.bak ];then
	sudo cp /etc/network/interfaces /etc/network/interfaces.bak
fi

echo "
[DEFAULT]
glance_host = ${GLANCE_IP}
glance_api_server = ${GLANCE_IP}:9292
rabbit_host = ${RABBITMQ_IP}
rabbit_userid = ${REMOTE_RABBITMQ_USER}
rabbit_password = ${REMOTE_RABBITMQ_PASSWD}
rabbit_virtual_host = /openstack/nova
rpc_backend = nova.openstack.common.rpc.impl_kombu
ec2_dmz_host = ${CTRL_IP}
service_quantum_metadata_proxy = True
quantum_url = http://${CTRL_IP}:9696
quantum_admin_tenant_name = admin
quantum_auth_strategy = keystone
quantum_admin_auth_url = http://${KEYSTONE_IP}:35357/v2.0
quantum_admin_password = ${REMOTE_PASSWD}
quantum_admin_username = admin
network_api_class = nova.network.quantumv2.api.API
volume_api_class = nova.volume.cinder.API
enabled_apis = ec2, osapi_compute, metadata
instance_name_template = instance-%08x
libvirt_type=${LIBVERT_TYPE}
sql_connection=$(getSqlConn ${REMOTE_DATABASE_USER} ${REMOTE_DATABASE_PASSWORD} ${DB_IP} nova ${DB_PORT})
my_ip = ${REMOTE_IP} 
osapi_compute_extension = nova.api.openstack.compute.contrib.standard_extensions
s3_port = 3333
s3_host = ${CTRL_IP}
default_floating_pool = nova
fixed_range = 10.112.0.0/24
force_dhcp_release = True
dhcpbridge_flagfile = /etc/nova/nova.conf
compute_scheduler_driver = nova.scheduler.simple.SimpleScheduler
api_paste_config = /etc/nova/api-paste.ini
allow_resize_to_same_host = True
auth_strategy = keystone

firewall_driver = nova.virt.libvirt.firewall.IptablesFirewallDriver
compute_driver = libvirt.LibvirtDriver
libvirt_vif_driver = nova.virt.libvirt.vif.LibvirtHybridOVSBridgeDriver
linuxnet_interface_driver =
libvirt_cpu_mode = none

vncserver_proxyclient_address = 127.0.0.1
vncserver_listen = 127.0.0.1
vnc_enabled = true
xvpvncproxy_base_url = http://${REMOTE_IP}:6081/console
novncproxy_base_url = http://${REMOTE_IP}:6080/vnc_auto.html

instances_path = /opt/openstack/data/nova/instances
lock_path = /opt/openstack/data/nova
state_path = /opt/openstack/data/nova

#logging
logging_exception_prefix = %(color)s%(asctime)s.%(msecs)03d TRACE %(name)s %(instance)s
logging_debug_format_suffix = from (pid=%(process)d) %(funcName)s %(pathname)s:%(lineno)d
logging_default_format_string = %(asctime)s.%(msecs)03d %(color)s%(levelname)s %(name)s [-%(color)s] %(instance)s%(color)s%(message)s
logging_context_format_string = %(asctime)s.%(msecs)03d %(color)s%(levelname)s %(name)s [%(request_id)s %(user_name)s %(project_name)s%(color)s] %(instance)s%(color)s%(message)s

debug = True
verbose = True
[conductor]
[cells]
[baremetal]
[rpc_notifier2]
[trusted_computing]
[vmware]
[spice]
" > ${CONF_PATH}

sudo chmod o-w ${PASTE_PATH}
sudo chmod o-w ${CONF_PATH}
sudo chmod 755 /etc/nova

sudo mkdir -p /opt/openstack/data/nova
sudo mkdir -p /opt/openstack/data/nova/instances

cat << DOWN_IMAGE
myT3 "Down Image"
if [ ! -f ~/images/cirros.img ];then
	mkdir -p ~/images
	cd ~/images && wget -c https://launchpad.net/cirros/trunk/0.3.0/+download/cirros-0.3.0-x86_64-disk.img -O cirros.img
fi
DOWN_IMAGE

myT2 "End Install Nova!"
