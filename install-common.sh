# functions - Common functions used by DevStack components

TOP_DIR=$(cd $(dirname "$0") && pwd)
if [ -f ${TOP_DIR}/localrc.sh ];then
    TOP_DIR=${TOP_DIR}
elif [ -f ${TOP_DIR}/../localrc.sh ];then
    TOP_DIR=${TOP_DIR}/..
elif [ -f ${TOP_DIR}/../../localrc.sh ];then
    TOP_DIR=${TOP_DIR}/../..
fi

source ${TOP_DIR}/localrc.sh

NEVER_MATCH="nEvErMaTcH"
GITHUB_IP="207.97.227.239 github.com ${NEVER_MATCH}
65.74.177.129 www.github.com ${NEVER_MATCH}
207.97.227.252 nodeload.github.com ${NEVER_MATCH}
207.97.227.243 raw.github.com ${NEVER_MATCH}
204.232.175.78 documentcloud.github.com ${NEVER_MATCH}
204.232.175.78 pages.github.com ${NEVER_MATCH}"
GITHUB_OPENSTACK="https://github.com/openstack/"

#PIP_MIRROR=${PIP_MIRROR:-"http://e.pypi.python.org/simple"}
PIP_MIRROR=${PIP_MIRROR:-"http://b.pypi.python.org/simple"}

REMOTE_USER=${REMOTE_USER:-"pear"}
REMOTE_PASSWD=${REMOTE_PASSWD:-"231"}
REMOTE_ADMIN_TOKEN=${REMOTE_ADMIN_TOKEN:-"ADMIN_TOKEN"}
REMOTE_DATABASE_USER=${REMOTE_DATABASE_USER:-${REMOTE_USER}}
REMOTE_DATABASE_PASSWORD=${REMOTE_DATABASE_PASSWORD:-${REMOTE_PASSWD}}
REMOTE_RABBITMQ_USER=${REMOTE_RABBITMQ_USER:-${REMOTE_USER}}
REMOTE_RABBITMQ_PASSWD=${REMOTE_RABBITMQ_PASSWD:-${REMOTE_PASSWD}}
DNS_IP=${DNS_IP:-"8.8.8.8"}
SWIFT_ENABLE=${SWIFT_ENABLE:-"yes"}
SWIFT_VD=${SWIFT_VD:-"vdb1"}
SWIFT_HASH=${SWIFT_HASH:-"66a3d6b56c1f479c8b4e70ab5c2000f5"}
CINDER_VD=${CINDER_VD:-"vdb1"}
ARCH_TYPE=${ARCH_TYPE:-"amd64"} #i686
LIBVERT_TYPE=${LIBVERT_TYPE:-"kvm"} #qemu
USE_GITHUB_IP=${USE_GITHUB_IP:-"no"} #yes
DB_TYPE=${DB_TYPE:-"mysql"} #mysql, postgresql
GIT_BASE=${GIT_BASE:-"${GITHUB_OPENSTACK}"}
BS_SUBNET=${BS_SUBNET:-"192.168.1"}
MGT_SUBNET=${MGT_SUBNET:-"192.168.1"}
PUBLIC_SUBNET=${PUBLIC_SUBNET:-"172.16.5"}
PRIVATE_SUBNET=${PRIVATE_SUBNET:-"10.0.1.0/24"}

DEFAULT_DSA=${DEFAULT_DSA:-"yes"}
DB_PORT=${DB_PORT:-""}

RABBITMQ_IP=${RABBITMQ_IP:-"22"}
DB_IP=${DB_IP:-"21"}
CTRL_IP=${CTRL_IP:-"23"}
NETWORK_IP=${NETWORK_IP:-"24"}
KEYSTONE_IP=${KEYSTONE_IP:-"${CTRL_IP}"}
SWIFT_PROXY_IP=${SWIFT_PROXY_IP:-"${CTRL_IP}"}

IP_LIST="RABBITMQ_IP DB_IP CTRL_IP KEYSTONE_IP SWIFT_PROXY_IP NETWORK_IP"
for itemName in ${IP_LIST};do
    itemIp=$(eval "echo \${${itemName}}")
    eval "${itemName}=${BS_SUBNET}.${itemIp}"
    eval "MGT_${itemName}=${MGT_SUBNET}.${itemIp}"
#    eval "echo \${${itemName}}"
#    eval "echo \${MGT_${itemName}}"
done

