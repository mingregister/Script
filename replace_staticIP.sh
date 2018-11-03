#!/usr/bin/env bash

set -eu
# set -x
set -o pipefail

CONFIGFILE=/etc/sysconfig/network-scripts/ifcfg-ens33
MASK=''
IP=''
GATEWAY=''

function usage() {
  cat >&2 <<-'EOF'
    USAGE：
      -i --ip(required): ip address
      -m --mask: NETMASK
      -g --gateway: GATEWAY
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --ip | -i)
      IP=$2
      shift             # 如果是参数组的话，加上这个shift，如果不是，那就不需要加。
      ;;
  --mask | -m)
      MASK=$2
      shift
      ;;
  --gateway | -g)
      GATEWAY=$2
      shift
      ;;
  --* | -* | * | -h)
      echo "Illegal option $1"
      usage
      exit 1
      ;;
  esac
  shift $(( $# > 0 ? 1 : 0 ))
done

if [[ -z ${IP} ]]; then
  echo "IP must be passed"
fi

if [[ -z ${MASK} ]]; then
  MASK=255.255.255.0
fi

if [[ -z ${GATEWAY} ]]; then
  GATEWAY=192.168.160.1
fi

sed -i "s/^BOOTPROTO.*/BOOTPROTO=static/" ${CONFIGFILE}
sed -i "4a NETMASK=${MASK}" ${CONFIGFILE}
sed -i "4a GATEWAY=${GATEWAY}" ${CONFIGFILE}
sed -i "4a IPADDR=${IP}" ${CONFIGFILE}
