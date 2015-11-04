#!/usr/bin/env sh
# --------------------------------------------------------------------------------------------------
#   Author   :  Jacques Duplessis
#   Title    :
#   Synopsis :
#
#   Version  :  1.0
#   Date     :  10 July 2013
#   Requires :  sh
#   SCCS-Id. :  @(#) template.sh 2.0 2013/07/10
# --------------------------------------------------------------------------------------------------
#
#set -x

# pull in sysconfig settings
#[ -f /etc/sysconfig/sshd ] && . /etc/sysconfig/sshd
#SYSCONFIG="/etc/sysconfig/nmon-script"
#[ -r "$SYSCONFIG" ] && source "$SYSCONFIG

# --------------------------------------------------------------------------------------------------
#                           Script Variables Definitions
# --------------------------------------------------------------------------------------------------
PN=${0##*/}                                     ; export PN             # Current Script name
VER='2.1'                                       ; export VER            # Program version
SYSADMIN="duplessis.jacques@gmail.com"          ; export SYSADMIN       # sysadmin email
DASH=`printf %100s |tr " " "="`                 ; export DASH           # 100 dashes line
INST=`echo "$PN" | awk -F\. '{ print $1 }'`     ; export INST           # Get Current script name
RC=0                                            ; export RC             # Set default Script Return Code
HOSTNAME=`hostname -s`                          ; export HOSTNAME       # Current Host name
OSNAME=`uname -s|tr '[:lower:]' '[:upper:]'`    ; export OSNAME         # Get OS Name (AIX or LINUX)
CUR_DATE=`date +"%Y_%m_%d"`                     ; export CUR_DATE       # Current Date
CUR_TIME=`date +"%H_%M_%S"`                     ; export CUR_TIME       # Current Time
#
BASE_DIR="/sysinfo"                             ; export BASE_DIR       # Script Root Base Directory
BIN_DIR="$BASE_DIR/bin"                         ; export BIN_DIR        # Script Root binary directory
TMP_DIR="$BASE_DIR/tmp"                         ; export TMP_DIR        # Script Temp  directory
TMP_FILE1="${TMP_DIR}/${INST}_1.$$"             ; export TMP_FILE1      # Script Tmp File1 for processing
TMP_FILE2="${TMP_DIR}/${INST}_2.$$"             ; export TMP_FILE2      # Script Tmp File2 for processing
TMP_FILE3="${TMP_DIR}/${INST}_3.$$"             ; export TMP_FILE3      # Script Tmp File3 for processing
LOG_DIR="/var/adsmlog"                          ; export LOG_DIR        # Script log directory
LOG="${LOG_DIR}/${INST}.log"                    ; export LOG            # Script LOG filename
RCLOG="${LOG_DIR}/rc.${HOSTNAME}.${INST}.log"   ; export RCLOG          # Establish Return code filename
GLOBAL_ERROR=0                                  ; export GLOBAL_ERROR   # Global Error Return Code
#
MUSER="query"                                   ; export MUSER          # MySql User
MPASS="query"                                   ; export MPASS          # MySql Password
MHOST="sysinfo.maison.ca"                         ; export MHOST          # Mysql Host
MYSQL="$(which mysql)"                          ; export MYSQL          # Location of mysql program
#
FILENAME="WILL BE ASKED"                        ; export FILENAME       # File name to copy 2 remote


# --------------------------------------------------------------------------------------------------
#                       F U N C T I O N S    D E C L A R A T I O N
# --------------------------------------------------------------------------------------------------

# Write infornation into the log
write_log()
{
    echo -e "`date +"%Y-%b-%m %H:%M"` - $1" >> $LOG
    echo -e "`date +"%Y-%b-%m %H:%M"` - $1"
}


# Convert String Received to Uppercase
toupper()
{
    echo $1 | tr  "[:lower:]" "[:upper:]"
}



# --------------------------------------------------------------------------------------------------
#                        Commands run at the beginning of the script
# --------------------------------------------------------------------------------------------------
init_process()
{

    # If log Directory doesn't exist, create it.
    if [ ! -d "$LOG_DIR" ] ; then mkdir -p $LOG_DIR ; chmod 2775 $LOG_DIR ; export LOG_DIR ; fi

    # If TMP Directory doesn't exist, create it.
    if [ ! -d "$TMP_DIR" ] ; then mkdir -p $TMP_DIR ; chmod 2775 $TMP_DIR ; export TMP_DIR ; fi

    # If log doesn't exist, Create it and Make sure it is writable
    if [ ! -e "$LOG" ]  ; then touch $LOG   ;chmod 664 $LOG   ; export LOG   ;fi

    # If Return Log doesn't exist, Create it and Make sure it have right permission
    if [ ! -e "$RCLOG" ]    ; then touch $RCLOG ;chmod 664 $RCLOG ; export RCLOG ;fi

    # Write Starting Info in the Log
    write_log "${DASH}"
    write_log "Starting $PN $VER - `date`"
    write_log "${DASH}"

    # Update the Return Code File
    start=`date "+%C%y.%m.%d %H:%M:%S"`
    #echo "${HOSTNAME} ${start} ........ ${INST} 2" >>$RCLOG
}


# --------------------------------------------------------------------------------------------------
#                        Commands run at the end of the script
# --------------------------------------------------------------------------------------------------
end_process()
{

    # Maintain Backup RC File log at a reasonnable size.
    RC_MAX_LINES=100
    write_log "Trimming the rc log file $RCLOG to ${RC_MAX_LINES} lines."
    tail -100 $RCLOG > $RCLOG.$$
    rm -f $RCLOG > /dev/null
    mv $RCLOG.$$ $RCLOG
    chmod 666 $RCLOG

    # Making Sure the return code is 1 or 0 only.
    if [ $GLOBAL_ERROR -ne 0 ] ; then GLOBAL_ERROR=1 ; else GLOBAL_ERROR=0 ; fi

    # Update the Return Code File
    end=`date "+%H:%M:%S"`
    #echo "$MYHOST $start $end $INST $GLOBAL_ERROR" >>$RCLOG

    write_log "${PN} ended at ${end}"
    write_log "${DASH}\n\n\n\n"

    # Maintain Script log at a reasonnable size (5000 Records)
    cat $LOG >> $LOG.$$
    tail -5000 $LOG > $LOG.$$
    rm -f $LOG > /dev/null
    mv $LOG.$$ $LOG

    # Inform by Email if error
    if [ $RC -ne 0 ]
      then cat $LOG | mail -s "${PN} FAILED on ${HOSTNAME} at $end" $SYSADMIN
    fi

    # Delete Temproray files used
    if [ -e "$TMP_FILE1" ] ; then rm -f $TMP_FILE1 >/dev/null 2>&1 ; fi
    if [ -e "$TMP_FILE2" ] ; then rm -f $TMP_FILE2 >/dev/null 2>&1 ; fi
    if [ -e "$TMP_FILE3" ] ; then rm -f $TMP_FILE3 >/dev/null 2>&1 ; fi
}




# --------------------------------------------------------------------------------------------------
#                      Process Linux servers selected by the SQL
# --------------------------------------------------------------------------------------------------
process_linux_servers()
{
    if [ "$LINUX_UPDATE" = "N" ]
        then write_log "I Will process NO Linux Servers"
             return 0
    fi

    SQL1="use sysinfo; "
    SQL2="SELECT server_name, server_os, server_domain, server_type FROM servers "
    MSINFO="Will process all Linux "
    case "$LINUX_TYPE" in
        d|D) MSINFO=`echo "$MSINFO Dev. servers " `
             SQL3="where server_doc_only=0 and server_active=1 and server_os='Linux' and server_type='Dev' ;"
             LINUX_TYPE="D"
             break
             ;;
        p|P) MSINFO=`echo "$MSINFO Prod. servers "`
             SQL3="where server_doc_only=0 and server_active=1 and server_os='Linux' and server_type='Prod' ;"
             LINUX_TYPE="P"
             break
             ;;
        b|B) MSINFO=`echo "$MSINFO servers "`
             SQL3="where server_doc_only=0 and server_active=1 and server_os='Linux' ;"
             LINUX_TYPE="B"
             break
             ;;
    esac
    write_log "$MSINFO"
    SQL="${SQL1}${SQL2}${SQL3}"
    $MYSQL -u $MUSER -h $MHOST -p$MPASS -s -e "$SQL" | sort >$TMP_FILE1

    while read wline
        do
        server_name=`  echo $wline|awk '{ print $1 }'`
        server_os=`    echo $wline|awk '{ print $2 }'`
        server_domain=`echo $wline|awk '{ print $3 }'`
        server_type=`  echo $wline|awk '{ print $4 }'`
        write_log "Processing Server : ${server_name}.${server_domain} ${server_os} ${server_type}"
        write_log "scp -q ${FILENAME} ${server_name}.${server_domain}:${FILENAME}"
        scp -q $FILENAME ${server_name}.${server_domain}:$FILENAME
        RC=$?
        if [ $RC -ne 0 ]
            then write_log "***** ERROR ($RC) PUSHING FILE TO ${server_name}.${server_domain}"
                 write_log "***** RETURN CODE IS $RC"
            else write_log "Return Code is $RC"
        fi
        write_log "${DASH}"
        done < $TMP_FILE1


}


