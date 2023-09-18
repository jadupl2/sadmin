#! /usr/bin/env bash
# --------------------------------------------------------------------------------------------------
#   Author   :  Jacques Duplessis
#   Title    :  sadm_fetch_servers.sh
#   Synopsis :  Rsync all *.rch/*.log/*.rpt files from all active SADMIN client to the SADMIN Server
#   Version  :  1.0
#   Date     :  December 2015
#   Requires :  sh
#   SCCS-Id. :  @(#) sadm_fetch_servers.sh 1.0 2015.09.06
# --------------------------------------------------------------------------------------------------
# Change Log
# 2016_12_12 server v1.6 Major changes to include ssh test to each server and alert when not working
# 2017_02_09 server v1.8 Change Script name and change SADM server default crontab
# 2017_04_04 server v1.9 Cosmetic - Remove blank lines inside processing servers
# 2017_07_07 server v2.0 Remove Ping before doing the SSH to each server (Not really needed)
# 2017_07_20 server v2.1 When Error Detected - The Error is included at the top of Email (Simplify Diag)
# 2017_08_03 server v2.2 Minor Bug Fix
# 2017_08_24 server v2.3 Rewrote section of code & Message more concise
# 2017_08_29 server v2.4 Bug Fix - Corrected problem when retrying rsync when failed
# 2017_08_30 server v2.5 If SSH test to server fail, try a second time (Prevent false Error)
# 2017_12_17 server v2.6 Modify to use MySQL instead of PostGres
# 2018_02_08 server v2.8 Fix compatibility problem with 'dash' shell
# 2018_02_10 server v2.9 Rsync on SADMIN server (locally) is not using ssh
# 2018_04_05 server v2.10 Do not copy web Interface crontab from backup unless file exist
# 2018_05_06 server v2.11 Remove URL from Email when Error are detecting while fetching data
# 2018_05_06 server v2.12 Small Modification for New Libr Version
# 2018_06_29 server v2.13 Use SADMIN Client Dir in Database instead of assuming /sadmin as root dir
# 2018_07_08 server v2.14 O/S Update crontab file is recreated and updated if needed at end of script.
# 2018_07_14 server v2.15 Fix Problem Updating O/S Update crontab when running with the dash shell.
# 2018_07_21 server v2.16 Give Explicit Error when cannot connect to Database
# 2018_07_27 server v2.17 O/S Update Script will store each server output log in $SADMIN/tmp for 7 days.
# 2018_08_08 server v2.18 Server not responding to SSH wasn't include in O/S update crontab,even active
# 2018_09_14 server v2.19 Alert are now send to Production Alert Group (sprod-->Slack Channel sadm_prod)
# 2018_09_18 server v2.20 Alert Minors fixes
# 2018_09_26 server v2.21 Include Subject Field in Alert and Add Info field from SysMon
# 2018_09_26 server v2.22 Reformat Error message for alerting system
# 2018_10_04 server v2.23 Supplemental message about o/s update crontab modification
# 2018_11_28 server v2.24 Added Fetch to MacOS Client 
# 2018_12_30 server v2.25 Problem updating O/S Update crontab when some MacOS clients were used.
# 2018_12_30 server v2.26 - Diminish alert while system reboot after O/S Update.
# 2019_01_05 server v2.27 - Using sudo to start o/s update in cron file.
# 2019_01_11 server v2.28 - Now update sadm_backup crontab when needed.
# 2019_01_12 server v2.29 - Now update Backup List and Exclude on Clients.
# 2019_01_18 server v2.30 - Fix O/S Update crontab generation.
# 2019_01_26 server v2.31 Add to test if crontab file exist, when run for first time.
# 2019_02_19 server v2.32 Copy script rch file in global dir after each run.
# 2019_04_12 server v2.33 Create Web rch directory, if not exist when script run for the first time.
# 2019_04_17 server v2.34 Show Processing message only when active servers are found.
# 2019_05_07 server v2.35 Change Send Alert parameters for Library 
# 2019_05_23 server v2.36 Updated to use SADM_DEBUG instead of Local Variable DEBUG_LEVEL
# 2019_06_06 server v2.37 Fix problem sending alert when SADM_ALERT_TYPE was set 2 or 3.
# 2019_06_07 server v2.38 An alert status summary of all systems is displayed at the end.
# 2019_06_19 server v2.39 Cosmetic change to alerts summary and alert subject.
# 2019_07_12 server v3.00 Fix script path for backup and o/s update in respective crontab file.
# 2019_07_24 server v3.1 Major revamp of code.
# 2019_08_23 server v3.2 Remove Crontab work file (Cleanup)
# 2019_08_29 server v3.3 Correct problem with CR in site.conf 
# 2019_08_31 server v3.4 More compact alert email subject.
# 2019_12_01 server v3.5 Backup crontab will backup daily not to miss weekly,monthly and yearly.
# 2020_01_12 server v3.6 Compact log produced by the script.
# 2020_01_14 server v3.7 Don't use SSH when running daily backup and ReaR Backup for SADMIN server. 
# 2020_02_19 server v3.8 Restructure & Create an Alert when can't SSH to client. 
# 2020_03_21 server v3.9 SSH error to client were not reported in System Monitor.
# 2020_05_05 server v3.10 Temp. file was not remove under certain circumstance.
# 2020_05_13 server v3.11 Move processing command line switch to a function.
# 2020_05_22 server v3.12 No longer report an error, if a system is rebooting because of O/S update.
# 2020_07_20 server v3.13 Change email to have success or failure at beginning of subject.
# 2020_07_29 server v3.14 Move location of o/s update is running indicator file to $SADMIN/tmp.
# 2020_09_05 server v3.15 Minor Bug fix, Alert Msg now include Start/End?Elapse Script time
# 2020_09_09 server v3.16 Modify Alert message when client is down.
# 2020_10_29 server v3.17 If comma was used in server description, it cause delimiter problem.
# 2020_11_04 server v3.18 Reduce time allowed for O/S update to 1800sec. (30Min) & keep longer log.
# 2020_11_05 server v3.19 Change msg written to log & no alert while o/s update is running.
# 2020_11_24 server v3.20 Optimize code & Now calling new 'sadm_osupdate_starter' for o/s update.
# 2020_12_02 server v3.21 New summary added to the log and Misc. fix.
# 2020_12_12 server v3.22 Copy Site Common alert group and slack configuration files to client
# 2020_12_19 server v3.23 Don't copy alert group and slack configuration files, when on SADMIN Server.
# 2020_12_19 server v3.24 Remove verbose on rsync
# 2021_04_19 server v3.25 Change Include text in ReaR Config file.
# 2021_05_10 nolog  v3.26 Error message change "sadm_osupdate_farm.sh" to "sadm_osupdate_starter"
# 2021_06_06 server v3.27 Change generation of /etc/cron.d/sadm_osupdate to use $SADMIN variable.
# 2021_06_11 server v3.28 Collect system uptime and store it in DB and update SADMIN section 
# 2021_07_19 server v3.29 Sleep 5 seconds between rsync retries, if first failed.
# 2021_08_17 server v3.30 Performance improvement et code restructure
# 2021_08_27 server v3.31 Increase ssh connection Timeout "-o ConnectTimeout=3".
# 2021_10_20 server v3.32 Remove syncing of depreciated file 'alert_slack.cfg'. 
# 2021_11_15 server v3.33 Fix type error on comment line
# 2022_04_19 server v3.34 Minor fix and performance improvements.
# 2022_05_12 server v3.35 Move 'sadm_send_alert()' & 'write_alert_history()' functions from library.
# 2022_05_19 server v3.36 Added 'chown' and 'chmod' for log and rch files and directories.
# 2022_06_01 server v3.37 Create 'rpt' and 'rch' directories in $SADMIN/www/dat if do not exist.
# 2022_06_13 server v3.38 Update to use 'sadm_sendmail()' instead of 'mutt' manually.
# 2022_06_14 server v3.39 Email alert will now send script AND error log.
# 2022_06_15 server v3.40 Fix problem when 2 attachments or more were send with sadm_sendmail()
# 2022_07_01 server v3.41 Fix error updating crontab.
# 2022_07_09 server v3.42 Updated to use new SADMIN section v1.52.
# 2022_07_14 server v3.43 Change group to '$SADM_GROUP' in $SADMIN/www/dat (fix web ui problem).
# 2022_09_29 server v3.44 Daily backup, check new web option to compress backup or not.
#@2023_07_18 server v3.45 Fix problem when not using the standard ssh port (22) for some clients.
#@2023_09_18 server v3.46 Old file *.nmon was not clean up properly.
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPT the ^C
#set -x




# ------------------- S T A R T  O F   S A D M I N   C O D E    S E C T I O N  ---------------------
# v1.56 - Setup for Global Variables and load the SADMIN standard library.
#       - To use SADMIN tools, this section MUST be present near the top of your code.    

# Make Sure Environment Variable 'SADMIN' Is Defined.
if [ -z "$SADMIN" ] || [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]            # SADMIN defined? Libr.exist
    then if [ -r /etc/environment ] ; then source /etc/environment ;fi  # LastChance defining SADMIN
         if [ -z "$SADMIN" ] || [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]   # Still not define = Error
            then printf "\nPlease set 'SADMIN' environment variable to the install directory.\n"
                 exit 1                                                 # No SADMIN Env. Var. Exit
         fi
fi 

