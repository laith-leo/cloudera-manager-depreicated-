#!/bin/bash
# Authuor: Laith Al Obaidy
# Email: laith@laith.info, laith@cloudera.com
# URL: www.laith.info
# Date: 01/17/2017
# version: 1.0.0
#INSTALL CM5 SHELL FOR A RHEL6.* BASED#


##Colors variables
RED="\033[1;31m"
YELLOW="\033[1;33m"
GREEN="\033[1;32m"
BOLD="\033[1m"
RESET="\033[0m"

#Setting swappiness to 1 on the kernel level
echo 1 > /proc/sys/vm/swappiness


echo "Cloudera Manager is being installed, please wait.. "

#No firewalls!
iptables -F
chkconfig iptables off

###Disabling SELinux
sed -i 's/enforcing/disabled/g' /etc/selinux/config /etc/selinux/config
echo -e "${RED}System needs to be rebooted to disable SELinux"

###STARTING MYSQL PART OF INSTALLATION###
MYSQL_PASS=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1`
yum install mysql-server -y  &>/dev/null
service mysqld start && chkconfig mysqld on
mysql -e "update mysql.user set password=PASSWORD('$MYSQL_PASS') where User='root';"
mysql -e "FLUSH PRIVILEGES"
echo `service mysqld restart` &>/dev/null
echo '[mysql]' > /root/.my.cnf
echo 'user=root' >> /root/.my.cnf
echo "password=$MYSQL_PASS" >> /root/.my.cnf
echo "auto-rehash" >> /root/.my.cnf
mysql -e 'drop database test'
mysql -e "create database cmf"
mysql -e "create user 'cmf'@'%' identified by 'cmf';"
mysql -e "grant all privileges on cmf.* to 'cmf'@'%' identified by 'cmf';"
mysql -e "grant all privileges on cmf.* to 'cmf'@'localhost' identified by 'cmf';"
mysql -e "update mysql.user set password=PASSWORD('cmf') where User='cmf';"
mysql -e "create database hue;"
mysql -e "create database oozie;"
mysql -e "create database rmon;"
mysql -e "create database hive;"
mysql -e "create database amon;"
mysql -e "create database sentry;"
mysql -e "grant all ON hive.* TO 'hive'@'%' IDENTIFIED BY 'hive';"
mysql -e "grant all ON rmon.* TO 'rmon'@'%' IDENTIFIED BY 'rmon';"
mysql -e "grant all ON hue.* TO 'hue'@'%' IDENTIFIED BY 'hue';"
mysql -e "grant all ON oozie.* TO 'oozie'@'%' IDENTIFIED BY 'oozie';"
mysql -e "grant all ON amon.* TO 'amon'@'%' IDENTIFIED BY 'amon';"
mysql -e "grant all ON sentry.* TO 'sentry'@'%' IDENTIFIED BY 'sentry';"
###END OF MYSQL PART INSTALLATION###

#Installing Cloudera Repository
curl -O http://archive.cloudera.com/cm5/redhat/6/x86_64/cm/cloudera-manager.repo
mv /root/cloudera-manager.repo /etc/yum.repos.d/ && yum repolist  &>/dev/null ; yum clean all

#Installing Cloudera Manager along with my tools
yum install python epel-* wget vim screen nc python java oracle-j2sdk1.7.x86_64 bash-completion cloudera-manager-daemons cloudera-manager-server -y

wget https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.42.tar.gz
tar -xf mysql-connector-java-5.*
mkdir /usr/share/java/
cp mysql-connector-java-*/mysql-connector-java-* /usr/share/java/mysql-connector-java.jar

bash /usr/share/cmf/schema/scm_prepare_database.sh mysql cmf cmf cmf

service cloudera-scm-server start
chkconfig cloudera-scm-server on


MYIP=`hostname -I | cut -d " " -f 1`
echo ""
echo -e "${YELLOW}Now you can login into your Cloudera Manager 5 on ${RED}http://$MYIP:7180 or ${GREEN}http://`hostname`:7180 ${RESET}"
echo ""
