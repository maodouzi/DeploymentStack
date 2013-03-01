#! /usr/bin/env bash 

TOP_DIR=$(cd $(dirname "$0") && pwd)
source ${TOP_DIR}/../../install-common.sh

myT2 "Init Keystone!"

myT3 "Run Keystone"
stopKeystone
startKeystone

myT3 "Add admin tenant / user / role / service / endpoint"
TENANT_ID=$(get_tenant_id admin)
if [ "x${TENANT_ID}" = "x" ];then
	keystone --token ${REMOTE_ADMIN_TOKEN} --endpoint http://${KEYSTONE_IP}:35357/v2.0 tenant-create --name=admin
	TENANT_ID=$(get_tenant_id admin)
fi
echo "TENANT_ID=${TENANT_ID}"

USER_ID=$(get_user_id admin)
if  [ "x${USER_ID}" = "x" ];then
	keystone --token ${REMOTE_ADMIN_TOKEN} --endpoint http://${KEYSTONE_IP}:35357/v2.0 user-create --name=admin --pass=${REMOTE_PASSWD} --tenant-id=${TENANT_ID}
	USER_ID=$(get_user_id admin)
fi
echo "USER_ID=${USER_ID}"

ROLE_ID=$(get_role_id admin)
if [ "x${ROLE_ID}" = "x" ];then
	keystone --token ${REMOTE_ADMIN_TOKEN} --endpoint http://${KEYSTONE_IP}:35357/v2.0 role-create --name=admin
	ROLE_ID=$(get_role_id admin)
fi
echo "ROLE_ID=${ROLE_ID}"

keystone --token ${REMOTE_ADMIN_TOKEN} --endpoint http://${KEYSTONE_IP}:35357/v2.0 user-role-add --user_id=${USER_ID} --tenant_id=${TENANT_ID} --role_id=${ROLE_ID}

SERVICE_ID=$(get_service_id identity)
if [ "x${SERVICE_ID}" = "x" ];then
	keystone --token ${REMOTE_ADMIN_TOKEN} --endpoint http://${KEYSTONE_IP}:35357/v2.0 service-create --name=keystone --type=identity
	SERVICE_ID=$(get_service_id identity)
fi
echo "SERVICE_ID=${SERVICE_ID}"

ENDPOINT_ID=$(get_endpoint_id ${SERVICE_ID})
if [ "x${ENDPOINT_ID}" = "x" ];then
	keystone --token ${REMOTE_ADMIN_TOKEN} --endpoint http://${KEYSTONE_IP}:35357/v2.0 endpoint-create --region=RegionOne \
			--service-id=${SERVICE_ID} \
			--publicurl=http://${KEYSTONE_IP}:5000/v2.0/ \
			--adminurl=http://${KEYSTONE_IP}:35357/v2.0/ \
			--internalurl=http://${KEYSTONE_IP}:5000/v2.0/
	ENDPOINT_ID=$(get_endpoint_id ${SERVICE_ID})
fi
echo "ENDPOINT_ID=${ENDPOINT_ID}"

SWIFT_SERVICE_ID=$(get_service_id object-store)
if [ "x${SWIFT_SERVICE_ID}" = "x" ];then
	keystone --token ${REMOTE_ADMIN_TOKEN} --endpoint http://${KEYSTONE_IP}:35357/v2.0 service-create --name=swift --type=object-store
	SWIFT_SERVICE_ID=$(get_service_id object-store)
fi
echo "SWIFT_SERVICE_ID=${SWIFT_SERVICE_ID}"

SWIFT_ENDPOINT_ID=$(get_endpoint_id ${SWIFT_SERVICE_ID})
if [ "x${SWIFT_ENDPOINT_ID}" = "x" ];then
	keystone --token ${REMOTE_ADMIN_TOKEN} --endpoint http://${KEYSTONE_IP}:35357/v2.0 endpoint-create --region=RegionOne \
			--service-id=${SWIFT_SERVICE_ID} \
			--publicurl="http://${SWIFT_PROXY_IP}:8080/v1/AUTH_\$(tenant_id)s" \
			--adminurl="http://${SWIFT_PROXY_IP}:8080"\
			--internalurl="http://${SWIFT_PROXY_IP}:8080/v1/AUTH_\$(tenant_id)s"
	SWIFT_ENDPOINT_ID=$(get_endpoint_id ${SWIFT_SERVICE_ID})
fi
echo "SWIFT_ENDPOINT_ID=${SWIFT_ENDPOINT_ID}"

GLANCE_SERVICE_ID=$(get_service_id image)
if [ "x${GLANCE_SERVICE_ID}" = "x" ];then
	keystone --token ${REMOTE_ADMIN_TOKEN} --endpoint http://${KEYSTONE_IP}:35357/v2.0 service-create --name=glance --type=image
	GLANCE_SERVICE_ID=$(get_service_id image)
fi
echo "GLANCE_SERVICE_ID=${GLANCE_SERVICE_ID}"

