#! /usr/bin/env bash 

TOP_DIR=$(cd $(dirname "$0") && pwd)
source ${TOP_DIR}/../install-common.sh

myT2 "Begin Install MySQL!"

myT3 "Install MySQL"
cat <<MYSQL_PRESEED | sudo debconf-set-selections
mysql-server-5.1 mysql-server/root_password password $REMOTE_DATABASE_PASSWORD
mysql-server-5.1 mysql-server/root_password_again password $REMOTE_DATABASE_PASSWORD
mysql-server-5.1 mysql-server/start_on_boot boolean true
MYSQL_PRESEED

if [[ ! -e $HOME/.my.cnf ]]; then
    cat <<EOF >$HOME/.my.cnf
[client]
user=root
password=$REMOTE_DATABASE_PASSWORD
host=localhost
EOF
    chmod 0600 $HOME/.my.cnf
fi
sudo apt-get install mysql-server -y

myT3 "Config MySQL"
sudo chmod 777 /etc/mysql
sudo chmod 777 /etc/mysql/my.cnf
sudo sed -i "s/^bind-address/#bind-address/" /etc/mysql/my.cnf
sudo chmod 755 /etc/mysql
sudo chmod 644 /etc/mysql/my.cnf

cat <<MYSQL_CONF >/tmp/mysql_conf.sql
GRANT ALL PRIVILEGES ON *.* TO root@localhost IDENTIFIED BY "${REMOTE_DATABASE_PASSWORD}"; 
GRANT ALL PRIVILEGES ON *.* TO root@"%" IDENTIFIED BY "${REMOTE_DATABASE_PASSWORD}"; 
MYSQL_CONF
mysql -u root -p${REMOTE_DATABASE_PASSWORD} < /tmp/mysql_conf.sql

myT3 "Restart MySQL"
sudo service mysql restart

myT2 "End Install MySQL!"
