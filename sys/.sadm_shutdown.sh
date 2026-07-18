#! /usr/bin/env bash
# --------------------------------------------------------------------------------------------------
#   Author:     Jacques Duplessis
#   Title:      sadm_shutdown.sh
#   Date:       25 October 2015
#   Synopsis:   This script is run when the sadmin.service is shutdown when server goes down.
#               Called by /etc/systemd/system/sadmin.service (systemd) or /etc/init.d/sadmin (SysV)
# --------------------------------------------------------------------------------------------------
# 2015_01_09 startup/shutdown v2.2  Log Enhancement
# 2015_02_09 startup/shutdown v2.3  Restructure to use the SADM Library and Send email on execution.
# 2015_04_09 startup/shutdown v2.4  Add sleep of 5 sec. at the end, to allow completion shutdown
# 2015_04_09 startup/shutdown v2.5  Added code to run shutdown command based on Hostname
# 2017_08_05 startup/shutdown V2.6  Send email only on Execution Error
# 2018_01_31 startup/shutdown V2.7  Added execution of /etc/profile.d/sadmin.sh to have SADMIN Var. 
# 2018_09_19 startup/shutdown V2.8  Added Alert Group Utilization
# 2018_10_18 startup/shutdown v2.9  Remove execution of /etc/profile.d/sadmin.sh(Don't need anymore)
# 2019_03_29 startup/shutdown v02.10.00 Get SADMIN Directory Location from /etc/environment
# 2020_05_27 startup/shutdown v02.11.00 Force using bash instead of dash & problem setting SADMIN var.
# 2020_11_04 startup/shutdown v02.12.00 Update SADMIN section & use env cmd to use proper bash shell.
# 2022_09_15 startup/shutdown v02.13.00 Update SADMIN section 1.52 & minor changes.
# 2023_07_17 startup/shutdown v02.14.00 Update with latest SADMIN section(v1.56).
#@2024_05_02 startup/shutdown v02.15.00 Send shutdown email if 'SADM_EMAIL_SHUTDOWN' = "Y" in sadmin.cfg.
#@2025_03_25 startup/shutdown v02.16.00 Change format of shutdown email sent to sysadmin.
#@2026_03_10 startup/shutdown v02.17.00 Not appending the log 'SADM_LOG_APPEND="N"' (Create a new one).
#@2026_07_08 startup/shutdown v02.17.01 Create Email Body text file to use sendmail 
#@2026_07_09 startup/shutdown v02.17.02 Add 'uptime' and 'who-u' in the email sent to SADMIN admin.
#@2026_07_09 startup/shutdown v02.17.03 Add more info in Email sent to SADMIN admin.
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPT ^C
#set -x


# ---------   S T A R T   O F   S A D M I N   R E Q U I R E D   C O D E   S E C T I O N  -----------
# v1.60 - Setup Global Variables and load the SADMIN standard library $SADMIN/lib/sadmlib_std.sh.
#       - To use SADMIN scripting tools, this section MUST be present near the top of your code.    
#
# Make sure environment variable 'SADMIN' is defined, if it's not, exit with error message.
if [ -r /etc/environment ] && [ -z "$SADMIN" ] ; then source /etc/environment ; fi 
if [ -z "$SADMIN" ]                                        # Advise user, SADMIN Env. Var. is a MUST
   then printf "\n[ ERROR ] Set 'SADMIN' environment variable to the install directory." 
        printf "\n  - Add a line similar to 'SADMIN=/opt/sadmin' in /etc/environment." 
        exit 1 
fi 
if [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]                   # If SADMIN shell library doesn't exist 
   then printf "\n[ ERROR ] SADMIN library '$SADMIN/lib/sadmlib_std.sh' can't be found.\n" ; exit 1 
fi 