SWIFT_NODE_LIST=${SWIFT_NODE_LIST:-"${BS_SUBNET}.45 ${BS_SUBNET}.46 ${BS_SUBNET}.47"}
i=-1;for x in ${SWIFT_NODE_LIST};do i=$(expr $i + 1);done
SWIFT_NODE_NUM=$i 

PUBLIC_IP=${PUBLIC_IP:-"${PUBLIC_SUBNET}.50"}

REMOTE_SRC_DIR=/home/${REMOTE_USER}/src/
REMOTE_INSTALL_DIR=/home/${REMOTE_USER}/openstack/

source ${TOP_DIR}/db/${DB_TYPE}/dbrc.sh
source ${TOP_DIR}/db/dbrc.sh

tmpDir=$(pwd)
cd ~
HOME_DIR=$(pwd)
cd ${tmpDir}

function myExit() {
    myEcho "Exit Now!"
    exit $*
}

function myEcho() {
    echo $*
}

function myLine1() {
    myEcho "------------------------------"
}

function myLine2() {
    myEcho "=============================="
}

function myT1() {
    myEcho ""
    myLine2
    myEcho $*
    myLine2
    myEcho ""
}

function myT2() {
    myEcho ""
    myLine1
    myEcho $*
    myLine1
    myEcho ""
}

function myT3() {
    myEcho ""
    myEcho "== $* =="
}

function configSshCert {
    local host=$1
    local user=$2
    local identity=$3
    local sshCfg=$4
    grep "#${host}#${user}#${identity}" "${sshCfg}"
    if [ $? -ne 0 ];then
        echo "Host ${host} #${host}#${user}#${identity}
    HostName ${host}
    User ${user}
    IdentityFile ${identity}" >> ${sshCfg}
    fi
}

function restartNet {
	sudo /etc/init.d/networking restart 
}

function confDNS {
	sudo chmod o+w /etc/resolv.conf
	sudo echo "nameserver ${DNS_IP}" > /etc/resolv.conf 
	sudo chmod o-w /etc/resolv.conf
}

function confHosts {
   	sudo chmod o+w /etc/hosts
    sudo sed -i "/${NEVER_MATCH}/d" /etc/hosts
    if [ "${USE_GITHUB_IP}" = "yes" ];then
   	    sudo echo "${GITHUB_IP}" >> /etc/hosts
    fi
    sudo chmod o-w /etc/hosts	
}

function getIpAddr {
	local nicName=$1
	echo $(ifconfig ${nicName} | grep "inet addr:" | awk '{print $2}' | head -n 1 | awk -F : '{print $2}')
}

