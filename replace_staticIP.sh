#!/usr/bin/env bash

set -eu
# set -x
set -o pipefail

# CONFIGFILE=/tmp/ifcfg-ens33
CONFIGFILE=/etc/sysconfig/network-scripts/ifcfg-ens33
 
function usage() {
  cat >&2 <<-'EOF'
    USAGE：
      -i --ip(required): ip address
      -m --mask: NETMASK
      -g --gateway: GATEWAY
EOF
}

DEFAULTIP=''
DEFAULTMASK=255.255.255.0
DEFAULTGATEWAY=192.168.160.2

while getopts "i:m:g:" opt; do
    case ${opt} in
        i )
            ip=${OPTARG}
            ;;
        m )
            mask=${OPTARG}
            ;;
        g )
            gateway=${OPTARG}
            ;;            
    esac
done
shift $((OPTIND-1))

IP=${ip:-${DEFAULTIP}}
MASK=${mask:-${DEFAULTMASK}}
GATEWAY=${gateway:-${DEFAULTGATEWAY}}

if [[ -z ${IP} ]]; then
  echo "IP must be passed"
  usage
  exit 1
fi

sed -i "s/^BOOTPROTO.*/BOOTPROTO=static/" ${CONFIGFILE}
sed -i "4a NETMASK=${MASK}" ${CONFIGFILE}
sed -i "4a GATEWAY=${GATEWAY}" ${CONFIGFILE}
sed -i "4a IPADDR=${IP}" ${CONFIGFILE}
