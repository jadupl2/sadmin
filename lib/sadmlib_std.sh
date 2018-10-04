#!/usr/bin/env sh
#===================================================================================================
#  Author:    Jacques Duplessis
#  Title      sadmlib_std.sh
#  Date:      August 2015
#  Synopsis:  SADMIN  Shell Script Main Library
#  
# --------------------------------------------------------------------------------------------------
# Description
# This file is not a stand-alone shell script; it provides functions to your scripts that source it.
# --------------------------------------------------------------------------------------------------
# CHANGE LOG
# 2016_11_05  V2.0 Create log file earlier to prevent error message
# 2016_04_17  V2.1 Added Support for Linux Mint
# 2016_04_19  V2.2 Minor Modifications concerning Trimming the Log File
# 2017_07_03  V2.3 Cosmetic change (Use only 50 Dash line at start & end of script)
# 2017_07_17  V2.4 Split Second line of log header into two lines/ Change Timming Line
# 2017_08_12  V2.5 Print FQDN instead of hostname and SADM Lib Ver. in header of the log
# 2017_08_27  V2.6 If Log not in Append Mode, then no need to Trim - Change Log footer message accordingly
# 2017_09_23  V2.7 Add SQLite3 Dir & Name Plus Correct Typo Error in sadm_stop when testing for log trimming or not 
# 2017_09_29  V2.8 Correct chown on ${SADMIN}/dat/net and Test creation and chown on www directories
# 2017_12_18  V2.9 Function were changed to run on MacOS and Some Restructuration was done
# 2017_12_23  V2.10 SSH Command line construction added at the end of script
# 2017_12_30  V2.11 Combine sadmlib_server into sadmlib_std , so onle library from then on.
# 2018_01_03  V2.12 Added Check for facter command , if present use it get get hardware info
# 2018_01_05  V2.13 Remove Warning when command can't be found for compatibility
# 2018_01_23  V2.14 Add arc directory in $SADMIN/www for archiving purpose
# 2018_01_25  V2.15 Add SADM_RRDTOOL to sadmin.cfg for php page using it
# 2018_02_07  V2.16 Bug Fix when determining if server is a virtual or physical
# 2018_02_08  V2.17 Correct 'if' statement compatibility problem with 'dash' shell
# 2018_02_14  V2.18 Add Documentation Directory
# 2018_02_22  V2.19 Add SADM_HOST_TYPE field in sadmin.cfg
# 2018_05_03  V2.20 Password for Database Standard User (sadmin and squery) now read from .dbpass file
# 2018_05_06  V2.21 Change name of crontab file in etc/cron.d to sadm_server_osupdate
# 2018_05_14  V2.22 Add Options not to use or not the RC File, to show or not the Log Header and Footer
# 2018_05_23  V2.23 Remove some variables and logic modifications
# 2018_05_26  V2.24 Added Variables SADM_RPT_FILE and SADM_USERNAME for users
# 2018_05_27  V2.25 Get Read/Write & Read/Only User Database Password, only if on SADMIN Server.
# 2018_05_28  V2.26 Added Loading of backup parameters coming from sadmin.cfg
# 2018_06_04  V2.27 Add dat/dbb,usr/bin,usr/doc,usr/lib,usr/mon,setup and www/tmp/perf creation.
# 2018_06_10  V2.28 SADM_CRONTAB file change name (/etc/cron.d/sadm_osupdate)
# 2018_06_14  V2.29 Added test to make sure that /etc/environment contains "SADMIN=${SADMIN}" line
# 2018_07_07  V2.30 Move .sadm_osupdate crontab work file to $SADMIN/cfg
# 2018_07_16  V2.31 Fix sadm_stop function crash, when no parameter (exit Code) is recv., assume 1
# 2018_07_24  v2.32 Show Kernel version instead of O/S Codename in log header
# 2018_08_16  v2.33 Remove Change Owner & Protection Error Message while not running with root.
# 2018_09_04  v2.34 Load SlackHook and Smon Alert Type from sadmin.cfg, so avail. to all scripts.
# 2018_09_07  v2.35 Alerting System now support using Slack (slack.com).
# 2018_09_16  v2.36 Alert Group added to ReturnCodeHistory file to alert script owner if not default
# 2018_09_18  v2.37 Alert mechanism Update, Enhance Performance, fixes
# 2018_09_20  v2.38 Fix Alerting problem with Slack, Change chown bug and Set default alert group to 'default'
# 2018_09_22  v2.39 Change Alert Message Format
# 2018_09_23  v2.40 Added alert_sysadmin function
# 2018_09_25  v2.41 Enhance Email Standard Alert Message
# 2018_09_26  v2.42 Send Alert Include Message Subject now
# 2018_09_27  v2.43 Now Script log can be sent to Slack Alert
# 2018_09_30  v2.44 Some Alert Message was too long (Corrupting history file), have shorthen them.
#@2018_10_04  v2.45 Error reported by scripts, issue multiple alert within same day (now once a day)
#===================================================================================================
trap 'exit 0' 2                                                         # Intercepte The ^C    
#set -x

# --------------------------------------------------------------------------------------------------
#                             V A R I A B L E S      D E F I N I T I O N S
# --------------------------------------------------------------------------------------------------
#
SADM_HOSTNAME=`hostname -s`                 ; export SADM_HOSTNAME      # Current Host name
SADM_DASH=`printf %80s |tr " " "="`         ; export SADM_DASH          # 80 equals sign line
SADM_FIFTY_DASH=`printf %50s |tr " " "="`   ; export SADM_FIFTY_DASH    # 50 equals sign line
SADM_80_DASH=`printf %80s |tr " " "="`      ; export SADM_80_DASH       # 80 equals sign line
SADM_TEN_DASH=`printf %10s |tr " " "-"`     ; export SADM_TEN_DASH      # 10 dashes line
SADM_VAR1=""                                ; export SADM_VAR1          # Temp Dummy Variable
SADM_STIME=""                               ; export SADM_STIME         # Store Script Start Time
SADM_DEBUG_LEVEL=0                          ; export SADM_DEBUG_LEVEL   # 0=NoDebug Higher=+Verbose
DELETE_PID="Y"                              ; export DELETE_PID         # Default Delete PID On Exit 
SADM_LIB_VER="2.45"                         ; export SADM_LIB_VER       # This Library Version

# SADMIN DIRECTORIES STRUCTURES DEFINITIONS
SADM_BASE_DIR=${SADMIN:="/sadmin"}          ; export SADM_BASE_DIR      # Script Root Base Dir.
SADM_BIN_DIR="$SADM_BASE_DIR/bin"           ; export SADM_BIN_DIR       # Script Root binary Dir.
SADM_TMP_DIR="$SADM_BASE_DIR/tmp"           ; export SADM_TMP_DIR       # Script Temp  directory
SADM_LIB_DIR="$SADM_BASE_DIR/lib"           ; export SADM_LIB_DIR       # Script Lib directory
SADM_LOG_DIR="$SADM_BASE_DIR/log"           ; export SADM_LOG_DIR       # Script log directory
SADM_CFG_DIR="$SADM_BASE_DIR/cfg"           ; export SADM_CFG_DIR       # Configuration Directory
SADM_SYS_DIR="$SADM_BASE_DIR/sys"           ; export SADM_SYS_DIR       # System related scripts
SADM_DAT_DIR="$SADM_BASE_DIR/dat"           ; export SADM_DAT_DIR       # Data directory
SADM_DOC_DIR="$SADM_BASE_DIR/doc"           ; export SADM_DOC_DIR       # Documentation directory
SADM_PKG_DIR="$SADM_BASE_DIR/pkg"           ; export SADM_PKG_DIR       # Package rpm,deb  directory
SADM_SETUP_DIR="$SADM_BASE_DIR/setup"       ; export SADM_SETUP_DIR     # Package rpm,deb  directory
SADM_NMON_DIR="$SADM_DAT_DIR/nmon"          ; export SADM_NMON_DIR      # Where nmon file reside
SADM_DR_DIR="$SADM_DAT_DIR/dr"              ; export SADM_DR_DIR        # Disaster Recovery  files 
SADM_RCH_DIR="$SADM_DAT_DIR/rch"            ; export SADM_RCH_DIR       # Result Code History Dir
SADM_NET_DIR="$SADM_DAT_DIR/net"            ; export SADM_NET_DIR       # Network SubNet Info Dir
SADM_RPT_DIR="$SADM_DAT_DIR/rpt"            ; export SADM_RPT_DIR       # SADM Sysmon Report Dir
SADM_DBB_DIR="$SADM_DAT_DIR/dbb"            ; export SADM_DBB_DIR       # Database Backup Directory
SADM_WWW_DIR="$SADM_BASE_DIR/www"           ; export SADM_WWW_DIR       # Web Dir

# SADMIN USER DIRECTORIES
SADM_USR_DIR="$SADM_BASE_DIR/usr"           ; export SADM_USR_DIR       # Script User directory
SADM_UBIN_DIR="$SADM_USR_DIR/bin"           ; export SADM_UBIN_DIR      # Script User Bin Dir.
SADM_ULIB_DIR="$SADM_USR_DIR/lib"           ; export SADM_ULIB_DIR      # Script User Lib Dir.
SADM_UDOC_DIR="$SADM_USR_DIR/doc"           ; export SADM_UDOC_DIR      # Script User Doc. Dir.
SADM_UMON_DIR="$SADM_USR_DIR/mon"           ; export SADM_UMON_DIR      # Script User SysMon Scripts

# SADMIN SERVER WEB SITE DIRECTORIES DEFINITION
SADM_WWW_DOC_DIR="$SADM_WWW_DIR/doc"                        ; export SADM_WWW_DOC_DIR  # www Doc Dir
SADM_WWW_DAT_DIR="$SADM_WWW_DIR/dat"                        ; export SADM_WWW_DAT_DIR  # www Dat Dir
SADM_WWW_RRD_DIR="$SADM_WWW_DIR/rrd"                        ; export SADM_WWW_RRD_DIR  # www RRD Dir
SADM_WWW_CFG_DIR="$SADM_WWW_DIR/cfg"                        ; export SADM_WWW_CFG_DIR  # www CFG Dir
SADM_WWW_LIB_DIR="$SADM_WWW_DIR/lib"                        ; export SADM_WWW_LIB_DIR  # www Lib Dir
SADM_WWW_IMG_DIR="$SADM_WWW_DIR/images"                     ; export SADM_WWW_IMG_DIR  # www Img Dir
SADM_WWW_NET_DIR="$SADM_WWW_DAT_DIR/${SADM_HOSTNAME}/net"   ; export SADM_WWW_NET_DIR  # web net dir
SADM_WWW_TMP_DIR="$SADM_WWW_DIR/tmp"                        ; export SADM_WWW_TMP_DIR  # web tmp dir
SADM_WWW_PERF_DIR="$SADM_WWW_TMP_DIR/perf"                  ; export SADM_WWW_PERF_DIR # web perf dir

# SADM CONFIG FILE, LOGS AND TEMP FILES USER CAN USE
SADM_PID_FILE="${SADM_TMP_DIR}/${SADM_INST}.pid"            ; export SADM_PID_FILE   # PID file name
SADM_CFG_FILE="$SADM_CFG_DIR/sadmin.cfg"                    ; export SADM_CFG_FILE   # Cfg file name
SADM_ALERT_FILE="$SADM_CFG_DIR/alert_group.cfg"             ; export SADM_ALERT_FILE # AlertGrp File
SADM_ALERT_INIT="$SADM_CFG_DIR/.alert_group.cfg"            ; export SADM_ALERT_INIT # Initial Alert
SADM_SLACK_FILE="$SADM_CFG_DIR/alert_slack.cfg"             ; export SADM_SLACK_FILE # Slack WebHook
SADM_SLACK_INIT="$SADM_CFG_DIR/.alert_slack.cfg"            ; export SADM_SLACK_INIT # Slack Init WH
SADM_ALERT_HIST="$SADM_CFG_DIR/alert_history.txt"           ; export SADM_ALERT_HIST # Alert History
SADM_ALERT_HINI="$SADM_CFG_DIR/.alert_history.txt"          ; export SADM_ALERT_HINI # History Init
SADM_ALERT_SEQ="$SADM_CFG_DIR/alert_history.seq"            ; export SADM_ALERT_SEQ  # History Seq#
SADM_REL_FILE="$SADM_CFG_DIR/.release"                      ; export SADM_REL_FILE   # Release Ver.
SADM_CRON_FILE="$SADM_CFG_DIR/.sadm_osupdate"               ; export SADM_CRON_FILE  # Work crontab
SADM_CRONTAB="/etc/cron.d/sadm_osupdate"                    ; export SADM_CRONTAB    # Final crontab
SADM_CFG_HIDDEN="$SADM_CFG_DIR/.sadmin.cfg"                 ; export SADM_CFG_HIDDEN # Cfg file name
SADM_TMP_FILE1="${SADM_TMP_DIR}/${SADM_INST}_1.$$"          ; export SADM_TMP_FILE1  # Temp File 1 
SADM_TMP_FILE2="${SADM_TMP_DIR}/${SADM_INST}_2.$$"          ; export SADM_TMP_FILE2  # Temp File 2
SADM_TMP_FILE3="${SADM_TMP_DIR}/${SADM_INST}_3.$$"          ; export SADM_TMP_FILE3  # Temp File 3
SADM_LOG="${SADM_LOG_DIR}/${SADM_HOSTNAME}_${SADM_INST}.log"    ; export LOG         # Output LOG 
SADM_RCHLOG="${SADM_RCH_DIR}/${SADM_HOSTNAME}_${SADM_INST}.rch" ; export SADM_RCHLOG # Return Code 
SADM_RPT_FILE="${SADM_RPT_DIR}/${SADM_HOSTNAME}.rpt"        ; export SADM_RPT_FILE   # RPT FileName 

# COMMAND PATH REQUIRE THAT SADMIN USE
SADM_LSB_RELEASE=""                         ; export SADM_LSB_RELEASE   # Command lsb_release Path
SADM_DMIDECODE=""                           ; export SADM_DMIDECODE     # Command dmidecode Path
SADM_BC=""                                  ; export SADM_BC            # Command bc (Do Some Math)
SADM_FDISK=""                               ; export SADM_FDISK         # fdisk (Read Disk Capacity)
SADM_WHICH=""                               ; export SADM_WHICH         # which Path - Required
SADM_PERL=""                                ; export SADM_PERL          # perl Path (for epoch time)
SADM_MAIL=""                                ; export SADM_MAIL          # mail Pgm Path
SADM_MUTT=""                                ; export SADM_MUTT          # mutt Pgm Path
SADM_CURL=""                                ; export SADM_CURL          # curl Pgm Path
SADM_LSCPU=""                               ; export SADM_LSCPU         # Path to lscpu Command
SADM_NMON=""                                ; export SADM_NMON          # Path to nmon Command
SADM_PARTED=""                              ; export SADM_PARTED        # Path to parted Command
SADM_ETHTOOL=""                             ; export SADM_ETHTOOL       # Path to ethtool Command
SADM_SSH=""                                 ; export SADM_SSH           # Path to ssh Exec.
SADM_MYSQL=""                               ; export SADM_MYSQL         # Default mysql FQDN
SADM_FACTER=""                              ; export SADM_FACTER        # Default facter Cmd Path

