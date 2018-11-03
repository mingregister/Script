#!/usr/bin/env bash

RPM=http://repo.zabbix.com/zabbix/3.4/rhel/7/x86_64/zabbix-release-3.4-1.el7.centos.noarch.rpm
ZBXPACKAGES='zabbix-get zabbix-server zabbix-web-mysql zabbix-web zabbix-agent '
DBPACKAGES='mariadb mariadb-server'
MYCNF=/etc/my.cnf
PASSWD=admin
ZBXSERVERCONFIG=/etc/zabbix/zabbix_server.conf
ZABCLIENTCONFIG=/etc/zabbix/zabbix_agentd.conf
HTTPDCONFIG=/etc/httpd/conf.d/zabbix.conf
PHPCONFIG=/etc/php.ini

if [[ $(id -u) = "0" ]]; then
  SUDO=' '
else
  SUDO=sudo
fi

${SUDO} cat /var/log/messages > /dev/null
if [[ $? -ne 0 ]]; then
  echo "you don not have SUDO privileges"
  echo "please contact the administrator or use root to install"
  exit 1
fi

if [[ $(getenforce) -ne 'Disable' ]]; then
  echo "please close selinux first."
  echo "refer to /etc/sysconfig/selinux"
  exit 1
fi

FIREWALLDSTATUS=$(systemctl status firewalld | sed -n '3p' | awk -F':' '{print $2}' | awk '{print $1}')
if [[ ${FIREWALLDSTATUS} = 'active' ]]; then
  echo "you have to close the firewalld or config the policy yourself first"
  echo "type 1 for close the firewalld"
  echo "type 2 for config the policy yourself and exit the install"
  while true; do
    read -p "please input your choice 1 or 2: " choice
    if [[ ${choice} -eq 1 ]]; then
      ${SUDO} systemctl stop firewalld && ${SUDO} systemctl disable firewalld
      break
    elif [[ ${choice} -eq 2 ]]; then
      echo "now please config firewalld policy first"
      exit 1
    else
      continue
    fi
  done
fi

${SUDO} rpm -ivh ${RPM}
${SUDO} yum install  -y ${ZBXPACKAGES}
${SUDO} yum install  -y ${DBPACKAGES}
VERSION=$(rpm -qa zabbix-server-mysql | awk -F'-' '{print $4}')

${SUDO} sed -i '9a innodb_file_per_table=1' ${MYCNF}
${SUDO} sed -i '9a character-set-server=utf8' ${MYCNF}

${SUDO} systemctl start mariadb
if [[ $? -ne 0 ]]; then
  exit 1
fi
${SUDO} systemctl enable mariadb

mysqladmin -uroot password ${PASSWD}

mysql -uroot -p${PASSWD} -e "create database zabbix character set utf8;grant all privileges on zabbix.* to zabbix@localhost identified by 'zabbix';flush privileges;"

${SUDO} zcat /usr/share/doc/zabbix-server-mysql-${VERSION}/create.sql.gz | mysql -uzabbix -pzabbix zabbix
# zabbix_server.conf
${SUDO} sed -i 's/# DBHost=localhost/DBHost=localhost/' ${ZBXSERVERCONFIG}
# ${SUDO} sed -i 's/DBName=zabbix/DBName=zabbix/' ${ZBXSERVERCONFIG}
# ${SUDO} sed -i 's/DBUser=zabbix/DBUser=zabbix/' ${ZBXSERVERCONFIG}
${SUDO} sed -i 's/# DBPassword=/DBPassword=zabbix/' ${ZBXSERVERCONFIG}
${SUDO} sed -i 's/# StartPollers=5/StartPollers=5/' ${ZBXSERVERCONFIG}
${SUDO} sed -i 's/# CacheSize=8M/CacheSize=256M/' ${ZBXSERVERCONFIG}

${SUDO} mkdir /etc/zabbix/{alertscripts,externalscripts}

${SUDO} systemctl start zabbix-server
${SUDO} systemctl enable zabbix-server
# http config
${SUDO} sed -i '13s/.*/        php_value max_execution_time 300/' ${HTTPDCONFIG}
${SUDO} sed -i '14s/.*/        php_value memory_limit 128M/' ${HTTPDCONFIG}
${SUDO} sed -i '15s/.*/        php_value post_max_size 16M/' ${HTTPDCONFIG}
${SUDO} sed -i '16s/.*/        php_value upload_max_filesize 2M/' ${HTTPDCONFIG}
${SUDO} sed -i '17s/.*/        php_value max_input_time 300/' ${HTTPDCONFIG}
${SUDO} sed -i '18s/.*/        php_value always_populate_raw_post_data -1/' ${HTTPDCONFIG}
${SUDO} sed -i '19s/.*/        php_value date.timezone Asia\/Shanghai/' ${HTTPDCONFIG}
# php config
${SUDO} sed -i '878s/.*/date.timezone = Asia\/Shanghai/' ${PHPCONFIG}
${SUDO} sed -i '384s/.*/max_execution_time = 300/' ${PHPCONFIG}
${SUDO} sed -i '672s/.*/post_max_size = 16M/' ${PHPCONFIG}
${SUDO} sed -i '394s/.*/max_input_time = 300/' ${PHPCONFIG}
${SUDO} sed -i '405s/.*/memory_limit = 128M/' ${PHPCONFIG}
${SUDO} sed -i '1704s/.*/mbstring.func_overload = 0/' ${PHPCONFIG}


${SUDO} systemctl start httpd
${SUDO} systemctl enable httpd