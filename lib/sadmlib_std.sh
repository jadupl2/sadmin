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
# 2020_07_11 Fixes: v3.42 Date and time was not include in script log.
# 2020_07_12 Update: v3.43 When virtual system 'sadm_server_model' return (VMWARE,VIRTUALBOX,VM)
# 2020_07_20 Update: v3.44 Change permission for log and rch to allow normal user to run script.
# 2020_07_23 New: v3.45 New function 'sadm_ask', show received msg & wait for y/Y (return 1) or n/N (return 0)
# 2020_07_29 Fix: v3.46 Fix date not showing in the log under some condition.
# 2020_08_10 New: v3.47 Add module "sadm_sleep", sleep for X seconds with progressing info.
# 2020_08_10 Fix: v3.48 Remove improper '::' characters to was inserted im messages.
# 2020_08_12 New: v3.49 Global Var. $SADM_UCFG_DIR was added to refer $SADMIN/usr/cfg directory.
# 2020_08_18 New: v3.50 Change Screen Attribute Variable (Remove 'SADM_', $SADM_RED is NOW $RED).
# 2020_08_19 Fix: v3.51 Remove some ctrl character from the log (sadm_write()).
# 2020_08_20 Fix: v3.52 Adjust sadm_write method
# 2020_09_05 Fix: v3.53 Added Start/End/Elapse Time to Script Alert Message.
# 2020_09_09 Update: v3.54 Remove server name from Alert message (already in subject)
# 2020_10_01 Update: v3.55 Add Host name in email, when alert come from sysmon.
# 2020_10_05 Update: v3.56 Remove export for screen attribute variables.
# 2020_11_24 Update: v3.57 Revisit and Optimize 'send_alert' function.
# 2020_12_02 Update: v3.58 Optimize and fix some problem with Slack ans SMS alerting function.
# 2020_12_12 Update: v3.59 Add 'sadm_capitalize"function, add PID TimeOut, enhance script footer.
# 2020_12_17 Update: v3.60 sadm_get_osname() on 'CentOSStream' now return 'CENTOS'.
# 2020_12_23 Fix: v3.61 Log Header (SADM_LOG_HEADER) & Footer (SADM_LOG_FOOTER) were always produce.
# 2020_12_24 Fix: v3.62 Fix problem with capitalize function.
# 2020_12_26 Update: v3.63 Add Global Variable SADM_WWW_ARC_DIR for Server Archive when deleted
# 2021_01_13 Update: v3.64 Code Optimization (in Progress)
# 2021_01_27 Update: v3.65 By default Temp files declaration done in caller
# 2021_02_27 Update: v3.66 Abort if user not part of '$SADM_GROUP' & fix permission denied message.
#@2021_03_24 Update: v3.67 Non root user MUST be part of 'sadmin' group to use SADMIN library.
#@2021_04_02 Fix: v3.68 Replace test using '-v' with '! -z' on variable.
#@2021_04_09 Fix: v3.69 Fix problem with disabling log header, log footer and rch file.
#===================================================================================================
trap 'exit 0' 2                                                         # Intercept The ^C
#set -x
 

 
# --------------------------------------------------------------------------------------------------
#                             V A R I A B L E S      D E F I N I T I O N S
# --------------------------------------------------------------------------------------------------
#
export SADM_HOSTNAME=`hostname -s`                                      # Current Host name
export SADM_LIB_VER="3.69"                                              # This Library Version
export SADM_DASH=`printf %80s |tr " " "="`                              # 80 equals sign line
export SADM_FIFTY_DASH=`printf %50s |tr " " "="`                        # 50 equals sign line
export SADM_80_DASH=`printf %80s |tr " " "="`                           # 80 equals sign line
export SADM_80_SPACES=`printf %80s  " "`                                # 80 spaces 
export SADM_TEN_DASH=`printf %10s |tr " " "-"`                          # 10 dashes line
export SADM_STIME=""                                                    # Store Script Start Time
export SADM_DEBUG=0                                                     # 0=NoDebug Higher=+Verbose
export DELETE_PID="Y"                                                   # Default Delete PID On Exit
export LIB_DEBUG=0                                                      # This Library Debug Level

# SADMIN DIRECTORIES STRUCTURES DEFINITIONS
export SADM_BASE_DIR=${SADMIN:="/sadmin"}                               # Script Root Base Dir.
export SADM_BIN_DIR="$SADM_BASE_DIR/bin"                                # Script Root binary Dir.
export SADM_TMP_DIR="$SADM_BASE_DIR/tmp"                                # Script Temp  directory
export SADM_LIB_DIR="$SADM_BASE_DIR/lib"                                # Script Lib directory
export SADM_LOG_DIR="$SADM_BASE_DIR/log"                                # Script log directory
export SADM_CFG_DIR="$SADM_BASE_DIR/cfg"                                # Configuration Directory
export SADM_SYS_DIR="$SADM_BASE_DIR/sys"                                # System related scripts
export SADM_DAT_DIR="$SADM_BASE_DIR/dat"                                # Data directory
export SADM_DOC_DIR="$SADM_BASE_DIR/doc"                                # Documentation directory
export SADM_PKG_DIR="$SADM_BASE_DIR/pkg"                                # Package rpm,deb  directory
export SADM_SETUP_DIR="$SADM_BASE_DIR/setup"                            # Package rpm,deb  directory
export SADM_NMON_DIR="$SADM_DAT_DIR/nmon"                               # Where nmon file reside
export SADM_DR_DIR="$SADM_DAT_DIR/dr"                                   # Disaster Recovery  files
export SADM_RCH_DIR="$SADM_DAT_DIR/rch"                                 # Result Code History Dir
export SADM_NET_DIR="$SADM_DAT_DIR/net"                                 # Network SubNet Info Dir
export SADM_RPT_DIR="$SADM_DAT_DIR/rpt"                                 # SADM Sysmon Report Dir
export SADM_DBB_DIR="$SADM_DAT_DIR/dbb"                                 # Database Backup Directory
export SADM_WWW_DIR="$SADM_BASE_DIR/www"                                # Web Dir

# SADMIN USER DIRECTORIES
export SADM_USR_DIR="$SADM_BASE_DIR/usr"                                # Script User directory
export SADM_UBIN_DIR="$SADM_USR_DIR/bin"                                # Script User Bin Dir.
export SADM_UCFG_DIR="$SADM_USR_DIR/cfg"                                # Script User Cfg Dir.
export SADM_ULIB_DIR="$SADM_USR_DIR/lib"                                # Script User Lib Dir.
export SADM_UDOC_DIR="$SADM_USR_DIR/doc"                                # Script User Doc. Dir.
export SADM_UMON_DIR="$SADM_USR_DIR/mon"                                # Script User SysMon Scripts

# SADMIN SERVER WEB SITE DIRECTORIES DEFINITION
export SADM_WWW_DOC_DIR="$SADM_WWW_DIR/doc"                             # www Doc Dir
export SADM_WWW_DAT_DIR="$SADM_WWW_DIR/dat"                             # www Dat Dir
export SADM_WWW_ARC_DIR="$SADM_WWW_DIR/dat/archive"                     # www Dat Dir
export SADM_WWW_RRD_DIR="$SADM_WWW_DIR/rrd"                             # www RRD Dir
export SADM_WWW_CFG_DIR="$SADM_WWW_DIR/cfg"                             # www CFG Dir
export SADM_WWW_LIB_DIR="$SADM_WWW_DIR/lib"                             # www Lib Dir
export SADM_WWW_IMG_DIR="$SADM_WWW_DIR/images"                          # www Img Dir
export SADM_WWW_NET_DIR="$SADM_WWW_DAT_DIR/${SADM_HOSTNAME}/net"        # web net dir
export SADM_WWW_TMP_DIR="$SADM_WWW_DIR/tmp"                             # web tmp dir
export SADM_WWW_PERF_DIR="$SADM_WWW_TMP_DIR/perf"                       # web perf dir