# SADMIN CONFIG FILE VARIABLES (Default Values here will be overrridden by SADM CONFIG FILE Content)
SADM_MAIL_ADDR="your_email@domain.com"      ; export SADM_MAIL_ADDR     # Default is in sadmin.cfg
SADM_ALERT_TYPE=1                           ; export SADM_ALERT_TYPE    # 0=No 1=Err 2=Succes 3=All
SADM_ALERT_GROUP="default"                  ; export SADM_ALERT_GROUP   # Define in alert_group.cfg
SADM_CIE_NAME="Your Company Name"           ; export SADM_CIE_NAME      # Company Name
SADM_HOST_TYPE=""                           ; export SADM_HOST_TYPE     # SADMIN [S]erver/[C]lient
SADM_USER="sadmin"                          ; export SADM_USER          # sadmin user account
SADM_GROUP="sadmin"                         ; export SADM_GROUP         # sadmin group account
SADM_WWW_USER="apache"                      ; export SADM_WWW_USER      # /sadmin/www owner 
SADM_WWW_GROUP="apache"                     ; export SADM_WWW_GROUP     # /sadmin/www group
SADM_MAX_LOGLINE=5000                       ; export SADM_MAX_LOGLINE   # Max Nb. Lines in LOG
SADM_MAX_RCLINE=100                         ; export SADM_MAX_RCLINE    # Max Nb. Lines in RCH file
SADM_NMON_KEEPDAYS=60                       ; export SADM_NMON_KEEPDAYS # Days to keep old *.nmon
SADM_RCH_KEEPDAYS=60                        ; export SADM_RCH_KEEPDAYS  # Days to keep old *.rch
SADM_LOG_KEEPDAYS=60                        ; export SADM_LOG_KEEPDAYS  # Days to keep old *.log
SADM_DBNAME="sadmin"                        ; export SADM_DBNAME        # MySQL DataBase Name
SADM_DBHOST="sadmin.maison.ca"              ; export SADM_DBHOST        # MySQL DataBase Host
SADM_DBPORT=3306                            ; export SADM_DBPORT        # MySQL Listening Port
SADM_RW_DBUSER=""                           ; export SADM_RW_DBUSER     # MySQL Read/Write User 
SADM_RW_DBPWD=""                            ; export SADM_RW_DBPWD      # MySQL Read/Write Passwd
SADM_RO_DBUSER=""                           ; export SADM_RO_DBUSER     # MySQL Read Only User 
SADM_RO_DBPWD=""                            ; export SADM_RO_DBPWD      # MySQL Read Only Passwd
SADM_SERVER=""                              ; export SADM_SERVER        # Server FQDN Name
SADM_DOMAIN=""                              ; export SADM_DOMAIN        # Default Domain Name
SADM_NETWORK1=""                            ; export SADM_NETWORK1      # Network 1 to Scan 
SADM_NETWORK2=""                            ; export SADM_NETWORK2      # Network 2 to Scan 
SADM_NETWORK3=""                            ; export SADM_NETWORK3      # Network 3 to Scan 
SADM_NETWORK4=""                            ; export SADM_NETWORK4      # Network 4 to Scan 
SADM_NETWORK5=""                            ; export SADM_NETWORK5      # Network 5 to Scan 
DBPASSFILE="${SADM_CFG_DIR}/.dbpass"        ; export DBPASSFILE         # MySQL Passwd File
SADM_RELEASE=`cat $SADM_REL_FILE`           ; export SADM_RELEASE       # SADM Release Ver. Number
SADM_SSH_PORT=""                            ; export SADM_SSH_PORT      # Default SSH Port
SADM_RRDTOOL=""                             ; export SADM_RRDTOOL       # RRDTool Location
SADM_REAR_NFS_SERVER=""                     ; export SADM_REAR_NFS_SERVER        # ReaR NFS Server
SADM_REAR_NFS_MOUNT_POINT=""                ; export SADM_REAR_NFS_MOUNT_POINT   # ReaR Mount Point
SADM_REAR_BACKUP_TO_KEEP=3                  ; export SADM_REAR_BACKUP_TO_KEEP    # Rear Nb.Copy 
SADM_STORIX_NFS_SERVER=""                   ; export SADM_STORIX_NFS_SERVER      # Storix NFS Server
SADM_STORIX_NFS_MOUNT_POINT=""              ; export SADM_STORIX_NFS_MOUNT_POINT # Storix Mnt Point
SADM_STORIX_BACKUP_TO_KEEP=3                ; export SADM_STORIX_BACKUP_TO_KEEP  # Storix Nb. Copy
SADM_BACKUP_NFS_SERVER=""                   ; export SADM_BACKUP_NFS_SERVER      # Backup NFS Server
SADM_BACKUP_NFS_MOUNT_POINT=""              ; export SADM_BACKUP_NFS_MOUNT_POINT # Backup Mnt Point
SADM_DAILY_BACKUP_TO_KEEP=3                 ; export SADM_DAILY_BACKUP_TO_KEEP   # Daily to Keep
SADM_WEEKLY_BACKUP_TO_KEEP=3                ; export SADM_WEEKLY_BACKUP_TO_KEEP  # Weekly to Keep
SADM_MONTHLY_BACKUP_TO_KEEP=2               ; export SADM_MONTHLY_BACKUP_TO_KEEP # Monthly to Keep
SADM_YEARLY_BACKUP_TO_KEEP=1                ; export SADM_YEARLY_BACKUP_TO_KEEP  # Yearly to Keep
# Day of the week to do a weekly backup (1=Mon,2=Tue,3=Wed,4=Thu,5=Fri,6=Sat,7=Sun)
SADM_WEEKLY_BACKUP_DAY=5                    ; export SADM_WEEKLY_BACKUP_DAY      # Weekly Backup Day          
SADM_MONTHLY_BACKUP_DATE=1                  ; export SADM_MONTHLY_BACKUP_DATE    # Monthly Back Date
SADM_YEARLY_BACKUP_MONTH=12                 ; export SADM_YEARLY_BACKUP_MONTH    # Yearly Backup Mth
SADM_YEARLY_BACKUP_DATE=31                  ; export SADM_YEARLY_BACKUP_DATE     # Yearly Backup Day
SADM_MKSYSB_NFS_SERVER=""                   ; export SADM_MKSYSB_NFS_SERVER      # Mksysb NFS Server
SADM_MKSYSB_NFS_MOUNT_POINT=""              ; export SADM_MKSYSB_NFS_MOUNT_POINT # Mksysb Mnt Point
SADM_MKSYSB_NFS_TO_KEEP=2                   ; export SADM_MKSYSB_NFS_TO_KEEP     # Mksysb Bb. Copy

# Local to Library Variable - Can't be use elsewhere outside this script
LOCAL_TMP="$SADM_TMP_DIR/sadmlib_tmp.$$"    ; export LOCAL_TMP          # Local Temp File
LIB_DEBUG=0                                 ; export LIB_DEBUG          # Libr. Debug Level


# --------------------------------------------------------------------------------------------------
#                     THIS FUNCTION RETURN THE STRING RECEIVED TO UPPERCASE
# --------------------------------------------------------------------------------------------------
sadm_toupper() { 
    echo $1 | tr  "[:lower:]" "[:upper:]"
}

# --------------------------------------------------------------------------------------------------
#                       THIS FUNCTION RETURN THE STRING RECEIVED TO LOWERCASE 
# --------------------------------------------------------------------------------------------------
sadm_tolower() {
    echo $1 | tr  "[:upper:]" "[:lower:]"
}

# --------------------------------------------------------------------------------------------------
# Check if variable is an integer - Return 1, if not an intener - Return 0 if it is an integer
# --------------------------------------------------------------------------------------------------
sadm_isnumeric() {
    wnum=$1
    if [ "$wnum" -eq "$wnum" ] 2>/dev/null ; then return 0 ; else return 1 ; fi
}


# --------------------------------------------------------------------------------------------------
#     WRITE INFORMATION TO THE LOG (L) , TO SCREEN (S)  OR BOTH (B) DEPENDING ON $SADM_LOG_TYPE
# --------------------------------------------------------------------------------------------------
sadm_writelog() {
    SADM_SMSG="$@"                                                      # Screen Mess no Date/Time
    SADM_LMSG="$(date "+%C%y.%m.%d %H:%M:%S") $@"                       # Log Message with Date/Time
    case "$SADM_LOG_TYPE" in                                            # Depending of LOG_TYPE
        s|S) printf "%-s\n" "$SADM_SMSG"                                # Write Msg To Screen
             ;; 
        l|L) printf "%-s\n" "$SADM_LMSG" >> $SADM_LOG                   # Write Msg to Log File
             ;; 
        b|B) printf "%-s\n" "$SADM_SMSG"                                # Both = to Screen
             printf "%-s\n" "$SADM_LMSG" >> $SADM_LOG                   # Both = to Log
             ;;
        *)   printf "Wrong value in \$SADM_LOG_TYPE ($SADM_LOG_TYPE)\n" # Advise User if Incorrect
             ;;
    esac
}


# --------------------------------------------------------------------------------------------------
#                TRIM THE FILE RECEIVED AS FIRST PARAMETER (MAX LINES IN LOG AS 2ND PARAMATER)
# --------------------------------------------------------------------------------------------------
sadm_trimfile() {
    wfile=$1 ; maxline=$2                                               # Save FileName et Nb Lines
    wreturn_code=0                                                      # Return Code of function
    
    # Test Number of parameters received
    if [ $# -ne 2 ]                                                     # Should have rcv 1 Param
        then sadm_writelog "sadm_trimfile: Should receive 2 Parameters" # Show User Info on Error
             sadm_writelog "Have received $# parameters ($*)"           # Advise User to Correct
             return 1                                                   # Return Error to Caller
    fi
    
    # Test if filename received exist
    if [ ! -r "$wfile" ]                                                # Check if File Rcvd Exist
        then sadm_writelog "sadm_trimfile : Can't read file $1"         # Advise user
             return 1                                                   # Return Error to Caller
    fi

    # Test if Second Parameter Received is an integer
    sadm_isnumeric "$maxline"                                           # Test if an Integer
    if [ $? -ne 0 ]                                                     # If not an Integer
        then wreturn_code=1                                             # Return Code report error
             sadm_writelog "sadm_trimfile: Nb of line invalid ($2)"     # Advise User
             return 1                                                   # Return Error to Caller
    fi
    
    #tmpfile=`mktemp --tmpdir=${SADM_TMP_DIR}`                          # Problem in RHEL4 
    tmpfile="${SADM_TMP_DIR}/${SADM_INST}.$$"                           # Create Temp Work FileName    
    if [ $? -ne 0 ] ; then wreturn_code=1 ; fi                          # Return Code report error
    tail -${maxline} $wfile > $tmpfile                                  # Trim file to Desired Nb.
    if [ $? -ne 0 ] ; then wreturn_code=1 ; fi                          # Return Code report error
    rm -f ${wfile} > /dev/null                                          # Remove Original Log
    if [ $? -ne 0 ] ; then wreturn_code=1 ; fi                          # Return Code report error
    mv ${tmpfile} ${wfile}                                              # Move Tmp to original
    if [ $? -ne 0 ] ; then wreturn_code=1 ; fi                          # Return Code report error
    chmod 664 ${wfile}                                                  # Make permission to 664
    if [ $? -ne 0 ] ; then wreturn_code=1 ; fi                          # Return Code report error
    rm -f ${tmpfile} >/dev/null 2>&1                                    # Remove Temp Work File
    if [ $? -ne 0 ] ; then wreturn_code=1 ; fi                          # Return Code report error
    return ${wreturn_code}                                              # Return to Caller 
}


# --------------------------------------------------------------------------------------------------
# THIS FUNCTION VERIFY IF THE COMMAND RECEIVED IN PARAMETER IS AVAILABLE ON THE SYSTEM 
# IF THE COMMAND EXIST, RETURN 0  -  IF IT DOESN'T EXIST RETURN 1
# --------------------------------------------------------------------------------------------------
sadm_check_command_availibility() {
    SADM_CMD=$1                                                         # Save Parameter received
    if ${SADM_WHICH} ${SADM_CMD} >/dev/null 2>&1                        # command is found ?
        then SADM_VAR1=`${SADM_WHICH} ${SADM_CMD}`                      # Store Path of command
             return 0                                                   # Return 0 if cmd found
        else SADM_VAR1=""                                               # Clear Path of command
    fi  
    return 1
}


# --------------------------------------------------------------------------------------------------
# THIS FUNCTION IS USED TO INSTALL A MISSING PACKAGE THAT IS REQUIRED BY SADMIN TOOLS
#                       THE PACKAGE TO INSTALL IS RECEIVED AS A PARAMETER
# --------------------------------------------------------------------------------------------------
sadm_install_package() 
{
    # Check if we received at least a parameter
    if [ $# -ne 2 ]                                                      # Should have rcv 1 Param
        then sadm_writelog "Nb. Parameter received by $FUNCNAME function is incorrect"
             sadm_writelog "Please correct your script - Script Aborted" # Advise User to Correct
             sadm_stop 1                                                 # Prepare exit gracefully
             exit 1                                                      # Terminate the script
    fi
    PACKAGE_RPM=$1                                                       # RedHat/CentOS/Fedora Pkg
    PACKAGE_DEB=$2                                                       # Ubuntu/Debian/Raspian Deb
    

    # Install the Package under RedHat/CentOS/Fedora
    if [ "$(sadm_get_osname)" = "REDHAT" ] || [ "$(sadm_get_osname)" = "CENTOS" ] || 
       [ "$(sadm_get_osname)" = "FEDORA" ]
        then lmess="Starting installation of ${PACKAGE_RPM} under $(sadm_get_osname)"
             lmess="${lmess} Version $(sadm_get_osmajorversion)" 
             sadm_writelog "$lmess"
             case "$(sadm_get_osmajorversion)" in
                [34])  sadm_writelog "Running \"up2date --nox -i ${PACKAGE_RPM}\""
                       up2date --nox -i ${PACKAGE_RPM} >>$SADM_LOG 2>&1
                       rc=$?
                       sadm_writelog "Return Code after installing ${PACKAGE_RPM} is $rc"
                       break
                       ;;
              [567])   sadm_writelog "Running \"yum -y install ${PACKAGE_RPM}\"" # Install Command
                       yum -y install ${PACKAGE_RPM} >> $SADM_LOG 2>&1  # List Available update
                       rc=$?                                            # Save Exit Code
                       sadm_writelog "Return Code after in installation of ${PACKAGE_RPM} is $rc"
                       break
                       ;;
              *)       lmess="The version $(sadm_get_osmajorversion) of"
                       lmess="${lmess} $(sadm_get_osname) isn't supported at the moment"
                       sadm_writelog "$lmess"
                       rc=1                                             # Save Exit Code
                       break
                       ;;
             esac
    fi
    
    # Install the Package under Debian/*Ubuntu/RaspberryPi 
    if [ "$(sadm_get_osname)" = "UBUNTU" ] || [ "$(sadm_get_osname)" = "RASPBIAN" ] ||
       [ "$(sadm_get_osname)" = "DEBIAN" ] || [ "$(sadm_get_osname)" = "LINUXMINT" ] 
        then sadm_writelog "Resynchronize package index files from their sources via Internet"
             sadm_writelog "Running \"apt-get update\""                 # Msg Get package list 
             apt-get update > /dev/null 2>&1                            # Get Package List From Repo
             rc=$?                                                      # Save Exit Code
             if [ "$rc" -ne 0 ]
                then sadm_writelog "We had problem running the \"apt-get update\" command" 
                     sadm_writelog "We had a return code $rc" 
                else sadm_writelog "Return Code after apt-get update is $rc"  # Show  Return Code
                     sadm_writelog "Installing the Package ${PACKAGE_DEB} now"
                     sadm_writelog "apt-get -y install ${PACKAGE_DEB}"
                     apt-get -y install ${PACKAGE_DEB}
                     rc=$?                                              # Save Exit Code
                     sadm_writelog "Return Code after installation of ${PACKAGE_DEB} is $rc" 
             fi
    fi         
    sadm_writelog " "
    return $rc                                                          # 0=Installed 1=Error
}


# --------------------------------------------------------------------------------------------------
# THIS FUNCTION MAKE SURE THAT ALL SADM SHELL LIBRARIES (LIB/SADM_*) REQUIREMENTS ARE MET BEFORE USE
# IF THE REQUIRENMENT ARE NOT MET, THEN THE SCRIPT WILL ABORT INFORMING USER TO CORRECT SITUATION
# --------------------------------------------------------------------------------------------------
#
sadm_check_requirements() {
                           
    # The 'which' command is needed to determine presence of command - Return Error if not found
    if which which >/dev/null 2>&1                                      # Try the command which 
        then SADM_WHICH=`which which`  ; export SADM_WHICH              # Save the Path of Which
        else sadm_writelog "[ERROR] The command 'which' couldn't be found" 
             sadm_writelog "        This program is often used by the SADMIN tools"
             sadm_writelog "        Please install it and re-run this script"
             sadm_writelog "        *** Script Aborted"
             return 1                                                   # Return Error to Caller
    fi
    
    # Commands available on Linux O/S --------------------------------------------------------------
    if [ "$(sadm_get_ostype)" = "LINUX" ]                               # Under Linux O/S
       then sadm_check_command_availibility "lsb_release"               # lsb_release cmd available?
            SADM_LSB_RELEASE=$SADM_VAR1   
            sadm_check_command_availibility "dmidecode"                 # dmidecode cmd available?
            SADM_DMIDECODE=$SADM_VAR1    
            sadm_check_command_availibility "nmon"                      # Command available?
            if [ "$SADM_VAR1" = "" ]                                    # If Command not found
                then sadm_install_package "nmon" "nmon"                 # Go Install Missing Package
                     if [ $? -eq 0 ] ; then sadm_check_command_availibility nmon ;fi
            fi
            SADM_NMON=$SADM_VAR1                                        # Save Command Path

            sadm_check_command_availibility "ethtool"                   # Command available?
            if [ "$SADM_VAR1" = "" ]                                    # If Command not found
                then sadm_install_package "ethtool" "ethtool"           # Go Install Missing Package
                    if [ $? -eq 0 ] ;then sadm_check_command_availibility ethtool ;fi
            fi
            SADM_ETHTOOL=$SADM_VAR1                                     # Save Command Path
            
            sadm_check_command_availibility "parted"                    # Command available?
            if [ "$SADM_VAR1" = "" ]                                    # If Command not found
                then sadm_install_package "parted" "parted"             # Go Install Missing Package
                    if [ $? -eq 0 ] ;then sadm_check_command_availibility "parted" ;fi
            fi
            SADM_PARTED=$SADM_VAR1                                      # Save Command Path
            
            sadm_check_command_availibility "mail"                      # Mail cmd available?
            if [ "$SADM_VAR1" = "" ]                                    # If Command not found
                then sadm_install_package "mailx" "mailutils"            # Go Install Missing Package
                     if [ $? -eq 0 ] ;then sadm_check_command_availibility "mail" ; fi
            fi
            SADM_MAIL=$SADM_VAR1                                        # Save Command Path    
            
            sadm_check_command_availibility "mutt"                      # mutt cmd available?
            if [ "$SADM_VAR1" = "" ]                                    # If Command not found
                then sadm_install_package "mutt" "mutt"                 # Go Install Missing Package
                     if [ $? -eq 0 ] ;then sadm_check_command_availibility "mutt" ; fi
            fi
            SADM_MUTT=$SADM_VAR1                                        # Save Command Path    
            
            sadm_check_command_availibility "curl"                      # mutt cmd available?
            if [ "$SADM_VAR1" = "" ]                                    # If Command not found
                then sadm_install_package "curl" "curl"                 # Go Install Missing Package
                     if [ $? -eq 0 ] ;then sadm_check_command_availibility "mutt" ; fi
            fi
            SADM_CURL=$SADM_VAR1                                        # Save Command Path    
            
            sadm_check_command_availibility lscpu                       # lscpu cmd available?
            SADM_LSCPU=$SADM_VAR1                                       # Save Command Path    
    fi
                            
    # Commands on Aix O/S --------------------------------------------------------------------------
    if [ "$(sadm_get_ostype)" = "AIX" ]                                 # Under Aix O/S
       then sadm_check_command_availibility "nmon"                      # nmon cmd available?
            SADM_NMON=$SADM_VAR1       
            if [ "$SADM_VAR1" = "" ]                                    # If Command not found
               then NMON_WDIR="${SADM_PKG_DIR}/nmon/aix/" 
                    NMON_EXE="nmon_aix$(sadm_get_osmajorversion)$(sadm_get_osminorversion)"
                    NMON_USE="${NMON_WDIR}${NMON_EXE}"
                    if [ ! -x "$NMON_USE" ]
                        then sadm_writelog "The nmon for AIX $(sadm_get_osversion) isn't available"
                             sadm_writelog "The nmon executable we need is $NMON_USE" 
                       else sadm_writelog "ln -s ${NMON_USE} /usr/bin/nmon" 
                             ln -s ${NMON_USE} /usr/bin/nmon
                             if [ $? -eq 0 ] ; then SADM_NMON="/usr/bin/nmon" ; fi 
                    fi
            fi
    fi
    
    # Commands require on ALL platform -------------------------------------------------------------
    sadm_check_command_availibility "perl"                              # perl needed (epoch time)
    SADM_PERL=$SADM_VAR1                                                # Save perl path
    sadm_check_command_availibility "ssh"                               # ssh needed (epoch time)
    SADM_SSH=$SADM_VAR1                                                 # Save ssh path
    sadm_check_command_availibility "bc"                                # bc cmd available?
    SADM_BC=$SADM_VAR1                                                  # Save Command Path
    sadm_check_command_availibility "mail"                              # Mail cmd available?
    SADM_MAIL=$SADM_VAR1                                                # Save Command Path
    sadm_check_command_availibility "fdisk"                             # FDISK cmd available?
    SADM_FDISK=$SADM_VAR1                                               # Save Command Path
    sadm_check_command_availibility "facter"                            # facter cmd available?
    SADM_FACTER=$SADM_VAR1                                              # Save Command Path

    # If on the SADMIN Server mysql MUST be present - Check Availibility of the mysql command.
    SADM_MYSQL=""                                                       # Default mysql Location
    if [ "$(sadm_get_fqdn)" = "$SADM_SERVER" ]                          # Only Check on SADMIN Srv
        then sadm_check_command_availibility "mysql"                    # Command available?
             SADM_MYSQL=$SADM_VAR1                                      # Save Command Path
    fi
    return 0
}



