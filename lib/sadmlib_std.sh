#!/usr/bin/env bash
#===================================================================================================
#  Author:    Jacques Duplessis
#  Title      sadmlib_std.sh
#  Date:      August 2015
#  Synopsis:  SADMIN  Shell Script Main Library
#
# --------------------------------------------------------------------------------------------------
# Description
# This file is not a stand-alone shell script; it provides functions to your scripts that source it.
#
# Note : All scripts (Shell,Python,php), configuration file and screen output are formatted to 
#        have and use a 100 characters per line. Comments in script always begin at column 73. 
#        You will have a better experience, if you set screen width to have at least 100 Characters.
# 
# --------------------------------------------------------------------------------------------------
# CHANGE LOG
# 2016_11_05 V2.0 Create log file earlier to prevent error message
# 2016_04_17 V2.1 Added Support for Linux Mint
# 2016_04_19 V2.2 Minor Modifications concerning Trimming the Log File
# 2017_07_03 V2.3 Cosmetic change (Use only 50 Dash line at start & end of script)
# 2017_07_17 V2.4 Split Second line of log header into two lines/ Change Timming Line
# 2017_08_12 V2.5 Print FQDN instead of hostname and SADM Lib Ver. in header of the log
# 2017_08_27 V2.6 If Log not in Append Mode, then no need to Trim - Change Log footer message accordingly
# 2017_09_23 V2.7 Add SQLite3 Dir & Name Plus Correct Typo Error in sadm_stop when testing for log trimming or not
# 2017_09_29 V2.8 Correct chown on ${SADMIN}/dat/net and Test creation and chown on www directories
# 2017_12_18 V2.9 Function were changed to run on MacOS and Some Restructuration was done
# 2017_12_23 V2.10 SSH Command line construction added at the end of script
# 2017_12_30 V2.11 Combine sadmlib_server into sadmlib_std , so onle library from then on.
# 2018_01_03 V2.12 Added Check for facter command , if present use it get get hardware info
# 2018_01_05 V2.13 Remove Warning when command can't be found for compatibility
# 2018_01_23 V2.14 Add arc directory in $SADMIN/www for archiving purpose
# 2018_01_25 V2.15 Add SADM_RRDTOOL to sadmin.cfg for php page using it
# 2018_02_07 V2.16 Bug Fix when determining if server is a virtual or physical
# 2018_02_08 V2.17 Correct 'if' statement compatibility problem with 'dash' shell
# 2018_02_14 V2.18 Add Documentation Directory
# 2018_02_22 V2.19 Add SADM_HOST_TYPE field in sadmin.cfg
# 2018_05_03 V2.20 Password for Database Standard User (sadmin and squery) now read from .dbpass file
# 2018_05_06 V2.21 Change name of crontab file in etc/cron.d to sadm_server_osupdate
# 2018_05_14 V2.22 Add Options not to use or not the RC File, to show or not the Log Header and Footer
# 2018_05_23 V2.23 Remove some variables and logic modifications
# 2018_05_26 V2.24 Added Variables SADM_RPT_FILE and SADM_USERNAME for users
# 2018_05_27 V2.25 Get Read/Write & Read/Only User Database Password, only if on SADMIN Server.
# 2018_05_28 V2.26 Added Loading of backup parameters coming from sadmin.cfg
# 2018_06_04 V2.27 Add dat/dbb,usr/bin,usr/doc,usr/lib,usr/mon,setup and www/tmp/perf creation.
# 2018_06_10 V2.28 SADM_CRONTAB file change name (/etc/cron.d/sadm_osupdate)
# 2018_06_14 V2.29 Added test to make sure that /etc/environment contains "SADMIN=${SADMIN}" line
# 2018_07_07 V2.30 Move .sadm_osupdate crontab work file to $SADMIN/cfg
# 2018_07_16 V2.31 Fix sadm_stop function crash, when no parameter (exit Code) is recv., assume 1
# 2018_07_24 v2.32 Show Kernel version instead of O/S Codename in log header
# 2018_08_16 v2.33 Remove Change Owner & Protection Error Message while not running with root.
# 2018_09_04 v2.34 Load SlackHook and Smon Alert Type from sadmin.cfg, so avail. to all scripts.
# 2018_09_07 v2.35 Alerting System now support using Slack (slack.com).
# 2018_09_16 v2.36 Alert Group added to ReturnCodeHistory file to alert script owner if not default
# 2018_09_18 v2.37 Alert mechanism Update, Enhance Performance, fixes
# 2018_09_20 v2.38 Fix Alerting problem with Slack, Change chown bug and Set default alert group to 'default'
# 2018_09_22 v2.39 Change Alert Message Format
# 2018_09_23 v2.40 Added alert_sysadmin function
# 2018_09_25 v2.41 Enhance Email Standard Alert Message
# 2018_09_26 v2.42 Send Alert Include Message Subject now
# 2018_09_27 v2.43 Now Script log can be sent to Slack Alert
# 2018_09_30 v2.44 Some Alert Message was too long (Corrupting history file), have shorthen them.
# 2018_10_04 v2.45 Error reported by scripts, issue multiple alert within same day (now once a day)
# 2018_10_15 v2.46 Remove repetitive lines in Slack Message and Email Alert
# 2018_10_20 v2.47 Alert not sent by client anymore,all alert are send by SADMIN Server(Avoid Dedup)
# 2018_10_28 v2.48 Only assign a Reference Number to 'Error' alert (Warning & Info not anymore)
# 2018_10_29 v2.49 Correct Type Error causing occasional crash
# 2018_10_30 v2.50 Use dnsdomainname to get current domainname if host cmd don't return it.
# 2018_11_09 v2.51 Add Link in Slack Message to view script log.
# 2018_11_09 v2.52 Update For Calculate CPU SPeed & for MacOS Mojave.
# 2018_12_08 v2.53 Fix problem determining domainname when DNS is server is down.
# 2018_12_14 v2.54 Fix Error Message when DB pwd file don't exist on server & Get DomainName on MacOS
# 2018_12_18 v2.55 Add ways to get CPU type on MacOS
# 2018_12_23 v2.56 Change way of getting CPU Information on MacOS 
# 2018_12_27 v2.57 If Startup and Shutdown scripts doesn't exist, create them from template.
# 2018_12_29 v2.58 Default logging ([B]oth) is now set to screen and log.
# 2019_01_11 Added: v2.59 Include definitions for backup & exclude list, avail to user.
# 2019_01_29 Change: v2.60 Improve the sadm_get_domainname function.
# 2019_02_05 Fix: v2.61 Correct type error. 
# 2019_02_06 Fix: v2.62 break error when finding system domain name.
# 2019_02_25 Change: v2.63 Added SADM_80_SPACES variable available to user.
# 2019_02_28 Change: v2.64 'lsb_release -si' return new string in RHEL/CentOS 8 Chg sadm_get_osname
# 2019_03_18 Change: v2.65 Improve: Optimize code to reduce load time (125 lines removed).
# 2019_03_18 New: v2.66 Function 'sadm_get_packagetype' that return package type (rpm,dev,aix,dmg).  
# 2019_03_31 Update: v2.67 Set log file owner ($SADM_USER) and permission (664) if executed by root.
# 2019_04_07 Update: v2.68 Optimize execution time & screen color variable now available.
# 2019_04_09 Update: v2.69 Fix tput error when running in batch mode and TERM not set.
# 2019_04_25 Update: v2.70 Read and Load 2 news sadmin.cfg variable Alert_Repeat,Textbelt Key & URL
# 2019_05_01 Update: v2.71 Correct problem while writing to alert history log.
# 2019_05_07 Update: v2.72 Function 'sadm_alert_sadmin' is removed, now using 'sadm_send_alert'
# 2019_05_08 Fix: v2.73 Eliminate sending duplicate alert.
# 2019_05_09 Update: v2.74 Change Alert History file layout to facilitate search for duplicate alert
# 2019_05_10 Update: v2.75 Change to duplicate alert management, more efficient.
# 2019_05_11 Update: v2.76 Alert History epoch time (1st field) is always epoch the alert is sent.
# 2019_05_12 Feature: v2.77 Alerting System with Mail, Slack and SMS now fullu working.
# 2019_05_13 Update: v2.78 Minor adjustment of message format for history file and log.
# 2019_05_14 Update: v2.79 Alert via mail while now have the script log attach to the email.
# 2019_05_16 Update: v3.00 Only one summary line is now added to RCH file when scripts are executed.
# 2019_05_19 Update: v3.01 SADM_DEBUG_LEVEL change to SADM_DEBUG for consistency with Python Libr.
# 2019_05_20 Update: v3.02 Eliminate `tput` warning when TERM variable was set to 'dumb'.
# 2019_06_07 Update: v3.03 Create/Update the RCH file using the new format (with alarm type).
# 2019_06_11 Update: v3.04 Function send_alert change to add script name as a parameter.
# 2019_06_19 Fixes: v3.05 Fix problem with repeating alert.
# 2019_06_23 Improve: v3.06 Code reviewed and library optimization (300 lines were removed).
# 2019_06_23 nolog: v3.06a Correct Typo error, in email alert.
# 2019_06_23 nolog: v3.06b Correct Typo error, in email alert.
# 2019_06_25 Update: v3.07 Optimize 'send_alert' function.
# 2019_06_27 Nolog: v3.08 Change 'Alert' for 'Notification' in source & email '1 of 0' corrected.
# 2019_07_14 Update: v3.09 Change History file format , correct some alert issues.
# 2019_07_18 Update: v3.10 Repeat SysMon (not Script) Alert once a day if not solve the next day.
# 2019_08_04 Update: v3.11 Minor change to alert message format
# 2019_08_19 Update: v3.12 Added SADM_REAR_EXCLUDE_INIT Global Var. as default Rear Exclude List 
# 2019_08_19 Update: v3.13 Added Global Var. SADM_REAR_NEWCRON and SADM_REAR_CRONTAB file location
# 2019_08_23 Update: v3.14 Create all necessary dir. in ${SADMIN}/www for the git pull to work
# 2019_08_31 Update: v3.15 Change owner of web directories differently if on client or server.
# 2019_09_20 Update: v3.16 Foreground color definition, typo corrections.
# 2019_10_13 Update: v3.17 Added function 'sadm_server_arch' - Return system arch. (x86_64,armv7l,.)
# 2019_10_15 Update: v3.18 Enhance method to get host domain name in function $(sadm_get_domainname)
# 2019_10_30 Update: v3.19 Remove utilization of 'facter' (Depreciated)
# 2019_11_22 Update: v3.20 Change the way domain name is obtain on MacOS $(sadm_get_domainname).
# 2019_11_22 Update: v3.20 Change the way domain name is obtain on MacOS $(sadm_get_domainname).
# 2019_12_02 Update: v3.21 Add Server name in subject of Email Alert,
# 2020_01_12 Update: v3.22 When script run on SADMIN server, copy 'rch' & 'log' in Web Interface Dir.
# 2020_01_20 Update: v3.23 Place Alert Message on top of Alert Message (SMS,SLACK,EMAIL)
# 2020_01_21 Update: v3.24 For texto alert, put alert message on top of texto & don't show if 1 of 1
# 2020_01_21 Update: v3.25 Show the script starting date in the header. 
# 2020_02_01 Fix: v3.26 If on SADM Server & script don't use 'rch', gave error trying to copy 'rch'.
# 2020_02_19 Update: v3.27 Added History Archive File Definition
# 2020_02_25 Update: v3.28 Add 'export SADMIN=$INSTALLDIR' to /etc/environment, if not there.
# 2020_03_15 Update: v3.29 Change the way script info (-v) is shown.
# 2020_03_16 Update: v3.30 If not present, create Alert Group file (alert_group.cfg) from template.
# 2020_04_01 Update: v3.31 Function sadm_writelog() with N/L depreciated, remplace by sadm_write().
# 2020_04_01 Update: v3.32 Function sadm_writelog() replaced by sadm_write in Library.
# 2020_04_04 Update: v3.33 New Variable SADM_OK, SADM_WARNING, SADM_ERROR to Show Status in Color.
# 2020_04_05 Update: v3.34 New Variable SADM_SUCCESS, SADM_FAILED to Show Status in Color.
# 2020_04_13 Update: v3.35 Correct Typo Error in SADM_ERROR
# 2020_04_13 Update: v3.36 Add @@LNT (Log No Time) var. to prevent sadm_write to put Date/Time in Log
# 2020_05_12 Fix: v3.37 Fix problem sending attachment file when sending alert by email.
# 2020_05_23 Fix: v3.38 Fix intermittent problem with 'sadm_write' & alert sent multiples times.
# 2020_06_09 Update: v3.39 Don't trim the log file, if $SADM_MAX_LOGLINE=0.
# 2020_06_06 Update: v3.40 When writing to log don't include time when prefix with OK,Warning,Error
# 2020_06_09 Update: v3.41 Don't trim the RCH file (ResultCodeHistory). if $SADM_MAX_RCLINE=0.
#@2020_07_11 Fixes: v3.42 Date and time was not include in script log.
#@2020_07_12 Update: v3.43 When virtual system 'sadm_server_model' return (VMWARE,VIRTUALBOX,VM)
#@2020_07_20 Update: v3.44 Change permission for log and rch to allow normal user to run script.
#@2020_07_23 New: v3.45 New function 'sadm_ask', show received msg & wait for y/Y (return 1) or n/N (return 0)
#@2020_07_29 Fix: v3.46 Fix date not showing in the log under some condition.
#@2020_09_10 New: v3.47 Add module "sadm_sleep", sleep for X seconds with progressing info.
#@2020_09_10 Fix: v3.48 Remove improper '::' characters to was inserted im messages.
#@2020_09_12 New: v3.49 Global Var. $SADM_UCFG_DIR was added to refer $SADMIN/usr/cfg directory.
#@2020_09_18 New: v3.50 Change Screen Attribute Variable (Remove 'SADM_', $SADM_RED is NOW $RED).
#===================================================================================================
trap 'exit 0' 2                                                         # Intercept The ^C
#set -x
 

 
# --------------------------------------------------------------------------------------------------
#                             V A R I A B L E S      D E F I N I T I O N S
# --------------------------------------------------------------------------------------------------
#
SADM_HOSTNAME=`hostname -s`                 ; export SADM_HOSTNAME      # Current Host name
SADM_LIB_VER="3.50"                         ; export SADM_LIB_VER       # This Library Version
SADM_DASH=`printf %80s |tr " " "="`         ; export SADM_DASH          # 80 equals sign line
SADM_FIFTY_DASH=`printf %50s |tr " " "="`   ; export SADM_FIFTY_DASH    # 50 equals sign line
SADM_80_DASH=`printf %80s |tr " " "="`      ; export SADM_80_DASH       # 80 equals sign line
SADM_80_SPACES=`printf %80s  " "`           ; export SADM_80_SPACES     # 80 spaces 
SADM_TEN_DASH=`printf %10s |tr " " "-"`     ; export SADM_TEN_DASH      # 10 dashes line
SADM_STIME=""                               ; export SADM_STIME         # Store Script Start Time
SADM_DEBUG=0                                ; export SADM_DEBUG         # 0=NoDebug Higher=+Verbose
DELETE_PID="Y"                              ; export DELETE_PID         # Default Delete PID On Exit
LIB_DEBUG=0                                 ; export LIB_DEBUG          # This Library Debug Level

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
SADM_UCFG_DIR="$SADM_USR_DIR/cfg"           ; export SADM_UCFG_DIR      # Script User Cfg Dir.
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