# SADM CONFIG FILES, LOGS AND TEMP FILES USER CAN USE
export SADM_PID_FILE="${SADM_TMP_DIR}/${SADM_INST}.pid"                 # PID file name
export SADM_CFG_FILE="$SADM_CFG_DIR/sadmin.cfg"                         # Cfg file name
export SADM_ALERT_FILE="$SADM_CFG_DIR/alert_group.cfg"                  # AlertGrp File
export SADM_ALERT_INIT="$SADM_CFG_DIR/.alert_group.cfg"                 # Initial Alert
export SADM_SLACK_FILE="$SADM_CFG_DIR/alert_slack.cfg"                  # Slack WebHook
export SADM_SLACK_INIT="$SADM_CFG_DIR/.alert_slack.cfg"                 # Slack Init WH
export SADM_ALERT_HIST="$SADM_CFG_DIR/alert_history.txt"                # Alert History
export SADM_ALERT_HINI="$SADM_CFG_DIR/.alert_history.txt"               # History Init
export SADM_ALERT_ARC="$SADM_CFG_DIR/alert_archive.txt"                 # Alert Archive
export SADM_ALERT_ARCINI="$SADM_CFG_DIR/.alert_archive.txt"             # Init Archive
export SADM_REL_FILE="$SADM_CFG_DIR/.release"                           # Release Ver.
export SADM_SYS_STARTUP="$SADM_SYS_DIR/sadm_startup.sh"                 # Startup File
export SADM_SYS_START="$SADM_SYS_DIR/.sadm_startup.sh"                  # Startup Template
export SADM_SYS_SHUTDOWN="$SADM_SYS_DIR/sadm_shutdown.sh"               # Shutdown 
export SADM_SYS_SHUT="$SADM_SYS_DIR/.sadm_shutdown.sh"                  # Shutdown Template
export SADM_CRON_FILE="$SADM_CFG_DIR/.sadm_osupdate"                    # Work crontab
export SADM_CRONTAB="/etc/cron.d/sadm_osupdate"                         # Final crontab
export SADM_BACKUP_NEWCRON="$SADM_CFG_DIR/.sadm_backup"                 # Tmp Cron
export SADM_BACKUP_CRONTAB="/etc/cron.d/sadm_backup"                    # Act Cron
export SADM_REAR_NEWCRON="$SADM_CFG_DIR/.sadm_rear_backup"              # Tmp Cron
export SADM_REAR_CRONTAB="/etc/cron.d/sadm_rear_backup"                 # Real Cron
export SADM_BACKUP_LIST="$SADM_CFG_DIR/backup_list.txt"                 # List of file to Backup
export SADM_BACKUP_LIST_INIT="$SADM_CFG_DIR/.backup_list.txt"           # Default files to Backup
export SADM_BACKUP_EXCLUDE="$SADM_CFG_DIR/backup_exclude.txt"           # files Exclude from Backup
export SADM_REAR_EXCLUDE_INIT="$SADM_CFG_DIR/.rear_exclude.txt"         # Default Rear Files Excl.
export SADM_BACKUP_EXCLUDE_INIT="$SADM_CFG_DIR/.backup_exclude.txt"     # Default Files to Exclude
export SADM_CFG_HIDDEN="$SADM_CFG_DIR/.sadmin.cfg"                      # Default SADMIN Cfg File

# Define 3 temporaries file name, that can be use by the user.
# They are deleted automatically by the sadm_stop() function (If they exist).
if [ ! -z $SADM_TMP_FILE1 ] || [ -z "$SADM_TMP_FILE1" ]                 # Var blank or don't exist
   then export SADM_TMP_FILE1="${SADM_TMP_DIR}/${SADM_INST}_1.$$"       # Temp File 1 for you to use
fi 
if [ ! -z $SADM_TMP_FILE2 ] || [ -z "$SADM_TMP_FILE2" ]                 # Var blank or don't exist
   then export SADM_TMP_FILE2="${SADM_TMP_DIR}/${SADM_INST}_2.$$"       # Temp File 1 for you to use
fi 
if [ ! -z $SADM_TMP_FILE3 ] || [ -z "$SADM_TMP_FILE3" ]                 # Var blank or don't exist
   then export SADM_TMP_FILE3="${SADM_TMP_DIR}/${SADM_INST}_3.$$"       # Temp File 1 for you to use
fi 

# Definition of SADMIN log, error log, Result Code  History (.rch) and Monitor report file (*.rpt).
export SADM_LOG="${SADM_LOG_DIR}/${SADM_HOSTNAME}_${SADM_INST}.log"     # Script Output LOG
export SADM_ERRLOG="${SADM_LOG_DIR}/${SADM_HOSTNAME}_${SADM_INST}_err.log" # Script Error Output LOG
export SADM_RCHLOG="${SADM_RCH_DIR}/${SADM_HOSTNAME}_${SADM_INST}.rch"  # Result Code History File
export SADM_RPT_FILE="${SADM_RPT_DIR}/${SADM_HOSTNAME}.rpt"             # Monitor Report file (rpt)

# COMMAND PATH REQUIRE THAT SADMIN USE
export SADM_LSB_RELEASE=""                                              # Command lsb_release Path
export SADM_DMIDECODE=""                                                # Command dmidecode Path
export SADM_BC=""                                                       # Command bc (Do Some Math)
export SADM_FDISK=""                                                    # fdisk (Read Disk Capacity)
export SADM_WHICH=""                                                    # which Path - Required
export SADM_PERL=""                                                     # perl Path (for epoch time)
export SADM_MAIL=""                                                     # mail Pgm Path
export SADM_MUTT=""                                                     # mutt Pgm Path
export SADM_CURL=""                                                     # curl Pgm Path
export SADM_LSCPU=""                                                    # Path to lscpu Command
export SADM_NMON=""                                                     # Path to nmon Command
export SADM_PARTED=""                                                   # Path to parted Command
export SADM_ETHTOOL=""                                                  # Path to ethtool Command
export SADM_SSH=""                                                      # Path to ssh Exec.
export SADM_MYSQL=""                                                    # Default mysql FQDN

# SADMIN CONFIG FILE VARIABLES (Default Values here will be overridden by SADM CONFIG FILE Content)
export SADM_MAIL_ADDR="your_email@domain.com"                           # Default is in sadmin.cfg
export SADM_ALERT_TYPE=1                                                # 0=No 1=Err 2=Success 3=All
export SADM_ALERT_GROUP="default"                                       # Define in alert_group.cfg
export SADM_ALERT_REPEAT=43200                                          # Repeat Alarm wait time Sec
export SADM_TEXTBELT_KEY="textbelt"                                     # Textbelt.com API Key
export SADM_TEXTBELT_URL="https://textbelt.com/text"                    # Textbelt.com API URL
export SADM_CIE_NAME="Your Company Name"                                # Company Name
export SADM_HOST_TYPE=""                                                # [S]erver/[C]lient/[D]ev.
export SADM_USER="sadmin"                                               # sadmin user account
export SADM_GROUP="sadmin"                                              # sadmin group account
export SADM_WWW_USER="apache"                                           # /sadmin/www owner
export SADM_WWW_GROUP="apache"                                          # /sadmin/www group
export SADM_MAX_LOGLINE=5000                                            # Max Nb. Lines in LOG
export SADM_MAX_RCLINE=100                                              # Max Nb. Lines in RCH file
export SADM_NMON_KEEPDAYS=60                                            # Days to keep old *.nmon
export SADM_RCH_KEEPDAYS=60                                             # Days to keep old *.rch
export SADM_LOG_KEEPDAYS=60                                             # Days to keep old *.log
export SADM_DBNAME="sadmin"                                             # MySQL DataBase Name
export SADM_DBHOST="sadmin.maison.ca"                                   # MySQL DataBase Host
export SADM_DBPORT=3306                                                 # MySQL Listening Port
export SADM_RW_DBUSER=""                                                # MySQL Read/Write User
export SADM_RW_DBPWD=""                                                 # MySQL Read/Write Passwd
export SADM_RO_DBUSER=""                                                # MySQL Read Only User
export SADM_RO_DBPWD=""                                                 # MySQL Read Only Passwd
export SADM_SERVER=""                                                   # Server FQDN Name
export SADM_DOMAIN=""                                                   # Default Domain Name
export SADM_NETWORK1=""                                                 # Network 1 to Scan
export SADM_NETWORK2=""                                                 # Network 2 to Scan
export SADM_NETWORK3=""                                                 # Network 3 to Scan
export SADM_NETWORK4=""                                                 # Network 4 to Scan
export SADM_NETWORK5=""                                                 # Network 5 to Scan
export DBPASSFILE="${SADM_CFG_DIR}/.dbpass"                             # MySQL Passwd File
export SADM_RELEASE=`cat $SADM_REL_FILE`                                # SADM Release Ver. Number
export SADM_SSH_PORT=""                                                 # Default SSH Port
export SADM_RRDTOOL=""                                                  # RRDTool Location
export SADM_REAR_NFS_SERVER=""                                          # ReaR NFS Server
export SADM_REAR_NFS_MOUNT_POINT=""                                     # ReaR Mount Point
export SADM_REAR_BACKUP_TO_KEEP=3                                       # Rear Nb.Copy
export SADM_STORIX_NFS_SERVER=""                                        # Storix NFS Server
export SADM_STORIX_NFS_MOUNT_POINT=""                                   # Storix Mnt Point
export SADM_STORIX_BACKUP_TO_KEEP=3                                     # Storix Nb. Copy
export SADM_BACKUP_NFS_SERVER=""                                        # Backup NFS Server
export SADM_BACKUP_NFS_MOUNT_POINT=""                                   # Backup Mnt Point
export SADM_DAILY_BACKUP_TO_KEEP=3                                      # Daily to Keep
export SADM_WEEKLY_BACKUP_TO_KEEP=3                                     # Weekly to Keep
export SADM_MONTHLY_BACKUP_TO_KEEP=2                                    # Monthly to Keep
export SADM_YEARLY_BACKUP_TO_KEEP=1                                     # Yearly to Keep
export SADM_WEEKLY_BACKUP_DAY=5                                         # 1=Mon, ... ,7=Sun
export SADM_MONTHLY_BACKUP_DATE=1                                       # Monthly Back Date
export SADM_YEARLY_BACKUP_MONTH=12                                      # Yearly Backup Mth
export SADM_YEARLY_BACKUP_DATE=31                                       # Yearly Backup Day
export SADM_MKSYSB_NFS_SERVER=""                                        # Mksysb NFS Server
export SADM_MKSYSB_NFS_MOUNT_POINT=""                                   # Mksysb Mnt Point
export SADM_MKSYSB_NFS_TO_KEEP=2                                        # Mksysb Bb. Copy

