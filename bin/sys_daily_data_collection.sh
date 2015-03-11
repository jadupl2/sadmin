#! /bin/sh
#############################################################################################
# Title      :  /sysinfo/bin/daily_data_collection.sh
# Description:  Get hardware Info & Performance Datafrom all active servers
# Version    :  1.4
# Author     :  Jacques Duplessis
# Date       :  2010-04-21
# Requires   :  ksh
# SCCS-Id.   :  @(#) daily_data_collection.sh 1.4 21-04/2010
#############################################################################################
# Description
#
#############################################################################################
#set -x
env | sort > /tmp/env.txt 2>&1

# --------------------------------------------------------------------------------------------------
# These variables got to be defined prior to calling the initialize (sadm_init.sh) script                                    Script Variables Definitions
# --------------------------------------------------------------------------------------------------
PN=${0##*/}                                    ; export PN              # Current Script name
VER='2.9'                                      ; export VER             # Program version
DEBUG=0                                        ; export DEBUG           # Debug ON (1) or OFF (0)
INST=`echo "$PN" | awk -F\. '{ print $1 }'`    ; export INST            # Get Current script name
TPID="$$"                                      ; export TPID            # Script PID
GLOBAL_ERROR=0                                 ; export GLOBAL_ERROR    # Global Error Return Code
MAX_LOGLINE=5000                               ; export MAX_LOGLINE     # Max Nb. Of Line in LOG (Trim)
RC_MAX_LINES=100                               ; export RC_MAX_LINES    # Max Nb. Of Line in RCLOG (Trim)

# --------------------------------------------------------------------------------------------------
# Source sadm variables and Load sadm functions
# --------------------------------------------------------------------------------------------------
BASE_DIR=${SADMIN:="/sadmin"}                  ; export BASE_DIR        # Script Root Base Directory
[ -f ${BASE_DIR}/bin/sadm_init.sh ] && . ${BASE_DIR}/bin/sadm_init.sh   # Init Var. & Load sadm functions


# --------------------------------------------------------------------------------------------------
# Script Variables definition
# --------------------------------------------------------------------------------------------------
#
HWDIR="/sysinfo/www/data/hw"	           	   ; export HWDIR           # Hardware Data collected
SYSPERF="/sysinfo/www/rrd/perf"                ; export SYSPERF         # Where to store Perf.Data
REMOTE_NMON_DIR="/var/adsmlog/nmonlog"         ; export REMOTE_NMON_DIR # Remote location of nmon file
NMON_DIR="/sysinfo/www/data/nmon/linux" 	   ; export NMON_DIR	    # Where Linux nmon files are
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
    SQL1="use sysinfo; SELECT server_name, server_domain FROM servers where server_os='AIX' "
    SQL2="and server_active=1 and server_doc_only=0 ;"
    SQL="${SQL1} ${SQL2}"
    $MYSQL -u $MUSER -h $MHOST -p$MPASS -s -e "$SQL" >$TMP_FILE1

    cat $TMP_FILE1 | while read wline
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
        write_log "rcp $server:/sysadmin/sysinfo/hw/* /sysinfo/www/data/hw"
        rcp $server:/sysadmin/sysinfo/hw/*  /sysinfo/www/data/hw >>$LOG 2>&1
        RC=$?
        if [ $RC -ne 0 ]
            then write_log "ERROR NUMBER $RC for $server"
                 ERROR_COUNT=$(($ERROR_COUNT+1))
            else write_log "RETURN CODE IS 0 - OK"
        fi
        write_log "Total Aix Error Count is at $ERROR_COUNT"

        # Transfer OS Information - Custom report
        write_log " " ;  write_log "${DASH2}"
        write_log "rcp $server:/sysadmin/sysinfo/log/${server}.log /sysinfo/www/data/cfg"
        if [ "$server" = "sxmq1222a" ]
           then rcp $server:/sysadmin/sysinfo/log/sxmq1222*.log /sysinfo/www/data/cfg >>$LOG 2>&1
           else rcp $server:/sysadmin/sysinfo/log/${server}.log /sysinfo/www/data/cfg >>$LOG 2>&1
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
    write_log "rcp $server:/sysadmin/sysinfo/log/${server}*.html /sysinfo/www/data/cfg"
    if [ "$server" = "sxmq1222a" ]
        then rcp $server:/sysadmin/sysinfo/log/sxmq1222*.html /sysinfo/www/data/cfg >>$LOG 2>&1
        else rcp $server:/sysadmin/sysinfo/log/${server}*.html /sysinfo/www/data/cfg >>$LOG 2>&1
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
    if [ ! -d  /sysinfo/www/data/nmon/aix/${server} ]
       then write_log "Directory  /sysinfo/www/data/nmon/aix/${server} was not found, it is now created"
            mkdir -p  /sysinfo/www/data/nmon/aix/${server}
            chmod 775  /sysinfo/www/data/nmon/aix/${server}
    fi
    WYESTERDAY=`date --date="1 day ago" +"%y%m%d"`
    NMON_FILENAME="${server}_${WYESTERDAY}_*.nmon"
    write_log "rcp $server:${REMOTE_NMON_DIR}/${NMON_FILENAME} /sysinfo/www/data/nmon/aix/${server}"
    if [ "$server" = "sxmq1222a" ]
        then rcp $server:${REMOTE_NMON_DIR}/sxmq1222_${WYESTERDAY}*.nmon /sysinfo/www/data/nmon/aix/${server} >>$LOG 2>&1
        else rcp $server:${REMOTE_NMON_DIR}/${NMON_FILENAME} /sysinfo/www/data/nmon/aix/${server} >>$LOG 2>&1
    fi
    RC=$?
    if [ $RC -ne 0 ]
       then write_log "ERROR NUMBER $RC for $server"
            ERROR_COUNT=$(($ERROR_COUNT+1))
       else write_log "RETURN CODE IS 0 - OK"
    fi
    write_log "Total Aix Error Count is at $ERROR_COUNT"
    done

    write_log "Final Total AIX Error Count is at $ERROR_COUNT"
    return $ERROR_COUNT

}



# --------------------------------------------------------------------------------------------------
#                      Produce a List of all actives Linux Servers
# --------------------------------------------------------------------------------------------------
#
get_linux_files()
{
    SQL1="use sysinfo; SELECT server_name, server_domain FROM servers where server_os='Linux' "
    SQL2="and server_active=1 and server_doc_only=0 ;"
    SQL="${SQL1} ${SQL2}"
    $MYSQL -u $MUSER -h $MHOST -p$MPASS -s -e "$SQL" >$TMP_FILE1

    cat $TMP_FILE1 | while read wline
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
                 continue
            else write_log "RETURN CODE IS 0 - OK"
        fi
        write_log "Total Linux Error Count is at $ERROR_COUNT"

    # Transfer Hardware Info - Detailed
    write_log " " ;  write_log "${DASH2}"
    write_log "rsync -v -e 'ssh -qp32' $server:/sysadmin/sysinfo/hw/* /sysinfo/www/data/hw"
    rsync -v -e 'ssh -qp32' $server:/sysadmin/sysinfo/hw/* /sysinfo/www/data/hw >>$LOG 2>&1
    RC=$?
    if [ $RC -ne 0 ]
       then write_log "ERROR NUMBER $RC for $server"
            ERROR_COUNT=$(($ERROR_COUNT+1))
       else write_log "RETURN CODE IS 0 - OK"
    fi
    write_log "Total Linux Error Count is at $ERROR_COUNT"


    # Transfer OS Information - Custom report
    write_log " " ;  write_log "${DASH2}"
    write_log "rsync -v -e 'ssh -qp32' $server:/sysadmin/sysinfo/log/${server}.log /sysinfo/www/data/cfg"
    rsync -v -e 'ssh -qp32' $server:/sysadmin/sysinfo/log/${server}.log /sysinfo/www/data/cfg >>$LOG 2>&1
    RC=$?
    if [ $RC -ne 0 ]
       then write_log "ERROR NUMBER $RC for $server"
            ERROR_COUNT=$(($ERROR_COUNT+1))
       else write_log "RETURN CODE IS 0 - OK"
    fi
    write_log "Total Linux Error Count is at $ERROR_COUNT"


    # Transfer OS Information - Detailled report
    write_log " " ;  write_log "${DASH2}"
    write_log "rsync -v -e 'ssh -qp32' $server:/sysadmin/sysinfo/log/${server}*.html /sysinfo/www/data/cfg"
    rsync -v -e 'ssh -qp32' $server:/sysadmin/sysinfo/log/${server}*.html /sysinfo/www/data/cfg >>$LOG 2>&1
    RC=$?
    if [ $RC -ne 0 ]
       then write_log "ERROR NUMBER $RC for $server"
            ERROR_COUNT=$(($ERROR_COUNT+1))
       else write_log "RETURN CODE IS 0 - OK"
    fi
    write_log "Total Linux Error Count is at $ERROR_COUNT"


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
            rsync -v -e 'ssh -qp32' $server:$PERFDATA_FILE $SYSPERF/${server} >>$LOG 2>&1
            RC=$?
            if [ $RC -ne 0 ]
               then write_log "Performance Data - ERROR $RC for $server"
                    ERROR_COUNT=$(($ERROR_COUNT+1))
               else write_log "RETURN CODE IS 0 - OK"
            fi
            write_log "Total Linux Error Count is at $ERROR_COUNT"
	fi

    # Transfer Nmon file----------------------------------------------------------------------------
    write_log " " ;  write_log "${DASH2}"
    if [ ! -d  /sysinfo/www/data/nmon/linux/${server} ]
       then write_log "Directory  /sysinfo/www/data/nmon/linux/${server} was not found, it is now created"
            mkdir -p  /sysinfo/www/data/nmon/linux/${server}
            chmod 775  /sysinfo/www/data/nmon/linux/${server}
    fi
    WYESTERDAY=`date --date="1 day ago" +"%y%m%d"`
    NMON_FILENAME="${server}_${WYESTERDAY}_*.nmon"
    write_log "rsync -v -e 'ssh -qp32' $server:${REMOTE_NMON_DIR}/${NMON_FILENAME} /sysinfo/www/data/nmon/linux/${server}"
    rsync -v -e 'ssh -qp32' $server:${REMOTE_NMON_DIR}/${NMON_FILENAME} /sysinfo/www/data/nmon/linux/${server} >>$LOG 2>&1
    RC=$?
    if [ $RC -ne 0 ]
       then write_log "ERROR NUMBER $RC for $server"
            ERROR_COUNT=$(($ERROR_COUNT+1))
       else write_log "RETURN CODE IS 0 - OK"
    fi
    write_log "Total Linux Error Count is at $ERROR_COUNT"

    done

    write_log "Final Total Linux Error Count is at $ERROR_COUNT"
    return $ERROR_COUNT

}


# --------------------------------------------------------------------------------------------------
#                           S T A R T   O F   M A I N    P R O G R A M
# --------------------------------------------------------------------------------------------------
#
    sadm_start                                                          # Make sure Dir. Struc. exist
    rm -f $HWDIR/*.Z > /dev/null 2>&1                                   # Del prv *.Z before getting new files

    get_aix_files                                                       # Collect Files from AIX Servers
    GLOBAL_ERROR=$?                                                     # Set Nb. Errors while collecting
    get_linux_files                                                     # Collect Files from Linux Servers
    NB_ERROR=$?                                                         # Set Nb. Errors while collecting
    GLOBAL_ERROR=$(($GLOBAL_ERROR+$NB_ERROR))                           # Set Total AIX+Linux Errors

    write_log " " ; write_log " " ;  write_log "${DASH}";               # Insert Blank lines in log
    write_log "COPY NMON FILES TO ARCHIVE DIRECTORY"                    # Advise user - End of Processing
    write_log "${DASH}"                                                 # Advise user that we are finish
    if [ -d "$NMON_DIR" ]
    	then cd $NMON_DIR
    	     pwd >> $LOG
	    	 write_log "cp -var . /sysinfo/www/data/nmon/archive/linux"
		     cp -var . /sysinfo/www/data/nmon/archive/linux >> $LOG 2>&1

 		     # Now that we have a copy in Archive - Delete the originals
    	     write_log " " ; write_log "${DASH2}"
    		 write_log "Delete all Linux nmon files in $NMON_DIR"
    		 find . -name "*.nmon"  -exec rm -f {} \;  >> $LOG 2>&1
    fi

    write_log " " ; write_log " " ;                                     # Insert Blank lines in log
    write_log "${DASH}"; write_log "END OF PROCESSING"                  # Advise user - End of Processing
    write_log "${DASH}"                                                 # Advise user that we are finish
    write_log "Final Error Count is at $GLOBAL_ERROR"                   # Advise nb. total errors.
    if [ $GLOBAL_ERROR -gt 0 ]                                          # If at least one error
        then RC=1                                                       # Then Set exit code to 1
		     write_log "Error Count is at $GLOBAL_ERROR then RC = $RC"  # Advise user that RC set to 1
        else RC=0                                                       # If no error set Exit code to 0
    fi
    sadm_stop $GLOBAL_ERROR                                             # End Process with exit Code
    exit $rc                                                            # Exit script