# --------------------------------------------------------------------------------------------------
#                      Process Linux servers selected by the SQL
# --------------------------------------------------------------------------------------------------
process_aix_servers()
{
    if [ "$AIX_UPDATE" = "N" ]
        then write_log "I Will process NO Aix Servers"
             return 0
    fi

    SQL1="use sysinfo; "
    SQL2="SELECT server_name, server_os, server_domain, server_type FROM servers "
    MSINFO="Will process all Aix "
    case "$AIX_TYPE" in
        d|D) MSINFO=`echo "$MSINFO Dev. servers " `
             SQL3="where server_doc_only=0 and server_active=1 and server_os='Aix' and server_type='Dev' ;"
             AIX_TYPE="D"
             break
             ;;
        p|P) MSINFO=`echo "$MSINFO Prod. servers "`
             SQL3="where server_doc_only=0 and server_active=1 and server_os='Aix' and server_type='Prod' ;"
             AIX_TYPE="P"
             break
             ;;
        b|B) MSINFO=`echo "$MSINFO servers "`
             SQL3="where server_doc_only=0 and server_active=1 and server_os='Aix' ;"
             AIX_TYPE="B"
             break
             ;;
    esac
    write_log "$MSINFO"
    SQL="${SQL1}${SQL2}${SQL3}"
    $MYSQL -u $MUSER -h $MHOST -p$MPASS -s -e "$SQL" | sort >$TMP_FILE1

    while read wline
        do
        server_name=`  echo $wline|awk '{ print $1 }'`
        server_os=`    echo $wline|awk '{ print $2 }'`
        server_domain=`echo $wline|awk '{ print $3 }'`
        server_type=`  echo $wline|awk '{ print $4 }'`
        write_log "Processing Server : ${server_name}.${server_domain} ${server_os} ${server_type}"
        write_log "rcp ${FILENAME} ${server_name}.${server_domain}:${FILENAME}"
        rcp $FILENAME ${server_name}.${server_domain}:$FILENAME
        RC=$?
        if [ $RC -ne 0 ]
            then write_log "***** ERROR ($RC) PUSHING FILE TO ${server_name}.${server_domain}"
                 write_log "***** RETURN CODE IS $RC"
            else write_log "Return Code is $RC"
        fi
        write_log "${DASH}"
        done < $TMP_FILE1

}


