#!/usr/bin/env bash

# 测试已可用！！！

set -eu
set -x
set -o pipefail

# MYSQL_USER=bkpuser
# MYSQL_PASSWORD=admin123
# MYSQL_SOCKET=/var/lib/mysql/mysql.sock
DEFAULTSFILE=/etc/my.cnf
# BACKUPNAME_prefix=ZabbixBackup
BACKUPDIR_prefix=/data/backup
INNOBACKUPEX=/usr/bin/innobackupex

DATADIR=/var/lib/mysql
dirowner=mysql
dirgroup=mysql

DATE_tmp=$(date +%Y%m)
BACKUPDIR=${BACKUPDIR_prefix}/${DATE_tmp}
if [[ ! -d ${BACKUPDIR} ]]; then
  DATE_tmp=$(date +%Y%m -d '1 month ago')
  BACKUPDIR=${BACKUPDIR_prefix}/${DATE_tmp}
fi
# DATE=$(date +%Y-%m-%d_%H-%M-%S)
# BACKUPNAME=${BACKUPNAME_prefix}-${DATE}
BACKUPLOG=${BACKUPDIR}/backuplog

function line_counter() {
  line_count=$(cat ${BACKUPLOG} | wc -l)
}

function get_fulldir_name() {
  fulldirname=$(cat ${BACKUPLOG} | grep FULL | sed '/^$/!h;$!d;g' | awk -F':' '{print $2}')
}

function get_incrementaldir_name() {
  incrementaldirname=$(cat ${BACKUPLOG} | grep INCREMENTAL | awk -F':' '{print $2}')
}

function restore_full() {
  line_counter
  if [[ ${line_count} -eq 1 ]]; then
    readonly=' '
  else
    readonly='--redo-only'
  fi
  ${INNOBACKUPEX} --defaults-file=${DEFAULTSFILE} --apply-log ${readonly} ${fulldirname}
}

function restore_incremental() {
  line_counter
  if [[ ${line_count} -eq 1 ]]; then
    return 0
  fi
  get_incrementaldir_name
  lastbackupname=$(cat ${BACKUPLOG} | grep INCREMENTAL | sed '/^$/!h;$!d;g' | awk -F':' '{print $2}')
  for dirname in ${incrementaldirname[@]}; do
    if [[ ${dirname} != ${lastbackupname} ]]; then
      readonly='--redo-only'
    else
      readonly=' '
    fi
    ${INNOBACKUPEX} --defaults-file=${DEFAULTSFILE} --apply-log ${readonly} ${fulldirname} --incremental-dir=${dirname}
  done
}

function restore_all() {
  ${INNOBACKUPEX} --defaults-file=${DEFAULTSFILE} --copy-back --rsync ${fulldirname}
  chown -R ${dirowner}:${dirgroup} ${DATADIR}
}

function stop_service() {
  systemctl stop mysqld || systemctl stop mariadb
}

function start_service() {
  systemctl start mysqld  || systemctl start mariadb
}

function do_restore() {
  stop_service
  line_counter
  get_fulldir_name
  restore_full
  restore_incremental
  restore_all
  start_service
}

do_restore
