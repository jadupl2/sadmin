#! /bin/sh
#############################################################################################
# Title      :  sys_daily_data_collection.sh
# Description:  Get hardware Info & Performance Datafrom all active servers
# Version    :  2.4
# Author     :  Jacques Duplessis
# Date       :  2010-04-21
# Requires   :  ksh
# SCCS-Id.   :  @(#) sys_daily_data_collection.sh 1.4 21-04/2010
#############################################################################################
# Description
# 2015 - Restructure and redesign for modularity - Jacques Duplessus
#############################################################################################
#set -x

# --------------------------------------------------------------------------------------------------
# These variables got to be defined prior to calling the initialize (sadm_init.sh) script
# These variables are use and needed by the sadm_init.sh script.
# --------------------------------------------------------------------------------------------------
PN=${0##*/}                                    ; export PN              # Current Script name
VER='2.9'                                      ; export VER             # Program version
OUTPUT2=1                                      ; export OUTPUT2         # Output 0=log 1=Screen+Log
INST=`echo "$PN" | awk -F\. '{ print $1 }'`    ; export INST            # Get Current script name
TPID="$$"                                      ; export TPID            # Script PID
GLOBAL_ERROR=0                                 ; export GLOBAL_ERROR    # Global Error Return Code
MAX_LOGLINE=5000                               ; export MAX_LOGLINE     # Max Nb. Of Line in LOG (Trim)
MAX_RCLINE=100                                 ; export MAX_RCLINE      # Max Nb. Of Line in RCLOG (Trim)

# --------------------------------------------------------------------------------------------------
# Source sadm variables and Load sadm functions
# --------------------------------------------------------------------------------------------------
BASE_DIR=${SADMIN:="/sadmin"}                  ; export BASE_DIR        # Script Root Base Directory
[ -x ${BASE_DIR}/lib/sadm_init.sh ] && . ${BASE_DIR}/lib/sadm_init.sh   # Init Var. & Load sadm functions


# --------------------------------------------------------------------------------------------------
# Script Variables definition
# --------------------------------------------------------------------------------------------------
#
DAT_DIR="/sysinfo/www/data"	           	       ; export DAT_DIR         # Base Data Directory in sysinfo
HW_DIR="$DAT_DIR/hw"	                	   ; export HW_DIR          # Hardware Data collected
NMON_DIR="$DAT_DIR/nmon" 	                   ; export NMON_DIR	    # Where Linux nmon files are
NMON_ARC="$NMON_DIR/archive" 	               ; export NMON_ARC	    # Where Linux nmon Archive are
SYSPERF="/sysinfo/www/rrd/perf"                ; export SYSPERF         # Where to store Perf.Data
NMON_REM_DIR="/var/adsmlog/nmonlog"            ; export NMON_REM_DIR    # Remote location of nmon file

#
MUSER="query"                                  ; export MUSER           # MySql User
MPASS="query"                                  ; export MPASS           # MySql Password
MHOST="sysinfo.maison.ca"                      ; export MHOST           # Mysql Host
MYSQL="$(which mysql)"                         ; export MYSQL           # Location of mysql program
DASH2=`printf %60s |tr " " "-"`                ; export DASH2           # 60 dashes line
DATE=`date +%y%m%d --date="yesterday"`         ; export DATE            # Yesterday Date
PERFDATA_DIR=/etc/perf                         ; export PERFDATA_DIR    # Remote dir. of Perf.Data
PERFDATA_FILE_PREFIX=perfdata                  ; export PERFDATA_FILE_PREFIX   # File Prefix for Perf.File
PERFDATA_FILE=$PERFDATA_DIR/$PERFDATA_FILE_PREFIX.${DATE} ;export PERFDATA_FILE # Perf FileName on remote
ERROR_COUNT=0                                  ; export ERROR_COUNT     # Global Error Counter
TOTAL_AIX=0                                    ; export TOTAL_AIX       # Nb Error in Aix Function
TOTAL_LINUX=0                                  ; export TOTAL_LINUX     # Nb Error in Linux Function


# --------------------------------------------------------------------------------------------------
#                           Produce a List of all actives AIX Servers
# --------------------------------------------------------------------------------------------------
#
get_aix_files()
{
    write_log " "
    write_log "Starting to process AIX Servers ..."
    SQL1="use sysinfo; SELECT server_name, server_domain FROM servers where server_os='AIX' "
    SQL2="and server_active=1 and server_doc_only=0 ;"
    SQL="${SQL1} ${SQL2}"
    $MYSQL -u $MUSER -h $MHOST -p$MPASS -s -e "$SQL" >$TMP_FILE1

#    cat $TMP_FILE1 | while read wline
    while read wline
        do
        server=`echo $wline|awk '{ print $1 }'`
        domain=`echo $wline|awk '{ print $2 }'`

        # Test pinging the server - if doesn t work then skip server & Log error
        write_log " " ; write_log " "
        write_log "${DASH}"
        write_log "PROCESSING AIX SERVER : ${server}.${domain}"
        write_log "${DASH}"
        write_log "ping -c 2 ${server}.${domain}"
        ping -c 2 ${server}.${domain} >/dev/null 2>/dev/null
        RC=$?
        if [ $RC -ne 0 ]
            then write_log "Could not ping server ${server}.${domain} ..."
                 write_log "Will not be able to get the files from ${server}"
                 ERROR_COUNT=$(($ERROR_COUNT+1))
                 continue
            else write_log "RETURN CODE IS 0 - OK"
        fi
        write_log "Total Aix Error Count is at $ERROR_COUNT"

        write_log " " ;  write_log "${DASH2}"
        write_log "rcp $server:/sysadmin/sysinfo/hw/* $HW_DIR"
        rcp $server:/sysadmin/sysinfo/hw/*  $HW_DIR >>$LOG 2>&1
        RC=$?
        if [ $RC -ne 0 ]
            then write_log "ERROR NUMBER $RC for $server"
                 ERROR_COUNT=$(($ERROR_COUNT+1))
            else write_log "RETURN CODE IS 0 - OK"
        fi
        write_log "Total Aix Error Count is at $ERROR_COUNT"

        # Transfer OS Information - Custom report
        write_log " " ;  write_log "${DASH2}"
        write_log "rcp $server:/sysadmin/sysinfo/log/${server}.log $DAT_DIR/cfg"
        if [ "$server" = "sxmq1222a" ]
           then rcp $server:/sysadmin/sysinfo/log/sxmq1222*.log $DAT_DIR/cfg >>$LOG 2>&1
           else rcp $server:/sysadmin/sysinfo/log/${server}.log $DAT_DIR/cfg >>$LOG 2>&1
        fi
        RC=$?
        if [ $RC -ne 0 ]
            then write_log "ERROR NUMBER $RC for $server"
                 ERROR_COUNT=$(($ERROR_COUNT+1))
            else write_log "RETURN CODE IS 0 - OK"
        fi
    write_log "Total Aix Error Count is at $ERROR_COUNT"


    # Transfer OS Information - Detailled report
    write_log " " ;  write_log "${DASH2}"
    write_log "rcp $server:/sysadmin/sysinfo/log/${server}*.html $DAT_DIR/cfg"
    if [ "$server" = "sxmq1222a" ]
        then rcp $server:/sysadmin/sysinfo/log/sxmq1222*.html $DAT_DIR/cfg >>$LOG 2>&1
        else rcp $server:/sysadmin/sysinfo/log/${server}*.html $DAT_DIR/cfg >>$LOG 2>&1
    fi
    RC=$?
    if [ $RC -ne 0 ]
       then write_log "ERROR NUMBER $RC for $server"
            ERROR_COUNT=$(($ERROR_COUNT+1))
       else write_log "RETURN CODE IS 0 - OK"
    fi
    write_log "Total Aix Error Count is at $ERROR_COUNT"



    # Transfer Nmon file----------------------------------------------------------------------------
    write_log " " ;  write_log "${DASH2}"
    if [ ! -d  $NMON_DIR/aix/${server} ]
       then write_log "Directory  $NMON_DIR/aix/${server} was not found, it is now created"
            mkdir -p   $NMON_DIR/aix/${server}
            chmod 775  $NMON_DIR/aix/${server}
    fi
    WYESTERDAY=`date --date="1 day ago" +"%y%m%d"`
    NMON_FILENAME="${server}_${WYESTERDAY}_*.nmon"
    write_log "rcp $server:${NMON_REM_DIR}/${NMON_FILENAME} $NMON_DIR/aix/${server}"
    if [ "$server" = "sxmq1222a" ]
        then rcp $server:${NMON_REM_DIR}/sxmq1222_${WYESTERDAY}*.nmon $NMON_DIR/aix/${server} >>$LOG 2>&1
        else rcp $server:${NMON_REM_DIR}/${NMON_FILENAME} $NMON_DIR/aix/${server} >>$LOG 2>&1
    fi
    RC=$?
    if [ $RC -ne 0 ]
       then write_log "ERROR NUMBER $RC for $server"
            ERROR_COUNT=$(($ERROR_COUNT+1))
       else write_log "RETURN CODE IS 0 - OK"
    fi
    write_log "Total Aix Error Count is at $ERROR_COUNT"
    done < $TMP_FILE1

    write_log " "
    write_log "Total number of AIX Error(s) detected is $ERROR_COUNT"
    return $ERROR_COUNT

}



# --------------------------------------------------------------------------------------------------
#                      Produce a List of all actives Linux Servers
# --------------------------------------------------------------------------------------------------
#
get_linux_files()
{
    write_log " "
    write_log "Starting to process Linux Servers ..."
    SQL1="use sysinfo; SELECT server_name, server_domain FROM servers where server_os='Linux' "
    SQL2="and server_active=1 and server_doc_only=0 ;"
    SQL="${SQL1} ${SQL2}"
    $MYSQL -u $MUSER -h $MHOST -p$MPASS -s -e "$SQL" >$TMP_FILE1

#    cat $TMP_FILE1 | while read wline
    while read wline
        do
        server=`echo $wline|awk '{ print $1 }'`
        domain=`echo $wline|awk '{ print $2 }'`

        # Test pinging the server - if doesn t work then skip server & Log error
        write_log " " ; write_log " "
        write_log "${DASH}"
        write_log "PROCESSING LINUX SERVER : ${server}.${domain}"
        write_log "${DASH}"
        write_log "ping -c 2 ${server}.${domain}"
        ping -c 2 ${server}.${domain} >/dev/null 2>/dev/null
        RC=$?
        if [ $RC -ne 0 ]
            then write_log "Could not ping server ${server} ..."
                 write_log "Will not be able to get the files from ${server}"
                 ERROR_COUNT=$(($ERROR_COUNT+1))
                 write_log "Total Linux Error Count is now at $ERROR_COUNT"
                 continue
            else write_log "RETURN CODE IS 0 - OK"
        fi
        write_log "Total Linux Error Count is now at $ERROR_COUNT"

    # Transfer Hardware Info - Detailed
    write_log " " ;  write_log "${DASH2}"
    write_log "rsync -v -e 'ssh -qp32' $server:/sysadmin/sysinfo/hw/* $DAT_DIR/hw"
    rsync -v -e 'ssh -qp32' $server:/sysadmin/sysinfo/hw/* $DAT_DIR/hw >>/dev/null 2>&1
    RC=$?
    if [ $RC -ne 0 ]
       then write_log "ERROR NUMBER $RC for $server"
            ERROR_COUNT=$(($ERROR_COUNT+1))
       else write_log "RETURN CODE IS 0 - OK"
    fi
    write_log "Total Linux Error Count is now at $ERROR_COUNT"


    # Transfer OS Information - Custom report
    write_log " " ;  write_log "${DASH2}"
    write_log "rsync -v -e 'ssh -qp32' $server:/sysadmin/sysinfo/log/${server}.log $DAT_DIR/cfg"
    rsync -v -e 'ssh -qp32' $server:/sysadmin/sysinfo/log/${server}.log $DAT_DIR/cfg >>/dev/null 2>&1
    RC=$?
    if [ $RC -ne 0 ]
       then write_log "ERROR NUMBER $RC for $server"
            ERROR_COUNT=$(($ERROR_COUNT+1))
       else write_log "RETURN CODE IS 0 - OK"
    fi
    write_log "Total Linux Error Count is now at $ERROR_COUNT"


    # Transfer OS Information - Detailled report
    write_log " " ;  write_log "${DASH2}"
    write_log "rsync -v -e 'ssh -qp32' $server:/sysadmin/sysinfo/log/${server}*.html $DAT_DIR/cfg"
    rsync -v -e 'ssh -qp32' $server:/sysadmin/sysinfo/log/${server}*.html $DAT_DIR/cfg >>/dev/null 2>&1
    RC=$?
    if [ $RC -ne 0 ]
       then write_log "ERROR NUMBER $RC for $server"
            ERROR_COUNT=$(($ERROR_COUNT+1))
       else write_log "RETURN CODE IS 0 - OK"
    fi
    write_log "Total Linux Error Count is now at $ERROR_COUNT"


    # Transfer Performance Data
    write_log " " ;  write_log "${DASH2}"
    if [ ! -d ${SYSPERF}/${server} ]
       then write_log "\nDirectory ${SYSPERF}/${server} was not found, it is now created"
            mkdir -p ${SYSPERF}/${server}
            chmod 775 ${SYSPERF}/${server}
    fi
    backup_vm=`echo ${server} | cut -c1-2`
	if [ "$backup_vm" != "lb" ]
	   then write_log "rsync -v -e 'ssh -qp32' $server:$PERFDATA_FILE $SYSPERF/${server}"
            rsync -v -e 'ssh -qp32' $server:$PERFDATA_FILE $SYSPERF/${server} >>/dev/null 2>&1
            RC=$?
            if [ $RC -ne 0 ]
               then write_log "Performance Data - ERROR $RC for $server"
                    ERROR_COUNT=$(($ERROR_COUNT+1))
               else write_log "RETURN CODE IS 0 - OK"
            fi
            write_log "Total Linux Error Count is now at $ERROR_COUNT"
	fi

    # Transfer Nmon file----------------------------------------------------------------------------
    write_log " " ;  write_log "${DASH2}"
    if [ ! -d  $NMON_ARC/linux/${server} ]
       then write_log "Directory  $NMON_ARC/linux/${server} was not found, it is now created"
            mkdir -p   $NMON_ARC/linux/${server}
            chmod 775  $NMON_ARC/linux/${server}
    fi
    WYESTERDAY=`date --date="1 day ago" +"%y%m%d"`
    NMON_FILENAME="${server}_${WYESTERDAY}_*.nmon"
    write_log "rsync -v -e 'ssh -qp32' $server:${NMON_REM_DIR}/${NMON_FILENAME} $NMON_ARC/linux/${server}"
    rsync -v -e 'ssh -qp32' $server:${NMON_REM_DIR}/${NMON_FILENAME} $NMON_ARC/linux/${server} >>/dev/null 2>&1
    RC=$?
    if [ $RC -ne 0 ]
       then write_log "ERROR NUMBER $RC for $server"
            ERROR_COUNT=$(($ERROR_COUNT+1))
       else write_log "RETURN CODE IS 0 - OK"
    fi
    write_log "Total Linux Error Count is now at $ERROR_COUNT"
    done < $TMP_FILE1

    write_log " "
    write_log "Total number of LINUX Error(s) detected is $ERROR_COUNT"
    return $ERROR_COUNT

}


# --------------------------------------------------------------------------------------------------
#                           S T A R T   O F   M A I N    P R O G R A M
# --------------------------------------------------------------------------------------------------
#
    sadm_start                                                          # Make sure Dir. Struc. exist

    get_aix_files                                                       # Collect Files from AIX Servers
    AIX_ERROR=$?                                                        # AIX Nb. Errors while collecting

    get_linux_files                                                     # Collect Files from Linux Servers
    LINUX_ERROR=$?                                                      # Set Nb. Errors while collecting

    GLOBAL_ERROR=$(($AIX_ERROR+$LINUX_ERROR))                           # Set Total AIX+Linux Errors
    write_log " " ; write_log " " ;                                     # Insert Blank lines in log
    write_log "${DASH}"; write_log "END OF PROCESSING"                  # Advise user - End of Processing
    write_log "${DASH}"                                                 # Advise user that we are finish
    write_log "Final Global Error count is at $GLOBAL_ERROR"            # Advise nb. total errors.

    sadm_stop $GLOBAL_ERROR                                             # End Process with exit Code
    RC=$?                                                               # Recuperate a 0 or a 1
    write_log "The exist code is set to $RC"                            # Advise user that RC set to 1
    exit $RC                                                            # Exit script
