#!/usr/bin/env bash

set -eu
# set -x
# set -o pipefail

###Usage#####
# 按如下格式填写${HOME}/sshinfo.csv的内容
# 注意这个文件的内容不能包括自身的ip, 注释set -eu或者就可以包括自身的ip了。
## cat ${SSHINFO}
#192.168.160.192,zmhuang,admin123
#192.168.160.193,zmhuang,admin123 
###Usage#####

KEYFILE=${HOME}/.ssh/id_rsa
SSHINFO=${HOME}/sshinfo.csv
EXPECT=/bin/expect

[ ! -e "${KEYFILE}" ] && ssh-keygen -t rsa -P '' -f ${KEYFILE} >/dev/null 2>&1

function ssh_expect() {
    # $1:IP $2:USER $3:PASSWORD
    # 如果需要debug,可以将 /dev/null 改成 /tmp/log
    ${EXPECT} << EOF > /dev/null 2>&1
        spawn ssh-copy-id -i ${KEYFILE}.pub -p 22 $2@$1
        expect {
            "yes/no" {send "yes\r";exp_continue}
            "password" {send "$3\r"}
        }
        expect eof
EOF
}

sshinfos=$(cat ${SSHINFO})
for info in ${sshinfos}; do
    IP=$(echo ${info} | awk -F',' '{print $1}')
    USER=$(echo ${info} | awk -F',' '{print $2}')
    PASSWORD=$(echo ${info} | awk -F',' '{print $3}')
    ssh_expect ${IP} ${USER} ${PASSWORD}
done

