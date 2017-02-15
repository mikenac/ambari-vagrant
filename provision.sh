#!/bin/bash

echo "Updating system"
sudo yum  -y update

echo "Installing pre-requisites"
sudo yum -y install scp curl unzip tar wget openssl.x86_64 ntp

echo "Setting open file limits"
sudo sysctl -p /etc/sysctl.conf
sudo sysctl -w fs.file-max=100000
sudo sysctl --system
echo "* soft nofile 10000" | sudo tee -a /etc/security/limits.conf > /dev/null
echo "* hard nofile 10000" | sudo tee -a /etc/security/limits.conf > /dev/null
sudo sysctl -p

echo "Enabling NTP - change if you are not in North America"
sudo sed -i '/server .*/d' /etc/ntpd.conf
echo "server 0.north-america.pool.ntp.org" | sudo tee -a /etc/ntp.conf > /dev/null
echo "server 1.north-america.pool.ntp.org" | sudo tee -a /etc/ntp.conf > /dev/null
echo "server 2.north-america.pool.ntp.org" | sudo tee -a /etc/ntp.conf > /dev/null
echo "server 3.north-america.pool.ntp.org" | sudo tee -a /etc/ntp.conf > /dev/null
sudo systemctl enable ntpd
sudo systemctl start ntpd

echo "Leaving hosts and DNS set to localhost.localdomain"

echo "Disabling firewall"
sudo systemctl disable firewalld
sudo systemctl stop firewalld

echo "Turning off SELinux"
sudo setenforce 0

echo "Installing Java"
sudo yum  -y install java-1.8.0-openjdk.x86_64
if [ ! -f /etc/profile.d/java.sh ];
then
	echo "export JAVA_HOME=/usr/lib/jvm/jre-1.8.0-openjdk" | sudo tee -a  /etc/profile.d/java.sh > /dev/null
fi
source /etc/profile.d/java.sh

echo "Setting up root user for passwordless access"
USER_HOME=/root
sudo  mkdir $USER_HOME/.ssh
sudo chmod 700 $USER_HOME/.ssh
sudo  ssh-keygen -t dsa -P '' -f $USER_HOME/.ssh/id_dsa
sudo  bash -c "cat $USER_HOME/.ssh/id_dsa.pub >> $USER_HOME/.ssh/authorized_keys"
sudo  bash -c "ssh-keyscan -H localhost >> $USER_HOME/.ssh/known_hosts"
sudo chmod 600 $USER_HOME/.ssh/authorized_keys

echo "Configuring Yum repos"
sudo wget -nv http://public-repo-1.hortonworks.com/ambari/centos7/2.x/updates/2.4.2.0/ambari.repo -O /etc/yum.repos.d/ambari.repo 

echo "Installing Ambari"
sudo yum -y install ambari-server

echo "Ambari server installed. Run 'ambari-server setup'"
sudo ambari-server setup -j $JAVA_HOME -s
sudo ambari-server start