# --------------------------------------------------------------------------------------------------
# Called when we need to advise the SysAdmin of an error or when his attention is required.
#   Email of system admintrator(s) is taken from SADMIN configuration file ($SADMIN/cfg/sadmin.cfg)
#   The Common variable name that contains the email(s) is $SADM_MAIL_ADDR
#
# 1st Paramater : Alert Typer [M]ail [S]lack
# 2nd Parameter : Message Severity ([E]rror [W]arning [I]nformation
# 3rd Paramater : Server Name 
# 4rd Paramater : Subject of Message
# 5th Parameter : Message
# 6th Parameter : FileName of attachement (if Any, could be blank)
#
# --------------------------------------------------------------------------------------------------
alert_sysadmin()    {

    # Validate the Number of parameter received.
    if [ $# -ne 6 ] 
        then sadm_writelog "Invalid Nb argument receive by ${FUNCNAME}" # Advise User
             sadm_writelog "Should be 6, we received $# : $*"           # Show what received
             return 1                                                   # Return Error to caller
    fi
    as_exit_code=0                                                      # Func. Default Return Code

    # Save Parameters (After Removing leading and trailing Spaces and/or Making it UpperCase)
    as_type=`echo $1      | tr "[:lower:]" "[:upper:]"`                 # Alert Type [M]ail [S]lack
    as_severity=`echo $2  | tr "[:lower:]" "[:upper:]"`                 # E=Error W=Warning I=info
    as_server=`echo "$3"  | awk '{$1=$1;print}'`                        # Problematic Server Name 
    as_subject=`echo "$4" | awk '{$1=$1;print}'`                        # Alert Subject
    as_mess=$5                                                          # Alert Message 
    as_file=`echo "$6"    | awk '{$1=$1;print}'`                        # Alert Attachement FileName

    # Is there is an attachment is the File Readable ?
    if [ "$as_file" != "" ] && [ ! -r "$as_file" ]                      # Can't read Attachment File
       then sadm_writelog "Error in ${FUNCNAME} - Attachment file '$as_file' missing" 
            return 1                                                    # Return Error to caller
    fi 
    
    # Build SADM uniform Subject Prefix - Based on Alert Severity Received
    case "$as_severity" in                                              # Depend on Severity E/W/I
        E)   
             as_subject="SADM ERROR: $as_subject"                       # Error Subject Prefix 
             ;; 
        W)   
             as_subject="SADM WARNING: $as_subject"                     # Warning Subject Prefix 
             ;; 
        I)   
             as_subject="SADM INFO: $as_subject"                        # Info Subject Prefix 
             ;; 
          *) 
             as_subject="SADM ${as_severity}: $as_subject"              # Invalid Subject Prefix
             ;; 
    esac

    # Send the Alert Message using the type of alert requested
    case "$as_type" in 
        M) if [ "$SADM_MUTT" = "" ] 
                then sadm_writelog "Function 'alert_sysadmin' was requested to send an email" 
                     sadm_writelog "But the 'mutt' program was not found (SADM_MUTT=${SADM_MUTT})" 
                     sadm_writelog "Install the 'mutt' command and try again"
                     return 1                                           # Something went wrong 
                else if [ "$as_file" != "" ]
                        then echo -e "$as_mess" | $SADM_MUTT -s "$as_subject" $SADM_MAIL_ADDR -a $as_file
                        else echo -e "$as_mess" | $SADM_MUTT -s "$as_subject" $SADM_MAIL_ADDR 
                     fi 
                     #if [ "$as_file" != "" ] ; then $MUTT_CMD="$MUTT_CMD -a $as_file" ; fi 
                     #sadm_writelog "MUTTCMD = $MUTT_CMD"
                     as_exit_code=$?                                    # Set Return Code 
                     if [ "$as_exit_code" -ne 0 ] 
                        then sadm_writelog "Error send email to SysAdmin '$SADM_MAIL_ADDR'"
                             sadm_writelog "Command used: $MUTT_CMD"
                     fi                             
           fi
           ;; 
        *) sadm_writelog "Error in ${FUNCNAME} - Type of alert '$as_type' not supported" 
           as_exit_code=1                                               # Something went wrong 
           ;; 
    esac

    return $as_exit_code
}


# --------------------------------------------------------------------------------------------------
#                       R E T U R N      C U R R E N T    E P O C H   T I M E           
# --------------------------------------------------------------------------------------------------
sadm_get_epoch_time() {
    w_epoch_time=`${SADM_PERL} -e 'print time'`                         # Use Perl to get Epoch Time
    echo "$w_epoch_time"                                                # Return Epoch to Caller
}



# --------------------------------------------------------------------------------------------------
#    C O N V E R T   E P O C H   T I M E    R E C E I V E   T O    D A T E  (YYYY.MM.DD HH:MM:SS)
# --------------------------------------------------------------------------------------------------
sadm_epoch_to_date() {

    if [ $# -ne 1 ]                                                     # Should have rcv 1 Param
        then sadm_writelog "No Parameter received by $FUNCNAME function"  # Show User Info on Error
             sadm_writelog "Please correct your script - Script Aborted"  # Advise User to Correct
             sadm_stop 1                                                # Prepare to exit gracefully
             exit 1                                                     # Terminate the script
    fi
    wepoch=$1                                                           # Save Epoch Time Receivec

    # Verify if parameter received is all numeric - If not advice user and exit
    echo $wepoch | grep [^0-9] > /dev/null 2>&1                         # Grep for Number
    if [ "$?" -eq "0" ]                                                 # Not All Number
        then sadm_writelog "Incorrect parameter received by \"sadm_epoch_to_date\" function"
             sadm_writelog "Should recv. epoch time & received ($wepoch)" # Advise User
             sadm_writelog "Please correct situation - Script Aborted"    # Advise that will abort
             sadm_stop 1                                                # Prepare to exit gracefully
             exit 1                                                     # Terminate the script
    fi
    
    # Format the Converted Epoch time obtain from Perl 
    WDATE=`$SADM_PERL -e "print scalar(localtime($wepoch))"`            # Perl Convert Epoch to Date
    YYYY=`echo    $WDATE | awk '{ print $5 }'`                          # Extract the Year 
    HMS=`echo     $WDATE | awk '{ print $4 }'`                          # Extract Hour:Min:Sec
    DD=`echo      $WDATE | awk '{ print $3 }'`                          # Extract Day Number
    MON_STR=`echo $WDATE | awk '{ print $2 }'`                          # Extract Month String
    if [ "$MON_STR" = "Jan" ] ; then MM=01 ; fi                         # Convert Jan to 01 
    if [ "$MON_STR" = "Feb" ] ; then MM=02 ; fi                         # Convert Feb to 02
    if [ "$MON_STR" = "Mar" ] ; then MM=03 ; fi                         # Convert Mar to 03
    if [ "$MON_STR" = "Apr" ] ; then MM=04 ; fi                         # Convert Apr to 04
    if [ "$MON_STR" = "May" ] ; then MM=05 ; fi                         # Convert May to 05
    if [ "$MON_STR" = "Jun" ] ; then MM=06 ; fi                         # Convert Jun to 06
    if [ "$MON_STR" = "Jul" ] ; then MM=07 ; fi                         # Convert Jul to 07
    if [ "$MON_STR" = "Aug" ] ; then MM=08 ; fi                         # Convert Aug to 08
    if [ "$MON_STR" = "Sep" ] ; then MM=09 ; fi                         # Convert Sep to 09
    if [ "$MON_STR" = "Oct" ] ; then MM=10 ; fi                         # Convert Oct to 10
    if [ "$MON_STR" = "Nov" ] ; then MM=11 ; fi                         # Convert Nov to 11
    if [ "$MON_STR" = "Dec" ] ; then MM=12 ; fi                         # Convert Dec to 12
    w_epoch_to_date="${YYYY}.${MM}.${DD} ${HMS}"                        # Combine Data to form Date
    echo "$w_epoch_to_date"                                             # Return converted date
}



# --------------------------------------------------------------------------------------------------
#    C O N V E R T   D A T E  (YYYY.MM.DD HH:MM:SS)  R E C E I V E    T O    E P O C H   T I M E  
# --------------------------------------------------------------------------------------------------
sadm_date_to_epoch() {
    if [ $# -ne 1 ]                                                     # Should have rcv 1 Param
        then sadm_writelog "No Parameter received by $FUNCNAME function"  # Log Error Mess,
             sadm_writelog "Please correct script please, script aborted" # Advise that will abort
             sadm_stop 1                                                # Prepare to exit gracefully
             exit 1                                                     # Terminate the script
    fi

    WDATE=$1                                                            # Save Received Date
    YYYY=`echo $WDATE | awk -F. '{ print $1 }'`                         # Extract Year from Rcv Date
    MTH=` echo $WDATE | awk -F. '{ print $2 }'`                         # Extract MTH  from Rcv Date
    DD=`echo   $WDATE | awk -F. '{ print $3 }' | awk '{ print $1 }'`    # Extract Day
    HH=`echo   $WDATE | awk '{ print $2 }' | awk -F: '{ print $1 }'`    # Extract Hours
    MM=`echo   $WDATE | awk '{ print $2 }' | awk -F: '{ print $2 }'`    # Extract Min   
    SS=`echo   $WDATE | awk '{ print $2 }' | awk -F: '{ print $3 }'`    # Extract Sec

    case "$(sadm_get_ostype)" in                                            
        "LINUX")    if [ ${#DD} -lt 2 ]     ; then  DD=` printf "%02d" $DD`     ; fi 
                    if [ ${#MTH} -lt 2 ]    ; then  MTH=`printf "%02d" $MTH`    ; fi
                    if [ ${#HH} -lt 2 ]     ; then  HH=` printf "%02d" $HH`     ; fi
                    if [ ${#MM} -lt 2 ]     ; then  MM=` printf "%02d" $MM`     ; fi
                    if [ ${#SS} -lt 2 ]     ; then  SS=` printf "%02d" $SS`     ; fi               
                    sadm_date_to_epoch=`date +"%s" -d "$YYYY/$MTH/$DD $HH:$MM:$SS" `
                    ;; 
        "AIX")      if [ "$MTH" -gt 0 ] ; then MTH=`echo $MTH | sed 's/^0//'` ; fi      # Remove Leading 0 from Mth
                    MTH=`echo "$MTH -1" | $SADM_BC`
                    DD=`echo   $WDATE | awk -F. '{ print $3 }' | awk '{ print $1 }' | sed 's/^0//'` # Extract Day
                    HH=`echo   $WDATE | awk '{ print $2 }' | awk -F: '{ print $1 }' | sed 's/^0//'` # Extract Hours
                    MM=`echo   $WDATE | awk '{ print $2 }' | awk -F: '{ print $2 }' | sed 's/^0//'` # Extract Min   
                    SS=`echo   $WDATE | awk '{ print $2 }' | awk -F: '{ print $3 }' | sed 's/^0//'` # Extract Sec
                    sadm_date_to_epoch=`perl -e "use Time::Local; print timelocal($SS,$MM,$HH,$DD,$MTH,$YYYY)"`
                    ;;
        "DARWIN")   if [ ${#DD} -lt 2 ]     ; then  DD=` printf "%02d" $DD`     ; fi 
                    if [ ${#MTH} -lt 2 ]    ; then  MTH=`printf "%02d" $MTH`    ; fi
                    if [ ${#HH} -lt 2 ]     ; then  HH=` printf "%02d" $HH`     ; fi
                    if [ ${#MM} -lt 2 ]     ; then  MM=` printf "%02d" $MM`     ; fi
                    if [ ${#SS} -lt 2 ]     ; then  SS=` printf "%02d" $SS`     ; fi                     
                    sadm_date_to_epoch=`date -j -f "%Y/%m/%d %T" "$YYYY/$MTH/$DD $HH:$MM:$SS" +"%s"`
                    ;;   
    esac
    echo "$sadm_date_to_epoch"                                          # Return Epoch of Date Rcv.
}



# --------------------------------------------------------------------------------------------------
#    Calculate elapse time between date1 (YYYY.MM.DD HH:MM:SS) and date2 (YYYY.MM.DD HH:MM:SS)
#    Date 1 MUST be greater than date 2  (Date 1 = Like End time,  Date 2 = Start Time )
# --------------------------------------------------------------------------------------------------
sadm_elapse() {
    if [ $# -ne 2 ]                                                     # Should have rcv 1 Param
        then sadm_writelog "Invalid number of parameter received by $FUNCNAME function"
             sadm_writelog "Please correct script please, script aborted" # Advise that will abort
             sadm_stop 1                                                # Prepare to exit gracefully
             exit 1                                                     # Terminate the script
    fi
    w_endtime=$1                                                        # Save Ending Time
    w_starttime=$2                                                      # Save Start Time
    epoch_start=`sadm_date_to_epoch "$w_starttime"`                     # Get Epoch for Start Time
    epoch_end=`sadm_date_to_epoch   "$w_endtime"`                       # Get Epoch for End Time
    epoch_elapse=`echo "$epoch_end - $epoch_start" | $SADM_BC`          # Substract End - Start time

    if [ "$epoch_elapse" = "" ] ; then epoch_elapse=0 ; fi              # If nb Sec Greater than 1Hr
    whour=00 ; wmin=00 ; wsec=00

    # Calculate number of hours (1 hr = 3600 Seconds)
    if [ "$epoch_elapse" -gt 3599 ]                                     # If nb Sec Greater than 1Hr
        then whour=`echo "$epoch_elapse / 3600" | $SADM_BC`             # Calculate nb of Hours
             epoch_elapse=`echo "$epoch_elapse - ($whour * 3600)" | $SADM_BC` # Sub Hr*Sec from elapse
    fi
    
    # Calculate number of minutes 1 Min = 60 Seconds)
    if [ "$epoch_elapse" -gt 59 ]                                       # If more than 1 min left
       then  wmin=`echo "$epoch_elapse / 60" | $SADM_BC`                # Calc. Nb of minutes
             epoch_elapse=`echo  "$epoch_elapse - ($wmin * 60)" | $SADM_BC` # Sub Min*Sec from elapse
    fi

    wsec=$epoch_elapse                                                  # left is less than 60 sec
    sadm_elapse=`printf "%02d:%02d:%02d" ${whour} ${wmin} ${wsec}`      # Format Result
    echo "$sadm_elapse"                                                 # Return Result to caller
}



# --------------------------------------------------------------------------------------------------
#                THIS FUNCTION DETERMINE THE OS (DISTRIBUTION) VERSION NUMBER 
# --------------------------------------------------------------------------------------------------
sadm_get_osversion() {
    wosversion="0.0"                                                    # Default Value
    case "$(sadm_get_ostype)" in                                            
        "LINUX")    wosversion=`$SADM_LSB_RELEASE -sr`                  # Use lsb_release to Get Ver
                    ;; 
        "AIX")      wosversion="`uname -v`.`uname -r`"                  # Get Aix Version 
                    ;;
        "DARWIN")   wosversion=`sw_vers -productVersion`                # Get O/S Version on MacOS
                    ;;   
    esac
    echo "$wosversion"
}

# --------------------------------------------------------------------------------------------------
#                            RETURN THE OS (DISTRIBUTION) MAJOR VERSION
# --------------------------------------------------------------------------------------------------
sadm_get_osmajorversion() {
    case "$(sadm_get_ostype)" in
        "LINUX")    wosmajorversion=`echo $(sadm_get_osversion) | awk -F. '{ print $1 }'| tr -d ' '`
                    ;;
        "AIX")      wosmajorversion=`uname -v`
                    ;;
        "DARWIN")   wosmajorversion=`sw_vers -productVersion | awk -F '.' '{print $1 "." $2}'`
                    ;;                 
    esac
    echo "$wosmajorversion"
}


# --------------------------------------------------------------------------------------------------
#                            RETURN THE OS (DISTRIBUTION) MINOR VERSION
# --------------------------------------------------------------------------------------------------
sadm_get_osminorversion() {
    case "$(sadm_get_ostype)" in
        "LINUX")    wosminorversion=`echo $(sadm_get_osversion) | awk -F. '{ print $2 }'| tr -d ' '`
                    ;;
        "AIX")      wosminorversion=`uname -r`
                    ;;
        "DARWIN")   wosminorversion=`sw_vers -productVersion | awk -F '.' '{print $3 }'`
                    ;;
    esac
    echo "$wosminorversion"
}

# --------------------------------------------------------------------------------------------------
#                RETURN THE OS TYPE (LINUX, AIX) -- ALWAYS RETURNED IN UPPERCASE
# --------------------------------------------------------------------------------------------------
sadm_get_ostype() {
    sadm_get_ostype=`uname -s | tr '[:lower:]' '[:upper:]'`     # OS Name (AIX/LINUX/DARWIN/SUNOS)           
    echo "$sadm_get_ostype"
}


# --------------------------------------------------------------------------------------------------
#                             RETURN THE OS PROJECT CODE NAME
# --------------------------------------------------------------------------------------------------
sadm_get_oscodename() {
    case "$(sadm_get_ostype)" in
        "DARWIN")   wver="$(sadm_get_osmajorversion)"                   # Default is OX Version
                    if [ "$wver"  = "10.0" ]  ; then woscodename="Cheetah"          ;fi
                    if [ "$wver"  = "10.1" ]  ; then woscodename="Puma"             ;fi
                    if [ "$wver"  = "10.2" ]  ; then woscodename="Jaguar"           ;fi
                    if [ "$wver"  = "10.3" ]  ; then woscodename="Panther"          ;fi
                    if [ "$wver"  = "10.4" ]  ; then woscodename="Tiger"            ;fi
                    if [ "$wver"  = "10.5" ]  ; then woscodename="Leopard"          ;fi
                    if [ "$wver"  = "10.6" ]  ; then woscodename="Snow Leopard"     ;fi
                    if [ "$wver"  = "10.7" ]  ; then woscodename="Lion"             ;fi
                    if [ "$wver"  = "10.8" ]  ; then woscodename="Mountain Lion"    ;fi
                    if [ "$wver"  = "10.9" ]  ; then woscodename="Mavericks"        ;fi
                    if [ "$wver"  = "10.10" ] ; then woscodename="Yosemite"         ;fi
                    if [ "$wver"  = "10.11" ] ; then woscodename="El Capitan"       ;fi
                    if [ "$wver"  = "10.12" ] ; then woscodename="Sierra"           ;fi
                    if [ "$wver"  = "10.13" ] ; then woscodename="High Sierra"      ;fi
                    ;;
        "LINUX")    woscodename=`$SADM_LSB_RELEASE -sc`
                    ;;
        "AIX")      woscodename="IBM_AIX"
                    ;;
    esac
    echo "$woscodename"
}


# --------------------------------------------------------------------------------------------------
#                   RETURN THE OS  NAME (ALWAYS RETURNED IN UPPERCASE)
# --------------------------------------------------------------------------------------------------
sadm_get_osname() {
    case "$(sadm_get_ostype)" in
        "DARWIN")   wosname=`sw_vers -productName | tr -d ' '`
                    wosname=`echo $wosname | tr '[:lower:]' '[:upper:]'`
                    ;;
        "LINUX")    wosname=`$SADM_LSB_RELEASE -si | tr '[:lower:]' '[:upper:]'`
                    if [ "$wosname" = "REDHATENTERPRISESERVER" ] ; then wosname="REDHAT" ; fi
                    if [ "$wosname" = "REDHATENTERPRISEAS" ]     ; then wosname="REDHAT" ; fi
                    ;;
        "AIX")      wosname="AIX"
                    ;;
        *)          wosname="UNKNOWN"                    
                    ;;
    esac
    echo "$wosname"
}



# --------------------------------------------------------------------------------------------------
#                                 RETURN SADMIN RELEASE VERSION NUMBER
# --------------------------------------------------------------------------------------------------
sadm_get_release() {
    if [ -r "$SADM_REL_FILE" ]
        then wrelease=`cat $SADM_REL_FILE`
        else wrelease="00.00"
    fi
    echo "$wrelease"
}



# --------------------------------------------------------------------------------------------------
#                                 RETURN THE HOSTNAME (SHORT)
# --------------------------------------------------------------------------------------------------
sadm_get_hostname() {
    case "$(sadm_get_ostype)" in
        "AIX")      whostname=`hostname | awk -F. '{ print $1 }'`       # Get HostName
                    ;;
        *)          whostname=`hostname -s`                             # Get rid of domain name
                    ;;
    esac
    echo "$whostname"
}


# --------------------------------------------------------------------------------------------------
#                                 RETURN THE DOMAINNAME (SHORT)
# --------------------------------------------------------------------------------------------------
sadm_get_domainname() {
    case "$(sadm_get_ostype)" in
        "LINUX") wdomainname=`host ${SADM_HOSTNAME} |head -1 |awk '{ print $1 }' |cut -d. -f2-3` 
                 ;;
        "AIX")   wdomainname=`namerslv -s | grep domain | awk '{ print $2 }'`
                 ;;
    esac
    if [ "$wdomainname" = "" ] ; then wdomainname="$SADM_DOMAIN" ; fi
    echo "$wdomainname"
}