# YOU CAN USE THE VARIABLES BELOW, BUT DON'T CHANGE THEM (Used by SADMIN Standard Library).
export SADM_PN=${0##*/}                                    # Script name(with extension)
export SADM_INST=$(echo "$SADM_PN" |cut -d'.' -f1)         # Script name(without extension)
export SADM_TPID="$$"                                      # Script Process ID.
export SADM_HOSTNAME=$(hostname -s)                        # Host name without Domain Name
export SADM_OS_TYPE=$(uname -s |tr '[:lower:]' '[:upper:]') # Return LINUX,AIX,DARWIN,SUNOS 
export SADM_USERNAME=$(id -un)                             # Current user name.

# YOU CAB USE & CHANGE VARIABLES BELOW TO YOUR NEEDS (They influence execution of SADMIN Library).
export SADM_VER='3.46'                                     # Script version number
export SADM_PDESC="Collect scripts results & SysMon status from all systems and send alert if needed." 
export SADM_ROOT_ONLY="Y"                                  # Run only by root ? [Y] or [N]
export SADM_SERVER_ONLY="Y"                                # Run only on SADMIN server? [Y] or [N]
export SADM_EXIT_CODE=0                                    # Script Default Exit Code
export SADM_LOG_TYPE="B"                                   # Log [S]creen [L]og [B]oth
export SADM_LOG_APPEND="N"                                 # Y=AppendLog, N=CreateNewLog
export SADM_LOG_HEADER="Y"                                 # Y=ProduceLogHeader N=NoHeader
export SADM_LOG_FOOTER="Y"                                 # Y=IncludeFooter N=NoFooter
export SADM_MULTIPLE_EXEC="N"                              # Run Simultaneous copy of script
export SADM_USE_RCH="Y"                                    # Update RCH History File (Y/N)
export SADM_DEBUG=0                                        # Debug Level(0-9) 0=NoDebug
export SADM_TMP_FILE1=$(mktemp "$SADMIN/tmp/${SADM_INST}1_XXX") 
export SADM_TMP_FILE2=$(mktemp "$SADMIN/tmp/${SADM_INST}2_XXX") 
export SADM_TMP_FILE3=$(mktemp "$SADMIN/tmp/${SADM_INST}3_XXX") 

# LOAD SADMIN SHELL LIBRARY AND SET SOME O/S VARIABLES.
. "${SADMIN}/lib/sadmlib_std.sh"                           # Load SADMIN Shell Library
export SADM_OS_NAME=$(sadm_get_osname)                     # O/S Name in Uppercase
export SADM_OS_VERSION=$(sadm_get_osversion)               # O/S Full Ver.No. (ex: 9.0.1)
export SADM_OS_MAJORVER=$(sadm_get_osmajorversion)         # O/S Major Ver. No. (ex: 9)
#export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} "   # SSH CMD to Access Systems

# VALUES OF VARIABLES BELOW ARE LOADED FROM SADMIN CONFIG FILE ($SADMIN/cfg/sadmin.cfg)
# BUT THEY CAN BE OVERRIDDEN HERE, ON A PER SCRIPT BASIS (IF NEEDED).
#export SADM_ALERT_TYPE=1                                   # 0=No 1=OnError 2=OnOK 3=Always
#export SADM_ALERT_GROUP="default"                          # Alert Group to advise
#export SADM_MAIL_ADDR="your_email@domain.com"              # Email to send log
#export SADM_MAX_LOGLINE=500                                # Nb Lines to trim(0=NoTrim)
#export SADM_MAX_RCLINE=35                                  # Nb Lines to trim(0=NoTrim)
#export SADM_PID_TIMEOUT=7200                               # Sec. before PID Lock expire
#export SADM_LOCK_TIMEOUT=3600                              # Sec. before Del. System LockFile
# --------------- ---  E N D   O F   S A D M I N   C O D E    S E C T I O N  -----------------------






#===================================================================================================
# Scripts Variables 
#===================================================================================================
#
export REAR_TMP="${SADMIN}/tmp/rear_site.tmp$$"                         # New ReaR site.conf tmp file
export REAR_CFG="${SADMIN}/tmp/rear_site.cfg$$"                         # Will be new /etc/site.conf
export FETCH_RPT_LOCAL="${SADM_RPT_DIR}/${SADM_HOSTNAME}_fetch.rpt"     # SADMIN Server Local RPT
export FETCH_RPT_GLOBAL="${SADM_WWW_DAT_DIR}/${SADM_HOSTNAME}/rpt/${SADM_HOSTNAME}_fetch.rpt" 
export REBOOT_SEC=900                                                   # O/S Upd Reboot Nb Sec.wait
export RCH_FIELD=10                                                     # Nb. of field on rch file.
export OSTIMEOUT=1800                                                   # 1800sec=30Min todo O/S Upd
export GLOB_UPTIME=""                                                   # Global Server uptime value 
export BOOT_DATE=""                                                     # Server Last Boot Date/Time
export ERROR_COUNT=0                                                    # Rsync Error Count
export SADM_TEN_DASH=`printf %10s |tr " " "-"`                          # 10 dashes line
#
# Variables used to insert in /etc/cron.d/sadm* crontab files.
export OS_SCRIPT="sadm_osupdate_starter.sh"                             # OSUpdate Script in crontab
export BA_SCRIPT="sadm_backup.sh"                                       # Backup Script 
export REAR_SCRIPT="sadm_rear_backup.sh"                                # ReaR Backup Script 
#
# Reset Alert Totals Counters
export total_alert=0 total_duplicate=0 total_ok=0 total_error=0 total_oldies=0
#
# Reset Alert Totals Counters
export t_alert=0 t_duplicate=0 t_ok=0 t_error=0 t_oldies=0




# --------------------------------------------------------------------------------------------------
# H E L P      U S A G E   D I S P L A Y    F U N C T I O N
# --------------------------------------------------------------------------------------------------
show_usage()
{
    printf "\nUsage: %s%s%s%s [options]" "${BOLD}" "${CYAN}" $(basename "$0") "${NORMAL}"
    printf "\nDesc.: %s" "${BOLD}${CYAN}${SADM_PDESC}${NORMAL}"
    printf "\n\n${BOLD}${GREEN}Options:${NORMAL}"
    printf "\n   ${BOLD}${YELLOW}[-d 0-9]${NORMAL}\t\tSet Debug (verbose) Level"
    printf "\n   ${BOLD}${YELLOW}[-h]${NORMAL}\t\t\tShow this help message"
    printf "\n   ${BOLD}${YELLOW}[-v]${NORMAL}\t\t\tShow script version information"
    printf "\n\n" 
}



# ==================================================================================================
# Update the crontab work file based on the parameters received
#
# (1) cserver   Name odf server to update the o/s/
# (2) cscript   The name of the script to executed
# (3) cmin      Minute when the update will begin (00-59)
# (4) chour     Hour when the update should begin (00-23)
# (5) cmonth    13 Characters (either a Y or a N) each representing a month (YNNNNNNNNNNNN)
#               Position 0 = Y Then ALL Months are Selected
#               Position 1-12 represent the month that are selected (Y or N)             
#               Default is YNNNNNNNNNNNN meaning will run every month 
# (6) cdom      32 Characters (either a Y or a N) each representing a day (1-31) Y=Update N=No Update
#               Position 0 = Y Then ALL Date in the month are Selected
#               Position 1-31 Indicate (Y) date of the month that script will run or not (N)
# (7) cdow      8 Characters (either a Y or a N) 
#               If Position 0 = Y then will run every day of the week
#               Position 1-7 Indicate a week day () Starting with Sunday
#               Default is all Week (YNNNNNNN)
# (8)           SSH port to communicate with the system
# ---------
# Example of line generated
# 15 04 * * 06 root /sadmin/bin/sadm_osupdate_starter.sh nano >/dev/null 2>&1
# ==================================================================================================
update_osupdate_crontab () 
{
    cserver=$1                                                          # Server Name (NOT FQDN)
    cscript=$2                                                          # Update Script to Run
    cmin=$3                                                             # Crontab Minute
    chour=$4                                                            # Crontab Hour
    cmonth=$5                                                           # Crontab Mth (YNNNN) Format
    cdom=$6                                                             # Crontab DOM (YNNNN) Format
    cdow=$7                                                             # Crontab DOW (YNNNN) Format
    SSH_PORT=$8

    # To Display Parameters received - Used for Debugging Purpose ----------------------------------
    if [ $SADM_DEBUG -gt 5 ] 
        then sadm_writelog "I'm in update crontab"
             sadm_writelog "cserver  = $cserver"                        # Server to run script
             sadm_writelog "cscript  = $cscript"                        # Script to execute
             sadm_writelog "cmonth   = $cmonth"                         # Month String YNYNYNYNYNY..
             sadm_writelog "cdom     = $cdom"                           # Day of MOnth String YNYN..
             sadm_writelog "cdow     = $cdow"                           # Day of Week String YNYN...
             sadm_writelog "chour    = $chour"                          # Hour to run script
             sadm_writelog "cmin     = $cmin"                           # Min. to run Script
             sadm_writelog "cronfile = $SADM_CRON_FILE"                 # Name of Output file
    fi
    
    # Begin constructing our crontab line ($cline) - Based on Hour and Min. Received ---------------
    cline=`printf "%02d %02d" "$cmin" "$chour"`                         # Hour & Min. of Execution
    if [ $SADM_DEBUG -gt 5 ] ; then sadm_writelog "cline=.$cline.";fi  # Show Cron Line Now


    # Construct DATE of the month (1-31) to run and add it to crontab line ($cline) ----------------
    flag_dom=0
    if [ "$cdom" = "YNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN" ]                 # If it's to run every Date
        then cline="$cline *"                                           # Then use a Star for Date
        else fdom=""                                                    # Clear Final Date of Month
             for i in $(seq 2 32)
                do    
                wchar=`expr substr $cdom $i 1`
                if [ $SADM_DEBUG -gt 5 ] ; then echo "cdom[$i] = $wchar" ; fi
                xmth=`expr $i - 1`                                      # Date = Index -1 ,Cron Mth
                if [ "$wchar" = "Y" ]                                   # If Date Set to Yes 
                    then if [ $flag_dom -eq 0 ]                         # If First Date to Run 
                            then fdom=`printf "%02d" "$xmth"`           # Add Date to Final DOM
                                 flag_dom=1                             # No Longer the first date
                            else wdom=`printf "%02d" "$xmth"`           # Format the Date number
                                 fdom=`echo "${fdom},${wdom}"`          # Combine Final+New Date
                         fi
                fi                                                      # If Date is set to No
                done                                                    # End of For Loop
             cline="$cline $fdom"                                       # Add DOM in Crontab Line
    fi
    if [ $SADM_DEBUG -gt 5 ] ; then sadm_writelog "cline=.$cline.";fi  # Show Cron Line Now


    # Construct the month(s) (1-12) to run the script and add it to crontab line ($cline) ----------
    flag_mth=0
    if [ "$cmonth" = "YNNNNNNNNNNNN" ]                                  # 1st Char=Y = run every Mth
        then cline="$cline *"                                           # Then use a Star for Month
        else fmth=""                                                    # Clear Final Date of Month
             for i in $(seq 2 13)                                       # Check Each Mth 2-13 = 1-12
                do                                                      # Get Y or N for the Month 
                wchar=`expr substr $cmonth $i 1`
                xmth=`expr $i - 1`                                      # Mth = Index -1 ,Cron Mth
                if [ "$wchar" = "Y" ]                                   # If Month Set to Yes 
                    then if [ $flag_mth -eq 0 ]                         # If 1st Insert in Cron Line
                            then fmth=`printf "%02d" "$xmth"`           # Add Month to Final Months
                                 flag_mth=1                             # No Longer the first Month
                            else wmth=`printf "%02d" "$xmth"`           # Format the Month number
                                 fmth=`echo "${fmth},${wmth}"`          # Combine Final+New Months
                         fi
                fi                                                      # If Month is set to No
                done                                                    # End of For Loop
             cline="$cline $fmth"                                       # Add Month in Crontab Line
    fi
    if [ $SADM_DEBUG -gt 5 ] ; then sadm_writelog "cline=.$cline.";fi  # Show Cron Line Now


    # Construct the day of the week (0-6) to run the script and add it to crontab line ($cline) ----
    flag_dow=0
    if [ "$cdow" = "YNNNNNNN" ]                                         # 1st Char=Y Run all dayWeek
        then cline="$cline *"                                           # Then use Star for All Week
        else fdow=""                                                    # Final Day of Week Flag
             for i in $(seq 2 8)                                        # Check Each Day 2-8 = 0-6
                do                                                      # Day of the week (dow)
                wchar=`expr substr "$cdow" $i 1`                        # Get Char of loop
                if [ $SADM_DEBUG -gt 5 ] ; then echo "cdow[$i] = $wchar" ; fi
                if [ "$wchar" = "Y" ]                                   # If Day is Yes 
                    then xday=`expr $i - 2`                             # Adjust Indx to Crontab Day
                         if [ $SADM_DEBUG -gt 5 ] ; then echo "xday = $xday" ; fi
                         if [ $flag_dow -eq 0 ]                         # If First Day to Insert
                            then fdow=`printf "%02d" "$xday"`           # Add day to Final Day
                                 flag_dow=1                             # No Longer the first Insert
                            else wdow=`printf "%02d" "$xday"`           # Format the day number
                                 fdow=`echo "${fdow},${wdow}"`          # Combine Final+New Day
                         fi
                fi                                                      # If DOW is set to No
                done                                                    # End of For Loop
             cline="$cline $fdow"                                       # Add DOW in Crontab Line
    fi
    if [ $SADM_DEBUG -gt 5 ] ; then sadm_writelog "cline=.$cline.";fi  # Show Cron Line Now
    
    
    # Add User, script name and script parameter to crontab line -----------------------------------
    # SCRIPT WILL RUN ONLY IF LOCATED IN $SADMIN/BIN 
    # $SADM_TMP_DIR
    #cline="$cline root $cscript -s $cserver >/dev/null 2>&1";   
    cline="$cline $SADM_USER sudo $cscript $cserver >/dev/null 2>&1";   
    #cline="$cline root $cscript -s $cserver > ${SADM_TMP_DIR}/sadm_osupdate_${cserver}.log 2>&1";   
    if [ $SADM_DEBUG -gt 0 ] ; then sadm_writelog "cline=.$cline.";fi  # Show Cron Line Now

    echo "$cline" >> $SADM_CRON_FILE                                    # Output Line to Crontab cfg
}



# ==================================================================================================
# Update the ReaR crontab work file based on the parameters received
#
# (1) cserver   Name odf server to update the o/s/
# (2) cscript   The name of the script to executed
# (3) cmin      Minute when the update will begin (00-59)
# (4) chour     Hour when the update should begin (00-23)
# (5) cmonth    13 Characters (either a Y or a N) each representing a month (YNNNNNNNNNNNN)
#               Position 0 = Y Then ALL Months are Selected
#               Position 1-12 represent the month that are selected (Y or N)             
#               Default is YNNNNNNNNNNNN meaning will run every month 
# (6) cdom      32 Characters (either a Y or a N) each representing a day (1-31) Y=Update N=No Update
#               Position 0 = Y Then ALL Date in the month are Selected
#               Position 1-31 Indicate (Y) date of the month that script will run or not (N)
# (7) cdow      8 Characters (either a Y or a N) 
#               If Position 0 = Y then will run every day of the week
#               Position 1-7 Indicate a week day () Starting with Sunday
#               Default is all Week (YNNNNNNN)
# (8)           SSH port to communicate with the system
# ---------
# Example of line generated
# 15 04 * * 06 root /sadmin/bin/sadm_osupdate_starter.sh nano >/dev/null 2>&1
# ==================================================================================================
update_rear_crontab () 
{
    cserver=$1                                                          # Server Name (NOT FQDN)
    cscript=$2                                                          # Update Script to Run
    cmin=$3                                                             # Crontab Minute
    chour=$4                                                            # Crontab Hour
    cmonth=$5                                                           # Crontab Mth (YNNNN) Format
    cdom=$6                                                             # Crontab DOM (YNNNN) Format
    cdow=$7                                                             # Crontab DOW (YNNNN) Format
    SSH_PORT=$8

    # To Display Parameters received - Used for Debugging Purpose ----------------------------------
    if [ $SADM_DEBUG -gt 5 ] 
        then sadm_writelog "I'm in update crontab"
             sadm_writelog "cserver  = $cserver"                        # Server to run script
             sadm_writelog "cscript  = $cscript"                        # Script to execute
             sadm_writelog "cmonth   = $cmonth"                         # Month String YNYNYNYNYNY..
             sadm_writelog "cdom     = $cdom"                           # Day of MOnth String YNYN..
             sadm_writelog "cdow     = $cdow"                           # Day of Week String YNYN...
             sadm_writelog "chour    = $chour"                          # Hour to run script
             sadm_writelog "cmin     = $cmin"                           # Min. to run Script
             sadm_writelog "cronfile = $SADM_CRON_FILE"                 # Name of Output file
    fi
    
    # Begin constructing our crontab line ($cline) - Based on Hour and Min. Received ---------------
    cline=`printf "%02d %02d" "$cmin" "$chour"`                         # Hour & Min. of Execution
    if [ $SADM_DEBUG -gt 5 ] ; then sadm_writelog "cline=.$cline.";fi  # Show Cron Line Now


    # Construct DATE of the month (1-31) to run and add it to crontab line ($cline) ----------------
    flag_dom=0
    if [ "$cdom" = "YNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN" ]                 # If it's to run every Date
        then cline="$cline *"                                           # Then use a Star for Date
        else fdom=""                                                    # Clear Final Date of Month
             for i in $(seq 2 32)
                do    
                wchar=`expr substr $cdom $i 1`
                if [ $SADM_DEBUG -gt 5 ] ; then echo "cdom[$i] = $wchar" ; fi
                xmth=`expr $i - 1`                                      # Date = Index -1 ,Cron Mth
                if [ "$wchar" = "Y" ]                                   # If Date Set to Yes 
                    then if [ $flag_dom -eq 0 ]                         # If First Date to Run 
                            then fdom=`printf "%02d" "$xmth"`           # Add Date to Final DOM
                                 flag_dom=1                             # No Longer the first date
                            else wdom=`printf "%02d" "$xmth"`           # Format the Date number
                                 fdom=`echo "${fdom},${wdom}"`          # Combine Final+New Date
                         fi
                fi                                                      # If Date is set to No
                done                                                    # End of For Loop
             cline="$cline $fdom"                                       # Add DOM in Crontab Line
    fi
    if [ $SADM_DEBUG -gt 5 ] ; then sadm_writelog "cline=.$cline.";fi  # Show Cron Line Now


    # Construct the month(s) (1-12) to run the script and add it to crontab line ($cline) ----------
    flag_mth=0
    if [ "$cmonth" = "YNNNNNNNNNNNN" ]                                  # 1st Char=Y = run every Mth
        then cline="$cline *"                                           # Then use a Star for Month
        else fmth=""                                                    # Clear Final Date of Month
             for i in $(seq 2 13)                                       # Check Each Mth 2-13 = 1-12
                do                                                      # Get Y or N for the Month  
                wchar=`expr substr $cmonth $i 1`
                xmth=`expr $i - 1`                                      # Mth = Index -1 ,Cron Mth
                if [ "$wchar" = "Y" ]                                   # If Month Set to Yes 
                    then if [ $flag_mth -eq 0 ]                         # If 1st Insert in Cron Line
                            then fmth=`printf "%02d" "$xmth"`           # Add Month to Final Months
                                 flag_mth=1                             # No Longer the first Month
                            else wmth=`printf "%02d" "$xmth"`           # Format the Month number
                                 fmth=`echo "${fmth},${wmth}"`          # Combine Final+New Months
                         fi
                fi                                                      # If Month is set to No
                done                                                    # End of For Loop
             cline="$cline $fmth"                                       # Add Month in Crontab Line
    fi
    if [ $SADM_DEBUG -gt 5 ] ; then sadm_writelog "cline=.$cline.";fi  # Show Cron Line Now


    # Construct the day of the week (0-6) to run the script and add it to crontab line ($cline) ----
    flag_dow=0
    if [ "$cdow" = "YNNNNNNN" ]                                         # 1st Char=Y Run all dayWeek
        then cline="$cline *"                                           # Then use Star for All Week
        else fdow=""                                                    # Final Day of Week Flag
             for i in $(seq 2 8)                                        # Check Each Day 2-8 = 0-6
                do                                                      # Day of the week (dow)
                wchar=`expr substr "$cdow" $i 1`                        # Get Char of loop
                if [ $SADM_DEBUG -gt 5 ] ; then echo "cdow[$i] = $wchar" ; fi
                if [ "$wchar" = "Y" ]                                   # If Day is Yes 
                    then xday=`expr $i - 2`                             # Adjust Indx to Crontab Day
                         if [ $SADM_DEBUG -gt 5 ] ; then echo "xday = $xday" ; fi
                         if [ $flag_dow -eq 0 ]                         # If First Day to Insert
                            then fdow=`printf "%02d" "$xday"`           # Add day to Final Day
                                 flag_dow=1                             # No Longer the first Insert
                            else wdow=`printf "%02d" "$xday"`           # Format the day number
                                 fdow=`echo "${fdow},${wdow}"`          # Combine Final+New Day
                         fi
                fi                                                      # If DOW is set to No
                done                                                    # End of For Loop
             cline="$cline $fdow"                                       # Add DOW in Crontab Line
    fi
    if [ $SADM_DEBUG -gt 5 ] ; then sadm_writelog "cline=.$cline.";fi  # Show Cron Line Now
    
    
    # Add User, script name and script parameter to crontab line -----------------------------------
    # SCRIPT WILL RUN ONLY IF LOCATED IN $SADMIN/BIN 
    # $SADM_TMP_DIR
    if [ "$SADM_HOSTNAME" != "$cserver" ]  
        then cline="$cline $SADM_USER sudo ${SADM_SSH} -qnp $SSH_PORT $cserver \"$cscript\" >/dev/null 2>&1";
        else cline="$cline $SADM_USER sudo \"$cscript\" >/dev/null 2>&1";
    fi 
    if [ $SADM_DEBUG -gt 0 ] ; then sadm_writelog "cline=.$cline.";fi  # Show Cron Line Now

    echo "$cline" >> $SADM_REAR_NEWCRON                               # Output Line to Crontab cfg
}





# ==================================================================================================
# Update the crontab work file based on the parameters received
#
# (1) cserver   Name odf server to backup
# (2) cscript   The name of the script to executed
# (3) cmin      Minute when the update will begin (00-59)
# (4) chour     Hour when the update should begin (00-23)
# (5) cmonth    13 Characters (either a Y or a N) each representing a month (YNNNNNNNNNNNN)
#               Position 0 = Y Then ALL Months are Selected
#               Position 1-12 represent the month that are selected (Y or N)             
#               Default is YNNNNNNNNNNNN meaning will run every month 
# (6) cdom      32 Characters (either a Y or a N) each representing a day (1-31) Y=Update N=No Update
#               Position 0 = Y Then ALL Date in the month are Selected
#               Position 1-31 Indicate (Y) date of the month that script will run or not (N)
# (7) cdow      8 Characters (either a Y or a N) 
#               If Position 0 = Y then will run every day of the week
#               Position 1-7 Indicate a week day () Starting with Sunday
#               Default is all Week (YNNNNNNN)
# (8)           SSH port to communicate with the system
# ---------
# Example of line generated
# 15 04 * * 06 root /sadmin/bin/sadm_osupdate_starter.sh nano >/dev/null 2>&1
# ==================================================================================================
update_backup_crontab () 
{
    cserver=$1                                                          # Server Name (NOT FQDN)
    cscript=$2                                                          # Update Script to Run
    cmin=$3                                                             # Crontab Minute
    chour=$4                                                            # Crontab Hour
    cmonth=$5                                                           # Crontab Mth (YNNNN) Format
    cdom=$6                                                             # Crontab DOM (YNNNN) Format
    cdow=$7                                                             # Crontab DOW (YNNNN) Format
    SSH_PORT=$8                                                         # SSH Port Number 
    ccompress=$9                                                        # Compress Backup 1=Yes 0=No

    cline=`printf "%02d %02d" "$cmin" "$chour"`                         # Hour & Min. of Execution
    if [ $SADM_DEBUG -gt 5 ] ; then sadm_writelog "cline=.$cline.";fi   # Show Cron Line Now
    cline="$cline * * * "
    if [ "$SADM_HOSTNAME" != "$cserver" ]  
        then if [ $ccompress -eq 1 ] 
                then cline="$cline $SADM_USER sudo ${SADM_SSH} -qnp $SSH_PORT $cserver \"$cscript\" >/dev/null 2>&1";
                else cline="$cline $SADM_USER sudo ${SADM_SSH} -qnp $SSH_PORT $cserver \"$cscript -n\" >/dev/null 2>&1";
             fi                 
        else if [ $ccompress -eq 1 ]
                then cline="$cline $SADM_USER sudo \"$cscript\" >/dev/null 2>&1"; 
                else cline="$cline $SADM_USER sudo \"$cscript -n\" >/dev/null 2>&1"; 
             fi 
    fi 
    echo "$cline" >> $SADM_BACKUP_NEWCRON                               # Output Line to Crontab cfg
}



#===================================================================================================
# Generic rsync function, use to collect client files (*.rpt,*.log,*.rch,) 
# rsync remote SADM client with local directories
# 
# Input Parameters :
#   1) Remote Directory to sync with 
#       Format : "${fqdn_server}:${RDIR}/"  
#   2) Local Destination directory
#       Format : "${LDIR}/"
#
# Return Value : 
#   0) Rsync with Success
#   1) Rsync failed.
#===================================================================================================
rsync_function()
{
    # Parameters received should always by two - If not write error to log and return to caller
    if [ $# -ne 2 ]
        then sadm_writelog "Error: Function ${FUNCNAME[0]} didn't receive 2 parameters."
             sadm_writelog "Function received $* and this isn't valid."
             sadm_writelog "Should receive remote directory path and the local directory path." 
             sadm_writelog "The two parameters must both end with a '/' (Important)." 
             return 1
    fi

    # Save rsync information
    REMOTE_DIR=$1                                                       # user@host:remote directory
    LOCAL_DIR=$2                                                        # Local Directory

    # If Local directory doesn't exist create it 
    if [ ! -d "${LOCAL_DIR}" ] ; then mkdir -p ${LOCAL_DIR} ; chmod 2775 ${LOCAL_DIR} ; fi

    # Rsync remote directory on local directory - On error try 3 times before signaling error
    RETRY=0                                                             # Set Retry counter to zero
    while [ $RETRY -lt 3 ]                                              # Retry rsync 3 times
        do
        RETRY=`expr $RETRY + 1`                                         # Incr Retry counter.
        rsync -ar -e "ssh -p $ssh_port" --delete ${REMOTE_DIR} ${LOCAL_DIR} >/dev/null 2>&1  # rsync selected directory
        RC=$?                                                           # save error number

        # Consider Error 24 as none critical (Partial transfer due to vanished source files)
        if [ $RC -eq 24 ] ; then RC=0 ; fi                              # Source File Gone is OK

        if [ $RC -ne 0 ]                                                # If Error doing rsync
           then if [ $RETRY -lt 3 ]                                     # If less than 3 retry
                   then sleep 5                                        # Sleep 5Sec. between retries
                        sadm_writelog "[ RETRY $RETRY ] rsync -ar -e "ssh -p $ssh_port" --delete ${REMOTE_DIR} ${LOCAL_DIR}"
                   else sadm_writelog "$SADM_ERROR [ $RETRY ] rsync -ar -e "ssh -p $ssh_port" --delete ${REMOTE_DIR} ${LOCAL_DIR}"
                        break
                fi
           else sadm_writelog "$SADM_OK rsync -ar -e "ssh -p $ssh_port" --delete ${REMOTE_DIR} ${LOCAL_DIR}"
                break
        fi
    done
    #sadm_writelog "chmod 775 ${LOCAL_DIR}" 
    chmod 775 ${LOCAL_DIR}  >> $SADM_LOG 2>&1
    #sadm_writelog "chmod 664 ${LOCAL_DIR}*" 
    chmod 664 ${LOCAL_DIR}* >> $SADM_LOG 2>&1
    return $RC
}




# --------------------------------------------------------------------------------------------------
# Process Operating System received in parameter (aix/linux,darwin)
# --------------------------------------------------------------------------------------------------
update_rear_site_conf()
{
    WSERVER=$1 

    # Build name of the client footer of modified Rear exclude file (Via Web Interface)
    REAR_USER_EXCLUDE="${SADM_WWW_DAT_DIR}/${WSERVER}/cfg/rear_exclude.tmp"     

    # If client did not modified the ReaR Exclude option file, then do nothing & return to caller.
    if [ ! -r "$REAR_USER_EXCLUDE" ] ; then return 0 ; fi
    
    # Start creating a new ReaR site.conf file into a temp. file for now.
    echo  "#${SADM_DASH}" > $REAR_TMP
    echo  "# This file have generated on `date '+%C%y.%m.%d %H:%M:%S'` by 'sadm_fetch_clients.sh'." >> $REAR_TMP
    echo  "# Every time you modify the '${WSERVER}' ReaR backup or ReaR backup exclude list, "  >> $REAR_TMP
    echo  "# your changes are copied from the sadmin server ($SADM_SERVER) to ${WSERVER} shortly after (Max 5min). " >> $REAR_TMP
    echo  "#${SADM_DASH}" >> $REAR_TMP
    echo  "# " >> $REAR_TMP
    echo  "# " >> $REAR_TMP
    echo  "# Create a bootable ISO9660 image on disk as rear-$(hostname).iso" >> $REAR_TMP
    echo  "OUTPUT=ISO" >> $REAR_TMP
    echo  " " >> $REAR_TMP
    echo  "# Internal backup method used to create a simple backup (tar archive)." >> $REAR_TMP
    echo  "BACKUP=NETFS" >> $REAR_TMP
    echo  " " >> $REAR_TMP
    echo  "# Directory within mount point where iso and tgz will be stored" >> $REAR_TMP
    echo  "NETFS_PREFIX=\"\$HOSTNAME\"" >> $REAR_TMP
    echo  " " >> $REAR_TMP
    echo  "# To backup to NFS disk, use BACKUP_URL=nfs://nfs-server-name/share/path"  >> $REAR_TMP
    echo  "BACKUP_URL=\"nfs://${SADM_REAR_NFS_SERVER}/${SADM_REAR_NFS_MOUNT_POINT}\"" >> $REAR_TMP
    echo  " " >> $REAR_TMP
    echo  "# Disable SELinux while the backup is running." >> $REAR_TMP
    echo  "BACKUP_SELINUX_DISABLE=1" >> $REAR_TMP
    echo  " " >> $REAR_TMP
    echo  "# Prefix name for ISO images without the .iso suffix (rear_HOSTNAME.iso)" >> $REAR_TMP
    echo  "ISO_PREFIX=\"rear_\$HOSTNAME\"" >> $REAR_TMP
    echo  " " >> $REAR_TMP
    echo  "# Name of Backup (tar.gz) File" >> $REAR_TMP
    echo  "BACKUP_PROG_ARCHIVE=\"rear_\${HOSTNAME}\"" >> $REAR_TMP
    echo  " " >> $REAR_TMP
    echo  "### BACKUP INCLUDE/EXCLUDE SECTION " >> $REAR_TMP
    echo  " " >> $REAR_TMP

    # Create the NEW site.conf from the tmp just create above
    cat $REAR_TMP $REAR_USER_EXCLUDE | tr -d '\r' > $REAR_CFG           # Concat & Remove CR in file
    #cat $REAR_TMP $REAR_USER_EXCLUDE > $REAR_CFG           # Concat & Remove CR in file

    #sadm_writelog "scp -CqP${SADM_SSH_PORT} $REAR_CFG ${WSERVER}:/etc/rear/site.conf" 
    #scp -CqP${SADM_SSH_PORT}  $REAR_CFG ${WSERVER}:/etc/rear/site.conf
    #if [ $? -eq 0 ] ; then sadm_writelog "[OK] /etc/rear/site.conf is updated on ${WSERVER}" ;fi
}

# --------------------------------------------------------------------------------------------------
# On Linux, Create standard crontab header for O/S Update, Daily Backup and ReaR Backup 
# --------------------------------------------------------------------------------------------------
create_crontab_files_header()
{
    # Header for O/S Update Crontab File
    echo "# "                                                        > $SADM_CRON_FILE 
    echo "# SADMIN - Operating System Update Schedule"              >> $SADM_CRON_FILE 
    echo "# Please don't edit manually, SADMIN generated."          >> $SADM_CRON_FILE 
    echo "# "                                                       >> $SADM_CRON_FILE 
    echo "# Min, Hrs, Date, Mth, Day, User, Script"                 >> $SADM_CRON_FILE
    echo "# Day 0=Sun 1=Mon 2=Tue 3=Wed 4=Thu 5=Fri 6=Sat"          >> $SADM_CRON_FILE
    echo "# "                                                       >> $SADM_CRON_FILE 
    echo "SADMIN=$SADM_BASE_DIR"                                    >> $SADM_CRON_FILE
    echo "# "                                                       >> $SADM_CRON_FILE

    # Header for Backup Crontab File
    echo "# "                                                        > $SADM_BACKUP_NEWCRON 
    echo "# SADMIN Client Backup Schedule"                          >> $SADM_BACKUP_NEWCRON 
    echo "# Please don't edit manually, SADMIN generated."          >> $SADM_BACKUP_NEWCRON 
    echo "# "                                                       >> $SADM_BACKUP_NEWCRON 
    echo "# Min, Hrs, Date, Mth, Day, User, Script"                 >> $SADM_BACKUP_NEWCRON
    echo "# Day 0=Sun 1=Mon 2=Tue 3=Wed 4=Thu 5=Fri 6=Sat"          >> $SADM_BACKUP_NEWCRON
    echo "# "                                                       >> $SADM_BACKUP_NEWCRON 
    echo "SADMIN=$SADM_BASE_DIR"                                    >> $SADM_BACKUP_NEWCRON
    echo "# "                                                       >> $SADM_BACKUP_NEWCRON

    # Header for Rear Crontab File
    echo "# "                                                        > $SADM_REAR_NEWCRON 
    echo "# SADMIN Client ReaR Schedule"                            >> $SADM_REAR_NEWCRON 
    echo "# Please don't edit manually, SADMIN generated."          >> $SADM_REAR_NEWCRON 
    echo "# "                                                       >> $SADM_REAR_NEWCRON 
    echo "# Min, Hrs, Date, Mth, Day, User, Script"                 >> $SADM_REAR_NEWCRON
    echo "# Day 0or7=Sun 1=Mon 2=Tue 3=Wed 4=Thu 5=Fri 6=Sat"       >> $SADM_REAR_NEWCRON
    echo "# "                                                       >> $SADM_REAR_NEWCRON 
    echo "SADMIN=$SADM_BASE_DIR"                                    >> $SADM_REAR_NEWCRON
    echo "# "                                                       >> $SADM_REAR_NEWCRON
    return
}


# --------------------------------------------------------------------------------------------------
# Validate SSH Server Connectivity 
#  Parameters:
#   1) Fully qualified domain name of the server to connect with SSH
#   2) SSH port number used to communicate to system.
#  Return Value:
#   0) Server Accessible
#   1) Error, go to next server (Can't SSH to Server, Missing Parameter rcv, Hostname Unresovable)
#   2) Warning, skip server (server lock, O/S Update Running, Sporadic System or Monitor if OFF)
#   3) Was not able to update uptime of server in Database
# --------------------------------------------------------------------------------------------------
validate_server_connectivity()
{
    # Validate number of parameter received
    if [ $# -ne 2 ]
        then sadm_writelog "Error: Function ${FUNCNAME[0]} didn't receive 2 parameters."
             sadm_writelog "Function received $* and this isn't valid."
             sadm_writelog "Should receive the fqdn of the server and the ssh port number."
             return 1
    fi

    FQDN_SNAME=$1                                                       # Server Name Full Qualified
    SSH_PORT=$2                                                         # Port No. to SSH to system

    # Can we resolve the hostname ?
    if ! host $FQDN_SNAME >/dev/null 2>&1                               # Name is resolvable ? 
           then SMSG="Can't process '$FQDN_SNAME', hostname can't be resolved."
                sadm_write_err "[ ERROR ] ${SMSG}"                      # Advise user
                return 1                                                # Return Error to Caller
    fi
    SNAME=$(echo "$FQDN_SNAME" | awk -F\. '{print $1}')                 # System Name without Domain

    # Check if System is Locked.
    sadm_check_system_lock "$SNAME"                                        # Check lock file status
    if [ $? -eq 1 ] ; then return 2 ; fi                                # System Lock, Nxt Server

    # Try to get uptime from system to test if ssh to system is working
    # -o ConnectTimeout=1 -o ConnectionAttempts=1 
    wuptime=$(${SADM_SSH} -qnp $SSH_PORT -o ConnectTimeout=2 -o ConnectionAttempts=2 $FQDN_SNAME uptime 2>/dev/null)
    RC=$?                                                               # Save Error Number
    if [ $RC -eq 0 ]                                                    # If SSH Worked
        then GLOB_UPTIME=$(echo "$wuptime" |awk -F, '{print $1}' |awk '{gsub(/^[ ]+/,""); print $0}')
             update_server_uptime "$SNAME" "$GLOB_UPTIME"               # Update Server Uptime in DB
             if [ $? -eq 0 ] ; then return 0 ; else return 3 ; fi       # Return ErrorCode to caller
    fi                               

    # SSH didn't work, but it's a sporadic system (Laptop or Tmp Server, don't report an error)
    if [ "$server_sporadic" = "1" ]                                     # If Error on Sporadic Host
        then sadm_write_log "[ WARNING ] Can't SSH to ${FQDN_SNAME} (Sporadic System)."
             return 2                                                   # Return Skip Code to caller
    fi 

    # SSH didn't work, but monitoring for that system is off (don't report an error)
    if [ "$server_monitor" = "0" ]                                      # If Error & Monitor is OFF
        then sadm_write_log "[ WARNING ] Can't SSH to ${FQDN_SNAME} (Monitoring is OFF)."
             return 2                                                   # Return Skip Code to caller
    fi 

    # SSH is not working and it should be 
    sadm_write_err "[ ERROR ] ${FQDN_SNAME} unresponsive (Can't SSH to it)." 
    
    # Create Error Line in Global Error Report File (rpt)
    ADATE=$(date "+%Y.%m.%d;%H:%M")                                     # Current Date/Time
    RPTLINE="Error;${SNAME};${ADATE};linux;NETWORK"                     # Date/Time,Module,SubModule
    RPTLINE="${RPTLINE};${FQDN_SNAME} unresponsive (Can't SSH to it)"   # Monitor Error Message
    RPTLINE="${RPTLINE};${SADM_ALERT_GROUP};${SADM_ALERT_GROUP}"        # Set Alert group to notify
    echo "$RPTLINE" >> $FETCH_RPT_LOCAL                                 # SADMIN Server Monitor RPT
    echo "$RPTLINE" >> $FETCH_RPT_GLOBAL                                # SADMIN All System rpt 
    return 1    
}



# --------------------------------------------------------------------------------------------------
#  Build a system list of the O/S type (aix/linux,darwin) received.
#
# Input Parameters :
#   1)  Operating System Type
# 
# Output resultant :
#  File $SADM_TMP_FILE1 contains system list for wanted O/S type with fields neened for processing.
#  Fields in this file are ';' delimited.
# --------------------------------------------------------------------------------------------------
build_server_list()
{ 
    WOSTYPE=$1                                                          # O/S Type Linux,aix,darwin
    
    # Build the SQL select statement for active systems with selected o/s 
    SQL="SELECT srv_name,srv_ostype,srv_domain,srv_monitor,srv_sporadic,srv_active,srv_sadmin_dir," 
    SQL="${SQL} srv_update_minute,srv_update_hour,srv_update_dom,srv_update_month,srv_update_dow,"
    SQL="${SQL} srv_update_auto,srv_backup,srv_backup_month,srv_backup_dom,srv_backup_dow,"
    SQL="${SQL} srv_backup_hour,srv_backup_minute,"
    SQL="${SQL} srv_img_backup,srv_img_month,srv_img_dom,srv_img_dow,srv_img_hour,srv_img_minute, "
    SQL="${SQL} srv_ssh_port, srv_backup_compress "
    SQL="${SQL} from server"
    SQL="${SQL} where srv_ostype = '${WOSTYPE}' and srv_active = True "
    SQL="${SQL} order by srv_name; "                                    # Order Output by ServerName

    # Setup database connection parameters
    WAUTH="-u $SADM_RO_DBUSER  -p$SADM_RO_DBPWD "                       # Set Authentication String 
    CMDLINE="$SADM_MYSQL $WAUTH "                                       # Join MySQL with Authen.
    CMDLINE="$CMDLINE -h $SADM_DBHOST $SADM_DBNAME -N -e '$SQL' | tr '/\t/' '/;/'" # Build CmdLine
    if [ $SADM_DEBUG -gt 5 ] ; then sadm_write "${CMDLINE}\n" ; fi      # Debug = Write command Line

    # Try simple sql statement to test connection to database
    $SADM_MYSQL $WAUTH -h $SADM_DBHOST -e "show databases;" > /dev/null 2>&1
    if [ $? -ne 0 ]                                                     # Error Connecting to DB
        then sadm_write "Error connecting to Database.\n"               # Access Denied
             return 1                                                   # Return Error to Caller
    fi 

    # Execute sql to get a list of active servers of the received o/s type into $sadm_tmp_file1
    $SADM_MYSQL $WAUTH -h $SADM_DBHOST $SADM_DBNAME -N -e "$SQL" | tr '/\t/' '/;/' >$SADM_TMP_FILE1
    
    # If file wasn't created or has a zero lenght, then no active system is found, return to caller.
    if [ ! -s "$SADM_TMP_FILE1" ] || [ ! -r "$SADM_TMP_FILE1" ]         # File has zero length?
        then sadm_write "${SADM_TEN_DASH}\n"                            # Print 10 Dash line
             sadm_write "No Active '$WOSTYPE' system found.\n"          # Not ACtive Server MSG
             return 0                                                   # Return Error to Caller
    fi 
}



# --------------------------------------------------------------------------------------------------
# Process Operating System received in parameter (aix/linux,darwin)
# Function call 3 times - One for Linux, one for Aix, and one for MacOS
# --------------------------------------------------------------------------------------------------
process_servers()
{
    WOSTYPE=$1                                                          # Should be aix/linux/darwin

    build_server_list "$WOSTYPE"
    if [ $? -ne 0 ] ; then return 1 ; fi

    # Check input file presence and readability and not empty
    if [ ! -s "$SADM_TMP_FILE1" ] || [ ! -r "$SADM_TMP_FILE1" ]         # File has zero length?
        then return 0 
    fi 

    sadm_writelog " "                                                   # Blank Line in log/Screen
    sadm_writelog "=================================================="
    sadm_writelog "Processing active '$WOSTYPE' server(s)" 
    sadm_writelog " "                                                   # Blank Line in log/Screen

    # Create Standard SADMIN header for cron files (sadm_backup, sadm_osupdate, sadm_rear_backup)
    if [ "$WOSTYPE" = "linux" ] ; then create_crontab_files_header ; fi # Create crontab Files Headr

    # Process each servers included in $SADM_TMP_FILE1 created previously by build_server_list()
    xcount=0; ERROR_COUNT=0;                                            # Initialize Counters 
    while read wline                                                    # Read Server Data from DB
        do                                                              # Line by Line
        xcount=`expr $xcount + 1`                                       # Incr Server Counter Var.
        server_name=`    echo $wline|awk -F\; '{ print $1 }'`           # Extract Server Name
        server_os=`      echo $wline|awk -F\; '{ print $2 }'`           # Extract O/S (linux/aix)
        server_domain=`  echo $wline|awk -F\; '{ print $3 }'`           # Extract Domain of Server
        server_monitor=` echo $wline|awk -F\; '{ print $4 }'`           # Monitor t=True f=False
        server_sporadic=`echo $wline|awk -F\; '{ print $5 }'`           # Sporadic t=True f=False
        server_dir=`     echo $wline|awk -F\; '{ print $7 }'`           # SADMIN Dir on Client 
        fqdn_server=`    echo ${server_name}.${server_domain}`          # Create FQN Server Name
        #
        db_updmin=`     echo $wline|awk -F\; '{ print $8 }'`            # crontab Update Min field
        db_updhrs=`     echo $wline|awk -F\; '{ print $9 }'`            # crontab Update Hrs field
        db_upddom=`     echo $wline|awk -F\; '{ print $10 }'`           # crontab Update DOM field
        db_updmth=`     echo $wline|awk -F\; '{ print $11 }'`           # crontab Update Mth field
        db_upddow=`     echo $wline|awk -F\; '{ print $12 }'`           # crontab Update DOW field 
        db_updauto=`    echo $wline|awk -F\; '{ print $13 }'`           # crontab Update DOW field 
        #
        backup_auto=`   echo $wline|awk -F\; '{ print $14 }'`           # crontab Backup 1=Yes 0=No 
        backup_mth=`    echo $wline|awk -F\; '{ print $15 }'`           # crontab Backup Mth field
        backup_dom=`    echo $wline|awk -F\; '{ print $16 }'`           # crontab Backup DOM field
        backup_dow=`    echo $wline|awk -F\; '{ print $17 }'`           # crontab Backup DOW field 
        backup_hrs=`    echo $wline|awk -F\; '{ print $18 }'`           # crontab Backup Hrs field
        backup_min=`    echo $wline|awk -F\; '{ print $19 }'`           # crontab Backup Min field
        #
        rear_auto=`     echo $wline|awk -F\; '{ print $20 }'`           # Rear Crontab 1=Yes 0=No 
        rear_mth=`      echo $wline|awk -F\; '{ print $21 }'`           # Rear Crontab Mth field
        rear_dom=`      echo $wline|awk -F\; '{ print $22 }'`           # Rear Crontab DOM field
        rear_dow=`      echo $wline|awk -F\; '{ print $23 }'`           # Rear Crontab DOW field 
        rear_hrs=`      echo $wline|awk -F\; '{ print $24 }'`           # Rear Crontab Hrs field
        rear_min=`      echo $wline|awk -F\; '{ print $25 }'`           # Rear Crontab Min field
        ssh_port=`      echo $wline|awk -F\; '{ print $26 }'`           # Port No. to SSH to System
        compress=`      echo $wline|awk -F\; '{ print $27 }'`           # Compress (1=Yes,0=No)
        #
        sadm_writelog " "                                               # White Line
        sadm_writelog "---- [$xcount ($server_os)] ${fqdn_server} ----" # Show count & ServerName

        # TO DISPLAY DATABASE COLUMN WE WILL USED, FOR DEBUGGING
        if [ $SADM_DEBUG -gt 4 ] 
            then sadm_write_log "Column Name and Value before processing them."
                 sadm_write_log "server_name     = $server_name"        # Server Name to run script
                 sadm_write_log "backup_auto     = $backup_auto"        # Run Backup ? 1=Yes 0=No 
                 sadm_write_log "backup_mth      = $backup_mth"         # Month String YNYNYNYNYNY..
                 sadm_write_log "backup_dom      = $backup_dom"         # Day of MOnth String YNYN..
                 sadm_write_log "backup_dow      = $backup_dow"         # Day of Week String YNYN...
                 sadm_write_log "backup_hrs      = $backup_hrs"         # Hour to run script
                 sadm_write_log "backup_min      = $backup_min"         # Min. to run Script
                 sadm_write_log "backup_compress = $compress"           # Compress Backup 1=Y 0=N)
                 sadm_write_log "fqdn_server     = $fqdn_server"        # Name of Output file
                 sadm_write_log "ssh_port        = $ssh_port"           # Port No. to ssh to system
                 sadm_write_log "rear_auto       = $rear_auto "         # Rear Crontab 1=Yes 0=No 
                 sadm_write_log "rear_mth        = $rear_mth  "         # Rear Crontab Mth field
                 sadm_write_log "rear_dom        = $rear_dom  "         # Rear Crontab DOM field
                 sadm_write_log "rear_dow        = $rear_dow  "         # Rear Crontab DOW field 
                 sadm_write_log "rear_hrs        = $rear_hrs  "         # Rear Crontab Hrs field
                 sadm_write_log "rear_min        = $rear_min  "         # Rear Crontab Min field
        fi
    
        # Test SSH connectivity and update uptime in Database 
        if [ "$fqdn_server" != "$SADM_SERVER" ]                         # Not on SADMIN Srv Test SSH
           then validate_server_connectivity "$fqdn_server" "$ssh_port" # Test SSH, Upd uptime in DB
                 RC=$?                                                  # Save function return code 
                 if [ $RC -eq 2 ] ; then continue ; fi                  # Sporadic,Monitor Off,OSUpd
                 if [ $RC -eq 1 ] || [ $RC -eq 3 ]                      # Error SSH or Update Uptime
                    then ERROR_COUNT=$(($ERROR_COUNT+1))                # Error - Incr Error counter
                         sadm_writelog "Total ${WOSTYPE} error(s) is now $ERROR_COUNT"
                         continue                                       # Not accessible, Nxt Server
                 fi 
            else GLOB_UPTIME=$(uptime |awk -F, '{print $1}' |awk '{gsub(/^[ ]+/,""); print $0}')
                 update_server_uptime "$server_name" "$GLOB_UPTIME"           # Update Server Uptime in DB
        fi                            

        # On Linux & O/S AutoUpdate is ON, Generate Crontab entry in O/S Update crontab work file
        if [ "$WOSTYPE" = "linux" ] && [ "$db_updauto" -eq 1 ]          # If O/S Update Scheduled
            then update_osupdate_crontab "$server_name" "\${SADMIN}/bin/$OS_SCRIPT" "$db_updmin" "$db_updhrs" "$db_updmth" "$db_upddom" "$db_upddow" "$ssh_port"
        fi

        # Generate Crontab Entry for this server in Backup crontab work file
        if [ $backup_auto -eq 1 ]                                       # If Backup set to Yes 
            then update_backup_crontab "$server_name" "${server_dir}/bin/$BA_SCRIPT" "$backup_min" "$backup_hrs" "$backup_mth" "$backup_dom" "$backup_dow" "$ssh_port" "$compress"
        fi

        # Generate Crontab Entry for this server in ReaR crontab work file
        if [ "$WOSTYPE" = "linux" ] && [ $rear_auto -eq 1 ]            # If Rear Backup set to Yes 
            then update_rear_crontab "$server_name" "${server_dir}/bin/$REAR_SCRIPT" "$rear_min" "$rear_hrs" "$rear_mth" "$rear_dom" "$rear_dow" "$ssh_port"
        fi
                
        # Set remote $SADMIN/cfg Dir. and local www/dat/${server_name}/cfg directory.
        LDIR="${SADM_WWW_DAT_DIR}/${server_name}/cfg"                   # cfg Local Receiving Dir.
        RDIR="${server_dir}/cfg"                                        # Remote cfg Directory

        # If client backup list was modified on master (if backup_list.tmp exist) then update client.
        if [ -r "$LDIR/backup_list.tmp" ]                               # If backup list was modify
           then if [ "$fqdn_server" != "$SADM_SERVER" ]                 # If Not on SADMIN Server
                   then rsync -ar -e "ssh -p $ssh_port" $LDIR/backup_list.tmp ${server_name}:$RDIR/backup_list.txt # Rem.Rsync
                   else rsync -ar -e "ssh -p $ssh_port" $LDIR/backup_list.tmp $SADM_CFG_DIR/backup_list.txt  # Local Rsync 
                fi
                RC=$?                                                   # Save Command Return Code
                if [ $RC -eq 0 ]                                        # If copy to client Worked
                    then sadm_write "$SADM_OK Modified Backup list updated on ${server_name}\n"
                         rm -f $LDIR/backup_list.tmp                    # Remove modified Local copy
                    else sadm_write "$SADM_ERROR Syncing backup list with ${server_name}\n"
                fi
        fi

        # If backup exclude list was modified on master (if backup_exclude.tmp exist), update client
        if [ -r "$LDIR/backup_exclude.tmp" ]                            # Backup Exclude list modify
           then if [ "$fqdn_server" != "$SADM_SERVER" ]                 # If Not on SADMIN Server
                   then rsync -ar -e "ssh -p $ssh_port" $LDIR/backup_exclude.tmp ${server_name}:$RDIR/backup_exclude.txt 
                   else rsync -ar -e "ssh -p $ssh_port" $LDIR/backup_exclude.tmp $SADM_CFG_DIR/backup_exclude.txt # LocalRsync 
                fi
                RC=$?                                                   # Save Command Return Code
                if [ $RC -eq 0 ]                                        # If copy to client Worked
                    then sadm_writelog "$SADM_OK Modified Backup Exclude list updated on ${server_name}"
                         rm -f $LDIR/backup_exclude.tmp                 # Remove modified Local copy
                    else sadm_writelog "$SADM_ERROR Syncing Backup Exclude list with ${server_name}"
                fi
        fi

        # Build the name of the client footer that might have been modified Rear by user.
        REAR_USER_EXCLUDE="${SADM_WWW_DAT_DIR}/${server_name}/cfg/rear_exclude.tmp"     

        # Check if ReaR backup exclude list was modified (if backup_exclude.tmp exist), update client
        if [ -r "$REAR_USER_EXCLUDE" ]                                  # Rear Exclude option modify
           then update_rear_site_conf ${server_name}
                if [ "$fqdn_server" != "$SADM_SERVER" ]                 # If Not on SADMIN Server
                   then #sadm_writelog "rsync -var $REAR_CFG ${server_name}:/etc/rear/site.conf "
                        rsync -ar -e "ssh -p $ssh_port" $REAR_CFG ${server_name}:/etc/rear/site.conf 
                        if [ $? -eq 0 ] 
                            then sadm_writelog "$SADM_OK /etc/rear/site.conf updated on ${server_name}"
                            else sadm_writelog "$SADM_ERROR Trying to update /etc/rear/site.conf on ${server_name}"
                                 if [ $RC -ne 0 ] ; then ERROR_COUNT=$(($ERROR_COUNT+1)) ; fi  
                        fi
                        #
                        #sadm_writelog "rsync -var $REAR_USER_EXCLUDE ${server_name}:${RDIR}/rear_exclude.txt" 
                        rsync -ar -e "ssh -p $ssh_port" "$REAR_USER_EXCLUDE" "${server_name}:${RDIR}/rear_exclude.txt"
                        if [ $? -eq 0 ] 
                            then sadm_writelog "$SADM_OK ${RDIR}/rear_exclude.txt updated on ${server_name}"
                            else sadm_writelog "$SADM_ERROR Trying to update ${RDIR}/rear_exclude.txt on ${server_name}"
                                 if [ $RC -ne 0 ] ; then ERROR_COUNT=$(($ERROR_COUNT+1)) ; fi  
                        fi
                   else #sadm_writelog "rsync -var $REAR_CFG /etc/rear/site.conf" 
                        rsync -ar -e "ssh -p $ssh_port" $REAR_CFG /etc/rear/site.conf
                        if [ $? -eq 0 ] 
                            then sadm_writelog "$SADM_OK /etc/rear/site.conf updated on ${server_name}"
                            else sadm_writelog "$SADM_ERROR Trying to update /etc/rear/site.conf on ${server_name}"
                                 if [ $RC -ne 0 ] ; then ERROR_COUNT=$(($ERROR_COUNT+1)) ; fi  
                        fi
                        #
                        #sadm_writelog "rsync $REAR_USER_EXCLUDE ${SADM_CFG_DIR}/rear_exclude.txt" 
                        rsync -ar -e "ssh -p $ssh_port" "$REAR_USER_EXCLUDE" "${SADM_CFG_DIR}/rear_exclude.txt"
                        if [ $? -eq 0 ] 
                            then sadm_writelog "$SADM_OK ${SADM_CFG_DIR}/rear_exclude.txt updated on ${server_name}"
                            else sadm_writelog "$SADM_ERROR Trying to update ${SADM_CFG_DIR}/rear_exclude.txt on ${server_name}"
                                 if [ $RC -ne 0 ] ; then ERROR_COUNT=$(($ERROR_COUNT+1)) ; fi  
                        fi
                        RC=$?
                fi
        fi

        # Copy Site Common configuration files to client (If not on server)
        if [ "$fqdn_server" != "$SADM_SERVER" ]                         # If Not on SADMIN Server
            then rem_cfg_files=( alert_group.cfg )
                 for WFILE in "${rem_cfg_files[@]}"
                   do
                   CFG_SRC="${SADM_CFG_DIR}/${WFILE}" 
                   CFG_DST="${fqdn_server}:${server_dir}/cfg/${WFILE}"
                   CFG_CMD="rsync -ar -e ssh -p $ssh_port ${CFG_SRC} ${CFG_DST}"
                   if [ $SADM_DEBUG -gt 5 ] ; then sadm_writelog "$CFG_CMD" ; fi 
                   rsync -ar -e "ssh -p $ssh_port" "${CFG_SRC}" "${CFG_DST}" >> "$SADM_LOG" 2>&1
                   RC=$? 
                   if [ $RC -ne 0 ]
                      then sadm_writelog "$SADM_ERROR ($RC) doing ${CFG_CMD}"
                           ERROR_COUNT=$(($ERROR_COUNT+1))
                      else sadm_writelog "$SADM_OK ${CFG_CMD}" 
                   fi
                   done  
        fi 

        # Get remote $SADMIN/cfg Dir. and update local www/dat/${server_name}/cfg directory.
        if [ "$fqdn_server" != "$SADM_SERVER" ]                         # If Not on SADMIN Try SSH 
            then rsync_function "${fqdn_server}:${RDIR}/" "${LDIR}/"    # Remote to Local rsync
            else rsync_function "${RDIR}/" "${LDIR}/"                   # Local Rsync if on Master
        fi
        if [ $RC -ne 0 ] ; then ERROR_COUNT=$(($ERROR_COUNT+1)) ; fi    # rsync error, Incr Err Cntr
        chown -R $SADM_WWW_USER:$SADM_GROUP ${SADM_WWW_DAT_DIR}/${server_name} # Change Owner

        
        # Get remote $SADMIN/log Dir. and update local www/dat/${server_name}/log directory.
        LDIR="${SADM_WWW_DAT_DIR}/${server_name}/log"                   # Local Receiving Dir.
        RDIR="${server_dir}/log"                                        # Remote log Directory
        if [ "$fqdn_server" != "$SADM_SERVER" ]                         # If Not on SADMIN Try SSH 
            then rsync_function "${fqdn_server}:${RDIR}/" "${LDIR}/"    # Remote to Local rsync
            else rsync_function "${RDIR}/" "${LDIR}/"                   # Local Rsync if on Master
        fi
        if [ $RC -ne 0 ] ; then ERROR_COUNT=$(($ERROR_COUNT+1)) ; fi    # rsync error, Incr Err Cntr
        find $LDIR -type f -exec chown $SADM_WWW_USER:$SADM_WWW_GROUP {} \;
        find $LDIR -type f -exec chmod 666 {} \;

       # Rsync remote rch dir. onto local web rch dir/ (${SADMIN}/www/dat/${server_name}/rch) 
        LDIR="${SADM_WWW_DAT_DIR}/${server_name}/rch"                   # Local Receiving Dir. Path
        RDIR="${server_dir}/dat/rch"                                    # Remote RCH Directory Path
        if [ "$fqdn_server" != "$SADM_SERVER" ]                         # If Not on SADMIN Try SSH 
            then rsync_function "${fqdn_server}:${RDIR}/" "${LDIR}/"    # Remote to Local rsync
            else rsync_function "${RDIR}/" "${LDIR}/"                   # Local Rsync if on Master
        fi
        if [ $RC -ne 0 ] ; then ERROR_COUNT=$(($ERROR_COUNT+1)) ; fi    # rsync error, Incr Err Cntr
        find $LDIR -type f -exec chown $SADM_WWW_USER:$SADM_WWW_GROUP {} \;
        find $LDIR -type f -exec chmod 666 {} \;


        # Get remote $SADMIN/dat/rpt Dir. and update local www/dat/${server_name}/rpt directory.
        LDIR="$SADM_WWW_DAT_DIR/${server_name}/rpt"                     # Local www Receiving Dir.
        RDIR="${server_dir}/dat/rpt"                                    # Remote log Directory
        if [ "$fqdn_server" != "$SADM_SERVER" ]                         # If Not on SADMIN Try SSH 
            then rsync_function "${fqdn_server}:${RDIR}/" "${LDIR}/"    # Remote to Local rsync
            #else rsync_function "${RDIR}/" "${LDIR}/"                   # Local Rsync if on Master
        fi
        if [ $RC -ne 0 ] ; then ERROR_COUNT=$(($ERROR_COUNT+1)) ; fi    # rsync error, Incr Err Cntr
        find $LDIR -type f -exec chown $SADM_WWW_USER:$SADM_WWW_GROUP {} \;
        find $LDIR -type f -exec chmod 666 {} \;


        # Advise the user if the total error counter is different than zero.
        if [ $ERROR_COUNT -ne 0 ]                                       # If at Least 1 Error
           then sadm_writelog " "                                       # Separation Blank Line
                sadm_writelog "** Total ${WOSTYPE} error(s) is now $ERROR_COUNT" # Show Err. Count
        fi

        done < $SADM_TMP_FILE1                                          # Read active server list

    sadm_writelog " "                                                   # Separation Blank Line
    #sadm_writelog "${SADM_TEN_DASH}"                                    # Print 10 Dash line
    return $ERROR_COUNT                                                 # Return Total Error Count
}




# --------------------------------------------------------------------------------------------------
# Combine all clients *.rpt files and issues alert(s) if needed.
# ----------
# Get all *.rpt files content and output it then a temp file ($SADM_TMP_FILE1).
#  Example of rpt content : 
#   Warning;nomad;2018.09.16;11:00;linux;FILESYSTEM;Filesystem /usr at 86% > 85%;mail;sadmin
#   Error;nano;2018.09.16;11:00;SERVICE;DAEMON;Service crond|cron not running !;sadm;sadm
#   Error;raspi0;2018.09.16;11:00;linux;CPU;CPU at 100 pct for more than 240 min;mail;sadmin
#
# --------------------------------------------------------------------------------------------------
check_all_rpt()
{
    sadm_writelog "Verifying all Systems Monitors reports files (*.rpt) :"
    find $SADM_WWW_DAT_DIR -name *.rpt -exec cat {} \;  > $SADM_TMP_FILE3
    if [ $SADM_DEBUG -gt 0 ] 
        then sadm_write "\nFile containing results\n"
             ls -l $SADM_TMP_FILE3
             sadm_write "Content of the file $SADM_TMP_FILE3 \n" 
             cat  $SADM_TMP_FILE3 | while read wline ; do sadm_writelog "$wline"; done
    fi 


    # Process the file containing all *.rpt content (if any).
    if [ -s "$SADM_TMP_FILE3" ]                                         # If File Not Zero in Size
        then while read line                      # Read Each Line of file
                do
                if [ $SADM_DEBUG -gt 6 ] ; then sadm_writelog "Processing Line=$line" ; fi
                ehost=`echo $line | awk -F\; '{ print $2 }'`            # Get Hostname for Event
                emess=`echo $line | awk -F\; '{ print $7 }'`            # Get Event Error Message
                wdate=`echo $line | awk -F\; '{ print $3 }'`            # Get Event Date
                wtime=`echo $line | awk -F\; '{ print $4 }'`            # Get Event Time
                etime="${wdate} ${wtime}"                               # Combine Event Date & Time
                if [ ${line:0:1} = "W" ] || [ ${line:0:1} = "w" ]       # If it is a Warning
                    then etype="W"                                      # Set Event Type to Warning
                         egname=`echo $line | awk -F\; '{ print $8 }'`  # Get Warning Alert Group
                         esub="$emess"                                  # Specify it is a Warning
                fi
                if [ ${line:0:1} = "I" ] || [ ${line:0:1} = "i" ]       # If it is an Info
                    then etype="I"                                      # Set Event Type to Info
                         egname=`echo $line | awk -F\; '{ print $8 }'`  # Get Info Alert Group
                         esub="$emess"                                  # Specify it is an Info
                fi
                if [ ${line:0:1} = "E" ] || [ ${line:0:1} = "e" ]       # If it is an Info
                    then etype="E"                                      # Set Event Type to Error
                         egname=`echo $line | awk -F\; '{ print $9 }'`  # Get Error Alert Group
                         esub="$emess"                                  # Specify it is a Error
                fi
                emess2=`echo -e "${emess}\nEvent Date/Time : ${etime}\n"` 
                if [ $SADM_DEBUG -gt 0 ] 
                    then sadm_writelog "sadm_send_alert $etype $etime $ehost sysmon $egname $esub $emess $eattach"
                fi
                #sadm_write "$etime SysMon alert ($etype) on ${ehost} : ${emess}\n"
                alert_counter=`expr $alert_counter + 1`                 # Increase Submit AlertCount
                umess="${alert_counter}) $etime SysMon alert ($etype) on ${ehost} : ${emess} -"
                t_alert=`expr $t_alert + 1`                             # Incr. Alert counter
                sadm_send_alert "$etype" "$etime" "$ehost" "SysMon" "$egname" "$esub" "$emess2" "$eattach"
                RC=$?
                case $RC in
                    0)  t_ok=`expr $t_ok + 1`
                        sadm_writelog "${umess} Alert sent successfully."
                        ;;
                    1)  t_error=`expr $t_error + 1`
                        sadm_writelog "${umess} Error submitting alert."
                        ;;
                    2)  t_duplicate=`expr $t_duplicate + 1`
                        sadm_writelog "${umess} Alert already sent."
                        ;;
                    3)  t_oldies=`expr $t_oldies + 1`
                        sadm_writelog "${umess} Alert is older than 24 hrs."
                        ;;
                    *)  if [ $SADM_DEBUG -gt 0 ] 
                            then sadm_writelog "   - ERROR: Unknown return code $RC"
                        fi
                        ;;
                esac                                                    # End of case
                done < $SADM_TMP_FILE3 
        else sadm_writelog "${BOLD}No error reported by any 'SysMon report files' (*.rpt).${NORMAL}" 
    fi

    # Print Alert submitted Summary
    sadm_writelog " "                                               # Separation Blank Line
    if [ $t_alert -ne 0 ]    
        then sadm_writelog "${BOLD}$t_alert System Monitor Alert(s) submitted${NORMAL}"
        else sadm_writelog "${BOLD}No System Monitor Alert(s) submitted${NORMAL}"
    fi
    sadm_writelog "   - New alert sent successfully : $t_ok" 
    sadm_writelog "   - Alert error trying to send  : $t_error"
    sadm_writelog "   - Alert older than 24 Hrs     : $t_oldies"
    sadm_writelog "   - Alert already sent          : $t_duplicate"
    sadm_writelog "${SADM_TEN_DASH}"                                # Print 10 Dash lineHistory

}