# --------------------------------------------------------------------------------------------------
#                               Ask User what to do
# --------------------------------------------------------------------------------------------------
ask_user()
{

    tput clear


    # What is the file name and path to push to servers
    # ----------------------------------------------------------------------------------------------
    while :
        do
        echo -e "\n==============================================================================="
        echo -en "Specify the filename you want to push to Unix servers or (Q)uit? "
        read FILENAME
        case "$FILENAME" in
           q|Q )        exit 1
                        ;;
           * )          if [ ! -f "$FILENAME" ]
                            then echo "File not found !"
                            else break
                        fi
                        ;;
        esac
    done



    # What to push the file to AIX Servers ?
    # ----------------------------------------------------------------------------------------------
    while :
        do
        echo -e "\n==============================================================================="
        echo -en "Want to Update Aix Servers (Y/N) or (Q)uit? "
        read AIX_UPDATE
        case "$AIX_UPDATE" in
           o|O|Y|y )    AIX_UPDATE="Y"
                        break
                        ;;
           n|N )        AIX_UPDATE="N"
                        break
                        ;;
           q|Q )        exit 1
                        ;;
           * )          echo "Must enter (Y)es or (N)o or (Q)uit !"
                        ;;
        esac
    done


    # What to push the file to AIX Dev or Prod Servers or Both ?
    # ----------------------------------------------------------------------------------------------
    AIX_TYPE="X"
    if [ "$AIX_UPDATE" = "Y" ]
        then while :
                do
                echo -e "\n==============================================================================="
                echo -en "Want to Update Aix (D)ev. or (P)rod. or (B)oth or (Q)uit (D/P/B/Q) ? "
                read AIX_TYPE
                case "$AIX_TYPE" in
                   d|D) AIX_TYPE="D"
                        break
                        ;;
                   p|P) AIX_TYPE="P"
                        break
                        ;;
                   b|B) AIX_TYPE="B"
                        break
                        ;;
                   q|Q) exit 1
                        ;;
                   * )  echo "Must enter D or P or B or Q !"
                        ;;
                esac
                done
    fi



    # What to push the file to Linux Servers ?
    # ----------------------------------------------------------------------------------------------
    while :
        do
        echo -e "\n==============================================================================="
        echo -en "Want to Update Linux Servers (Y/N) ? "
        read LINUX_UPDATE
        case "$LINUX_UPDATE" in
           o|O|Y|y )    LINUX_UPDATE="Y"
                        break
                        ;;
           n|N )        LINUX_UPDATE="N"
                        break
                        ;;
           q|Q )        exit 1
                        ;;
           * )          echo "Must enter (Y)es or (N)o or (Q)uit !"
                        ;;
        esac
    done


    # What to push the file to Linux Dev or Prod Servers or Both ?
    # ----------------------------------------------------------------------------------------------
    LINUX_TYPE="X"
    if [ "$LINUX_UPDATE" = "Y" ]
        then while :
                do
                echo -e "\n==============================================================================="
                echo -en "Want to Update Linux (D)ev. or (P)rod. or (B)oth or (Q)uit (D/P/B/Q) ? "
                read LINUX_TYPE
                case "$LINUX_TYPE" in
                   d|D) LINUX_TYPE="D"
                        break
                        ;;
                   p|P) LINUX_TYPE="P"
                        break
                        ;;
                   b|B) LINUX_TYPE="B"
                        break
                        ;;
                   q|Q) exit 1
                        ;;
                   * )  echo "Must enter D or P or B or Q !"
                        ;;
                esac
                done
    fi

    export AIX_UPDATE AIX_TYPE LINUX_UPDATE LINUX_TYPE FILENAME



    # Final OK before doing the job
    # ----------------------------------------------------------------------------------------------
    while :
        do
        echo -e "\n==============================================================================="
        echo "I will push the file $FILENAME"
        if [ "$AIX_UPDATE" = "N" ]
            then echo "I will not push it to any Aix Servers"
            else MSINFO="I will push it to all Aix"
                 if [ "$AIX_TYPE" = "D" ] ; then MSINFO=`echo "$MSINFO Dev. servers " ` ; fi
                 if [ "$AIX_TYPE" = "P" ] ; then MSINFO=`echo "$MSINFO Prod. servers " ` ; fi
                 if [ "$AIX_TYPE" = "B" ] ; then MSINFO=`echo "$MSINFO servers " ` ; fi
                 echo "$MSINFO"
        fi
        if [ "$LINUX_UPDATE" = "N" ]
            then echo "I will not push it to any Linux Servers"
            else MSINFO="I will push it to all Linux"
                 if [ "$LINUX_TYPE" = "D" ] ; then MSINFO=`echo "$MSINFO Dev. servers " ` ; fi
                 if [ "$LINUX_TYPE" = "P" ] ; then MSINFO=`echo "$MSINFO Prod. servers " ` ; fi
                 if [ "$LINUX_TYPE" = "B" ] ; then MSINFO=`echo "$MSINFO servers " ` ; fi
                 echo "$MSINFO"
        fi
        echo -en "Are you ok with this (Y)es or (N)o ? "
        read FINAL_ANSWER
        case "$FINAL_ANSWER" in
                   y|Y) break
                        ;;
                   n|n) exit 1
                        ;;
                   * )  echo "Must enter Y or N !"
                        ;;
        esac
        done
}




# --------------------------------------------------------------------------------------------------
#                        Script Start HERE
# --------------------------------------------------------------------------------------------------
    init_process
    ask_user
    process_aix_servers
    process_linux_servers
    end_process
    exit $GLOBAL_ERROR