# SADM CONFIG FILES, LOGS AND TEMP FILES USER CAN USE
SADM_PID_FILE="${SADM_TMP_DIR}/${SADM_INST}.pid"            ; export SADM_PID_FILE   # PID file name
SADM_CFG_FILE="$SADM_CFG_DIR/sadmin.cfg"                    ; export SADM_CFG_FILE   # Cfg file name
SADM_ALERT_FILE="$SADM_CFG_DIR/alert_group.cfg"             ; export SADM_ALERT_FILE # AlertGrp File
SADM_ALERT_INIT="$SADM_CFG_DIR/.alert_group.cfg"            ; export SADM_ALERT_INIT # Initial Alert
SADM_SLACK_FILE="$SADM_CFG_DIR/alert_slack.cfg"             ; export SADM_SLACK_FILE # Slack WebHook
SADM_SLACK_INIT="$SADM_CFG_DIR/.alert_slack.cfg"            ; export SADM_SLACK_INIT # Slack Init WH
SADM_ALERT_HIST="$SADM_CFG_DIR/alert_history.txt"           ; export SADM_ALERT_HIST # Alert History
SADM_ALERT_HINI="$SADM_CFG_DIR/.alert_history.txt"          ; export SADM_ALERT_HINI # History Init
SADM_ALERT_ARC="$SADM_CFG_DIR/alert_archive.txt"            ; export SADM_ALERT_ARC  # Alert Archive
SADM_ALERT_ARCINI="$SADM_CFG_DIR/.alert_archive.txt"        ; export SADM_ALERT_ARCINI # Init Archive
SADM_REL_FILE="$SADM_CFG_DIR/.release"                      ; export SADM_REL_FILE   # Release Ver.
SADM_SYS_STARTUP="$SADM_SYS_DIR/sadm_startup.sh"            ; export SADM_SYS_STARTUP # Startup File
SADM_SYS_START="$SADM_SYS_DIR/.sadm_startup.sh"             ; export SADM_SYS_START  # Startup Template
SADM_SYS_SHUTDOWN="$SADM_SYS_DIR/sadm_shutdown.sh"          ; export SADM_SYS_SHUTDOWN # Shutdown 
SADM_SYS_SHUT="$SADM_SYS_DIR/.sadm_shutdown.sh"             ; export SADM_SYS_SHUT   # Shutdown Template
SADM_CRON_FILE="$SADM_CFG_DIR/.sadm_osupdate"               ; export SADM_CRON_FILE  # Work crontab
SADM_CRONTAB="/etc/cron.d/sadm_osupdate"                    ; export SADM_CRONTAB    # Final crontab
SADM_BACKUP_NEWCRON="$SADM_CFG_DIR/.sadm_backup"            ; export SADM_BACKUP_NEWCRON # Tmp Cron
SADM_BACKUP_CRONTAB="/etc/cron.d/sadm_backup"               ; export SADM_BACKUP_CRONTAB # Act Cron
SADM_REAR_NEWCRON="$SADM_CFG_DIR/.sadm_rear_backup"         ; export SADM_REAR_NEWCRON # Tmp Cron
SADM_REAR_CRONTAB="/etc/cron.d/sadm_rear_backup"            ; export SADM_REAR_CRONTAB # Real Cron
SADM_BACKUP_LIST="$SADM_CFG_DIR/backup_list.txt"            ; export SADM_BACKUP_LIST
SADM_BACKUP_LIST_INIT="$SADM_CFG_DIR/.backup_list.txt"      ; export SADM_BACKUP_LIST_INIT
SADM_BACKUP_EXCLUDE="$SADM_CFG_DIR/backup_exclude.txt"      ; export SADM_BACKUP_EXCLUDE
SADM_REAR_EXCLUDE_INIT="$SADM_CFG_DIR/.rear_exclude.txt"    ; export SADM_REAR_EXCLUDE_INIT
SADM_BACKUP_EXCLUDE_INIT="$SADM_CFG_DIR/.backup_exclude.txt" ;export SADM_BACKUP_EXCLUDE_INIT
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

# SADMIN CONFIG FILE VARIABLES (Default Values here will be overridden by SADM CONFIG FILE Content)
SADM_MAIL_ADDR="your_email@domain.com"      ; export SADM_MAIL_ADDR     # Default is in sadmin.cfg
SADM_ALERT_TYPE=1                           ; export SADM_ALERT_TYPE    # 0=No 1=Err 2=Succes 3=All
SADM_ALERT_GROUP="default"                  ; export SADM_ALERT_GROUP   # Define in alert_group.cfg
SADM_ALERT_REPEAT=43200                     ; export SADM_ALERT_REPEAT  # Repeat Alarm wait time Sec
SADM_TEXTBELT_KEY="textbelt"                ; export SADM_TEXTBELT_KEY  # Textbelt.com API Key
SADM_TEXTBELT_URL="https://textbelt.com/text" ;export SADM_TEXTBELT_URL # Textbelt.com API URL
SADM_CIE_NAME="Your Company Name"           ; export SADM_CIE_NAME      # Company Name
SADM_HOST_TYPE=""                           ; export SADM_HOST_TYPE     # [S]erver/[C]lient/[D]ev.
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
SADM_WEEKLY_BACKUP_DAY=5                    ; export SADM_WEEKLY_BACKUP_DAY      # 1=Mon, ... ,7=Sun
SADM_MONTHLY_BACKUP_DATE=1                  ; export SADM_MONTHLY_BACKUP_DATE    # Monthly Back Date
SADM_YEARLY_BACKUP_MONTH=12                 ; export SADM_YEARLY_BACKUP_MONTH    # Yearly Backup Mth
SADM_YEARLY_BACKUP_DATE=31                  ; export SADM_YEARLY_BACKUP_DATE     # Yearly Backup Day
SADM_MKSYSB_NFS_SERVER=""                   ; export SADM_MKSYSB_NFS_SERVER      # Mksysb NFS Server
SADM_MKSYSB_NFS_MOUNT_POINT=""              ; export SADM_MKSYSB_NFS_MOUNT_POINT # Mksysb Mnt Point
SADM_MKSYSB_NFS_TO_KEEP=2                   ; export SADM_MKSYSB_NFS_TO_KEEP     # Mksysb Bb. Copy

# Local to Library Variable - Can't be use elsewhere outside this script
LOCAL_TMP="$SADM_TMP_DIR/sadmlib_tmp.$$"    ; export LOCAL_TMP          # Local Temp File

# Screen related variables
if [ -z $TERM ] || [ "$TERM" = "dumb" ]
    then export CLREOL=""                                               # Clear to End of Line
         export CLREOS=""                                               # Clear to End of Screen
         export BOLD=""                                                 # Set Bold Attribute
         export BELL=""                                                 # Ring the Bell
         export REVERSE=""                                              # Reverse Video On
         export UNDERLINE=""                                            # Set UnderLine On
         export HOME=""                                                 # Home Cursor
         export UP=""                                                   # Cursor up
         export DOWN=""                                                 # Cursor down
         export RIGHT=""                                                # Cursor right
         export LEFT=""                                                 # Cursor left
         export CLRSCR=""                                               # Clear Screen
         export BLINK=""                                                # Blinking on
         export NORMAL=""                                               # Reset Screen Attribute
    else export CLREOL=$(tput el)          2>/dev/null                  # Clear to End of Line
         export CLREOS=$(tput ed)          2>/dev/null                  # Clear to End of Screen
         export BOLD=$(tput bold)          2>/dev/null                  # Set Bold Attribute On
         export BELL=$(tput bel)           2>/dev/null                  # Ring the Bell
         export REVERSE=$(tput rev)            2>/dev/null              # Reverse Video 
         export UNDERLINE=$(tput sgr 0 1)        2>/dev/null            # UnderLine
         export HOME=$(tput home)       2>/dev/null                     # Home Cursor
         export UP=$(tput cuu1)            2>/dev/null                  # Cursor up
         export DOWN=$(tput cud1)          2>/dev/null                  # Cursor down
         export RIGHT=$(tput cub1)         2>/dev/null                  # Cursor right
         export LEFT=$(tput cuf1)          2>/dev/null                  # Cursor left
         export CLRSCR=$(tput clear)          2>/dev/null               # Clear Screen
         export BLINK=$(tput blink)        2>/dev/null                  # Blinking on
         export NORMAL=$(tput sgr0)         2>/dev/null                 # Reset Screen
fi    

# Foreground Color
if [ -z $TERM ] || [ "$TERM" = "dumb" ]
    then export BLACK=""                                                # Black color
         export MAGENTA=""                                              # Magenta color
         export RED=""                                                  # Red color
         export GREEN=""                                                # Green color
         export YELLOW=""                                               # Yellow color
         export BLUE=""                                                 # Blue color
         export CYAN=""                                                 # Cyan color
         export WHITE=""                                                # White color
    else export BLACK=$(tput setaf 0)      2>/dev/null                  # Black color
         export RED=$(tput setaf 1)        2>/dev/null                  # Red color
         export GREEN=$(tput setaf 2)      2>/dev/null                  # Green color
         export YELLOW=$(tput setaf 3)     2>/dev/null                  # Yellow color
         export BLUE=$(tput setaf 4)       2>/dev/null                  # Blue color
         export MAGENTA=$(tput setaf 5)    2>/dev/null                  # Magenta color
         export CYAN=$(tput setaf 6)       2>/dev/null                  # Cyan color
         export WHITE=$(tput setaf 7)      2>/dev/null                  # White color
fi 

