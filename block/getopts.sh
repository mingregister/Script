#!/bin/bash
# simple demonstration of the getopts command

while getopts :ab:c opt
do
	case "$opt" in
	a) echo "Found the -a option";;
	b) echo "Found the -b option, with value $OPTARG";;
	c) echo "Found the -c option";;
	*) echo "Unknown option:$opt";;
	esac
done

####
while getopts "m:nsbe:h:u:p:d:y:?h" flag; do
    case $flag in
        h)    DBHOST=$OPTARG    ;;
        u)    DBUSER=$OPTARG    ;;
        p)    DBPASS=$OPTARG    ;;
        e)    EMAIL=$OPTARG     ;;
        s)    SIMULATE=1        ;;
        n)    NONINTERACTIVE=1  ;;
        b)    BACKUP=1          ;;
        d)    h=$OPTARG
            if [ $h -gt 0 ] 2>/dev/null; then
                daily_history_min=$h
            else
                echo "Invalid daily history min, exiting"
                exit 1
            fi
            ;;
        m)    h=$OPTARG
            if [ $h -gt 0 ] 2>/dev/null; then
                monthly_history_min=$h
            else
                echo "Invalid monthly history min, exiting"
                exit 1
            fi
            ;;

        y)    yy=$OPTARG
            if [ $yy -lt $y -a $yy -gt 2000 ] 2>/dev/null; then
                first_year=$yy
            else
                echo "Invalid year, exiting"
                exit 1
            fi
            ;;
        ?|h)    usage ;;
    esac
done
shift $((OPTIND-1))
