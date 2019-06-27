#!/usr/bin/env bash

# set -eu
# set -x
# set -o pipefail

###Usage#####
# 按如下格式填写${HOME}/sshinfo.csv的内容
# 注意这个文件的内容不能包括自身的ip, 注释set -eu或者就可以包括自身的ip了。
## cat ${SSHINFO}
#192.168.160.192,root,admin123
#192.168.160.193,root,admin123
###Usage#####

KEYFILE=${HOME}/.ssh/id_rsa
SSHINFO=${HOME}/sshinfo.csv

#### DO NOT CHANGE THE BELOW CODE!!! ####
EXPECT=$(which expect)
KnownHost=${HOME}/.ssh/known_hosts
[ ! -e "${KEYFILE}" ] && ssh-keygen -t rsa -P '' -f ${KEYFILE} >/dev/null 2>&1

function ssh_expect() {
    # $1:IP $2:USER $3:PASSWORD
    # 如果需要debug,可以将 /dev/null 改成 /tmp/log
    # ${EXPECT} << EOF > /dev/null 2>&1
    ${EXPECT} << EOF >> /tmp/log 2>&1
        set timeout 5
        spawn ssh-copy-id -i ${KEYFILE}.pub -p 22 $2@$1
        expect {
            "yes/no" {send "yes\r";exp_continue}
            "*assword" {send "$3\r"}
        }
        expect eof
EOF
}

function ssh_expect_knownHost() {
    # $1:IP $2:USER $3:PASSWORD
    # 如果需要debug,可以将 /dev/null 改成 /tmp/log
    # ${EXPECT} << EOF > /dev/null 2>&1
    ${EXPECT} << EOF >> /tmp/log 2>&1
        set timeout 5
        spawn ssh-copy-id -i ${KEYFILE}.pub -p 22 $2@$1
        expect {
            "*assword" {send "$3\r"}
        }
        expect eof
EOF
}

sshinfos=$(cat ${SSHINFO})
for info in ${sshinfos}; do
    IP=$(echo ${info} | awk -F',' '{print $1}')
    USER=$(echo ${info} | awk -F',' '{print $2}')
    PASSWORD=$(echo ${info} | awk -F',' '{print $3}')
    grep -ioE ${IP} ${KnownHost} >/dev/null 2>&1
    if [[ $? == 0 ]]; then
      ssh_expect_knownHost ${IP} ${USER} ${PASSWORD}
      # 这里无论怎么样，都是echo SUCCESS的，你要根据时间来判断。
      # 如果是echo FAILED的话，那么就是原本就有密码了。
      [[ $? == 0 ]] && echo "${IP} SUCCESS" || echo "${IP} FAILED"
    else
      ssh_expect ${IP} ${USER} ${PASSWORD}
      [[ $? == 0 ]] && echo "${IP} SUCCESS" || echo "${IP} FAILED"
    fi
done
