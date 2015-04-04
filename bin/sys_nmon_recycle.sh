#!/usr/bin/env sh
# --------------------------------------------------------------------------------------------------
#   Author   : Jacques Duplessis
#   Synopsis :  1) Restart nmon daemon at midnight every day, so that it finish at 23:55
#               2) Clean up of old nmon files
#   Version  :  1.0
#   Date     :  August 2013
#   Requires :  sh
#   SCCS-Id. :  @(#) sys_nmon_recycle.sh 1.0 2013/08/02
# --------------------------------------------------------------------------------------------------
# Modified in March 2015 - Add clean up Process - Jacques Duplessis
# --------------------------------------------------------------------------------------------------
#set +x
#
OSNAME=`uname -s|tr '[:lower:]' '[:upper:]'`    ; export OSNAME         # Get OS Name (AIX or LINUX)
if [ "$OSNAME" = "AIX" ]
   then NMON_PGM="/usr/bin/nmon" ; export NMON_PGM
   else NMON_PGM="/usr/bin/nmon" ; export NMON_PGM
fi

# Display Currently Running number of nmon process
# --------------------------------------------------------------------------------------------------
date
nmon_count=`ps -ef | grep -v grep | grep "$NMON_PGM" | wc -l`
echo "The number of nmon process running before killing it is $nmon_count"
ps -ef | grep -v grep | grep "$NMON_PGM" | nl


# If nmon is running, kill it - Before Restarting it.
# --------------------------------------------------------------------------------------------------
if [ $nmon_count -gt 0 ]
   then ps -ef | grep -v grep | grep "$NMON_PGM" | awk '{ print $2 }' |xargs kill -9
fi


# Start the nmon Process
# --------------------------------------------------------------------------------------------------
$NMON_PGM -s300 -c288 -t -m /var/adsmlog/nmonlog -f > /dev/null 2>&1


# Display info after starting nmon
# --------------------------------------------------------------------------------------------------
nmon_count=`ps -ef | grep -v grep | grep "$NMON_PGM" | wc -l`
echo "The number of nmon process running after restarting it is $nmon_count"
ps -ef | grep -v grep | grep "$NMON_PGM" | nl
#
find /var/adsmlog/nmonlog -mtime +60 -type f -name "*.nmon" -exec rm {} \; >/dev/null 2>&1