# SADMIN Section of your program that is shared with SADMIN Bash Library.
export SADM_TPID="$$"                                      # Script Process ID.
export SADM_HOSTNAME=$(hostname -s)                        # Host name without Domain Name
export SADM_OS_TYPE=$(uname -s|tr '[:lower:]' '[:upper:]') # Return LINUX,AIX,DARWIN,SUNOS 
export SADM_USERNAME=$(id -un)                             # Current user name.
export SADM_DEBUG=0                                        # Debug Level(0-9), 0 = NoDebug
export SADM_EXIT_CODE=0                                    # Pgm. Default Exit Code
export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} "   # SSH CMD to Access Systems
export SADM_PN=${0##*/}                                    # Script name(with extension)
export SADM_INST=$(echo "$SADM_PN" |cut -d'.' -f1)         # Script name(without extension)

export SADM_VER='02.17.03'                                 # Script version number
export SADM_PDESC="Executed when the system is brought down by the 'sadmin.service'."
export SADM_ROOT_ONLY="Y"                                  # Pgm. run only by root ? [Y] or [N]
export SADM_SERVER_ONLY="N"                                # Pgm. run only on SADMIN server? [Y]/[N]
export SADM_GROUP_ONLY='N'                            # Pgm. run only if usr part of SADMIN Grp
export SADM_MULTIPLE_EXEC="N"                              # Can Run Simultaneous copy of script Y/N
export SADM_LOG_TYPE="B"                                   # Write log to [S]creen, [L]og, [B]oth
export SADM_LOG_APPEND="N"                                 # Append log ? Y=AppendLog,N=CreateNewLog
export SADM_LOG_HEADER="Y"                                 # Y = ProduceLogHeader, N = NoLogHeader
export SADM_LOG_FOOTER="Y"                                 # Y = ProduceLogFooter, N = NoLogFooter
export SADM_USE_RCH="Y"                                    # Update the RCH History File (Y/N)
export SADM_QUIET="N"                                      # Y=HideMsg & Error#  N=Show Msg & Error#
export SADM_ERRMSG=""                                      # Error Message returned by Library 
export SADM_ERRNO=0                                        # Error number (0=OK) returned by Library
export SADM_PID_TIMEOUT=7200                               # Sec. before PID file is remove,7200=2hr
export SADM_LOCK_TIMEOUT=3600                              # Sec. before System LockFile is Del, 1hr
export SADM_DB_USED="N"                                    # Use or Not, Got to be on SADMIN server
export SADM_DB_NAME="sadmin"                               # Database Name SADM_DBNAME in sadmin.cfg
export SADM_TMP_FILE1=$(mktemp -q "$SADMIN/tmp/sadm_tmp1_XXX") # Make tmpfile1, rm in sadm_stop()
export SADM_TMP_FILE2=$(mktemp -q "$SADMIN/tmp/sadm_tmp2_XXX") # Make tmpfile2, rm in sadm_stop()
export SADM_TMP_FILE3=$(mktemp -q "$SADMIN/tmp/sadm_tmp3_XXX") # Make tmpfile3, rm in sadm_stop()

# Load SADMIN Bash Shell Library, ready to  be used.
. "${SADMIN}/lib/sadmlib_std.sh"                           # Init SADMIN tools, load cfg files

# Example of some functions and variable you can use.
export SADM_OS_NAME=$(sadm_get_osname)                     # REDHAT,ROCKY,ALMA,CENTOS,DEBIAN,UBUNTU.
export SADM_OS_VERSION=$(sadm_get_osversion)               # O/S Full Ver.No. (ex: 9.5)
export SADM_OS_MAJORVER=$(sadm_get_osmajorversion)         # O/S Major Ver. No. (ex: 9)

# Variables Below Are Taken From SADMIN Configuration File (sadmin.cfg) when the Library is loaded.
# You Can Overridde them On A Per Program Basis (If Needed).
#export SADM_ALERT_TYPE=1                                   # 0=NoAlert 1=OnError 2=OnOK 3=Always
#export SADM_ALERT_GROUP="default"                          # Error Group Define in alert_group.cfg
#export SADM_WARNING_GROUP="default"                        # Warning Alert Group (alert_group.cfg)   
#export SADM_INFO_GROUP="default"                           # Info Alert Group (in alert_group.cfg)
#export SADM_ALERT_REPEAT=0                                 # 0=No Alert Repeat, Sec. between Repeat
#export SADM_MAIL_ADDR="your_email@domain.com"              # Send email to...default in sadmin.cfg
#export SADM_MAX_LOGLINE=400                                # Nb of Lines to trim (0=NoTrim)
#export SADM_MAX_RCHLINE=35                                 # Nb of Lines to trim (0=NoTrim)
# -------------------  E N D   O F   S A D M I N   C O D E    S E C T I O N  -----------------------

#



# Send email when the system goes offline.
# --------------------------------------------------------------------------------------------------
shutdown_mail()
{
    sadm_write_log " "
    sadm_write_log "Send shutdown email to $SADM_MAIL_ADDR"

    # Create the Body of email in a text file 
    wb="$SADMIN/tmp/body$$$.txt"                                        # Email body txt file
    echo -e "$(date)"  > $wb
    echo -e "For your information, system '${SADM_HOSTNAME}' is going down." >> $wb
    echo -e "The program '${SADM_PN}' is reponsable for sending this email." >> $wb

    echo -e "\n\nUptime          : \n$(uptime)\n" >> $wb
    echo -e "\n\nLast Reboot     :\n$(last reboot | head -3)\n" >> $wb
    echo -e "\n\Users on system  : \n$(w)\n" >> $wb
    echo -e "\n\Hardware or kernel errors prior to power down : \n$(dmesg -l err)\n" >> $wb
    echo -e "\n\listening ports  : \n$(ss -tnul)\n" >> $wb
    echo -e "\n\Top 10 processes : \n$(ps -eo pid,ppid,cmd,%cpu,%mem --sort=-%cpu | head -n 11)\n" >> $wb
    
    echo -e "\nHave a nice day !\n" >> $wb
    ws="SADM_INFO: System '$SADM_HOSTNAME' going down." 
    we="$SADM_MAIL_ADDR"
    sadm_sendmail "$we" "$ws" "$wb" 
    RC=$?
    if [ $RC -eq 0 ] 
        then sadm_write_log "[ OK ] Mail sent successfully to $we"
        else sadm_write_err "[ ERROR ] Problem sending email to $we" 
    fi 

    if [ -f  "$wb" ] ; then rm -f "$wb" ; fi                            # Remove body file
    return $RC 
}

# --------------------------------------------------------------------------------------------------
#                                S c r i p t    M a i n     P r o c e s s
# --------------------------------------------------------------------------------------------------
main_process()
{
    sadm_write_log "*** Running SADM System Shutdown Script on $(sadm_get_fqdn)  ***"
    ERROR_COUNT=0

    # Special Operation for some particular System
    sadm_write_log " "
    sadm_write_log "Shutdown procedure for $SADM_HOSTNAME"
    case "$SADM_HOSTNAME" in
        "myhost" )  sadm_write_log "Stop MyApp Web Server ..."
                    /myapp/bin/stop_httpd.sh >> $SADM_LOG 2>&1
                    if [ $? -ne 0 ] 
                        then sadm_write_err "  [ ERROR ] Stopping Web Server ..." 
                             (($ERROR_COUNT+1))
                    fi  
                    ;;



                *)  sadm_write_log "  No particular shutdown procedure needed for '$SADM_HOSTNAME'."
                    ;;

    esac

    sadm_write_log " "

    if [ "$SADM_EMAIL_SHUTDOWN" = "Y" ] 
        then shutdown_mail    
             if [ $? -ne 0 ] ; then ((ERROR_COUNT++)) ; fi
             sleep 10                                                   # Give time to send email   
    fi     
    
    return $ERROR_COUNT                                                 # Return Default return code
}



# --------------------------------------------------------------------------------------------------
# 	                          	S T A R T   O F   M A I N    P R O G R A M
# --------------------------------------------------------------------------------------------------
#
    sadm_start                                                          # Won't come back if error
    main_process                                                        # Main Process
    SADM_EXIT_CODE=$?                                                   # Save Process Exit Code
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