# --------------------------------------------------------------------------------------------------
#                        RETURN THE FULLY QUALIFIED NAME OF THE SYSTEM
# --------------------------------------------------------------------------------------------------
sadm_get_fqdn() {
    echo "${SADM_HOSTNAME}.$(sadm_get_domainname)"
}


# --------------------------------------------------------------------------------------------------
#                              RETURN THE IP OF THE CURRENT HOSTNAME
# --------------------------------------------------------------------------------------------------
sadm_get_host_ip() {
    case "$(sadm_get_ostype)" in
        "LINUX")    whost_ip=`host ${SADM_HOSTNAME} |awk '{ print $4 }' |head -1` 
                    ;;
        "AIX")      whost_ip=`host ${SADM_HOSTNAME}.$(sadm_get_domainname) |head -1 |awk '{ print $3 }'` 
                    ;;
        "DARWIN")   whost_ip=`ifconfig |grep inet | grep broadcast | awk '{ print $2 }'`
                    ;;
    esac    
    echo "$whost_ip"
}



# --------------------------------------------------------------------------------------------------
#                           Return The IPs of the current Hostname
# --------------------------------------------------------------------------------------------------
sadm_server_ips() {
    
    index=0 ; sadm_server_ips=""                                        # Init Variables at Start
    xfile="$SADM_TMP_DIR/sadm_ips_$$"                                   # IP Info Work File Name
    if [ -f "$xfile" ] ; then rm -f $xfile >/dev/null 2>&1 ;fi          # Make sure doesn't exist 
    
    case "$(sadm_get_ostype)" in
        "LINUX")    ip addr |grep 'inet ' |grep -v '127.0.0' |awk '{ printf "%s %s\n",$2,$NF }'>$xfile
                    while read sadm_wip                                 # Read IP one per line
                        do
                        if [ "$index" -ne 0 ]                           # Don't add ; for 1st IP
                            then sadm_servers_ips="${sadm_servers_ips}," # For others IP add ";"
                        fi
                        SADM_IP=`echo $sadm_wip |awk -F/ '{ print $1 }'` # Get IP Address 
                        SADM_MASK_NUM=`echo $sadm_wip |awk -F/ '{ print $2 }' |awk '{ print $1 }'`
                        SADM_IF=`echo $sadm_wip | awk '{ print $2 }'`   # Get Interface Name
                        if [ "$SADM_MASK_NUM" = "1"  ] ; then SADM_MASK="128.0.0.0"        ; fi
                        if [ "$SADM_MASK_NUM" = "2"  ] ; then SADM_MASK="192.0.0.0"        ; fi
                        if [ "$SADM_MASK_NUM" = "3"  ] ; then SADM_MASK="224.0.0.0"        ; fi
                        if [ "$SADM_MASK_NUM" = "4"  ] ; then SADM_MASK="240.0.0.0"        ; fi
                        if [ "$SADM_MASK_NUM" = "5"  ] ; then SADM_MASK="248.0.0.0"        ; fi
                        if [ "$SADM_MASK_NUM" = "6"  ] ; then SADM_MASK="252.0.0.0"        ; fi
                        if [ "$SADM_MASK_NUM" = "7"  ] ; then SADM_MASK="254.0.0.0"        ; fi
                        if [ "$SADM_MASK_NUM" = "8"  ] ; then SADM_MASK="255.0.0.0"        ; fi
                        if [ "$SADM_MASK_NUM" = "9"  ] ; then SADM_MASK="255.128.0.0"      ; fi
                        if [ "$SADM_MASK_NUM" = "10" ] ; then SADM_MASK="255.192.0.0"      ; fi
                        if [ "$SADM_MASK_NUM" = "11" ] ; then SADM_MASK="255.224.0.0"      ; fi
                        if [ "$SADM_MASK_NUM" = "12" ] ; then SADM_MASK="255.240.0.0"      ; fi
                        if [ "$SADM_MASK_NUM" = "13" ] ; then SADM_MASK="255.248.0.0"      ; fi
                        if [ "$SADM_MASK_NUM" = "14" ] ; then SADM_MASK="255.252.0.0"      ; fi
                        if [ "$SADM_MASK_NUM" = "15" ] ; then SADM_MASK="255.254.0.0"      ; fi
                        if [ "$SADM_MASK_NUM" = "16" ] ; then SADM_MASK="255.255.0.0"      ; fi
                        if [ "$SADM_MASK_NUM" = "17" ] ; then SADM_MASK="255.255.128.0"    ; fi
                        if [ "$SADM_MASK_NUM" = "18" ] ; then SADM_MASK="255.255.192.0"    ; fi
                        if [ "$SADM_MASK_NUM" = "19" ] ; then SADM_MASK="255.255.224.0"    ; fi
                        if [ "$SADM_MASK_NUM" = "20" ] ; then SADM_MASK="255.255.240.0"    ; fi
                        if [ "$SADM_MASK_NUM" = "21" ] ; then SADM_MASK="255.255.248.0"    ; fi
                        if [ "$SADM_MASK_NUM" = "22" ] ; then SADM_MASK="255.255.252.0"    ; fi
                        if [ "$SADM_MASK_NUM" = "23" ] ; then SADM_MASK="255.255.254.0"    ; fi
                        if [ "$SADM_MASK_NUM" = "24" ] ; then SADM_MASK="255.255.255.0"    ; fi
                        if [ "$SADM_MASK_NUM" = "25" ] ; then SADM_MASK="255.255.255.128"  ; fi
                        if [ "$SADM_MASK_NUM" = "26" ] ; then SADM_MASK="255.255.255.192"  ; fi
                        if [ "$SADM_MASK_NUM" = "27" ] ; then SADM_MASK="255.255.255.224"  ; fi
                        if [ "$SADM_MASK_NUM" = "28" ] ; then SADM_MASK="255.255.255.240"  ; fi
                        if [ "$SADM_MASK_NUM" = "29" ] ; then SADM_MASK="255.255.255.248"  ; fi
                        if [ "$SADM_MASK_NUM" = "30" ] ; then SADM_MASK="255.255.255.252"  ; fi
                        if [ "$SADM_MASK_NUM" = "31" ] ; then SADM_MASK="255.255.255.254"  ; fi
                        if [ "$SADM_MASK_NUM" = "32" ] ; then SADM_MASK="255.255.255.255"  ; fi
                        SADM_MAC=`ip addr show ${SADM_IF} | grep 'link' |head -1 | awk '{ print $2 }'` 
                        sadm_servers_ips="${sadm_servers_ips}${SADM_IF}|${SADM_IP}|${SADM_MASK}|${SADM_MAC}" 
                        index=`expr $index + 1`                         # Increment Index by 1
                        done < $xfile                                   # Read IP From Generated File
                    rm -f $xfile > /dev/null 2>&1    # Remove TMP IP File Output
                    ;;
        "AIX")      rm -f $xfile > /dev/null 2>&1    # Del TMP file - Make sure
                    ifconfig -a | grep 'flags' | grep -v 'lo0:' | awk -F: '{ print $1 }' >$xfile
                    while read sadm_wip                                 # Read IP one per line
                        do
                        if [ "$index" -ne 0 ]                           # Don't add ; for 1st IP
                            then sadm_servers_ips="${sadm_servers_ips},"# For others IP add ";"
                        fi
                        SADM_IP=`ifconfig $sadm_wip |grep inet |awk '{ print $2 }'` # Get IP Address 
                        SADM_MASK=`lsattr -El $sadm_wip | grep -i netmask | awk '{ print $2 }'` 
                        SADM_IF="$sadm_wip"                             # Get Interface Name
                        SADM_MAC=`entstat -d $sadm_wip | grep 'Hardware Address:' | awk  '{  print $3 }'`
                        sadm_servers_ips="${sadm_servers_ips}${SADM_IF}|${SADM_IP}|${SADM_MASK}|${SADM_MAC}" 
                        index=`expr $index + 1`                         # Increment Index by 1
                        done < $xfile                                   # Read IP From Generated File
                    ;;
        "DARWIN")   FirstTime=0 
                    while [ $index -le 10 ]                             # Process from en0 to en9
                        do
                        ipconfig getpacket en${index} >$xfile 2>&1      # Get Info about Interface 
                        if [ $? -eq 0 ]                                 # If Device in use
                            then SADM_IP=`ipconfig getifaddr en${index} | tr -d '\n'` 
                                 SADM_MASK=`ipconfig getpacket en${index} |grep subnet_mask |awk '{ print $3 }'`
                                 SADM_IF="en${index}"                   # Set Interface Name
                                 SADM_MAC=`ipconfig getpacket en${index} | grep chaddr | awk '{ print $3 }'` 
                                 NEWIP="${SADM_IF}|${SADM_IP}|${SADM_MASK}|${SADM_MAC}" 
                                 if [ "$FirstTime" -eq 0 ]              # If First IP to be Added             
                                     then sadm_servers_ips="${NEWIP}"   # List of IP = New Ip
                                          FirstTime=1                   # No More the first Time
                                     else sadm_servers_ips="${sadm_servers_ips},${NEWIP}"
                                 fi
                        fi 
                        index=$((index + 1))
                        done
                    ;;
    esac 
    if [ -f "$xfile" ] ; then rm -f $xfile >/dev/null 2>&1  ; fi        # Del. WorkFile before exit                 
    echo "$sadm_servers_ips"
}


# --------------------------------------------------------------------------------------------------
#                    Return a "P" if server is physical and "V" if it is Virtual
# --------------------------------------------------------------------------------------------------
sadm_server_type() {
    case "$(sadm_get_ostype)" in
        "LINUX")    if [ "$SADM_FACTER" != "" ]                         # If facter is installed
                       then W=`facter |grep is_virtual |awk '{ print $3 }'`   # Get VM True or False
                            if [ "$W" = "false" ] 
                                then sadm_server_type="P" 
                                else sadm_server_type="V" 
                            fi
                            break
                    fi
                    if [ "$SADM_DMIDECODE" != "" ]
                        then $SADM_DMIDECODE |grep -i vmware >/dev/null 2>&1    # Search vmware in dmidecode
                             if [ $? -eq 0 ]                                     # If vmware was found
                                 then sadm_server_type="V"                       # If VMware Server
                                 else sadm_server_type="P"                       # Default Assume Physical
                             fi
                    fi 
                    ;;
        "AIX")      sadm_server_type="P"                                # Default Assume Physical
                    ;;        
        "DARWIN")   sadm_server_type="P"                                # Default Assume Physical
                    ;;
    esac
    echo "$sadm_server_type"
}




