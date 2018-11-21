#!/usr/bin/env bash

# pretask
# 修改网卡，获取dhcp的ip
# vi /etc/sysconfig/network-scripts/ifcfg-ens33
# onboot=yes

ROOTPASSWD=admin123
NEWUSER=zmhuang
NEWUSERPASSWD=admin123
HOSTNAME=initvm
IP=192.168.160.194
GATEWAY=192.168.160.2
MASK=255.255.255.0
YUMSOURCE=http://mirrors.aliyun.com/repo/Centos-7.repo

### DO NOT CHANGE THE BELOW CODE ###
echo root:${ROOTPASSWD} | chpasswd

useradd ${NEWUSER}
echo ${NEWUSER}:${NEWUSERPASSWD} | chpasswd
touch /etc/sudoers.d/${NEWUSER}
echo "${NEWUSER} ALL=(ALL)       NOPASSWD:ALL" >> /etc/sudoers.d/${NEWUSER}

# 关闭selinux
sed -i 's/^SELINUX=.*/SELINUX=disable/g' /etc/selinux/config
setenforce 0

# aliyun yum源
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
curl -o /etc/yum.repos.d/CentOS-Base.repo ${YUMSOURCE}

# ntpdate
yum install ntpdate -y
echo '*/30  *  *  *  * root /sbin/ntpdate cn.ntp.org.cn' >> /etc/crontab

# 修改hostname
hostnamectl set-hostname ${HOSTNAME}
# 修改/etc/hosts
cp /etc/hosts /etc/hosts.bak
cat >/etc/hosts <<-'EOF'
127.0.0.1  ${HOSTNAME}
::1        ${HOSTNAME}
EOF

# 禁止root登录
sed -i 's/^.*PermitRootLogin.*/PermitRootLogin no/g' /etc/ssh/sshd_config
systemctl restart sshd

# 修改静态IP
sh replace_staticIP.sh -i ${IP} -g ${GATEWAY} -m ${MASK}