# --------------------------------------------------------------------------------------------------
# Check the last line of every *.rch file of all systems and submit alert if needed.
#
# Example of line in rch file :
#   holmes 2018.09.18 11:48:53 2018.09.18 11:48:53 00:00:00 sadm_template default 0 1
#   debian10 2018.09.18 11:48:53 2018.09.18 11:48:53 00:00:00 sadm_template default 1 1
#   raspi2 2019.05.07 01:31:00 2019.05.07 01:34:25 00:03:25 sadm_osupdate default 2 0
#   ubuntu1604 2019.07.25 01:10:01 2019.07.25 01:11:02 00:01:01 sadm_backup default 3 0
# --------------------------------------------------------------------------------------------------
check_all_rch()
{
    sadm_write "\n"
    sadm_write "${BOLD}${YELLOW}Verifying all systems scripts results files (*.rch) :${NORMAL}\n"
    total_ok=0 ; total_error=0 ; total_oldies=0 ; total_duplicate=0     # Clear Function Totals
    find $SADM_WWW_DAT_DIR -type f -name '*.rch' -exec tail -1 {} \; > $SADM_TMP_FILE1 2>&1
    awk 'match($NF,/[0-1]/) { print }' $SADM_TMP_FILE1 >$SADM_TMP_FILE2 # Keep line ending with 0or1

    # IF NO FILE TO PROCESS
    if [ ! -s "$SADM_TMP_FILE2" ]                                       # If File Zero in Size
        then sadm_write "No error reported by any scripts files (*.rch)\n" 
             sadm_write "${SADM_TEN_DASH}\n"                            # Print 10 Dash 
             sadm_write "\n"                                            # Separation Blank Line
             return 0                                                   # Return to Caller
    fi

    # LOOP THROUGH EACH LINE IN THE CREATED FILE.
    alert_counter=0                                                     # Init alert counter
    cat $SADM_TMP_FILE2 | { while read line                             # Read Each Line of file
        do                
        NBFIELD=`echo $line | awk '{ print NF }'`                       # How many fields on line ?

        # Each line MUST have the right number of field ($NBFIELD) to be process, else skip line.
        if [ $SADM_DEBUG -gt 8 ] ;then sadm_write "Processing Line: ${line} ($NBFIELD)\n" ;fi
        if [ "${NBFIELD}" != "${RCH_FIELD}" ]                           # If abnormal nb. of field
           then sadm_write "Line below have ${NBFIELD} but it should have ${RCH_FIELD}.\n"
                sadm_write "This line is skipped: ${line}\n"
                sadm_write "\n"
                continue 
        fi

        # Extract each field from the current line and prepare alert content.
        # Line example: holmes 2018.09.18 11:48:53 2018.09.18 11:48:53 00:00:00 sadm_template default 0 1
        ehost=`echo $line   | awk '{ print $1 }'`                       # Host Name of Event
        sdate=`echo $line   | awk '{ print $2 }'`                       # Get Script Ending Date 
        stime=`echo $line   | awk '{ print $3 }' `                      # Get Script Ending Time 
        stime=`echo ${stime:0:5}`                                       # Eliminate the Seconds
        start_time="${sdate} ${stime}"                                  # Combine Event Date & Time
        edate=`echo $line   | awk '{ print $4 }'`                       # Get Script Ending Date 
        etime=`echo $line   | awk '{ print $5 }' `                      # Get Script Ending Time 
        etime=`echo ${etime:0:5}`                                       # Eliminate the Seconds
        end_time="${edate} ${etime}"                                    # Combine Event Date & Time
        elapse=`echo $line  | awk '{ print $6 }' `                      # Get Script Elapse time 
        escript=`echo $line | awk '{ print $7 }'`                       # Script Name 
        egname=`echo $line  | awk '{ print $8 }'`                       # Alert Group Name
        egtype=`echo $line  | awk '{ print $9 }'`                       # Alert Group Type [0,1,2,3]
        ecode=`echo $line   | awk '{ print $10 }'`                      # Return Code (0,1)
        etype="S"                                                       # Event Type = S = Script 
        if [ "$ecode" = "1" ]                                           # Script Ended with Error
           then esub="Error with ${escript} on $ehost."                 # Alert Subject
                emess="Script '$escript' failed on ${ehost}."           # Alert Message
           else esub="Success of '$escript' on ${ehost}."               # Script Success Alert Subj.
                emess="Successfully ran '$escript' on ${ehost}."        # Script Success Alert Mess.
        fi
        
        eattach=""                                                      # Clear Attachment Name
        elogfile="${ehost}_${escript}.log"                              # Build Log File Name
        elogname="${SADM_WWW_DAT_DIR}/${ehost}/log/${elogfile}"         # Build Log Full Path File
        if [ -e "$elogname" ]                                           # If Log file exist
           then eattach="$elogname"                                     # Set Attachment to LogName
        fi
        errlogfile="${ehost}_${escript}_e.log"                          # Build Err Log File Name
        errlogname="${SADM_WWW_DAT_DIR}/${ehost}/log/${errlogfile}"     # Build Err Log Full Path
        if [ -e "$errlogname" ]                                         # If Error Log file exist
           then if [ -e "$elogname" ]                                   # If log already attach
                   then eattach="$eattach,$errlogname"                  # Also attach Error Log
                   else eattach="$errlogname"                           # Attach Error Log
                fi 
        fi

        # Event Group Type ($egtype) = 0=None 1=AlertOnErr 2=AlertOnOK 3=Always 
        # Event Return Code ($ecode) = 0=Success 1=Error
        # So if user want to be alerted :
        #  - If script terminate with error ($egtype=1 and $ecode=1)
        #  - If script terminate with success  ($egtype=2 and $ecode=0)
        #  - Each time the script is executed ($egtype=3)
        if [ "$egtype" = "1" -a "$ecode" = "1" ] || 
           [ "$egtype" = "2" -a "$ecode" = "0" ] || [ "$egtype" = "3" ]  
           then total_alert=`expr $total_alert + 1`                     # Incr. Alert counter
                if [ $SADM_DEBUG -gt 0 ]                                # Under Debug Show Parameter
                   then dmess="'$etype' '$start_time' '$end_time' '$ehost' '$egname'"    # Build Mess to see Param.
                        dmess="$dmess '$esub' '$emess' '$eattach'"      # Build Mess to see Param.
                        sadm_writelog "sadm_send_alert $dmess RC=$RC"   # Show User Paramaters sent
                fi
                alert_counter=`expr $alert_counter + 1`                 # Increase Submit AlertCount
                #sadm_writelog " " 
                #sadm_writelog "${alert_counter}) $etime alert ($etype) for $escript on ${ehost}: "
                #sadm_writelog "   - $emess"
                emess=$(echo -e "${emess}\nScript start time  : ${start_time}\n")
                emess=$(echo -e "${emess}\nScript end time    : ${end_time}\n")
                emess=$(echo -e "${emess}\nScript elapse time : ${elapse}\n")
                if [ $SADM_DEBUG -gt 0 ] ;then sadm_write "Email Message is:\n${emess}\n" ; fi
                sadm_send_alert "$etype" "$end_time" "$ehost" "$escript" "$egname" "$esub" "$emess" "$eattach"
                RC=$?
                if [ $SADM_DEBUG -gt 0 ] ;then sadm_writelog "RC=$RC" ;fi # Debug Show ReturnCode
                case $RC in
                    0)  total_ok=`expr $total_ok + 1`
                        sadm_writelog "${alert_counter}) $start_time alert ($etype) for $escript on ${ehost}: Alert was sent successfully."
                        ;;
                    1)  total_error=`expr $total_error + 1`
                        sadm_writelog "${alert_counter}) $start_time alert ($etype) for $escript on ${ehost}: Error submitting the alert."
                        ;;
                    2)  total_duplicate=`expr $total_duplicate + 1`
                        sadm_writelog "${alert_counter}) $start_time alert ($etype) for $escript on ${ehost}: Alert already sent."
                        ;;
                    3)  total_oldies=`expr $total_oldies + 1`
                        sadm_writelog "${alert_counter}) $start_time alert ($etype) for $escript on ${ehost}: Alert is older than 24 hrs."
                        ;;
                    *)  if [ $SADM_DEBUG -gt 0 ] ;then sadm_writelog "   - ERROR: Unknown return code $RC"; fi
                        ;;
                esac                                                    # End of case
        fi
        done 

        # Print Alert submitted Summary
        sadm_writelog " "                                               # Separation Blank Line
        sadm_writelog "${BOLD}$total_alert Script(s) Alert(s) submitted${NORMAL}"
        sadm_writelog "   - New alert sent successfully : $total_ok"
        sadm_writelog "   - Alert error trying to send  : $total_error"
        sadm_writelog "   - Alert older than 24 Hrs     : $total_oldies"
        sadm_writelog "   - Alert already sent          : $total_duplicate"
        sadm_writelog "${SADM_TEN_DASH}"                                # Print 10 Dash lineHistory
    }                                                              
}




