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
sudo mkdir -p /var/log/quantum
sudo touch /var/log/quantum/quantum.log

sudo mkdir -p /etc/quantum
sudo cp -r ${REMOTE_SRC_DIR}/quantum/etc/* /etc/quantum
sudo chmod 777 /etc/quantum

sudo mkdir -p /opt/openstack/data/quantum
sudo mkdir -p /var/lib/quantum/keystone-signing 
QUANTUM_CONF_FILE=/etc/quantum/quantum.conf
sudo chmod o+w ${QUANTUM_CONF_FILE}
iniset ${QUANTUM_CONF_FILE} DEFAULT debug True
iniset ${QUANTUM_CONF_FILE} DEFAULT verbose True
iniset ${QUANTUM_CONF_FILE} DEFAULT allow_overlapping_ips True
iniset ${QUANTUM_CONF_FILE} DEFAULT state_path /opt/openstack/data/quantum
iniset ${QUANTUM_CONF_FILE} DEFAULT core_plugin quantum.plugins.openvswitch.ovs_quantum_plugin.OVSQuantumPluginV2
iniset ${QUANTUM_CONF_FILE} DEFAULT auth_strategy keystone
iniset ${QUANTUM_CONF_FILE} DEFAULT rpc_backend quantum.openstack.common.rpc.impl_kombu
iniset ${QUANTUM_CONF_FILE} DEFAULT rabbit_host ${RABBITMQ_IP}
iniset ${QUANTUM_CONF_FILE} DEFAULT rabbit_password ${REMOTE_RABBITMQ_PASSWD}
iniset ${QUANTUM_CONF_FILE} DEFAULT rabbit_userid ${REMOTE_RABBITMQ_USER}
iniset ${QUANTUM_CONF_FILE} DEFAULT rabbit_virtual_host /openstack/quantum
iniset ${QUANTUM_CONF_FILE} keystone_authtoken auth_host ${KEYSTONE_IP}
iniset ${QUANTUM_CONF_FILE} keystone_authtoken admin_tenant_name admin
iniset ${QUANTUM_CONF_FILE} keystone_authtoken admin_user admin
iniset ${QUANTUM_CONF_FILE} keystone_authtoken admin_password ${REMOTE_PASSWD}
sudo chmod o-w ${QUANTUM_CONF_FILE}

API_INI_FILE=/etc/quantum/api-paste.ini
sudo chmod o+w ${API_INI_FILE}
iniset ${API_INI_FILE} filter:authtoken auth_host ${KEYSTONE_IP}
iniset ${API_INI_FILE} filter:authtoken auth_port 35357
iniset ${API_INI_FILE} filter:authtoken auth_protocol http
iniset ${API_INI_FILE} filter:authtoken auth_uri http://${KEYSTONE_IP}:5000/
iniset ${API_INI_FILE} filter:authtoken admin_tenant_name admin
iniset ${API_INI_FILE} filter:authtoken admin_user admin
iniset ${API_INI_FILE} filter:authtoken admin_password ${REMOTE_PASSWD}
sudo chmod o-w ${API_INI_FILE}

sudo chmod 755 /etc/quantum

OVS_INI_FILE=/etc/quantum/quantum/plugins/openvswitch/ovs_quantum_plugin.ini
sudo chmod 777 /etc/quantum/quantum/plugins/openvswitch
sudo chmod o+w ${OVS_INI_FILE}
iniset ${OVS_INI_FILE} DATABASE sql_connection $(getSqlConn ${REMOTE_DATABASE_USER} ${REMOTE_DATABASE_PASSWORD} ${DB_IP} quantum ${DB_PORT})
iniset ${OVS_INI_FILE} OVS local_ip ${CTRL_IP}
iniset ${OVS_INI_FILE} OVS enable_tunneling True
iniset ${OVS_INI_FILE} OVS tunnel_id_ranges 1:2000
iniset ${OVS_INI_FILE} OVS tenant_network_type gre
sudo chmod o-w ${OVS_INI_FILE}
sudo chmod 755 /etc/quantum/quantum/plugins/openvswitch

myT2 "End Install Quantum!"
