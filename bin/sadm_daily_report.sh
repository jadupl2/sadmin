#! /usr/bin/env bash
# --------------------------------------------------------------------------------------------------
#   Author      :  Jacques Duplessis
#   Script name :  sadm_daily_report.sh
#   Synopsis    :  Produce reports of the last 24 hrs activities and email it to the sysadmin.
#   Version     :  1.0
#   Date        :  30 July 2020
#   Requires    :  sh
#   The SADMIN Tool is free software; you can redistribute it and/or modify it under the terms
#   of the GNU General Public License as published by the Free Software Foundation; either
#   version 2 of the License, or (at your option) any later version.
#   SADMIN Tool are distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
#   without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#   See the GNU General Public License for more details.
#
# --------------------------------------------------------------------------------------------------
# Version Change Log 
#
# 2015_12_14 V1.0 Initial Version
# 2020_09_23 V1.1 In Progress September 
# 2020_10_01 Update: v1.2 First Release
# 2020_10_05 Update: v1.3 Daily Backup Report & ReaR Backup Report now available.
# 2020_10_06 Fix: v1.4 Bug that get Current backup size in yellow, when shouldn't.
# 2020_10_06 Update: v1.5 Minor Typo Corrections
# 2020_10_29 Update: v1.6 Change CmdLine Switch & Storix Daily report is working
# 2020_11_04 Update: v1.7 Added 1st draft of scripts html report.
# 2020_11_07 New: v1.8 Exclude file can be use to exclude scripts or servers from daily report.
# 2020_11_08 Updated: v1.9 Show Alert Group Name on Script Report
# 2020_11_10 Fix: v1.10 Minor bug fixes.
# 2020_11_13 New: v1.11 Email of each report now include a pdf of the report(if wkhtmltopdf install)
# 2020_11_12 Updated v1.12 Warning in Yellow when backup outdated, bug fixes.
# 2020_11_21 Updated v1.13 Insert Script execution Title.
# 2020_12_12 Updated v1.14 Major revamp of HTML and PDF Report that are send via email to sysadmin.
# 2020_12_15 Updated v1.15 Cosmetic changes to Daily Report.
# 2020_12_26 Updated v1.16 Include link to web page in email.
# 2020_12_26 Updated v1.17 Insert Header when reporting script error(s).
# 2020_12_27 Updated v1.18 Insert Header when reporting script running.
# 2021_01_13 Updated v1.19 Change reports heading color and font style.
# 2021_01_17 Updated v1.20 Center Heading of scripts report.
# 2021_01_23 Updated v1.21 SCRIPTS & SERVERS variables no longer in "sadm_daily_report_exclude.sh"
# 2021_02_18 Updated v1.22 Added example to 'SERVERS' variable of system to be ignored from Report.
# 2021_04_01 Fix: v1.23 Fix problem when the last line of *.rch was a blank line.
# 2021_04_28 Fix: v1.24 Fix problem with the report servers exclude list.
# 2021_06_08 nolog: v1.25 Remove from daily backup report system that the daily backup is disable.
# 2021_06_08 nolog: v1.26 Remove from daily ReaR backup report system that the backup is disable.
# 2021_06_10 server: v1.27 Show system backup in bold instead of having a yellow background.
# 2021_08_07 server: v1.28 Help message was showing wrong command line options.w background.
# 2022_06_09 server: v1.29 Added AlmaLinux and Rocky Logo for web interface.
# 2022_07_18 server: v1.30 Remove unneeded work file at the end.
# 2022_07_21 server: v1.31 Insert new SADMIN section v1.52.
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPT The Control-C
#set -x



# ---------------------------------------------------------------------------------------
# SADMIN CODE SECTION 1.52
# Setup for Global Variables and load the SADMIN standard library.
# To use SADMIN tools, this section MUST be present near the top of your code.    
# ---------------------------------------------------------------------------------------

# MAKE SURE THE ENVIRONMENT 'SADMIN' VARIABLE IS DEFINED, IF NOT EXIT SCRIPT WITH ERROR.
if [ -z $SADMIN ] || [ ! -r "$SADMIN/lib/sadmlib_std.sh" ] # SADMIN defined ? SADMIN Libr. exist   
    then if [ -r /etc/environment ] ; then source /etc/environment ;fi # Last chance defining SADMIN
         if [ -z $SADMIN ] || [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]    # Still not define = Error
            then printf "\nPlease set 'SADMIN' environment variable to the install directory.\n"
                 exit 1                                    # No SADMIN Env. Var. Exit
         fi
fi 

