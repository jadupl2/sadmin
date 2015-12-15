#! /bin/sh
##########################################################################
# Shellscript:	rsync_laptop.sh - server/laptop rsync script
# Version    :	1.2
# Author     :	jacques duplessis (duplessis.jacques@gmail.com)
# Date       :	2009-01-12
# Requires   :	bash shell 
# Category   :	backup
# SCCS-Id.   :	@(#) rsync_laptop.sh 1.2 12.01.2009
##########################################################################
# Description
#
# Note
#    o Run every hour to synchronize data across laptop and server 
#
##########################################################################
set -x
PN=${0##*/}			     	    ; export PN     # Program name
VER='1.2'                                   ; export VER    # program version
SERVER="192.168.1.101"                      ; export SERVER
SYSADMIN="duplessis.jacques@gmail.com"      ; export SYSADMIN
SDATE=$(date "+%C%y.%m.%d %H:%M:%S")	    ; export SDATE
LLOG="/tmp/sync_laptop.log"                 : export LLOG

tput clear
echo -e "Program $PN - Version $VER - Starting $SDATE"

# Rsync Data from Laptop to the Linux Server
echo -e "-----------\nrsync -vhar /home/jacques/MyNotes/ ${SERVER}:/mystuff/MyNotes/" > $LLOG 2>&1
rsync -vhar /home/jacques/MyNotes/ ${SERVER}:/mystuff/MyNotes/ >> $LLOG 2>&1
RC1=$?
echo -e "rsync from LAPTOP to $SERVER - Error = $RC1" >> $LLOG

# Rsync Data from Linux Server to the Laptop
echo -e "-----------\nrsync -vhar ${SERVER}:/mystuff/MyNotes/ /home/jacques/MyNotes/" >> $LLOG 2>&1
rsync -vhar ${SERVER}:/mystuff/MyNotes/ /home/jacques/MyNotes/ >> $LLOG 2>&1
RC2=$?
echo -e "rsync from $SERVER to LAPTOP - Error = $RC2\n-----------" >> $LLOG


# Rsync Data from Laptop to the Linux Server
#echo -e "-----------\nrsync -vhar /home/jacques/python/ ${SERVER}:/mystuff/python/" > $LLOG 2>&1
#rsync -vhar /home/jacques/python/ ${SERVER}:/mystuff/python/ >> $LLOG 2>&1
#RC3=$?
RC3=0
#echo -e "rsync from LAPTOP to $SERVER - Error = $RC3" >> $LLOG

# Rsync Data from Linux Server to the Laptop
#echo -e "-----------\nrsync -vhar ${SERVER}:/mystuff/python/ /home/jacques/python/" >> $LLOG 2>&1
#rsync -vhar ${SERVER}:/mystuff/python/ /home/jacques/python/ >> $LLOG 2>&1
#RC4=$?
RC4=0
#echo -e "rsync from $SERVER to LAPTOP - Error = $RC2\n-----------" >> $LLOG


# End of process
# --------------------------------------------------------------------------------------------
RC=`expr $RC1 + $RC2 + $RC3 + $RC4`
EDATE=$(date "+%C%y.%m.%d %H:%M:%S")
echo "End of process - Return Code = $RC - `date`"
if [ "$RC" -eq 0 ]
   then cat $LLOG | mail -s "Success - Notes Rsync $SDATE" $SYSADMIN
   else cat $LLOG | mail -s "MyNotes Rsync Failed $SDATE " $SYSADMIN
fi
exit $RC
