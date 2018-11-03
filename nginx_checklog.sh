#!/usr/bin/env bash

set -eu
# set -x
set -o pipefail

LOG=$1
NUM=$2
# LOG=/tmp/1000access.log
# NUM=1000

function Count_http_status() {
    Http_status_codes=`tail -n ${NUM} ${LOG} | \
        grep -ioE "HTTP\/1\.[1|0]\"[[:blank:]][0-9]{3}" | \
            awk -F"[ ]+" '{
                if ($2>=200&&$2<300)
                    {j++}
                else if($2>=400&&$2<500)
                    {n++}
                else if($2>=300&&$2<400)
                    {k++}
                else if($2>=500)
                    {p++}
                else if($2>100&&$2<200)
                    {i++}
            }END{
                print i?i:0,j?j:0,k?k:0,n?n:0,p?p:0,i+j+k+n+p
            }'`
        echo -e '\E[33m'"The number of http status [100+]:"  $(echo -n ${Http_status_codes} | awk '{print $1}')
        echo -e '\E[33m'"The number of http status [200+]:"  $(echo -n ${Http_status_codes} | awk '{print $2}')
        echo -e '\E[33m'"The number of http status [300+]:"  $(echo -n ${Http_status_codes} | awk '{print $3}')
        echo -e '\E[33m'"The number of http status [400+]:"  $(echo -n ${Http_status_codes} | awk '{print $4}')
        echo -e '\E[33m'"The number of http status [500+]:"  $(echo -n ${Http_status_codes} | awk '{print $5}')
        echo -e '\E[33m'"All Request Numbers:"  $(echo -n ${Http_status_codes} | awk '{print $6}')
}

function Check_http_code() {
    Http_codes=`tail -n  ${NUM} ${LOG} | \
        grep -ioE "HTTP\/1\.[1|0]\"[[:blank:]][0-9]{3}" | \
            awk -v total=0 -F"[ ]+" '{
                if ($2!="")
                    {code[$2]++;total++}
                else
                    {exit}
                }END{
                    print code[404]?code[404]:0,code[403]?code[403]:0,total
                }'`
    echo -e '\E[33m'"The number of http status [404]:"  $(echo -n ${Http_codes} | awk '{print $1}')
    echo -e '\E[33m'"The number of http status [403]:"  $(echo -n ${Http_codes} | awk '{print $2}')
    echo -e '\E[33m'"All Request Numbers:"  $(echo -n ${Http_codes} | awk '{print $3}')
}
# echo `date +%Y%m%d-%H:%M:%S`
Count_http_status
Check_http_code
# echo `date +%Y%m%d-%H:%M:%S`
echo -e '\E[37m'