# Local to Library Variable - Can't be use elsewhere outside this script
export LOCAL_TMP="$SADM_TMP_DIR/sadmlib_tmp.$$"                         # Local Temp File

# Misc. Screen Attribute
if [ -z "$TERM" ] || [ "$TERM" = "dumb" ] || [ "$TERM" = "unknown" ]
    then export CLREOL=""                                               # Clear to End of Line
         export CLREOS=""                                               # Clear to End of Screen
         export BOLD=""                                                 # Set Bold Attribute
         export BELL=""                                                 # Ring the Bell
         export REVERSE=""                                              # Reverse Video On
         export UNDERLINE=""                                            # Set UnderLine On
         export HOME_CURSOR=""                                          # Home Cursor
         export UP=""                                                   # Cursor up
         export DOWN=""                                                 # Cursor down
         export RIGHT=""                                                # Cursor right
         export LEFT=""                                                 # Cursor left
         export CLRSCR=""                                               # Clear Screen
         export BLINK=""                                                # Blinking on
         export NORMAL=""                                               # Reset Screen Attribute
         export BLACK=""                                                # Foreground Color Black
         export MAGENTA=""                                              # Foreground Color Magenta
         export RED=""                                                  # Foreground Color Red
         export GREEN=""                                                # Foreground Color Green
         export YELLOW=""                                               # Foreground Color Yellow
         export BLUE=""                                                 # Foreground Color Blue
         export CYAN=""                                                 # Foreground Color Cyan
         export WHITE=""                                                # Foreground Color White
         export BBLACK=""                                               # Background Color Black
         export BRED=""                                                 # Background Color Red
         export BGREEN=""                                               # Background Color Green
         export BYELLOW=""                                              # Background Color Yellow
         export BBLUE=""                                                # Background Color Blue
         export BMAGENTA=""                                             # Background Color Magenta
         export BCYAN=""                                                # Background Color Cyan
         export BWHITE=""                                               # Background Color White
    else export CLREOL=$(tput el)          2>/dev/null                  # Clear to End of Line
         export CLREOS=$(tput ed)          2>/dev/null                  # Clear to End of Screen
         export BOLD=$(tput bold)          2>/dev/null                  # Set Bold Attribute On
         export BELL=$(tput bel)           2>/dev/null                  # Ring the Bell
         export REVERSE=$(tput rev)        2>/dev/null                  # Reverse Video 
         export UNDERLINE=$(tput sgr 0 1)  2>/dev/null                  # UnderLine
         export HOME_CURSOR=$(tput home)   2>/dev/null                  # Home Cursor
         export UP=$(tput cuu1)            2>/dev/null                  # Cursor up
         export DOWN=$(tput cud1)          2>/dev/null                  # Cursor down
         export RIGHT=$(tput cub1)         2>/dev/null                  # Cursor right
         export LEFT=$(tput cuf1)          2>/dev/null                  # Cursor left
         export CLRSCR=$(tput clear)       2>/dev/null                  # Clear Screen
         export BLINK=$(tput blink)        2>/dev/null                  # Blinking on
         export NORMAL=$(tput sgr0)        2>/dev/null                  # Reset Screen
         export BLACK=$(tput setaf 0)      2>/dev/null                  # Foreground Color Black
         export RED=$(tput setaf 1)        2>/dev/null                  # Foreground Color Red
         export GREEN=$(tput setaf 2)      2>/dev/null                  # Foreground Color Green
         export YELLOW=$(tput setaf 3)     2>/dev/null                  # Foreground Color Yellow
         export BLUE=$(tput setaf 4)       2>/dev/null                  # Foreground Color Blue
         export MAGENTA=$(tput setaf 5)    2>/dev/null                  # Foreground Color Magenta
         export CYAN=$(tput setaf 6)       2>/dev/null                  # Foreground Color Cyan
         export WHITE=$(tput setaf 7)      2>/dev/null                  # Foreground Color White
         export BBLACK=$(tput setab 0)     2>/dev/null                  # Background Color Black
         export BRED=$(tput setab 1)       2>/dev/null                  # Background Color Red
         export BGREEN=$(tput setab 2)     2>/dev/null                  # Background Color Green
         export BYELLOW=$(tput setab 3)    2>/dev/null                  # Background Color Yellow
         export BBLUE=$(tput setab 4)      2>/dev/null                  # Background Color Blue
         export BMAGENTA=$(tput setab 5)   2>/dev/null                  # Background Color Magenta
         export BCYAN=$(tput setab 6)      2>/dev/null                  # Background Color Cyan
         export BWHITE=$(tput setab 7)     2>/dev/null                  # Background Color White
fi 


# Constant Var., if message begin with these constant it's showed with special color by sadm_write()
SADM_ERROR="[ ERROR ]"                                                  # [ ERROR ] in Red Trigger 
SADM_FAILED="[ FAILED ]"                                                # [ FAILED ] in Red Trigger 
SADM_WARNING="[ WARNING ]"                                              # [ WARNING ] in Yellow
SADM_OK="[ OK ]"                                                        # [ OK ] in Green Trigger
SADM_SUCCESS="[ SUCCESS ]"                                              # [ SUCCESS ] in Green
SADM_INFO="[ INFO ]"                                                    # [ INFO] in Blue Trigger

# When mess. begin with constant above they are substituted by the value below in sadm_write().
SADM_SERROR="[ ${RED}ERROR${NORMAL} ]"                                  # [ ERROR ] Red
SADM_SFAILED="[ ${RED}FAILED${NORMAL} ]"                                # [ FAILED ] Red
SADM_SWARNING="[ ${BOLD}${YELLOW}WARNING${NORMAL} ]"                    # WARNING Yellow
SADM_SOK="[ ${BOLD}${GREEN}OK${NORMAL} ]"                               # [ OK ] Green
SADM_SSUCCESS="[ ${BOLD}${GREEN}SUCCESS${NORMAL} ]"                     # SUCCESS Green
SADM_SINFO="[ ${BOLD}${BLUE}INFO${NORMAL} ]"                            # INFO Blue




# Function return the string received to uppercase
sadm_toupper() {
    echo $1 | tr  "[:lower:]" "[:upper:]"
}



# Function return the string received to uppercase
sadm_tolower() {
    echo $1 | tr "[:upper:]" "[:lower:]" 
}



# Function return the string received to with the first character in uppercase
sadm_capitalize() {
    C=`echo $1 | tr "[:upper:]" "[:lower:]"`
    echo "${C^}"
}



# Check if variable is an integer - Return 1, if not an integer - Return 0 if it is an integer
sadm_isnumeric() {
    wnum=$1
    if [ "$wnum" -eq "$wnum" ] 2>/dev/null ; then return 0 ; else return 1 ; fi
}