# --------------------------------------------------------------------------------------------------
#                               RETURN THE MODEL OF THE SERVER
# --------------------------------------------------------------------------------------------------
sadm_server_model() {
    case "$(sadm_get_ostype)" in
        "LINUX") sadm_sm=`${SADM_DMIDECODE} |grep -i "Product Name:" |head -1 |awk -F: '{print $2}'`
                 sadm_sm=`echo ${sadm_sm}| sed 's/ProLiant//'`
                 sadm_sm=`echo ${sadm_sm}|sed -e 's/^[ \t]*//' |sed 's/^[ \t]*//;s/[ \t]*$//' `
                 sadm_server_model="${sadm_sm}"
                 if [ "$(sadm_server_type)" = "V" ]
                     then sadm_server_model="VM"
                     else grep -i '^revision' /proc/cpuinfo > /dev/null 2>&1
                          if [ $? -eq 0 ]
                            then wrev=`grep -i '^revision' /proc/cpuinfo |cut -d ':' -f 2)` 
                                 wrev=`echo $wrev | sed -e 's/^[ \t]*//'` #Del Lead Space
                                 sadm_server_model="Raspberry Rev.${wrev}"
                          fi
                 fi
                 ;;
        "AIX")   sadm_server_model=`uname -M | sed 's/IBM,//'`
                 ;;
       "DARWIN") syspro="system_profiler SPHardwareDataType" 
                 sadm_server_model=`$syspro |grep 'Ident' |awk -F: '{ print $2 }' |tr -d ' '`
                 ;;
    esac
    echo "$sadm_server_model"
}


# --------------------------------------------------------------------------------------------------
#                             RETURN THE SERVER SERIAL NUMBER
# --------------------------------------------------------------------------------------------------
sadm_server_serial() {
    case "$(sadm_get_ostype)" in
        "LINUX")    if [ "$(sadm_server_type)" = "V" ]                  # If Virtual Machine
                        then wserial=" "                                # VM as no serial 
                        else wserial=`${SADM_DMIDECODE} |grep "Serial Number" |head -1 |awk '{ print $3 }'`
                            if [ -r /proc/cpuinfo ]                     # Serial in cpuinfo (raspi)
                                then grep -i serial /proc/cpuinfo > /dev/null 2>&1
                                     if [ $? -eq 0 ]                    # If Serial found in cpuinfo
                                        then wserial="$(grep -i Serial /proc/cpuinfo |cut -d ':' -f 2)"
                                             wserial=`echo $wserial | sed -e 's/^[ \t]*//'` #Del Lead Space
                                     fi
                            fi
                    fi 
                    ;;
        "AIX")      wserial=`uname -u | awk -F, '{ print $2 }'`
                    ;;
        "DARWIN")   syspro="system_profiler SPHardwareDataType" 
                    wserial=`$syspro |grep -i 'Serial' |awk -F: '{ print $2 }' |tr -d ' '`
                    ;;
    esac
    echo "$wserial"
}


# --------------------------------------------------------------------------------------------------
#                     RETURN THE SERVER AMOUNT OF PHYSICAL MEMORY IN MB
# --------------------------------------------------------------------------------------------------
sadm_server_memory() {
    case "$(sadm_get_ostype)" in
        "LINUX")    sadm_server_memory=`grep -i "memtotal:" /proc/meminfo | awk '{ print $2 }'`
                    sadm_server_memory=`echo "$sadm_server_memory / 1024" | bc`
                    ;;
        "AIX")      sadm_server_memory=`bootinfo -r`
                    sadm_server_memory=`echo "${sadm_server_memory} /1024" | $SADM_BC` 
                    ;;
        "DARWIN")   sadm_server_memory=`sysctl hw.memsize | awk '{ print $2 }'`
                    sadm_server_memory=`echo "${sadm_server_memory} /1048576" | $SADM_BC` 
                    ;;
    esac
    echo "$sadm_server_memory"
}


# --------------------------------------------------------------------------------------------------
#                             RETURN THE SERVER NUMBER OF PHYSICAL CPU
# --------------------------------------------------------------------------------------------------
sadm_server_nb_cpu() { 
    case "$(sadm_get_ostype)" in
        "LINUX")    wnbcpu=`grep '^physical id' /proc/cpuinfo| sort -u | wc -l| tr -d ' '`
                    if [ $wnbcpu -eq 0 ] ; then wnbcpu=1 ; fi
                    ;;
        "AIX")      wnbcpu=`lsdev -C -c processor | wc -l | tr -d ' '`
                    ;;
        "DARWIN")   syspro="system_profiler SPHardwareDataType" 
                    wnbcpu=`$syspro | grep "Number of Processors"| awk -F: '{print$2}' | tr -d ' '`
                    #wnbcpu=`sysctl -n hw.ncpu`
                    ;;
    esac
    echo "$wnbcpu"
}

 
# --------------------------------------------------------------------------------------------------
#                             RETURN THE SERVER NUMBER OF LOGICAL CPU
# --------------------------------------------------------------------------------------------------
sadm_server_nb_logical_cpu() { 
    case "$(sadm_get_ostype)" in
        "LINUX")    wlcpu=`nproc --all`
                    if [ $wlcpu -eq 0 ] ; then wlcpu=1 ; fi
                    ;;
        "AIX")      wlcpu=`lsdev -C -c processor | wc -l | tr -d ' '`
                    ;;        
        "DARWIN")   wlcpu=`sysctl -n hw.logicalcpu`
                    ;;
    esac
    echo "$wlcpu"
}


# --------------------------------------------------------------------------------------------------
#                                   Return the CPU Speed in Mhz
# --------------------------------------------------------------------------------------------------
sadm_server_cpu_speed() { 
    case "$(sadm_get_ostype)" in
        "LINUX") 
                 if [ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq ]
                    then freq=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq)
                         sadm_server_cpu_speed=`echo "$freq / 1000" | $SADM_BC `
                    else sadm_server_cpu_speed=`cat /proc/cpuinfo | grep -i "cpu MHz" | tail -1 | awk -F: '{ print $2 }'`
                         sadm_server_cpu_speed=`echo "$sadm_server_cpu_speed / 1" | $SADM_BC`
                         #if [ "$sadm_server_cpu_speed" -gt 1000 ]
                         #   then sadm_server_cpu_speed=`expr $sadm_server_cpu_speed / 1000`
                         #fi
                 fi
                 ;;
        "AIX")   sadm_server_cpu_speed=`pmcycles -m | awk '{ print $5 }'`
                 ;;
        "DARWIN")   syspro="system_profiler SPHardwareDataType" 
                    w=`$syspro | grep -i "Speed" | awk -F: '{print $2}'|awk '{print$1}'` 
                    sadm_server_cpu_speed=`echo "$w * 1000 / 1" | $SADM_BC`
                    ;;
    esac
    echo "$sadm_server_cpu_speed"
}


# --------------------------------------------------------------------------------------------------
#                         Return the Server Number of Core per Socket
# --------------------------------------------------------------------------------------------------
sadm_server_core_per_socket() {
    case "$(sadm_get_ostype)" in
       "LINUX")     wcps=`cat /proc/cpuinfo |egrep "core id|physical id" |tr -d "\n" |sed s/physical/\\nphysical/g |grep -v ^$ |sort |uniq |wc -l`
                    if [ "$wcps" -eq 0 ] ;then wcps=1 ; fi
                    if [ "$SADM_LSCPU" != "" ]
                        then wcps=`$SADM_LSCPU | grep -i '^core(s) per socket' | cut -d ':' -f 2 | tr -d ' '`
                    fi
                    ;;
        "AIX")      wcps=1
                    ;;
        "DARWIN")   syspro="system_profiler SPHardwareDataType" 
                    wcps=`$syspro | grep -i "Number of Cores"| awk -F: '{print$2}' | tr -d ' '`
                    ;;
    esac
    echo "$wcps"
}


# --------------------------------------------------------------------------------------------------
#                       RETURN THE SERVER NUMBER OF THREAD(S) PER CORE
# --------------------------------------------------------------------------------------------------
sadm_server_thread_per_core() { 
    case "$(sadm_get_ostype)" in
        "LINUX")    sadm_wht=`cat /proc/cpuinfo |grep -E "cpu cores|siblings|physical id" |xargs -n 11 echo |sort |uniq |head -1`
                    sadm_sibbling=`echo $sadm_wht | awk -F: '{ print $3 }' | awk '{ print $1 }'`
                    if [ -z "$sadm_sibbling" ] ; then sadm_sibbling=0 ; fi
                    sadm_cores=`echo $sadm_wht | awk -F: '{ print $4 }' | tr -d ' '`
                    if [ -z "$sadm_cores" ] ; then sadm_cores=0 ; fi
                    if [ "$sadm_sibbling" -gt 0 ] && [ "$sadm_cores" -gt 0 ]
                        then sadm_server_thread_per_core=`echo "$sadm_sibbling / $sadm_cores" | bc`
                        else sadm_server_thread_per_core=1
                    fi
                    if [ "$SADM_LSCPU" != "" ]
                        then wnbcpu=`$SADM_LSCPU | grep -i '^thread' | cut -d ':' -f 2 | tr -d ' '`
                    fi
                    ;;
        "AIX")      sadm_server_thread_per_core=1
                    ;;
        "DARWIN")   w=`sysctl -n machdep.cpu.thread_count` 
                    sadm_server_thread_per_core=`echo "$w / $(sadm_server_core_per_socket) " | $SADM_BC`
                    ;;
    esac
    echo "$sadm_server_thread_per_core"
}

# --------------------------------------------------------------------------------------------------
#                             RETURN THE SERVER NUMBER OF CPU SOCKET
# --------------------------------------------------------------------------------------------------
sadm_server_nb_socket() { 
    case "$(sadm_get_ostype)" in
       "LINUX")     wns=`cat /proc/cpuinfo | grep "physical id" | sort | uniq | wc -l`
                    if [ "$SADM_LSCPU" != "" ]
                        then wns=`$SADM_LSCPU | grep -i '^Socket(s)' | cut -d ':' -f 2 | tr -d ' '`
                    fi
                    ;;
        "AIX")      wns=`lscfg -vpl sysplanar0 | grep WAY | wc -l | tr -d ' '`
                    ;;
        "DARWIN")   wns=1
                    ;;    
    esac
    if [ "$wns" -eq 0 ] ; then wns=1 ; fi
    echo "$wns"
}


# --------------------------------------------------------------------------------------------------
#                     Return 32 or 64 Bits Depending of CPU Hardware Capability
# --------------------------------------------------------------------------------------------------
sadm_server_hardware_bitmode() { 
    case "$(sadm_get_ostype)" in
        "LINUX")   sadm_server_hardware_bitmode=`grep -o -w 'lm' /proc/cpuinfo | sort -u`
                   if [ "$sadm_server_hardware_bitmode" = "lm" ]
                       then sadm_server_hardware_bitmode=64
                       else sadm_server_hardware_bitmode=32
                   fi
                   ;;
        "AIX")     sadm_server_hardware_bitmode=`bootinfo -y`
                   ;;
        "DARWIN")  sadm_server_hardware_bitmode=64
                   ;;
    esac
    echo "$sadm_server_hardware_bitmode"
}


# --------------------------------------------------------------------------------------------------
#                     Return if running 32 or 64 Bits Kernel version
# --------------------------------------------------------------------------------------------------
sadm_get_kernel_bitmode() { 
    case "$(sadm_get_ostype)" in
        "LINUX")   wkernel_bitmode=`getconf LONG_BIT`
                   ;;
        "AIX")     wkernel_bitmode=`getconf KERNEL_BITMODE`
                   ;;
         "DARWIN") wkernel_bitmode=64
                   ;; 
    esac
    echo "$wkernel_bitmode"
}



# --------------------------------------------------------------------------------------------------
#                                 RETURN KERNEL RUNNING VERSION
# --------------------------------------------------------------------------------------------------
sadm_get_kernel_version() {
    case "$(sadm_get_ostype)" in
        "LINUX")    #wkernel_version=`uname -r | cut -d. -f1-3`
                    wkernel_version=`uname -r`
                    ;;
        "AIX")      wkernel_version=`uname -r`
                    ;;
        *)          wkernel_version=`uname -r`
                    ;;
    esac
    echo "$wkernel_version"
}



# --------------------------------------------------------------------------------------------------
#    FUNCTION RETURN A STRING CONTAINING DISKS NAMES AND CAPACITY (MB) OF EACH DISKS
#
#    Example :  sda:65536;sdb:17408;sdc:17408;sdd:104
#        EACH DISK NAME IS FOLLOWED BY THE DISK CAPACITY IN MB,  SEPERATED BY A ":"
#        IF THEY ARE MULTIPLE DISKS ON THE SERVER EACH DISK INFO IS SEPARATED BY A ";"
# --------------------------------------------------------------------------------------------------
sadm_server_disks() {
    index=0 ; output_line=""                                            # Init Variables
    case "$(sadm_get_ostype)" in
        "LINUX") STMP="/tmp/sadm_server_disk_$$.txt"                    # Name TMP Working file

                 # Cannot Get Info under RedHat/CentOS 3 and 4 - Unsuported
                 SOSNAME=$(sadm_get_osname) ; SOSVER=$(sadm_get_osmajorversion)
                 #echo "SOSNAME = $SOSNAME , SOSVER = $SOSVER"
                 if (([ $SOSNAME = "CENTOS" ] || [ $SOSNAME = "REDHAT" ]) && ([ $SOSVER -lt 5 ]))
                    then echo "O/S Version not Supported - To get disk Name/Size "      >$STMP
                    else $SADM_PARTED -l | grep "^Disk" | grep -vE "mapper|Disk Flags:" >$STMP
                 fi
                         
                 while read xline                                       # Read Each disks line
                    do
                    if [ "$index" -ne 0 ]                               # Don't add , for 1st Disk
                        then output_line="${output_line},"              # For others disks add ","
                    fi
                    # Get the Disk Name
                    dname=`echo $xline| awk '{ print $2 }'| awk -F/ '{ print $3 }'| tr -d ':'`

                    # Get Disk Size
                    dsize=`echo $xline | awk '{ print $3 }' | awk '{print substr($0,1,length-2)}'`            # Get Disk Size on Line

                    # Get Size Unit (GB,MB,TB)
                    disk_unit=`echo $xline | awk '{ print $3 }' | awk '{print substr($0,length-1,2)}'`
                    disk_unit=`sadm_toupper $disk_unit`                 # Make sure is in Uppercase
                    
                    # Convert Disk Size in MB if needed
                    if [ "$disk_unit" = "GB" ]                          # If GB Unit
                       then dsize=`echo "($dsize * 1024) / 1" | $SADM_BC`  # Convert GB into MB 
                    fi
                    if [ "$disk_unit" = "MB" ]                          # if MB Unit
                       then dsize=`echo "$dsize * 1"| $SADM_BC`         # If MB Get Rid of Decimal
                    fi
                    if [ "$disk_unit" = "TB" ] 
                       then dsize=`echo "(($dsize*1024)*1024)/1"| $SADM_BC` # Convert GB into MB 
                    fi
                    
                    output_line="${output_line}${dname}|${dsize}"       # Combine Disk Name & Size
                    index=`expr $index + 1`                             # Increment Index by 1
                    done < $STMP
                 rm -f $STMP> /dev/null 2>&1                            # Remove Temp File
                 ;;
        "AIX")   for wdisk in `find /dev -name "hdisk*"`
                     do
                     if [ "$index" -ne 0 ] ; then output_line="${output_line}," ; fi
                     sadm_dname=`basename $wdisk`
                     sadm_dsize=`getconf DISK_SIZE ${wdisk}` 
                     output_line="${output_line}${sadm_dname}|${sadm_dsize}"
                     index=`expr $index + 1`                                    
                     done 
                 ;;
    esac
    echo "$output_line"                                                      
}




# --------------------------------------------------------------------------------------------------
#       Return  String containing all VG names, VG capacity and VG Free Spaces in (MB)
# --------------------------------------------------------------------------------------------------
#    Example :  datavg:16373:10250:6123;datavg_sdb:16373:4444:11929;rootvg:57088:49859:7229
#               Each VG name is followed by the VGSize, VGUsed and VGFree space in MB
#               If they are multiple disks on the server each disk info is separated by a ";"
# --------------------------------------------------------------------------------------------------
sadm_server_vg() {
    index=0 ; sadm_server_vg=""                                         # Init Variables at Start
    rm -f $SADM_TMP_DIR/sadm_vg_$$ > /dev/null 2>&1                          # Del TMP file - Make sure
    case "$(sadm_get_ostype)" in
        "LINUX") ${SADM_WHICH} vgs >/dev/null 2>&1
                 if [ $? -eq 0 ]
                    then vgs --noheadings -o vg_name,vg_size,vg_free | tr -d '<' >$SADM_TMP_DIR/sadm_vg_$$ 2>/dev/null
                         while read sadm_wvg                                                 # Read VG one per line
                            do
                            if [ "$index" -ne 0 ]                                           # Don't add ; for 1st VG
                                then sadm_server_vg="${sadm_server_vg},"                    # For others VG add ";"
                            fi    
                            sadm_vg_name=`echo ${sadm_wvg} | awk '{ print $1 }'`            # Save VG Name
                            sadm_vg_size=`echo ${sadm_wvg} | awk '{ print $2 }'`            # Get VGSize from vgs output
                            if $(echo $sadm_vg_size | grep -i 'g' >/dev/null 2>&1)             # If Size Specified in GB
                                then sadm_vg_size=`echo $sadm_vg_size | sed 's/g//' |sed 's/G//'`        # Get rid of "g" in size
                                     sadm_vg_size=`echo "($sadm_vg_size * 1024) / 1" | $SADM_BC` # Convert in MB
                                else sadm_vg_size=`echo $sadm_vg_size | sed 's/m//'`        # Get rid of "m" in size
                                     sadm_vg_size=`echo "$sadm_vg_size / 1" | $SADM_BC`     # Get rid of decimal
                            fi
                            sadm_vg_free=`echo ${sadm_wvg} | awk '{ print $3 }'`            # Get VGFree from vgs ouput
                            if $(echo $sadm_vg_free | grep -i 'g' >/dev/null 2>&1)             # If Size Specified in GB
                                then sadm_vg_free=`echo $sadm_vg_free | sed 's/g//' |sed 's/G//'|sed 's/M//'`        # Get rid of "g" in size
                                     sadm_vg_free=`echo "($sadm_vg_free * 1024) / 1" | $SADM_BC`  # Convert in MB
                                else sadm_vg_free=`echo $sadm_vg_free | sed 's/m//' |sed 's/M//'`        # Get rid of "m" in size
                                     sadm_vg_free=`echo "$sadm_vg_free / 1" | $SADM_BC`     # Get rid of decimal
                            fi
                            sadm_vg_used=`expr ${sadm_vg_size} - ${sadm_vg_free}`           # Calculate VG Used MB 
                            sadm_server_vg="${sadm_server_vg}${sadm_vg_name}|${sadm_vg_size}|${sadm_vg_used}|${sadm_vg_free}"
                            index=`expr $index + 1`                                         # Increment Index by 1
                            done < $SADM_TMP_DIR/sadm_vg_$$                                          # Read VG From Generated File
                 fi
                 ;;
        "AIX")   lsvg > $SADM_TMP_DIR/sadm_vg_$$
                 while read sadm_wvg
                    do
                    if [ "$index" -ne 0 ] ; then sadm_server_vg="${sadm_server_vg}," ;fi
                    sadm_vg_name="$sadm_wvg"
                    sadm_vg_size=`lsvg $sadm_wvg |grep 'TOTAL PPs:' |awk -F: '{print $3}' |awk -F"(" '{print $2}'|awk '{print $1}'`
                    sadm_vg_free=`lsvg $sadm_wvg |grep 'FREE PPs:'  |awk -F: '{print $3}' |awk -F"(" '{print $2}'|awk '{print $1}'`
                    sadm_vg_used=`lsvg $sadm_wvg |grep 'USED PPs:'  |awk -F: '{print $3}' |awk -F"(" '{print $2}'|awk '{print $1}'`
                    sadm_server_vg="${sadm_server_vg}${sadm_vg_name}|${sadm_vg_size}|${sadm_vg_used}|${sadm_vg_free}"
                    index=`expr $index + 1`                                         # Increment Index by 1
                    done < $SADM_TMP_DIR/sadm_vg_$$ 
                ;;
    esac
    
    rm -f $SADM_TMP_DIR/sadm_vg_$$ > /dev/null 2>&1                          # Remove TMP VG File Output
    echo "$sadm_server_vg"                                              # Return VGInfo to caller
}