# Background Color
if [ -z $TERM ] || [ "$TERM" = "dumb" ]
    then export BBLACK=""                                               # Black color
         export BRED=""                                                 # Red color
         export BGREEN=""                                               # Green color
         export BYELLOW=""                                              # Yellow color
         export BBLUE=""                                                # Blue color
         export BMAGENTA=""                                             # Magenta color
         export BCYAN=""                                                # Cyan color
         export BWHITE=""                                               # White color
    else     
         export BBLACK=$(tput setab 0)     2>/dev/null                  # Black color
         export BRED=$(tput setab 1)       2>/dev/null                  # Red color
         export BGREEN=$(tput setab 2)     2>/dev/null                  # Green color
         export BYELLOW=$(tput setab 3)    2>/dev/null                  # Yellow color
         export BBLUE=$(tput setab 4)      2>/dev/null                  # Blue color
         export BMAGENTA=$(tput setab 5)   2>/dev/null                  # Magenta color
         export BCYAN=$(tput setab 6)      2>/dev/null                  # Cyan color
         export BWHITE=$(tput setab 7)     2>/dev/null                  # White color
fi


# Standard Variable to Show ERROR,OK,WARNING status uniformingly.
export SADM_ERROR="::[ ${RED}ERROR${NORMAL} ]"                          # [ ERROR ] Red
export SADM_FAILED="::[ ${RED}FAILED${NORMAL} ]"                        # [ FAILED ] Red
export SADM_WARNING="::[ ${BOLD}${YELLOW}WARNING${NORMAL} ]"            # WARNING Yellow
export SADM_OK="::[ ${BOLD}${GREEN}OK${NORMAL} ]"                       # [ OK ] Green
export SADM_SUCCESS="::[ ${BOLD}${GREEN}SUCCESS${NORMAL} ]"             # SUCCESS Green
export SADM_INFO="::[ ${BOLD}${BLUE}INFO${NORMAL} ]"                    # INFO Blue



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



# ==================================================================================================
# Display Question (Receive as $1) and wait for response from user.
# Y/y (return 1) or N/n (return 0)
# ==================================================================================================
function sadm_ask() {
    wmess="$1 [y,n] ? "                                                 # Add Y/N to Mess. Rcv
    while :
        do
        printf "%s" "$wmess"                                            # Print "Question [Y/N] ?" 
        read answer                                                     # Read User answer
        case "$answer" in                                               # Test Answer
           Y|y ) wreturn=1                                              # Yes = Return Value of 1
                 break                                                  # Break of the loop
                 ;;
           n|N ) wreturn=0                                              # No = Return Value of 0
                 break                                                  # Break of the loop
                 ;;
             * ) echo ""                                                # Blank Line
                 ;;                                                     # Other stay in the loop
         esac
    done
    return $wreturn                                                     # Return Answer to caller 
}



# --------------------------------------------------------------------------------------------------
# Write String received to Log (L), Screen (S) or Both (B) depending on $SADM_LOG_TYPE
# Use sadm_write (No LF at EOL) instead of sadm_writelog (With LF at EOL) which is depreciated.
# --------------------------------------------------------------------------------------------------
sadm_write() {
    SADM_SMSG="$@"                                                      # Save Received Message
    
    # If two first characters of message are '::', then don't include timestamp in the log.
    if [ "${SADM_SMSG:0:2}" = "::" ] 
        then SADM_SMSG=`echo "${SADM_SMSG:2:${#SADM_SMSG}}"`            # Remove '::' in the front
             SADM_LMSG="$SADM_SMSG"                                     # Then Log Mess with no Time
        else SADM_LMSG="$(date "+%C%y.%m.%d %H:%M:%S") $SADM_SMSG"      # For Log Line include Time
    fi 
    SADM_SMSG=`echo ${SADM_SMSG/::/}`                                   # Remove :: from Screen Mess
    SADM_LMSG=`echo ${SADM_LMSG/::/}`                                   # Remove :: from Log Mess
    
    case "$SADM_LOG_TYPE" in                                            # Depending of LOG_TYPE
        s|S) echo -ne "$SADM_SMSG"                                      # Write Msg to Screen
             ;;
        l|L) echo -ne "$SADM_LMSG" >> $SADM_LOG                         # Write Msg to Log File
             ;;
        b|B) echo -ne "$SADM_SMSG"                                      # Write Msg to Screen
             echo -ne "$SADM_LMSG" >> $SADM_LOG                         # Write Msg to Log File
             ;;
        *)   printf "\nWrong \$SADM_LOG_TYPE value ($SADM_LOG_TYPE)\n"  # Advise User if Incorrect
             printf -- "%-s\n" "$SADM_LMSG" >> $SADM_LOG                # Write Msg to Log File
             ;;
    esac
}