GLANCE_ENDPOINT_ID=$(get_endpoint_id ${GLANCE_SERVICE_ID})
if [ "x${GLANCE_ENDPOINT_ID}" = "x" ];then
	keystone --token ${REMOTE_ADMIN_TOKEN} --endpoint http://${KEYSTONE_IP}:35357/v2.0 endpoint-create --region=RegionOne \
			--service-id=${GLANCE_SERVICE_ID} \
			--publicurl=http://${CTRL_IP}:9292 \
			--adminurl=http://${CTRL_IP}:9292 \
			--internalurl=http://${CTRL_IP}:9292
	GLANCE_ENDPOINT_ID=$(get_endpoint_id ${GLANCE_SERVICE_ID})
fi
echo "GLANCE_ENDPOINT_ID=${GLANCE_ENDPOINT_ID}"

NOVA_SERVICE_ID=$(get_service_id compute)
if [ "x${NOVA_SERVICE_ID}" = "x" ];then
	keystone --token ${REMOTE_ADMIN_TOKEN} --endpoint http://${KEYSTONE_IP}:35357/v2.0 service-create --name=nova --type=compute
	NOVA_SERVICE_ID=$(get_service_id compute)
fi
echo "NOVA_SERVICE_ID=${NOVA_SERVICE_ID}"

NOVA_ENDPOINT_ID=$(get_endpoint_id ${NOVA_SERVICE_ID})
if [ "x${NOVA_ENDPOINT_ID}" = "x" ];then
	keystone --token ${REMOTE_ADMIN_TOKEN} --endpoint http://${KEYSTONE_IP}:35357/v2.0 endpoint-create --region=RegionOne \
			--service-id=${NOVA_SERVICE_ID} \
			--publicurl="http://${CTRL_IP}:8774/v2/%(tenant_id)s" \
			--adminurl="http://${CTRL_IP}:8774/v2/%(tenant_id)s" \
			--internalurl="http://${CTRL_IP}:8774/v2/%(tenant_id)s"
	NOVA_ENDPOINT_ID=$(get_endpoint_id ${NOVA_SERVICE_ID})
fi
echo "NOVA_ENDPOINT_ID=${NOVA_ENDPOINT_ID}"

CINDER_SERVICE_ID=$(get_service_id volume)
if [ "x${CINDER_SERVICE_ID}" = "x" ];then
	keystone --token ${REMOTE_ADMIN_TOKEN} --endpoint http://${KEYSTONE_IP}:35357/v2.0 service-create --name=CINDER --type=volume
	CINDER_SERVICE_ID=$(get_service_id volume)
fi
echo "CINDER_SERVICE_ID=${CINDER_SERVICE_ID}"

CINDER_ENDPOINT_ID=$(get_endpoint_id ${CINDER_SERVICE_ID})
if [ "x${CINDER_ENDPOINT_ID}" = "x" ];then
	keystone --token ${REMOTE_ADMIN_TOKEN} --endpoint http://${KEYSTONE_IP}:35357/v2.0 endpoint-create --region=RegionOne \
			--service-id=${CINDER_SERVICE_ID} \
			--publicurl="http://${CTRL_IP}:8776/v1/%(tenant_id)s" \
			--adminurl="http://${CTRL_IP}:8776/v1/%(tenant_id)s" \
			--internalurl="http://${CTRL_IP}:8776/v1/%(tenant_id)s"
	CINDER_ENDPOINT_ID=$(get_endpoint_id ${CINDER_SERVICE_ID})
fi
echo "CINDER_ENDPOINT_ID=${CINDER_ENDPOINT_ID}"

QUANTUM_SERVICE_ID=$(get_service_id network)
if [ "x${QUANTUM_SERVICE_ID}" = "x" ];then
	keystone --token ${REMOTE_ADMIN_TOKEN} --endpoint http://${KEYSTONE_IP}:35357/v2.0 service-create --name=QUANTUM --type=network
	QUANTUM_SERVICE_ID=$(get_service_id network)
fi
echo "QUANTUM_SERVICE_ID=${QUANTUM_SERVICE_ID}"

QUANTUM_ENDPOINT_ID=$(get_endpoint_id ${QUANTUM_SERVICE_ID})
if [ "x${QUANTUM_ENDPOINT_ID}" = "x" ];then
	keystone --token ${REMOTE_ADMIN_TOKEN} --endpoint http://${KEYSTONE_IP}:35357/v2.0 endpoint-create --region=RegionOne \
			--service-id=${QUANTUM_SERVICE_ID} \
			--publicurl="http://${CTRL_IP}:9696/" \
			--adminurl="http://${CTRL_IP}:9696/" \
			--internalurl="http://${CTRL_IP}:9696/"
	QUANTUM_ENDPOINT_ID=$(get_endpoint_id ${QUANTUM_SERVICE_ID})
fi
echo "QUANTUM_ENDPOINT_ID=${QUANTUM_ENDPOINT_ID}"

myT2 "End Init Keystone!"

