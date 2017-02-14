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

echo "Enabling NTP"
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

echo "Creating user for installation"
sudo useradd -m -c "hdp" hdp -s /bin/bash
sudo gpasswd -a hdp wheel

# create a passwordless logon for installation user
USER_HOME=/home/hdp
sudo -u hdp mkdir $USER_HOME/.ssh
sudo chmod 700 $USER_HOME/.ssh
sudo -u hdp ssh-keygen -t dsa -P '' -f $USER_HOME/.ssh/id_dsa
sudo -u hdp bash -c "cat $USER_HOME/.ssh/id_dsa.pub >> $USER_HOME/.ssh/authorized_keys"
sudo -u hdp bash -c "ssh-keyscan -H localhost >> $USER_HOME/.ssh/known_hosts"
sudo chmod 600 $USER_HOME/.ssh/authorized_keys
echo "Created user 'hdp' for running application."

echo "Configuring Yum repos"
sudo wget -nv http://public-repo-1.hortonworks.com/ambari/centos7/2.x/updates/2.1.1/ambari.repo -O /etc/yum.repos.d/ambari.repo

echo "Installing Ambari"
sudo yum -y install ambari-server

echo "Ambari server installed. Run 'ambari-server setup'"
sudo ambari-server setup -j $JAVA_HOME -s
sudo ambari-server start