# --------------------------------------------------------------------------------------------------
#     WRITE INFORMATION TO THE LOG (L) , TO SCREEN (S)  OR BOTH (B) DEPENDING ON $SADM_LOG_TYPE
# Use sadm_write instead of sadm_writelog which is depreciated.
# --------------------------------------------------------------------------------------------------
sadm_writelog() {
    SADM_SMSG="$@"                                                      # Screen Mess no Date/Time
    SADM_LMSG="$(date "+%C%y.%m.%d %H:%M:%S") $@"                       # Log Message with Date/Time
    if [ "$SADM_LOG_TYPE" = "" ] ; then SADM_LOG_TYPE="B" ; fi          # Log Type Default is Both
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
# Show Script Name, version, Library Version, O/S Name/Version and Kernel version.
# --------------------------------------------------------------------------------------------------
sadm_show_version()
{
    printf "\n${SADM_PN} v${SADM_VER} - Hostname ${SADM_HOSTNAME}"
    printf "\nSADMIN Shell Library v${SADM_LIB_VER}"
    printf "\n$(sadm_get_osname) v$(sadm_get_osversion)"
    printf " - Kernel $(sadm_get_kernel_version)"
    printf "\n\n" 
}


# --------------------------------------------------------------------------------------------------
# TRIM THE FILE RECEIVED AS FIRST PARAMETER (MAX LINES IN LOG AS 2ND PARAMATER)
# --------------------------------------------------------------------------------------------------
sadm_trimfile() {
    wfile=$1 ; maxline=$2                                               # Save FileName et Nb Lines
    wreturn_code=0                                                      # Return Code of function

    # Test Number of parameters received
    if [ $# -ne 2 ]                                                     # Should have rcv 1 Param
        then sadm_write "sadm_trimfile: Should receive 2 Parameters\n"  # Show User Info on Error
             sadm_write "Have received $# parameters ($*)\n"            # Advise User to Correct
             return 1                                                   # Return Error to Caller
    fi

    # Test if filename received exist
    if [ ! -r "$wfile" ]                                                # Check if File Rcvd Exist
        then sadm_write "sadm_trimfile : Can't read file $1\n"          # Advise user
             return 1                                                   # Return Error to Caller
    fi

    # Test if Second Parameter Received is an integer
    sadm_isnumeric "$maxline"                                           # Test if an Integer
    if [ $? -ne 0 ]                                                     # If not an Integer
        then wreturn_code=1                                             # Return Code report error
             sadm_write "sadm_trimfile: Nb of line invalid ($2)\n"      # Advise User
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
# IF THE COMMAND EXIST, RETURN 0  -  IF IT DOESN'T EXIST, RETURN 1
# --------------------------------------------------------------------------------------------------
sadm_get_command_path() {
    SADM_CMD=$1                                                         # Save Parameter received
    if ${SADM_WHICH} ${SADM_CMD} >/dev/null 2>&1                        # Command is found ?
        then CMD_PATH=`${SADM_WHICH} ${SADM_CMD}`                       # Store Path in Cmd path
             echo "$CMD_PATH"                                           # Return Command Path 
             return 0                                                   # Return 0 if Cmd found
        else CMD_PATH=""                                                # Clear Command Path 
             echo "$CMD_PATH"                                           # Return empty str as path
    fi
    return 1                                                            # Return 1 if Cmd not Found
}

# ----------------------------------------------------------------------------------------------
# DETERMINE THE INSTALLATION PACKAGE TYPE OF CURRENT O/S 
# ----------------------------------------------------------------------------------------------
sadm_get_packagetype() {
    packtype=""                                                     # Initial Package None
    found=$(sadm_get_command_path 'rpm')                            # Is command rpm available 
    if [ "$found" != "" ] ; then packtype="rpm"  ; echo "$packtype" ; return 0 ; fi 
    
    found=$(sadm_get_command_path 'dpkg')                           # Is command dpkg available 
    if [ "$found" != "" ] ; then packtype="deb"  ; echo "$packtype" ; return 0 ; fi 
    
    found=$(sadm_get_command_path 'lslpp')                          # Is command lslpp available 
    if [ "$found" != "" ] ; then packtype="aix"  ; echo "$packtype" ; return 0 ; fi 

    found=$(sadm_get_command_path 'launchctl')                      # Is command lslpp available 
    if [ "$found" != "" ] ; then packtype="dmg"  ; echo "$packtype" ; return 0 ; fi 
    
    echo "$packtype"                                                # Return Package Type
    return 1                                                        # Error - Return code 1
}



# --------------------------------------------------------------------------------------------------
# THIS FUNCTION MAKE SURE THAT ALL SADM SHELL LIBRARIES (LIB/SADM_*) REQUIREMENTS ARE MET BEFORE USE
# IF THE REQUIRENMENT ARE NOT MET, THEN THE SCRIPT WILL ABORT INFORMING USER TO CORRECT SITUATION
# --------------------------------------------------------------------------------------------------
#
sadm_check_requirements() {
    if [ "$LIB_DEBUG" -gt 4 ] ;then sadm_write "sadm_check_requirement\n" ; fi

    # The 'which' command is needed to determine presence of command - Return Error if not found
    if which which >/dev/null 2>&1                                      # Try the command which
        then SADM_WHICH=`which which`  ; export SADM_WHICH              # Save Path of Which Command
        else sadm_write "${SADM_ERROR} The command 'which' couldn't be found\n"
             sadm_write "        This program is often used by the SADMIN tools\n"
             sadm_write "        Please install it and re-run this script\n"
             sadm_write "        *** Script Aborted\n"
             return 1                                                   # Return Error to Caller
    fi

    # Get Command path for Linux O/S ---------------------------------------------------------------
    if [ "$(sadm_get_ostype)" = "LINUX" ]                               # Under Linux O/S
       then SADM_LSB_RELEASE=$(sadm_get_command_path "lsb_release")     # Get lsb_release cmd path
            SADM_DMIDECODE=$(sadm_get_command_path "dmidecode")         # Get dmidecode cmd path
            SADM_NMON=$(sadm_get_command_path "nmon")                   # Get nmon cmd path   
            SADM_ETHTOOL=$(sadm_get_command_path "ethtool")             # Get ethtool cmd path   
            SADM_PARTED=$(sadm_get_command_path "parted")               # Get parted cmd path   
            SADM_MUTT=$(sadm_get_command_path "mutt")                   # Get mutt cmd path   
            SADM_LSCPU=$(sadm_get_command_path "lscpu")                 # Get lscpu cmd path   
            SADM_FDISK=$(sadm_get_command_path "fdisk")                 # Get fdisk cmd path   
    fi

    # Special consideration for nmon on Aix 5.x & 6.x (After that it is included as part of O/S ----
    if [ "$(sadm_get_ostype)" = "AIX" ]                                 # Under Aix O/S
       then SADM_NMON=$(sadm_get_command_path "nmon")                   # Get nmon cmd path   
            if [ "$SADM_NMON" = "" ]                                    # If Command not found
               then NMON_WDIR="${SADM_PKG_DIR}/nmon/aix/"               # Where Aix nmon exec are
                    NMON_EXE="nmon_aix$(sadm_get_osmajorversion)$(sadm_get_osminorversion)"
                    NMON_USE="${NMON_WDIR}${NMON_EXE}"                  # Use exec. of your version
                    if [ ! -x "$NMON_USE" ]                             # nmon exist and executable
                        then sadm_write "'nmon' for AIX $(sadm_get_osversion) isn't available\n"
                             sadm_write "The nmon executable we need is ${NMON_USE}\n"
                        else sadm_write "ln -s ${NMON_USE} /usr/bin/nmon\n"
                             ln -s ${NMON_USE} /usr/bin/nmon            # Link nmon avail to user
                             if [ $? -eq 0 ] ; then SADM_NMON="/usr/bin/nmon" ; fi # Set SADM_NMON
                    fi
            fi
    fi

    # Get Command path for All supported O/S -------------------------------------------------------
    SADM_PERL=$(sadm_get_command_path "perl")                           # Get perl cmd path   
    SADM_SSH=$(sadm_get_command_path "ssh")                             # Get ssh cmd path   
    SADM_BC=$(sadm_get_command_path "bc")                               # Get bc cmd path   
    SADM_MAIL=$(sadm_get_command_path "mail")                           # Get mail cmd path   
    SADM_CURL=$(sadm_get_command_path "curl")                           # Get curl cmd path   
    SADM_MYSQL=$(sadm_get_command_path "mysql")                         # Get mysql cmd path  
    return 0
}


# --------------------------------------------------------------------------------------------------
# Function will Sleep for a number of seconds.
#   - 1st parameter is the time to sleep in seconds.
#   - 2nd Parameter is the interval in seconds, user will be showed the elapse number of seconds.
# --------------------------------------------------------------------------------------------------
sadm_sleep() {
    SLEEP_TIME=$1                                                       # Nb. Sec. to Sleep 
    TIME_INTERVAL=$2                                                    # Interval show user count
    TIME_SLEPT=0                                                        # Time Slept in Seconds
    while [ $SLEEP_TIME -gt $TIME_SLEPT ]                               # Loop Sleep time Exhaust
        do
        printf "${TIME_SLEPT}..."                                       # Indicate Sec. Slept
        sleep $TIME_INTERVAL                                            # Sleep Interval Nb. Seconds
        TIME_SLEPT=$(( $TIME_SLEPT + $TIME_INTERVAL ))                  # Inc Slept Time by Interval
        done
    printf "${TIME_SLEPT}\n"
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
        then sadm_write "No Parameter received by $FUNCNAME function\n" # Show User Info on Error
             sadm_write "Please correct your script - Script Aborted\n" # Advise User to Correct
             sadm_stop 1                                                # Prepare to exit gracefully
             exit 1                                                     # Terminate the script
    fi
    wepoch=$1                                                           # Save Epoch Time Receivec

    # Verify if parameter received is all numeric - If not advice user and exit
    echo $wepoch | grep [^0-9] > /dev/null 2>&1                         # Grep for Number
    if [ "$?" -eq "0" ]                                                 # Not All Number
        then sadm_write "Incorrect parameter received by \"sadm_epoch_to_date\" function\n"
             sadm_write "Should recv. epoch time & received ($wepoch)\n" # Advise User
             sadm_write "Please correct situation - Script Aborted\n"    # Advise that will abort
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
        then sadm_write "No Parameter received by $FUNCNAME function\n" # Log Error Mess,
             sadm_write "Please correct script please,script aborted\n" # Advise that will abort
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
        then sadm_write "Invalid number of parameter received by $FUNCNAME function\n"
             sadm_write "Please correct script please, script aborted\n" # Advise that will abort
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
                    if [ "$wver"  = "10.14" ] ; then woscodename="Mojave"           ;fi
                    if [ "$wver"  = "10.15" ] ; then woscodename="Catalina"         ;fi
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
                    if [ "$wosname" = "REDHATENTERPRISE" ]       ; then wosname="REDHAT" ; fi
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
    wdom=""
    case "$(sadm_get_ostype)" in
        "LINUX")   
            wdom=""                                                     # No Domain Default
            wdom=`hostname -d`                                          # Get Hostname Domain
            if [ $? -ne 0 ] || [ "$wdom" = "" ]                         # If Domain Name Problem
                then host -4 ${SADM_HOSTNAME} >/dev/null 2>&1           # Try host Command
                     if [ $? -eq 0 ]                                    # Host Command worked ?
                        then wdom=`host ${SADM_HOSTNAME} |head -1 |awk '{ print $1 }' |cut -d. -f2-3`
                             if [ $wdom = ${SADM_HOSTNAME} ] ; then wdom="" ;fi  
                     fi
            fi
            ;;
        "AIX")              
            wdom=`namerslv -s | grep domain | awk '{ print $2 }'`
            ;;
        "DARWIN")              
            wdom=`scutil --dns |grep 'search domain\[0\]' |head -1 |awk -F\: '{print $2}' |tr -d ' '`
            ;;            
    esac

    if [ "$wdom" = "" ] ; then wdom="$SADM_DOMAIN" ; fi                 # No Domain = Def DomainName
    echo "$wdom"

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
        "DARWIN")   whost_ip=`host ${SADM_HOSTNAME} |awk '{ print $4 }' |head -1`
                    #whost_ip=`ifconfig |grep inet | grep broadcast | awk '{ print $2 }'`
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
        "LINUX")    sadm_server_type="P"                                # Physical Server Default
                    if [ "$SADM_DMIDECODE" != "" ]
                       then $SADM_DMIDECODE |grep -i vmware >/dev/null 2>&1 # Search vmware
                            if [ $? -eq 0 ]                             # If vmware was found
                               then sadm_server_type="V"                # If VMware Server
                               else $SADM_DMIDECODE |grep -i virtualbox >/dev/null 2>&1
                                    if [ $? -eq 0 ]                     # If VirtualBox was found
                                        then sadm_server_type="V"       # If VirtualBox Server
                                        else sadm_server_type="P"       # Default Assume Physical
                                    fi 
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
                 if [ "$(sadm_server_type)" = "P" ]
                    then grep -i '^revision' /proc/cpuinfo > /dev/null 2>&1
                         if [ $? -eq 0 ]
                            then wrev=`grep -i '^revision' /proc/cpuinfo |cut -d ':' -f 2`
                                 wrev=`echo $wrev | sed -e 's/^[ \t]*//'`   # Del Lead Space
                                 sadm_server_model="Raspberry Rev.${wrev}"
                         fi
                    else sadm_server_model="VM"                         # Default Virtual Model 
                         # Are we running under VMWare ?
                         A=`dmidecode -s system-manufacturer | awk '{ print $1 }' | tr [A-Z] [a-z]`
                         if [ "$A" = "vmware," ] ; then sadm_server_model="VMWARE" ; fi
                         # Are we running under VirtualBox ? 
                         A=`dmidecode -s bios-version | tr [A-Z] [a-z]`     
                         if [ "$A" = "virtualbox" ] ; then sadm_server_model="VIRTUALBOX" ; fi 
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
#                             RETURN THE SYSTEM ARCHITECTURE 
# --------------------------------------------------------------------------------------------------
sadm_server_arch() {
    case "$(sadm_get_ostype)" in
        "LINUX")    warch=`uname -m`
                    ;;
        "AIX")      warch=`uname -p`  
                    ;;
        "DARWIN")   warch=`uname -m` 
                    ;;
    esac
    echo "$warch"
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
        "DARWIN")   #syspro="system_profiler SPHardwareDataType"
                    #wnbcpu=`$syspro | grep "Number of Processors"| awk -F: '{print$2}' | tr -d ' '`
                    wnbcpu=`sysctl -n hw.ncpu`
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
                    w=`$syspro | grep -i "Speed" |awk -F: '{print $2}'|awk '{print $1}' |tr ',' '.'`
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
        "DARWIN")   #syspro="system_profiler SPHardwareDataType"
                    #wcps=`$syspro | grep -i "Number of Cores"| awk -F: '{print$2}' | tr -d ' '`
                    wcps=`sysctl -n machdep.cpu.core_count`
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
        "DARWIN")   wlcpu=`sysctl -n hw.logicalcpu`
                    wnbcpu=`sysctl -n hw.ncpu`
                    sadm_server_thread_per_core=`echo "$wlcpu / $wnbcpu" | $SADM_BC | tr -d ' '`
                    #sadm_server_thread_per_core=`sysctl -n machdep.cpu.thread_count`
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
        "DARWIN")  wkernel_bitmode=`getconf LONG_BIT`
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
        "DARWIN")   wkernel_version=`uname -r`
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
    if [ "$LIB_DEBUG" -gt 4 ] ;then sadm_write "sadm_load_config_file\n" ; fi

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
        echo "$wline" |grep -i "^SADM_ALERT_REPEAT" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_ALERT_REPEAT=`echo "$wline"  |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_TEXTBELT_KEY" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_TEXTBELT_KEY=`echo "$wline"  |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_TEXTBELT_URL" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_TEXTBELT_URL=`echo "$wline"  |cut -d= -f2 |tr -d ' '` ;fi
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
    SADM_RW_DBPWD=""                                                    # Default Write Pwd is Blank
    SADM_RO_DBPWD=""                                                    # Default ReadOnly Pwd Blank
    if [ "$(sadm_get_fqdn)" = "$SADM_SERVER" ] && [ -r "$DBPASSFILE" ]  # If on Server & pwd file
        then SADM_RW_DBPWD=`grep "^${SADM_RW_DBUSER}," $DBPASSFILE |awk -F, '{ print $2 }'` # RW PWD
             SADM_RO_DBPWD=`grep "^${SADM_RO_DBUSER}," $DBPASSFILE |awk -F, '{ print $2 }'` # RO PWD
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
# mkdir -p ${SADMIN}/{etc/x1,lib,usr/{x2,x3},bin,tmp/{Y1,Y2,Y3/z},opt,var}
sadm_start() {

    # ($SADMIN/log) If log Directory doesn't exist, create it.
    [ ! -d "$SADM_LOG_DIR" ] && mkdir -p $SADM_LOG_DIR
    if [ $(id -u) -eq 0 ]
        then chmod 0775 $SADM_LOG_DIR ; chown ${SADM_USER}:${SADM_GROUP} $SADM_LOG_DIR
    fi

    # ($SADMIN/log/`hostname -s`_SCRIPT.log) If LOG File doesn't exist, Create it & Make it writable
    [ ! -e "$SADM_LOG" ] && touch $SADM_LOG
    if [ $(id -u) -eq 0 ]
        then chmod 666 $SADM_LOG ; chown ${SADM_USER}:${SADM_GROUP} ${SADM_LOG}
    fi

    # If user don't want to append to existing log - Clear it - Else we will append to it.
    [ "$SADM_LOG_APPEND" != "Y" ] && echo " " > $SADM_LOG

    # Write Starting Info in the Log
    if [ -z "$SADM_LOG_HEADER" ] || [ "$SADM_LOG_HEADER" = "Y" ]        # Want to Produce Log Header
        then #echo " " >>$SADM_LOG                                      # Blank line at beginning
             sadm_write "${SADM_80_DASH}\n"                             # Write 80 Dashes Line
             sadm_write "`date` - ${SADM_PN} V${SADM_VER} - SADM Lib. V${SADM_LIB_VER}\n"
             sadm_write "Server Name: $(sadm_get_fqdn) - Type: $(sadm_get_ostype)\n"
             sadm_write "$(sadm_get_osname) $(sadm_get_osversion) Kernel $(sadm_get_kernel_version)\n"
             sadm_write "${SADM_FIFTY_DASH}\n"                          # Write 50 Dashes Line
             sadm_write "\n"
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

    # ($SADMIN/usr/cfg) If User cfg Dir doesn't exist, create it.
    [ ! -d "$SADM_UCFG_DIR" ] && mkdir -p $SADM_UCFG_DIR
    if [ $(id -u) -eq 0 ]
        then chmod 0775 $SADM_UCFG_DIR ; chown ${SADM_USER}:${SADM_GROUP} $SADM_UCFG_DIR
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

    # If System Startup Script does not exist - Create it from the startup template script
    [ ! -r "$SADM_SYS_STARTUP" ] && cp $SADM_SYS_START $SADM_SYS_STARTUP
    if [ $(id -u) -eq 0 ]
        then chmod 0774 $SADM_SYS_STARTUP ; chown ${SADM_USER}:${SADM_GROUP} $SADM_SYS_STARTUP
    fi

    # If System Shutdown Script does not exist - Create it from the shutdown template script
    [ ! -r "$SADM_SYS_SHUTDOWN" ] && cp $SADM_SYS_SHUT $SADM_SYS_SHUTDOWN
    if [ $(id -u) -eq 0 ]
        then chmod 0774 $SADM_SYS_SHUTDOWN ; chown ${SADM_USER}:${SADM_GROUP} $SADM_SYS_SHUTDOWN
    fi

    # ($SADMIN/dat/net) If Network/Subnet Info Directory doesn't exist, create it.
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
            if [ "$(sadm_get_fqdn)" = "$SADM_SERVER" ]
                then chown ${SADM_WWW_USER}:${SADM_WWW_GROUP} $SADM_WWW_DIR
                else chown ${SADM_USER}:${SADM_GROUP} $SADM_WWW_DIR
            fi
    fi

    # $SADMIN/www/dat Dir.
    [ ! -d "$SADM_WWW_DAT_DIR" ] && mkdir -p $SADM_WWW_DAT_DIR
    if [ $(id -u) -eq 0 ]
       then chmod 0775 $SADM_WWW_DAT_DIR
            if [ "$(sadm_get_fqdn)" = "$SADM_SERVER" ]
                then chown ${SADM_WWW_USER}:${SADM_WWW_GROUP} $SADM_WWW_DAT_DIR
                else chown ${SADM_USER}:${SADM_GROUP} $SADM_WWW_DAT_DIR
            fi
    fi

    # $SADMIN/www/doc Dir.
    [ ! -d "$SADM_WWW_DOC_DIR" ] && mkdir -p $SADM_WWW_DOC_DIR
    if [ $(id -u) -eq 0 ]
       then chmod 0775 $SADM_WWW_DOC_DIR
            if [ "$(sadm_get_fqdn)" = "$SADM_SERVER" ]
                then chown ${SADM_WWW_USER}:${SADM_WWW_GROUP} $SADM_WWW_DOC_DIR
                else chown ${SADM_USER}:${SADM_GROUP} $SADM_WWW_DOC_DIR
            fi
    fi

    # $SADMIN/www/lib Dir.
    [ ! -d "$SADM_WWW_LIB_DIR" ] && mkdir -p $SADM_WWW_LIB_DIR
    if [ $(id -u) -eq 0 ]
       then chmod 0775 $SADM_WWW_LIB_DIR
            if [ "$(sadm_get_fqdn)" = "$SADM_SERVER" ]
                then chown ${SADM_WWW_USER}:${SADM_WWW_GROUP} $SADM_WWW_LIB_DIR
                else chown ${SADM_USER}:${SADM_GROUP} $SADM_WWW_LIB_DIR
            fi
    fi

    # $SADMIN/www/images Dir.
    [ ! -d "$SADM_WWW_IMG_DIR" ] && mkdir -p $SADM_WWW_IMG_DIR
    if [ $(id -u) -eq 0 ]
       then chmod 0775 $SADM_WWW_IMG_DIR
            if [ "$(sadm_get_fqdn)" = "$SADM_SERVER" ]
                then chown ${SADM_WWW_USER}:${SADM_WWW_GROUP} $SADM_WWW_IMG_DIR
                else chown ${SADM_USER}:${SADM_GROUP} $SADM_WWW_IMG_DIR
            fi
    fi

    # $SADMIN/www/tmp Dir.
    [ ! -d "$SADM_WWW_TMP_DIR" ] && mkdir -p $SADM_WWW_TMP_DIR
    if [ $(id -u) -eq 0 ]
       then chmod 0775 $SADM_WWW_TMP_DIR
            if [ "$(sadm_get_fqdn)" = "$SADM_SERVER" ]
                then chown ${SADM_WWW_USER}:${SADM_WWW_GROUP} $SADM_WWW_TMP_DIR
                else chown ${SADM_USER}:${SADM_GROUP} $SADM_WWW_TMP_DIR
            fi
    fi


    # Alert Group File ($SADMIN/cfg/alert_group.cfg) MUST be present.
    # If it doesn't exist, create it from initial file ($SADMIN/cfg/.alert_group.cfg)
    if [ ! -r "$SADM_ALERT_FILE" ]                                      # alert_group.cfg not Exist
       then if [ ! -r "$SADM_ALERT_INIT" ]                              # .alert_group.cfg not Exist
               then sadm_write "********************************************************\n"
                    sadm_write "SADMIN Alert Group file not found - $SADM_ALERT_FILE \n"
                    sadm_write "Even Alert Group Template file is missing - $SADM_ALERT_INIT\n"
                    sadm_write "Copy both files from another system to this server\n"
                    sadm_write "Or restore them from a backup\n"
                    sadm_write "Don't forget to review the file content.\n"
                    sadm_write "********************************************************\n"
                    sadm_stop 1                                         # Exit to O/S with Error
               else cp $SADM_ALERT_INIT $SADM_ALERT_FILE                # Copy Template as initial
                    chmod 664 $SADM_ALERT_FILE
            fi
    fi

    # Check Files that are present ONLY ON SADMIN SERVER
    # Slack Channel File ($SADMIN/cfg/slackchannel.cfg) MUST be present.
    # If it doesn't exist create it from initial file ($SADMIN/cfg/.slackchannel.cfg)
    if [ "$(sadm_get_fqdn)" = "$SADM_SERVER" ]
        then if [ ! -r "$SADM_SLACK_FILE" ]                             # If AlertGrp not Exist
                then if [ ! -r "$SADM_SLACK_INIT" ]                     # If AlertInit File not Fnd
                       then sadm_write "********************************************************"
                            sadm_write "SADMIN Slack Channel file is missing - ${SADM_SLACK_FILE}\n"
                            sadm_write "Even Slack Channel template file is missing - $SADM_SLACK_INIT\n"
                            sadm_write "Copy both files from another system to this server\n"
                            sadm_write "Or restore them from a backup\n"
                            sadm_write "Don't forget to review the file content.\n"
                            sadm_write "********************************************************\n"
                            sadm_stop 1                                 # Exit to O/S with Error
                       else cp $SADM_SLACK_INIT $SADM_SLACK_FILE        # Copy Template as initial
                            chmod 664 $SADM_SLACK_FILE
                     fi
             fi
             # Alert History File ($SADMIN/cfg/alert_history.txt) MUST be present.
             if [ ! -r "$SADM_ALERT_HIST" ]                             # If Alert History Missing
                then if [ ! -r "$SADM_ALERT_HINI" ]                     # If Alert Init File not Fnd
                        then touch $SADM_ALERT_HIST                     # Create a Blank One
                        else cp $SADM_ALERT_HINI $SADM_ALERT_HIST       # Copy Initial Hist. File
                     fi
                     chmod 666 $SADM_ALERT_HIST                         # Make sure it's writable
             fi
    fi

    # Feed the (RCH) Return Code History File stating the script is Running (Code 2)
    #SADM_STIME=`date "+%C%y.%m.%d %H:%M:%S"`  ; export SADM_STIME      # Statup Time of Script
    if [ -z "$SADM_USE_RCH" ] || [ "$SADM_USE_RCH" = "Y" ]              # Want to Produce RCH File
        then [ ! -e "$SADM_RCHLOG" ] && touch $SADM_RCHLOG              # Create RCH If not exist
             [ $(id -u) -eq 0 ] && chmod 664 $SADM_RCHLOG               # Change protection on RCH
             [ $(id -u) -eq 0 ] && chown ${SADM_USER}:${SADM_GROUP} ${SADM_RCHLOG}
             WDOT=".......... ........ ........"                        # End Time & Elapse = Dot
             RCHLINE="${SADM_HOSTNAME} $SADM_STIME $WDOT $SADM_INST"    # Format Part1 of RCH File
             RCHLINE="$RCHLINE $SADM_ALERT_GROUP $SADM_ALERT_TYPE 2"    # Format Part2 of RCH File
             echo "$RCHLINE" >>$SADM_RCHLOG                             # Append Line to  RCH File
#             echo "${SADM_HOSTNAME} $SADM_STIME $WDOT $SADM_INST $SADM_ALERT_GROUP $SADM_ALERT_TYPE 2" >>$SADM_RCHLOG
    fi

    # If PID File exist and User want to run only 1 copy of the script - Abort Script
    if [ -e "${SADM_PID_FILE}" ] && [ "$SADM_MULTIPLE_EXEC" != "Y" ]    # PIP Exist - Run One Copy
       then sadm_write "$SADM_PN is already running ... \n"            # Script already running
            sadm_write "PID File ${SADM_PID_FILE} exist ...\n"         # Show PID File Name
            sadm_write "Won't launch a second copy of this script.\n"  # Only one copy can run
            sadm_write "Unless you remove the PID File or set SADM_MULTIPLE_EXEC='Y' in the script.\n"
            DELETE_PID="N"                                              # No Del PID Since running
            sadm_stop 1                                                 # Call SADM Close Function
            exit 1                                                      # Exit with Error
       else echo "$TPID" > $SADM_PID_FILE                               # Create the PID File
            DELETE_PID="Y"                                              # Del PID Since running
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
             sadm_write "Function '${FUNCNAME[0]}' expect one parameter.\n"
             sadm_write "${SADM_ERROR} Received None.\n"                # Advise User
        else SADM_EXIT_CODE=$1                                          # Save Exit Code Received
    fi
    if [ "$SADM_EXIT_CODE" -ne 0 ] ; then SADM_EXIT_CODE=1 ; fi         # Making Sure code is 1 or 0

    # Get End time and Calculate Elapse Time
    sadm_end_time=`date "+%C%y.%m.%d %H:%M:%S"` ; export sadm_end_time  # Get & Format End Time
    sadm_elapse=`sadm_elapse "$sadm_end_time" "$SADM_STIME"`            # Get Elapse - End-Start

    # Start Writing Log Footer
    if [ -z "$SADM_LOG_FOOTER" ] || [ "$SADM_LOG_FOOTER" = "Y" ]        # Want to Produce Log Footer
        then sadm_write "\n"                                            # Blank LIne
             sadm_write "${SADM_FIFTY_DASH}\n"                          # Dash Line
             if [ $SADM_EXIT_CODE -eq 0 ]                               # If script succeeded
                then sadm_write "Script exit code is ${SADM_EXIT_CODE} (Success)\n" # Success 
                else sadm_write "Script exit code is ${SADM_EXIT_CODE} (Failed)\n"  # Failed 
             fi 
             sadm_write "Script execution time is ${sadm_elapse}\n"     # Write the Elapse Time
    fi

    # Update RCH File and Trim It to $SADM_MAX_RCLINE lines define in sadmin.cfg
    if [ -z "$SADM_USE_RCH" ] || [ "$SADM_USE_RCH" = "Y" ]              # Want to Produce RCH File ?
        then XCODE=`tail -1 ${SADM_RCHLOG}| awk '{ print $NF }'`        # Get RCH Code of last line
             if [ "$XCODE" -eq 2 ]                                      # If last Line was code 2
                then XLINE=`wc -l ${SADM_RCHLOG} | awk '{print $1}'`    # Count Nb. Line in RCH File
                     XCOUNT=`expr $XLINE - 1`                           # Count without last line
                     head -$XCOUNT ${SADM_RCHLOG} > ${SADM_TMP_DIR}/xrch.$$ # Create rch file trim
                     rm -f ${SADM_RCHLOG} >/dev/null 2>&1               # Remove old rch file
                     mv ${SADM_TMP_DIR}/xrch.$$ ${SADM_RCHLOG}          # New RCH without code 2
             fi                     
             RCHLINE="${SADM_HOSTNAME} $SADM_STIME $sadm_end_time"      # Format Part1 of RCH File
             RCHLINE="$RCHLINE $sadm_elapse $SADM_INST"                 # Format Part2 of RCH File
             RCHLINE="$RCHLINE $SADM_ALERT_GROUP $SADM_ALERT_TYPE"      # Format Part3 of RCH File
             RCHLINE="$RCHLINE $SADM_EXIT_CODE"                         # Format Part4 of RCH File
             echo "$RCHLINE" >>$SADM_RCHLOG                             # Append Line to  RCH File
             if [ -z "$SADM_LOG_FOOTER" ] || [ "$SADM_LOG_FOOTER" = "Y" ]
                then if [ "$SADM_MAX_RCLINE" -ne 0 ]                     # MaxRCLine != 0 = Trim 
                        then sadm_write "Trim History $SADM_RCHLOG to ${SADM_MAX_RCLINE} lines.\n"
                             sadm_trimfile "$SADM_RCHLOG" "$SADM_MAX_RCLINE" # Trim file to Nb. Line
                        else sadm_write "User requested not to trim the rch file (\$SADM_MAX_RCLINE=0).\n"
                     fi
             fi
             [ $(id -u) -eq 0 ] && chmod 664 ${SADM_RCHLOG}             # R/W Owner/Group R by World
             [ $(id -u) -eq 0 ] && chown ${SADM_USER}:${SADM_GROUP} ${SADM_RCHLOG} # Change RCH Owner
    fi

    # If log size not at zero and user want to use the log.
    if [ -z "$SADM_LOG_FOOTER" ] || [ "$SADM_LOG_FOOTER" = "Y" ]        # Want to Produce Log Footer
        then case $SADM_ALERT_TYPE in
                0)  sadm_write "User requested no alert to be sent when script end.\n"
                    ;;
                1)  if [ "$SADM_EXIT_CODE" -ne 0 ]
                        then sadm_write "User requested alert if script failed (\$SADM_ALERT_TYPE=1), will send alert.\n"
                        else sadm_write "User requested alert only if script fail (\$SADM_ALERT_TYPE=1), won't send alert.\n"
                    fi
                    ;;
                2)  if [ "$SADM_EXIT_CODE" -eq 0 ]
                        then sadm_write "User requested alert on Success of script (\$SADM_ALERT_TYPE=2), will send alert.\n"
                        else sadm_write "User requested alert only on script Success (\$SADM_ALERT_TYPE=2), won't send alert.\n"
                    fi
                    ;;
                3)  sadm_write "User requested alert at the end of each execution (\$SADM_ALERT_TYPE=3), will send alert.\n"
                    ;;
                *)  sadm_write "SADM_ALERT_TYPE isn't set properly, should be between 0 and 3.\n"
                    sadm_write "It's set to $SADM_ALERT_TYPE changing it to 3.\n"
                    SADM_ALERT_TYPE=3
                    ;;
             esac
             if [ $SADM_MAX_LOGLINE -ne 0 ]                             # Max Line in Log Not 0 
                then sadm_write "Trim log $SADM_LOG to ${SADM_MAX_LOGLINE} lines.\n" 
                else sadm_write "User requested not to trim the log (\$SADM_MAX_LOGLINE=0).\n"
             fi 
             sadm_write "`date` - End of ${SADM_PN}\n"                  # Write End Time To Log
             sadm_write "${SADM_80_DASH}\n\n"                           # Write 80 Dash Line
             cat $SADM_LOG > /dev/null                                  # Force buffer to flush
             if [ $SADM_MAX_LOGLINE -ne 0 ]                             # Max Line in Log Not 0 
                then sadm_trimfile "$SADM_LOG" "$SADM_MAX_LOGLINE"      # Trim the Log
             fi                                                         # Else no trim of log made
             chmod 666 ${SADM_LOG} >>/dev/null 2>&1                     # Owner/Group Write Else Read
             chgrp ${SADM_GROUP} ${SADM_LOG} >>/dev/null 2>&1           # Change Log file Group
             [ $(id -u) -eq 0 ] && chmod 664 ${SADM_LOG}                # R/W Owner/Group R by World
             [ $(id -u) -eq 0 ] && chown ${SADM_USER}:${SADM_GROUP} ${SADM_LOG}  # Change Log Owner
    fi

    # Alert the Unix Admin. based on his selected choice
    if [ "$LIB_DEBUG" -gt 4 ] ;then sadm_write "SADM_ALERT_TYPE = ${SADM_ALERT_TYPE}.\n" ; fi

    #wmess=`cat $SADM_LOG`                                       # Log = Message of Alert
    # case $SADM_ALERT_TYPE in
    #   1)  if [ "$SADM_EXIT_CODE" -ne 0 ]                                # Alert On Error Only
    #          then wsub="$SADM_PN reported an error on ${SADM_HOSTNAME}" # Format Subject
    #               wmess="Script execution time is $sadm_elapse"
    #               sadm_send_alert "E" "$SADM_HOSTNAME" "$SADM_ALERT_GROUP" "$wsub" "$wmess" "$SADM_LOG"
    #        fi
    #       ;;
    #   2)  if [ "$SADM_EXIT_CODE" -eq 0 ]                                # Alert On Success Only
    #          then wsub="SUCCESS of $SADM_PN on ${SADM_HOSTNAME}"        # Format Subject
    #               wmess="Script execution time is $sadm_elapse"
    #               sadm_send_alert "I" "$SADM_HOSTNAME" "$SADM_ALERT_GROUP" "$wsub" "$wmess" ""
    #       fi
    #       ;;
    #   3)  if [ "$SADM_EXIT_CODE" -eq 0 ]                                # Always send an Alert
    #         then wsub="SUCCESS of $SADM_PN on ${SADM_HOSTNAME}"         # Format Subject
    #              wmess="Script execution time is $sadm_elapse"
    #              sadm_send_alert "I" "$SADM_HOSTNAME" "$SADM_ALERT_GROUP" "$wsub" "$wmess" ""
    #         else wsub="$SADM_PN reported an error on ${SADM_HOSTNAME}"    # Format Subject
    #              wmess="Script execution time is $sadm_elapse"
    #              sadm_send_alert "I" "$SADM_HOSTNAME" "$SADM_ALERT_GROUP" "$wsub" "$wmess" "$SADM_LOG"
    #       fi
    #       ;;
    #   4)  wsub="Invalid alert type '$SADM_ALERT_TYPE' on $SADM_HOSTNAME" # Format Subject
    #       wmess="Correct problem in your script."
    #       sadm_send_alert "E" "$SADM_HOSTNAME" "$SADM_ALERT_GROUP" "$wsub" "$wmess" ""
    #       ;;
    # esac
    # if [ "$LIB_DEBUG" -gt 4 ] ;then sadm_write "wsub = $wsub" ; fi


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

    # If on the SADMIN server, copy the script final log and rch to web data section.
    # If we don't do that, log look incomplete & script seem to be always running on web interface.
    if [ "$(sadm_get_fqdn)" = "$SADM_SERVER" ]                         # Only run on SADMIN 
       then cp $SADM_LOG    ${SADM_WWW_DAT_DIR}/${SADM_HOSTNAME}/log
            if [ -z "$SADM_USE_RCH" ] || [ "$SADM_USE_RCH" = "Y" ]     # Want to Produce RCH File
               then cp $SADM_RCHLOG ${SADM_WWW_DAT_DIR}/${SADM_HOSTNAME}/rch
            fi 
    fi

    return $SADM_EXIT_CODE
}