# USE VARIABLES BELOW, BUT DON'T CHANGE THEM (Used by SADMIN Standard Library).
export SADM_PN=${0##*/}                                    # Script name(with extension)
export SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1`          # Script name(without extension)
export SADM_TPID="$$"                                      # Script Process ID.
export SADM_HOSTNAME=`hostname -s`                         # Host name without Domain Name
export SADM_OS_TYPE=`uname -s |tr '[:lower:]' '[:upper:]'` # Return LINUX,AIX,DARWIN,SUNOS 
export SADM_USERNAME=$(id -un)                             # Current user name.

# USE & CHANGE VARIABLES BELOW TO YOUR NEEDS (They influence execution of SADMIN Library).
export SADM_VER='1.31'                                      # Script version number
export SADM_PDESC="Produce reports of the last 24 hrs activities and email it to the sysadmin."
export SADM_EXIT_CODE=0                                    # Script Default Exit Code
export SADM_LOG_TYPE="B"                                   # Log [S]creen [L]og [B]oth
export SADM_LOG_APPEND="N"                                 # Y=AppendLog, N=CreateNewLog
export SADM_LOG_HEADER="Y"                                 # Y=ProduceLogHeader N=NoHeader
export SADM_LOG_FOOTER="Y"                                 # Y=IncludeFooter N=NoFooter
export SADM_MULTIPLE_EXEC="N"                              # Run Simultaneous copy of script
export SADM_PID_TIMEOUT=7200                               # Sec. before PID Lock expire
export SADM_LOCK_TIMEOUT=3600                              # Sec. before Del. System LockFile
export SADM_USE_RCH="Y"                                    # Update RCH History File (Y/N)
export SADM_DEBUG=0                                        # Debug Level(0-9) 0=NoDebug
export SADM_TMP_FILE1="${SADMIN}/tmp/${SADM_INST}_1.$$"    # Tmp File1 for you to use
export SADM_TMP_FILE2="${SADMIN}/tmp/${SADM_INST}_2.$$"    # Tmp File2 for you to use
export SADM_TMP_FILE3="${SADMIN}/tmp/${SADM_INST}_3.$$"    # Tmp File3 for you to use
export SADM_ROOT_ONLY="Y"                                  # Run only by root ? [Y] or [N]
export SADM_SERVER_ONLY="Y"                                # Run only on SADMIN server? [Y] or [N]

# LOAD SADMIN SHELL LIBRARY AND SET SOME O/S VARIABLES.
. ${SADMIN}/lib/sadmlib_std.sh                             # Load SADMIN Shell Library
export SADM_OS_NAME=$(sadm_get_osname)                     # O/S Name in Uppercase
export SADM_OS_VERSION=$(sadm_get_osversion)               # O/S Full Ver.No. (ex: 9.0.1)
export SADM_OS_MAJORVER=$(sadm_get_osmajorversion)         # O/S Major Ver. No. (ex: 9)
export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} "   # SSH CMD to Access Systems

# VALUES OF VARIABLES BELOW ARE LOADED FROM SADMIN CONFIG FILE ($SADMIN/cfg/sadmin.cfg)
# BUT THEY CAN BE OVERRIDDEN HERE, ON A PER SCRIPT BASIS (IF NEEDED).
#export SADM_ALERT_TYPE=1                                   # 0=No 1=OnError 2=OnOK 3=Always
#export SADM_ALERT_GROUP="default"                          # Alert Group to advise
#export SADM_MAIL_ADDR="your_email@domain.com"              # Email to send log
#export SADM_MAX_LOGLINE=500                                # Nb Lines to trim(0=NoTrim)
#export SADM_MAX_RCLINE=35                                  # Nb Lines to trim(0=NoTrim)
# ---------------------------------------------------------------------------------------





# -----------------------------------------------------------------------------
# Daily Report Exclude List
# The SCRIPTS variable is used to specify some scripts to be excluded from 
# the web scripts report. Script name are specify without extension.
#
# The SERVERS variable should contain the system hostname (Without Domain Name)
# to be excluded from the reports (ALL the reports).
# -----------------------------------------------------------------------------

# SCRIPTS variable declare the script names you don't want to see in the
# daily script web report.
SCRIPTS="sadm_backup sadm_rear_backup sadm_nmon_watcher " 

# Exclude scripts that are executing as part of sadm_client_sunset script.
# Any error encountered by the scripts below, will be reported by sadm_client_sunset.
SCRIPTS="$SCRIPTS sadm_dr_savefs sadm_create_sysinfo sadm_cfg2html"

# Exclude scripts that are executing as part of sadm_server_sunrise script.
# Any error encountered by the scripts below, will be reported by sadm_server_sunrise.
SCRIPTS="$SCRIPTS sadm_daily_farm_fetch sadm_database_update sadm_nmon_rrd_update "

# Exclude System Startup and Shutdown Script for Daily scripts Report
# This one is optional
SCRIPTS="$SCRIPTS sadm_startup sadm_shutdown"

# Exclude template scripts and demo scripts.
SCRIPTS="$SCRIPTS sadm_template sadmlib_std_demo"

# Define here your custom scripts you want to exclude from the script daily report
SCRIPTS="$SCRIPTS sadm_vm_tools sadm_vm_start sadm_vm_stop"

# Server name to be exclude from every Daily Report (Backup, Rear and Scripts)
SERVERS="dm4500w gandalf"



#===================================================================================================
# Global Scripts Variables 
#===================================================================================================
#
export FIELD_IN_RCH=10                                                  # Nb of field in a RCH File
export TOTAL_ERROR=0                                                    # Total Error in script
export URL_VIEW_FILE='/view/log/sadm_view_file.php'                     # View log File Content URL

# If the size of Today & Yesterday Backup/ReaR this percentage, it will highlight in yellow
export WPCT=50                                                          # BackupSize 50% Larger/lower

export BACKUP_REPORT="ON"                                               # Backup Report Activated
export REAR_REPORT="ON"                                                 # ReaR Report Activated
export SCRIPT_REPORT="ON"                                               # Scripts Report Activated
export STORIX_REPORT="OFF"                                              # Storix Report De-Activated

# Output HTML and PDF page for each type of report.
export HTML_BFILE="${SADM_WWW_DIR}/view/daily_backup_report.html"       # Backup Report HTML File 
export PDF_BFILE="${SADM_WWW_DIR}/view/daily_backup_report.pdf"         # Backup Report PDF File 
#
export HTML_RFILE="${SADM_WWW_DIR}/view/daily_rear_report.html"         # ReaR Backup Rep. HTML File 
export PDF_RFILE="${SADM_WWW_DIR}/view/daily_rear_report.pdf"           # ReaR Backup Rep. PDF File 
#
export HTML_XFILE="${SADM_WWW_DIR}/view/daily_storix_report.html"       # Storix Rep. HTML File 
export PDF_XFILE="${SADM_WWW_DIR}/view/daily_storix_report.pdf"         # Storix Rep. PDF File 
#
export HTML_SFILE="${SADM_WWW_DIR}/view/daily_scripts_report.html"      # Scripts Rep. HTML File 
export PDF_SFILE="${SADM_WWW_DIR}/view/daily_scripts_report.pdf"        # Scripts Rep. PDF File 


# Define NFS local mount point depending of O/S
if [ "$SADM_OS_TYPE" = "DARWIN" ]                                       # If on MacOS
    then export LOCAL_MOUNT="/preserve/daily_report"                    # NFS Mount Point for OSX
    else export LOCAL_MOUNT="/mnt/daily_report"                         # NFS Mount Point for Linux
fi  

# Variable used for the Rear Report.
export rear_script_name="sadm_rear_backup"                              # Name of ReaR Backup Script
export REAR_INTERVAL=14                                                 # Day between ReaR Backup
URL_REAR_SCHED='/crud/srv/sadm_server_rear_backup.php?sel=SYSTEM&back=/view/sys/sadm_view_rear.php' 

# Variables fused for the Storix Daily Report
ISODIR="iso"                                                            # NFS SubDir for Storix ISO 
IMGDIR="image"                                                          # NFS SubDir for Storix Img
STWARN=14                                                               # Backup Older = Yellow 

# Backup Report Variables.
# Different format of Today and Yesterday Date used to produce Backup Report
backup_script_name="sadm_backup"                                        # Name of DailyBackup Script
URL_UPD_SCHED='/crud/srv/sadm_server_backup.php?sel=SYSTEM&back/view/sys/sadm_view_backup.php'
export TODAY=`date "+%Y.%m.%d"`                                         # Today Date YYYY.MM.DD
export YESTERDAY=$(date --date="yesterday" +"%Y.%m.%d")                 # Yesterday Date YYYY.MM.DD
export UND_YESTERDAY=$(date --date="yesterday" +"%Y_%m_%d")             # Yesterday Date YYYY_MM_DD

# Script Report Variables
declare -a rch_array                                                    # Lst Line of each rch array 
RCH_SUMMARY="${SADM_TMP_DIR}/scripts_summary.txt"                       # RCH Summary File
SCRIPT_MAX_AGE=30                                                       # Max Script Age Days=Yellow

# DataBase extracted Information for one server
export DB_SERVER=""                                                     # Server Name
export DB_DESC=""                                                       # Server Description
export DB_OSNAME=""                                                     # Server O/S Name
export DB_OSVERSION=""                                                  # Server O/S Version

# Script Global variables used when splitting the RCH line 
export RCH_SERVER=""                                                    # RCH Server Name
export RCH_DATE1=""                                                     # RCH Date Started
export RCH_TIME1=""                                                     # RCH Time Started
export RCH_DATE2=""                                                     # RCH Date Started
export RCH_TIME2=""                                                     # RCH Time Ended
export RCH_ELAPSE=""                                                    # RCH Time Ended
export RCH_SCRIPT=""                                                    # RCH Script Name
export RCH_ALERT=""                                                     # RCH Alert Group Name
export RCH_TYPE=""                                                      # RCH Alert Group Type
export RCH_RCODE=""                                                     # RCH Return Code 






# --------------------------------------------------------------------------------------------------
# Show Script command line option
# --------------------------------------------------------------------------------------------------
show_usage()
{
    printf "\nUsage: %s%s%s [options]" "${BOLD}${CYAN}" $(basename "$0") "${NORMAL}"
    printf "\nDesc.: %s" "${BOLD}${CYAN}${SADM_PDESC}${NORMAL}"
    printf "\n\n${BOLD}${GREEN}Options:${NORMAL}"
    printf "\n   ${BOLD}${YELLOW}[-d 0-9]${NORMAL}\t\tSet Debug (verbose) Level"
    printf "\n   ${BOLD}${YELLOW}[-h]${NORMAL}\t\t\tShow this help message"
    printf "\n   ${BOLD}${YELLOW}[-v]${NORMAL}\t\t\tShow script version information"
    printf "\n   ${BOLD}${YELLOW}[-b]${NORMAL}\t\t\tDon't produce and email the Backup report"
    printf "\n   ${BOLD}${YELLOW}[-r]${NORMAL}\t\t\tDon't produce and email the ReaR report"
    printf "\n   ${BOLD}${YELLOW}[-s]${NORMAL}\t\t\tDon't produce and email the Scripts report"
    printf "\n\n" 
}





# ==================================================================================================
# Mount the NFS $1 on ${LOCAL_MOUNT}
# ==================================================================================================
mount_nfs()
{
    REM_MOUNT="$1"                                                      # Remote NFS Mount Point
    if [ ! -d ${LOCAL_MOUNT} ]                                          # Mount Point doesn't exist
        then mkdir -p ${LOCAL_MOUNT}                                    # Create if not exist
             if [ $? -ne 0 ]                                            # If Error trying to mount
                then sadm_writelog "${SADM_ERROR} Creating local mount point."
                     return 1                                           # End Function with error
                else sadm_writelog "${SADM_OK} Local mount point created."
             fi
             chmod 775 ${LOCAL_MOUNT}                                   # Change Permission 
    fi

    # Make sure it's not already mounted or in use (Umount it)
    cd $SADM_TMP_DIR                                                    # Make sure ! in LOCAL_MOUNT                                           
    umount ${LOCAL_MOUNT} > /dev/null 2>&1                              # Make sure not mounted

    # Mount the NFS mount point.
    if [ "$SADM_OS_TYPE" = "DARWIN" ]                                   # If on MacOS
        then mount -t nfs -o resvport,rw ${REM_MOUNT} ${LOCAL_MOUNT} >>$SADM_LOG 2>&1
             RC=$?                                                      # Save Return Code
        else mount ${REM_MOUNT} ${LOCAL_MOUNT} >>$SADM_LOG 2>&1         # Mount NFS Drive
             RC=$?                                                      # Save Return Code
    fi
    if [ $RC -ne 0 ]                                                    # If Error trying to mount
        then sadm_writelog "${SADM_ERROR} Mount ${REM_MOUNT} ${LOCAL_MOUNT}" # Error - Advise User
             return 1                                                   # End Function with error
        else sadm_writelog "${SADM_OK} Mount ${REM_MOUNT} ${LOCAL_MOUNT}" # NFS Mount Succeeded Msg
    fi
    return 0
}




# ==================================================================================================
# Unmount NFS Directory and delete the local mount point
# ==================================================================================================
unmount_nfs()
{
    cd $SADM_TMP_DIR                                                    # Make sure not in UmountDir
    umount $LOCAL_MOUNT >> $SADM_LOG 2>&1                               # Umount Just to make sure
    if [ $? -ne 0 ]                                                     # If Error trying to mount
        then sadm_writelog "${SADM_ERROR} Unmount NFS mount directory ${LOCAL_MOUNT}"                               # Show user Error Unmounting
             return 1                                                   # End Function with error
        else sadm_writelog "${SADM_OK} Unmount directory ${LOCAL_MOUNT}" # Show Unmount Result
             rm -f $LOCAL_MOUNT >/dev/null 2>&1                         # Remove Local Mount Point
    fi
    return 0
}



# ==================================================================================================
# Read Server information from the Database
# ==================================================================================================
read_server_column()
{
    WSERVER=$1                                                          # Server to Read Info

    # See rows available in 'table_structure_server.pdf' in $SADMIN/doc/database_info directory
    SQL="SELECT srv_name,srv_desc,srv_osname,srv_osversion,srv_ostype,srv_domain"  
    SQL="${SQL},srv_monitor,srv_sporadic,srv_active,srv_sadmin_dir "
    SQL="${SQL} from server"                                            # From the Server Table
    SQL="${SQL} where srv_name = '$WSERVER' ;"                          # Read Selected server
    CMDLINE="$SADM_MYSQL -u $SADM_RO_DBUSER  -p$SADM_RO_DBPWD "         # MySQL Auth/Read Only User
    $CMDLINE -h $SADM_DBHOST $SADM_DBNAME -Ne "$SQL" | tr '/\t/' '/;/' >$SADM_TMP_FILE3

    if [ ! -s "$SADM_TMP_FILE3" ] || [ ! -r "$SADM_TMP_FILE3" ]         # File not readable or 0 len
        then sadm_write "$SADM_WARNING System '$WSERVER' was not found in Database.\n"
             DB_SERVER=""                                               # Server Name
             DB_DESC=""                                                 # Server Description
             DB_OSNAME=""                                               # Server O/S Name
             DB_OSVERSION=""                                            # Server O/S Version
             return 1                                                   # Return Status to Caller
        else DB_LINE=$(head -1 $SADM_TMP_FILE3)                         # Get First (Only) Line 
             if [ $SADM_DEBUG -gt 5 ] ; then sadm_writelog "DB_LINE=$DB_LINE" ; fi 
             DB_SERVER=$(echo "$DB_LINE"   | awk -F\; '{print $1}')     # Server Name
             DB_DESC=$(echo "$DB_LINE"     | awk -F\; '{print $2}')     # Server Description
             DB_OSNAME=$(echo "$DB_LINE"   | awk -F\; '{print $3}')     # Server O/S Name
             DB_OSVERSION=$(echo "$DB_LINE"| awk -F\; '{print $4}')     # Server O/S Version
    fi 
    return 0
}



# ==================================================================================================
# Show Distribution Logo as a cell in a table
# ==================================================================================================
insert_logo() 
{
    whost=$1                                                            # Host Name
    WHTML=$2                                                            # HTML File Name to write to
    read_server_column "$whost"                                         # Read Server Info in DB
    if [ $SADM_DEBUG -gt 5 ]
        then sadm_writelog "In insert_logo whost=$whost - WHTML=$WHTML - DB_OSNAME=$DB_OSNAME $DB_DESC"
    fi         

    echo -n "<th class='dt-center' rowspan=2>" >> $WHTML 
    case $DB_OSNAME in 
        'redhat')       echo -n "<a href='http://www.redhat.com' " >> $WHTML 
                        echo -n "title='Server $whost is a RedHat server - Visit redhat.com'>" >> $WHTML
                        echo -n "<img src='http://sadmin.${SADM_DOMAIN}/images/logo_redhat.png' " >> $WHTML
                        echo -e "style='width:32px;height:32px;'></a></th>\n" >> $WHTML
                        ;;
        'fedora')       echo -n "<a href='https://getfedora.org' " >> $WHTML
                        echo -n "title='Server $whost is a Fedora server - Visit getfedora.org'>" >> $WHTML
                        echo -n "<img src='http://sadmin.${SADM_DOMAIN}/images/logo_fedora.png' " >> $WHTML
                        echo -e "style='width:32px;height:32px;'></a></th>\n" >> $WHTML
                        ;;
        'macosx')       echo -n "<a href='https://apple.com' " >> $WHTML
                        echo -n "title='Server $whost is an Apple System - Visit apple.com'>" >> $WHTML
                        echo -n "<img src='http://sadmin.${SADM_DOMAIN}/images/logo_apple.png' " >> $WHTML
                        echo -e "style='width:32px;height:32px;'></a></th>\n" >> $WHTML
                        ;;
        'centos')       echo -n "<a href='https://www.centos.org' " >> $WHTML
                        echo -n "title='Server $whost is a CentOS server - Visit centos.org'>" >> $WHTML
                        echo -n "<img src='http://sadmin.${SADM_DOMAIN}/images/logo_centos.png' " >> $WHTML
                        echo -e "style='width:32px;height:32px;'></a></th>\n" >> $WHTML
                        ;;
        'ubuntu')       echo -n "<a href='https://www.ubuntu.com/' " >> $WHTML
                        echo -n "title='Server $whost is a Ubuntu server - Visit ubuntu.com'>" >> $WHTML
                        echo -n "<img src='http://sadmin.${SADM_DOMAIN}/images/logo_ubuntu.png' " >> $WHTML
                        echo -e "style='width:32px;height:32px;'></a></th>\n" >> $WHTML
                        ;;
        'linuxmint')    echo -n "<a href='https://linuxmint.com/' " >> $WHTML
                        echo -n "title='Server $whost is a LinuxMint server - Visit linuxmint.com'>" >> $WHTML
                        echo -n "<img src='http://sadmin.${SADM_DOMAIN}/images/logo_linuxmint.png' " >> $WHTML
                        echo -e "style='width:32px;height:32px;'></a></th>\n" >> $WHTML
                        ;;
        'debian')       echo -n "<a href='https://www.debian.org/' " >> $WHTML
                        echo -n "title='Server $whost is a Debian server - Visit debian.org'>" >> $WHTML
                        echo -n "<img src='http://sadmin.${SADM_DOMAIN}/images/logo_debian.png' " >> $WHTML
                        echo -e "style='width:32px;height:32px;'></a></th>\n" >> $WHTML
                        ;;
        'raspbian')     echo -n "<a href='https://www.raspbian.org/' " >> $WHTML
                        echo -n "title='Server $whost is a Raspbian server - Visit raspian.org'>" >> $WHTML
                        echo -n "<img src='http://sadmin.${SADM_DOMAIN}/images/logo_raspbian.png' " >> $WHTML
                        echo -e "style='width:32px;height:32px;'></a></th>\n" >> $WHTML
                        ;;
        'almalinux')    echo -n "<a href='https://almalinux.org/' " >> $WHTML
                        echo -n "title='Server $whost is a AlmaLinux server - Visit almalinux.org'>" >> $WHTML
                        echo -n "<img src='http://sadmin.${SADM_DOMAIN}/images/logo_almalinux.png' " >> $WHTML
                        echo -e "style='width:32px;height:32px;'></a></th>\n" >> $WHTML
                        ;;
        'rocky')        echo -n "<a href='https://rockylinux.org//' " >> $WHTML
                        echo -n "title='Server $whost is a Rocky Linux server - Visit rockylinux.org'>" >> $WHTML
                        echo -n "<img src='http://sadmin.${SADM_DOMAIN}/images/logo_rockylinux.png' " >> $WHTML
                        echo -e "style='width:32px;height:32px;'></a></th>\n" >> $WHTML
                        ;;
        'suse')         echo -n "<a href='https://www.opensuse.org/' " >> $WHTML
                        echo -n "title='Server $whost is a OpenSUSE server - Visit opensuse.org'>" >> $WHTML
                        echo -n "<img src='http://sadmin.${SADM_DOMAIN}/images/logo_suse.png' " >> $WHTML
                        echo -e "style='width:32px;height:32px;'></a></th>\n" >> $WHTML
                        ;;
        'aix')          echo -n "<a href='http://www-03.ibm.com/systems/power/software/aix/' " >> $WHTML
                        echo -n "title='Server $whost is an AIX server - Visit Aix Home Page'>" >> $WHTML
                        echo -n "<img src='http://sadmin.${SADM_DOMAIN}/images/logo_aix.png' " >> $WHTML
                        echo -e "style='width:32px;height:32px;'></a></th>\n" >> $WHTML
                        ;;
        *)              echo "<img src='http://sadmin.${SADM_DOMAIN}/images/logo_linux.png' style='width:32px;height:32px;'>" >> $WHTML
                        echo "${WOS}</th>\n" >> $WHTML
                        ;;
    esac
}



# ==================================================================================================
# Mount the NFS Directory where all the ReaR backup files are stored 
# Produce a list of the latest backup for every systems.
# ==================================================================================================
script_report() 
{
    script_error=0                                                      # Nb of Error Encountered
    if [ -f "$HTML_SFILE" ] ;then rm -f $HTML_SFILE >/dev/null 2>&1 ;fi # Output HTML Report file. 
    sadm_writelog "${BOLD}${YELLOW}Creating the Daily Script Report${NORMAL}"  
    sadm_writelog "${SADM_OK} Create Script Web Page." 

    # Generate the Web Page Heading
    script_page_heading "SADMIN Daily Scripts Report - `date +%a` `date '+%C%y.%m.%d %H:%M:%S'`" 


    # SCRIPTS THAT ARE CURRENTLY RUNNING SECTION
    #
    if [ $SADM_DEBUG -gt 4 ]; then sadm_writelog "Checking for running script ..." ; fi 
    xcount=0                                                            # Nb. of Running script 
    for RCH_LINE in "${rch_array[@]}"                                   # For every item in array
        do 
        RCH_RCODE=` echo -e $RCH_LINE | awk '{ print $10 }'`            # Extract Return Code 
        if [ $RCH_RCODE -eq 2 ]                                         # If 'Running' Status
            then split_rchline "$RCH_LINE"                              # Split Line into fields
                 xcount=$(($xcount+1))                                  # Increase Line Counter
                 if [ $xcount -eq 1 ] 
                    then msg="List of running script(s)"
                         echo -e "<center>\n"  >>$HTML_SFILE
                         echo -e "\n<p class='report_subtitle'>$msg</p>\n" >>$HTML_SFILE 
                         echo -e "<center>\n"  >>$HTML_SFILE
                         script_table_heading "Script(s) currently running" "$RCH_SERVER"
                 fi
                 script_line "$xcount"                                  # Show line in Table
                 sadm_writelog "- Script $RCH_SCRIPT is running on $RCH_SERVER since ${RCH_TIME1}."
        fi 
        done
    if [ $xcount -eq 0 ]                                                # If no running script found
        then echo "<p style='color:blue;'>" >>$HTML_SFILE
             msg="No script actually running" >>$HTML_SFILE             # Section Title Header
             echo -e "\n<center>" >> $HTML_SFILE
             echo -e "<p class='report_subtitle'>$msg</p>\n" >>$HTML_SFILE
             echo -e "\n</center>" >> $HTML_SFILE
             sadm_writelog "${SADM_OK} No script actually running."     # Feed Screen & Log
        else echo -e "</table>\n<br>\n" >> $HTML_SFILE                  # End of HTML Table
    fi
    echo -e "\n<hr class="dash">\n" >> $HTML_SFILE                      # Horizontal Dashed Line


    # SCRIPT THAT TERMINATED WITH ERROR SECTION
    #echo -e "\n<center><h3>List of script(s) terminated with error(s)</h3></center>\n" >>$HTML_SFILE
    if [ $SADM_DEBUG -gt 4 ]; then sadm_writelog "Checking for script(s) ended with error ..." ; fi 
    xcount=0                                                            # Nb. of Running script 
    for RCH_LINE in "${rch_array[@]}"                                   # For every item in array
        do 
        RCH_RCODE=` echo -e $RCH_LINE | awk '{ print $10 }'`            # Extract Return Code 
        split_rchline "$RCH_LINE"                                       # Split Line into fields
        if [ $RCH_RCODE -eq 1 ]                                         # If Terminated with 'Error'
            then split_rchline "$RCH_LINE"                              # Split Line into fields
                 xcount=$(($xcount+1))                                  # Increase Line Counter
                 if [ $xcount -eq 1 ] 
                    then msg="List of script(s) terminated with error(s)"
                         echo -e "\n<center><p class='report_subtitle'>$msg</p></center>\n" >>$HTML_SFILE
                         script_table_heading "Script Ended With Error" "$RCH_SERVER"
                 fi
                 script_line "$xcount"                                  # Show line in Table
                 sadm_writelog "- Script $RCH_SCRIPT on $RCH_SERVER ended with error at $RCH_TIME2."
                 FOUND=$(($FOUND+1))                                    # Increment Found Counter
        fi 
        done
    if [ $xcount -eq 0 ]                                                # If no running script found
        then msg="No script terminated with error" >>$HTML_SFILE        # Message to User
             echo -e "\n<center><p class='report_subtitle'>$msg</p></center>\n" >>$HTML_SFILE  
             sadm_writelog "${SADM_OK} $msg"                            # Feed Screen & Log
        else echo -e "</table>\n<br>\n" >> $HTML_SFILE                  # End of HTML Table
    fi
    echo -e "\n<hr class="dash">\n\n" >> $HTML_SFILE                    # Horizontal Dashed Line


    # SCRIPT EXECUTION HISTORY SECTION
    msg="Scripts execution history by system name" >>$HTML_SFILE        # Section Title Header
    echo -e "\n<center><p class='report_subtitle'>$msg</p></center>\n" >>$HTML_SFILE     # Insert Header on Page
    current_server=""                                                   # Clear Current Server Name
    # Sort by server name and by reverse execution date.
    sort -t' ' -k1,1 -k2,2r  $RCH_SUMMARY | grep -iv "storix" > $SADM_TMP_FILE1
    #sort -t' ' -k1,1 -k2,2r  $RCH_SUMMARY | grep -iv "storix" > /tmp/sorted.txt
    while read RCH_LINE                                                 # Read Tmp file Line by Line
        do
        split_rchline "$RCH_LINE"                                       # Split Line into fields

        # Check if server is in the Exclude list
        #echo "$SERVERS" | grep -i "$RCH_SERVER" >>/dev/null 2>&1        # Server in excl. ServerList 
        #if [ $? -eq 0 ] ; then continue ; fi                            # Skip Server in Excl. List
        lfound=0                                                        # Default not in excl. list
        for lserver in $SERVERS                                         # Loop exclude server list
            do
            if [ "$lserver" = "$RCH_SERVER" ] ; then lfound=1 ; fi      # Server in Exclude LIst
            done
        if [ $lfound -eq 1 ] ; then continue ; fi                       # Skip Server in Excl. List

        echo "$SCRIPTS" | grep -i "$RCH_SCRIPT" >>/dev/null 2>&1        # Script in excl. ServerList 
        if [ $? -eq 0 ] ; then continue ; fi                            # Skip Script in Excl. List
        if [ "$current_server" = "" ]                                   # Is it the time loop
           then script_table_heading "'$RCH_SERVER' system scripts" "$RCH_SERVER"
                current_server=$RCH_SERVER                              # Save Actual Server Name
                xcount=0                                                # Set Server Counter to 0 
        fi 
        if [ "$current_server" != "$RCH_SERVER" ]                       # ServerName Different 
           then echo -e "</table>\n<br>\n" >> $HTML_SFILE               # End of Previous Server 
                xcount=1                                                # Reset Line Counter to 1
                current_server=$RCH_SERVER                              # ServerName = Actual Server
                script_table_heading "'$RCH_SERVER' system scripts" "$RCH_SERVER"
           else xcount=$(($xcount+1))                                   # Increase Line Counter
        fi 
        script_line "$xcount"                                           # Show RCH line in Table
        done < $SADM_TMP_FILE1                                          # Read RCH from Sorted File
    echo -e "</table>\n<br><br>\n" >> $HTML_SFILE                       # End of Server HTML Table
    sadm_writelog "${SADM_OK} Scripts grouped by server page generated" # Show progress to user

    # End of HTML Page
    echo -e "\n<hr class="large_green">\n"              >> $HTML_SFILE  # Big Horizontal Green Line
    echo -e "</body>\n</html>\n\n" >> $HTML_SFILE                           # End of HTML Page


    # Set Report by Email to SADMIN Administrator
    subject="SADMIN Script Report"                                      # Send Backup Report by mail
    export EMAIL="$SADM_MAIL_ADDR"                                      # Set the FROM Email 
    if [ "$WKHTMLTOPDF" != "" ]                                         # If wkhtmltopdf on System
        then $WKHTMLTOPDF $HTML_SFILE $PDF_SFILE > /dev/null 2>&1       # Convert HTML Page to PDF
             mutt -e 'set content_type=text/html' -s "$subject" $SADM_MAIL_ADDR -a $PDF_SFILE < $HTML_SFILE
             SADM_EXIT_CODE=$?                                          # Save mutt return Code.
        else mutt -e 'set content_type=text/html' -s "$subject" $SADM_MAIL_ADDR < $HTML_SFILE
             SADM_EXIT_CODE=$?                                          # Save mutt return Code.
    fi 
    if [ $SADM_EXIT_CODE -eq 0 ]                                        # If mail sent successfully
        then sadm_writelog "[ OK ] Script report sent to $SADM_MAIL_ADDR"      
        else sadm_writelog "[ ERROR ] Sending script report email to $SADM_MAIL_ADDR"
    fi

    sadm_write "${BOLD}${YELLOW}End of the Script Report ...${NORMAL}\n" 
    sadm_write "\n"
    return 0
}


# ==================================================================================================
# Function used to split a RCH file line into separated global variables
# ==================================================================================================
split_rchline() 
{
    RLINE="$1"                                                          # RCH Line received
    RCH_SERVER=`echo -e $RLINE | awk '{ print $1 }'`                    # Extract Server Name
    RCH_DATE1=` echo -e $RLINE | awk '{ print $2 }'`                    # Extract Date Started
    RCH_TIME1=` echo -e $RLINE | awk '{ print $3 }'`                    # Extract Time Started
    RCH_DATE2=` echo -e $RLINE | awk '{ print $4 }'`                    # Extract Date Started
    RCH_TIME2=` echo -e $RLINE | awk '{ print $5 }'`                    # Extract Time Ended
    RCH_ELAPSE=`echo -e $RLINE | awk '{ print $6 }'`                    # Extract Time Ended
    RCH_SCRIPT=`echo -e $RLINE | awk '{ print $7 }'`                    # Extract Script Name
    RCH_ALERT=` echo -e $RLINE | awk '{ print $8 }'`                    # Extract Alert Group Name
    RCH_TYPE=`  echo -e $RLINE | awk '{ print $9 }'`                    # Extract Alert Group Type
    RCH_RCODE=` echo -e $RLINE | awk '{ print $10 }'`                   # Extract Return Code 
}



# ==================================================================================================
# Script Page Heading
# ==================================================================================================
script_page_heading()
{
    RTITLE="$1"                                                         # Set Page Title
    #
    echo -e "<!DOCTYPE html><html>"         >  $HTML_SFILE
    echo -e "<head>"                        >> $HTML_SFILE
    echo -e "<meta charset='utf-8' />"      >> $HTML_SFILE

    echo -e "<style>"                                                               >> $HTML_SFILE
    #echo -e "th { color: white; background-color: #000000; padding: 0px; }"         >> $HTML_SFILE
    echo -e "th { color: black; background-color: #f1f1f1; padding: 5px; }"         >> $HTML_SFILE
    echo -e "td { color: white; border-bottom: 1px solid #ddd; padding: 5px; }"     >> $HTML_SFILE
    echo -e "table, th, td { border: 1px solid black; border-collapse: collapse; }" >> $HTML_SFILE
    echo -e "div.fs150   { font-size: 150%; }"                  >> $HTML_SFILE
    echo -e "div.fs13px  { text-align: left; font-size: 13px; }"                  >> $HTML_SFILE
    echo -e "\n/* Dashed red border */"                         >> $HTML_SFILE
    echo -e "hr.dash        { border-top: 1px dashed red; }"    >> $HTML_SFILE
    echo -e "/* Large rounded green border */"                  >> $HTML_SFILE
    echo -e "hr.large_green { border: 2px solid green; border-radius: 5px; }"       >> $HTML_SFILE
    echo -e "p.report_title {" >> $HTML_SFILE
    echo -e "   font-family:Helvetica,Arial;color:blue;font-size:25px;font-weight:bold;" >> $HTML_SFILE
    echo -e "}" >> $HTML_SFILE    
    echo -e "p.report_subtitle {" >> $HTML_SFILE
    echo -e "   font-family:Helvetica,Arial;color:brown;font-size:18px;font-weight:bold;" >> $HTML_SFILE
    echo -e "}" >> $HTML_SFILE    
    echo -e "</style>"                                                              >> $HTML_SFILE
    echo -e "<title>$RTITLE</title>\n"                          >> $HTML_SFILE
    echo -e "</head>"                                           >> $HTML_SFILE
    echo -e "<body>"                                            >> $HTML_SFILE

    echo -e "<center>" >> $HTML_SFILE                                   # Center what's coming
    echo -e "<p class='report_title'>${RTITLE}</p>" >> $HTML_SFILE      # Report Title
    #
    URL_SCRIPTS_REPORT="/view/daily_scripts_report.html"                # Scripts Daily Report Page
    RURL="http://sadmin.${SADM_DOMAIN}/${URL_SCRIPTS_REPORT}"           # Full URL to HTML report 
    TITLE2="View the web version of this report"                        # Link Description
    echo -e "</center>" >> $HTML_SFILE                                  # End Text Center
    echo -e "<div class='fs13px'><a href='${RURL}'>${TITLE2}</a></div>" >>$HTML_SFILE    # Insert Link on Page

    echo -e "\n<hr class="large_green">\n"              >> $HTML_SFILE  # Big Horizontal Green Line
    #echo -e "<br>" >> $HTML_SFILE
}




#===================================================================================================
# Script Report Heading
#===================================================================================================
script_table_heading()
{
    RTITLE=$1                                                           # Table Heading Title
    RSERVER=$2                                                          # Name Of Server

    echo -e "\n<center>\n<table border=0>"                    >> $HTML_SFILE
    echo -e "\n<thead>"                                       >> $HTML_SFILE

    echo -e "<tr>"                                            >> $HTML_SFILE
    insert_logo "$RSERVER" "$HTML_SFILE"
    ROS=$(sadm_capitalize $DB_OSNAME)
    echo -e "<th colspan=9>System '${RSERVER}' - $DB_DESC</th>" >> $HTML_SFILE
    echo -e "</tr>"                                           >> $HTML_SFILE
    echo -e "<tr>"                                            >> $HTML_SFILE
    #echo -e "<th colspan=10 dt-head-center>${RTITLE}</th>"    >> $HTML_SFILE
    echo -e "<th colspan=10>${ROS} - Version ${DB_OSVERSION}</th>"    >> $HTML_SFILE
    echo -e "</tr>"                                           >> $HTML_SFILE

    echo -e "<tr>"                                            >> $HTML_SFILE
    echo -e "<th>No</th>"                                     >> $HTML_SFILE
    echo -e "<th>Date</th>"                                   >> $HTML_SFILE
    echo -e "<th>Status</th>"                                 >> $HTML_SFILE
    echo -e "<th>Server</th>"                                 >> $HTML_SFILE
    echo -e "<th>Script/Log</th>"                             >> $HTML_SFILE
    echo -e "<th>Started</th>"                                >> $HTML_SFILE
    echo -e "<th>Ended</th>"                                  >> $HTML_SFILE
    echo -e "<th>Elapse</th>"                                 >> $HTML_SFILE
    echo -e "<th>Alert Type</th>"                             >> $HTML_SFILE
    echo -e "<th>Alert Group</th>"                            >> $HTML_SFILE
    echo -e "</tr>"                                           >> $HTML_SFILE

    echo -e "</thead>"                                        >> $HTML_SFILE
    echo -e " "                                               >> $HTML_SFILE
}


#===================================================================================================
# Print RCH line to HTML Table
#===================================================================================================
script_line()
{
    xcount=$1                                                           # Line Counter  
        
    # Set Background Color - Color at https://www.w3schools.com/tags/ref_colornames.asp
    # Alternate background color at every line
    if (( $xcount %2 == 0 ))                                            # Modulo on line counter
       then BCOL="#FFFFE0" ; FCOL="#000000"                             # LightYellow Pair color
       else BCOL="#FAF0E6" ; FCOL="#000000"                             # Linen Impair color
    fi    

    echo -e "<tr>"  >> $HTML_SFILE
    echo -e "<td align=center bgcolor=$BCOL><font color=$FCOL>$xcount</font></td>"     >>$HTML_SFILE

    # Execution Date
    epoch_now=`date "+%s"`                                              # Current Date in Epoch Time
    wdate=`echo "$RCH_DATE1" | sed 's/\./\//g'`                         # Replace dot by '/' in date
    script_epoch=`date -d "$wdate" "+%s"`                               # Script Date in Epoch Time
    diff=$(($epoch_now - $script_epoch))                                # Nb. Seconds between
    days=$(($diff/(60*60*24)))                                          # Convert Sec. to Days
    if [ $days -eq 0 ]                                                  # Script was ran today
        then echo -n "<td title='Script ran today.' " >>$HTML_SFILE     # Insert tooltips
        else echo -n "<td title='Script ran $days day(s) ago, warning is set to ${SCRIPT_MAX_AGE} days.' " >>$HTML_SFILE  
    fi 
    if [ $days -ge $SCRIPT_MAX_AGE ]                                    # Script Age > Max Age
        then echo -n " align=center bgcolor='Yellow'>" >>$HTML_SFILE    # Show in Yellow
        else echo -n " align=center bgcolor=$BCOL>"    >>$HTML_SFILE    # Else Normal Color
    fi
    echo "<font color=$FCOL>$RCH_DATE1</font></td>"    >>$HTML_SFILE    # Script date

    # Script Ending Status
    SAVCOL=$BCOL                                                        # Save Current Back Color    
    WSTATUS="CODE $RCH_RCODE"                                           # Invalid RCH Code Desc
    if [ "$RCH_RCODE" = "0" ] ; then WSTATUS="Success" ; fi             # Code 0 = Success
    if [ "$RCH_RCODE" = "1" ] ; then WSTATUS="Error  " ; BCOL='Yellow' ; fi  # Code 1 = Error
    if [ "$RCH_RCODE" = "2" ] ; then WSTATUS="Running" ; BCOL='Yellow' ; fi  # Code 2 = Running 
    if [ "$WSTATUS" != "Success" ]
       then echo "<td align=center bgcolor='Yellow'><font color=$FCOL>$WSTATUS</font></td>" >>$HTML_SFILE
       else echo "<td align=center bgcolor=$BCOL><font color=$FCOL>$WSTATUS</font></td>"    >>$HTML_SFILE
    fi 
    BCOL=$SAVCOL                                                        # Restore Std Back color
    
    # Server Name
    echo  "<td align=center bgcolor=$BCOL><font color=$FCOL>$RCH_SERVER</font></td>" >>$HTML_SFILE

    # Insert Name of the Script with link to log if log is accessible
    echo -n "<td align=center bgcolor=$BCOL><font color=$FCOL>" >> $HTML_SFILE
    LOGFILE="${RCH_SERVER}_${RCH_SCRIPT}.log"                           # Assemble log Script Name
    LOGNAME="${SADM_WWW_DAT_DIR}/${RCH_SERVER}/log/${LOGFILE}"          # Add Dir. Path to Name
    LOGURL="http://sadmin.${SADM_DOMAIN}/${URL_VIEW_FILE}?filename=${LOGNAME}" # Url to View Log
    if [ -r "$LOGNAME" ]                                                # If log is Readable
        then echo -n "<a href='$LOGURL' "              >> $HTML_SFILE   # Link to Access the Log
             echo -n "title='View Script Log File'>"   >> $HTML_SFILE   # ToolTip to Show User
             echo "$RCH_SCRIPT</font></a></td>"        >> $HTML_SFILE   # End of Link Definition
        else echo "$RCH_SCRIPT</font></td>"            >> $HTML_SFILE   # No Log = No LInk
    fi

    # Start Time
    echo -e "<td align=center bgcolor=$BCOL><font color=$FCOL>$RCH_TIME1</font></td>"  >>$HTML_SFILE

    # End Time
    if [ "$RCH_TIME2" = "........" ] ; then RCH_TIME2="Running" ; fi    # Replace Dot with Running
    echo -e "<td align=center bgcolor=$BCOL><font color=$FCOL>$RCH_TIME2</font></td>"  >>$HTML_SFILE
    
    # Elapse Time
    if [ "$RCH_ELAPSE" = "........" ] ; then RCH_ELAPSE="Running" ; fi  # Replace Dot with Running
    echo -e "<td align=center bgcolor=$BCOL><font color=$FCOL>$RCH_ELAPSE</font></td>" >>$HTML_SFILE
    
    # Alert Type ( 0=None 1=AlertOnError 2=AlertOnOK 3=Always)
    SAVCOL=$FCOL                                                        # Save Current Line Color
    SAVBCOL=$BCOL
    case "$RCH_TYPE" in                                                 # When or Not to alert Code
        0 ) FCOL='Red' ; BCOL='Yellow' 
            ALERT_TYPE="Never Alert"                                    # Never Send an Alert 
            echo -n "<td align=center bgcolor=$BCOL>"  >>$HTML_SFILE
            echo -e "<strong><font color=$FCOL>$ALERT_TYPE</font></strong></td>" >>$HTML_SFILE
            ;; 
        1 ) ALERT_TYPE="Alert on Error"                                 # If Script ended with Error
            echo -n "<td align=center bgcolor=$BCOL>"  >>$HTML_SFILE
            echo -e "<font color=$FCOL>$ALERT_TYPE</font></td>" >>$HTML_SFILE
            ;; 
        2 ) ALERT_TYPE="Alert on Success"                               # Script ended with success
            FCOL='Blue' ; BCOL='Yellow'
            echo -n "<td align=center bgcolor=$BCOL>"  >>$HTML_SFILE
            echo -e "<strong><font color=$FCOL>$ALERT_TYPE</font></strong></td>" >>$HTML_SFILE
            ;; 
        3 ) FCOL='Blue'
            ALERT_TYPE="Always Alert"  ; BCOL='Yellow'                  # Alert on every execution
            echo -n "<td align=center bgcolor=$BCOL>"  >>$HTML_SFILE
            echo -e "<strong><font color=$FCOL>$ALERT_TYPE</font></strong></td>" >>$HTML_SFILE
            ;; 
        * ) FCOL='Red' ; BCOL='Yellow'
            ALERT_TYPE="Unknown $ $RCH_TYPE ?"                          # Alert Type is invalid
            echo -n "<td align=center bgcolor=$BCOL>"  >>$HTML_SFILE
            echo -e "<strong><font color=$FCOL>$ALERT_TYPE</font></strong></td>" >>$HTML_SFILE
            ;; 
    esac
    #echo -e "<td align=center bgcolor=$BCOL><font color=$FCOL>$ALERT_TYPE</font></td>" >>$HTML_SFILE
    FCOL=$SAVCOL                                                        # Restore Std Line color
    BCOL=$SAVBCOL                                                       # Restore Background color

    # Alert Group
    GRP_TYPE=$(grep -i "^$RCH_ALERT " $SADM_ALERT_FILE |awk '{print$2}' |tr -d ' ')
    GRP_NAME=$(grep -i "^$RCH_ALERT " $SADM_ALERT_FILE |awk '{print$3}' |tr -d ' ')
    case "$GRP_TYPE" in                                                 # Case on Default Alert Group
        m|M )   GRP_DESC="By Email"                                     # Alert Sent by Email
                ;; 
        s|S )   GRP_DESC="Slack $GRP_NAME" 
                ;; 
        c|C )   GRP_DESC="Cell. $GRP_NAME" 
                ;; 
        t|T )   GRP_DESC="SMS $GRP_NAME" 
                ;; 
        *   )   GRP_DESC="Grp. $GRP_TYPE ?"                             # Illegal Code Desc
                ;;
    esac
    echo -e "<td align=center bgcolor=$BCOL><font color=$FCOL>$GRP_DESC</font></td>"  >>$HTML_SFILE

    echo -e "</tr>\n" >> $HTML_SFILE
    return 
} 



# ==================================================================================================
# Mount the NFS Directory where all the ReaR backup files are stored 
# Produce a list of the latest backup for every systems.
# ==================================================================================================
rear_report() 
{
    rear_backup_error=0                                                 # Set to 1 if error in func.
    if [ -f "$SADM_TMP_FILE2" ] ; then rm -f $SADM_TMP_FILE2 >/dev/null 2>&1 ; fi 
    if [ -f "$HTML_RFILE" ] ; then rm -f $HTML_RFILE >/dev/null 2>&1 ; fi 

    sadm_write "${BOLD}${YELLOW}Creating the ReaR Backup Report${NORMAL}\n"  

    # Put Rows you want in the select. 
    # See rows available in 'table_structure_server.pdf' in $SADMIN/doc/database_info directory
    SQL="SELECT srv_name,srv_desc,srv_ostype,srv_domain,srv_monitor,srv_sporadic,srv_active" 
    SQL="${SQL},srv_sadmin_dir,srv_backup,srv_img_backup,srv_arch,srv_rear_ver "

    # Build SQL to select active server(s) from Database.
    SQL="${SQL} from server"                                            # From the Server Table
    SQL="${SQL} where srv_ostype = 'linux'"                             # ReaR Avail. Only on Linux
    #SQL="${SQL} where srv_ostype = 'linux' and srv_active = True and srv_img_backup = True "   
    SQL="${SQL} order by srv_name; "                                    # Order Output by ServerName
    
    # Execute SQL Query to Create CSV in SADM Temporary work file ($SADM_TMP_FILE1)
    CMDLINE="$SADM_MYSQL -u $SADM_RO_DBUSER  -p$SADM_RO_DBPWD "         # MySQL Auth/Read Only User
    #if [ $SADM_DEBUG -gt 5 ] ; then sadm_write "${CMDLINE}\n" ; fi      # Debug Show Auth cmdline
    $CMDLINE -h $SADM_DBHOST $SADM_DBNAME -Ne "$SQL" | tr '/\t/' '/;/' >$SADM_TMP_FILE1
    if [ ! -s "$SADM_TMP_FILE1" ] || [ ! -r "$SADM_TMP_FILE1" ]         # File not readable or 0 len
        then sadm_write "$SADM_WARNING No Active Server were found.\n"  # Not Active Server MSG
             return 0                                                   # Return Status to Caller
    fi 

    # Exclude the servers specify in sadmin.cfg from the report
    for server in $SERVERS                                              # For All in Exclude List
    	do 
        grep -iq "^${server};" $SADM_TMP_FILE1
        if [ $? -eq 0 ]                                                 # Server in Exclude List 
            then grep -iv "^$server" $SADM_TMP_FILE1 > $SADM_TMP_FILE2  # Remove it from file
                 mv $SADM_TMP_FILE2 $SADM_TMP_FILE1                     # Copy work to Server List
    	fi
	done
    chmod 664 $SADM_TMP_FILE1                                           # So everybody can read it.

    # Mount NFS Rear Backup Directory
    NFSMOUNT="${SADM_REAR_NFS_SERVER}:${SADM_REAR_NFS_MOUNT_POINT}"     # Remote NFS Mount Point
    mount_nfs "$NFSMOUNT"                                               # Go and Mount NFS Dir.
    if [ $? -ne 0 ] ; then return 1 ; fi                                # Can't Mount back to caller
    
    # Produce the report heading
    rear_heading "SADMIN ReaR Backup Report - `date '+%a %C%y.%m.%d %H:%M:%S'`" "$HTML_RFILE"  

    xcount=0                                                            # Set Server & Error Counter
    while read wline                                                    # Read Tmp file Line by Line
        do
        server_name=$(echo $wline      |awk -F\; '{print $1}')          # Extract Server Name
        server_desc=$(echo $wline      |awk -F\; '{print $2}')          # Extract Server Description
        server_os=$(echo $wline        |awk -F\; '{print $3}')          # O/S (linux/aix/darwin)
        server_domain=$(echo $wline    |awk -F\; '{print $4}')          # Extract Domain of Server
        server_monitor=$(echo $wline   |awk -F\; '{print $5}')          # Monitor  1=True 0=False
        server_sporadic=$(echo $wline  |awk -F\; '{print $6}')          # Sporadic 1=True 0=False
        server_active=$(echo $wline    |awk -F\; '{print $7}')          # Active   1=Yes  0=No
        server_rootdir=$(echo $wline   |awk -F\; '{print $8}')          # Client SADMIN Root Dir.
        server_backup=$(echo $wline    |awk -F\; '{print $9}')          # Backup Schd 1=True 0=False
        server_img_backup=$(echo $wline|awk -F\; '{print $10}')         # ReaR Sched. 1=True 0=False
        server_arch=$(      echo $wline|awk -F\; '{print $11}')         # Server Architecture
        server_rear_ver=$(  echo $wline|awk -F\; '{print $12}')         # ReaR Server Version
        fqdn_server=`echo ${server_name}.${server_domain}`              # Create FQDN Server Name

        # ReaR Backup only Supported under these Architecture
        if [ "$server_arch" != "x86_64" ] && [ "$server_arch" != "i686" ] && 
           [ "$server_arch" != "i386" ]
           then continue
        fi 
        #
        if [ "$SADM_DEBUG" -gt 4 ]                                      # If Debug Show System name
           then sadm_write "\n"                                         # Space line
                sadm_write "Processing ${server_name}.\n"               # Server Name
        fi 
        #

        # Calculate Today ($CUR_TOTAL) and Yesterday ($PRV_TOTAL) Backup Size in MB
        CUR_TOTAL=0                                                     # Reset Today Backup Size 
        PRV_TOTAL=0                                                     # Reset Previous Backup Size
        if [ -d ${LOCAL_MOUNT}/${server_name} ]                         # If Server Backup Dir Exist
           then cd ${LOCAL_MOUNT}/${server_name}                        # CD into Backup Dir.
                rear_file="${LOCAL_MOUNT}/${server_name}/rear_${server_name}.tar.gz" 
                if [ -s $rear_file ] 
                   then TSIZE=$(stat --format=%s $rear_file)
                        CUR_TOTAL=$(echo "$TSIZE /1024/1024" | bc)      # Convert Backup Size in MB
                   else CUR_TOTAL=0
                fi 
                rear_file2=$(ls -1tr *.tar.gz | tail -2 | head -1)
                if [ -s $rear_file2 ] 
                   then TSIZE=$(stat --format=%s $rear_file2)
                        PRV_TOTAL=$(echo "$TSIZE /1024/1024" | bc)      # Convert Backup Size in MB
                   else PRV_TOTAL=0
                fi 
        fi

        # Get the last line of the backup RCH file for the system.
        RCH_FILE="${SADM_WWW_DAT_DIR}/${server_name}/rch/${server_name}_${rear_script_name}.rch"
        if [ -s $RCH_FILE ]                                             # If System Backup RCH Exist
            then RCH_LINE=$(tail -3 $RCH_FILE | sort | tail -1)         # Get last line in RCH File
            else #echo "RCH file ${RCH_FILE} not found or is empty."    # Advise user no RCH File
                 start_end="---------- -------- ---------- -------- --------" # Start/End Date/Time
                 RCH_LINE="${server_name} ${start_end} ${rear_script_name} default 1 3" 
        fi 

        # The RCH line should have 10 ($FIELD_IN_RCH) fields, if not set error to 1 & advise user.
        NBFIELD=`echo $RCH_LINE | awk '{ print NF }'`                   # How many fields on line ?
        if [ "${NBFIELD}" != "${FIELD_IN_RCH}" ]                        # If abnormal nb. of field
           then sadm_write "Format error in this RCH file : ${RCH_FILE}\n"
                sadm_write "Line below have ${NBFIELD} but it should have ${FIELD_IN_RCH}.\n"
                sadm_write "The backup for this server is skipped: ${RCH_LINE}\n"
                sadm_write "\n"
                rear_backup_error=1                                          # Func. Return Code now at 1
                continue 
        fi        
        if [ $SADM_DEBUG -gt 5 ] 
            then printf "The RCH Filename of ${server_name} backup of is ${RCH_FILE}\n"
                 printf "The last Line in the file is : ${RCH_LINE}\n"
        fi 

        # Split the RCH Line 
        WSERVER=`echo -e $RCH_LINE | awk '{ print $1 }'`                # Extract Server Name
        WDATE1=` echo -e $RCH_LINE | awk '{ print $2 }'`                # Extract Date Started
        WTIME1=` echo -e $RCH_LINE | awk '{ print $3 }'`                # Extract Time Started
        WDATE2=` echo -e $RCH_LINE | awk '{ print $4 }'`                # Extract Date Started
        WTIME2=` echo -e $RCH_LINE | awk '{ print $5 }'`                # Extract Time Ended
        WELAPSE=`echo -e $RCH_LINE | awk '{ print $6 }'`                # Extract Time Ended
        WSCRIPT=`echo -e $RCH_LINE | awk '{ print $7 }'`                # Extract Script Name
        WALERT=` echo -e $RCH_LINE | awk '{ print $8 }'`                # Extract Alert Group Name
        WTYPE=`  echo -e $RCH_LINE | awk '{ print $9 }'`                # Extract Alert Group Type
        WRCODE=` echo -e $RCH_LINE | awk '{ print $10 }'`               # Extract Return Code 

        # Set the backup Status Description
        case "$WRCODE" in                                               # Case on RCH Return Code
            0 ) WSTATUS="Success" 
                ;; 
            1 ) WSTATUS="Failed"
                ;;
            2 ) WSTATUS="Running"
                ;;
            3 ) WSTATUS="No Backup"
                ;;
            * ) WRDESC="CODE $WRCODE ?"                                 # Illegal Code  Desc
                ;;                                                          
        esac
        
        # Build backup line to be written to work file (Will be sorted later)
        BLINE="${WDATE1};${WTIME1};${WELAPSE};${WSTATUS};${server_name}" 
        BLINE="${BLINE};${server_desc};${server_img_backup}"
        BLINE="${BLINE};${CUR_TOTAL};${PRV_TOTAL};${server_sporadic};${server_rear_ver}" 
        echo "$BLINE" >> $SADM_TMP_FILE2                                # Write Info to work file
        done < $SADM_TMP_FILE1

    # Umount NFS Mount point, Sort the Work File (By Date/Time) then produce report it HTML format.
    unmount_nfs                                                         # UnMount NFS Backup Dir.
    sort $SADM_TMP_FILE2 > $SADM_TMP_FILE1                              # Sort Tmp file by Date/Time
    while read wline                                                    # Read Tmp file Line by Line
        do
        xcount=$(($xcount+1))                                           # Increase Line Counter
        rear_line "${wline};${xcount};$HTML_RFILE;R"                    # Insert line in HTML Page
        done < $SADM_TMP_FILE1                                          # Read Sorted file

    echo -e "</table>\n" >> $HTML_RFILE                                 # End of rear section
    rear_legend                                                         # Add Legend at page bottom
    echo -e "</body>\n</html>" >> $HTML_RFILE                           # End of ReaR Page

    # Set Report by Email to SADMIN Administrator
    subject="SADMIN ReaR Backup Report"                                 # Send Backup Report by mail
    export EMAIL="$SADM_MAIL_ADDR"                                      # Set the FROM Email 
    if [ "$WKHTMLTOPDF" != "" ]                                         # If wkhtmltopdf on System
        then $WKHTMLTOPDF -O landscape $HTML_RFILE $PDF_RFILE > /dev/null 2>&1 # Convert HTML to PDF
             mutt -e 'set content_type=text/html' -s "$subject" $SADM_MAIL_ADDR -a $PDF_RFILE < $HTML_RFILE
             SADM_EXIT_CODE=$?                                          # Save mutt return Code.
        else mutt -e 'set content_type=text/html' -s "$subject" $SADM_MAIL_ADDR < $HTML_RFILE
             SADM_EXIT_CODE=$?                                          # Save mutt return Code.
    fi 
    if [ $SADM_EXIT_CODE -eq 0 ]                                        # If mail sent successfully
        then sadm_writelog "${SADM_OK} ReaR Backup Report sent to $SADM_MAIL_ADDR"      
        else sadm_writelog "${SADM_ERROR} Failed to send the ReaR Backup Report to $SADM_MAIL_ADDR"
    fi

    sadm_write "${BOLD}${YELLOW}End of the ReaR Backup Report ...${NORMAL}\n" 
    sadm_write "\n"

    return $rear_backup_error                                          # Return Err Count to caller
}



#===================================================================================================
# Rear Report Heading
#===================================================================================================
rear_heading()
{
    RTITLE=$1                                                           # Report Title
    HTML=$2                                                             # HTML Report File Name

    echo -e "<!DOCTYPE html><html>" > $HTML
    echo -e "<head>" >> $HTML
    echo -e "\n<meta charset='utf-8' />"            >> $HTML
    #
    echo -e "\n<style>" >> $HTML
    echo -e "th { color: white; background-color: #0000ff; padding: 0px; }" >> $HTML
    echo -e "td { color: white; border-bottom: 1px solid #ddd; padding: 5px; }" >> $HTML
    echo -e "tr:nth-child(odd)  { background-color: #F5F5F5; }" >> $HTML
    echo -e "table, th, td { border: 1px solid black; border-collapse: collapse; }" >> $HTML
    echo -e "div.fs150   { font-size: 150%; }"                  >> $HTML
    echo -e "div.fs13px  { text-align: left; font-size: 13px; }"                  >> $HTML
    echo -e "\n/* Dashed red border */" >> $HTML
    echo -e "hr.dash        { border-top: 1px dashed red; }" >> $HTML
    echo -e "/* Large rounded green border */" >> $HTML
    echo -e "hr.large_green { border: 3px solid green; border-radius: 5px; }" >> $HTML
    echo -e "p.report_title {" >> $HTML
    echo -e "   font-family:Helvetica,Arial;color:blue;font-size:25px;font-weight:bold;" >> $HTML
    echo -e "}" >> $HTML    
    echo -e "</style>" >> $HTML
    echo -e "\n<title>$RTITLE</title>" >> $HTML
    echo -e "</head>\n" >> $HTML
    echo -e "<body>" >> $HTML
    
    echo -e "<center>" >> $HTML                                         # Center what's coming
    echo -e "<p class='report_title'>${RTITLE}</p>" >> $HTML            # Report Title    
    URL_SCRIPTS_REPORT="/view/daily_rear_report.html"                   # Scripts Daily Report Page
    RURL="http://sadmin.${SADM_DOMAIN}/${URL_SCRIPTS_REPORT}"           # Full URL to HTML report 
    TITLE2="View the web version of this report"                        # Link Description
    echo -e "</center>" >> $HTML                                        # End Text Center
    echo -e "<div class='fs13px'><a href='${RURL}'>${TITLE2}</a></div>" >>$HTML # Insert Link on Page
    echo -e "\n<hr class="large_green">\n<br>"              >> $HTML    # Big Horizontal Green Line

    echo -e "\n<center><table border=0>" >> $HTML
    echo -e "\n<thead>" >> $HTML
    echo -e "<tr>" >> $HTML
    echo -e "<th colspan=1 dt-head-center></th>" >> $HTML
    echo -e "<th colspan=4 align=center>Last Backup</th>" >> $HTML
    echo -e "<th align=center>Schedule</th>" >> $HTML
    echo -e "<th colspan=2></th>" >> $HTML
    echo -e "<th align=center>Rear</th>" >> $HTML
    echo -e "<th align=center>Sporadic</th>" >> $HTML
    echo -e "<th align=center>Current</th>" >> $HTML
    echo -e "<th align=center>Previous</th>" >> $HTML
    echo -e "</tr>" >> $HTML
    #
    echo -e "<tr>" >> $HTML
    echo -e "<th align=center>No</th>" >> $HTML
    echo -e "<th align=center>Date</th>" >> $HTML
    echo -e "<th align=center>Time</th>" >> $HTML
    echo -e "<th align=center>Elapse</th>" >> $HTML
    echo -e "<th align=center>Status</th>"  >> $HTML
    echo -e "<th align=left>Activated</th>" >> $HTML
    echo -e "<th align=center>System</th>" >> $HTML
    echo -e "<th align=left>Description</th>" >> $HTML    
    echo -e "<th align=center>Version</th>" >> $HTML    
    echo -e "<th align=center>System</th>" >> $HTML
    echo -e "<th align=center>Size</th>" >> $HTML
    echo -e "<th align=center>Size</th>" >> $HTML
    echo -e "</tr>" >> $HTML
    #
    echo -e "</thead>\n" >> $HTML
    return 0
}


#===================================================================================================
# Add the receiving line into the ReaR Backup report page
#===================================================================================================
rear_line()
{
    # Extract fields from parameters received.
    BACKUP_INFO=$*                                                       # Comma Sep. Info Line
    WDATE1=$(     echo $BACKUP_INFO | awk -F\; '{ print $1 }')           # Backup Script RCH Line
    WTIME1=$(     echo $BACKUP_INFO | awk -F\; '{ print $2 }')           # DB System Description
    WELAPSE=$(    echo $BACKUP_INFO | awk -F\; '{ print $3 }')           # DB System Description
    WSTATUS=$(    echo $BACKUP_INFO | awk -F\; '{ print $4 }')           # DB System Description
    WSERVER=$(    echo $BACKUP_INFO | awk -F\; '{ print $5 }')           # DB System Description
    WDESC=$(      echo $BACKUP_INFO | awk -F\; '{ print $6 }')           # DB System Description
    WACT=$(       echo $BACKUP_INFO | awk -F\; '{ print $7 }')           # DB System Description
    WCUR_TOTAL=$( echo $BACKUP_INFO | awk -F\; '{ print $8 }')           # Current Backup Total MB
    WPRV_TOTAL=$( echo $BACKUP_INFO | awk -F\; '{ print $9 }')           # Yesterday Backup Total MB
    WSPORADIC=$(  echo $BACKUP_INFO | awk -F\; '{ print $10 }')          # Sporadic Server=1 else=0
    WREARVER=$(   echo $BACKUP_INFO | awk -F\; '{ print $11 }')          # Rear Version Number
    WCOUNT=$(     echo $BACKUP_INFO | awk -F\; '{ print $12 }')          # Line Counter
    HTML=$(       echo $BACKUP_INFO | awk -F\; '{ print $13 }')          # HTML Output File Name
    RTYPE=$(      echo $BACKUP_INFO | awk -F\; '{ print $14 }')          # R=RearBackup B=DailyBackup

    # Alternate background color at every line
    if (( $WCOUNT %2 == 0 ))                                            # Modulo on line counter
       then BCOL="#00FFFF" ; FCOL="#000000"                             # Pair count color
       else BCOL="#F0FFFF" ; FCOL="#000000"                             # Impar line color
    fi

    # Beginning to Insert Line in HTML Table
    echo -e "<tr>"  >> $HTML                                            # Begin backup line
    echo -e "<td align=center bgcolor=$BCOL><font color=$FCOL>$WCOUNT</font></td>"  >> $HTML

    # Calculate number of days between now and the backup date
    backup_date=`echo "$WDATE1" | sed 's/\./\//g'`                      # Replace dot by '/' in date
    epoch_backup=`date -d "$backup_date" "+%s"`                         # Backup Date in Epoch Time
    epoch_now=`date "+%s"`                                              # Today in Epoch Time
    diff=$(($epoch_now - $epoch_backup))                                # Nb. Seconds between
    days=$(($diff/(60*60*24)))                                          # Convert Sec. to Days

    # ReaR Backup Date 
    if [ "$TODAY" = "$WDATE1" ]                                         # Backup done today
       then echo -n "<td title='Rear Image was done today'" >>$HTML     # Tooltip 
            echo " align=center bgcolor=$BCOL><font color=$FCOL>$WDATE1</font></td>" >>$HTML
            #echo "<font color=$FCOL>$WDATE1</font></td>" >>$HTML        # Show Backup Date
       else if [ "$WDATE1" = "----------" ]                             # Date=Dashes=No Backup Yet
               then echo -n "<td title='No ReaR backup recorded' " >>$HTML   
                    echo -n "align=center bgcolor='Yellow'>" >>$HTML
                    echo "<font color=$FCOL>$WDATE1</font></td>" >>$HTML        # Show Backup Date
               else echo -n "<td title='Backup was done $days days ago, warning at $REAR_INTERVAL days.'" >>$HTML  
                    if [ $days -gt $REAR_INTERVAL ]                     # RearBackupDate > WarnDays
                        then if [ $WACT -eq 0 ]                         # If Backup Disable
                                then echo -n "align=center bgcolor=$BCOL>" >>$HTML 
                                     echo "<font color=$FCOL><strong>$WDATE1</strong></font></td>" >>$HTML
                                else echo -n "align=center bgcolor='Yellow'>" >>$HTML 
                                     echo "<font color=$FCOL>$WDATE1</font></td>" >>$HTML
                             fi
                        else echo -n "align=center bgcolor=$BCOL>" >>$HTML 
                             echo "<font color=$FCOL>$WDATE1</font></td>" >>$HTML # Show Backup Date
                    fi 
            fi
    fi 

    # Backup Time & Elapse time
    echo "<td align=center bgcolor=$BCOL><font color=$FCOL>$WTIME1</font></td>"  >> $HTML
    echo "<td align=center bgcolor=$BCOL><font color=$FCOL>$WELAPSE</font></td>" >> $HTML
    #echo "<td align=center bgcolor=$BCOL><font color=$FCOL>$WSTATUS</font></td>" >> $HTML

    # Backup Status - (If you click on it it will show the backup script log.)
    if [ "$WSTATUS" = "Success" ]                                       # Not Success Backgrd Yellow 
        then echo -e "<td align=center bgcolor=$BCOL><font color=$FCOL>"    >> $HTML
        else echo -e "<td align=center bgcolor='Yellow'><font color=$FCOL>" >> $HTML
    fi 
    LOGFILE="${WSERVER}_${WSCRIPT}.log"                                 # Assemble log Script Name
    LOGNAME="${SADM_WWW_DAT_DIR}/${WSERVER}/log/${LOGFILE}"             # Add Dir. Path to Name
    LOGURL="http://sadmin.${SADM_DOMAIN}/${URL_VIEW_FILE}?filename=${LOGNAME}"  # Url to View Log
    if [ -r "$LOGNAME" ]                                                # If log is Readable
        then echo -n "<a href='$LOGURL 'title='View Backup Log File'>" >>$HTML
             echo "${WSTATUS}</font></a></td>" >>$HTML 
        else echo -e "${WSTATUS}</font></td>" >> $HTML                  # No Log = No LInk
    fi

    # Backup Schedule Status - Activated or Deactivated (show in Yellow background)
    URL_SCHED_UPDATE=$(echo "${URL_REAR_SCHED/SYSTEM/$WSERVER}") # URL To Modify Backup Schd
    if [ $WACT -eq 0 ]                                                  # If Backup Disable
       then echo "<td align=center bgcolor=$BCOL><font color=$FCOL>"         >>$HTML
            echo -n "<a href='http://sadmin.${SADM_DOMAIN}/$URL_SCHED_UPDATE "  >>$HTML
            echo "'title='Schedule Deactivated, click to modify'><strong>No</strong></font></a></td>" >>$HTML
       else echo "<td align=center bgcolor=$BCOL><font color=$FCOL>"            >>$HTML    
            echo -n "<a href='http://sadmin.${SADM_DOMAIN}/$URL_SCHED_UPDATE "  >>$HTML
            echo "'title='Click to modify Backup Schedule'>Yes</font></a></td>"          >>$HTML
    fi

    # Server Name, Descrition (From DB) and ReaR Version number.
    echo "<td align=center bgcolor=$BCOL><font color=$FCOL>$WSERVER</font></td>" >> $HTML
    echo "<td align=left bgcolor=$BCOL><font color=$FCOL>$WDESC</font></td>"     >> $HTML
    echo "<td align=center bgcolor=$BCOL><font color=$FCOL>$WREARVER</font></td>"  >> $HTML

    # Sporadic Server or Not 
    if [ "$WSPORADIC" =  "0" ] 
       then echo "<td align=center bgcolor=$BCOL><font color=$FCOL>No</font></td>"  >>$HTML
       else echo "<td align=center bgcolor=$BCOL><font color=$FCOL>Yes</font></td>" >>$HTML
    fi

    # CURRENT BACKUP SIZE - Show in Yellow if : 
    #   - Today Backup Size ($WCUR_TOTAL) is 0
    #   - Today Backup Size ($WCUR_TOTAL) vs Yesterday ($WPRV_TOTAL) is greater than threshold $WPCT
    #
    if [ $WCUR_TOTAL -eq 0 ]                                            # If Today Backup Size is 0
        then if [ $WACT -eq 0 ]                                         # If Backup Disable
                then echo -en "<td title='No Backup situation' align=center bgcolor=$BCOL>" >>$HTML
                     echo -e "<font color=$FCOL><strong>${WCUR_TOTAL} MB</strong></font></td>" >>$HTML
                else echo -en "<td title='No Backup situation' align=center bgcolor='Yellow'>" >>$HTML
                     echo -e "<font color=$FCOL>${WCUR_TOTAL} MB</font></td>" >> $HTML
             fi
        else if [ $WPRV_TOTAL -eq 0 ]                                   # If Yesterday Backup Size=0
                then echo -en "<td align=center bgcolor=$BCOL><font color=$FCOL>" >>$HTML
                     echo -e " ${WCUR_TOTAL} MB</font></td>" >>$HTML
                else if [ $WCUR_TOTAL -ge $WPRV_TOTAL ]                 # Today Backup >= Yesterday
                        then PCT=`echo "(($WCUR_TOTAL - $WPRV_TOTAL) / $WPRV_TOTAL) * 100" | bc -l`
                             PCT=$(printf "%.f" $PCT) 
                             if [ $PCT -ge $WPCT ]                      # Inc Greater than threshold
                                then echo -en "<td align=center bgcolor='Yellow' " >>$HTML
                                     echo "title='Backup is ${PCT}% bigger than yesterday'>" >>$HTML
                                     echo "<font color=$FCOL>${WCUR_TOTAL} MB</font></td>" >>$HTML
                                else echo -n "<td align=center bgcolor=$BCOL>" >>$HTML
                                     echo "<font color=$FCOL>${WCUR_TOTAL} MB</font></td>" >>$HTML
                             fi
                        else PCT=`echo "(($WPRV_TOTAL - $WCUR_TOTAL) / $WCUR_TOTAL) * 100" | bc -l`
                             #PCT=`echo "($WCUR_TOTAL / $WPRV_TOTAL) * 100" | bc -l` 
                             PCT=$(printf "%.f" $PCT)
                             if [ $PCT -ge $WPCT ] && [ $PCT -ne 0 ]         # Decr. less than threshold
                                then echo -n "<td title='Backup is ${PCT}% smaller than previous' " >>$HTML
                                     echo "align=center bgcolor='Yellow'> " >> $HTML
                                     echo "<font color=$FCOL>${WCUR_TOTAL} MB</font></td>" >>$HTML
                                else echo -n "<td align=center bgcolor=$BCOL>" >>$HTML
                                     echo "<font color=$FCOL>${WCUR_TOTAL} MB</font></td>" >>$HTML
                             fi
                     fi 
             fi 
    fi 


    # Yesterday Backup Size - If Size is 0, show it in Yellow.
    if [ $WPRV_TOTAL -eq 0 ]                                
        then echo -en "<td title='No Backup situation' align=center bgcolor='Yellow'>" >>$HTML
             echo -e "<font color=$FCOL>${WPRV_TOTAL} MB</font></td>" >> $HTML
        else echo -en "<td align=center bgcolor=$BCOL><font color=$FCOL> " >> $HTML
             echo -e " ${WPRV_TOTAL} MB</font></td>" >> $HTML
    fi 

    echo -e "</tr>\n" >> $HTML
    return 
} 



#===================================================================================================
# Add legend at the bottom of the ReaR report page
#===================================================================================================
rear_legend()
{
    echo -e "\n<br>\n<hr class="dash">\n" >> $HTML_RFILE                # Horizontal Dashed Line
    echo -e "\n\n<br><table cellspacing="0" cellpadding="0" border=0>\n"  >> $HTML_RFILE 
    BCOL="#ffffff"                                                      # Background color (White)
    FCOL="#000000"                                                      # Font Color (Black)

    echo -e "<tr>"  >> $HTML_RFILE                                      # Heading rows
    DATA="Column Name"
    echo -e "<th align=center colspan=8>$DATA</th>" >> $HTML_RFILE
    echo -e "<th align=center colspan=4>Column have a yellow background when ...</td>" >>$HTML_RFILE
    echo -e "</tr>"  >> $HTML_RFILE                                      # Begin Legend Row

    echo -e "<tr>"  >> $HTML_RFILE                                      # Begin Legend Row
    DATA="Last Backup Date"
    echo -e "<td align=left colspan=4 bgcolor=$BCOL><font color=$FCOL>$DATA</td>" >> $HTML_RFILE
    DATA="The backup date is older than $REAR_INTERVAL days or wasn't done."
    echo -e "<td align=left colspan=8 bgcolor=$BCOL><font color=$FCOL>$DATA</td>" >> $HTML_RFILE
    echo -e "</tr>"  >> $HTML_RFILE 

    echo -e "<tr>"  >> $HTML_RFILE                                      # Begin Legend Row
    DATA="Last Backup Status"
    echo -e "<td align=left colspan=4 bgcolor=$BCOL><font color=$FCOL>$DATA</td>" >> $HTML_RFILE
    DATA="The backup status is different than 'Success'."
    echo -e "<td align=left colspan=8 bgcolor=$BCOL><font color=$FCOL>$DATA</td>" >> $HTML_RFILE
    echo -e "</tr>"  >> $HTML_RFILE 

    echo -e "<tr>"  >> $HTML_RFILE                                      # Begin Legend Row
    DATA="Schedule Activated"
    echo -e "<td align=left colspan=4 bgcolor=$BCOL><font color=$FCOL>$DATA</td>" >> $HTML_RFILE
    DATA="The backup schedule is not activated."
    echo -e "<td align=left colspan=8 bgcolor=$BCOL><font color=$FCOL>$DATA</td>" >> $HTML_RFILE
    echo -e "</tr>"  >> $HTML_RFILE 

    echo -e "<tr>"  >> $HTML_RFILE                                      # Begin Legend Row
    DATA="Current Size"
    echo -e "<td align=left colspan=4 bgcolor=$BCOL><font color=$FCOL>$DATA</td>" >> $HTML_RFILE
    DATA="The backup size is zero or ${WPCT}% bigger or smaller than the previous backup."
    echo -e "<td align=left colspan=8 bgcolor=$BCOL><font color=$FCOL>$DATA</td>" >> $HTML_RFILE
    echo -e "</tr>"  >> $HTML_RFILE 

    echo -e "<tr>"  >> $HTML_RFILE                                      # Begin Legend Row
    DATA="Previous Size"
    echo -e "<td align=left colspan=4 bgcolor=$BCOL><font color=$FCOL>$DATA</td>" >> $HTML_RFILE
    DATA="The backup size is zero or ${WPCT}% bigger or smaller than the current backup."
    echo -e "<td align=left colspan=8 bgcolor=$BCOL><font color=$FCOL>$DATA</td>" >> $HTML_RFILE
    echo -e "</tr>"  >> $HTML_RFILE 

    echo -e "</table><br><br>\n" >> $HTML_RFILE                         # End of Legend Section
}




#===================================================================================================
# Produce the Storix Image Backup report and email it to the SADMIN Administrator.
#===================================================================================================
storix_report()
{
    storix_error=0                                                      # Set to 1 if error in func.
    if [ -f "$SADM_TMP_FILE2" ] ; then rm -f $SADM_TMP_FILE2 >/dev/null 2>&1 ; fi 
    if [ -f "$HTML_XFILE" ] ; then rm -f $HTML_XFILE >/dev/null 2>&1 ; fi     
    sadm_write "${BOLD}${YELLOW}Creating the Storix Daily Backup Report${NORMAL}\n" 

    # Put Rows you want in the select. 
    # See rows available in 'table_structure_server.pdf' in $SADMIN/doc/database_info directory
    SQL="SELECT srv_name,srv_desc,srv_ostype,srv_domain,srv_monitor,srv_sporadic,srv_active" 
    SQL="${SQL},srv_sadmin_dir,srv_backup,srv_img_backup,srv_arch "

    # Build SQL to select active server(s) from Database.
    SQL="${SQL} from server"                                            # From the Server Table
    SQL="${SQL} where srv_ostype = 'linux'"                             # ReaR Avail. Only on Linux
    SQL="${SQL} order by srv_name; "                                    # Order Output by ServerName
    
    # Execute SQL Query to Create CSV in SADM Temporary work file ($SADM_TMP_FILE1)
    CMDLINE="$SADM_MYSQL -u $SADM_RO_DBUSER  -p$SADM_RO_DBPWD "         # MySQL Auth/Read Only User
    $CMDLINE -h $SADM_DBHOST $SADM_DBNAME -Ne "$SQL" | tr '/\t/' '/;/' >$SADM_TMP_FILE1
    if [ ! -s "$SADM_TMP_FILE1" ] || [ ! -r "$SADM_TMP_FILE1" ]         # File not readable or 0 len
        then sadm_write "$SADM_WARNING No Active Server were found.\n"  # Not Active Server MSG
             return 0                                                   # Return Status to Caller
    fi 
    if [ "$SADM_DEBUG" -gt 4 ]                                          # If Debug Show SQL Results
       then sadm_writelog " "                                           # Space line
            sadm_writelog "Output of the SQL Query for producing the Backup Report."
            cat $SADM_TMP_FILE1 | while read wline ; do sadm_writelog "${wline}"; done
            sadm_writelog " "                                           # Space line
    fi

    # Mount NFS Storix Backup Location
    NFSMOUNT="${SADM_STORIX_NFS_SERVER}:${SADM_STORIX_NFS_MOUNT_POINT}" # Remote NFS Mount Point
    mount_nfs "$NFSMOUNT"                                               # Go and Mount NFS Dir.
    if [ $? -ne 0 ] ; then return 1 ; fi                                # Can't Mount back to caller

    # Exclude the servers to exclude specify in sadmin.cfg from the report
    for server in $SERVERS                                              # For All in Exclude List
    	do 
        grep -iq "^${server};" $SADM_TMP_FILE1
        if [ $? -eq 0 ]                                                 # Server in Exclude List 
            then grep -iv "^$server" $SADM_TMP_FILE1 > $SADM_TMP_FILE2  # Remove it from file
                 mv $SADM_TMP_FILE2 $SADM_TMP_FILE1                     # Copy work to Server List
    	fi
	    done
    chmod 664 $SADM_TMP_FILE1                                           # So everybody can read it.

    # Produce the report Heading
    storix_heading "SADMIN Storix Report - `date '+%a %C%y.%m.%d %H:%M:%S'`" # Produce Page Heading
    xcount=0                                                            # Set Server & Error Counter
    while read wline                                                    # Read Tmp file Line by Line
        do
        server_name=$(echo $wline      |awk -F\; '{print $1}')          # Extract Server Name
        server_desc=$(echo $wline      |awk -F\; '{print $2}')          # Extract Server Description
        server_os=$(echo $wline        |awk -F\; '{print $3}')          # O/S (linux/aix/darwin)
        server_domain=$(echo $wline    |awk -F\; '{print $4}')          # Extract Domain of Server
        server_monitor=$(echo $wline   |awk -F\; '{print $5}')          # Monitor  1=True 0=False
        server_sporadic=$(echo $wline  |awk -F\; '{print $6}')          # Sporadic 1=True 0=False
        server_active=$(echo $wline    |awk -F\; '{print $7}')          # Active   1=Yes  0=No
        server_rootdir=$(echo $wline   |awk -F\; '{print $8}')          # Client SADMIN Root Dir.
        server_backup=$(echo $wline    |awk -F\; '{print $9}')          # Backup Schd 1=True 0=False
        server_img_backup=$(echo $wline|awk -F\; '{print $10}')         # ReaR Sched. 1=True 0=False
        server_arch=$(      echo $wline|awk -F\; '{print $11}')         # Server Architecture        
        fqdn_server=`echo ${server_name}.${server_domain}`              # Create FQDN Server Name
        
        if [ "$SADM_DEBUG" -gt 4 ]                                      # If Debug Show System name
           then sadm_writelog "Handling ${server_name} ${server_arch}"  # Server Name & Architecture
        fi 
 
        # ReaR Backup only Supported under these Architecture
        if [ "$server_arch" != "x86_64" ] && [ "$server_arch" != "i686" ] && 
           [ "$server_arch" != "i386" ]
           then continue                                                # Storix run Intel Platform
        fi 

        # Get Information about Storix ISO 
        ISO_NAME="No ISO" ; ISO_SIZE=0 ; ISO_DATE="N/A" ; ISO_EPOCH=0   # Default if no ISO found
        if [ -d ${LOCAL_MOUNT}/${ISODIR} ]                              # If Server Backup Dir Exist
           then ls -l ${LOCAL_MOUNT}/${ISODIR}/*.iso | grep -i ${server_name} > /dev/null 2>&1
                if [ $? -eq 0 ]                                         # ISO exist for server ?
                   then ISO_NAME=$(ls -1 ${LOCAL_MOUNT}/${ISODIR}/*.iso | grep -i ${server_name} |head -1)
                        ISO_SIZE=$(stat  --format=%s ${ISO_NAME})
                        ISO_SIZE=$(echo "$ISO_SIZE /1024/1024" | bc)    # Convert Backup Size in MB
                        ISO_DATE=$(stat  --format=%y ${ISO_NAME} | awk '{print $1}')
                        ISO_EPOCH=$(stat --format=%Y ${ISO_NAME} | awk '{print $1}')
                   else sadm_writelog "${SADM_WARNING} - No ISO was found for system ${server_name}"
                fi 
           else sadm_writelog "${SADM_ERROR} - ISO Directory doesn't exist (${LOCAL_MOUNT}/${ISODIR})"
        fi
        if [ $SADM_DEBUG -gt 0 ] 
            then sadm_writelog "ISO_NAME=$ISO_NAME  SIZE=$ISO_SIZE  DATE=$ISO_DATE  EPOCH=$ISO_EPOCH"
        fi 
        
        # Check if at least one TOC file exist for the current server
        STTOT=0                                                         # Defaut Storix Backup Size
        SAVPWD=`pwd`                                                    # Save Current Working Dir.
        cd ${LOCAL_MOUNT}/${IMGDIR}                                     # Move into Image Directory
        ls -1tr SB*${server_name}*:TOC:* > /dev/null 2>&1               # At Least 1 TOC For System?
        if [ $? -ne 0 ]                                                 # Bo TOC = No Backup
           then sadm_writelog "${SADM_WARNING} - No Storix image found for system ${server_name}"
           else STTOC=$(ls -1tr SB*${server_name}*:TOC:* | tail -1)     # Get lastest TOC FileName
                ST_DATE=$(stat  --format=%y ${STTOC} |awk '{print $1}') # Get TOC Modifcation Date
                STSEQ=$(echo $STTOC | awk -F: '{print $5}')             # Get Backup ID Number
                bsize="${SADM_TMP_DIR}/daily_storix.size"               # WorkFile, Calc Backup Size
                rm -f $bsize > /dev/null 2>&1                           # Del. Size Work File
                find ${LOCAL_MOUNT}/${IMGDIR} -name "SB*" -exec ls -l {} \; |grep "${STSEQ}" >$bsize
                if [ -s $bsize ]                                        # Backup File Not Found or 0
                   then TOTAL=$(awk '{sum += $5} END {print sum}' $bsize)  # Add each file size 
                        STTOT=$(echo "$TOTAL /1024/1024" | bc)          # Convert Backup Size in MB
                fi 
        fi 
        cd ${SAVPWD}                                                    # Move out of NFS Directory

        # Get the last line of the backup RCH file for the system.
        RCH_FILE="${SADM_WWW_DAT_DIR}/${server_name}/rch/${server_name}_storix_client_post_job.rch"
        if [ -s $RCH_FILE ]                                             # If System Backup RCH Exist
            then RCH_LINE=$(tail -3 $RCH_FILE | sort | tail -1)         # Get last line in RCH File
            else #echo "RCH file ${RCH_FILE} not found or is empty."    # Advise user no RCH File
                 start_end="---------- -------- ---------- -------- --------" # Start/End Date/Time
                 RCH_LINE="${server_name} ${start_end} ${backup_script_name} default 1 3" 
        fi 

        # The RCH line should have 10 ($FIELD_IN_RCH) fields, if not set error to 1 & advise user.
        NBFIELD=`echo $RCH_LINE | awk '{ print NF }'`                   # How many fields on line ?
        if [ "${NBFIELD}" != "${FIELD_IN_RCH}" ]                        # If abnormal nb. of field
           then sadm_write "${SADM_ERROR} Format error in this RCH file : ${RCH_FILE}\n"
                sadm_write "Line below have ${NBFIELD} but it should have ${FIELD_IN_RCH}.\n"
                sadm_write "The backup for this server is skipped: ${RCH_LINE}\n"
                sadm_write "\n"
                storix_error=1                                          # Func. Return Code now at 1
                continue 
        fi        
        if [ $SADM_DEBUG -gt 5 ] 
            then printf "The RCH Filename of ${server_name} backup of is ${RCH_FILE}\n"
                 printf "The last Line in the file is : ${RCH_LINE}\n"
        fi 

        # Split the RCH Line 
        WSERVER=` echo -e $RCH_LINE | awk '{ print $1 }'`               # Extract Server Name
        WDATE1=`  echo -e $RCH_LINE | awk '{ print $2 }'`               # Extract Date Started
        WTIME1=`  echo -e $RCH_LINE | awk '{ print $3 }'`               # Extract Time Started
        WDATE2=`  echo -e $RCH_LINE | awk '{ print $4 }'`               # Extract Date Started
        WTIME2=`  echo -e $RCH_LINE | awk '{ print $5 }'`               # Extract Time Ended
        WELAPSE=` echo -e $RCH_LINE | awk '{ print $6 }'`               # Extract Time Ended
        WSCRIPT=` echo -e $RCH_LINE | awk '{ print $7 }'`               # Extract Script Name
        WALERT=`  echo -e $RCH_LINE | awk '{ print $8 }'`               # Extract Alert Group Name
        WTYPE=`   echo -e $RCH_LINE | awk '{ print $9 }'`               # Extract Alert Group Type
        WRCODE=`  echo -e $RCH_LINE | awk '{ print $10 }'`              # Extract Return Code 

        # Set the backup Status Description
        case "$WRCODE" in                                               # Case on RCH Return Code
            0 ) WSTATUS="Success" 
                ;; 
            1 ) WSTATUS="Failed"
                ;;
            2 ) WSTATUS="Running"
                ;;
            3 ) WSTATUS="No Backup"
                ;;
            * ) WRDESC="CODE $WRCODE ?"                                 # Illegal Code  Desc
                ;;                                                          
        esac
        
        # Build backup line to be written to work file (Will then be sorted later)
        BLINE="${WDATE1};${WTIME1};${WELAPSE};${WSTATUS};${server_name}" 
        BLINE="${BLINE};${server_desc};${server_backup};${STTOT};${ISO_SIZE}"
        BLINE="${BLINE};${server_sporadic};${ISO_DATE};${ST_DATE}"
        echo "${BLINE}" >> $SADM_TMP_FILE2                                # Write Info to work file
        done < $SADM_TMP_FILE1

    # Umount NFS Mount point, Sort the Work File (By Date/Time) then produce report it HTML format.
    unmount_nfs                                                         # UnMount NFS Backup Dir.
    sort $SADM_TMP_FILE2 > $SADM_TMP_FILE1                              # Sort Tmp file by Date/Time
    while read wline                                                    # Read Tmp file Line by Line
        do
        xcount=$(($xcount+1))                                           # Increase Line Counter
        storix_line "${wline};${xcount}"                                # Insert line in HTML Page
        done < $SADM_TMP_FILE1                                          # Read Sorted file
    echo -e "</table>\n" >> $HTML_XFILE                                 # End of storix section
    storix_legend                                                       # Add Legend at page bottom
    echo -e "</body>\n</html>" >> $HTML_XFILE                           # End of Storix Page

    # Set Report by Email to SADMIN Administrator
    subject="SADMIN Storix Report"                                      # Send Backup Report by mail
    export EMAIL="$SADM_MAIL_ADDR"                                      # Set the FROM Email 
    if [ "$WKHTMLTOPDF" != "" ]                                         # If wkhtmltopdf on System
        then $WKHTMLTOPDF -O landscape $HTML_XFILE $PDF_XFILE > /dev/null 2>&1 # Convert HTML to PDF
             mutt -e 'set content_type=text/html' -s "$subject" $SADM_MAIL_ADDR -a $PDF_XFILE < $HTML_XFILE
             SADM_EXIT_CODE=$?                                          # Save mutt return Code.
        else mutt -e 'set content_type=text/html' -s "$subject" $SADM_MAIL_ADDR < $HTML_XFILE
             SADM_EXIT_CODE=$?                                          # Save mutt return Code.
    fi 
    if [ $SADM_EXIT_CODE -eq 0 ]                                        # If mail sent successfully
        then sadm_writelog "${SADM_OK} Daily Backup Report sent to $SADM_MAIL_ADDR"      
        else sadm_writelog "${SADM_ERROR} Failed to send the Daily Backup Report to $SADM_MAIL_ADDR"
    fi

    # End of Storix Report
    sadm_write "${BOLD}${YELLOW}End of Daily Backup Report ...${NORMAL}\n"   
    sadm_write "\n"                                                     # White line in log & Screen
    return $SADM_EXIT_CODE                                              # Return Err Count to caller
}


#===================================================================================================
# Report Heading
#===================================================================================================
storix_heading()
{
    RTITLE=$1                                                           # Report Title

    echo -e "<!DOCTYPE html><html>" > $HTML_XFILE
    echo -e "<head>" >> $HTML_XFILE
    echo -e "\n<meta charset='utf-8' />" >> $HTML_XFILE
    #
    echo -e "\n<style>" >> $HTML_XFILE
    echo -e "th { color: white; background-color: #0000ff; padding: 0px; }" >> $HTML_XFILE
    echo -e "td { color: white; border-bottom: 1px solid #ddd; padding: 5px; }" >> $HTML_XFILE
    echo -e "tr:nth-child(odd)  { background-color: #F5F5F5; }" >> $HTML_XFILE
    echo -e "table, th, td { border: 1px solid black; border-collapse: collapse; }" >> $HTML_XFILE
    echo -e "div.fs150   { font-size: 150%; }"                  >> $HTML_XFILE
    echo -e "div.fs13px  { text-align: left; font-size: 13px; }"                  >> $HTML_XFILE
    echo -e "\n/* Dashed red border */" >> $HTML_XFILE
    echo -e "hr.dash        { border-top: 1px dashed red; }" >> $HTML_XFILE
    echo -e "/* Large rounded green border */" >> $HTML_XFILE
    echo -e "hr.large_green { border: 3px solid green; border-radius: 5px; }" >> $HTML_XFILE
    echo -e "p.report_title {" >> $HTML_XFILE
    echo -e "   font-family:Helvetica,Arial;color:blue;font-size:25px;font-weight:bold;" >> $HTML_XFILE
    echo -e "}" >> $HTML_XFILE
    echo -e "</style>" >> $HTML_XFILE
    #
    echo -e "\n<title>$RTITLE</title>" >> $HTML_XFILE
    echo -e "</head>\n" >> $HTML_XFILE
    echo -e "<body>" >> $HTML_XFILE

    echo -e "<center>" >> $HTML_XFILE                                   # Center what's coming
    echo -e "<p class='report_title'>${RTITLE}</p>" >> $HTML_XFILE      # Report Title
    URL_SCRIPTS_REPORT="/view/daily_storix_report.html"                 # Scripts Daily Report Page
    RURL="http://sadmin.${SADM_DOMAIN}/${URL_SCRIPTS_REPORT}"           # Full URL to HTML report 
    TITLE2="View the web version of this report"                        # Link Description
    echo -e "</center>" >> $HTML_XFILE                                  # End Text Center
    echo -e "<div class='fs13px'><a href='${RURL}'>${TITLE2}</a></div>" >>$HTML_XFILE    # Insert Link on Page
    echo -e "\n<hr class="large_green">\n"              >> $HTML_XFILE
    echo -e "\n<center><table border=0>" >> $HTML_XFILE
    #
    echo -e "\n<thead>" >> $HTML_XFILE
    echo -e "<tr>" >> $HTML_XFILE
    echo -e "<th colspan=1 dt-head-center></th>" >> $HTML_XFILE
    echo -e "<th colspan=4 align=center>Last Backup Execution</th>" >> $HTML_XFILE
    echo -e "<th colspan=2></th>" >> $HTML_XFILE
    echo -e "<th align=center>System</th>" >> $HTML_XFILE
    echo -e "<th align=center>Backup</th>" >> $HTML_XFILE
    echo -e "<th align=center>Backup</th>" >> $HTML_XFILE
    echo -e "<th align=center>ISO</th>" >> $HTML_XFILE
    echo -e "<th align=center>ISO</th>" >> $HTML_XFILE
    echo -e "</tr>" >> $HTML_XFILE
    #
    echo -e "<tr>" >> $HTML_XFILE
    echo -e "<th align=center>No</th>" >> $HTML_XFILE
    echo -e "<th align=center>Date</th>" >> $HTML_XFILE
    echo -e "<th align=center>Time</th>" >> $HTML_XFILE
    echo -e "<th align=center>Elapse</th>" >> $HTML_XFILE
    echo -e "<th align=center>Status</th>"  >> $HTML_XFILE
    echo -e "<th align=center>System</th>" >> $HTML_XFILE
    echo -e "<th align=left>Description</th>" >> $HTML_XFILE    
    echo -e "<th align=left>Sporadic</th>" >> $HTML_XFILE
    echo -e "<th align=center>Date</th>" >> $HTML_XFILE
    echo -e "<th align=center>Size</th>" >> $HTML_XFILE
    echo -e "<th align=center>Date</th>" >> $HTML_XFILE
    echo -e "<th align=center>Size</th>" >> $HTML_XFILE
    echo -e "</tr>" >> $HTML_XFILE
    echo -e "</thead>\n" >> $HTML_XFILE
    return 0
}


#===================================================================================================
# Add the receiving line into the Storix report page
#===================================================================================================
storix_line()
{
    # Extract fields from parameters received.
    BACKUP_INFO=$*                                                      # Comma Sep. Info Line
    WDATE1=$(      echo $BACKUP_INFO | awk -F\; '{ print $1 }')         # Most Recent Backup Date
    WTIME1=$(      echo $BACKUP_INFO | awk -F\; '{ print $2 }')         # Most Recent Backup Time
    WELAPSE=$(     echo $BACKUP_INFO | awk -F\; '{ print $3 }')         # Recent Backup Elapse Time
    WSTATUS=$(     echo $BACKUP_INFO | awk -F\; '{ print $4 }')         # Storix Backup Status
    WSERVER=$(     echo $BACKUP_INFO | awk -F\; '{ print $5 }')         # Server System Name
    WDESC=$(       echo $BACKUP_INFO | awk -F\; '{ print $6 }')         # Server System Description
    WACT=$(        echo $BACKUP_INFO | awk -F\; '{ print $7 }')         # DB System Description
    BACKUP_SIZE=$( echo $BACKUP_INFO | awk -F\; '{ print $8 }')         # Current Backup Total MB
    ISO_SIZE=$(    echo $BACKUP_INFO | awk -F\; '{ print $9 }')         # ISO Size MB
    WSPORADIC=$(   echo $BACKUP_INFO | awk -F\; '{ print $10 }')        # Sporadic Server=1 else=0
    ISO_DATE=$(    echo $BACKUP_INFO | awk -F\; '{ print $11 }')        # Date ISO was created
    ST_DATE=$(     echo $BACKUP_INFO | awk -F\; '{ print $12 }')        # Date of Storix TOC File
    WCOUNT=$(      echo $BACKUP_INFO | awk -F\; '{ print $13 }')        # Line Counter

    # Alternate background color at every line
    if (( $WCOUNT %2 == 0 ))                                            # Modulo on line counter
       then BCOL="#00FFFF" ; FCOL="#000000"                             # Pair count color
       else BCOL="#F0FFFF" ; FCOL="#000000"                             # Impair line color
    fi

    # Beginning to Insert Line in HTML_XFILE Table
    echo -e "<tr>"  >> $HTML_XFILE                                      # Begin backup line
    echo -e "<td align=center bgcolor=$BCOL><font color=$FCOL>$WCOUNT</font></td>"  >> $HTML_XFILE

    # Backup older than $STWARN = yellow background & tooltips indicate nb days elapse since backup
    ebackup_date=`echo "$WDATE1" | sed 's/\./\//g'`                     # Replace dot by '/' in date
    backup_date=`echo "$WDATE1" | sed 's/\./-/g'`                       # Replace dot by '-' in date
    epoch_backup=`date -d "$ebackup_date" "+%s"`                        # Backup Date in Epoch Time
    epoch_now=`date "+%s"`                                              # Today in Epoch Time
    diff=$(($epoch_now - $epoch_backup))                                # Nb. Seconds between
    days=$(($diff/(60*60*24)))                                          # Convert Sec. to Days
    if [ $days -gt $STWARN ]                                            # Backup taken too far away
       then echo -n "<td title='Storix backup done $days days ago, warning at $STWARN days.' " >>$HTML_XFILE 
            echo -n "align=center bgcolor='Yellow'>" >>$HTML_XFILE      # Yellow Background
            echo "<font color=$FCOL>$backup_date</font></td>" >>$HTML_XFILE
       else if [ "$backup_date" != "$ST_DATE" ] ||  [ "$backup_date" != "$ISO_DATE" ] 
               then echo -n "<td title='Storix backup date different than ISO or image date' " >>$HTML_XFILE 
                    echo -n "align=center bgcolor='Yellow'>" >>$HTML_XFILE      # Yellow Background
                    echo "<font color=$FCOL>$backup_date</font></td>" >>$HTML_XFILE  # Show Backup Date
               else echo -n "<td title='Storix backup done $days days ago, warning at $STWARN days.' " >>$HTML_XFILE 
                    echo "align=center bgcolor=$BCOL><font color=$FCOL>$backup_date</font></td>" >>$HTML_XFILE
            fi
    fi 

    # Backup Time & Elapse time
    echo "<td align=center bgcolor=$BCOL><font color=$FCOL>$WTIME1</font></td>"  >> $HTML_XFILE
    echo "<td align=center bgcolor=$BCOL><font color=$FCOL>$WELAPSE</font></td>" >> $HTML_XFILE

    # Backup Status
    if [ "$WSTATUS" != "Success" ]
        then echo -e "<td align=center bgcolor='Yellow'><font color=$FCOL>" >> $HTML_XFILE
        else echo -e "<td align=center bgcolor=$BCOL><font color=$FCOL>"    >> $HTML_XFILE
    fi 
    LOGFILE="${WSERVER}_${WSCRIPT}.log"                                 # Assemble log Script Name
    LOGNAME="${SADM_WWW_DAT_DIR}/${WSERVER}/log/${LOGFILE}"             # Add Dir. Path to Name
    LOGURL="http://sadmin.${SADM_DOMAIN}/${URL_VIEW_FILE}?filename=${LOGNAME}"  # Url to View Log
    if [ -r "$LOGNAME" ]                                                # If log is Readable
        then echo -n "<a href='$LOGURL 'title='View Backup Log File'>" >>$HTML_XFILE
             echo "${WSTATUS}</font></a></td>" >>$HTML_XFILE 
        else echo -e "${WSTATUS}</font></td>" >> $HTML_XFILE            # No Log = No LInk
    fi

    # Server Name & Descrition 
    echo "<td align=center bgcolor=$BCOL><font color=$FCOL>$WSERVER</font></td>" >> $HTML_XFILE
    echo "<td align=left bgcolor=$BCOL><font color=$FCOL>$WDESC</font></td>"     >> $HTML_XFILE

    # Show if Server is Sporadic or not.
    if [ "$WSPORADIC" =  "0" ] 
       then echo "<td align=center bgcolor=$BCOL><font color=$FCOL>No</font></td>"  >>$HTML_XFILE
       else echo "<td align=center bgcolor=$BCOL><font color=$FCOL>Yes</font></td>" >>$HTML_XFILE
    fi

    # Show Date and Size of Storix Backup
    if [ "$backup_date" != "$ST_DATE" ] 
        then echo -n "<td title='Execution Backup Date different than Image file date' " >>$HTML_XFILE 
             echo " align=center bgcolor='Yellow'><font color=$FCOL>$ST_DATE</font></td>" >>$HTML_XFILE
        else echo "<td align=center bgcolor=$BCOL><font color=$FCOL>$ST_DATE</font></td>" >>$HTML_XFILE
    fi 
    if [ $BACKUP_SIZE -eq 0 ] 
        then echo "<td align=center bgcolor='Yellow'><font color=$FCOL>$BACKUP_SIZE MB</font></td>" >>$HTML_XFILE
        else echo "<td align=center bgcolor=$BCOL><font color=$FCOL>$BACKUP_SIZE MB</font></td>" >>$HTML_XFILE
    fi 

    # Show Storix Date & ISO Size
    if [ "$backup_date" != "$ISO_DATE" ] 
        then echo -n "<td title='Execution Backup Date different than ISO file date' " >>$HTML_XFILE
             echo " align=center bgcolor='Yellow'><font color=$FCOL>$ISO_DATE</font></td>" >>$HTML_XFILE
        else echo "<td align=center bgcolor=$BCOL><font color=$FCOL>$ISO_DATE</font></td>" >>$HTML_XFILE
    fi 
    if [ $ISO_SIZE -eq 0 ]                                
        then echo -en "<td title='No ISO was found' align=center bgcolor='Yellow'>" >>$HTML_XFILE
             echo -e "<font color=$FCOL>${ISO_SIZE} MB</font></td>" >> $HTML_XFILE
        else echo -en "<td align=center bgcolor=$BCOL><font color=$FCOL> " >> $HTML_XFILE
             echo -e " ${ISO_SIZE} MB</font></td>" >> $HTML_XFILE
    fi 

    echo -e "</tr>\n" >> $HTML_XFILE
    return 
} 



#===================================================================================================
# Add legend at the bottom of the Storix report page
#===================================================================================================
storix_legend()
{
    echo -e "\n<br>\n<hr class="dash">\n" >> $HTML_XFILE                # Horizontal Dashed Line
    echo -e "\n\n<br><table cellspacing="0" cellpadding="0" border=0>\n"  >> $HTML_XFILE 
    BCOL="#ffffff"                                                      # Background color (White)
    FCOL="#000000"                                                      # Font Color (Black)

    echo -e "<tr>"  >> $HTML_XFILE                                      # Heading rows
    DATA="Column Name"
    echo -e "<th align=center colspan=8>$DATA</th>" >> $HTML_XFILE
    echo -e "<th align=center colspan=4>Column have a yellow background when ...</td>" >>$HTML_XFILE
    echo -e "</tr>"  >> $HTML_XFILE                                      # Begin Legend Row

    echo -e "<tr>"  >> $HTML_XFILE                                      # Begin Legend Row
    DATA="Backup execution date"
    echo -e "<td align=left colspan=4 bgcolor=$BCOL><font color=$FCOL>$DATA</td>" >> $HTML_XFILE
    DATA="The backup date is older than $STWARN days or when it's different than backup or ISO date."
    echo -e "<td align=left colspan=8 bgcolor=$BCOL><font color=$FCOL>$DATA</td>" >> $HTML_XFILE
    echo -e "</tr>"  >> $HTML_XFILE 

    echo -e "<tr>"  >> $HTML_XFILE                                      # Begin Legend Row
    DATA="Backup status"
    echo -e "<td align=left colspan=4 bgcolor=$BCOL><font color=$FCOL>$DATA</td>" >> $HTML_XFILE
    DATA="The backup status is different than 'Success'."
    echo -e "<td align=left colspan=8 bgcolor=$BCOL><font color=$FCOL>$DATA</td>" >> $HTML_XFILE
    echo -e "</tr>"  >> $HTML_XFILE 

    echo -e "<tr>"  >> $HTML_XFILE                                      # Begin Legend Row
    DATA="Backup date"
    echo -e "<td align=left colspan=4 bgcolor=$BCOL><font color=$FCOL>$DATA</td>" >> $HTML_XFILE
    DATA="The backup date is different than execution date."
    echo -e "<td align=left colspan=8 bgcolor=$BCOL><font color=$FCOL>$DATA</td>" >> $HTML_XFILE
    echo -e "</tr>"  >> $HTML_XFILE 

    echo -e "<tr>"  >> $HTML_XFILE                                      # Begin Legend Row
    DATA="Backup size"
    echo -e "<td align=left colspan=4 bgcolor=$BCOL><font color=$FCOL>$DATA</td>" >> $HTML_XFILE
    DATA="The size of the backup is zero."
    echo -e "<td align=left colspan=8 bgcolor=$BCOL><font color=$FCOL>$DATA</td>" >> $HTML_XFILE
    echo -e "</tr>"  >> $HTML_XFILE 

    echo -e "<tr>"  >> $HTML_XFILE                                      # Begin Legend Row
    DATA="ISO date"
    echo -e "<td align=left colspan=4 bgcolor=$BCOL><font color=$FCOL>$DATA</td>" >> $HTML_XFILE
    DATA="The date of the ISO file is different than the execution date."
    echo -e "<td align=left colspan=8 bgcolor=$BCOL><font color=$FCOL>$DATA</td>" >> $HTML_XFILE
    echo -e "</tr>"  >> $HTML_XFILE 

    echo -e "<tr>"  >> $HTML_XFILE                                      # Begin Legend Row
    DATA="ISO size"
    echo -e "<td align=left colspan=4 bgcolor=$BCOL><font color=$FCOL>$DATA</td>" >> $HTML_XFILE
    DATA="The size of the ISO file is zero."
    echo -e "<td align=left colspan=8 bgcolor=$BCOL><font color=$FCOL>$DATA</td>" >> $HTML_XFILE
    echo -e "</tr>"  >> $HTML_XFILE 
    echo -e "</table>\n<br><br>\n" >> $HTML_XFILE                       # End of Legend Section
}




#===================================================================================================
# Produce the backup report and email it to the SADMIN Administrator.
#===================================================================================================
backup_report()
{
    # Initialize Variable and Temporary work files.
    backup_error=0                                                      # Set to 1 if error in func.
    if [ -f "$SADM_TMP_FILE2" ] ; then rm -f $SADM_TMP_FILE2 >/dev/null 2>&1 ; fi 
    if [ -f "$HTML_BFILE" ] ; then rm -f $HTML_BFILE >/dev/null 2>&1 ; fi     
    sadm_write "${BOLD}${YELLOW}Creating the Daily Backup Report${NORMAL}\n" 

    # Put Rows you want in the select. 
    SQL="SELECT srv_name,srv_desc,srv_ostype,srv_domain,srv_monitor,srv_sporadic,srv_active" 
    SQL="${SQL},srv_sadmin_dir,srv_backup,srv_img_backup,srv_rear_ver "

    # Build SQL to select active server(s) from Database.
    SQL="${SQL} from server"                                            # From the Server Table
    SQL="${SQL} where srv_active = True"                                # Select only Active Servers
    #SQL="${SQL} where srv_active = True and srv_backup = True "         # Active Server & Backup Yes
    SQL="${SQL} order by srv_name; "                                    # Order Output by ServerName
    
    # Execute SQL Query to Create CSV in SADM Temporary work file ($SADM_TMP_FILE1)
    CMDLINE="$SADM_MYSQL -u $SADM_RO_DBUSER  -p$SADM_RO_DBPWD "         # MySQL Auth/Read Only User
    $CMDLINE -h $SADM_DBHOST $SADM_DBNAME -Ne "$SQL" | tr '/\t/' '/;/' >$SADM_TMP_FILE1
    if [ ! -s "$SADM_TMP_FILE1" ] || [ ! -r "$SADM_TMP_FILE1" ]         # File not readable or 0 len
        then sadm_write "$SADM_WARNING No Active Server were found.\n"  # Not Active Server MSG
             return 0                                                   # Return Status to Caller
    fi 
    if [ "$SADM_DEBUG" -gt 7 ]                                          # If Debug Show SQL Results
       then sadm_writelog " "                                             # Space line
            sadm_writelog "Output of the SQL Query for producing the Backup Report."
            cat $SADM_TMP_FILE1 | while read wline ; do sadm_writelog "${wline}"; done
            sadm_writelog " "                                             # Space line
    fi

    NFSMOUNT="${SADM_BACKUP_NFS_SERVER}:${SADM_BACKUP_NFS_MOUNT_POINT}" # Remote NFS Mount Point
    mount_nfs "$NFSMOUNT"                                               # Go and Mount NFS Dir.
    if [ $? -ne 0 ] ; then return 1 ; fi                                # Can't Mount back to caller

    # Exclude the servers to exclude specify in sadmin.cfg from the report
    for server in $SERVERS                                              # For All in Exclude List
    	do 
        grep -iq "^${server};" $SADM_TMP_FILE1
        if [ $? -eq 0 ]                                                 # Server in Exclude List 
            then grep -iv "^$server" $SADM_TMP_FILE1 > $SADM_TMP_FILE2  # Remove it from file
                 mv $SADM_TMP_FILE2 $SADM_TMP_FILE1                     # Copy work to Server List
    	fi
	done
    chmod 664 $SADM_TMP_FILE1                                           # So everybody can read it.

    # Produce the report Heading
    sadm_writelog "${SADM_OK} Create Backup Web Page." 
    backup_heading "SADMIN Daily Backup Report - `date '+%a %C%y.%m.%d %H:%M:%S'`" "$HTML_BFILE" 

    xcount=0                                                            # Set Server & Error Counter
    while read wline                                                    # Read Tmp file Line by Line
        do
        server_name=$(echo $wline      |awk -F\; '{print $1}')          # Extract Server Name
        server_desc=$(echo $wline      |awk -F\; '{print $2}')          # Extract Server Description
        server_os=$(echo $wline        |awk -F\; '{print $3}')          # O/S (linux/aix/darwin)
        server_domain=$(echo $wline    |awk -F\; '{print $4}')          # Extract Domain of Server
        server_monitor=$(echo $wline   |awk -F\; '{print $5}')          # Monitor  1=True 0=False
        server_sporadic=$(echo $wline  |awk -F\; '{print $6}')          # Sporadic 1=True 0=False
        server_active=$(echo $wline    |awk -F\; '{print $7}')          # Active   1=Yes  0=No
        server_rootdir=$(echo $wline   |awk -F\; '{print $8}')          # Client SADMIN Root Dir.
        server_backup=$(echo $wline    |awk -F\; '{print $9}')          # Backup Schd 1=True 0=False
        server_img_backup=$(echo $wline|awk -F\; '{print $10}')         # ReaR Sched. 1=True 0=False
        server_rear_ver=$(  echo $wline|awk -F\; '{print $11}')         # ReaR Sched. 1=True 0=False
        fqdn_server=`echo ${server_name}.${server_domain}`              # Create FQDN Server Name
        #
        if [ "$SADM_DEBUG" -gt 4 ]                                      # If Debug Show System name
           then sadm_writelog "Processing ${server_name}."              # Server Name
        fi 
        #

        # Calculate Today ($CUR_TOTAL) and Yesterday ($PRV_TOTAL) Backup Size in MB
        CUR_TOTAL=0                                                     # Reset Today Backup Size 
        PRV_TOTAL=0                                                     # Reset Previous Backup Size
        if [ -d ${LOCAL_MOUNT}/${server_name} ]                         # If Server Backup Dir Exist
           then export TOUCH_TODAY=`date "+%Y/%m/%d"`                   # Today Date YYYY/MM/DD
                export TOUCH_YESTERDAY=$(date --date="yesterday" +"%Y/%m/%d") # Yesterday YYYY/MM/DD
                bsize="${SADM_TMP_DIR}/daily_report.size"               # WorkFile, Calc Backup Size
                cd ${LOCAL_MOUNT}/${server_name}                        # CD into Backup Dir.
                touch_file="${SADM_TMP_DIR}/daily_report.time"          # Backup Ref Touch File Time
                touch -d "$TOUCH_TODAY" $touch_file                     # TouchFile=Today Date/Time 
                find . -type f -newer $touch_file -exec stat --format=%s {} \; > $bsize
                if [ "$SADM_DEBUG" -gt 4 ]
                    then sadm_writelog "TOUCH_TODAY=$TOUCH_TODAY"
                         sadm_writelog "touch -d $TOUCH_TODAY $touch_file"
                         sadm_writelog "find . -type f -newer $touch_file -exec stat --format=%s {} \; > $bsize"
                         sadm_writelog "cat bsize ($bsize)"
                         ls -l $bsize 
                         cat $bsize
                fi
                if [ -s $bsize ]                                        # Backup File Not Found or 0
                   then TOTAL=$(awk '{sum += $1} END {print sum}' $bsize) # Add each file size 
                        CUR_TOTAL=$(echo "$TOTAL /1024/1024" | bc)      # Convert Backup Size in MB
                fi 
                touch -d "$TOUCH_YESTERDAY" $touch_file                 # TouchFile=Yesterday  
                find . -type f -newer $touch_file -exec ls -l {} \; | grep "$UND_YESTERDAY" > $bsize
                if [ -s $bsize ]                                        # Backup File Not Found or 0
                   then TOTAL=$(awk '{sum += $5} END {print sum}' $bsize) # Add each file size 
                        PRV_TOTAL=$(echo "$TOTAL /1024/1024" | bc)      # Convert Backup Size in MB
                fi 
                rm -f $bsize > /dev/null 2>&1                           # Del. Size Work File
                rm -f $touch_file > /dev/null 2>&1                      # Del. Touch Work File
        fi
        if [ "$SADM_DEBUG" -gt 4 ]                                      # If Debug Show System name
           then sadm_writelog "CUR_TOTAL=$CUR_TOTAL PRV_TOTAL=$PRV_TOTAL"
        fi 

        # Get the last line of the backup RCH file for the system.
        RCH_FILE="${SADM_WWW_DAT_DIR}/${server_name}/rch/${server_name}_${backup_script_name}.rch"
        if [ -s $RCH_FILE ]                                             # If System Backup RCH Exist
            then RCH_LINE=$(tail -3 $RCH_FILE | sort | tail -1)         # Get last line in RCH File
            else #echo "RCH file ${RCH_FILE} not found or is empty."    # Advise user no RCH File
                 start_end="---------- -------- ---------- -------- --------" # Start/End Date/Time
                 RCH_LINE="${server_name} ${start_end} ${backup_script_name} default 1 3" 
        fi 

        # The RCH line should have 10 ($FIELD_IN_RCH) fields, if not set error to 1 & advise user.
        NBFIELD=`echo $RCH_LINE | awk '{ print NF }'`                   # How many fields on line ?
        if [ "${NBFIELD}" != "${FIELD_IN_RCH}" ]                        # If abnormal nb. of field
           then sadm_write "Format error in this RCH file : ${RCH_FILE}\n"
                sadm_write "Line below have ${NBFIELD} but it should have ${FIELD_IN_RCH}.\n"
                sadm_write "The backup for this server is skipped: ${RCH_LINE}\n"
                sadm_write "\n"
                backup_error=1                                          # Func. Return Code now at 1
                continue 
        fi        
        if [ $SADM_DEBUG -gt 5 ] 
            then printf "The RCH Filename of ${server_name} backup of is ${RCH_FILE}\n"
                 printf "The last Line in the file is : ${RCH_LINE}\n"
        fi 

        # Split the RCH Line 
        WSERVER=`echo -e $RCH_LINE | awk '{ print $1 }'`                # Extract Server Name
        WDATE1=` echo -e $RCH_LINE | awk '{ print $2 }'`                # Extract Date Started
        WTIME1=` echo -e $RCH_LINE | awk '{ print $3 }'`                # Extract Time Started
        WDATE2=` echo -e $RCH_LINE | awk '{ print $4 }'`                # Extract Date Started
        WTIME2=` echo -e $RCH_LINE | awk '{ print $5 }'`                # Extract Time Ended
        WELAPSE=`echo -e $RCH_LINE | awk '{ print $6 }'`                # Extract Time Ended
        WSCRIPT=`echo -e $RCH_LINE | awk '{ print $7 }'`                # Extract Script Name
        WALERT=` echo -e $RCH_LINE | awk '{ print $8 }'`                # Extract Alert Group Name
        WTYPE=`  echo -e $RCH_LINE | awk '{ print $9 }'`                # Extract Alert Group Type
        WRCODE=` echo -e $RCH_LINE | awk '{ print $10 }'`               # Extract Return Code 

        # Set the backup Status Description
        case "$WRCODE" in                                               # Case on RCH Return Code
            0 ) WSTATUS="Success" 
                ;; 
            1 ) WSTATUS="Failed"
                ;;
            2 ) WSTATUS="Running"
                ;;
            3 ) WSTATUS="No Backup"
                ;;
            * ) WRDESC="CODE $WRCODE ?"                                 # Illegal Code  Desc
                ;;                                                          
        esac
        
        # Build backup line to be written to work file (Will be sorted later)
        BLINE="${WDATE1};${WTIME1};${WELAPSE};${WSTATUS};${server_name}" 
        BLINE="${BLINE};${server_desc};${server_backup}"
        BLINE="${BLINE};${CUR_TOTAL};${PRV_TOTAL};${server_sporadic};${server_rear_ver}" 
        echo "$BLINE" >> $SADM_TMP_FILE2                                # Write Info to work file
        done < $SADM_TMP_FILE1

    # Umount NFS Mount point, Sort the Work File (By Date/Time) then produce report it HTML format.
    unmount_nfs                                                         # UnMount NFS Backup Dir.
    sort $SADM_TMP_FILE2 > $SADM_TMP_FILE1                              # Sort Tmp file by Date/Time
    while read wline                                                    # Read Tmp file Line by Line
        do
        xcount=$(($xcount+1))                                           # Increase Line Counter
        backup_line "${wline};${xcount};$HTML_BFILE;B"                  # Insert line in HTML Page
        done < $SADM_TMP_FILE1                                          # Read Sorted file

    echo -e "</table>\n" >> $HTML_BFILE                                 # End of Backup section
    backup_legend                                                       # Add Legend at page bottom
    echo -e "</body>\n</html>" >> $HTML_BFILE                           # End of Backup Page

    # Set Report by Email to SADMIN Administrator
    subject="SADMIN Backup Report"                                      # Send Backup Report by mail
    export EMAIL="$SADM_MAIL_ADDR"                                      # Set the FROM Email 
    if [ "$WKHTMLTOPDF" != "" ]                                         # If wkhtmltopdf on System
        then $WKHTMLTOPDF -O landscape $HTML_BFILE $PDF_BFILE > /dev/null 2>&1 # Convert HTML to PDF
             mutt -e 'set content_type=text/html' -s "$subject" $SADM_MAIL_ADDR -a $PDF_BFILE < $HTML_BFILE
             SADM_EXIT_CODE=$?                                          # Save mutt return Code.
        else mutt -e 'set content_type=text/html' -s "$subject" $SADM_MAIL_ADDR < $HTML_BFILE
             SADM_EXIT_CODE=$?                                          # Save mutt return Code.
    fi 
    if [ $SADM_EXIT_CODE -eq 0 ]                                        # If mail sent successfully
        then sadm_writelog "${SADM_OK} Daily Backup Report sent to $SADM_MAIL_ADDR"      
        else sadm_writelog "${SADM_ERROR} Failed to send the Daily Backup Report to $SADM_MAIL_ADDR"
    fi

    sadm_write "${BOLD}${YELLOW}End of Daily Backup Report ...${NORMAL}\n"   
    sadm_write "\n"                                                     # White line in log & Screen
    return $SADM_EXIT_CODE                                              # Return Err Count to caller
}



#===================================================================================================
# Backup Report Heading
#===================================================================================================
backup_heading()
{
    RTITLE=$1                                                           # Report Title
    HTML=$2                                                             # HTML Report File Name

    echo -e "<!DOCTYPE html><html>"                          > $HTML
    echo -e "<head>"                                        >> $HTML
    echo -e "\n<meta charset='utf-8' />"                    >> $HTML
    echo -e "\n<style>"                                     >> $HTML
    echo -e "th { color: white; background-color: #0000ff; padding: 0px; }"         >> $HTML
    echo -e "td { color: white; border-bottom: 1px solid #ddd; padding: 5px; }"     >> $HTML
    echo -e "tr:nth-child(odd)  { background-color: #F5F5F5; }"                     >> $HTML
    echo -e "table, th, td { border: 1px solid black; border-collapse: collapse; }" >> $HTML
    echo -e "div.fs150   { font-size: 150%; }"                                      >> $HTML
    echo -e "div.fs13px  { text-align: left; font-size: 13px; }"                    >> $HTML
    echo -e "\n/* Dashed red border */"                     >> $HTML
    echo -e "hr.dash        { border-top: 1px dashed red;}" >> $HTML
    echo -e "/* Large rounded green border */"              >> $HTML
    echo -e "hr.large_green { border: 3px solid green; border-radius: 5px; }"       >> $HTML
    echo -e "p.report_title {" >> $HTML
    echo -e "   font-family:Helvetica,Arial;color:blue;font-size:25px;font-weight:bold;" >> $HTML
    echo -e "}" >> $HTML
    echo -e "</style>"                                      >> $HTML
    echo -e "\n<title>$RTITLE</title>"                      >> $HTML
    echo -e "</head>\n"                                     >> $HTML
    echo -e "<body>"                                        >> $HTML

    echo -e "<center>" >> $HTML                                         # Center what's coming
    echo -e "<p class='report_title'>${RTITLE}</p>" >> $HTML            # Report Title
    URL_SCRIPTS_REPORT="/view/daily_backup_report.html"                 # Scripts Daily Report Page
    RURL="http://sadmin.${SADM_DOMAIN}/${URL_SCRIPTS_REPORT}"           # Full URL to HTML report 
    TITLE2="View the web version of this report"                        # Link Description
    echo -e "</center>" >> $HTML                                        # End Text Center
    echo "<div class='fs13px'><a href='${RURL}'>${TITLE2}</a></div>" >>$HTML # Insert Link on Page
    echo -e "\n<hr class="large_green">\n"                  >> $HTML
    echo -e "\n<br>\n<center>\n<table border=0>"            >> $HTML
    #
    echo -e "\n<thead>"                                     >> $HTML
    #
    echo -e "<tr>"                                          >> $HTML
    echo -e "<th colspan=1 dt-head-center></th>"            >> $HTML
    echo -e "<th colspan=4 align=center>Last Backup</th>"   >> $HTML
    echo -e "<th align=center>Schedule</th>"                >> $HTML
    echo -e "<th colspan=2></th>"                           >> $HTML
    echo -e "<th align=center>System</th>"                  >> $HTML
    echo -e "<th align=center>Current</th>"                 >> $HTML
    echo -e "<th align=center>Previous</th>"                >> $HTML
    echo -e "</tr>"                                         >> $HTML
    #
    echo -e "<tr>"                              >> $HTML
    echo -e "<th align=center>No</th>"          >> $HTML
    echo -e "<th align=center>Date</th>"        >> $HTML
    echo -e "<th align=center>Time</th>"        >> $HTML
    echo -e "<th align=center>Elapse</th>"      >> $HTML
    echo -e "<th align=center>Status</th>"      >> $HTML
    echo -e "<th align=left>Activated</th>"     >> $HTML
    echo -e "<th align=center>System</th>"      >> $HTML
    echo -e "<th align=left>Description</th>"   >> $HTML    
    echo -e "<th align=left>Sporadic</th>"      >> $HTML
    echo -e "<th align=center>Size</th>"        >> $HTML
    echo -e "<th align=center>Size</th>"        >> $HTML
    echo -e "</tr>"                             >> $HTML
    echo -e "</thead>\n"                        >> $HTML
    return 0
}



#===================================================================================================
# Add the receiving line into the Backup report page
#===================================================================================================
backup_line()
{
    # Extract fields from parameters received.
    BACKUP_INFO=$*                                                      # Comma Sep. Info Line
    WDATE1=$(     echo $BACKUP_INFO | awk -F\; '{ print $1 }')           # Backup Script RCH Line
    WTIME1=$(     echo $BACKUP_INFO | awk -F\; '{ print $2 }')           # DB System Description
    WELAPSE=$(    echo $BACKUP_INFO | awk -F\; '{ print $3 }')           # DB System Description
    WSTATUS=$(    echo $BACKUP_INFO | awk -F\; '{ print $4 }')           # DB System Description
    WSERVER=$(    echo $BACKUP_INFO | awk -F\; '{ print $5 }')           # DB System Description
    WDESC=$(      echo $BACKUP_INFO | awk -F\; '{ print $6 }')           # DB System Description
    WACT=$(       echo $BACKUP_INFO | awk -F\; '{ print $7 }')           # DB System Description
    WCUR_TOTAL=$( echo $BACKUP_INFO | awk -F\; '{ print $8 }')           # Current Backup Total MB
    WPRV_TOTAL=$( echo $BACKUP_INFO | awk -F\; '{ print $9 }')           # Yesterday Backup Total MB
    WSPORADIC=$(  echo $BACKUP_INFO | awk -F\; '{ print $10 }')          # Sporadic Server=1 else=0
    WREARVER=$(   echo $BACKUP_INFO | awk -F\; '{ print $11 }')          # Rear Version Number
    WCOUNT=$(     echo $BACKUP_INFO | awk -F\; '{ print $12 }')          # Line Counter
    HTML=$(       echo $BACKUP_INFO | awk -F\; '{ print $13 }')          # HTML Output File Name
    RTYPE=$(      echo $BACKUP_INFO | awk -F\; '{ print $14 }')          # R=RearBackup B=DailyBackup

    # Alternate background color at every line
    if (( $WCOUNT %2 == 0 ))                                            # Modulo on line counter
       then BCOL="#00FFFF" ; FCOL="#000000"                             # Pair count color
       else BCOL="#F0FFFF" ; FCOL="#000000"                             # Impar line color
    fi

    # Beginning to Insert Line in HTML Table
    echo -e "<tr>"  >> $HTML                                            # Begin backup line
    echo -e "<td align=center bgcolor=$BCOL><font color=$FCOL>$WCOUNT</font></td>"  >> $HTML

    # Calculate number of days between now and the backup date
    backup_date=`echo "$WDATE1" | sed 's/\./\//g'`                      # Replace dot by '/' in date
    epoch_backup=`date -d "$backup_date" "+%s"`                         # Backup Date in Epoch Time
    epoch_now=`date "+%s"`                                              # Today in Epoch Time
    diff=$(($epoch_now - $epoch_backup))                                # Nb. Seconds between
    days=$(($diff/(60*60*24)))                                          # Convert Sec. to Days

    # Backup Date is not today (May be Missed, Sporadic, ...) Show in Yellow Background
    if [ "$TODAY" = "$WDATE1" ]                                         # Backup done today
       then echo -n "<td title='Backup was done today'" >>$HTML         # Tooltip 
            echo " align=center bgcolor=$BCOL><font color=$FCOL>$WDATE1</font></td>" >>$HTML
       else if [ "$WDATE1" = "----------" ]                             # backup running or NoBackup
               then echo -n "<td title='No backup recorded' " >>$HTML 
               else echo -n "<td title='Last Backup done $days days ago' " >>$HTML   
            fi
            if [ $WACT -eq 0 ]                                                  # If Backup Inactive
                then echo -n "align=center bgcolor=$BCOL>" >>$HTML               # Normal Backup
                     echo "<font color=$FCOL><strong>$WDATE1</strong></font></td>" >>$HTML # Date in Bold
                else echo -n "align=center bgcolor='Yellow'>" >>$HTML            # Yellow Background
                     echo "<font color=$FCOL>$WDATE1</font></td>" >>$HTML        # Show Backup Date
            fi
    fi

    # Backup Time & Elapse time
    echo "<td align=center bgcolor=$BCOL><font color=$FCOL>$WTIME1</font></td>"  >> $HTML
    echo "<td align=center bgcolor=$BCOL><font color=$FCOL>$WELAPSE</font></td>" >> $HTML
    #echo "<td align=center bgcolor=$BCOL><font color=$FCOL>$WSTATUS</font></td>" >> $HTML

    # Backup Status - (If you click on it it will show the backup script log.)
    if [ "$WSTATUS" = "Success" ]                                       # Not Success Backgrd Yellow 
        then echo -e "<td align=center bgcolor=$BCOL><font color=$FCOL>"    >> $HTML
        else echo -e "<td align=center bgcolor='Yellow'><font color=$FCOL>" >> $HTML
    fi 
    LOGFILE="${WSERVER}_${WSCRIPT}.log"                                 # Assemble log Script Name
    LOGNAME="${SADM_WWW_DAT_DIR}/${WSERVER}/log/${LOGFILE}"             # Add Dir. Path to Name
    LOGURL="http://sadmin.${SADM_DOMAIN}/${URL_VIEW_FILE}?filename=${LOGNAME}"  # Url to View Log
    if [ -r "$LOGNAME" ]                                                # If log is Readable
        then echo -n "<a href='$LOGURL 'title='View Backup Log File'>" >>$HTML
             echo "${WSTATUS}</font></a></td>" >>$HTML 
        else echo -e "${WSTATUS}</font></td>" >> $HTML                  # No Log = No LInk
    fi

    # Backup Schedule Status - Activated or Deactivated (show in Yellow background)
    URL_SCHED_UPDATE=$(echo "${URL_UPD_SCHED/SYSTEM/$WSERVER}")  # URL To Modify Backup Schd
    if [ $WACT -eq 0 ] 
       #then echo "<td align=center bgcolor='Yellow'><font color=$FCOL>"         >>$HTML
       then echo "<td align=center bgcolor=$BCOL><font color=$FCOL>"         >>$HTML
            echo -n "<a href='http://sadmin.${SADM_DOMAIN}/$URL_SCHED_UPDATE "  >>$HTML
            echo "'title='Schedule Deactivated, click to modify'><strong>No</strong></font></a></td>" >>$HTML
       else echo "<td align=center bgcolor=$BCOL><font color=$FCOL>"            >>$HTML    
            echo -n "<a href='http://sadmin.${SADM_DOMAIN}/$URL_SCHED_UPDATE "  >>$HTML
            echo "'title='Click to modify Backup Schedule'>Yes</font></a></td>"          >>$HTML
    fi

    # Server Name & Descrition (From DB)
    echo "<td align=center bgcolor=$BCOL><font color=$FCOL>$WSERVER</font></td>" >> $HTML
    echo "<td align=left bgcolor=$BCOL><font color=$FCOL>$WDESC</font></td>"     >> $HTML

    # Sporadic Server or Not 
    if [ "$WSPORADIC" =  "0" ] 
       then echo "<td align=center bgcolor=$BCOL><font color=$FCOL>No</font></td>"  >>$HTML
       else echo "<td align=center bgcolor=$BCOL><font color=$FCOL>Yes</font></td>" >>$HTML
    fi

    # CURRENT BACKUP SIZE - Show in Yellow if : 
    #   - Today Backup Size ($WCUR_TOTAL) is 0
    #   - Today Backup Size ($WCUR_TOTAL) vs Yesterday ($WPRV_TOTAL) is greater than threshold $WPCT
    #
    if [ $WCUR_TOTAL -eq 0 ]                                            # If Today Backup Size is 0
        then if [ $WACT -eq 0 ]                                         # If Backup Inactive
                then echo -en "<td title='No Backup situation' align=center bgcolor=$BCOL>" >>$HTML
                     echo -e "<font color=$FCOL><strong>${WCUR_TOTAL} MB</strong></font></td>" >> $HTML
                else echo -en "<td title='No Backup situation' align=center bgcolor='Yellow'>" >>$HTML
                     echo -e "<font color=$FCOL>${WCUR_TOTAL} MB</font></td>" >> $HTML
             fi
        else if [ $WPRV_TOTAL -eq 0 ]                                   # If Yesterday Backup Size=0
                then echo -en "<td align=center bgcolor=$BCOL><font color=$FCOL>" >>$HTML
                     echo -e " ${WCUR_TOTAL} MB</font></td>" >>$HTML
                else if [ $WCUR_TOTAL -ge $WPRV_TOTAL ]                 # Today Backup >= Yesterday
                        then PCT=`echo "(($WCUR_TOTAL - $WPRV_TOTAL) / $WPRV_TOTAL) * 100" | bc -l`
                             PCT=$(printf "%.f" $PCT) 
                             if [ $PCT -ge $WPCT ]                      # Inc Greater than threshold
                                then echo -en "<td align=center bgcolor='Yellow' " >>$HTML
                                     echo "title='Backup is ${PCT}% bigger than yesterday'>" >>$HTML
                                     echo "<font color=$FCOL>${WCUR_TOTAL} MB</font></td>" >>$HTML
                                else echo -n "<td align=center bgcolor=$BCOL>" >>$HTML
                                     echo "<font color=$FCOL>${WCUR_TOTAL} MB</font></td>" >>$HTML
                             fi
                        else PCT=`echo "(($WPRV_TOTAL - $WCUR_TOTAL) / $WCUR_TOTAL) * 100" | bc -l`
                             #PCT=`echo "($WCUR_TOTAL / $WPRV_TOTAL) * 100" | bc -l` 
                             PCT=$(printf "%.f" $PCT)
                             if [ $PCT -ge $WPCT ] && [ $PCT -ne 0 ]         # Decr. less than threshold
                                then echo -n "<td title='Backup is ${PCT}% smaller than yesterday' " >>$HTML
                                     echo "align=center bgcolor='Yellow'> " >> $HTML
                                     echo "<font color=$FCOL>${WCUR_TOTAL} MB</font></td>" >>$HTML
                                else echo -n "<td align=center bgcolor=$BCOL>" >>$HTML
                                     echo "<font color=$FCOL>${WCUR_TOTAL} MB</font></td>" >>$HTML
                             fi
                     fi 
             fi 
    fi 


    # Yesterday Backup Size - If Size is 0, show it in Yellow.
    if [ $WPRV_TOTAL -eq 0 ]                                
        then if [ $WACT -eq 0 ]                                         # If Backup Inactive
                then echo -en "<td title='No Backup situation' align=center bgcolor=$BCOL>" >>$HTML
                     echo -e "<font color=$FCOL><strong>${WPRV_TOTAL} MB</strong></font></td>" >> $HTML
                else echo -en "<td title='No Backup situation' align=center bgcolor='Yellow'>" >>$HTML
                     echo -e "<font color=$FCOL>${WPRV_TOTAL} MB</font></td>" >> $HTML
             fi
        else echo -en "<td align=center bgcolor=$BCOL><font color=$FCOL> " >> $HTML
             echo -e " ${WPRV_TOTAL} MB</font></td>" >> $HTML
    fi 

    echo -e "</tr>\n" >> $HTML
    return 
} 


#===================================================================================================
# Add legend at the bottom of the Storix report page
#===================================================================================================
backup_legend()
{
    echo -e "\n<br>\n<hr class="dash">\n" >> $HTML_BFILE                # Horizontal Dashed Line
    echo -e "\n\n<br><table cellspacing="5" cellpadding="0" border=0>\n"  >> $HTML_BFILE 
    BCOL="#ffffff"                                                      # Background color (White)
    FCOL="#000000"                                                      # Font Color (Black)

    echo -e "<tr>"  >> $HTML_BFILE                                            # Heading rows
    DATA="Column Name"
    echo -e "<th align=left colspan=5>$DATA</th>" >> $HTML_BFILE
    echo -e "<th align=left >&nbsp;</th>" >> $HTML_BFILE
    echo -e "<th align=left colspan=5>Column have a yellow background when ...</td>" >>$HTML_BFILE
    echo -e "</tr>"  >> $HTML_BFILE                                     

    echo -e "<tr>"  >> $HTML_BFILE                                      
    DATA="Last Backup Date"
    echo -e "<td align=left colspan=5 bgcolor=$BCOL><font color=$FCOL>$DATA</td>" >> $HTML_BFILE
    echo -e "<td align=left >&nbsp;</td>" >> $HTML_BFILE
    DATA="The backup date is not today (Backup are done daily)."
    echo -e "<td align=left colspan=5 bgcolor=$BCOL><font color=$FCOL>$DATA</td>" >> $HTML_BFILE
    echo -e "</tr>"  >> $HTML_BFILE 

    echo -e "<tr>"  >> $HTML_BFILE                                      
    DATA="Last Backup Status"
    echo -e "<td align=left colspan=5 bgcolor=$BCOL><font color=$FCOL>$DATA</td>" >> $HTML_BFILE
    echo -e "<td align=left >&nbsp;</td>" >> $HTML_BFILE
    DATA="The backup status is different than 'Success'."
    echo -e "<td align=left colspan=5 bgcolor=$BCOL><font color=$FCOL>$DATA</td>" >> $HTML_BFILE
    echo -e "</tr>"  >> $HTML_BFILE 

    echo -e "<tr>"  >> $HTML_BFILE                                      
    DATA="Schedule Activated"
    echo -e "<td align=left colspan=5 bgcolor=$BCOL><font color=$FCOL>$DATA</td>" >> $HTML_BFILE
    echo -e "<td align=left >&nbsp;</td>" >> $HTML_BFILE
    DATA="The backup schedule is not activated."
    echo -e "<td align=left colspan=5 bgcolor=$BCOL><font color=$FCOL>$DATA</td>" >> $HTML_BFILE
    echo -e "</tr>"  >> $HTML_BFILE 

    echo -e "<tr>"  >> $HTML_BFILE                                      
    DATA="Current Size"
    echo -e "<td align=left colspan=5 bgcolor=$BCOL><font color=$FCOL>$DATA</td>" >> $HTML_BFILE
    echo -e "<td align=left >&nbsp;</td>" >> $HTML_BFILE
    DATA="The backup size is zero or ${WPCT}% bigger or smaller than the previous backup."
    echo -e "<td align=left colspan=5 bgcolor=$BCOL><font color=$FCOL>$DATA</td>" >> $HTML_BFILE
    echo -e "</tr>"  >> $HTML_BFILE 

    echo -e "<tr>"  >> $HTML_BFILE                                      
    DATA="Previous Size"
    echo -e "<td align=left colspan=5 bgcolor=$BCOL><font color=$FCOL>$DATA</td>" >> $HTML_BFILE
    echo -e "<td align=left >&nbsp;</td>" >> $HTML_BFILE
    DATA="The backup size is zero or ${WPCT}% bigger or smaller than the current backup."
    echo -e "<td align=left colspan=5 bgcolor=$BCOL><font color=$FCOL>$DATA</td>" >> $HTML_BFILE
    echo -e "</tr>"  >> $HTML_BFILE 
    echo -e "</table>\n<br><br>\n" >> $HTML_BFILE                       # End of Legend Section
}


# --------------------------------------------------------------------------------------------------
# Command line Options functions
# Evaluate Command Line Switch Options Upfront
# By Default (-h) Show Help Usage, (-v) Show Script Version,(-d0-9] Set Debug Level 
# By Default all report will be produce and email to sysadmin (Except Storix report)
# --------------------------------------------------------------------------------------------------
function cmd_options()
{
    OPTION_SELECTED=0                                                   # Default no option selected
    while getopts "hvd:brsx" opt ; do                                   # Loop to process Switch
        case $opt in
            b) BACKUP_REPORT="OFF"                                      # De-Activate Backup report
               OPTION_SELECTED=$(($OPTION_SELECTED+1))                  # Incr. Nb. Option Selected
               ;;                                       
            r) REAR_REPORT="OFF"                                        # De-Activate ReaR Report
               OPTION_SELECTED=$(($OPTION_SELECTED+1))                  # Incr. Nb. Option Selected
               ;;
            s) SCRIPT_REPORT="OFF"                                      # De-Activate Script Report
               OPTION_SELECTED=$(($OPTION_SELECTED+1))                  # Incr. Nb. Option Selected
               ;;
            x) STORIX_REPORT="ON"                                       # Produce Storix Reports
               OPTION_SELECTED=$(($OPTION_SELECTED+1))                  # Incr. Nb. Option Selected
               ;;
            d) SADM_DEBUG=$OPTARG                                       # Get Debug Level Specified
               num=`echo "$SADM_DEBUG" | grep -E ^\-?[0-9]?\.?[0-9]+$`  # Valid is Level is Numeric
               if [ "$num" = "" ]                                       # No it's not numeric 
                  then printf "\nDebug Level specified is invalid.\n"   # Inform User Debug Invalid
                       show_usage                                       # Display Help Usage
                       exit 1                                           # Exit Script with Error
               fi
               printf "Debug Level set to ${SADM_DEBUG}.\n"             # Display Debug Level
               ;;                                                       
            h) show_usage                                               # Show Help Usage
               exit 0                                                   # Back to shell
               ;;
            v) sadm_show_version                                        # Show Script Version Info
               exit 0                                                   # Back to shell
               ;;
           \?) printf "\nInvalid option: -${OPTARG}.\n"                 # Invalid Option Message
               show_usage                                               # Display Help Usage
               exit 1                                                   # Exit with Error
               ;;
        esac                                                            # End of case
    done                                                                # End of while
    return 
}



#===================================================================================================
#
# 1- Create a file containing last line of all *.rch within $SADMIN/wwww/dat in $SADM_TMP_FILE1 
# 2- Sort it by Return Code in Reverse order then by date , then by server into $SADM_TMP_FILE1 
# 3- File is loaded into an array.
# 3- If any line don't have 10 ($FIELD_IN_RCH) fields it's an error message is issued.
#
#===================================================================================================
load_rch_array()
{
    # SADMIN Server get ReturnCodeHistory (RCH) files from all clients via "sadm_fetch_clients.sh" 
    # Creare a tmp file containing the LAST line of each *.rch present in ${SADMIN}/www/dat dir.
    find $SADM_WWW_DAT_DIR -type f -name "*.rch" -exec tail -1 {} \; > $SADM_TMP_FILE2
    sort -t' ' -rk10,10 -k2,3 -k7,7 $SADM_TMP_FILE2 > $SADM_TMP_FILE1   # Sort by Return Code & date

    # Check if working file is empty, then nothing to report
    if [ ! -s "$SADM_TMP_FILE1" ]                                       # No rch file record ??
       then sadm_writelog "${SADM_WARNING} No RCH File to process."     # Issue message to user
            return 1                                                    # Exit Function 
    fi
    
    # Now we put the last line of all rch file from the working temp file into an array.
    index=0 ;                                                           # RCH Array Index
    if [ -a "$RCH_SUMMARY" ] ; then rm -f $RCH_SUMMARY ; fi             # Remove old file if exist
    while read wline                                                    # Read Line from TEMP3 file
        do                                                              # Start of loop
        WNB_FIELD=`echo $wline | wc -w`                                 # Check Nb. Of field in Line
        if [ "$WNB_FIELD" -eq 0 ] ; then continue ; fi                  # Ignore Blank Line
        if [ "$WNB_FIELD" -ne "$FIELD_IN_RCH" ]                         # If NB.Field don't match
            then echo $wline >> $SADM_TMP_FILE3                         # Faulty Line to TMP3 file
                 SMESS1="${SADM_ERROR} Lines in RCH file should have ${FIELD_IN_RCH} fields," 
                 SMESS2="${SMESS1} line below have $WNB_FIELD and is ignore." 
                 sadm_write "${SMESS2}\n"                               # Advise User Line in Error
                 sadm_write "'$wline'\n"                                # Show Faulty Line to User
                 aerror=$(($aerror+1))                                  # Increment Error Counter
                 continue                                               # Go on and read next line
        fi
        rch_array[$index]="$wline"                                      # Put Line in Array
        index=$(($index+1))                                             # Increment Array Index
        echo "$wline" >> $RCH_SUMMARY                                   # Add Line>>RCH Summary file
        done < $SADM_TMP_FILE1                                          # ENd Loop - Input FileName

    # Under Debug Mode Print out the content of the array
    if [ $SADM_DEBUG -gt 4 ]                                            # Debug Over 4 Activated
       then sadm_writelog "Content of the working RCH Array"            # Advise what shows below
            index=0                                                     # Reset Array index to 0
            for WLINE in "${rch_array[@]}"                              # For every item in array
                do 
                sadm_writelog "[$index] $WLINE"                         # Show index and Array Value
                index=$(($index+1))                                     # Increment Error Counter
                done
    fi 
    
    return $aerror                                                      # Return ErrCount to caller
}




#===================================================================================================
# Main Function of this script.
# It Genenerate every web page and pdf and send them by email to the sadmin main user.
#===================================================================================================
main_process()
{
    
    # Set Path to wkhtmltopdf (If Exist on System) else will be blank
    export WKHTMLTOPDF=$(sadm_get_command_path "wkhtmltopdf")           # Get wkhtmltopdf cmd path 
    if [ "$WKHTMLTOPDF" = "" ]
        then sadm_write "[ WARNING ] Please consider installing package 'wkhtmltopdf'.\n"
             sadm_write "With this package, we will be able generate pdf from the generate html pages.\n"
             sadm_write "   - For Debian,Ubuntu,Raspbian,... : sudo apt -y install wkhtmltopdf \n"
             sadm_write "   - For CentOS and RHEL v7 ...     : sudo yum -y install $SADMIN/pkg/wkhtmltopdf/*centos7* \n"
             sadm_write "   - For CentOS and RHEL v8 ...     : sudo dnf -y install $SADMIN/pkg/wkhtmltopdf/*centos8* \n"
             sadm_write "   - For Fedora (included in repo)  : sudo dnf -y install wkhtmltopdf \n"
             sadm_write "You can also download the latest version of 'wkhtmltopdf' at https://wkhtmltopdf.org \n"
             sadm_write "After doing so, a pdf copy of the reports will be attached to the emails.\n"
             sadm_write_log " "
    fi 

    if [ "$BACKUP_REPORT" = "ON" ]                                      # If CmdLine -b was used
        then backup_report                                              # Produce Backup Report 
             RC=$?                                                      # Save the Return Code
             SADM_EXIT_CODE=$(($SADM_EXIT_CODE+$RC))                    # Add ReturnCode to ExitCode
    fi 
    if [ "$REAR_REPORT" = "ON" ]                                        # If CmdLine -r was used
        then rear_report                                                # Produce ReaR Backup Report 
             RC=$?                                                      # Save the Return Code
             SADM_EXIT_CODE=$(($SADM_EXIT_CODE+$RC))                    # Add ReturnCode to ExitCode
    fi 
    if [ "$STORIX_REPORT" = "ON" ]                                      # If CmdLine -x was used
        then storix_report                                              # Produce Storix Backup Rep. 
             RC=$?                                                      # Save the Return Code
             SADM_EXIT_CODE=$(($SADM_EXIT_CODE+$RC))                    # Add ReturnCode to ExitCode
    fi 

    # Create an array containing the last line of each '*.rch' files 
    load_rch_array                                                      # Create rch last line array 

    if [ "$SCRIPT_REPORT" = "ON" ]                                      # If CmdLine -s was used
        then script_report                                              # Produce Script Report 
             RC=$?                                                      # Save the Return Code
             SADM_EXIT_CODE=$(($SADM_EXIT_CODE+$RC))                    # Add ReturnCode to ExitCode
    fi 

    if [ -f "$RCH_SUMMARY" ] ; then rm -f $RCH_SUMMARY >/dev/null 2>&1 ;fi  # Remove Work file
    return $SADM_EXIT_CODE

}

# --------------------------------------------------------------------------------------------------
#                       S T A R T     O F    T H E    S C R I P T 
# --------------------------------------------------------------------------------------------------

    cmd_options "$@"                                                    # Check command-line Options    
    sadm_start                                                          # Create Dir.,PID,log,rch
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if 'Start' went wrong
    main_process                                                        # Execute Main Function
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log 
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
    