# Display Question (Receive as $1) and wait for response from user, Y/y (return 1) or N/n (return 0)
sadm_ask() {
    wmess="$1 [y,n] ? "                                                 # Add Y/N to Mess. Rcv
    while :                                                             # While until good answer
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




# Write String received to Log (L), Screen (S) or Both (B) depending on $SADM_LOG_TYPE variable.
# Use sadm_write (No LF at EOL) instead of sadm_writelog (With LF at EOL).
sadm_write() {
    SADM_SMSG="$@"                                                      # Screen Msg = Msg Received
    SADM_LMSG="$SADM_SMSG"                                              # Log Mess. = Screen Mess

    # Replace special status andput them in color.
    SADM_SMSG=`echo "${SADM_SMSG//'[ OK ]'/$SADM_SOK}"`                 # Put OK in Green 
    SADM_SMSG=`echo "${SADM_SMSG//'[ ERROR ]'/$SADM_SERROR}"`           # Put ERROR in Red
    SADM_SMSG=`echo "${SADM_SMSG//'[ WARNING ]'/$SADM_SWARNING}"`       # Put WARNING in Yellow
    SADM_SMSG=`echo "${SADM_SMSG//'[ FAILED '/$SADM_SFAILED}"`          # Put FAILED in Red
    SADM_SMSG=`echo "${SADM_SMSG//'[ SUCCESS ]'/$SADM_SSUCCESS}"`       # Put Success in Green
    SADM_SMSG=`echo "${SADM_SMSG//'[ INFO ]'/$SADM_SINFO}"`             # Put INFO in Blue
    if [ "${SADM_SMSG:0:1}" != "[" ]                                    # 1st Char. of Mess. Not [
        then SADM_LMSG="$(date "+%C%y.%m.%d %H:%M:%S") $SADM_LMSG"      # Insert Date/Time in Log
    fi 
    
    # Write Message received to either [S]creen, [L]og or [B]oth.
    case "$SADM_LOG_TYPE" in                                            # Depending of LOG_TYPE
        s|S) echo -ne "$SADM_SMSG"                                      # Write Msg to [S]creen
             ;;
        l|L) echo -ne "$SADM_LMSG" >> $SADM_LOG                         # Write Msg to [L]og File
             ;;
        b|B) echo -ne "$SADM_SMSG"                                      # Write Msg to [S]creen
             echo -ne "$SADM_LMSG" >> $SADM_LOG                         # Write Msg to [L]og File
             ;;
        *)   printf "\nWrong \$SADM_LOG_TYPE value ($SADM_LOG_TYPE)\n"  # Advise User if Incorrect
             printf -- "%-s\n" "$SADM_LMSG" >> $SADM_LOG                # Write Msg to Log File
             ;;
    esac
}




# Write String received to Log (L), Screen (S) or Both (B) depending on $SADM_LOG_TYPE variable.
# Just write the message received as is, with a new line at the end.
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



