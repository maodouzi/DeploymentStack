function getSqlConn_postgresql {
    local user=$1
    local passwd=$2
    local ipAddr=$3
    local dbName=$4
    local port=$5
    if [ ! "x${port}" = "x" ];then
        local port=":${port}"
    fi
    echo "postgresql://${user}:${passwd}@${ipAddr}${port}/${dbName}?charset=utf8"
}

function initDb_postgresql {
    echo "
DROP DATABASE IF EXISTS keystone;
CREATE DATABASE IF NOT EXISTS keystone;
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY '${REMOTE_DATABASE_PASSWORD}';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY '${REMOTE_DATABASE_PASSWORD}';

DROP DATABASE IF EXISTS glance;
CREATE DATABASE IF NOT EXISTS glance;
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY '${REMOTE_DATABASE_PASSWORD}';
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY '${REMOTE_DATABASE_PASSWORD}';

DROP DATABASE IF EXISTS nova;
CREATE DATABASE IF NOT EXISTS nova;
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY '${REMOTE_DATABASE_PASSWORD}';
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY '${REMOTE_DATABASE_PASSWORD}';

DROP DATABASE IF EXISTS cinder;
CREATE DATABASE IF NOT EXISTS cinder;
GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'%' IDENTIFIED BY '${REMOTE_DATABASE_PASSWORD}';
GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'localhost' IDENTIFIED BY '${REMOTE_DATABASE_PASSWORD}';

DROP DATABASE IF EXISTS quantum;
CREATE DATABASE IF NOT EXISTS quantum;
GRANT ALL PRIVILEGES ON quantum.* TO 'quantum'@'%' IDENTIFIED BY '${REMOTE_DATABASE_PASSWORD}';
GRANT ALL PRIVILEGES ON quantum.* TO 'quantum'@'localhost' IDENTIFIED BY '${REMOTE_DATABASE_PASSWORD}';
" > /tmp/init.sql

    echo "mysql -u root -p${REMOTE_DATABASE_PASSWORD} < /tmp/init.sql"
}