# --------------------------------------------------------------------------------------------------
# Check checksum of current crontab versus the one created while processing each systems.
# If checksum is different, update the crontab file (For sadm_osupdate file and sadm_vackup file).
# --------------------------------------------------------------------------------------------------
crontab_update()
{
    sadm_writelog "${BOLD}${YELLOW}Crontab Update Summary${NORMAL}"

    # Create sha1sum on newly and actual backup crontab.
    # Compare the two sha1sum and if they are different, then the new crontab become the actual.
    if [ -f ${SADM_CRON_FILE} ] ; then work_sha1=`sha1sum ${SADM_CRON_FILE} |awk '{print $1}'` ;fi 
    if [ -f ${SADM_CRONTAB} ]   ; then real_sha1=`sha1sum ${SADM_CRONTAB}   |awk '{print $1}'` ;fi 
    if [ "$work_sha1" != "$real_sha1" ]                                 # New Different than Actual?
       then if [ -f ${SADM_CRON_FILE} ]
                then cp ${SADM_CRON_FILE} ${SADM_CRONTAB}               # Put in place New Crontab
                     chmod 644 $SADM_CRONTAB ; chown root:root ${SADM_CRONTAB} # Set crontab Perm.
                     sadm_writelog "  - O/S update schedule crontab ($SADM_CRONTAB) was updated."
            fi  
       else sadm_writelog "  - No need to update the O/S update schedule crontab ($SADM_CRONTAB)."
    fi
    rm -f ${SADM_CRON_FILE} >>/dev/null 2>&1                            # Remove crontab work file

    # Create sha1sum on newly and actual backup crontab.
    # Compare the two sha1sum and if they are different, then the new crontab become the actual.
    if [ -f ${SADM_BACKUP_NEWCRON} ] ; then nsha1=`sha1sum ${SADM_BACKUP_NEWCRON} |awk '{print $1}'` ;fi
    if [ -f ${SADM_BACKUP_CRONTAB} ] ; then asha1=`sha1sum ${SADM_BACKUP_CRONTAB} |awk '{print $1}'` ;fi 
    if [ "$nsha1" != "$asha1" ]                                         # New Different than Actual?
       then if [ -f ${SADM_BACKUP_NEWCRON} ]
                then cp ${SADM_BACKUP_NEWCRON} ${SADM_BACKUP_CRONTAB}   # Put in place New Crontab
                     chmod 644 $SADM_BACKUP_CRONTAB ; chown root:root ${SADM_BACKUP_CRONTAB}
                     sadm_writelog "  - Clients backup schedule crontab ($SADM_BACKUP_CRONTAB) was updated." 
            fi
       else sadm_writelog "  - No need to update the backup crontab ($SADM_BACKUP_CRONTAB)."
    fi
    rm -f ${SADM_BACKUP_NEWCRON} >>/dev/null 2>&1                       # Remove crontab work file

    # Create sha1sum on newly and actual ReaR backup crontab.
    # Compare the two sha1sum and if they are different, then the new crontab become the actual.
    if [ -f ${SADM_REAR_NEWCRON} ] ; then nsha1=`sha1sum ${SADM_REAR_NEWCRON} |awk '{print $1}'` ;fi
    if [ -f ${SADM_REAR_CRONTAB} ] ; then asha1=`sha1sum ${SADM_REAR_CRONTAB} |awk '{print $1}'` ;fi 
    if [ "$nsha1" != "$asha1" ]                                         # New Different than Actual?
       then if [ -f ${SADM_REAR_NEWCRON} ]
                then cp ${SADM_REAR_NEWCRON} ${SADM_REAR_CRONTAB}       # Put in place New Crontab
                     chmod 644 $SADM_REAR_CRONTAB ; chown root:root ${SADM_REAR_CRONTAB}
                     sadm_writelog "  - Clients ReaR backup schedule crontab ($SADM_REAR_CRONTAB) was updated."
            fi 
       else sadm_writelog "  - No need to update the ReaR backup crontab ($SADM_REAR_CRONTAB)."
    fi
    rm -f ${SADM_REAR_NEWCRON} >>/dev/null 2>&1                         # Remove crontab work file

    sadm_writelog "${SADM_TEN_DASH}"
    sadm_writelog " "
}