# Show Script Name, version, Library Version, O/S Name/Version and Kernel version.
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
                    if [ "$wver"  = "10.16" ] ; then woscodename="Big Sur"          ;fi
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
                    if [ "$wosname" = "CENTOSSTREAM" ]           ; then wosname="CENTOS" ; fi
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
        "LINUX")    #warch=`uname -m`
                    warch=$(arch)
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
                    else sadm_server_cpu_speed=`grep -i "cpu MHz" /proc/cpuinfo |tail -1 |awk -F: '{print $2}'`
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
       "LINUX")     wcps=`egrep "core id|physical id" /proc/cpuinfo |tr -d "\n" |sed s/physical/\\nphysical/g |grep -v ^$ |sort |uniq |wc -l`
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
        "LINUX")    sadm_wht=`grep -E "cpu cores|siblings|physical id" /proc/cpuinfo |xargs -n 11 echo |sort |uniq |head -1`
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
                    dsize=`echo $xline | awk '{ print $3 }' | awk '{print substr($0,1,length-2)}'`

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
                     echo "SADMIN configuration file $SADM_CFG_FILE doesn't exist."
                     echo "Even the config template file can't be found - $SADM_CFG_HIDDEN"
                     echo "Copy both files from another system to this server"
                     echo "Or restore the files from a backup"
                     echo "Don't forget to review the file content."
                     echo "Job aborted."
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
#$ mkdir {bananas,apples,oranges,peaches, kiwis}
sadm_start() {

    # 1st thing inititialize log directory and file.
    [ ! -d "$SADM_LOG_DIR" ] && mkdir -p $SADM_LOG_DIR                  # If Log Dir. don't Exist
    if [ $(id -u) -eq 0 ]                                               # Sure got good permission
        then chmod 0775 $SADM_LOG_DIR ; chown ${SADM_USER}:${SADM_GROUP} $SADM_LOG_DIR
    fi
    [ ! -e "$SADM_LOG" ] && touch $SADM_LOG                             # If Log File don't exist
    if [ $(id -u) -eq 0 ]                                               # Sure got good permission
        then chmod 666 $SADM_LOG ; chown ${SADM_USER}:${SADM_GROUP} ${SADM_LOG}
    fi
    [ "$SADM_LOG_APPEND" != "Y" ] && echo " " > $SADM_LOG               # No Append log, create new

    # Write Starting Info in the Log
    if [ ! -z "$SADM_LOG_HEADER" ] && [ "$SADM_LOG_HEADER" = "Y" ]      # Script Want Log Header
        then sadm_writelog "${SADM_80_DASH}"                            # Write 80 Dashes Line
             sadm_writelog "`date` - ${SADM_PN} V${SADM_VER} - SADM Lib. V${SADM_LIB_VER}"
             sadm_writelog "Server Name: $(sadm_get_fqdn) - Type: $(sadm_get_ostype)"
             sadm_writelog "$(sadm_get_osname) $(sadm_get_osversion) Kernel $(sadm_get_kernel_version)"
             sadm_writelog "${SADM_FIFTY_DASH}"                         # Write 50 Dashes Line
             sadm_writelog " "                                          # White space line
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

    # $SADMIN/www/dat/archive Dir.
    [ ! -d "$SADM_WWW_ARC_DIR" ] && mkdir -p $SADM_WWW_ARC_DIR
    if [ $(id -u) -eq 0 ]
       then chmod 0775 $SADM_WWW_ARC_DIR
            if [ "$(sadm_get_fqdn)" = "$SADM_SERVER" ]
                then chown ${SADM_WWW_USER}:${SADM_WWW_GROUP} $SADM_WWW_ARC_DIR
                else chown ${SADM_USER}:${SADM_GROUP} $SADM_WWW_ARC_DIR
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
                            exit 1
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
    if [ ! -z "$SADM_USE_RCH" ] && [ "$SADM_USE_RCH" = "Y" ]            # Want to Produce RCH File
        then [ ! -e "$SADM_RCHLOG" ] && touch $SADM_RCHLOG              # Create RCH If not exist
             [ $(id -u) -eq 0 ] && chmod 664 $SADM_RCHLOG               # Change protection on RCH
             [ $(id -u) -eq 0 ] && chown ${SADM_USER}:${SADM_GROUP} ${SADM_RCHLOG}
             WDOT=".......... ........ ........"                        # End Time & Elapse = Dot
             RCHLINE="${SADM_HOSTNAME} $SADM_STIME $WDOT $SADM_INST"    # Format Part1 of RCH File
             RCHLINE="$RCHLINE $SADM_ALERT_GROUP $SADM_ALERT_TYPE 2"    # Format Part2 of RCH File
             echo "$RCHLINE" >>$SADM_RCHLOG                             # Append Line to  RCH File
    fi

    # If PID File exist and User want to run only 1 copy of the script - Abort Script
    if [ -e "${SADM_PID_FILE}" ] && [ "$SADM_MULTIPLE_EXEC" = "N" ]     # PIP Exist - Run One Copy
       then pepoch=$(stat --format="%Y" $SADM_PID_FILE)                 # Last Modify Date of PID
            cepoch=$(sadm_get_epoch_time)                               # Current Epoch Time
            pelapse=$(( $cepoch - $pepoch ))                            # Nb Sec PID File was create
            sadm_write "${BOLD}PID File ${SADM_PID_FILE} exist, created $pelapse seconds ago.${NORMAL}\n"
            sadm_write "$SADM_PN may be already running ... \n"         # Script already running
            sadm_write "Not allowed to run a second copy of this script (\$SADM_MULTIPLE_EXEC='N').\n" 
            sadm_writelog " "
            sadm_write "Script can't execute unless one of the following thing is done :\n"
            sadm_write "  - Remove the PID File (${SADM_PID_FILE}).\n"
            sadm_write "  - Set 'SADM_MULTIPLE_EXEC' variable to 'Y' in the script.\n"
            if [ ! -z "$SADM_PID_TIMEOUT" ] 
                then sadm_write "  - You wait till PID timeout ('\$SADM_PID_TIMEOUT') is reach.\n"
                     sadm_write "    The PID file was created $pelapse seconds ago.\n"
                     sadm_write "    The '\$SADM_PID_TIMEOUT' variable is set to $SADM_PID_TIMEOUT seconds.\n"
                     if [ $pelapse -ge $SADM_PID_TIMEOUT ]              # PID Timeout reached
                        then sadm_write "\n${BOLD}${GREEN}PID File exceeded it time to live.\n"
                             sadm_write "Assuming script was aborted anormally, "
                             sadm_write "Script execution re-enable, PID file updated.${NORMAL}\n\n"
                             touch ${SADM_PID_FILE} >/dev/null 2>&1     # Update Modify date of PID
                             DELETE_PID="Y"                             # Del PID Since running
                        else DELETE_PID="N"                             # No Del PID Since running
                             sadm_stop 1                                # Call SADM Stop Function
                             exit 1                                     # Exit with Error
                     fi
                else DELETE_PID="N"                                     # No Del PID Since running
                     sadm_stop 1                                        # Call SADM Stop Function
                     exit 1                                             # Exit with Error
            fi 
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
    export sadm_end_time=`date "+%C%y.%m.%d %H:%M:%S"`                  # Get & Format End Time
    sadm_elapse=$(sadm_elapse "$sadm_end_time" "$SADM_STIME")           # Go Calculate Elapse Time

    # Write script exit code and execution time to log (If user ask for a log footer) 
    if [ ! -z "$SADM_LOG_FOOTER" ] && [ "$SADM_LOG_FOOTER" = "Y" ]      # Want to Produce Log Footer
        then sadm_write "\n"                                            # Blank LIne
             sadm_write "${SADM_FIFTY_DASH}\n"                          # Dash Line
             if [ $SADM_EXIT_CODE -eq 0 ]                               # If script succeeded
                then foot1="Script exit code is ${SADM_EXIT_CODE} (Success)" # Success 
                else foot1="Script exit code is ${SADM_EXIT_CODE} (Failed)"  # Failed 
             fi 
             sadm_write "$foot1 and execution time is ${sadm_elapse}\n" # Write the Elapse Time
    fi

    # Update RCH File and Trim It to $SADM_MAX_RCLINE lines define in sadmin.cfg
    if [ ! -z "$SADM_USE_RCH" ] && [ "$SADM_USE_RCH" = "Y" ]              # Want to Produce RCH File ?
        then XCODE=`tail -1 ${SADM_RCHLOG}| awk '{ print $NF }'`        # Get RCH Code on last line
             if [ "$XCODE" -eq 2 ]                                      # If last Line code is 2
                then XLINE=`wc -l ${SADM_RCHLOG} | awk '{print $1}'`    # Count Nb. Line in RCH File
                     XCOUNT=`expr $XLINE - 1`                           # Count without last line
                     head -$XCOUNT ${SADM_RCHLOG} > ${SADM_TMP_DIR}/xrch.$$ # Create rch file trim
                     rm -f ${SADM_RCHLOG} >/dev/null 2>&1               # Remove old rch file
                     mv ${SADM_TMP_DIR}/xrch.$$ ${SADM_RCHLOG}          # Replace RCH without code 2
             fi                     
             RCHLINE="${SADM_HOSTNAME} $SADM_STIME $sadm_end_time"      # Format Part1 of RCH File
             RCHLINE="$RCHLINE $sadm_elapse $SADM_INST"                 # Format Part2 of RCH File
             RCHLINE="$RCHLINE $SADM_ALERT_GROUP $SADM_ALERT_TYPE"      # Format Part3 of RCH File
             RCHLINE="$RCHLINE $SADM_EXIT_CODE"                         # Format Part4 of RCH File
             if [ -w $SADM_RCHLOG ] 
                then echo "$RCHLINE" >>$SADM_RCHLOG                     # Append to RCH File
                else sadm_writelog "Permission denied to write to $SADM_RCHLOG"
             fi
             if [ ! -z "$SADM_LOG_FOOTER" ] && [ "$SADM_LOG_FOOTER" = "Y" ] # If User want Log Footer
                then if [ "$SADM_MAX_RCLINE" -ne 0 ]                    # User want to trim rch file
                        then if [ -w $SADM_RCHLOG ]                     # If History RCH Writable
                                then mtmp1="History ($SADM_RCHLOG) trim to ${SADM_MAX_RCLINE} lines "
                                     mtmp2="(\$SADM_MAX_RCLINE=$SADM_MAX_RCLINE)"
                                     sadm_write "${mtmp1}${mtmp2}.\n"           # Write rch trim context 
                                     sadm_trimfile "$SADM_RCHLOG" "$SADM_MAX_RCLINE" 
                             fi
                        else mtmp="Script is set not to trim history file (\$SADM_MAX_RCLINE=0)"
                             sadm_write "${mtmp}.\n" 
                     fi
             fi
             [ $(id -u) -eq 0 ] && chmod 664 ${SADM_RCHLOG}             # R/W Owner/Group R by World
             [ $(id -u) -eq 0 ] && chown ${SADM_USER}:${SADM_GROUP} ${SADM_RCHLOG} # Change RCH Owner
    fi 

    # If log size not at zero and user want to use the log.
    if [ ! -z "$SADM_LOG_FOOTER" ] && [ "$SADM_LOG_FOOTER" = "Y" ]      # User Want the Log Footer
        then GRP_TYPE=$(grep -i "^$SADM_ALERT_GROUP " $SADM_ALERT_FILE |awk '{print$2}' |tr -d ' ')
             GRP_NAME=$(grep -i "^$SADM_ALERT_GROUP " $SADM_ALERT_FILE |awk '{print$3}' |tr -d ' ')
             ORG_NAME=$GRP_NAME                                         # Save Original Group Name
             if [ "$SADM_ALERT_GROUP" = "default" ]                     # Get Real Default GroupName
                then GRP_NAME=$(grep -i "^$GRP_NAME " $SADM_ALERT_FILE |awk '{print$3}' |tr -d ' ')
             fi
             case "$GRP_TYPE" in                                        # Case on Default Alert Group
                m|M )   GRP_DESC="by email to '$GRP_NAME'"              # Alert Sent by Email
                        ;; 
                s|S )   GRP_DESC="(Slack '$GRP_NAME' channel)"          # Alert Send using Slack App
                        ;; 
                c|C )   GRP_DESC="to Cell. '$GRP_NAME'"                 # Alert send to Cell. Number
                        ;; 
                t|T )   GRP_DESC="by SMS to '$GRP_NAME'"                # Alert send to SMS Group
                        ;; 
                *   )   GRP_DESC="Grp. $GRP_TYPE ?"                     # Illegal Code Desc
                        ;;
             esac
             case $SADM_ALERT_TYPE in
                0)  sadm_write "Script instructed to not send any alert (\$SADM_ALERT_TYPE=0).\n"
                    ;;
                1)  sadm_write "Script will send an alert only when it terminate with error (\$SADM_ALERT_TYPE=1).\n"
                    if [ "$SADM_EXIT_CODE" -ne 0 ]
                        then sadm_write "Script failed, alert will be send to '$SADM_ALERT_GROUP' alert group ${GRP_DESC}.\n"
                        else sadm_write "Script succeeded, no alert will be send to '$SADM_ALERT_GROUP' alert group.\n"
                    fi
                    ;;
                2)  sadm_write "Script will send an alert only when it terminate with success (\$SADM_ALERT_TYPE=2).\n"
                    if [ "$SADM_EXIT_CODE" -eq 0 ]
                        then sadm_write "Script succeeded, alert will be send to '$SADM_ALERT_GROUP' alert group ${GRP_DESC}.\n"
                        else sadm_write "Script failed, no alert will be send to '$SADM_ALERT_GROUP' alert group.\n"
                    fi
                    ;;
                3)  sadm_write "Script will send an alert at the end of every execution (\$SADM_ALERT_TYPE=3).\n"
                    sadm_write "Alert will be send to '$SADM_ALERT_GROUP' alert group ${GRP_DESC}.\n"
                    ;;
                *)  sadm_write "'\$SADM_ALERT_TYPE' code isn't set properly, should be between 0 and 3.\n"
                    sadm_write "It's set to '$SADM_ALERT_TYPE', changing it to 3.\n"
                    SADM_ALERT_TYPE=3
                    ;;
             esac
             if [ "$SADM_LOG_APPEND" = "N" ]                            # If New log Every Execution
                then sadm_write "New log ($SADM_LOG) created (\$SADM_LOG_APPEND='N').\n"
                else if [ $SADM_MAX_LOGLINE -eq 0 ]                     # MaxTrimLog=0 then no Trim
                        then sadm_write "Log $SADM_LOG is not trimmed (\$SADM_MAX_LOGLINE=0).\n"
                        else sadm_write "Log $SADM_LOG trim to ${SADM_MAX_LOGLINE} lines (\$SADM_MAX_LOGLINE=${SADM_MAX_LOGLINE}).\n" 
                     fi 
             fi 
             sadm_write "End of ${SADM_PN} - `date`\n"                  # Write End Time To Log
             sadm_write "${SADM_80_DASH}\n\n\n"                         # Write 80 Dash Line
             cat $SADM_LOG > /dev/null                                  # Force buffer to flush
             if [ $SADM_MAX_LOGLINE -ne 0 ] && [ "$SADM_LOG_APPEND" = "Y" ] # Max Line in Log Not 0 
                then sadm_trimfile "$SADM_LOG" "$SADM_MAX_LOGLINE"      # Trim the Log
             fi                                                         # Else no trim of log made
             chmod 666 ${SADM_LOG} >>/dev/null 2>&1                     # Log writable by Nxt Script
             chgrp ${SADM_GROUP} ${SADM_LOG} >>/dev/null 2>&1           # Change Log Group
             [ $(id -u) -eq 0 ] && chmod 664 ${SADM_LOG}                # R/W Owner/Group R by World
             [ $(id -u) -eq 0 ] && chown ${SADM_USER}:${SADM_GROUP} ${SADM_LOG}  # Change Log Owner
    fi

    # Normally we Delete the PID File when exiting the script.
    # But when script is already running, then we are the second instance of the script
    # we don't want to delete PID file. 
    # When this situation happend (DELETE_PID is set to "N") in sadm_start function. 
    if ( [ -e "$SADM_PID_FILE"  ] && [ "$DELETE_PID" = "Y" ] )          # PID Exist & Only Running 1
        then rm -f $SADM_PID_FILE  >/dev/null 2>&1                      # Delete the PID File
    fi

    # Delete Temporary files used
    if [ -e "$SADM_TMP_FILE1" ] ; then rm -f $SADM_TMP_FILE1 >/dev/null 2>&1 ; fi
    if [ -e "$SADM_TMP_FILE2" ] ; then rm -f $SADM_TMP_FILE2 >/dev/null 2>&1 ; fi
    if [ -e "$SADM_TMP_FILE3" ] ; then rm -f $SADM_TMP_FILE3 >/dev/null 2>&1 ; fi

    # If script is running on the SADMIN server, copy script final log and rch to web data section.
    # If we don't do that, log look incomplete & script seem to be always running on web interface.
    if [ "$(sadm_get_fqdn)" = "$SADM_SERVER" ]                          # Only run on SADMIN 
       then if [ -w ${SADM_WWW_DAT_DIR}/${SADM_HOSTNAME}/log ] 
               then cp $SADM_LOG ${SADM_WWW_DAT_DIR}/${SADM_HOSTNAME}/log
            fi 
            if [ ! -z "$SADM_USE_RCH" ] && [ "$SADM_USE_RCH" = "Y" ]    # Want to Produce RCH File
               then if [ -w  ${SADM_WWW_DAT_DIR}/${SADM_HOSTNAME}/rch ] 
                       then cp $SADM_RCHLOG ${SADM_WWW_DAT_DIR}/${SADM_HOSTNAME}/rch
                    fi
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
#           by altering SADM_ALERT_GROUP variable in it script.
#
#  [E/W/I]  ERROR, WARNING OR INFORMATION ALERT are detected by System Monitor.
#           [M]onitor type Warning and Error Alert Group are taken from the host System Monitor 
#           file ($SADMIN/cfg/hostname.smon).
#           In System monitor file Warning are specify at column 'J' and Error at col. 'K'.
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
#  0 = Success, Alert Sent
#  1 = Error - Aborted could not send alert 
#       - Number of arguments is incorrect
#       - Attachement specified doesn't exist
#       - Alert group name specified, doesn't exist in alert_group.cfg
#       - Alert Group Type is invalid (Not m,s,t or c)
#       - If SLack Used, Slack Channel is missing
#  2 = Same alert yesterday in history file, Alert already Sent, Maxrepeat per day reached
#  3 = Alert older than 24 hrs - Alert wasn't send
# --------------------------------------------------------------------------------------------------
#
sadm_send_alert() 
{
    LIB_DEBUG=0                                                         # Debug Library Level
    if [ $# -ne 8 ]                                                     # Invalid No. of Parameter
        then sadm_write "Invalid number of argument received by function ${FUNCNAME}.\n"
             sadm_write "Should be 8 we received $# : $* \n"            # Show what received
             return 1                                                   # Return Error to caller
    fi

    # Save Parameters Received (After Removing leading and trailing spaces).
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

    # If the Alert group received is 'default' replace it with group specified in alert_group.cfg
    if [ "$agroup" = "default" ] 
       then galias=`grep -i "^$agroup " $SADM_ALERT_FILE | head -1 | awk '{ print $3 }'` 
            agroup=`echo $galias | awk '{$1=$1;print}'`                 # Del Leading/Trailing Space
    fi 

    # Display Values received and we will use in this function.
    if [ $LIB_DEBUG -gt 4 ]                                             # Debug Info List what Recv.
       then printf "\n\nFunction '${FUNCNAME}' parameters received :\n" # Print Function Name
            sadm_write "atype=$atype \n"                                # Show Alert Type
            sadm_write "atime=$atime \n"                                # Show Event Date & Time
            sadm_write "aserver=$aserver \n"                            # Show Server Name
            sadm_write "ascript=$ascript \n"                            # Show Script Name
            sadm_write "agroup=$agroup \n"                              # Show Alert Group
            sadm_write "asubject=\"$asubject\"\n"                       # Show Alert Subject/Title
            sadm_write "amessage=\"$amessage\"\n"                       # Show Alert Message
            sadm_write "aattachment=\"$aattach\"\n"                     # Show Alert Attachment File
    fi

    # Is there is an attachment specified & the attachment is not readable ?
    if [ "$aattach" != "" ] && [ ! -r "$aattach" ]                      # Can't read Attachment File
       then sadm_write "Error in ${FUNCNAME} - Can't read attachment file '$aattach'\n"
            return 1                                                    # Return Error to caller
    fi

    # Validate if the Alert group name in the group alert File.
    grep -i "^$agroup " $SADM_ALERT_FILE >/dev/null 2>&1                # Search in Alert Group File
    if [ $? -ne 0 ]                                                     # Group Missing in GrpFile
        then sadm_write "\n[ ERROR ] Alert group '$agroup' missing from ${SADM_ALERT_FILE}\n"
             sadm_write "  - Alert date/time : $atime \n"               # Show Event Date & Time
             sadm_write "  - Alert subject   : $asubject \n"            # Show Event Subject
             return 1                                                   # Return Error to caller
    fi

    # Validate the Alert type from alert group file ([M]ail, [S]lack, [T]exto or [C]ellular)
    agroup_type=`grep -i "^$agroup " $SADM_ALERT_FILE |awk '{print $2}'` # [S/M/T/C] Group
    agroup_type=`echo $agroup_type |awk '{$1=$1;print}' |tr  "[:lower:]" "[:upper:]"`
    if [ "$agroup_type" != "M" ] && [ "$agroup_type" != "S" ] &&
       [ "$agroup_type" != "T" ] && [ "$agroup_type" != "C" ] 
       then wmess="\n[ ERROR ] Invalid Group Type '$agroup_type' for '$agroup' in $SADM_ALERT_FILE"
            sadm_write "${wmess}\n"
            return 1
    fi

    # Calculate some data that we will need later on 
    # Age of alert in Days (NbDaysOld), in Seconds (aage) & Nb. Alert Repeat per day (MaxRepeat)
    aepoch=$(sadm_date_to_epoch "$atime")                               # Convert AlertTime to Epoch
    cepoch=`date +%s`                                                   # Get Current Epoch Time
    aage=`expr $cepoch - $aepoch`                                       # Age of Alert in Seconds.
    if [ $SADM_ALERT_REPEAT -ne 0 ]                                     # If Config = Alert Repeat
        then MaxRepeat=`echo "(86400 / $SADM_ALERT_REPEAT)" | $SADM_BC` # Calc. Nb Alert Per Day
        else MaxRepeat=1                                                # MaxRepeat=1 NoAlarm Repeat
    fi
    if [ $aage -ge 86400 ]                                              # Alrt Age > 86400sec = 1Day
        then NbDaysOld=`echo "$aage / 86400" |$SADM_BC`                 # Calc. Alert age in Days
        else NbDaysOld=0                                                # Default Alert Age in Days
    fi 
    if [ "$LIB_DEBUG" -gt 4 ]                                           # Debug Info List what Recv.
        then sadm_write "Alert Epoch Time     - aepoch=$aepoch \n"     
             sadm_write "Current EpochTime    - cepoch=$cepoch \n"
             sadm_write "Age of alert in sec. - aage=$aage \n"
             sadm_write "Age of alert in days - NbDaysOld=$NbDaysOld \n"
    fi 

    # If Alert is older than 24 hours, 
    if [ $aage -gt 86400 ]                                              # Alert older than 24Hrs ?
        then if [ "$LIB_DEBUG" -gt 4 ]                                  # If Under Debug
                then sadm_write "Alert older than 24 Hrs ($aage sec.).\n" 
             fi
             return 3                                                   # Return Error to caller
    fi 

    # Search history to see if same alert already exist for today.
    if [ "$atype" != "S" ]                                              # Not Script Alert (Sysmon)
       then asearch=";$adate;$atype;$aserver;$agroup;$asubject;"        # Set Search Str for Sysmon
       else asearch=";$ahour;$adate;$atype;$aserver;$agroup;$asubject;" # Set Search Str for Script
    fi
    if [ "$LIB_DEBUG" -gt 4 ]                                           # If under Debug
        then sadm_write "Search history for \"${asearch}\"\n"           # Show Search String
             grep "${asearch}" $SADM_ALERT_HIST |tee -a $SADM_LOG       # Show grep result
    fi 
    grep "${asearch}" $SADM_ALERT_HIST >>/dev/null 2>&1                 # Search Alert History file
    RC=$?                                                               # Save Grep Result
    if [ "$LIB_DEBUG" -gt 4 ] ; then sadm_write "Search Return is $RC\n" ; fi

    # If same alert wasn't found for today 
    #   - search for same alert for yesterday 
    #   - if it's a Sysmon Alert & age of alert is less than 86400 Sec. (1day) is was alereay sent.
    if [ "$RC" -ne 0 ]                                                  # Alert was Not in History 
        then acounter=0                                                 # Script: SetAlert Sent Cntr
             if [ "$atype" != "S" ]                                     # Not a Script it's a Sysmon 
                then ydate=$(date --date="yesterday" +"%Y.%m.%d")       # Get yesterday date 
                     bsearch=`printf "%s;%s;%s;%s;%s" "$ydate" "$atype" "$aserver" "$agroup" "$asubject"`
                     grep "$bsearch" $SADM_ALERT_HIST >>/dev/null 2>&1  # Search SameAlert Yesterday
                     if [ $? -eq 0 ]                                    # Same Alert Yesterday Found
                        then yepoch=`grep "$bsearch" $SADM_ALERT_HIST |tail -1 |awk -F';' '{print $1}'` 
                             yage=`expr $cepoch - $yepoch`              # Yesterday Alert Age in Sec
                             if [ "$yage" -lt 86400 ]                   # SysmonAlert less than 1day
                                then return 2                           # Return Code 2 to caller
                             fi                                         # Alert already sent 
                     fi
             fi
    fi

    # If the alert was found in the history file , check if user want an alarm repeat
    if [ $RC -eq 0 ]                                                    # Same Alert was found
        then if [ $SADM_ALERT_REPEAT -eq 0 ]                            # User want no alert repeat
                then if [ "$LIB_DEBUG" -gt 4 ]                          # Under Debug
                        then wmsg="Alert already sent, you asked to sent alert only once"
                             sadm_write "$wmsg - (SADM_ALERT_REPEAT set to $SADM_ALERT_REPEAT).\n"
                     fi
                     return 2                                           # Return 2 = Alreay Sent
             fi             
             acounter=`grep "$alertid" $SADM_ALERT_HIST |tail -1 |awk -F\; '{print $2}'` # Actual Cnt
             if [ $acounter -ge $MaxRepeat ]                            # Max Alert per day Reached?
                then if [ "$LIB_DEBUG" -gt 4 ]                          # Under Debug
                        then sadm_write "Maximun number of Alert ($MaxRepeat) reached ($aepoch).\n" 
                     fi
                     return 2                                           # Return 2 = Alreay Sent
             fi 
            WaitSec=`echo "$acounter * $SADM_ALERT_REPEAT" | $SADM_BC`  # Next Alert Elapse Seconds
            if [ $aage -le $WaitSec ]                                   # Repeat Time not reached
                then xcount=`expr $WaitSec - $aage`                     # Sec till nxt alarm is sent
                     nxt_epoch=`expr $cepoch + $xcount`                 # Next Alarm Epoch
                     nxt_time=$(sadm_epoch_to_date "$nxt_epoch")        # Next Alarm Date/Time
                     msg="Waiting - Next alert will be send in $xcount seconds around ${nxt_time}."
                     if [ "$LIB_DEBUG" -gt 4 ] ;then sadm_write "${msg}\n" ;fi 
                     return 2                                            # Return 2 =Duplicate Alert
            fi 
    fi  

    # Update Alarm Counter 
    acounter=`expr $acounter + 1`                                       # Increase alert counter
    if [ $acounter -gt 1 ] ; then amessage="(Repeat) $amessage" ;fi     # Ins.Repeat in Msg if cnt>1
    acounter=`printf "%02d" "$acounter"`                                # Make counter two digits
    if [ "$LIB_DEBUG" -gt 4 ] ;then sadm_write "Repeat alert ($aepoch)-($acounter)-($alertid)\n" ;fi

    NxtInterval=`echo "$acounter * $SADM_ALERT_REPEAT" | $SADM_BC`      # Next Alert Elapse Seconds 
    NxtEpoch=`expr $NxtInterval + $aepoch`                              # Next repeat + ActualEpoch
    NxtAlarmTime=$(sadm_epoch_to_date "$NxtEpoch")                      # Next repeat Date/Time

    # Construct Subject Message base on alert type
    case "$atype" in                                                    # Depending on Alert Type
        E) ws="SADM ERROR: ${asubject}"                                 # Construct Mess. Subject
           ;;  
        W) ws="SADM WARNING: ${asubject}"                               # Build Warning Subject
           ;;  
        I) ws="SADM INFO: ${asubject}"                                  # Build Info Mess Subject
           ;;  
        S) ws="SADM SCRIPT: ${asubject}"                                # Build Script Msg Subject
           ;;  
        *) ws="Invalid Alert Type ($atype): ${aserver} ${asubject}"     # Invalid Alert type Message
           ;;
    esac
    if [ "$LIB_DEBUG" -gt 4 ] ; then sadm_write "Alert Subject will be : $ws \n" ; fi

    # Message Header
    mheader=""                                                          # Default Mess. Header Blank
    if [ "$atype" != "S" ]                                              # If Sysmon Mess(Not Script)
        then mheader="SADMIN System Monitor on '$aserver'."             # Sysmon Header Line
    fi 
    
    # Message Foother 
    if [ $acounter -eq 1 ] && [ $MaxRepeat -eq 1 ]                      # If Alarm is 1 of 1 bypass
        then mfooter=""                                                 # Default Footer is blank
        else mfooter=`printf "%s: %02d of %02d" "Alert counter" "$acounter" "$MaxRepeat"` 
    fi 
    if [ $SADM_ALERT_REPEAT -ne 0 ] && [ $acounter -ne $MaxRepeat ]     # If Repeat and Not Last
       then mfooter=`printf "%s, next notification around %s" "$mfooter" "$NxtAlarmTime"`
    fi
    
    # Final Message combine 
    body=`printf "%s\n%s\n%s" "$mheader" "$amessage" "$mfooter"`        # Construct Final Mess. Body
    if [ "$atype" = "S" ] && [ "$agroup_type" != "T" ]                  # If Script Alert, Not Texto
       then SNAME=`echo ${ascript} |awk '{ print $1 }'`                 # Get Script Name
            LOGFILE="${aserver}_${SNAME}.log"                           # Assemble log Script Name
            LOGNAME="${SADM_WWW_DAT_DIR}/${aserver}/log/${LOGFILE}"     # Add Dir. Path 
            URL_VIEW_FILE='/view/log/sadm_view_file.php'                # View File Content URL
            LOGURL="http://sadmin.${SADM_DOMAIN}/${URL_VIEW_FILE}?filename=${LOGNAME}" 
            body=$(printf "${body}\nView full log :\n${LOGURL}")        # Insert Log URL In Mess
    fi
    if [ "$LIB_DEBUG" -gt 4 ] ; then sadm_write "Alert body will be : $body \n" ; fi


    # Send the Alert Message using the type of alert requested
    case "$agroup_type" in

       # SEND EMAIL ALERT 
       M) aemail=`grep -i "^$agroup " $SADM_ALERT_FILE |awk '{ print $3 }'` # Get Emails of Group
          aemail=`echo $aemail | awk '{$1=$1;print}'`                   # Del Leading/Trailing Space
          if [ "$LIB_DEBUG" -gt 4 ] ; then sadm_write "Email alert sent to $aemail \n" ; fi 
          if [ "$aattach" != "" ]                                       # If Attachment Specified
             then printf "%s\n" "$body" | $SADM_MAIL -s "$ws" -a "$aattach" $aemail >>$SADM_LOG 2>&1 
             else printf "%s\n" "$body" | $SADM_MAIL -s "$ws" $aemail  >>$SADM_LOG 2>&1 
          fi
          RC=$?                                                         # Save Error Number
          if [ $RC -ne 0 ]                                              # Error sending email 
              then wstatus="[ Error ] Sending email to $aemail"         # Advise Error sending Email
                   sadm_write "${wstatus}\n"                            # Show Message to user 
          fi
          ;;

       # SEND SLACK ALERT 
       S) s_channel=`grep -i "^$agroup " $SADM_ALERT_FILE | head -1 | awk '{ print $3 }'` 
          s_channel=`echo $s_channel | awk '{$1=$1;print}'`             # Del Leading/Trailing Space
          grep -i "^$s_channel " $SADM_SLACK_FILE >/dev/null 2>&1       # Search Channel in SlackFile
          if [ $? -ne 0 ]                                               # Channel not in Slack File
              then sadm_write "[ ERROR ] Missing Channel '$s_channel' in ${SADM_SLACK_FILE}\n"
                   return 1                                             # Return Error to caller
          fi
          # Get the WebHook for the selected Channel
          slack_hook_url=`grep -i "^$s_channel " $SADM_SLACK_FILE |awk '{ print $2 }'`
          if [ "$LIB_DEBUG" -gt 4 ]                                     # Library Debugging ON 
              then sadm_write "Slack Channel=$s_channel got Webhook=${slack_hook_url}\n"
          fi
          if [ "$aattach" != "" ]                                       # If Attachment Specified
              then logtail=`tail -20 ${aattach}`                        # Attach file last 50 lines
                   body="${body}\n\n*----Attachment----*\n${logtail}"   # To Slack Message
          fi
          s_text="$body"                                                # Set Final Alert Text
          escaped_msg=$(echo "${s_text}" |sed 's/\"/\\"/g' |sed "s/'/\'/g" |sed 's/`/\`/g')
          s_text="\"text\": \"${escaped_msg}\""                         # Set Final Text Message
          s_icon="warning"                                              # Message Slack Icon
          s_md="\"mrkdwn\": true,"                                      # s_md format to true
          json="{\"channel\": \"${s_channel}\", \"icon_emoji\": \":${s_icon}:\", ${s_md} ${s_text}}"
          if [ "$LIB_DEBUG" -gt 4 ]
              then sadm_write "$SADM_CURL -s -d \"payload=$json\" ${slack_hook_url}\n"
          fi
          SRC=`$SADM_CURL -s -d "payload=$json" $slack_hook_url`        # Send Slack Message
          if [ "$LIB_DEBUG" -gt 4 ] ; then sadm_write "Status after send to Slack is ${SRC}\n" ;fi
          if [ $SRC = "ok" ]                                            # If Sent Successfully
              then RC=0                                                 # Set Return code to 0
                   wstatus="[ OK ] Slack message sent with success to $agroup ($SRC)" 
              else wstatus="[ Error ] Sending Slack message to $agroup ($SRC)"
                   sadm_write "${wstatus}\n"                            # Advise User
                   RC=1                                                 # When Error Return Code 1
          fi
          ;;

       # SEND TEXTO/SMS ALERT
       T) amember=`grep -i "^$agroup " $SADM_ALERT_FILE |awk '{print $3}'` # Get Group Members 
          amember=`echo $amember | awk '{$1=$1;print}'`                 # Del Leading/Trailing Space
          total_error=0                                                 # Total Error Counter Reset
          RC=0                                                          # Function Return Code Def.
          for i in $(echo $amember | tr ',' '\n')                       # For each member of group
              do
              if [ "$LIB_DEBUG" -gt 4 ] 
                  then printf "\nProcessing '$agroup' sms group member '${i}'.\n" 
              fi   
              # Get the Group Member of the Alert Group (Cellular No.)
              acell=`grep -i "^$i " $SADM_ALERT_FILE |awk '{print $3}'` # Get GroupMembers Cell
              acell=`echo $acell   | awk '{$1=$1;print}'`               # Del Leading/Trailing Space
              agtype=`grep -i "^$i " $SADM_ALERT_FILE |awk '{print $2}'` # GroupType should be C
              agtype=`echo $agtype | awk '{$1=$1;print}'`               # Del Leading/Trailing Space
              agtype=`echo $agtype | tr "[:lower:]" "[:upper:]"`        # Make Grp Type is uppercase
              if [ "$agtype" != "C" ]                                   # Member should be type [C]
                  then sadm_write "Member of '$agroup' alert group '$i' is not a type 'C' alert.\n"
                       sadm_write "Alert not send to '$i', proceeding with next member.\n"
                       total_error=`expr $total_error + 1`
                       continue
              fi
              T_URL=$SADM_TEXTBELT_URL                                  # Text Belt URL
              T_KEY=$SADM_TEXTBELT_KEY                                  # User Text Belt Key
              reponse=`${SADM_CURL} -s -X POST $T_URL -d phone=$acell -d "message=$body" -d key=$T_KEY`
              echo "$reponse" | grep -i "\"success\":true," >/dev/null 2>&1   # Success Response ?
              RC=$?                                                     # Save Error Number
              if [ $RC -eq 0 ]                                          # If Error Sending Email
                  then wstatus="SMS message sent to group $agroup ($acell)" 
                  else wstatus="Error ($RC) sending SMS message to group $agroup ($acell)"
                       sadm_write "${wstatus}\n"                        # Advise USer
                       sadm_write "${reponse}\n"                        # Error msg from Textbelt
                       total_error=`expr $total_error + 1`
                       RC=1                                             # When Error Return Code 1
              fi
              done
          if [ $total_error -ne 0 ] ; then RC=1 ; else RC=0 ; fi        # If Error Sending SMS
          ;;
       *) sadm_write "Error in ${FUNCNAME} - Alert Group Type '$agroup_type' not supported.\n"
          RC=1                                                          # Something went wrong
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
#   3th = Alert Group Name   = Alert Group Name to Alert (Must exist in $SADMIN/cfg/alert_group.cfg)
#   4th = Server Name        = Server name where the event happen
#   5th = Alert Description  = Alert Message
#   6th = Alert Sent Counter = Incremented after an alert is sent
#   7th = Alert Status Mess. = Status got after sending alert
#                               - Wait $elapse/$SADM_REPEAT
# Example : 
#   write_alert_history "$atype" "$atime" "$agroup" "$aserver" "$asubject" "$acount" "$astatus"
# --------------------------------------------------------------------------------------------------
write_alert_history() {
    if [ $# -ne 7 ]                                                     # Did not received 7 Param.?
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
# Things to do when first called
# --------------------------------------------------------------------------------------------------
    SADM_STIME=`date "+%C%y.%m.%d %H:%M:%S"`  ; export SADM_STIME       # Save Script Startup Time
    if [ "$LIB_DEBUG" -gt 4 ] ;then sadm_write "main: grepping /etc/environment\n" ; fi
    
    # Get SADMIN Installation Directory
    grep "SADMIN=" /etc/environment >/dev/null 2>&1                     # Do Env.File include SADMIN
    if [ $? -ne 0 ]                                                     # SADMIN missing in /etc/env
        then echo "export SADMIN=$SADMIN" >> /etc/environment           # Then add it to the file
    fi
    
    # User got to be root or be part of the SADMIN Group specified in $SADMIN/cfg/sadmin.cfg
    if [ -r $SADMIN/cfg/sadmin.cfg ]
       then SADM_GROUP=`awk -F= '/^SADM_GROUP/ {print $2}' $SADMIN/cfg/sadmin.cfg | tr -d ' '` 
            if [ $(id -u) -ne 0 ]                                       # If user is not 'root' user
               then usrname=$(id -un)                                   # Get Current User Name
                    if ! id -nG "$usrname" | grep -qw "$SADM_GROUP"     # User part of sadmin group?
                       then echo " "
                            echo "User '$(id -un)' doesn't belong to the '$SADM_GROUP' group."   
                            echo "Non 'root' user MUST be part of the '$SADM_GROUP' group."
                            echo "The '$SADM_GROUP' group is specified in $SADM_CFG_FILE file."
                            echo "Script aborted ..."
                            echo " "
                            exit 1                                      # Exit with Error
                    fi 
            fi
    fi 

    # Read SADMIN Confiuration file and put value in Global Variables.
    sadm_load_config_file                                               # Load sadmin.cfg file
    
    # Check SADMIN requirements
    sadm_check_requirements                                             # Check Lib Requirements
    if [ $? -ne 0 ] ; then exit 1 ; fi                                  # If Requirement are not met
    
    export SADM_SSH_CMD="${SADM_SSH} -qnp${SADM_SSH_PORT}"              # SSH Command to SSH CLient
    #export SADM_USERNAME=$(whoami)                                      # Current User Name
    if [ "$LIB_DEBUG" -gt 4 ] ;then sadm_write "Library Loaded,\n" ; fi
    