# --------------------------------------------------------------------------------------------------
# Send an Alert
#
# 1st Parameter could be a [S]cript, [E]rror, [W]arning, [I]nfo :
#  [S]      If it is a SCRIPT ALERT (Alert Message will include Script Info)
#           For type [S] Default Group come from sadmin.cfg or user can modify it
#           by altering SADM_ALERT_GROUP variable in his script.
#           ** Alert issue from a script will not be assign a reference no.
#
#  [E/W/I]  ERROR, WARNING OR INFORMATION ALERT are detected by System Monitor.
#           For this type [M] Warning and Error Alert Group are taken from the host
#           System Monitor file ($SADMIN/cfg/hostname.smon).
#           In System monitor file Warning are at column 'J' and Error at col. 'K'.
#           ** Error and Warning (Not Info) Alert issue from SADMIN SysMon will be
#           assign a reference no. and will be included in the alert message.
#
# 2nd Parameter    : Event date and time (YYYY/MM/DD HH:MM)
# 3th Parameter    : Server Name Where Alert come from
# 4th Parameter    : Script Name (or "" if not a script)
# 5th Parameter    : Alert Group Name to send Message
# 6th Parameter    : Subject/Title
# 7th Parameter    : Alert Message
# 8th Parameter    : Full Path Name of the attachment (If used, else blank)
#
# Example of parameters: 
# 'E,W,I,S' EVENT_DATE_TIME HOST_NAME SCRIPT_NAME ALERT_GROUP SUBJECT MESSAGE ATTACHMENT_PATH
#
# Function return value 
#  0 = 
#  1 = Error - Aborted could not send alert.
#  2 = 
#  3 = Alert older than 24 hrs - Alert wasn't send
# --------------------------------------------------------------------------------------------------
#
sadm_send_alert() {
    LIB_DEBUG=0                                                        # If Debugging the Library

    # Validate the Number of parameter received.
    if [ $# -ne 8 ]                                                     # Invalid No. of Parameter
        then sadm_write "Invalid number of argument received by function ${FUNCNAME}.\n"
             sadm_write "Should be 8 we received $# : $* \n"            # Show what received
             return 1                                                   # Return Error to caller
    fi

    # Save Parameters Received (After Removing leading and trailing Spaces.
    atype=`echo "$1" |awk '{$1=$1;print}' |tr "[:lower:]" "[:upper:]"`  # [S]cript [E]rr [W]arn [I]nfo
    atime=`echo "$2" | awk '{$1=$1;print}'`                             # Alert Event Date AND Time
    adate=`echo "$2"   | awk '{ print $1 }'`                            # Alert Date without time
    ahour=`echo "$2"   | awk '{ print $2 }'`                            # Alert Time without date
    aserver=`echo "$3" | awk '{$1=$1;print}'`                           # Server where alert Come
    ascript=`echo "$4" | awk '{$1=$1;print}'`                           # Script Name 
    agroup=`echo "$5"  | awk '{$1=$1;print}'`                           # SADM AlertGroup to Advise
    asubject="$6"                                                       # Save Alert Subject
    amessage="$7"                                                       # Save Alert Message
    aattach="$8"                                                        # Save Attachment FileName
    acounter="01"                                                       # Default alert Counter
    if [ $LIB_DEBUG -gt 4 ]                                             # Debug Info List what Recv.
       then printf "\n\nFunction '${FUNCNAME}' parameters received :\n"
            sadm_write "atype=$atype \n"                                # Show Alert Type
            sadm_write "atime=$atime \n"                                # Show Event Date & Time
            sadm_write "aserver=$aserver \n"                            # Show Server Name
            sadm_write "ascript=$ascript \n"                            # Show Script Name
            sadm_write "agroup=$agroup \n"                              # Show Alert Group
            sadm_write "asubject=\"$asubject\"\n"                       # Show Alert Subject/Title
            sadm_write "amessage=\"$amessage\"\n"                       # Show Alert Message
            sadm_write "aattachment=\"$aattach\"\n"                     # Show Alert Attachment File
    fi

    # Is there is an attachment and if the attachment is not readable ?
    if [ "$aattach" != "" ] && [ ! -r "$aattach" ]                      # Can't read Attachment File
       then sadm_write "Error in ${FUNCNAME} - Can't read attachment file '$aattach'\n"
            return 1                                                    # Return Error to caller
    fi

    # Does the Alert Group exist in the Group in alert File ?
    grep -i "^$agroup " $SADM_ALERT_FILE >/dev/null 2>&1                # Search Group in front line
    if [ $? -ne 0 ]                                                     # Group Missing in GrpFile
        then sadm_write "\nAlert Group '$agroup' missing from $SADM_ALERT_FILE \n"
             sadm_write "  - Alert date/time    : $atime \n"            # Show Event Date & Time
             sadm_write "Changing alert group from '$agroup' to 'default'\n"
             agroup='default'                                           # Change Alert Group
    fi

    # Determine if a [M]ail, [S]lack, [T]exto or [C]ellular  message need to be issued
    agroup_type=`grep -i "^$agroup " $SADM_ALERT_FILE |awk '{ print $2 }'` # [S/M/T/C] Group
    agroup_type=`echo $agroup_type |awk '{$1=$1;print}' |tr  "[:lower:]" "[:upper:]"`
    if [ "$agroup_type" != "M" ] && [ "$agroup_type" != "S" ] &&
       [ "$agroup_type" != "T" ] && [ "$agroup_type" != "C" ] 
       then wmess="Invalid Alert Group Type '$agroup_type' for '$agroup' in $SADM_ALERT_FILE"
            sadm_write "${wmess}\n"
            return 1
    fi

    # Calculate some data that we will need later on 
    aepoch=$(sadm_date_to_epoch "$atime")                               # Convert AlertTime to Epoch
    cepoch=`date +%s`                                                   # Get Current Epoch Time
    aage=`expr $cepoch - $aepoch`                                       # Age of Alert in Seconds.
    if [ $SADM_ALERT_REPEAT -ne 0 ]                                     # If Config = Alert Repeat
        then MaxRepeat=`echo "(86400 / $SADM_ALERT_REPEAT)" | $SADM_BC` # Calc. Nb Alert Per Day
        else MaxRepeat=1                                                # MaxRepeat=1 NoAlarm Repeat
    fi
    NbDaysOld=0                                                         # Default Alert Age in Days
    if [ $aage -ge 86400 ] ;then NbDaysOld=`echo "$aage / 86400" |$SADM_BC` ;fi # Alert age in Days
    if [ "$LIB_DEBUG" -gt 4 ]                                           # Debug Info List what Recv.
        then sadm_write "Alert Epoch Time     - aepoch=$aepoch \n"
             sadm_write "Current EpochTime    - cepoch=$cepoch \n"
             sadm_write "Age of alert in sec. - aage=$aage \n"
             sadm_write "Age of alert in days - NbDaysOld=$NbDaysOld \n"
    fi 

    # GREP HISTORY FILE TO SEE IF ALERT ALREADY EXIST.
    if [ "$atype" != "S" ]                                              # If not a Script alert 
        then asearch=";$adate;$atype;$aserver;$agroup;$asubject;"       # Alert from a Script
        else asearch=";$ahour;$adate;$atype;$aserver;$agroup;$asubject;" # Alert from Sysmon 
    fi
    if [ "$LIB_DEBUG" -gt 4 ]                                           # If under Debug
        then sadm_write "Search history for \"${asearch}\"\n"           # Show Search String
             grep "${asearch}" $SADM_ALERT_HIST |tee -a $SADM_LOG       # Show grep result
    fi 
    grep "${asearch}" $SADM_ALERT_HIST >>/dev/null 2>&1                 # Grep Alert History file
    RC=$?                                                               # Save Grep Result
    if [ "$LIB_DEBUG" -gt 4 ] ; then sadm_write "Search Return is $RC\n" ; fi



    # If same alert wasn't found for today and it's not a script alert (it's a SysMon Alert).
    #  - Check if there was the same alert yesterday
    #  - If same alert is found for yesterday :
    #    - If Age of alert is greater than 86400 Seconds (24Hrs) then Alert too old.
    #    - If Age of alert is less then 85500 Seconds (23Hrs 45Min) then alert already sent.
    #    - If Age of alert is greater than 85500 Seconds consider it as a new alert.
    if [ "$RC" -ne 0 ] && [ "$atype" != "S" ]
        then if [ "$LIB_DEBUG" -gt 4 ] ; then sadm_write "Alert wasn't found and it's a SysMon Alert.\n" ; fi
             ydate=$(date --date="yesterday" +"%Y.%m.%d")               # Date Day before the event
             yalertid=`printf "%s;%s;%s;%s;%s" "$ydate" "$atype" "$aserver" "$agroup" "$asubject"`
             grep "$yalertid" $SADM_ALERT_HIST  >>/dev/null 2>&1        # Search SameAlert Yesterday
             YRC=$?                                                     # Save Yesterday Return Code
             if [ "$YRC" -eq 0 ]                                        # Same Alert Yesterday Found
                then yepoch=`grep "$yalertid" $SADM_ALERT_HIST |tail -1 |awk -F';' '{ print $1 }'` 
                     yage=`expr $cepoch - $yepoch`                      # Yesterday Alert Age in Sec
                     if [ "$yage" -lt 86400 ]                           # Yesterday alert age < 24hr
                        then if [ "$LIB_DEBUG" -gt 4 ]                  # If Under Debug
                                then sadm_write "Same alert yesterday in history file ($yepoch)\n" 
                             fi
                             return 2                                   # Return 2 = Already Sent
                        else if [ "$LIB_DEBUG" -gt 4 ]                  # If Under Debug
                                then sadm_write "Sysmon alert older than 24Hrs ($NbDaysOld days).\n" 
                                     sadm_write "Consider it as a new alert.\n"
                             fi
                     fi
             fi
    fi


    # If Alert is older than 24 hours, 
    if [ $aage -gt 86400 ]                                              # Alert older than 24Hrs ?
        then if [ "$LIB_DEBUG" -gt 4 ]                                  # If Under Debug
                then sadm_write "Alert older than 24 Hrs ($aage sec.).\n" 
             fi
             return 3
        else if [ "$LIB_DEBUG" -gt 4 ]                                  # If Under Debug
                then sadm_write "Alert issued less than 24 Hrs ($aage sec.) ago.\n" 
             fi
    fi

    # ALERT WASN'T FOUND IN HISTORY FILE - THIS IS A NEW ALERT IF NOT OLDER THAN 24 Hours.
    if [ "$RC" -ne 0 ]                                                  # Alert wasn't found in Hist
        then acounter=0                                                 # Init History Alert Counter
             if [ "$LIB_DEBUG" -gt 4 ] 
                then sadm_write "Alert not in history file.\n" 
                     sadm_write "AlertEpoch:$aepoch  Cur.Epoch:$cepoch - AlertAge:${aage} Sec.\n"
             fi
    fi

    # ALERT WAS FOUND IN HISTORY FILE 
    if [ $RC -eq 0 ]                                                    # Same Alert was found
        then if [ "$LIB_DEBUG" -gt 4 ] 
                then sadm_write "AlertEpoch:$aepoch  Cur.Epoch:$cepoch - AlertAge:${aage} Sec.\n"
             fi
             # Alert were found in history and SADM_ALERT_REPEAT=0 then no need to repeat stop here.
             if [ $SADM_ALERT_REPEAT -eq 0 ]                            # User want no alert repeat
                then wmsg="Alert already sent, you asked to sent alert only once"  # No Alert repeat
                     if [ "$LIB_DEBUG" -gt 4 ]                          # Under Debug          
                        then sadm_write "$wmsg - (SADM_ALERT_REPEAT set to $SADM_ALERT_REPEAT).\n"
                     fi
                     return 2                                           # Return 2 = Duplicate Alert
             fi             

            # Get Actual Alert Sent Counter
            acounter=`grep "$alertid" $SADM_ALERT_HIST |tail -1 |awk -F\; '{print $2}'` 

            if [ $acounter -ge $MaxRepeat ]                             # Max Alert Nb. not Reached
               then if [ "$LIB_DEBUG" -gt 4 ]                           # Under Debug
                       then sadm_write "Maximun number of Alert ($MaxRepeat) reached ($aepoch).\n" 
                    fi
                    return 2
            fi 

            if [ $aage -gt 87300 ]                                      # 87300=24Hrs+15Min
               then if [ "$LIB_DEBUG" -gt 4 ]                  # Under Debug
                       then sadm_write "Alert older than 24 Hrs ($NbDaysOld days).\n" 
                    fi
                    return 3
            fi 

            WaitSec=`echo "$acounter * $SADM_ALERT_REPEAT" | $SADM_BC`        # Next Alert Elapse Seconds
            if [ "$LIB_DEBUG" -gt 4 ] 
                then msg="AlertCounter: $acounter"
                     #msg="$msg  NxtCounter: $ncounter"
                     msg="$msg  MaxRepeat: $MaxRepeat"
                     msg="$msg  AlertInterval: $SADM_ALERT_REPEAT"
                     msg="$msg  NextAlertAt: $WaitSec"
                     sadm_write "${msg}\n"
            fi

            if [ $aage -le $WaitSec ]                                  # Repeat Time not reached
                then xcount=`expr $WaitSec - $aage` 
                     next_alert_epoch=`expr $cepoch + $xcount` 
                     next_alert_time=$(sadm_epoch_to_date "$next_alert_epoch")
                     msg="Waiting - Next notification will be send in $xcount seconds around ${next_alert_time}."
                     if [ "$LIB_DEBUG" -gt 4 ] ;then sadm_write "${msg}\n" ;fi 
                     return 2                                            # Return 2 = Duplicate Alert
            fi 
    fi  


    # Final Setup before sending alert
    acounter=`expr $acounter + 1`                                       # Increase alert counter
    if [ $acounter -gt 1 ] ; then amessage="(Repeat) $amessage" ;fi     # Insert Repeat if Count>1
    acounter=`printf "%02d" "$acounter"`                                # Make counter two digits
    if [ "$LIB_DEBUG" -gt 4 ] ;then sadm_write "Repeat alert ($aepoch)-($acounter)-($alertid)\n" ;fi
    NxtInterval=`echo "$acounter * $SADM_ALERT_REPEAT" | $SADM_BC`      # Next Alert Elapse Seconds 
    NxtEpoch=`expr $NxtInterval + $aepoch`                              # Next Alarm Epoch Time
    NxtAlarmTime=$(sadm_epoch_to_date "$NxtEpoch")                      # Next Alarm Date/Time

    # Construct Email Subject 
    case "$atype" in                                                    # Depending on Alert Type
        e|E) ws="SADM ERROR: ${aserver} ${asubject}"                    # Construct Mess. Subject
             ;;
        w|W) ws="SADM WARNING: ${aserver} ${asubject}"                  # Build Warning Subject
             ;;
        i|I) ws="SADM INFO: ${aserver} ${asubject}"                     # Build Info Mess Subject
             ;;
        s|S) ws="SADM SCRIPT: ${asubject}"                              # Build Script Msg Subject
             ;;
        *)   ws="Invalid Alert Type ($atype): ${aserver} ${asubject}"   # Invalid Alert type Message
             ;;
    esac
    if [ "$LIB_DEBUG" -gt 4 ] ; then sadm_write "Alert Subject will be : $ws \n" ; fi

    # Construct Body of the Email.
    mdate=`date "+%Y.%m.%d %H:%M"`                                      # Date & Time of Email
    hepoch=$(sadm_date_to_epoch "$mdate")                               # Date/Time of mail to Epoch
    if [ "$atype" = "S" ] ; then body0="SADM Script Info" ; else body0="SADM Sysmon Info" ;fi 
    case "$agroup_type" in
        m|M)    body1=`printf "%-15s: %s" "Email date/time" "$mdate"`   # Date/Time of email 
                body4=`printf "%-15s: %s" "Event Message"  "$amessage"` # Body of the message
                ;;
        c|C)    body1=`printf "%-15s: %s" "SMS date/time" "$mdate"`     # Date the Cell Texto Sent
                body4=`printf "%s" "$amessage"`                         # Body of the message
                ;;
        s|S)    body1=`printf "%-15s: %s" "Slack sent date/time" "$mdate"` # Date/Time Slack Sent 
                body4=`printf "%-15s: %s" "Event Message" "$amessage"`  # Body of the message
                ;;
        t|T)    body1=`printf "%-15s: %s" "SMS date/time" "$mdate"`     # Date the Texto was Sent
                body4=`printf "%s" "$amessage"`                         # Body of the message
                ;;
    esac             
    body2=`printf "%-15s: %s" "Event date/time" "$atime"`               # Date/Time event occured
    if [ $acounter -eq 1 ] && [ $MaxRepeat -eq 1 ]                      # If Alarm is 1 of 1 bypass
        then body3=""
        else body3=`printf "%-15s: %02d of %02d" "Alert counter" "$acounter" "$MaxRepeat"` 
    fi 
    if [ $SADM_ALERT_REPEAT -ne 0 ] && [ $acounter -ne $MaxRepeat ]     # If Repeat or Not Last
       then body3=`printf "%s, next notification around %s" "$body3" "$NxtAlarmTime"`    # Time NextAlert
    fi
    #if [ $SADM_ALERT_REPEAT -eq 0 ] || [ $acounter -eq $MaxRepeat ]     # Final Alert Message
    #   then body3=`printf "%s, final notice." "$body3"`                 # Insert Final Notice
    #fi
    #body4=`printf "%-15s: %s" "Event Message"   "$amessage"`            # Body of the message
    body5=`printf "%-15s: %s" "Event on system" "$aserver"`             # Server where alert occured
    body6=`printf "%-15s: %s" "Script Name    " "$ascript"`             # Script Name
    if [ "$body3" != "" ] 
       then body=`printf "%s\n%s\n%s\n%s\n%s\n%s\n%s" "$body0" "$body4" "$body1" "$body2" "$body3" "$body5" "$body6"`
       else body=`printf "%s\n%s\n%s\n%s\n%s\n%s\n%s" "$body0" "$body4" "$body1" "$body2" "$body5" "$body6"`
    fi
    if [ "$LIB_DEBUG" -gt 4 ] ; then sadm_write "Alert body will be : $body \n" ; fi


    # Send the Alert Message using the type of alert requested
    case "$agroup_type" in

        # SEND EMAIL ALERT -------------------------------------------------------------------------
        m|M )   aemail=`grep -i "^$agroup " $SADM_ALERT_FILE |awk '{ print $3 }'` # Get Emails of Group
                aemail=`echo $aemail | awk '{$1=$1;print}'`             # Del Leading/Trailing Space
                # Send the Email using 'mutt'.
                if [ "$LIB_DEBUG" -gt 4 ] ; then sadm_write "Email alert sent to $aemail \n" ; fi 
                if [ "$aattach" != "" ]                                 # If Attachment Specified
                    then if [ "$LIB_DEBUG" -gt 4 ] 
                            then sadm_write "$SADM_MUTT -s \"$ws\" -a \"$aattach\" $aemail \n"
                         fi 
                         #printf "%s\n" "$body" | $SADM_MUTT -s "$ws" "$aemail" -a "$aattach"  >>$SADM_LOG 2>&1 
                         printf "%s\n" "$body" | $SADM_MAIL -s "$ws" -a "$aattach" $aemail >>$SADM_LOG 2>&1 
                    else if [ "$LIB_DEBUG" -gt 4 ] 
                            then sadm_write "$SADM_MAIL -s \"$ws\" $aemail \n"
                         fi
                         printf "%s\n" "$body" | $SADM_MAIL -s "$ws" $aemail  >>$SADM_LOG 2>&1 
                fi
                RC=$?                                                   # Save Error Number
                if [ $RC -eq 0 ]                                        # If Error Sending Email
                    then wstatus="Email sent to $aemail" 
                    else wstatus="Error sending email to $aemail"
                         sadm_write "${wstatus}\n"                      # Advise USer
                fi
                ;;

        # SEND ALERT TO CELLULAR NUMBER ------------------------------------------------------------
        C)  acell=`grep -i "^$agroup " $SADM_ALERT_FILE |awk '{ print $3 }'` # GetGroupMembers Cell#
            acell=`echo $acell | awk '{$1=$1;print}'`                   # Del Leading/Trailing Space
            if [ "$LIB_DEBUG" -gt 4 ] ; then sadm_write "SMS alert sent to $acell \n" ; fi 
            # Send the SMS unsing TextBelt
            reponse=`${SADM_CURL} -s -X POST $SADM_TEXTBELT_URL -d phone=$acell -d "message=$body" -d key=$SADM_TEXTBELT_KEY`
            # Test Cellular Return Code
            echo "$reponse" |grep -i "\"success\":true," >/dev/null 2>&1 # Success Response ?
            RC=$?                                                       # Save Error Number
            if [ $RC -eq 0 ]                                            # If Error Sending Email
                then wstatus="SMS message to cellular $acell" 
                else wstatus="Error sending SMS message to $acell"
                     sadm_write "${wstatus}\n"                          # Advise User
                     sadm_write "${reponse}\n"                          # Error msg from Textbelt
                     RC=1                                               # When Error Return Code 1
            fi
            ;;

        # SEND SLACK ALERT -------------------------------------------------------------------------
        S)  aslack_channel=`grep -i "^$agroup " $SADM_ALERT_FILE | awk '{ print $3 }'` 
            aslack_channel=`echo $aslack_channel | awk '{$1=$1;print}'` # Del Leading/Trailing Space
            # Search Slack Channel file for selected channel
            grep -i "^$aslack_channel " $SADM_SLACK_FILE >/dev/null 2>&1 # Grep Channel Name
            if [ $? -ne 0 ]                                             # Channel not in Chn File
                then sadm_write "ERROR: Slack Channel '$aslack_channel' missing in ${SADM_SLACK_FILE}\n"
                     return 1                                           # Return Error to caller
            fi
            # Get the WebHook for the selected Channel
            slack_hook_url=`grep -i "^$aslack_channel " $SADM_SLACK_FILE |awk '{ print $2 }'`
            if [ "$LIB_DEBUG" -gt 4 ]
                then sadm_write "Slack Channel=$aslack_channel got Slack Webhook=${slack_hook_url}\n"
            fi
            # Included last 50 lines of attachment file (if specified)
            if [ "$aattach" != "" ]                                     # If Attachment Specified
                then logtail=`tail -50 ${aattach}`
                     body="${body}\n\n*-----Attachment-----*\n${logtail}"
            fi
            # If Script Error include URL Link to view script log in message
            if [ "$atype" = "S" ]                                       # If SMS concerning Script
                then SNAME=`echo ${asubject} |awk '{ print $1 }'`       # Get Script Name
                     LOGFILE="${aserver}_${SNAME}.log"                  # Assemble log Script Name
                     LOGNAME="${SADM_WWW_DAT_DIR}/${aserver}/log/${LOGFILE}" # Add Dir. Path 
                     URL_VIEW_FILE='/view/log/sadm_view_file.php'       # View File Content URL
                     LOGURL="http://sadmin.${SADM_DOMAIN}/${URL_VIEW_FILE}?filename=${LOGNAME}" 
                     body="${body}\nEvent log link  :\n${LOGURL}"       # Insert Log URL In Mess
            fi
            slack_text="$body"                                          # Set Alert Text
            escaped_msg=$(echo "${slack_text}" |sed 's/\"/\\"/g' |sed "s/'/\'/g" |sed 's/`/\`/g')
            slack_text="\"text\": \"${escaped_msg}\""                   # Set Final Text Message
            slack_icon="warning"
            markdown="\"mrkdwn\": true,"
            #json="{\"channel\": \"${aslack_channel}\", \"username\":\"${slack_username}\", \"icon_emoji\":\":${slack_icon}:\", ${markdown} ${slack_text}}"
            json="{\"channel\": \"${aslack_channel}\", \"icon_emoji\": \":${slack_icon}:\", ${markdown} ${slack_text}}"
            if [ "$LIB_DEBUG" -gt 4 ]
                then sadm_write "$SADM_CURL -s -d \"payload=$json\" ${slack_hook_url}\n"
            fi
            #SLACK_CMD1="$SADM_CURL -X POST -H 'Content-type: application/json' --data"
            SRC=`$SADM_CURL -s -d "payload=$json" $slack_hook_url`
            if [ "$LIB_DEBUG" -gt 4 ] ; then sadm_write "Status after send to Slack is ${SRC}\n" ;fi
            # Test Slack Return Code
            if [ $SRC = "ok" ]                                          # If Sent Successfully
                then RC=0                                               # Set Return code to 0
                     wstatus="Slack message sent with success to $agroup ($SRC)" 
                else wstatus="Error sending Slack message to $agroup ($SRC)"
                     sadm_write "${wstatus}\n"                          # Advise User
                     RC=1                                               # When Error Return Code 1
            fi
            ;;

        # SEND TEXTO/SMS ALERT ---------------------------------------------------------------------
        T)  amember=`grep -i "^$agroup " $SADM_ALERT_FILE | awk '{ print $3 }'` # Get Group Members 
            amember=`echo $amember | awk '{$1=$1;print}'`               # Del Leading/Trailing Space
            # Send SMS to Texto Group Member
            total_error=0                                               # Total Error Counter Reset
            RC=0                                                        # Function Return Code Def.
            for i in $(echo $amember | tr ',' '\n')                     # For each member of group
                do
                if [ "$LIB_DEBUG" -gt 4 ]                               # Under Debugging Mode
                    then printf "\nProcessing sms member $i"            # Show Current Member 
                fi
                # Get the Group Member of the Alert Group (Cellular No.)
                acell=` grep -i "^$i " $SADM_ALERT_FILE |awk '{ print $3 }'` # Get GroupMembers Cell
                acell=`echo $acell   | awk '{$1=$1;print}'`             # Del Leading/Trailing Space
                # Check Member Type (Should be 'C')
                agtype=`grep -i "^$i " $SADM_ALERT_FILE |awk '{ print $2 }'` # GroupType should be C
                agtype=`echo $agtype | awk '{$1=$1;print}'`             # Del Leading/Trailing Space
                agtype=`echo $agtype | tr "[:lower:]" "[:upper:]"`      # Make Grp Type is uppercase
                if [ "$agtype" != "C" ]                                 # Member should be type [C]
                    then sadm_write "Member of $agroup $i is not a type 'C' alert.\n"
                         sadm_write "Alert not send to $i, proceeding with next member.\n"
                         total_error=`expr $total_error + 1`
                         continue
                fi
                # Send SMS to Cell Member ($acell)
                reponse=`${SADM_CURL} -s -X POST $SADM_TEXTBELT_URL -d phone=$acell -d "message=$body" -d key=$SADM_TEXTBELT_KEY`
                echo "$reponse" | grep -i "\"success\":true," >/dev/null 2>&1   # Success Response ?
                RC=$?                                                   # Save Error Number
                if [ $RC -eq 0 ]                                        # If Error Sending Email
                    then wstatus="SMS message sent to group $agroup ($acell)" 
                    else wstatus="Error ($RC) sending SMS message to group $agroup ($acell)"
                         sadm_write "${wstatus}\n"                      # Advise USer
                         sadm_write "${reponse}\n"                      # Error msg from Textbelt
                         total_error=`expr $total_error + 1`
                         RC=1                                           # When Error Return Code 1
                fi
                done
            # Test Cellular Return Code
            if [ $total_error -ne 0 ] ; then RC=1 ; else RC=0 ; fi      # If Error Sending SMS
            ;;

        # INVALID ALERT TYPE -----------------------------------------------------------------------
        *)  sadm_write "Error in ${FUNCNAME} - Alert Group Type '$agroup_type' not supported.\n"
            RC=1                                                        # Something went wrong
            ;;
    esac
    write_alert_history "$atype" "$atime" "$agroup" "$aserver" "$asubject" "$acounter" "$wstatus"
    LIB_DEBUG=0                                                        # If Debugging the Library
    return $RC

}

 
# --------------------------------------------------------------------------------------------------
# Write Alert History File
# Parameters:
#   1st = Alert Type         = [S]cript [E]rror [W]arning [I]nfo
#   2nd = Alert Date/Time    = Alert/Event Date and Time (YYYY/MM/DD HH:MM)
#   3th = Alert Group Name   = Alert Group Name to Advise (Must exist in $SADMIN/cfg/alert_group.cfg)
#   4th = Server Name        = Where the event happen
#   5th = Alert Description  = Alert Message
#   6th = Alert Sent Counter = Incremented after an alert is sent
#   7th = Alert Status Mess. = Status got afetr sending alert
#                               - Wait $elapse/$SADM_REPEAT
#
# Example : 
#   write_alert_history "$atype" "$atime" "$agroup" "$aserver" "$asubject" "$acount" "$astatus"
# --------------------------------------------------------------------------------------------------
#
write_alert_history() {
      
    # Validate the Number of parameter received.
    if [ $# -ne 7 ]                                                     # Invalid No. of Parameter
        then sadm_write "Invalid number of argument received by function ${FUNCNAME}.\n"
             sadm_write "Should be 7, we received $# : $* \n"           # Show what received
             return 1                                                   # Return Error to caller
    fi

    htype=$1                                                            # Script,Error,Warning,Info
    htype=`echo $htype |tr "[:lower:]" "[:upper:]"`                     # Make Alert Type Uppercase
    hdatetime=`echo "$2"  | awk '{$1=$1;print}'`                        # Save Event Date & Time
    hdate=`echo "$2"      | awk '{ print $1 }'`                         # Save Event Date
    htime=`echo "$2"      | awk '{ print $2 }'`                         # Save Event Time
    hgroup=`echo "$3"     | awk '{$1=$1;print}'`                        # SADM AlertGroup to Advise
    hserver=`echo "$4"    | awk '{$1=$1;print}'`                        # Save Server Name
    hsub="$5"                                                           # Save Alert Subject
    hcount="$6"                                                         # Save Alert Reference No.
    hstat="$7"                                                          # Save Alert Send Status
    hepoch=$(sadm_date_to_epoch "$hdatetime")                           # Convert Event Time to Epoch
    cdatetime=`date "+%C%y%m%d_%H%M"`                                   # Current Date & Time
    #
    hline=`printf "%s;%s" "$hepoch" "$hcount" `                         # Epoch and AlertSent Counter
    hline=`printf "%s;%s;%s;%s" "$hline" "$htime" "$hdate" "$htype"`    # Alert time,date,type
    hline=`printf "%s;%s;%s;%s" "$hline" "$hserver" "$hgroup" "$hsub"`  # Alert Server,Group,Subject
    hline=`printf "%s;%s;%s" "$hline" "$hstat" "$cdatetime"`            # Alert Status,Cur Date/Time
    echo "$hline" >>$SADM_ALERT_HIST                                    # Write Alert History File
    if [ "$LIB_DEBUG" -gt 4 ] ; then sadm_write "Line added to History : $hline \n" ; fi 

}


# --------------------------------------------------------------------------------------------------
# THINGS TO DO WHEN FIRST CALLED
# --------------------------------------------------------------------------------------------------
    SADM_STIME=`date "+%C%y.%m.%d %H:%M:%S"`  ; export SADM_STIME       # Statup Time of Script

    if [ "$LIB_DEBUG" -gt 4 ] ;then sadm_write "main: grepping /etc/environment\n" ; fi
    grep "SADMIN=" /etc/environment >/dev/null 2>&1                     # Do Env.File include SADMIN
    if [ $? -ne 0 ]                                                     # SADMIN missing in /etc/env
        then echo "export SADMIN=$SADMIN" >> /etc/environment           # Then add it to the file
    fi
    sadm_load_config_file                                               # Load sadmin.cfg file
    sadm_check_requirements                                             # Check Lib Requirements
    if [ $? -ne 0 ] ; then exit 1 ; fi                                  # If Requirement are not met
    export SADM_SSH_CMD="${SADM_SSH} -qnp${SADM_SSH_PORT}"              # SSH Command to SSH CLient
    export SADM_USERNAME=$(whoami)                                      # Current User Name
    if [ "$LIB_DEBUG" -gt 4 ] ;then sadm_write "Library Loaded,\n" ; fi
    