# --------------------------------------------------------------------------------------------------
# Get from all actives servers the new hostname.rpt file and all the new or updated *.rch files.
# --------------------------------------------------------------------------------------------------
main_process()
{
    # Process All Active Linux/Aix servers
    > $FETCH_RPT_LOCAL                                                  # Create Monitor Empty RPT
    > $FETCH_RPT_GLOBAL                                                 # Create Mon. in Glocal Dir
    LINUX_ERROR=0; AIX_ERROR=0 ; MAC_ERROR=0                            # Init. Error count to 0

    process_servers "linux"                                             # Process Active Linux
    LINUX_ERROR=$?                                                      # Save Nb. Errors in process
    process_servers "aix"                                               # Process Active Aix
    AIX_ERROR=$?                                                        # Save Nb. Errors in process
    process_servers "darwin"                                            # Process Active MacOS
    MAC_ERROR=$?                                                        # Save Nb. Errors in process

    # Print Total Scripts Errors
    sadm_writelog " "                                                   # Separation Blank Line
    sadm_writelog "${SADM_TEN_DASH}"                                    # Print 10 Dash lineHistory
    sadm_writelog "Systems Rsync Summary"                               # Rsync Summary 
    SADM_EXIT_CODE=$(($AIX_ERROR+$LINUX_ERROR+$MAC_ERROR))              # ExitCode=AIX+Linux+Mac Err
    sadm_writelog " - Total Linux error(s)  : ${LINUX_ERROR}"           # Display Total Linux Errors
    sadm_writelog " - Total Aix error(s)    : ${AIX_ERROR}"             # Display Total Aix Errors
    sadm_writelog " - Total Mac error(s)    : ${MAC_ERROR}"             # Display Total Mac Errors
    sadm_writelog "Rsync Total Error(s)     : ${SADM_EXIT_CODE}"
    sadm_writelog "${SADM_TEN_DASH}"                                    # Print 10 Dash lineHistory
    sadm_writelog " "                                                   # Separation Blank Line

    # Go and check if crontabs need to be updated (sadm_backup, sadm_osupdate, sadm_rear_backup)
    if [ $(sadm_get_ostype) = "LINUX" ] ; then crontab_update ; fi      # Update crontab if needed
    
    # To prevent this script from showing very often on the monitor (This script is run every 5 min)
    # we copy immediatly the updated .rch file in the SADMIN main web central directory. 
    if [ ! -d ${SADM_WWW_DAT_DIR}/${SADM_HOSTNAME}/rch ]                # Web RCH repo Dir not exist
        then mkdir -p ${SADM_WWW_DAT_DIR}/${SADM_HOSTNAME}/rch          # Create it
    fi
    cp $SADM_RCHLOG ${SADM_WWW_DAT_DIR}/${SADM_HOSTNAME}/rch            # cp rch for instant Status
    chmod 666 ${SADM_WWW_DAT_DIR}/${SADM_HOSTNAME}/rch

    if [ ! -d ${SADM_WWW_DAT_DIR}/${SADM_HOSTNAME}/rpt ]                # Web RCH repo Dir not exist
        then mkdir -p ${SADM_WWW_DAT_DIR}/${SADM_HOSTNAME}/rpt          # Create it
    fi
    cp ${SADM_RPT_DIR}/*.rpt ${SADM_WWW_DAT_DIR}/${SADM_HOSTNAME}/rpt   # cp rpt for instant Status
    chmod 666 ${SADM_WWW_DAT_DIR}/${SADM_HOSTNAME}/rpt/*.rpt

    # Check for Error or Alert to submit
    check_all_rpt                                                       # Check all *.rpt for Alert
    check_all_rch                                                       # Check all *.rch for Alert

    # Delete TMP work file before retuning to caller 
    if [ ! -f "$REAR_TMP" ] ; then rm -f $REAR_TMP >/dev/null 2>&1 ; fi
    
    return $SADM_EXIT_CODE
}





# --------------------------------------------------------------------------------------------------
#  Update the system uptime in Server Table in SADMIN Database
#  Parameters:
#   1) server hostname to update (without domain name)
#   2) uptime value to store in Database
#  Return Value:
#   0) Successful update
#   1) Error when trying to record uptime
# --------------------------------------------------------------------------------------------------
update_server_uptime()
{
    WSERVER=$1                                                          # Server Name to Update
    WUPTIME=$2                                                          # Uptime value to store
    WCURDAT=`date "+%C%y.%m.%d %H:%M:%S"`                               # Get & Format Update Date

    SQL1="UPDATE server SET "                                           # SQL Update Statement
    SQL2="srv_uptime = '$WUPTIME', "                                    # System uptime value
    SQL3="srv_date_update = '${WCURDAT}' "                              # Last Update Date
    SQL4=" "                                                            # Last Boot Date
    SQL5="where srv_name = '${WSERVER}' ;"                              # Server name to update
    SQL="${SQL1}${SQL2}${SQL3}${SQL4}${SQL5}"                           # Create final SQL Statement

    WAUTH="-u $SADM_RW_DBUSER  -p$SADM_RW_DBPWD "                       # Set Authentication String 
    CMDLINE="$SADM_MYSQL $WAUTH "                                       # Join MySQL with Authen.
    CMDLINE="$CMDLINE -h $SADM_DBHOST $SADM_DBNAME -e '$SQL'"           # Build Full Command Line
    if [ $SADM_DEBUG -gt 5 ] ; then sadm_write "${CMDLINE}\n" ; fi      # Debug = Write command Line

    # Execute SQL to Update Server O/S Data
    $SADM_MYSQL $WAUTH -h $SADM_DBHOST $SADM_DBNAME -e "$SQL" >>$SADM_LOG 2>&1
    if [ $? -ne 0 ]                                                     # If Error while updating
        then sadm_writelog "${SADM_ERROR} Failed to update database 'uptime' ($WUPTIME) of $WSERVER"
             RCU=1                                                      # Set Error Code = 1
        else sadm_writelog "${SADM_OK} Success updating database 'uptime' ($WUPTIME) of $WSERVER"
             RCU=0                                                      # Set Code = Success =0
    fi
    return $RCU
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
        then sadm_writelog "Invalid number of argument received by function ${FUNCNAME}."
             sadm_writelog "Should be 8 we received $# : $* "           # Show what received
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

    # If Alert group received is 'default', replace it with group specified in alert_group.cfg
    if [ "$agroup" = "default" ] 
       then galias=`grep -i "^default " $SADM_ALERT_FILE | head -1 | awk '{ print $3 }'` 
            agroup=`echo $galias | awk '{$1=$1;print}'`                 # Del Leading/Trailing Space
       else grep -i "^$agroup " $SADM_ALERT_FILE >/dev/null 2>&1        # Search in Alert Group File
            if [ $? -ne 0 ]                                             # Group Missing in GrpFile
                then sadm_writelog "[ ERROR ] Alert group '$agroup' missing from ${SADM_ALERT_FILE}"
                     sadm_writelog "  - Alert date/time : $atime"       # Show Event Date & Time
                     sadm_writelog "  - Alert subject   : $asubject"    # Show Event Subject
                     return 1                                           # Return Error to caller
            fi
    fi 

    # Display Values received and we will use in this function.
    if [ $LIB_DEBUG -gt 4 ]                                             # Debug Info List what Recv.
       then printf "\n\nFunction '${FUNCNAME}' parameters received :\n" # Print Function Name
            sadm_writelog "atype=$atype"                                # Show Alert Type
            sadm_writelog "atime=$atime"                                # Show Event Date & Time
            sadm_writelog "aserver=$aserver"                            # Show Server Name
            sadm_writelog "ascript=$ascript"                            # Show Script Name
            sadm_writelog "agroup=$agroup"                              # Show Alert Group
            sadm_writelog "asubject=\"$asubject\""                      # Show Alert Subject/Title
            sadm_writelog "amessage=\"$amessage\""                      # Show Alert Message
            sadm_writelog "aattachment=\"$aattach\""                    # Show Alert Attachment File
    fi


    # Mail with more than one attachment (Verify if file do exist)
    opt_a=""                                                            # -a attachment cumulative
    if [ $(expr index "$aattach" ,) -ne 0 ]                             # comma = multiple attach
       then for file in ${aattach//,/ }                                 # Process all Attachment
                do if [ ! -r "$file" ]                                  # Attachment Not Readable ?
                        then emsg="Missing attachment file '$file' can't be read or doesn't exist."
                             sadm_write_err "$emsg"                     # Avise user of error
                             amessage=$(printf "\n${amessage}\n\n${emsg}\n") 
                             RC=1                                       # Set Error return code
                        else opt_a="$opt_a -a $file "                   # Add -a attach Cmd Option
                   fi 
                done
       else if [ "$aattach" != "" ] && [ ! -r "$aattach" ]              # Can't read Attachment File
               then emsg="Missing file attachment '$aattach' can't be read or doesn't exist."
                    sadm_write_err "$emsg"                              # Avise user of error
                    amessage=$(printf "\n${amessage}\n\n${emsg}\n") 
                    RC=1                                                # Set Error return code
            fi 
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
    
    # Message Footer 
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
            LOGNAME="${SADM_WWW_DAT_DIR}/${aserver}/log/${LOGFILE}"     # Add Log Dir. Path 
            URL_VIEW_FILE='/view/log/sadm_view_file.php'                # View File Content URL
            LOGURL="https://sadmin.${SADM_DOMAIN}/${URL_VIEW_FILE}?filename=${LOGNAME}" 
            ELOGFILE="${aserver}_${SNAME}_e.log"                        # Assemble Error log Name
            ELOGNAME="${SADM_WWW_DAT_DIR}/${aserver}/log/${ELOGFILE}"   # Add Error log Dir. Path 
            if [ -s "$ELOGNAME" ]                                       # If Error log not empty
                then ELOGURL="https://sadmin.${SADM_DOMAIN}/${URL_VIEW_FILE}?filename=${ELOGNAME}" 
                     body=$(printf "${body}\nError log :\n${ELOGURL}\nView full log :\n${LOGURL}") 
                else body=$(printf "${body}\nView full log :\n${LOGURL}") 
            fi 
    fi
    if [ "$LIB_DEBUG" -gt 4 ] ; then sadm_write "Alert body will be : $body \n" ; fi


    # Send the Alert Message using the type of alert requested
    case "$agroup_type" in

       # SEND EMAIL ALERT 
       M) aemail=`grep -i "^$agroup " $SADM_ALERT_FILE |awk '{ print $3 }'` # Get Emails of Group
          aemail=`echo $aemail | awk '{$1=$1;print}'`                   # Del Leading/Trailing Space
          if [ "$LIB_DEBUG" -gt 4 ] ; then sadm_write "Email alert sent to $aemail \n" ; fi 
          sadm_sendmail "$aemail" "$ws" "$body" "$aattach"
          RC=$?                                                         # Save Error Number
          if [ $RC -ne 0 ]                                              # Error sending email 
              then wstatus="[ Error ] Sending email to $aemail"         # Advise Error sending Email
                   sadm_write "${wstatus}\n"                            # Show Message to user 
          fi
          ;;

       # SEND SLACK ALERT 
       S) s_channel=`grep -i "^$agroup " $SADM_ALERT_FILE | head -1 | awk '{ print $3 }'` 
          s_channel=`echo $s_channel | awk '{$1=$1;print}'`             # Del Leading/Trailing Space
          slack_hook_url=`grep -i "^$agroup " $SADM_ALERT_FILE | head -1 | awk '{ print $4 }'` 
          slack_hook_url=`echo $s_channel | awk '{$1=$1;print}'`        # Del Leading/Trailing Space
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
# Command line Options functions
# Evaluate Command Line Switch Options Upfront
# By Default (-h) Show Help Usage, (-v) Show Script Version,(-d0-9] Set Debug Level 
# --------------------------------------------------------------------------------------------------
function cmd_options()
{
    #echo -e "\nALL = $@ \n\n"
    while getopts "d:hv" opt ; do                                       # Loop to process Switch
        case $opt in
            d) SADM_DEBUG=$OPTARG                                       # Get Debug Level Specified
               num=`echo "$SADM_DEBUG" | grep -E ^\-?[0-9]?\.?[0-9]+$`  # Valid is Level is Numeric
               if [ "$num" = "" ]                                       # No it's not numeric 
                  then printf "\nDebug Level specified is invalid.\n"   # Inform User Debug Invalid
                       show_usage                                       # Display Help Usage
                       exit 1                                           # Exit Script with Error
               fi
               printf "Debug Level set to ${SADM_DEBUG}."               # Display Debug Level
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



# --------------------------------------------------------------------------------------------------
#                                       Script Start HERE
# --------------------------------------------------------------------------------------------------
#
    cmd_options "$@"                                                    # Check command-line Options    
    sadm_start                                                          # Create Dir.,PID,log,rch
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if 'Start' went wrong
    main_process                                                        # rsync from all clients
    SADM_EXIT_CODE=$?                                                   # Save Function Result Code 
    sadm_stop $SADM_EXIT_CODE                                           # Close/Trim Log & Upd. RCH
    exit $SADM_EXIT_CODE                                                # Exit With Error code (0/1)
