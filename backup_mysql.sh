#!/usr/bin/env bash

# crontab -e
# 03 1 * * * /usr/bin/sh /root/backup_mysql.sh

set -eu
set -x
set -o pipefail

MYSQL_USER=bkpuser
MYSQL_PASSWORD=admin123
MYSQL_SOCKET=/var/lib/mysql/mysql.sock
DEFAULTSFILE=/etc/my.cnf
BACKUPNAME_prefix=ZabbixBackup
BACKUPDIR_prefix=/data/backup
INNOBACKUPEX=/usr/bin/innobackupex

# DO NOT CHANGE THE BELOW CODE!!!
DATE_tmp=$(date +%Y%m)
BACKUPDIR=${BACKUPDIR_prefix}/${DATE_tmp}

# create backupdir if it not exists.
if [[ ! -d ${BACKUPDIR} ]]; then
  mkdir -p ${BACKUPDIR}
fi

DATE=$(date +%Y-%m-%d_%H-%M-%S)
BACKUPNAME=${BACKUPNAME_prefix}-${DATE}
BACKUPLOG=${BACKUPDIR}/backuplog

function get_backup_basedir() {
  backup_basedir_prefix=$(cat ${BACKUPLOG} | sed '/^$/!h;$!d;g' | awk -F':' '{print $1}')
  if [[ ${backup_basedir_prefix} == 'FULL' ]]; then
    backup_basedir=$(cat ${BACKUPLOG} | grep FULL | sed '/^$/!h;$!d;g' | awk -F':' '{print $2}')
  else
    backup_basedir=$(cat ${BACKUPLOG} | grep INCREMENTAL | sed '/^$/!h;$!d;g' | awk -F':' '{print $2}')
  fi
}

function full_backup_per_month() {
  ${INNOBACKUPEX} --defaults-file=${DEFAULTSFILE} --no-timestamp --user=${MYSQL_USER} --password=${MYSQL_PASSWORD} --socket=${MYSQL_SOCKET}  ${BACKUPDIR}/full-${BACKUPNAME}
  echo "FULL:${BACKUPDIR}/full-${BACKUPNAME}" >> ${BACKUPLOG}
}

function incremental_backup_per_week() {
  get_backup_basedir

  ${INNOBACKUPEX} --defaults-file=${DEFAULTSFILE} \
  --no-timestamp \
  --user=${MYSQL_USER} --password=${MYSQL_PASSWORD} --socket=${MYSQL_SOCKET}  \
  --incremental ${BACKUPDIR}/incremental-${BACKUPNAME} \
  --incremental-basedir=${backup_basedir}/ \
  --parallel=2
  echo "INCREMENTAL:${BACKUPDIR}/incremental-${BACKUPNAME}" >> ${BACKUPLOG}
}

function clear_old_backup() {
  DATE_old=$(date +%Y%m -d '3 month ago')
  BACKUPDIR_old=${BACKUPDIR_prefix}/${DATE_old}
  if [[ -f ${BACKUPDIR_old} ]]; then
    rm -rf ${BACKUPDIR_old}/*
  fi
}

function backup() {
  if [[ $(/usr/bin/date -d today +\%e) -eq 1 ]]; then    # 必须是1号进行全备，不然会有bug
    full_backup_per_month
    clear_old_backup
  elif [[ $(date +%w) -eq 7 ]]; then
    incremental_backup_per_week
  fi
}

backup