# Get an option from an INI file
# iniget config-file section option
function iniget() {
    local file=$1
    local section=$2
    local option=$3
    local line
    line=$(sed -ne "/^\[ *$section *\]/,/^\[.*\]/ { /^$option[ \t]*=/ p; }" $file)
    echo ${line#*=}
}

function syncScripts2vm {
	local remoteIpAddr=$1
    local allFlag=$2
    echo "Sync source to ${remoteIpAddr}"
	ssh ${REMOTE_USER}@${remoteIpAddr} "mkdir -p ${REMOTE_INSTALL_DIR};rm -rf ${REMOTE_INSTALL_DIR}/*"
	targetDir=$(ls -al | grep "^d" | awk '{print $9}' | grep -v -P "^\.\.?$")
	for xDir in ${targetDir};do
		scp -r ${TOP_DIR}/${xDir} ${REMOTE_USER}@${remoteIpAddr}:/${REMOTE_INSTALL_DIR}
	done
	scp -r ${TOP_DIR}/install-common.sh ${REMOTE_USER}@${remoteIpAddr}:/${REMOTE_INSTALL_DIR}
	scp -r ${TOP_DIR}/localrc.sh ${REMOTE_USER}@${remoteIpAddr}:/${REMOTE_INSTALL_DIR}
    if [ ! "x${allFlag=}" = "x" ];then
	    scp -r ${TOP_DIR}/*.sh ${REMOTE_USER}@${remoteIpAddr}:/${REMOTE_INSTALL_DIR}
    fi
}

function getPid {
	local markStr=$1
	local ignorePattern="rabbitmq"
	local pidList=$(ps -ef | grep "${markStr}" | grep -v grep | grep -v -P "${ignorePattern}" | awk '{print $2}' | xargs echo)
	echo $pidList
}

function startModule {
	local markStr=$1
	local cmdStr=$2
	myEcho "startModule ${markStr}"
	pidList=$(getPid "${markStr}")
	if [ "x${pidList}" = "x" ];then
		myEcho sudo screen -dmS ${markStr} ${cmdStr}
		sudo screen -dmS ${markStr} ${cmdStr}
	fi
	sleep 3
	ps -ef | grep "${markStr}"
}

function stopModule {
	local markStr=$1
	myEcho "stopModule ${markStr}"
	pidList=$(getPid "${markStr}")
	if [ ! "x${pidList}" = "x" ];then
		myEcho sudo kill -9 ${pidList}
		sudo kill -9 ${pidList}
	fi
	sleep 0.5	
	sudo screen -wipe
}

function startKeystone {
	startModule keystone-all "/usr/bin/python /usr/local/bin/keystone-all -d -v --debug"
}

function stopKeystone {
	stopModule keystone-all 
}

function startSwiftProxy {
	sudo service memcached restart
	sudo /usr/bin/python /usr/local/bin/swift-init proxy-server start
}

function startSwiftNode {
    sudo service rsync start
    sudo swift-init object-server start
    sudo swift-init object-replicator start
    sudo swift-init object-updater start
    sudo swift-init object-auditor start
    sudo swift-init container-server start
    sudo swift-init container-replicator start
    sudo swift-init container-updater start
    sudo swift-init container-auditor start
    sudo swift-init account-server start
    sudo swift-init account-replicator start
    sudo swift-init account-auditor start
    sudo swift-init account-updater start
}

function stopSwift {
	sudo /usr/bin/python /usr/local/bin/swift-init all stop
}

function startGlance {
	startModule glance-api "/usr/bin/python /usr/local/bin/glance-api --debug"
	startModule glance-registry "/usr/bin/python /usr/local/bin/glance-registry --debug"
}

function stopGlance {
	stopModule glance-api	
	stopModule glance-registry
}

function startNova {
	sudo service rabbitmq-server start
	sleep 1
	startModule nova-api "nova-api"
	startModule nova-compute "nova-compute"
	startModule nova-scheduler "nova-scheduler"
	startModule nova-cert "nova-cert"
	startModule nova-consoleauth "nova-consoleauth"
	startModule nova-conductor "nova-conductor"
	startModule nova-xvpvncproxy "nova-xvpvncproxy --config-file /etc/nova/nova.conf"
	startModule nova-novncproxy "${REMOTE_SRC_DIR}/noVNC/utils/nova-novncproxy --config-file /etc/nova/nova.conf --web ${REMOTE_SRC_DIR}/noVNC"
}

function startNovaCompute {
	startModule nova-compute "nova-compute"
	startModule nova-xvpvncproxy "nova-xvpvncproxy --config-file /etc/nova/nova.conf"
	startModule nova-novncproxy "${REMOTE_SRC_DIR}/noVNC/utils/nova-novncproxy --config-file /etc/nova/nova.conf --web ${REMOTE_SRC_DIR}/noVNC"
}

function startNovaCtrl {
	startModule nova-api "nova-api"
	startModule nova-scheduler "nova-scheduler"
	startModule nova-cert "nova-cert"
	startModule nova-consoleauth "nova-consoleauth"
	startModule nova-conductor "nova-conductor"
	startModule nova-xvpvncproxy "nova-xvpvncproxy --config-file /etc/nova/nova.conf"
	startModule nova-novncproxy "${REMOTE_SRC_DIR}/noVNC/utils/nova-novncproxy --config-file /etc/nova/nova.conf --web ${REMOTE_SRC_DIR}/noVNC"
}

function stopNova {
	stopModule nova-api 
	stopModule nova-compute
	stopModule nova-scheduler
	stopModule nova-cert
	stopModule nova-consoleauth
	stopModule nova-conductor
	stopModule nova-xvpvncproxy
	stopModule nova-novncproxy
}

function startCinder {
	startModule cinder-api "cinder-api"
	startModule cinder-volume "cinder-volume"
	startModule cinder-scheduler "cinder-scheduler"
}

function stopCinder {
	stopModule cinder-api
	stopModule cinder-volume
	stopModule cinder-scheduler
}

function startHorizon {
	cd ${REMOTE_SRC_DIR}/horizon
	startModule runserver "${REMOTE_SRC_DIR}/horizon/manage.py runserver 0.0.0.0:8080"
}

function stopHorizon {
	stopModule runserver
}

function startQuantum {
	startModule quantum-server "quantum-server --config-file=/etc/quantum/quantum.conf --config-file=/etc/quantum/quantum/plugins/openvswitch/ovs_quantum_plugin.ini"
	startModule quantum-openvswitch-agent "quantum-openvswitch-agent --config-file /etc/quantum/quantum.conf --config-file=/etc/quantum/quantum/plugins/openvswitch/ovs_quantum_plugin.ini"
	startModule quantum-dhcp-agent "quantum-dhcp-agent --config-file /etc/quantum/quantum.conf --config-file=/etc/quantum/dhcp_agent.ini"
	startModule quantum-l3-agent "quantum-l3-agent --config-file /etc/quantum/quantum.conf --config-file=/etc/quantum/l3_agent.ini"
    startModule quantum-metadata-agent "quantum-metadata-agent --config-file /etc/quantum/quantum.conf --config-file=/etc/quantum/metadata_agent.ini"
}

function startQuantumCtrl {
	startModule quantum-server "quantum-server --config-file=/etc/quantum/quantum.conf --config-file=/etc/quantum/quantum/plugins/openvswitch/ovs_quantum_plugin.ini"
}

function startQuantumNetwork {
	startModule quantum-openvswitch-agent "quantum-openvswitch-agent --config-file /etc/quantum/quantum.conf --config-file=/etc/quantum/quantum/plugins/openvswitch/ovs_quantum_plugin.ini"
	startModule quantum-dhcp-agent "quantum-dhcp-agent --config-file /etc/quantum/quantum.conf --config-file=/etc/quantum/dhcp_agent.ini"
	startModule quantum-l3-agent "quantum-l3-agent --config-file /etc/quantum/quantum.conf --config-file=/etc/quantum/l3_agent.ini"
    startModule quantum-metadata-agent "quantum-metadata-agent --config-file /etc/quantum/quantum.conf --config-file=/etc/quantum/metadata_agent.ini"
}

function startQuantumCompute {
	startModule quantum-openvswitch-agent "quantum-openvswitch-agent --config-file /etc/quantum/quantum.conf --config-file=/etc/quantum/quantum/plugins/openvswitch/ovs_quantum_plugin.ini"
}

function stopQuantum {
	stopModule quantum-server
	stopModule quantum-openvswitch-agent
	stopModule quantum-dhcp-agent
	stopModule quantum-l3-agent
    stopModule quantum-metadata-agent
}

# Set an option in an INI file
# iniset config-file section option value
function iniset() {
    local file=$1
    local section=$2
    local option=$3
    local value=$4
    if ! grep -q "^\[ *$section *\]" $file; then
        # Add section at the end
        echo -e "\n[$section]" >>$file
    fi
    if [[ -z "$(iniget $file $section $option)" ]]; then
        # Add it
        sed -i -e "/^\[ *$section *\]/ a\\
$option = $value
" $file
    else
        # Replace it
        sed -i -e "/^\[ *$section *\]/,/^\[.*\]/ s|^\($option[ \t]*=[ \t]*\).*$|\1$value|" $file
    fi
}

function get_tenant_id {
	local tenantName=$1
	local tenantId=$(keystone --token ${REMOTE_ADMIN_TOKEN} --endpoint http://${KEYSTONE_IP}:35357/v2.0 tenant-list | grep " ${tenantName} " | awk '{print $2}')
	echo ${tenantId}
}

function get_user_id {
	local userName=$1
	local userId=$(keystone --token ${REMOTE_ADMIN_TOKEN} --endpoint http://${KEYSTONE_IP}:35357/v2.0 user-list | grep " ${userName} " | awk '{print $2}')
	echo ${userId}
}

function get_role_id {
	local roleName=$1
	local roleId=$(keystone --token ${REMOTE_ADMIN_TOKEN} --endpoint http://${KEYSTONE_IP}:35357/v2.0 role-list | grep " ${roleName} " | awk '{print $2}')
	echo ${roleId}
}

function get_service_id {
	local serviceName=$1
	local serviceId=$(keystone --token ${REMOTE_ADMIN_TOKEN} --endpoint http://${KEYSTONE_IP}:35357/v2.0 service-list | grep " ${serviceName} " | awk '{print $2}')
	echo ${serviceId}
}

function get_endpoint_id {
	local serviceId=$1
	local endpointId=$(keystone --token ${REMOTE_ADMIN_TOKEN} --endpoint http://${KEYSTONE_IP}:35357/v2.0 endpoint-list | grep " ${serviceId} " | awk '{print $2}')
	echo ${endpointId}
}

function get_glance_index_id {
	local indexType=$1
	local adminTenantId=$(get_tenant_id admin)
	local indexId=$(glance --os-username admin --os-password ${REMOTE_PASSWD}  --os-tenant-id ${adminTenantId} --os-auth-url http://${KEYSTONE_IP}:5000/v2.0 index | grep ${indexType} | awk '{print $1}')
	echo ${indexId}
}

function get_nova_keypair_id {
	local keypairName=$1
	local keypairId=$(nova --os-username admin --os-password ${REMOTE_PASSWD} --os-tenant-name admin --os-auth-url http://${KEYSTONE_IP}:5000/v2.0 keypair-list | grep ${keypairName} | awk '{print $4}')
	echo ${keypairId}
}

function get_nova_instance_id {
	local instanceName=$1
	local instanceId=$(nova --os-username admin --os-password ${REMOTE_PASSWD} --os-tenant-name admin --os-auth-url http://${KEYSTONE_IP}:5000/v2.0 list | grep ${instanceName} | awk '{print $2}')
	echo ${instanceId}
}

function get_nova_network_id {
	local networkName=$1
	local networkId=$(nova --os-username admin --os-password ${REMOTE_PASSWD} --os-tenant-name admin --os-auth-url http://${KEYSTONE_IP}:5000/v2.0 network-list | grep ${networkName} | awk '{print $2}')
	echo ${networkId}
}

function get_cinder_type {
	local cinderTypeName=$1
	local cinderTypeId=$(cinder --os-username admin --os-password ${REMOTE_PASSWD} --os-tenant-name admin --os-auth-url http://${KEYSTONE_IP}:5000/v2.0 type-list | grep ${cinderTypeName} | awk '{print $2}')
	echo ${cinderTypeId}
}

function get_cinder_volume {
	local cinderVolumeName=$1
	local cinderVolumeId=$(cinder --os-username admin --os-password ${REMOTE_PASSWD} --os-tenant-name admin --os-auth-url http://${KEYSTONE_IP}:5000/v2.0 list | grep ${cinderVolumeName} | awk '{print $2}')
	echo ${cinderVolumeId}
}

function gitCloneModule {
	local module=$1
    local option=$2
    local gitUrl=${GIT_BASE}${module}.git
    if [ "${option}" = "url" ];then
        local gitUrl=$3
    fi

	cd ${REMOTE_SRC_DIR}
	if [ ! -d ${module}/.git ];then
		git clone ${gitUrl}
		cd ${REMOTE_SRC_DIR}/${module}
        if [ ${module} = "cinder" -o ${module} = "quantum" ];then
            sed -i 's/amqplib==0.6.1/amqplib>=0.6.1/' tools/pip-requires
            sed -i 's/kombu==1.0.4/kombu>=1.0.4/' tools/pip-requires
        fi
	else
		cd ${REMOTE_SRC_DIR}/${module}
		git pull
	fi
    echo "Clone ${module} Finished"
    
    if [ "${option}" = "install" ];then
        cd ${REMOTE_SRC_DIR}/${module}
        sudo pip install --index-url=${PIP_MIRROR} -r tools/pip-requires
        #sudo pip install --index-url=${PIP_MIRROR} -r tools/test-requires
        sudo python setup.py develop
    fi
}

function getGwIp {
	nicIpAddr=$1
	nicGwIp=$(echo "${nicIpAddr}" | sed "s/\.[0-9]*$/\.1/")
	echo ${nicGwIp}
}

function initOsEnv {
    sed -i "/${NEVER_MATCH}/d" /home/${REMOTE_USER}/.profile
    echo "export OS_USERNAME=admin  #${NEVER_MATCH}
export OS_PASSWORD=${REMOTE_PASSWD} #${NEVER_MATCH}
export OS_TENANT_NAME=admin #${NEVER_MATCH}
export OS_AUTH_URL=http://${KEYSTONE_IP}:35357/v2.0 #${NEVER_MATCH}" >> /home/${REMOTE_USER}/.profile
    grep "export OS_" /home/${REMOTE_USER}/.profile | sed "s/#${NEVER_MATCH}//"
}
