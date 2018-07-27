#! /bin/sh
# Restart Samba Service 
# Jacques Duplessis
# 2018_07_27    v1.0 Initial Version
#
tput clear
wosname=`lsb_release -si | tr '[:lower:]' '[:upper:]'`
if [ "$wosname" = "REDHATENTERPRISESERVER" ] ; then wosname="REDHAT" ; fi
if [ "$wosname" = "REDHATENTERPRISEAS" ]     ; then wosname="REDHAT" ; fi

echo "Before Stop"
ps -ef | grep smb | grep -v grep

if [ "${wosname}" = "REDHAT" ] || [ "${wosname}" = "CENTOS" ] || [ "${wosname}" = "FEDORA" ]
    then systemctl restart smb.service
    else systemctl restart smbd.service
fi

echo "After Start"
ps -ef | grep smb | grep -v grep
echo " " 
