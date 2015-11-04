root@lxmq1003:/etc/named.dat# cat /sysadmin/bin/dnstar.sh 
#! /bin/sh
#############################################################################################
# Title      :  dnstar.sh
# Version    :  1.0
# Author     :  Jacques Duplessis
# Date       :  19 Mars 2004
# Requires   :  sh - Bourne Shell
# SCCS-Id.   :  @(#) dnstar.sh 1.1 03/07/22
#############################################################################################
# Description
#   Run once a week - Tar DNS files
#   1.3 July 2011 - Modified to include jnl file cleanup (apply journal).
#
#############################################################################################
#set -x

#
# Define Global Variables
#############################################################################################
TODAY=$(date "+%d.%m.%Y")                       ; export TODAY     # Todays Date
BASE_DIR="/var/named_backup"                    ; export BASE_DIR  # Base Directories
BASE_FILE="${BASE_DIR}/dns_master_${TODAY}.tar" ; export BASE_FILE
GZIP_FILE="${BASE_DIR}/dns_master_${TODAY}.tgz" ; export GZIP_FILE
UUFILE="/tmp/dns_master_${TODAY}.uu"            ; export UUFILE
WDAY=$(date "+%u")                              ; export WDAY
PN=${0##*/}                                     ; export PN        # Program name
VER='1.3'                                       ; export VER       # Program Version
DNSADMIN="duplessis.jacques@gmail.com"          ; export DNSADMIN



#
# This is where the Program Begin
#############################################################################################
tput clear
echo "Program $PN Version $VER is starting - `date`"

tar -cvf ${BASE_FILE} /var/named
chmod 444 ${BASE_FILE}

# Send a copy of the backup to sysadmin once a week
/bin/gzip -c ${BASE_FILE} > ${GZIP_FILE}
echo "GZIP_FILE" 
ls -l ${GZIP_FILE}
echo "BASE_FILE" 
ls -l ${BASE_FILE}
/usr/bin/uuencode ${GZIP_FILE} ${GZIP_FILE} > ${UUFILE} 
echo "UUFILE=${UUFILE}"
ls -l ${UUFILE}
TO="duplessis.jacques@gmail.com"
mail -s "DNS_MASTER_${TODAY}" $DNSADMIN < ${UUFILE}
rm -f ${UUFILE} ${GZIP_FILE}

# Apply Zone journal to all zone
cd /etc/named.dat
ls -1 | grep -vE 'localhost.rev|master.localhost|named_stats.txt|root.servers|statistics-file|*.jnl' > /tmp/coco.txt
cat /tmp/coco.txt | while read wline
        do
        echo "rndc freeze $wline"
        rndc freeze $wline
        echo "rndc thaw   $wline"
        rndc thaw   $wline
        done
rm -f /tmp/coco.txt > /dev/null 2>&1

# This is where the Program END
echo "End of Program $PN - `date`"