# --------------------------------------------------------------------------------------------------
#            LOAD SADMIN CONFIGURATION FILE AND SET GLOBAL VARIABLES ACCORDINGLY
# --------------------------------------------------------------------------------------------------
sadm_load_config_file() {

    # SADMIN Configuration file MUST be present.
    # If not, then create sadmin.cfg from .sadmin.cfg.
    if [ ! -r "$SADM_CFG_FILE" ]                                        # If $SADMIN/cfg/sadmin.cfg
        then if [ ! -r "$SADM_CFG_HIDDEN" ]                             # Initial Cfg file not exist
                then echo "****************************************************************"
                     echo "SADMIN Configuration file not found - $SADM_CFG_FILE "
                     echo "Even the config template file can't be found - $SADM_CFG_HIDDEN"
                     echo "Copy both files from another system to this server"
                     echo "Or restore the files from a backup"
                     echo "Don't forget to review the file content."
                     echo "****************************************************************"
                     sadm_stop 1                                        # Exit to O/S with Error
                else echo "****************************************************************"
                     echo "SADMIN configuration file $SADM_CFG_FILE doesn't exist."
                     echo "Will continue using template configuration file $SADM_CFG_HIDDEN"
                     echo "Please review the configuration file ($SADM_CFG_FILE)."
                     echo "cp $SADM_CFG_HIDDEN $SADM_CFG_FILE"          # Install Initial cfg file
                     cp $SADM_CFG_HIDDEN $SADM_CFG_FILE                 # Install Default cfg file
                     echo "****************************************************************"
             fi
    fi
    
    
    # Loop for reading the sadmin configuration file
    while read wline 
        do
        FC=`echo $wline | cut -c1`
        if [ "$FC" = "#" ] || [ ${#wline} -eq 0 ] ; then continue ; fi
        #
        echo "$wline" |grep -i "^SADM_MAIL_ADDR" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_MAIL_ADDR=`echo "$wline"     | cut -d= -f2 |tr -d ' '` ; fi
        #
        echo "$wline" |grep -i "^SADM_CIE_NAME" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_CIE_NAME=`echo "$wline" |cut -d= -f2 |sed -e 's/^[ \t]*//'` ;fi
        #
        echo "$wline" |grep -i "^SADM_ALERT_TYPE" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_ALERT_TYPE=`echo "$wline"    |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_ALERT_GROUP" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_ALERT_GROUP=`echo "$wline"   |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_SERVER" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_SERVER=`echo "$wline"        |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_HOST_TYPE" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_HOST_TYPE=`echo "$wline"     |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_DOMAIN" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_DOMAIN=`echo "$wline"        |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_USER" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_USER=`echo "$wline"          |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_GROUP" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_GROUP=`echo "$wline"         |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_WWW_USER" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_WWW_USER=`echo "$wline"      |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_WWW_GROUP" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_WWW_GROUP=`echo "$wline"     |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_MAX_LOGLINE" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_MAX_LOGLINE=`echo "$wline"   |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_MAX_RCHLINE" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_MAX_RCLINE=`echo "$wline"    |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_NMON_KEEPDAYS" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_NMON_KEEPDAYS=`echo "$wline" |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_RCH_KEEPDAYS" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_RCH_KEEPDAYS=`echo "$wline"  |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_LOG_KEEPDAYS" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_LOG_KEEPDAYS=`echo "$wline"  |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_DBNAME" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_DBNAME=`echo "$wline"        |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_DBHOST" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_DBHOST=`echo "$wline"        |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_DBPORT" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_DBPORT=`echo "$wline"        |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_RW_DBUSER" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_RW_DBUSER=`echo "$wline"     |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_RW_DBPWD" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_RW_DBPWD=`echo "$wline"      |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_RO_DBUSER" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_RO_DBUSER=`echo "$wline"     |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_RO_DBPWD" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_RO_DBPWD=`echo "$wline"      |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_SSH_PORT" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_SSH_PORT=`echo "$wline"      |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_RRDTOOL" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_RRDTOOL=`echo "$wline"       |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_BACKUP_NFS_SERVER" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_BACKUP_NFS_SERVER=`echo "$wline"  |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_BACKUP_NFS_MOUNT_POINT" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_BACKUP_NFS_MOUNT_POINT=`echo "$wline" |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_DAILY_BACKUP_TO_KEEP" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_DAILY_BACKUP_TO_KEEP=`echo "$wline" |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_WEEKLY_BACKUP_TO_KEEP" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_WEEKLY_BACKUP_TO_KEEP=`echo "$wline" |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_MONTHLY_BACKUP_TO_KEEP" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_MONTHLY_BACKUP_TO_KEEP=`echo "$wline" |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_YEARLY_BACKUP_TO_KEEP" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_YEARLY_BACKUP_TO_KEEP=`echo "$wline" |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_WEEKLY_BACKUP_DAY" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_WEEKLY_BACKUP_DAY=`echo "$wline" |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_MONTHLY_BACKUP_DATE" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_MONTHLY_BACKUP_DATE=`echo "$wline"  |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_YEARLY_BACKUP_MONTH" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_YEARLY_BACKUP_MONTH=`echo "$wline"  |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_YEARLY_BACKUP_DATE" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_YEARLY_BACKUP_DATE=`echo "$wline"   |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_MKSYSB_NFS_SERVER" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_MKSYSB_NFS_SERVER=`echo "$wline"    |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_MKSYSB_NFS_MOUNT_POINT" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_MKSYSB_NFS_MOUNT_POINT=`echo "$wline" |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_MKSYSB_BACKUP_TO_KEEP" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_MKSYSB_BACKUP_TO_KEEP=`echo "$wline" |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_STORIX_NFS_SERVER" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_STORIX_NFS_SERVER=`echo "$wline"     |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_STORIX_NFS_MOUNT_POINT" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_STORIX_NFS_MOUNT_POINT=`echo "$wline" |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_STORIX_BACKUP_TO_KEEP" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_STORIX_BACKUP_TO_KEEP=`echo "$wline" |cut -d= -f2 |tr -d ' '` ;fi
        # 
        echo "$wline" |grep -i "^SADM_REAR_NFS_SERVER" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_REAR_NFS_SERVER=`echo "$wline" |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_REAR_NFS_MOUNT_POINT" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_REAR_NFS_MOUNT_POINT=`echo "$wline"  |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_REAR_BACKUP_TO_KEEP" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_REAR_BACKUP_TO_KEEP=`echo "$wline"  |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_NETWORK1" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_NETWORK1=`echo "$wline"  |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_NETWORK2" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_NETWORK2=`echo "$wline"  |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_NETWORK3" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_NETWORK3=`echo "$wline"  |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_NETWORK4" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_NETWORK4=`echo "$wline"  |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_NETWORK5" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_NETWORK5=`echo "$wline"  |cut -d= -f2 |tr -d ' '` ;fi
        #
        done < $SADM_CFG_FILE

    # Get Tead/Write and Read/Only User Password from pasword file (If on SADMIN Server)
    if [ "$(sadm_get_fqdn)" = "$SADM_SERVER" ] 
        then SADM_RW_DBPWD=`grep "^${SADM_RW_DBUSER}," $DBPASSFILE |awk -F, '{ print $2 }'` # RW PWD
             SADM_RO_DBPWD=`grep "^${SADM_RO_DBUSER}," $DBPASSFILE |awk -F, '{ print $2 }'` # RO PWD
        else SADM_RW_DBPWD="" 
             SADM_RO_DBPWD=""
    fi

    return 0
}



# --------------------------------------------------------------------------------------------------
#                   SADM INITIALIZE FUNCTION - EXECUTE BEFORE DOING ANYTHING
# What this function do.
#   1) Make sure All SADM Directories and sub-directories exist and they have proper permission
#   2) Make sure the log file exist with proper permission ($SADM_LOG)
#   3) Make sure the Return Code History Log exist and have the right permission
#   4) Create script PID file - If it exist and user want to run only 1 copy of script, then abort
#   5) Add line in the [R]eturn [C]ode [H]istory file stating script is started (Code 2 = Running)
#   6) Write HostName - Script name and version - O/S Name and version to the Log file ($SADM_LOG)
# --------------------------------------------------------------------------------------------------
#
sadm_start() {

    # ($SADMIN/log) If log Directory doesn't exist, create it.
    [ ! -d "$SADM_LOG_DIR" ] && mkdir -p $SADM_LOG_DIR
    if [ $(id -u) -eq 0 ] 
        then chmod 0775 $SADM_LOG_DIR ; chown ${SADM_USER}:${SADM_GROUP} $SADM_LOG_DIR 
    fi

    # ($SADMIN/log/`hostname -s`_SCRIPT.log) If LOG File doesn't exist, Create it & Make it writable 
    [ ! -e "$SADM_LOG" ] && touch $SADM_LOG
    if [ $(id -u) -eq 0 ] 
        then chmod 664 $SADM_LOG ; chown ${SADM_USER}:${SADM_GROUP} ${SADM_LOG}
    fi

    # If user don't want to append to existing log - Clear it - Else we will append to it.
    [ "$SADM_LOG_APPEND" != "Y" ] && echo " " > $SADM_LOG

    # Write Starting Info in the Log
    if [ -z "$SADM_LOG_HEADER" ] || [ "$SADM_LOG_HEADER" = "Y" ]        # Want to Produce Log Header
        then echo " " >>$SADM_LOG                                       # Blank line at beginning
             sadm_writelog "${SADM_80_DASH}"                            # Write 80 Dashes Line
             sadm_writelog "Starting ${SADM_PN} V${SADM_VER} - SADM Lib. V${SADM_LIB_VER}"
             sadm_writelog "Server Name: $(sadm_get_fqdn) - Type: $(sadm_get_ostype)" 
             sadm_writelog "$(sadm_get_osname) $(sadm_get_osversion) Kernel $(sadm_get_kernel_version)"
             sadm_writelog "${SADM_FIFTY_DASH}"                         # Write 50 Dashes Line
             sadm_writelog " "                                          # Write Blank line
    fi

    # ($SADMIN/tmp) If TMP Directory doesn't exist, create it.
    [ ! -d "$SADM_TMP_DIR" ] && mkdir -p $SADM_TMP_DIR
    if [ $(id -u) -eq 0 ] 
        then chmod 1777 $SADM_TMP_DIR ; chown ${SADM_USER}:${SADM_GROUP} $SADM_TMP_DIR
    fi

    # ($SADMIN/lib) If LIB Directory doesn't exist, create it.
    [ ! -d "$SADM_LIB_DIR" ] && mkdir -p $SADM_LIB_DIR
    if [ $(id -u) -eq 0 ] 
        then chmod 0775 $SADM_LIB_DIR ; chown ${SADM_USER}:${SADM_GROUP} $SADM_LIB_DIR
    fi

    # ($SADMIN/cfg) If Custom Configuration Directory doesn't exist, create it.
    [ ! -d "$SADM_CFG_DIR" ] && mkdir -p $SADM_CFG_DIR
    if [ $(id -u) -eq 0 ] 
        then chmod 0775 $SADM_CFG_DIR ; chown ${SADM_USER}:${SADM_GROUP} $SADM_CFG_DIR
    fi

    # ($SADMIN/sys) If System Startup/Shutdown Script Directory doesn't exist, create it.
    [ ! -d "$SADM_SYS_DIR" ] && mkdir -p $SADM_SYS_DIR
    if [ $(id -u) -eq 0 ] 
        then chmod 0775 $SADM_SYS_DIR ; chown ${SADM_USER}:${SADM_GROUP} $SADM_SYS_DIR
    fi 

    # ($SADMIN/doc) If Documentation Directory doesn't exist, create it.
    [ ! -d "$SADM_DOC_DIR" ] && mkdir -p $SADM_DOC_DIR
    if [ $(id -u) -eq 0 ] 
        then chmod 0775 $SADM_DOC_DIR ; chown ${SADM_USER}:${SADM_GROUP} $SADM_DOC_DIR
    fi

    # ($SADMIN/pkg) If Package Directory doesn't exist, create it.
    [ ! -d "$SADM_PKG_DIR" ] && mkdir -p $SADM_PKG_DIR
    if [ $(id -u) -eq 0 ] 
        then chmod 0775 $SADM_PKG_DIR ; chown ${SADM_USER}:${SADM_GROUP} $SADM_PKG_DIR
    fi

    # ($SADMIN/setup) If Setup Directory doesn't exist, create it.
    [ ! -d "$SADM_SETUP_DIR" ] && mkdir -p $SADM_SETUP_DIR
    if [ $(id -u) -eq 0 ] 
        then chmod 0775 $SADM_SETUP_DIR ; chown ${SADM_USER}:${SADM_GROUP} $SADM_SETUP_DIR
    fi

    # ($SADMIN/dat) If Data Directory doesn't exist, create it.
    [ ! -d "$SADM_DAT_DIR" ] && mkdir -p $SADM_DAT_DIR
    if [ $(id -u) -eq 0 ] 
        then chmod 0775 $SADM_DAT_DIR ; chown ${SADM_USER}:${SADM_GROUP} $SADM_DAT_DIR
    fi 

    # ($SADMIN/dat/nmon) If NMON Directory doesn't exist, create it.
    [ ! -d "$SADM_NMON_DIR" ] && mkdir -p $SADM_NMON_DIR
    if [ $(id -u) -eq 0 ]  
        then chmod 0775 $SADM_NMON_DIR ; chown ${SADM_USER}:${SADM_GROUP} $SADM_NMON_DIR 
    fi

    # ($SADMIN/dat/dr) If Disaster Recovery Information Directory doesn't exist, create it.
    [ ! -d "$SADM_DR_DIR" ] && mkdir -p $SADM_DR_DIR
    if [ $(id -u) -eq 0 ] 
        then chmod 0775 $SADM_DR_DIR ; chown ${SADM_USER}:${SADM_GROUP} $SADM_DR_DIR 
    fi

    # ($SADMIN/dat/rpt) If Sysmon Report Directory doesn't exist, create it.
    [ ! -d "$SADM_RPT_DIR" ] && mkdir -p $SADM_RPT_DIR
    if [ $(id -u) -eq 0 ] 
        then chmod 0775 $SADM_RPT_DIR ; chown ${SADM_USER}:${SADM_GROUP} $SADM_RPT_DIR
    fi

    # ($SADMIN/dat/rch) If Return Code History Directory doesn't exist, create it.
    [ ! -d "$SADM_RCH_DIR" ] && mkdir -p $SADM_RCH_DIR
    if [ $(id -u) -eq 0 ] 
        then chmod 0775 $SADM_RCH_DIR ; chown ${SADM_USER}:${SADM_GROUP} $SADM_RCH_DIR
    fi

    # ($SADMIN/usr) If User Directory doesn't exist, create it.
    [ ! -d "$SADM_USR_DIR" ] && mkdir -p $SADM_USR_DIR
    if [ $(id -u) -eq 0 ] 
        then chmod 0775 $SADM_USR_DIR ; chown ${SADM_USER}:${SADM_GROUP} $SADM_USR_DIR
    fi 

    # ($SADMIN/usr/bin) If User Bin Dir doesn't exist, create it.
    [ ! -d "$SADM_UBIN_DIR" ] && mkdir -p $SADM_UBIN_DIR
    if [ $(id -u) -eq 0 ] 
        then chmod 0775 $SADM_UBIN_DIR ; chown ${SADM_USER}:${SADM_GROUP} $SADM_UBIN_DIR 
    fi

    # ($SADMIN/usr/lib) If User Lib Dir doesn't exist, create it.
    [ ! -d "$SADM_ULIB_DIR" ] && mkdir -p $SADM_ULIB_DIR
    if [ $(id -u) -eq 0 ] 
        then chmod 0775 $SADM_ULIB_DIR ; chown ${SADM_USER}:${SADM_GROUP} $SADM_ULIB_DIR
    fi

    # ($SADMIN/usr/doc) If User Doc Directory doesn't exist, create it.
    [ ! -d "$SADM_UDOC_DIR" ] && mkdir -p $SADM_UDOC_DIR
    if [ $(id -u) -eq 0 ] 
        then chmod 0775 $SADM_UDOC_DIR ; chown ${SADM_USER}:${SADM_GROUP} $SADM_UDOC_DIR 
    fi

    # ($SADMIN/usr/mon) If User SysMon Scripts Directory doesn't exist, create it.
    [ ! -d "$SADM_UMON_DIR" ] && mkdir -p $SADM_UMON_DIR
    if [ $(id -u) -eq 0 ] 
        then chmod 0775 $SADM_UMON_DIR ; chown ${SADM_USER}:${SADM_GROUP} $SADM_UMON_DIR 
    fi

    # Check Directories that are present only on SADMIN Server
    if [ "$(sadm_get_fqdn)" = "$SADM_SERVER" ] 
        then # ($SADMIN/dat/net) If Network/Subnet Info Directory doesn't exist, create it.
             [ ! -d "$SADM_NET_DIR" ] && mkdir -p $SADM_NET_DIR
             if [ $(id -u) -eq 0 ] 
                then chmod 0775 $SADM_NET_DIR 
                     chown ${SADM_USER}:${SADM_GROUP} $SADM_NET_DIR
             fi
             # ($SADMIN/dat/dbb) If Database Backup Directory doesn't exist, create it.
             [ ! -d "$SADM_DBB_DIR" ] && mkdir -p $SADM_DBB_DIR
             if [ $(id -u) -eq 0 ] 
                then chmod 0775 $SADM_DBB_DIR 
                     chown ${SADM_USER}:${SADM_GROUP} $SADM_DBB_DIR 
             fi
             # $SADMIN/www Dir.
             [ ! -d "$SADM_WWW_DIR" ] && mkdir -p $SADM_WWW_DIR
             if [ $(id -u) -eq 0 ] 
                then chmod 0775 $SADM_WWW_DIR 
                     chown ${SADM_WWW_USER}:${SADM_WWW_GROUP} $SADM_WWW_DIR
             fi
             # $SADMIN/www/dat Dir.
             [ ! -d "$SADM_WWW_DAT_DIR" ] && mkdir -p $SADM_WWW_DAT_DIR
             if [ $(id -u) -eq 0 ] 
                then chmod 0775 $SADM_WWW_DAT_DIR 
                     chown ${SADM_WWW_USER}:${SADM_WWW_GROUP} $SADM_WWW_DAT_DIR
             fi
             # $SADMIN/www/doc Dir. 
             #[ ! -d "$SADM_WWW_DOC_DIR" ] && mkdir -p $SADM_WWW_DOC_DIR
             #if [ $(id -u) -eq 0 ] 
             #   then chmod 0775 $SADM_WWW_DOC_DIR 
             #        chown ${SADM_WWW_USER}:${SADM_WWW_GROUP} $SADM_WWW_DOC_DIR
             #fi
             # $SADMIN/www/lib Dir.
             [ ! -d "$SADM_WWW_LIB_DIR" ] && mkdir -p $SADM_WWW_LIB_DIR
             if [ $(id -u) -eq 0 ] 
                then chmod 0775 $SADM_WWW_LIB_DIR 
                     chown ${SADM_WWW_USER}:${SADM_WWW_GROUP} $SADM_WWW_LIB_DIR
             fi
             # $SADMIN/www/images Dir.
             [ ! -d "$SADM_WWW_IMG_DIR" ] && mkdir -p $SADM_WWW_IMG_DIR
             if [ $(id -u) -eq 0 ] 
                then chmod 0775 $SADM_WWW_IMG_DIR 
                     chown ${SADM_WWW_USER}:${SADM_WWW_GROUP} $SADM_WWW_IMG_DIR
             fi
             # $SADMIN/www/tmp Dir.
             [ ! -d "$SADM_WWW_TMP_DIR" ] && mkdir -p $SADM_WWW_TMP_DIR
             if [ $(id -u) -eq 0 ] 
                then chmod 0775 $SADM_WWW_TMP_DIR 
                     chown ${SADM_WWW_USER}:${SADM_WWW_GROUP} $SADM_WWW_TMP_DIR
             fi
            # Alert Group File ($SADMIN/cfg/alert_group.cfg) MUST be present.
            # If it doesn't exist create it from initial file ($SADMIN/cfg/.alert_group.cfg)
            if [ ! -r "$SADM_ALERT_FILE" ]                              # If AlertGrp not Exist
                then if [ ! -r "$SADM_ALERT_INIT" ]                     # If AlertInit File not Fnd
                       then sadm_writelog "********************************************************"
                            sadm_writelog "SADMIN Alert Group file not found - $SADM_ALERT_FILE "
                            sadm_writelog "Even Alert Group template file is missing - $SADM_ALERT_INIT"
                            sadm_writelog "Copy both files from another system to this server"
                            sadm_writelog "Or restore them from a backup"
                            sadm_writelog "Don't forget to review the file content."
                            sadm_writelog "********************************************************"
                            sadm_stop 1                                 # Exit to O/S with Error
                       else cp $SADM_ALERT_INIT $SADM_ALERT_FILE        # Copy Template as initial
                            chmod 664 $SADM_ALERT_FILE
                     fi
            fi
            # Slack Channel File ($SADMIN/cfg/slackchannel.cfg) MUST be present.
            # If it doesn't exist create it from initial file ($SADMIN/cfg/.slackchannel.cfg)
            if [ ! -r "$SADM_SLACK_FILE" ]                              # If AlertGrp not Exist
                then if [ ! -r "$SADM_SLACK_INIT" ]                     # If AlertInit File not Fnd
                       then sadm_writelog "********************************************************"
                            sadm_writelog "SADMIN Slack Channel file is missing - $SADM_SLACK_FILE "
                            sadm_writelog "Even Slack Channel template file is missing - $SADM_SLACK_INIT"
                            sadm_writelog "Copy both files from another system to this server"
                            sadm_writelog "Or restore them from a backup"
                            sadm_writelog "Don't forget to review the file content."
                            sadm_writelog "********************************************************"
                            sadm_stop 1                                 # Exit to O/S with Error
                       else cp $SADM_SLACK_INIT $SADM_SLACK_FILE        # Copy Template as initial
                            chmod 664 $SADM_SLACK_FILE
                     fi
            fi
            # Alert History File ($SADMIN/cfg/alert_history.txt) MUST be present.
            if [ ! -r "$SADM_ALERT_HIST" ]                              # If Alert History Missing
                then if [ ! -r "$SADM_ALERT_HINI" ]                     # If Alert Init File not Fnd
                       then touch $SADM_ALERT_HIST                      # Create a Blank One
                       else cp $SADM_ALERT_HINI $SADM_ALERT_HIST        # Copy Initial Hist. File
                     fi
                     chmod 666 $SADM_ALERT_HIST                         # Make sure it's writable
            fi
            # Alert History Sequence Number File ($SADMIN/cfg/alert_history.seq) MUST be present.
            if [ ! -r "$SADM_ALERT_SEQ" ]                               # If Alert Hist. Seq# Missing
                then echo "0" > $SADM_ALERT_SEQ                         # Create Initial Hist. Seq.
                     chmod 666 $SADM_ALERT_SEQ                          # Make it W/R File
            fi
    fi

    # Feed the Return Code History File stating the script is Running
    SADM_STIME=`date "+%C%y.%m.%d %H:%M:%S"`  ; export SADM_STIME       # Statup Time of Script
    if [ -z "$SADM_USE_RCH" ] || [ "$SADM_USE_RCH" = "Y" ]              # Want to Produce RCH File
        then [ ! -e "$SADM_RCHLOG" ] && touch $SADM_RCHLOG              # Create RCH If not exist
             chmod 664 $SADM_RCHLOG                                     # Change protection on RCH
             [ $(id -u) -eq 0 ] && chown ${SADM_USER}:${SADM_GROUP} ${SADM_RCHLOG} 
             WDOT=".......... ........ ........"                        # End Time & Elapse = Dot
             echo "${SADM_HOSTNAME} $SADM_STIME $WDOT $SADM_INST $SADM_ALERT_GROUP 2" >>$SADM_RCHLOG
    fi

    # If PID File exist and User want to run only 1 copy of the script - Abort Script
    if [ -e "${SADM_PID_FILE}" ] && [ "$SADM_MULTIPLE_EXEC" != "Y" ]    # PIP Exist - Run One Copy
       then sadm_writelog "Script is already running ... "              # Script already running
            sadm_writelog "PID File ${SADM_PID_FILE} exist ..."         # Show PID File Name
            sadm_writelog "Won't launch a second copy of this script."  # Only one copy can run
            sadm_writelog "Unless you remove the PID File."             # Del PID File to override
            DELETE_PID="N"                                              # No Del PID Since running
            sadm_stop 1                                                 # Call SADM Close Function
            exit 1                                                      # Exit with Error
       else echo "$TPID" > $SADM_PID_FILE                               # Create the PID File
    fi

    return 0 
}




# --------------------------------------------------------------------------------------------------
# SADM END OF PROCESS FUNCTION (RECEIVE 1 PARAMETER = EXIT CODE OF SCRIPT)
# What this function do.
#   1) If Exit Code is not zero, change it to 1.
#   2) Get Actual Time and Calculate the Execution Time.
#   3) Writing the Script Footer in the Log (Script Return code, Execution Time, ...)
#   4) Update the RCH File (Start/End/Elapse Time and the Result Code)
#   5) Trim The RCH File Based on User choice in sadmin.cfg
#   6) Write to Log the user mail alerting type choose by user (sadmin.cfg)
#   7) Trim the Log based on user selection in sadmin.cfg
#   8) Send Email to sysadmin (if user selected that option in sadmin.cfg)
#   9) Delete the PID File of the script (SADM_PID_FILE)
#  10) Delete the Uers 3 TMP Files (SADM_TMP_FILE1, SADM_TMP_FILE2, SADM_TMP_FILE3)
# --------------------------------------------------------------------------------------------------
#
sadm_stop() {    
    if [ $# -eq 0 ]                                                     # If No status Code Received
        then SADM_EXIT_CODE=1                                           # Assume Error if none given
             sadm_writelog "Function 'sadm_stop' expect a parameter (SADM_EXIT_CODE)"
             sadm_writelog "Received None - Assuming 1 (error)."        # Advise User
        else SADM_EXIT_CODE=$1                                          # Save Exit Code Received
    fi
    if [ "$SADM_EXIT_CODE" -ne 0 ] ; then SADM_EXIT_CODE=1 ; fi         # Making Sure code is 1 or 0
 
    # Get End time and Calculate Elapse Time
    sadm_end_time=`date "+%C%y.%m.%d %H:%M:%S"` ; export sadm_end_time  # Get & Format End Time
    sadm_elapse=`sadm_elapse "$sadm_end_time" "$SADM_STIME"`            # Get Elapse - End-Start

    # Start Writing Log Footer
    if [ -z "$SADM_LOG_FOOTER" ] || [ "$SADM_LOG_FOOTER" = "Y" ]        # Want to Produce Log Footer
        then sadm_writelog " "                                          # Blank Line
             sadm_writelog "${SADM_FIFTY_DASH}"                         # Dash Line
             sadm_writelog "Script return code is $SADM_EXIT_CODE"      # Final Exit Code to log
             sadm_writelog "Script execution time is $sadm_elapse"      # Write the Elapse Time
    fi

    # Update RCH File and Trim It to $SADM_MAX_RCLINE lines define in sadmin.cfg
    if [ -z "$SADM_USE_RCH" ] || [ "$SADM_USE_RCH" = "Y" ]              # Want to Produce RCH File
        then RCHLINE="${SADM_HOSTNAME} $SADM_STIME $sadm_end_time"      # Format Part1 of RCH File
             RCHLINE="$RCHLINE $sadm_elapse $SADM_INST"                 # Format Part2 of RCH File
             RCHLINE="$RCHLINE $SADM_ALERT_GROUP $SADM_EXIT_CODE"       # Format Part3 of RCH File
             echo "$RCHLINE" >>$SADM_RCHLOG                             # Append Line to  RCH File
             if [ -z "$SADM_LOG_FOOTER" ] || [ "$SADM_LOG_FOOTER" = "Y" ]
                then sadm_writelog "Trim History $SADM_RCHLOG to ${SADM_MAX_RCLINE} lines" 
             fi
             sadm_trimfile "$SADM_RCHLOG" "$SADM_MAX_RCLINE"            # Trim file to Desired Nb.
             chmod 664 ${SADM_RCHLOG}                                   # Writable by O/G Readable W
             chown ${SADM_USER}:${SADM_GROUP} ${SADM_RCHLOG}            # Change RCH file Owner
    fi

    # Write Alert Choice & The Log 
    if [ -z "$SADM_LOG_FOOTER" ] || [ "$SADM_LOG_FOOTER" = "Y" ]        # Want to Produce Log Footer
        then case $SADM_ALERT_TYPE in
                0)  sadm_writelog "User requested no alert to be sent when script end"
                    ;;
                1)  if [ "$SADM_EXIT_CODE" -ne 0 ]
                        then sadm_writelog "Requested alert if script failed (Will send alert)"
                        else sadm_writelog "Requested alert only if script fail (Won't send alert)"
                    fi
                    ;;
                2)  if [ "$SADM_EXIT_CODE" -eq 0 ]
                        then sadm_writelog "Requested alert on Success of script (Will send alert)"
                        else sadm_writelog "Requested alert only on script Success (Won't send alert)"
                    fi 
                    ;;
                3)  sadm_writelog "Requested alert at the end of each execution (Will send alert)"
                    ;;
                *)  sadm_writelog "SADM_ALERT_TYPE isn't set properly, should be between 0 and 3"
                    sadm_writelog "It is set to $SADM_ALERT_TYPE changing it to 3"
                    SADM_ALERT_TYPE=3
                    ;;
             esac
             sadm_writelog "Trim log $SADM_LOG to ${SADM_MAX_LOGLINE} lines" # Inform user trimming 
             sadm_writelog "`date` - End of ${SADM_PN}"                 # Write End Time To Log
             sadm_writelog "${SADM_80_DASH}"                            # Write 80 Dash Line
             sadm_writelog " "                                          # Blank Line

    fi


    # Trim the Log 
    cat $SADM_LOG > /dev/null                                           # Force buffer to flush
    sadm_trimfile "$SADM_LOG" "$SADM_MAX_LOGLINE"                       # Trim file to Desired Nb.
    chmod 664 ${SADM_LOG}                                               # Owner/Group Write Else Read
    chgrp ${SADM_GROUP} ${SADM_LOG}                                     # Change Log file Group 

    # Alert the Unix Admin. based on his selected choice
    if [ "$LIB_DEBUG" -gt 4 ] ;then sadm_writelog "SADM_ALERT_TYPE = $SADM_ALERT_TYPE" ; fi
    #wmess=`cat $SADM_LOG`                                       # Log = Message of Alert
    case $SADM_ALERT_TYPE in
      1)  if [ "$SADM_EXIT_CODE" -ne 0 ]                                # Alert On Error Only
             then wsub="$SADM_PN reported an error on ${SADM_HOSTNAME}" # Format Subject
                  wmess="$wsub\nScript execution time is $sadm_elapse"
                  sadm_send_alert "E" "$SADM_HOSTNAME" "$SADM_ALERT_GROUP" "$wsub" "$wmess" "$SADM_LOG"
           fi
          ;;
      2)  if [ "$SADM_EXIT_CODE" -eq 0 ]                                # Alert On Success Only
             then wsub="SUCCESS of $SADM_PN on ${SADM_HOSTNAME}"        # Format Subject
                  wmess="$wsub\nScript execution time is $sadm_elapse"
                  sadm_send_alert "I" "$SADM_HOSTNAME" "$SADM_ALERT_GROUP" "$wsub" "$wmess" "" 
          fi 
          ;;
      3)  if [ "$SADM_EXIT_CODE" -eq 0 ]                                # Always send an Alert
            then wsub="SUCCESS of $SADM_PN on ${SADM_HOSTNAME}"         # Format Subject
                 wmess="$wsub\nScript execution time is $sadm_elapse"
                 sadm_send_alert "I" "$SADM_HOSTNAME" "$SADM_ALERT_GROUP" "$wsub" "$wmess" "" 
            else wsub="$SADM_PN reported an error on ${SADM_HOSTNAME}"    # Format Subject
                 wmess="$wsub\nScript execution time is $sadm_elapse"
                 sadm_send_alert "I" "$SADM_HOSTNAME" "$SADM_ALERT_GROUP" "$wsub" "$wmess" "$SADM_LOG" 
          fi
          ;;
      4)  wsub="Invalid alert type '$SADM_ALERT_TYPE' on $SADM_HOSTNAME" # Format Subject
          wmess="$wsub"
          sadm_send_alert "E" "$SADM_HOSTNAME" "$SADM_ALERT_GROUP" "$wsub" "$wmess" "" 
          ;;
    esac
    if [ "$LIB_DEBUG" -gt 4 ] ;then sadm_writelog "wsub = $wsub" ; fi

        
    # Normally we Delete the PID File when exiting the script.
    # But when script is already running, we are the second instance of the script 
    # (DELETE_PID is set to "N"), we don't want to delete PID file
    if ( [ -e "$SADM_PID_FILE"  ] && [ "$DELETE_PID" = "Y" ] )          # PID Exist & Only Running 1
        then rm -f $SADM_PID_FILE  >/dev/null 2>&1                      # Delete the PID File
    fi

    # Delete Temporary files used
    if [ -e "$SADM_TMP_FILE1" ] ; then rm -f $SADM_TMP_FILE1 >/dev/null 2>&1 ; fi
    if [ -e "$SADM_TMP_FILE2" ] ; then rm -f $SADM_TMP_FILE2 >/dev/null 2>&1 ; fi
    if [ -e "$SADM_TMP_FILE3" ] ; then rm -f $SADM_TMP_FILE3 >/dev/null 2>&1 ; fi
    return $SADM_EXIT_CODE
}


# --------------------------------------------------------------------------------------------------
# Send an Alert 
#
# 1st Parameter    : [S]     If it is a Script Alert (Alert Message will include Script Info)
#                            For type [S] Default Group come from sadmin.cfg or user can modify it 
#                            by altering SADM_ALERT_GROUP variable in his script.
#                            ** Alert issue from a script will not be assign a reference no.
#
#                    [E/W/I] Error, Warning or Information Alert are detected by System Monitor.
#                            For this type [M] Warning and Error Alert Group are taken from the host
#                            System Monitor file ($SADMIN/cfg/hostname.smon).
#                            In System monitor file Warning are at column 'J' and Error at col. 'K'.
#                            ** Error and Warning (Not Info) Alert issue from SADMIN SysMon will be 
#                            assign a reference no. and will be included in the alert message.
#
# 2nd Parameter    : Server Name Where Alert come from
# 3th Parameter    : Alert Group Name to send Message
# 4th Parameter    : Subject/Title
# 5th Parameter    : The Alert Message
# 6th Parameter    : The Full Path Name of the attachment (If used, else blank)
#
# Example : sadm_send_alert E holmes sprod Filesystem /usr at 85% >= 85%
# --------------------------------------------------------------------------------------------------
#
sadm_send_alert() { 
    #LIB_DEBUG=6
    # Validate the Number of parameter received.
    if [ $# -ne 6 ]                                                     # Invalid No. of Parameter
        then sadm_writelog "Invalid number of argument received by function ${FUNCNAME}"
             sadm_writelog "Should be 6, we received $# : $*"           # Show what received
             return 1                                                   # Return Error to caller
    fi

    # Save Parameters Received (After Removing leading and trailing Spaces.
    alert_type=`echo "$1"   | awk '{$1=$1;print}'`               # [S]cript [E]rror [W]arning [I]nfo
    alert_type=`echo $alert_type |tr "[:lower:]" "[:upper:]"`           # Make Alert Type Uppercase
    alert_server=`echo "$2" | awk '{$1=$1;print}'`                      # Server where alert Come 
    alert_group=`echo "$3"  | awk '{$1=$1;print}'`                      # SADM AlertGroup to Advise
    alert_subject="$4"                                                  # Save Alert Subject
    alert_message="$5"                                                  # Save Alert Message
    alert_attach="$6"                                                   # Save Attachment FileName
    if [ "$LIB_DEBUG" -gt 4 ]                                           # Debug Info List what Recv.
       then debmes="sadm_send_alert: alert_type=$alert_type "           # Show Alert Type
            debmes="$debmes alert_group=$alert_group "                  # Show Alert Group
            debmes="$debmes alert_subject=\"$alert_subject\""           # Show Alert Subject/Title
            debmes="$debmes alert_message=\"$alert_message\""           # Show Alert Message
            debmes="$debmes alert_attachment=\"$alert_attach\""         # Show Alert Attachment File
            sadm_writelog "$debmes"
    fi

    # Is there is an attachment and is the File Readable ?
    if [ "$alert_attach" != "" ] && [ ! -r "$alert_attach" ]            # Can't read Attachment File
       then sadm_writelog "Error in ${FUNCNAME} - Attachment file '$alert_attach' missing" 
            return 1                                                    # Return Error to caller
    fi 

    # Is the AlertGroup File Readable ?
    if [ ! -r "$SADM_ALERT_FILE" ]                                      # If Can't read AlertGroup
       then sadm_writelog "Alert Group File '$SADM_ALERT_FILE' missing" # Advise User
            return 1                                                    # Return Error to caller
    fi 

    # Is the channel File present on Disk ?
    if [ ! -r "$SADM_SLACK_FILE" ]                                      # Can't read SlackChannel 
       then sadm_writelog "Slack Channel File '$SADM_SLACK_FILE' missing" # Advise User
            return 1                                                    # Return Error to caller
    fi 

    # Does the Alert Group exist in the Group in alert File ?
    #awk -F, '{ print $1 }' alert_group.cfg | grep -i "^sdev$"
    grep -i "^$alert_group " $SADM_ALERT_FILE >/dev/null 2>&1           # Line beginning with group
    if [ $? -ne 0 ]                                                     # Group Missing in GrpFile
        then sadm_writelog " "                                          # White line Before 
             sadm_writelog "----------"
             sadm_writelog "Alert Group '$alert_group' missing in $SADM_ALERT_FILE"  
             sadm_writelog "  - On server          : $alert_server"     # Show Alert Server Name
             sadm_writelog "  - Alert Type         : $alert_type"       # Show Alert Type S/E/W/I
             sadm_writelog "  - Alert Subject/Title: $alert_subject"    # Show Alert Message 
             sadm_writelog "  - Alert Message      : $alert_message"    # Show Alert Message 
             sadm_writelog "  - Alert Attachment   : $alert_attachment" # Show Attachment File
             sadm_writelog "Changing alert group from '$alert_group' to 'default'"
             alert_group='default'                                      # Change Alert Group
             sadm_writelog "----------"
    fi
    
    # Define Search String to see if we already alerted the user (Want to alert Once a Day)
    hsearch=`printf "%s,%s,%s" "$alert_server" "$alert_group" "$alert_subject"`
    hdate=`date +"%Y/%m/%d"`                                            # Current Date

    # Search For Today Message with the string "Server, Alert Group and Message"
    if [ "$LIB_DEBUG" -gt 4 ] 
        then sadm_writelog "Search History for \"$hdate\" and \"$hsearch\""
    fi
    grep "$hdate" $SADM_ALERT_HIST | grep "$hsearch" >>/dev/null 2>&1   # GrepMessage with same Date
    if [ $? -eq 0 ]                                                     # String Found=Already Done
        then sadm_writelog "Not sending Alert below, already sent in last 24Hrs"
             sadm_writelog "$hdate - $hsearch"
             return 2                                                   # Return 2 when alert exist
#        else sadm_writelog "Alert Not in History - Sending Alert to $alert_group : $hdate - $hsearch"
    fi                                

    # Determine if a [M]ail or a [S]lack Message need to be issued
    alert_group_type=`grep -i "^$alert_group " $SADM_ALERT_FILE |awk '{ print $2 }'` # [S/M]Group 
    alert_group_type=`echo $alert_group_type |awk '{$1=$1;print}' |tr  "[:lower:]" "[:upper:]"`
    if [ "$alert_group_type" != "M" ] && [ "$alert_group_type" != "S" ]
       then wmess="Invalid Alert Group Type '$alert_group_type' for '$alert_group' in $SADM_ALERT_FILE"
            sadm_writelog "$wmess"
            return 1
    fi

    # Get the Member of the Alert Group (Could be Email(s) or a SlackChannel define in Channel File)
    alert_group_member=`grep -i "^$alert_group " $SADM_ALERT_FILE | awk '{ print $3 }'` # Member
    alert_group_member=`echo $alert_group_member | awk '{$1=$1;print}'` # Del Leading/Trailing Space
    if [ "$LIB_DEBUG" -gt 4 ]                                           # If Debugging Library
       then debmes="sadm_send_alert: alert_group=$alert_group "         # Show Alert Group
            debmes="$debmes alert_group_type   =$alert_group_type "     # Show Alert Group Type (S/M)
            debmes="$debmes alert_group_member =${alert_group_member}"  # Show Alert Group Member
            debmes="$debmes alert_attachment   =${alert_attach}"        # Show Alert Attachment File
            sadm_writelog "$debmes"
    fi

    # If we are on the SADMIN Server assign a Reference No. else set it to "000000"
    if [ "$(sadm_get_fqdn)" != "$SADM_SERVER" ] || [ "$alert_type" = "I" ] 
        then refno="000000"                                             # Ref# when not on SADM Srv
        else href=`cat $SADM_ALERT_SEQ`                                 # Get Last Alert Ref. No.
             href=$(($href+1))                                          # Increment Alert Ref. No.
             printf "%d" $href > $SADM_ALERT_SEQ                        # Update Alert Ref. No. File
             refno=`printf "%06d" $href`                                # Alert Ref. No. with zero
    fi

    # If Alert Group Type is [M] then send ALERT BY EMAIL.------------------------------------------
    if [ "$alert_group_type" = "M" ]                                    # Alert by Mail 
        then adate=`date`                                               # Save Actual Date and Time
             if [ "$alert_type" = "E" ] ; then ws="SADM ERROR: ${alert_subject}"   ; fi 
             if [ "$alert_type" = "W" ] ; then ws="SADM WARNING: ${alert_subject}" ; fi 
             if [ "$alert_type" = "I" ] ; then ws="SADM INFO: ${alert_subject}"    ; fi 
             if [ "$alert_type" = "S" ] ; then ws="SADM SCRIPT: ${alert_subject}"  ; fi 
             if [ "$alert_type" = "I" ]
                then wm=`echo "${adate}\n${alert_message}\nOn server ${alert_server}."`
                else wm=`echo "${adate}\nReference No.${refno}\n${alert_message}\nOn server ${alert_server}."`
             fi
             if [ "$alert_attach" != "" ]                               # If Attachment Specified
                then echo -e "$wm" |$SADM_MUTT -s "$ws" "$alert_group_member" -a $alert_attach
                else echo -e "$wm" |$SADM_MUTT -s "$ws" "$alert_group_member"
             fi 
             RC=$?                                                      # Save Error Number    
             if [ $RC -eq 0 ]                                           # If Error Sending Email
                then write_alert_history "$alert_type" "$alert_group" "$alert_server" "$alert_subject" "$refno"
                else sadm_writelog "Error sending email to $alert_group_member" # Advise Usr
             fi
             return $RC                                                 # Return to Caller
    fi

    # If Alert Group Type is [S]lack then send ALERT TO SLACK with the WebHook.---------------------
    if [ "$alert_group_type" = "S" ]                                    # If Alert Type is Slack
        then 
             # Search Slack Channel file for selected channel
             grep -i "^$alert_group_member " $SADM_SLACK_FILE >/dev/null 2>&1 # Grep Channel Name
             if [ $? -ne 0 ]                                            # Channel not in Chn File
                then sadm_writelog "ERROR: Slack Channel '$alert_group_member' missing in $SADM_SLACK_FILE"
                     return 1                                           # Return Error to caller
             fi

             # Get the WebHook for the selected Channel
             slack_hook_url=`grep -i "^$alert_group_member " $SADM_SLACK_FILE |awk '{ print $2 }'`
             if [ "$LIB_DEBUG" -gt 4 ] 
                then sadm_writelog "Slack Channel=$alert_group_member Slack Webhook=$slack_hook_url"
             fi
             
             # If Alert is coming from a script
             mdate="`date`"                                              # Ready to Insert Date
             if [ "$alert_type" = "E" ] ; then ws="*SADM ERROR: ${alert_subject}*"   ; fi 
             if [ "$alert_type" = "W" ] ; then ws="*SADM WARNING: ${alert_subject}*" ; fi 
             if [ "$alert_type" = "I" ] ; then ws="*SADM INFO: ${alert_subject}*"    ; fi 
             if [ "$alert_type" = "S" ] ; then ws="*SADM SCRIPT: ${alert_subject}*"  ; fi 
             if [ "$alert_type" = "S" ] || [ "$alert_type" = "I" ]      # Alert [S]cript or [I]nfo
                then text="${ws}\n{$mdate}"                             # Insert Alert Subject
                     text="${text}\nOn server ${alert_server}."         # Insert Server with Alert
                     text="${text}\n$alert_message"                     # Insert Alert Message 
                else text="${ws}\n{$mdate}"                             # Insert Alert Subject
                     text="${text}\nReference No.${refno}"              # Insert Alert Reference No.
                     text="${text}\nOn server ${alert_server}."         # Insert Server with Alert
                     text="${text}\n${alert_message}"                   # Insert Alert Message 
             fi
             
             # Test for attachment 
             if [ "$alert_attach" != "" ]                               # If Attachment Specified
                then text_tail=`tail -50 ${alert_attach}`
                     text="${text}\n\n*-----Attachment-----*\n${text_tail}"
             fi 

             slack_text="$text"                                         # Set Alert Text
             escaped_msg=$(echo "${slack_text}" |sed 's/\"/\\"/g' |sed "s/'/\'/g" |sed 's/`/\`/g')
             slack_text="\"text\": \"${escaped_msg}\""                  # Set Final Text Message
             slack_icon="warning"
             markdown="\"mrkdwn\": true,"
             #json="{\"channel\": \"${alert_group_member}\", \"username\":\"${slack_username}\", \"icon_emoji\":\":${slack_icon}:\", ${markdown} ${slack_text}}"
             json="{\"channel\": \"${alert_group_member}\", \"icon_emoji\": \":${slack_icon}:\", ${markdown} ${slack_text}}"
             if [ "$LIB_DEBUG" -gt 4 ] 
                then sadm_writelog "$SADM_CURL -s -d \"payload=$json\" $slack_hook_url"
             fi
             #SLACK_CMD1="$SADM_CURL -X POST -H 'Content-type: application/json' --data"
             SRC=`$SADM_CURL -s -d "payload=$json" $slack_hook_url`
             if [ "$LIB_DEBUG" -gt 4 ] ; then sadm_writelog "Status after send to Slack is $SRC" ;fi
             if [ $SRC = "ok" ] 
                then RC=0
                     write_alert_history "$alert_type" "$alert_group" "$alert_server" "$alert_subject" "$refno"
                else RC=1
                     sadm_writelog "Error message : $SRC" 
             fi
             RC=0
             return $RC                                                 # Return to Caller
    fi
    return 0
}


# --------------------------------------------------------------------------------------------------
# Write Alert History File 
# Parameters:
#   1st = Alert Type        = [S]cript [E]rror [W]arning [I]nfo
#   2nd = Alert Group Name  = Alert Group Name to Advise (Must exist in $SADMIN/cfg/alert_group.cfg)
#   3rd = Server Name       = Where the event happen
#   4th = Alert Description = Alert Message
#   5th = Alert Reference#  = Reference No.
# write_alert_history "s" "alertGroup" "server" "mess"
# --------------------------------------------------------------------------------------------------
#
write_alert_history() { 
    htype=$1                                                  # [S]cript [E]rror [W]arning [I]nfo
    htype=`echo $htype |tr "[:lower:]" "[:upper:]"`                     # Make Alert Type Uppercase
    hgroup=`echo "$2"   | awk '{$1=$1;print}'`                          # SADM AlertGroup to Advise
    hserver=`echo "$3"  | awk '{$1=$1;print}'`                          # Save Server Name
    hmess="$4"                                                          # Save Alert Message
    href="$5"                                                           # Save Alert Reference No.
    hdate=`date +"%Y/%m/%d"`                                            # Current Date
    htime=`date +"%H:%M:%S"`                                            # Current Time
    hsearch=`printf "%s,%s,%s" "$hserver" "$hgroup" "$hmess"`           # Format Futur Search String
    #href=`cat $SADM_ALERT_SEQ`                                          # Get Last Alert Ref. No.
    #href=$(($href+1))                                                   # Increment Alert Ref. No.
    #printf "%d" $href > $SADM_ALERT_SEQ                                 # Update Alert Ref. No. File
    hline=`printf "%s,%1s,%-10s,%8s,%s\n" $href "$htype" "$hdate" "$htime" "$hsearch"`
    echo "$hline" >>$SADM_ALERT_HIST                                    # Write Alert History File
}


# --------------------------------------------------------------------------------------------------
# --------------------------------------------------------------------------------------------------
#                                THINGS TO DO WHEN FIRST CALLED
# --------------------------------------------------------------------------------------------------
# --------------------------------------------------------------------------------------------------
#
    grep "^SADMIN" /etc/environment >/dev/null 2>&1                     # Do Env.File include SADMIN
    if [ $? -ne 0 ]                                                     # SADMIN missing in /etc/env
        then echo "SADMIN=$SADMIN" >> /etc/environment                  # Then add it to the file
    fi 
    sadm_load_config_file                                               # Load sadmin.cfg file
    sadm_check_requirements                                             # Check Lib Requirements
    if [ $? -ne 0 ] ; then exit 1 ; fi                                  # If Requirement are not met
    export SADM_SSH_CMD="${SADM_SSH} -qnp${SADM_SSH_PORT}"              # SSH Command to SSH CLient
    export SADM_USERNAME=$(whoami)                                      # Current User Name
