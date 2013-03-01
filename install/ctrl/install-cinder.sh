#! /usr/bin/env bash 

TOP_DIR=$(cd $(dirname "$0") && pwd)
source ${TOP_DIR}/../../install-common.sh

myT2 "Begin Install Cinder!"

myT3 "Install Dep Pkgs"
sudo apt-get install iscsitarget open-iscsi iscsitarget-dkms -y

myT3 "Configure the iscsi services"
sudo sed -i 's/false/true/g' /etc/default/iscsitarget
sudo service iscsitarget start
sudo service open-iscsi start

myT3 "Install Cinder"
gitCloneModule cinder install

myT3 "Install Cinder Client"
gitCloneModule python-cinderclient install

myT3 "Config Cinder"
VOLUME_GROUP=cinder-volumes
STATE_PATH=/opt/cinder/data/cinder

sudo chmod 777 /etc/tgt
sudo chmod o+x /etc/tgt/targets.conf
sed -i "/${NEVER_MATCH}/d" /etc/tgt/targets.conf 
echo "include /opt/cinder/data/cinder/volumes/* #${NEVER_MATCH}" >>  /etc/tgt/targets.conf 
sudo chmod o-x /etc/tgt/targets.conf 
sudo chmod 755 /etc/tgt
sudo service tgt restart

sudo mkdir -p /etc/cinder
sudo cp -r ${REMOTE_SRC_DIR}/cinder/etc/cinder/* /etc/cinder
sudo chmod 777 /etc/cinder

sudo chmod o+x /etc/cinder/api-paste.ini
iniset /etc/cinder/api-paste.ini filter:authtoken auth_host ${KEYSTONE_IP}
iniset /etc/cinder/api-paste.ini filter:authtoken admin_tenant_name admin
iniset /etc/cinder/api-paste.ini filter:authtoken admin_user admin
iniset /etc/cinder/api-paste.ini filter:authtoken admin_password ${REMOTE_PASSWD}
sudo chmod o-x /etc/cinder/api-paste.ini

sudo touch /etc/cinder/cinder.conf
sudo chmod o+w /etc/cinder/cinder.conf
sudo echo "[DEFAULT]
logging_exception_prefix = %(color)s%(asctime)s TRACE %(name)s %(instance)s
logging_debug_format_suffix = from (pid=%(process)d) %(funcName)s %(pathname)s:%(lineno)d
logging_default_format_string = %(asctime)s %(color)s%(levelname)s %(name)s [-%(color)s] %(instance)s%(color)s%(message)s
logging_context_format_string = %(asctime)s %(color)s%(levelname)s %(name)s [%(request_id)s %(user_id)s %(project_id)s%(color)s] %(instance)s%(color)s%(message)s
rabbit_password = ${REMOTE_RABBITMQ_PASSWD}
rabbit_userid = ${REMOTE_RABBITMQ_USER}
rabbit_host = ${RABBITMQ_IP}
state_path = ${STATE_PATH}
osapi_volume_extension = cinder.api.openstack.volume.contrib.standard_extensions
root_helper = sudo /usr/local/bin/cinder-rootwrap /etc/cinder/rootwrap.conf
api_paste_config = /etc/cinder/api-paste.ini
sql_connection = $(getSqlConn ${REMOTE_DATABASE_USER} ${REMOTE_DATABASE_PASSWORD} ${DB_IP} cinder ${DB_PORT})
iscsi_helper = tgtadm
volume_name_template = volume-%s
volume_group = ${VOLUME_GROUP}
verbose = True
auth_strategy = keystone
" >  /etc/cinder/cinder.conf
sudo chmod o-w /etc/cinder/cinder.conf

sudo chmod 755 /etc/cinder

sudo mkdir -p ${STATE_PATH}/volumes
if ! sudo vgs $VOLUME_GROUP; then
	sudo vgcreate $VOLUME_GROUP /dev/${CINDER_VD}
fi

myT3 "DB Sync"
sudo cinder-manage db sync

myT2 "End Install Cinder!"
