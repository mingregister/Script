#!/usr/bin/env bash

set -eu
#set -x
set -o pipefail

while [[ $# -gt 0 ]]; do
    case "$1" in
        --pattern1 | -p1)
            PATTERN1=$2
            # do something
            echo ${PATTERN1}
            shift
            ;;
        --pattern2 | -p2)
            PATTERN2=$2
            # do something
            echo ${PATTERN2}
            shift
            ;;
        --pattern3 | -p3)
            PATTERN3=$2
            # do something
            echo ${PATTERN3}
            shift
            ;;
        --*)
            echo "Illegal option $1"
            exit 1
            ;;
    esac
    shift $(( $# > 0 ? 1 : 0 ))
done

#until [ $# -eq 0 ]; do
# echo "第一个参数为: $1 参数个数为: $#"
# shift
#done
