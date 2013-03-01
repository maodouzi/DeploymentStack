#! /usr/bin/env bash 

TOP_DIR=$(cd $(dirname "$0") && pwd)
source ${TOP_DIR}/../../install-common.sh

myT2 "Begin Install Quantum!"

myT3 "Install Dep Pkgs"
sudo apt-get install openvswitch-datapath-source openvswitch-switch openvswitch-datapath-dkms vlan bridge-utils -y
sudo module-assistant auto-install openvswitch-datapath 

myT3 "Install Quantum"
gitCloneModule quantum install

myT3 "Install Quantum Client"
gitCloneModule python-quantumclient install

myT3 "Config Quantum"
sudo mkdir -p /etc/quantum
sudo cp -r ${REMOTE_SRC_DIR}/quantum/etc/* /etc/quantum
sudo chmod 777 /etc/quantum

sudo chmod o+w /etc/quantum/quantum.conf
echo "[DEFAULT]
bind_host = 0.0.0.0 
bind_port = 9696 
core_plugin = quantum.plugins.openvswitch.ovs_quantum_plugin.OVSQuantumPluginV2
api_paste_config = /etc/quantum/api-paste.ini

rabbit_host = ${RABBITMQ_IP}
rabbit_userid = ${REMOTE_RABBITMQ_USER} 
rabbit_password = ${REMOTE_RABBITMQ_PASSWD}
rabbit_vhost = /openstack/quantum
" > /etc/quantum/quantum.conf
sudo chmod o-w /etc/quantum/quantum.conf

sudo chmod o+w /etc/quantum/api-paste.ini
echo "[composite:quantum]
use = egg:Paste#urlmap
/: quantumversions
/v2.0: quantumapi_v2_0

[composite:quantumapi_v2_0]
use = call:quantum.auth:pipeline_factory
noauth = extensions quantumapiapp_v2_0
keystone = authtoken keystonecontext extensions quantumapiapp_v2_0

[filter:keystonecontext]
paste.filter_factory = quantum.auth:QuantumKeystoneContext.factory

[filter:authtoken]
paste.filter_factory = keystone.middleware.auth_token:filter_factory
auth_host = ${CTRL_IP}
auth_port = 35357
auth_protocol = http
admin_tenant_name = admin
admin_user = admin
admin_password = ${REMOTE_PASSWD}

[filter:extensions]
paste.filter_factory = quantum.api.extensions:plugin_aware_extension_middleware_factory

[app:quantumversions]
paste.app_factory = quantum.api.versions:Versions.factory

[app:quantumapiapp_v2_0]
paste.app_factory = quantum.api.v2.router:APIRouter.factory
" > /etc/quantum/api-paste.ini
sudo chmod o-w /etc/quantum/api-paste.ini

sudo mkdir -p /opt/quantum/dhcp 
sudo chmod o+w /etc/quantum/dhcp_agent.ini
echo "[DEFAULT]
state_path = /opt/quantum/dhcp
interface_driver = quantum.agent.linux.interface.OVSInterfaceDriver
dhcp_driver = quantum.agent.linux.dhcp.Dnsmasq
root_helper = sudo

auth_url = http://${KEYSTONE_IP}:35357/v2.0
auth_region = RegionOne
admin_tenant_name = admin
admin_user = admin
admin_password = ${REMOTE_PASSWD}
" > /etc/quantum/dhcp_agent.ini
sudo chmod o-w /etc/quantum/dhcp_agent.ini

sudo chmod o+w /etc/quantum/l3_agent.ini
echo "[DEFAULT]
interface_driver = quantum.agent.linux.interface.OVSInterfaceDriver

auth_url = http://${KEYSTONE_IP}:35357/v2.0
auth_region = RegionOne
admin_tenant_name = admin
admin_user = admin
admin_password = ${REMOTE_PASSWD} 

root_helper = sudo
#external_network_bridge = br-ex
use_namespaces = True "> /etc/quantum/l3_agent.ini
sudo chmod o-w /etc/quantum/l3_agent.ini

sudo chmod o+w /etc/quantum/metadata_agent.ini
echo "[DEFAULT]
auth_url = http://${KEYSTONE_IP}:35357/v2.0
auth_region = RegionOne
admin_tenant_name = admin
admin_user = admin
admin_password = ${REMOTE_PASSWD}
root_helper = sudo
"> /etc/quantum/metadata_agent.ini
sudo chmod o-w /etc/quantum/metadata_agent.ini

sudo mkdir -p /etc/quantum/quantum/plugins/openvswitch/
sudo chmod o+w /etc/quantum/quantum/plugins/openvswitch/ovs_quantum_plugin.ini
echo "[DATABASE]
sql_connection=$(getSqlConn ${REMOTE_DATABASE_USER} ${REMOTE_DATABASE_PASSWORD} ${DB_IP} quantum ${DB_PORT})
reconnect_interval = 2

[OVS]
local_ip = ${NETWORK_IP}
tenant_network_type = gre
tunnel_id_ranges = 1:1000
enable_tunneling = True

[AGENT]
root_helper = sudo" > /etc/quantum/quantum/plugins/openvswitch/ovs_quantum_plugin.ini
sudo chmod o-w /etc/quantum/quantum/plugins/openvswitch/ovs_quantum_plugin.ini

sudo chmod 755 /etc/quantum

myT3 "Set Quantum Bridge"

brInt=$(sudo ovs-vsctl show | grep "Bridge br-int")
if [ "x${brInt}" = "x" ];then
	sudo ovs-vsctl add-br br-int
fi

brEx=$(sudo ovs-vsctl show | grep "Bridge br-ex")
if [ "x${brEx}" = "x" ];then
	sudo ovs-vsctl add-br br-ex
fi

#portEth2=$(sudo ovs-vsctl show | grep ' Port "eth2"')
#if [ "x${portEth2}" = "x" ];then
#	sudo ovs-vsctl add-port br-int eth2
#fi

portEth1=$(sudo ovs-vsctl show | grep ' Port "eth1"')
if [ "x${portEth1}" = "x" ];then
	echo "sudo ovs-vsctl add-port br-ex eth1"
fi

myT2 "End Install Quantum!"
