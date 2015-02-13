#! /bin/bash
##########################################################################
# Shellscript:  drrestore.sh - Restore filesystem template script
# Version    :  1.3
# Author     :  jacques duplessis (jack.duplessis@standardlife.ca)
# Date       :  2009-03-12
# Requires   :  bash shell
# Category   :  disaster tools
# SCCS-Id.   :  @(#) drrestore.sh 1.3 12.03.2009
##########################################################################
# Description
#
# Note
#    o This script is used to restore filesystem in case of dr
#    o It will restore all filesystem that were present on the system
#    o This script is generated every day by the $SAM/drsavevg.sh script 
#
##########################################################################
#set -x
PN=${0##*/}                     ; export PN     # Program name
VER='1.3'                       ; export VER    # program version

# Environment variables
SAM="/sysadmin/sam"             ; export SYSADM # where reside pgm & data
WLOG="/tmp/drrestore_$$.log"    ; export WLOG   # Output file of program
SCRIPT="$SAM/dr_restfs.sh"      ; export SCRIPT

# GLOBAL commands
DSMC="dsmc"                     ; export DSMC     # dsmc location
DSMC_CMD="$DSMC restore -replace=all -subdir=yes -ifnewer " # dsmc restore cmd


# Test to verify if connection to TSM is working
##########################################################################
echo "Do a tail -f $WLOG to se progress of restore"
echo -e "Program $PN - Version $VER - Starting `date`" > $WLOG
echo "Testing TSM Server connection" >> $WLOG
$DSMC q sched >$WLOG 2>&1
RC=$?
if [ $RC -ne 0 ]
   then echo "Error : $RC - dsmc command failed !"  >>$WLOG
        echo "        Process aborted !"      >>$WLOG
        exit 1
fi
echo -e "\n=============================================\n" >>$WLOG


# Restore each filesystem - One by One
# Check for error during restore = grep -i "error:" in /tmp/drrestore.log
##########################################################################
