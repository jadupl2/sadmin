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
# 2023_07_18 server v3.45 Fix when not using the standard ssh port (22).
# 2023_09_18 server v3.46 Enhance purge of old '*.nmon' files.
# 2023_12_17 server v3.47 Modification that allow SADMIN server IP to be an IP alias.
#@2024_04_16 server v3.48 Replace 'sadm_write' with 'sadm_write_log' and 'sadm_write_err'.
#@2024_10_31 server v3.49 Add code to update schedule of VirtualBox VM export in crontab 'sadm_vm'.
#@2024_11_11 server v3.50 Add creation of list of all VMs '$SADM_VMLIST' & VM Hosts '$SADM_VMHOSTS'.
#@2025_01_24 server v3.51 Bug fixes & refine lock detection vs Monitor page.
#@2025_01_29 server v3.52 Change 'sadm_vm' crontab update to use 'sadm_rmcmd_lock' to lock/unlock system.
#@2025_03_25 server v3.53 Refine way to copy local rch,log  and rpt to farm www directory.
#@2025_04_13 server v3.54 Add hostname in the email subject, if not already there.
#@2025_05_19 server v3.55 When server not accessible, the uptime is set to date/time of offline.
#@2025_05_26 server v3.56 Don't process system that are lock (no crontab entries)
#@2025_05_31 server v3.57 Avoid faulty error message when copying rpt.
#@2025_08_27 server v3.58 Create list of VMs in $SADMIN/www/dat "global_vm_list.txt" & "global_vm_hosts.txt"
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

# YOU CAN USE & CHANGE VARIABLES BELOW TO YOUR NEEDS (They influence execution of SADMIN Library).
export SADM_VER='3.58'                                     # Script version number
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
export ERROR_COUNT=0                                                    # Total Error Count
export WARNING_COUNT=0                                                  # Total Warning count
export SADM_TEN_DASH=$(printf %10s |tr " " "-")                         # 10 dashes line
#
# Variables used to insert in /etc/cron.d/sadm* crontab files.
export OS_SCRIPT="sadm_osupdate_starter.sh"                             # OSUpdate Script in crontab
export BA_SCRIPT="sadm_backup.sh"                                       # Backup Script 
export REAR_SCRIPT="sadm_rear_backup.sh"                                # ReaR Backup Script 
export EXPORT_SCRIPT="sadm_vm_export.sh"                                # VM export Script 
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
    if [ $SADM_DEBUG -gt 4 ] 
        then sadm_write_log " "
             sadm_write_log "----------" 
             sadm_write_log "I'm in update_osupdate_crontab for $cserver"
             sadm_write_log "cserver  = $cserver"                        # Server to run script
             sadm_write_log "cscript  = $cscript"                        # Script to execute
             sadm_write_log "cmonth   = $cmonth"                         # Month String YNYNYNYNYNY..
             sadm_write_log "cdom     = $cdom"                           # Day of MOnth String YNYN..
             sadm_write_log "cdow     = $cdow"                           # Day of Week String YNYN...
             sadm_write_log "chour    = $chour"                          # Hour to run script
             sadm_write_log "cmin     = $cmin"                           # Min. to run Script
             sadm_write_log "cronfile = $SADM_CRON_FILE"                 # Name of Output file
    fi
    
    # Begin constructing our crontab line ($cline) - Based on Hour and Min. Received ---------------
    cline=$(printf "%02d %02d" "$cmin" "$chour")                        # Hour & Min. of Execution
    if [ $SADM_DEBUG -gt 5 ] ; then sadm_write_log "cline=.$cline.";fi  # Show Cron Line Now


    # Construct DATE of the month (1-31) to run and add it to crontab line ($cline) ----------------
    flag_dom=0
    if [ "$cdom" = "YNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN" ]                 # Can run at any date 
        then cline="$cline *"                                           # Then use a Star for Date
        else fdom=""                                                    # Clear Final Date of Month
             for i in $(seq 2 32)
                do    
                wchar=$(expr substr $cdom $i 1)
                if [ $SADM_DEBUG -gt 5 ] ; then echo "cdom[$i] = $wchar" ; fi
                xmth=$(expr $i - 1)                                     # Date = Index -1 ,Cron Mth
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
    if [ $SADM_DEBUG -gt 5 ] ; then sadm_write_log "cline=.$cline.";fi  # Show Cron Line Now


    # Construct the month(s) (1-12) to run the script and add it to crontab line ($cline) ----------
    flag_mth=0
    if [ "$cmonth" = "YNNNNNNNNNNNN" ]                                  # 1st Ch=Y,can run every Mth
        then cline="$cline *"                                           # Then use a Star for Month
        else fmth=""                                                    # Clear Final Date of Month
             for i in $(seq 2 13)                                       # Check Each Mth 2-13 = 1-12
                do                                                      # Get Y or N for the Month 
                wchar=$(expr substr $cmonth $i 1)
                xmth=$(expr $i - 1)                                     # Mth = Index -1 ,Cron Mth
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
    if [ $SADM_DEBUG -gt 5 ] ; then sadm_write_log "cline=.$cline.";fi  # Show Cron Line Now


    # Construct the day of the week (0-6) to run the script and add it to crontab line ($cline) ----
    flag_dow=0
    if [ "$cdow" = "YNNNNNNN" ]                                         # 1st Ch=Y,can run every day
        then cline="$cline *"                                           # Then use Star for All Week
        else fdow=""                                                    # Final Day of Week Flag
             for i in $(seq 2 8)                                        # Check Each Day 2-8 = 0-6
                do                                                      # Day of the week (dow)
                wchar=$(expr substr "$cdow" $i 1)                       # Get Char of loop
                if [ $SADM_DEBUG -gt 5 ] ; then echo "cdow[$i] = $wchar" ; fi
                if [ "$wchar" = "Y" ]                                   # If Day is Yes 
                    then xday=$(expr $i - 2)                             # Adjust Indx to Crontab Day
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
    if [ $SADM_DEBUG -gt 5 ] ; then sadm_write_log "cline=.$cline.";fi  # Show Cron Line Now
    
    
    # Add User, script name and script parameter to crontab line -----------------------------------
    # SCRIPT WILL RUN ONLY IF LOCATED IN $SADMIN/BIN 
    # $SADM_TMP_DIR
    cline="$cline $SADM_USER sudo $cscript $cserver >/dev/null 2>&1";   
    if [ $SADM_DEBUG -gt 2 ] ; then sadm_write_log "cline='$cline'" ; fi  # Show Cron Line Now
    echo "$cline" >> $SADM_CRON_FILE                                    # Output Line to Crontab cfg
    return 0
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
    if [ "$SADM_DEBUG" -gt 4 ] 
        then sadm_write_log " "
             sadm_write_log "----------" 
             sadm_write_log "[ DEBUG ] I'm in update rear crontab for '$cserver'"
             sadm_write_log "[ DEBUG ] cserver  = $cserver"                        # Server to run script
             sadm_write_log "[ DEBUG ] cscript  = $cscript"                        # Script to execute
             sadm_write_log "[ DEBUG ] cmonth   = $cmonth"                         # Month String YNYNYNYNYNY..
             sadm_write_log "[ DEBUG ] cdom     = $cdom"                           # Day of MOnth String YNYN..
             sadm_write_log "[ DEBUG ] cdow     = $cdow"                           # Day of Week String YNYN...
             sadm_write_log "[ DEBUG ] chour    = $chour"                          # Hour to run script
             sadm_write_log "[ DEBUG ] cmin     = $cmin"                           # Min. to run Script
             sadm_write_log "[ DEBUG ] cronfile = $SADM_REAR_NEWCRON"              # Name of Output file
    fi
    
    # Begin constructing our crontab line ($cline) - Based on Hour and Min. Received ---------------
    cline=$(printf "%02d %02d" "$cmin" "$chour")                        # Hour & Min. of Execution

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
    if [ $SADM_DEBUG -gt 5 ] ; then sadm_write_log "cline='$cline'";fi  # Show Cron Line Now


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
    if [ $SADM_DEBUG -gt 5 ] ; then sadm_write_log "cline='$cline'";fi  # Show Cron Line Now


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
    if [ $SADM_DEBUG -gt 5 ] ; then sadm_write_log "cline='$cline'";fi  # Show Cron Line Now
    
    
    # Add User, script name and script parameter to crontab line -----------------------------------
    # SCRIPT WILL RUN ONLY IF LOCATED IN $SADMIN/BIN 
    # $SADM_TMP_DIR
    if [ "$SADM_HOSTNAME" != "$cserver" ]  
        then cline="$cline $SADM_USER sudo ${SADM_SSH} -qnp $SSH_PORT $cserver \"$cscript\" >/dev/null 2>&1";
        else cline="$cline $SADM_USER sudo \"$cscript\" >/dev/null 2>&1";
    fi 
    if [ $SADM_DEBUG -gt 0 ] ; then sadm_write_log "cline='$cline'" ; fi  # Show Cron Line Now

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

    cline=$(printf "%02d %02d" "$cmin" "$chour")                        # Hour & Min. of Execution
    if [ $SADM_DEBUG -gt 4 ] 
        then sadm_write_log " "
             sadm_write_log "----------" 
             sadm_write_log "I am in update_backup_crontab for '$cserver'." 
    fi 
    cline="$cline * * * "

    # Add argument -n if the backup is to be compress.
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

    # Add line to backup crontab tmp work file
    if [ $SADM_DEBUG -gt 4 ] ; then sadm_write_log "cline='$cline'" ; fi 
    echo "$cline" >> $SADM_BACKUP_NEWCRON                               # Output Line to Crontab cfg
}




# ==================================================================================================
# update_vmexport_crontab () 
#
# Update the export crontab work file based on the parameters received
#
# Parameters: 
#   (1) cserver   Name of virtual system to export.
#   (2) cscript   The name of the script to executed
#   (3) cmin      Minute when the update will begin (00-59)
#   (4) chour     Hour when the update should begin (00-23)
#   (5) cmonth    13 Characters (either a Y or a N) each representing a month (YNNNNNNNNNNNN)
#                 Position 0 = Y Then ALL Months are Selected
#                 Position 1-12 represent the month that are selected (Y or N)             
#                 Default is YNNNNNNNNNNNN meaning will run every month 
#   (6) cdom      32 Characters (either a Y or a N) each representing a day (1-31) Y=Update N=No Update
#                 Position 0 = Y Then ALL Date in the month are Selected
#                 Position 1-31 Indicate (Y) date of the month that script will run or not (N)
#   (7) cdow      8 Characters (either a Y or a N) 
#                 If Position 0 = Y then will run every day of the week
#                 Position 1-7 Indicate a week day () Starting with Sunday
#                 Default is all Week (YNNNNNNN)
#   (8)           SSH port to communicate with the system
#
# Example of line generated
# 00 13 05,27 * * sadmin sudo /usr/bin/ssh -qnp 32 jacques@anemone '$SADMIN/bin/sadm_vm_export.sh ubuntu2204'
#
# ==================================================================================================
update_vmexport_crontab () 
{
    cserver=$1                                                          # Server Name to export 
    cscript=$2                                                          # Export Script to Run
    cmin=$3                                                             # Crontab Minute
    chour=$4                                                            # Crontab Hour
    cmonth=$5                                                           # Crontab Mth (YNNNN) Format
    cdom=$6                                                             # Crontab DOM (YNNNN) Format
    cdow=$7                                                             # Crontab DOW (YNNNN) Format
    SSH_PORT=$8                                                         # SSH Port Number 
    chost=$9                                                            # VirtualBox Hostname

    # To Display Parameters received - Used for Debugging Purpose ----------------------------------
    if [ $SADM_DEBUG -gt 4 ] 
        then sadm_write_log " "
             sadm_write_log "----------" 
             sadm_write_log "I'm in update_vmexport_crontab for '$cserver'"
             sadm_write_log "cserver  = $cserver"                        # Server to export
             sadm_write_log "chost    = $chost"                          # VirtualBox Hostname
             sadm_write_log "cscript  = $cscript"                        # Script to execute
             sadm_write_log "cmonth   = $cmonth"                         # Month String YNYNYNYNYNY..
             sadm_write_log "cdom     = $cdom"                           # Day of MOnth String YNYN..
             sadm_write_log "cdow     = $cdow"                           # Day of Week String YNYN...
             sadm_write_log "chour    = $chour"                          # Hour to run script
             sadm_write_log "cmin     = $cmin"                           # Min. to run Script
             sadm_write_log "cronfile = $SADM_VMEXPORT_NEWCRON"          # Name of Output file
    fi
    
    # Begin constructing our crontab line ($cline) - Based on Hour and Min. Received ---------------
    cline=$(printf "%02d %02d" "$cmin" "$chour")                        # Hour & Min. of Execution
    if [ $SADM_DEBUG -gt 5 ] ; then sadm_write_log "cline='$cline'";fi  # Show Cron Line Now


    # Construct DATE OF THE MONTH (1-31) to run and add it to crontab line ($cline) ----------------
    flag_dom=0
    if [ "$cdom" = "YNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN" ]                 # If it's to run every Date
        then cline="$cline *"                                           # Then use a Star for Date
        else fdom=""                                                    # Clear Final Date of Month
             for i in $(seq 2 32)
                do    
                wchar=$(expr substr $cdom $i 1)
                if [ $SADM_DEBUG -gt 5 ] ; then echo "cdom[$i] = $wchar" ; fi
                xmth=$(expr $i - 1)                                     # Date = Index -1 ,Cron Mth
                if [ "$wchar" = "Y" ]                                   # If Date Set to Yes 
                    then if [ $flag_dom -eq 0 ]                         # If First Date to Run 
                            then fdom=$(printf "%02d" "$xmth")          # Add Date to Final DOM
                                 flag_dom=1                             # No Longer the first date
                            else wdom=$(printf "%02d" "$xmth")          # Format the Date number
                                 fdom=$(echo "${fdom},${wdom}")         # Combine Final+New Date
                         fi
                fi                                                      # If Date is set to No
                done                                                    # End of For Loop
             cline="$cline $fdom"                                       # Add DOM in Crontab Line
    fi
    if [ $SADM_DEBUG -gt 5 ] ; then sadm_write_log "cline=.$cline.";fi  # Show Cron Line Now


    # Construct the MONTH(S) (1-12) to run the script and add it to crontab line ($cline) ----------
    flag_mth=0
    if [ "$cmonth" = "YNNNNNNNNNNNN" ]                                  # 1st Char=Y = run every Mth
        then cline="$cline *"                                           # Then use a Star for Month
        else fmth=""                                                    # Clear Final Date of Month
             for i in $(seq 2 13)                                       # Check Each Mth 2-13 = 1-12
                do                                                      # Get Y or N for the Month 
                wchar=$(expr substr $cmonth $i 1)
                xmth=$(expr $i - 1)                                     # Mth = Index -1 ,Cron Mth
                if [ "$wchar" = "Y" ]                                   # If Month Set to Yes 
                    then if [ $flag_mth -eq 0 ]                         # If 1st Insert in Cron Line
                            then fmth=$(printf "%02d" "$xmth")          # Add Month to Final Months
                                 flag_mth=1                             # No Longer the first Month
                            else wmth=$(printf "%02d" "$xmth")          # Format the Month number
                                 fmth=$(echo "${fmth},${wmth}")          # Combine Final+New Months
                         fi
                fi                                                      # If Month is set to No
                done                                                    # End of For Loop
             cline="$cline $fmth"                                       # Add Month in Crontab Line
    fi
    if [ $SADM_DEBUG -gt 5 ] ; then sadm_write_log "cline=.$cline.";fi  # Show Cron Line Now


    # Construct the DAY OF THE WEEK (0-6) to run the script and add it to crontab line ($cline) ----
    flag_dow=0
    if [ "$cdow" = "YNNNNNNN" ]                                         # 1st Char=Y Run all dayWeek
        then cline="$cline *"                                           # Then use Star for All Week
        else fdow=""                                                    # Final Day of Week Flag
             for i in $(seq 2 8)                                        # Check Each Day 2-8 = 0-6
                do                                                      # Day of the week (dow)
                wchar=$(expr substr "$cdow" $i 1)                       # Get Char of loop
                if [ $SADM_DEBUG -gt 5 ] ; then echo "cdow[$i] = $wchar" ; fi
                if [ "$wchar" = "Y" ]                                   # If Day is Yes 
                    then xday=$(expr $i - 2)                            # Adjust Indx to Crontab Day
                         if [ $SADM_DEBUG -gt 5 ] ; then echo "xday = $xday" ; fi
                         if [ $flag_dow -eq 0 ]                         # If First Day to Insert
                            then fdow=$(printf "%02d" "$xday")          # Add day to Final Day
                                 flag_dow=1                             # No Longer the first Insert
                            else wdow=$(printf "%02d" "$xday")          # Format the day number
                                 fdow=$(echo "${fdow},${wdow}")         # Combine Final+New Day
                         fi
                fi                                                      # If DOW is set to No
                done                                                    # End of For Loop
             cline="$cline $fdow"                                       # Add DOW in Crontab Line
    fi

    cline="$cline $SADM_USER sudo \$RMCMD_LOCK -u ${SADM_VM_USER} -n $chost -l $cserver -s $cscript -a $cserver" 
    if [ $SADM_DEBUG -gt 2 ] ; then sadm_write_log "cline='$cline'" ;fi 
    echo "$cline" >> $SADM_VMEXPORT_NEWCRON                             # Output Line to VM Crontab 
    return
}




#===================================================================================================
# create_vm_list()
#
# Run for two objectgives : 
# 1- Create file "$SADM_VMLIST" that contain a list of all vms and their respective host.
# 2- Create file "SADMM_VMHOSTS" that contain a list of all vms host.
# 
# Example on content : 
#   lestrade,centos9,/opt/sadmin
#   lestrade,debian12,/opt/sadmin
# 
# Input Parameters : None 
#
# Return Value : None
#
#===================================================================================================
create_vm_list()
{
    # Delete old files
    if [ -f "$SADM_VMLIST_ALL" ]  ; then rm -f "$SADM_VMLIST_ALL" >/dev/null ; fi  # Global VM List
    if [ -f "$SADM_VMHOST_ALL" ]  ; then rm -f "$SADM_VMHOST_ALL" >/dev/null ; fi  # VM host List
    touch "$SADM_VMLIST_ALL" "$SADM_VMHOST_ALL"                         # Create empty files
    chmod 664 "$SADM_VMLIST_ALL" "$SADM_VMHOST_ALL" >/dev/null 2>&1     # With right permission
    chown "$SADM_WWW_USER:$SADM_WWW_GROUP" "$SADM_VMLIST_ALL" "$SADM_VMHOST_ALL" >/dev/null 2>&1

    # Creating VM list file
    sadm_write_log " "                                                  # Separation Blank Line
    sadm_write_log "${SADM_TEN_DASH}"                                   # Print 10 Dash line
    sadm_write_log "${BOLD}${YELLOW}Creating list of all VMs in '$SADM_VMLIST_ALL'.${RESET}"
    find "$SADM_WWW_DAT_DIR" -name "vm_list.txt" -exec cat {} \; | sort > $SADM_VMLIST_ALL
    #chmod 664 "$SADM_VMLIST_ALL" >/dev/null 2>&1
    #chown "$SADM_WWW_USER:$SADM_WWW_GROUP" "$SADM_VMLIST_ALL" >/dev/null 2>&1
    if [ -s "$SADM_VMLIST_ALL" ]                                        # Exist ? & contain data ? 
        then nl "$SADM_VMLIST_ALL"                                      # List Global VM List
        else sadm_write_log "No VM on all systems."                     # Advice nothing to report
             return 0                                                   # No VM then no VM host
    fi 

    # Create VM Hosts, if the list of vm is not empty, create the vm host file from it.
    if [ -s "$SADM_VMLIST_ALL" ]                                        # Exist & contain data     
        then sadm_write_log " "                                         # Separation Blank Line
             sadm_write_log "${BOLD}${YELLOW}Creating list of all VM Hosts '$SADM_VMHOST_ALL'${RESET}"
             awk -F, '{print $1}' "$SADM_VMLIST_ALL" | sort | uniq > $SADM_VMHOST_ALL
             if [ -s "$SADM_VMHOST_ALL" ]                               # Exist ? & Any VM Hosts ? 
                then nl "$SADM_VMHOST_ALL"                              # List All VM Hosts
                else sadm_write_log "No VM Host on all systems."
             fi
             chmod 664 "$SADM_VMHOST_ALL" >/dev/null 2>&1
             chown "$SADM_WWW_USER:$SADM_WWW_GROUP" "$SADM_VMHOST_ALL" >/dev/null 2>&1
    fi 

    sadm_write_log "${SADM_TEN_DASH}"                                   # Print 10 Dash line
    sadm_write_log " "                                                  # Separation Blank Line
    return 0 
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
        then sadm_write_log "Error: Function ${FUNCNAME[0]} didn't receive 2 parameters."
             sadm_write_log "Function received $* and this isn't valid."
             sadm_write_log "Should receive remote directory path and the local directory path." 
             sadm_write_log "The two parameters must both end with a '/' (Important)." 
             return 1
    fi

    # Save rsync information
    REMOTE_DIR="$1"                                                     # user@host:remote directory
    LOCAL_DIR="$2"                                                      # Local Directory

    #sadm_write_log "REMOTE_DIR = $REMOTE_DIR   LOCAL_DIR = $LOCAL_DIR"

    # If Local directory doesn't exist create it 
    if [ ! -d "${LOCAL_DIR}" ] ; then mkdir -p ${LOCAL_DIR} ; chmod 2775 ${LOCAL_DIR} ; fi

    # Rsync remote directory on local directory - On error try 3 times before signaling error
    RETRY=0                                                             # Set Retry counter to zero
    while [ $RETRY -lt 3 ]                                              # Retry rsync 3 times
        do
        RETRY=$((RETRY + 1))
        rsync -ar -e "ssh -p $ssh_port" --delete ${REMOTE_DIR} ${LOCAL_DIR} >/dev/null 2>&1 
        RC=$?                                                           # save error number

        # Consider Error 24 as none critical (Partial transfer due to vanished source files)
        if [ $RC -eq 24 ] ; then RC=0 ; fi                              # Source File Gone is OK

        if [ $RC -ne 0 ]                                                # If Error doing rsync
           then if [ $RETRY -lt 3 ]                                     # If less than 3 retry
                   then sleep 5                                         # Sleep 5Sec. between retries
                        sadm_write_log "[ RETRY $RETRY ] rsync -ar -e 'ssh -p $ssh_port' --delete ${REMOTE_DIR} ${LOCAL_DIR}"
                   else sadm_write_err "$SADM_ERROR $RETRY ] rsync -ar -e 'ssh -p $ssh_port' --delete ${REMOTE_DIR} ${LOCAL_DIR}"
                        break
                fi
           else sadm_write_log "$SADM_OK rsync -ar -e 'ssh -p $ssh_port' --delete ${REMOTE_DIR} ${LOCAL_DIR}"
                break
        fi
        done

    #sadm_write_log "chmod 775 ${LOCAL_DIR}" 
    chmod 775 ${LOCAL_DIR}  >> $SADM_LOG 2>&1
    #sadm_write_log "chmod 664 ${LOCAL_DIR}*" 
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
    echo  "# File generated on $(date '+%C%y.%m.%d %H:%M:%S') by 'sadm_fetch_clients.sh'." >> $REAR_TMP
    echo  "# Every time you modify the '${WSERVER}' ReaR backup or ReaR backup exclude list, "  >> $REAR_TMP
    echo  "# your changes are copied from the sadmin server ($SADM_SERVER) to ${WSERVER} shortly after (Max 5min). " >> $REAR_TMP
    echo  "#${SADM_DASH}" >> $REAR_TMP
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

    #sadm_write_log "scp -CqP${SADM_SSH_PORT} $REAR_CFG ${WSERVER}:/etc/rear/site.conf" 
    #scp -CqP${SADM_SSH_PORT}  $REAR_CFG ${WSERVER}:/etc/rear/site.conf
    #if [ $? -eq 0 ] ; then sadm_write_log "[OK] /etc/rear/site.conf is updated on ${WSERVER}" ;fi
}

# --------------------------------------------------------------------------------------------------
# create_crontab_files_header()
#
# Create standard crontab header for O/S Update, Daily Backup, ReaR Backup and VM export.
#
#  Parameters:
#   None.
#
#  Return Value:
#   0) When crontab files created with success.
#   1) If any error encountered.
# --------------------------------------------------------------------------------------------------
create_crontab_files_header()
{
    if [ "$SADM_DEBUG" -gt 1 ] ; then sadm_write_log "Creating crontab file header." ; fi

    # Header for O/S Update Crontab File
    echo "# "                                                        > "$SADM_CRON_FILE" 
    echo "# SADMIN - Operating System Update Schedule"              >> "$SADM_CRON_FILE" 
    echo "# Please don't edit manually, SADMIN will update it."     >> "$SADM_CRON_FILE"
    echo "# "                                                       >> "$SADM_CRON_FILE" 
    echo "# Min, Hrs, Date, Mth, Day, User, Script"                 >> "$SADM_CRON_FILE"
    echo "# Day 0=Sun 1=Mon 2=Tue 3=Wed 4=Thu 5=Fri 6=Sat"          >> "$SADM_CRON_FILE"
    echo "# "                                                       >> "$SADM_CRON_FILE" 
    echo "SADMIN=$SADM_BASE_DIR"                                    >> "$SADM_CRON_FILE"
    echo "# "                                                       >> "$SADM_CRON_FILE"
    echo "# "                                                       >> "$SADM_CRON_FILE"

    # Header for" Backup Crontab Filn"
    echo "# "                                                        > "$SADM_BACKUP_NEWCRON" 
    echo "# SADMIN Client Backup Schedule"                          >> "$SADM_BACKUP_NEWCRON" 
    echo "# Please don't edit manually, SADMIN will update it."     >> "$SADM_BACKUP_NEWCRON"
    echo "# "                                                       >> "$SADM_BACKUP_NEWCRON" 
    echo "# Min, Hrs, Date, Mth, Day, User, Script"                 >> "$SADM_BACKUP_NEWCRON"
    echo "# Day 0=Sun 1=Mon 2=Tue 3=Wed 4=Thu 5=Fri 6=Sat"          >> "$SADM_BACKUP_NEWCRON"
    echo "# "                                                       >> "$SADM_BACKUP_NEWCRON" 
    echo "SADMIN=$SADM_BASE_DIR"                                    >> "$SADM_BACKUP_NEWCRON"
    echo "# "                                                       >> "$SADM_BACKUP_NEWCRON"
    echo "# "                                                       >> "$SADM_BACKUP_NEWCRON"

    # Header for Rear Crontab File
    echo "# "                                                        > "$SADM_REAR_NEWCRON"
    echo "# SADMIN Client ReaR Schedule"                            >> "$SADM_REAR_NEWCRON"
    echo "# Please don't edit manually, SADMIN will update it."     >> "$SADM_REAR_NEWCRON"
    echo "# "                                                       >> "$SADM_REAR_NEWCRON"
    echo "# Min, Hrs, Date, Mth, Day, User, Script"                 >> "$SADM_REAR_NEWCRON"
    echo "# Day 0or7=Sun 1=Mon 2=Tue 3=Wed 4=Thu 5=Fri 6=Sat"       >> "$SADM_REAR_NEWCRON"
    echo "# "                                                       >> "$SADM_REAR_NEWCRON"
    echo "SADMIN=$SADM_BASE_DIR"                                    >> "$SADM_REAR_NEWCRON"
    echo "# "                                                       >> "$SADM_REAR_NEWCRON"
    echo "# "                                                       >> "$SADM_REAR_NEWCRON"

    # Header for Virtual system export 
    echo "# "                                                        > "$SADM_VMEXPORT_NEWCRON"
    echo "# SADMIN Client VM Export Schedule"                       >> "$SADM_VMEXPORT_NEWCRON"
    echo "# Please don't edit manually, SADMIN will update it."     >> "$SADM_VMEXPORT_NEWCRON"
    echo "# "                                                       >> "$SADM_VMEXPORT_NEWCRON"
    echo "# Min, Hrs, Date, Mth, Day, User, Script"                 >> "$SADM_VMEXPORT_NEWCRON"
    echo "# Day = 0or7=Sun 1=Mon 2=Tue 3=Wed 4=Thu 5=Fri 6=Sat"     >> "$SADM_VMEXPORT_NEWCRON"
    echo "# "                                                       >> "$SADM_VMEXPORT_NEWCRON"
    echo "SADMIN=$SADM_BASE_DIR"                                    >> "$SADM_VMEXPORT_NEWCRON"
    echo "RMCMD_LOCK=\$SADMIN/bin/sadm_rmcmd_lock.sh"               >> "$SADM_VMEXPORT_NEWCRON"
    echo "# "                                                       >> "$SADM_VMEXPORT_NEWCRON"
    echo "# "                                                       >> "$SADM_VMEXPORT_NEWCRON"

    return 0
}



# --------------------------------------------------------------------------------------------------
# check_host_connectivity()
#
#   Validate SSH Server Connectivity 
#
#  Parameters:
#   1) Host name (FQDN, with domain) of the system to test connectivity.
#   2) SSH port number used to communicate to system.
#
#  Return Value:
#   0) Server Accessible, ssh worked
#   1) Error : 
#       - Can't SSH to Server
#       - Missing Parameter received
#       - Hostname Unresolvable
#   2) Warning, skip server (Sporadic System or Monitor is OFF)
#
# --------------------------------------------------------------------------------------------------
check_host_connectivity()
{
    if [ "$SADM_DEBUG" -ne 0 ] ; then sadm_write_log "$FUNCNAME[0] of $1 on port $2" ;fi


    # If parameters received is not 2, return error to caller
    if [ $# -ne 2 ]
        then sadm_write_log "Error: Function $FUNCNAME[0] did not receive 2 parameters."
             sadm_write_log "Function received $* and this is not valid."
             sadm_write_log "Should have received the fqdn of the server and the ssh port number."
             return 1
    fi

    FQDN_SNAME="$1"                                                     # Server Name Full Qualified
    SSH_PORT="$2"                                                       # Port No. to SSH to system
    SNAME=$(echo "$FQDN_SNAME" | awk -F\. '{print $1}')                 # System Name without Domain


    # Can we resolve the hostname ?
    if ! host "$SNAME" >/dev/null 2>&1                                  # Name is resolvable ? 
           then SMSG="Can't process '$SNAME', because hostname can't be resolved."
                sadm_write_err "[ ERROR ] ${SMSG}"                      # Advise user
                return 1                                                # Return Error to Caller
    fi


    # Get uptime of remote system & we are testing at same time if ssh to remote system is working.
    if [ "$SADM_HOST_TYPE" = "S" ]                                      # If on the SADMIN Server    
        then wuptime=$(uptime 2>/dev/null)                              # Get local system uptime 
             uptime_rc=$?                                               # Save Result Code
        else wuptime=$($SADM_SSH -qnp $SSH_PORT -o ConnectTimeout=2 -o ConnectionAttempts=2 $FQDN_SNAME uptime 2>/dev/null)
             uptime_rc=$?                                               # Save Result Code
    fi

    # Update system uptime in the Database, if was able to obtain the uptime of the system, 
    if [ "$uptime_rc" -eq 0 ]                                           # Was able to get uptime
        then GLOB_UPTIME=$(echo "$wuptime" |awk -F, '{print $1}' |awk '{gsub(/^[ ]+/,""); print $0}')
             update_server_uptime "$SNAME" "$GLOB_UPTIME"               # Update Server Uptime in DB
             return 0
        else echo "$server_uptime" | grep -iq "up"                      # Grep for "up" in uptime? 
             if [ $? -eq 0 ]                                            # String "up" is in uptime
                then GLOB_UPTIME="OFF $(date "+%C%y.%m.%d %H:%M")"      # Date/Time came offline
                     update_server_uptime "$SNAME" "$GLOB_UPTIME"       # Update system uptime in DB
             fi
    fi 

    # SSH didn't work, but is it a sporadic system (Laptop,Test... system) don't report as an error)
    if [ $uptime_rc -ne 0 ]  && [ "$server_sporadic" = "1" ]            # If Error on Sporadic Host
        then sadm_write_log "[ WARNING ] Can't SSH to $SNAME (Sporadic System)."
             return 2                                                   # Return Skip Code to caller
    fi 

    # SSH didn't work, but monitoring for that system is off (don't report an error)
    if [ $uptime_rc -ne 0 ]  &&  [ "$server_monitor" = "0" ]            # If system monitoring OFF
        then sadm_write_log "[ WARNING ] Can't SSH to $SNAME (Monitoring is OFF)."
             return 2                                                   # Return Skip Code to caller
    fi 

    # We know that SSH to the system is not working at this point
    RPT_MSG="Can't SSH to $SNAME (System may be down)" 
    sadm_write_err "[ ERROR ] $RPT_MSG" 
    
    # Create Error Line in Global Error Report File (rpt)
    RPT_DATE=$(date "+%Y.%m.%d;%H:%M")                                     # Current Date/Time
    update_rpt_file "E" "$SNAME" "$(sadm_get_ostype)" "NETWORK" "$RPT_MSG" "$SADM_ALERT_GROUP" "$SADM_ALERT_GROUP"
    return 1    
}





# --------------------------------------------------------------------------------------------------
# update_rpt_file()
#
# Update the host SysMon report (rpt) 
#
# Input Parameters :
#   1) State of the report line (1 Char - Lower or Upper case).
#       'I' = Information line
#       'W' = Warning line
#       'E' = Error line
#       'S' = Script 
#   2) System Host Name
#   3) Operating System (LINUX,DARWIN or AIX)
#   4) SubModule (One of these ; NETWORK,SCRIPT,HTTP,HTTPS,DAEMON,SERVICE)
#   5) Message concerning the event (String)
#   6) Warning Alert Group Name (String)
#   7) Error Alert Group Name (String)
# 
# The rpt file is created ans the formatted rpt line is output to the filee.
# Fields in this file are ';' delimited.
#
# Example of rpt line: 
#  Warning;sherlock;2025.01.19;11:43;linux;FILESYSTEM;Filesystem /data at 92% >= 90%;default;default
# --------------------------------------------------------------------------------------------------
update_rpt_file()
{
    if [ $# -ne 7 ]
        then sadm_write_log "Invalid number of argument received by function ${FUNCNAME}."
             sadm_write_log "Should be 7, but we received $# : $* "     # Show what received
             return 1                                                   # Return Error to caller
    fi
    
    RPT_STAT="$1"
    RPT_HOST="$2"
    RPT_OSNAME="$3"
    RPT_MODULE="$4"
    RPT_MSG="$5"
    RPT_WGRP="$6"
    RPT_EGRP="$7"

    if [ "$SADM_DEBUG" -gt 2 ] 
        then sadm_write_log "[ DEBUG ] In function ${FUNCNAME}."
             sadm_write_log "[ DEBUG ] RPT_STAT=$RPT_STAT"
             sadm_write_log "[ DEBUG ] RPT_HOST=$RPT_HOST"
             sadm_write_log "[ DEBUG ] RPT_OSNAME=$RPT_OSNAME"
             sadm_write_log "[ DEBUG ] RPT_MODULE=$RPT_MODULE"
             sadm_write_log "[ DEBUG ] RPT_MSG=$RPT_MSG"
             sadm_write_log "[ DEBUG ] RPT_WGRP=$RPT_WGRP"
             sadm_write_log "[ DEBUG ] RPT_EGRP=$RPT_EGRP"
    fi 

    # Set Event Type 
    case "$RPT_STAT" in
        E|e) RPT_STAT="Error"
             ;;  
        W|w) RPT_STAT="Warning" 
             ;;  
        I|i) RPT_STAT="Info"
             ;;  
        S|s) RPT_STAT="Script" 
             ;;  
        *) RPT_STAT="Invalid status type '$1' "
           ;;
    esac

    RPT_DATE=$(date "+%Y.%m.%d")                                       
    RPT_TIME=$(date "+%H:%M")                                       
    RPTLINE="${RPT_STAT};${RPT_HOST};${RPT_DATE};${RPT_TIME};${RPT_OSNAME}" 
    RPTLINE="${RPTLINE};${RPT_MODULE};${RPT_MSG};${RPT_WGRP};${RPT_EGRP};"
    echo "$RPTLINE" >> $FETCH_RPT_LOCAL                                 # SADMIN Server Monitor rpt
    echo "$RPTLINE" >> $FETCH_RPT_GLOBAL                                # SADMIN WWW All System rpt 

    if [ "$SADM_DEBUG" -gt 2 ] 
        then sadm_write_log "[ DEBUG ] In function ${FUNCNAME}, Line added to $FETCH_RPT_LOCAL ."
             sadm_write_log "[ DEBUG ] $RPTLINE" 
    fi 
    return 0 
}




# --------------------------------------------------------------------------------------------------
# build_server_list()
#
# Build a system list of the O/S type (aix/linux,darwin) received in parameter.
#
# Input Parameters :
#   None
# 
# Output resultant :
#  File $SADM_TMP_FILE1 contains system list for wanted O/S type with fields neened for processing.
#  Fields in this file are ';' delimited.
# --------------------------------------------------------------------------------------------------
build_server_list()
{ 
    if [ "$SADM_DEBUG" -gt 1 ] 
        then sadm_write_log " "
             sadm_write_log "----------" 
             sadm_write_log "In function ${FUNCNAME[0]}." 
    fi 

    
    # Build the SQL select statement for active systems
    # System Info   1        2          3          4           5            6        
    SQL="SELECT srv_name,srv_ostype,srv_domain,srv_monitor,srv_sporadic,srv_sadmin_dir, " 

    # OS Update info to produce crontab (/etc/cron.d/sadm_osupdate)
    # OS Update     7                 8               9              10               11    
    SQL="${SQL} srv_update_minute,srv_update_hour,srv_update_dom,srv_update_month,srv_update_dow,"
    #               12              
    SQL="${SQL} srv_update_auto, "
    
    # Backup Info to produce backup crontab (/etc/cron.d/sadm_backup)
    #               13         14               15         16                 17
    SQL="${SQL} srv_backup,srv_backup_month,srv_backup_dom,srv_backup_dow,srv_backup_hour,"
    #               18  
    SQL="${SQL} srv_backup_minute," 

    # Rear backup Info to produce ReaR crontab (/etc/cron.d/sadm_rear)
    #               19             20            21          22          23           24    
    SQL="${SQL} srv_img_backup,srv_img_month,srv_img_dom,srv_img_dow,srv_img_hour,srv_img_minute, "
    #               25           26  
    SQL="${SQL} srv_ssh_port,srv_backup_compress,"

    # Virtual Machine export Info use to produce VM export schedule.
    #               27           28               29             30             31    
    SQL="${SQL} srv_vm_type, srv_export_sched,srv_export_ova,srv_export_mth,srv_export_dom,"
    #               32             33             34             35          36     37   
    SQL="${SQL} srv_export_dow,srv_export_hrs,srv_export_min,srv_vm_host,srv_vm,srv_vm_version," 

    
    # General info 
    #               38          39
    SQL="${SQL} srv_uptime, srv_lock "
    #
    SQL="${SQL} from server"
    SQL="${SQL} where srv_active = True "
    SQL="${SQL} order by srv_name; "                                    # Order Output by ServerName

    # Setup database connection parameters
    WAUTH="-u $SADM_RO_DBUSER  -p$SADM_RO_DBPWD "                       # Set Authentication String 
    CMDLINE="$SADM_MYSQL $WAUTH "                                       # Join MySQL with Authen.
    CMDLINE="$CMDLINE -h $SADM_DBHOST $SADM_DBNAME -N -e '$SQL' | tr '/\t/' '/;/'" # Build CmdLine
    if [ "$SADM_DEBUG" -gt 7 ] ; then sadm_write_log "${CMDLINE}" ; fi  # Debug = Write command Line

    # Try simple sql statement to test connection to database
    $SADM_MYSQL $WAUTH -h $SADM_DBHOST -e "show databases;" > /dev/null 2>&1
    if [ $? -ne 0 ]                                                     # Error Connecting to DB
        then sadm_write_err "[ ERROR ] Error connecting to Database."   # Access Denied
             return 1                                                   # Return Error to Caller
    fi 


    # Execute sql to get a list of active servers of the received o/s type into $sadm_tmp_file1
    $SADM_MYSQL $WAUTH -h $SADM_DBHOST $SADM_DBNAME -N -e "$SQL" | tr '/\t/' '/;/' >$SADM_TMP_FILE1
    
    if [ $SADM_DEBUG -gt 7 ] 
        then sadm_write_log " "
             sadm_write_log "----------" 
             sadm_write_log "Content a the file created by the SQL:"
             cat $SADM_TMP_FILE1 | tee -a $SADM_LOG 
    fi 
    # If result file don't exist or have a size of zero.
    if [ ! -s "$SADM_TMP_FILE1" ]                                       # File don't exist or size=0
       then sadm_write_err "[ ERROR ] List of server '${SADM_TMP_FILE1}' is empty or don't exist ? "
            sadm_write_log "  - No Active system in SADMIN database"    # Not one active system msg.
            return 1 
    fi   
}





# --------------------------------------------------------------------------------------------------
# process_servers()
#
# Process each Operating System received in parameter (aix/linux,darwin)
# 
#--------------------------------------------------------------------------------------------------
process_servers()
{
    if [ "$SADM_DEBUG" -gt 1 ] ; then sadm_write_log "In function ${FUNCNAME[0]}." ; fi

    # Build a list of active system of the O/S type received and output to $SADM_TMP_FILE1 file.
    build_server_list                                                   # Create List in TMP_FILE1
    if [ $? -ne 0 ] ; then return 1 ; fi                                # Return Error to caller 
    
 
    # Create SADMIN crontab files headers (sadm_backup, sadm_osupdate, sadm_rear_backup, sadm_vm)
    create_crontab_files_header 
    if [ "$SADM_DEBUG" -gt 1 ] ; then sadm_write_log "Returning from create_crontab_file_header" ;fi 

    # Process each servers included in $SADM_TMP_FILE1 created previously by build_server_list()
    xcount=0; ERROR_COUNT=0; WARNING_COUNT=0                            # Initialize Counters 
    while read wline                                                    # Read Server Data from DB
        do                                                              # Line by Line
        xcount=$((xcount + 1))                                          # Incr Server Counter Var.
        server_name=$(    echo $wline|awk -F\; '{ print $1 }')          # Extract Server Name
        server_os=$(      echo $wline|awk -F\; '{ print $2 }')          # Extract O/S (linux/aix)
        server_domain=$(  echo $wline|awk -F\; '{ print $3 }')          # Extract Domain of Server
        server_monitor=$( echo $wline|awk -F\; '{ print $4 }')          # Monitor t=True f=False
        server_sporadic=$(echo $wline|awk -F\; '{ print $5 }')          # Sporadic t=True f=False
        server_dir=$(     echo $wline|awk -F\; '{ print $6 }')          # SADMIN Dir on Client 
        fqdn_server="${server_name}.${server_domain}"                   # Create FQN Server Name

        # O/S Update Info used to produce crontab (/etc/cron.d/sadm_update)
        db_updmin=$(     echo $wline|awk -F\; '{ print $7 }')           # crontab Update Min field
        db_updhrs=$(     echo $wline|awk -F\; '{ print $8 }')           # crontab Update Hrs field
        db_upddom=$(     echo $wline|awk -F\; '{ print $9 }')           # crontab Update DOM field
        db_updmth=$(     echo $wline|awk -F\; '{ print $10 }')          # crontab Update Mth field
        db_upddow=$(     echo $wline|awk -F\; '{ print $11 }')          # crontab Update DOW field 
        db_updauto=$(    echo $wline|awk -F\; '{ print $12 }')          # crontab Update DOW field 
    
        # Backup Info to produce backup crontab (/etc/cron.d/sadm_backup)
        backup_auto=$(  echo $wline|awk -F\; '{ print $13 }')           # crontab Backup 1=Yes 0=No 
        backup_mth=$(   echo $wline|awk -F\; '{ print $14 }')           # crontab Backup Mth field
        backup_dom=$(   echo $wline|awk -F\; '{ print $15 }')           # crontab Backup DOM field
        backup_dow=$(   echo $wline|awk -F\; '{ print $16 }')           # crontab Backup DOW field 
        backup_hrs=$(   echo $wline|awk -F\; '{ print $17 }')           # crontab Backup Hrs field
        backup_min=$(   echo $wline|awk -F\; '{ print $18 }')           # crontab Backup Min field

        # Rear backup Info to produce ReaR crontab (/etc/cron.d/sadm_rear)
        rear_auto=$( echo $wline|awk -F\; '{ print $19 }')              # Rear Crontab 1=Yes 0=No 
        rear_mth=$(  echo $wline|awk -F\; '{ print $20 }')              # Rear Crontab Mth field
        rear_dom=$(  echo $wline|awk -F\; '{ print $21 }')              # Rear Crontab DOM field
        rear_dow=$(  echo $wline|awk -F\; '{ print $22 }')              # Rear Crontab DOW field 
        rear_hrs=$(  echo $wline|awk -F\; '{ print $23 }')              # Rear Crontab Hrs field
        rear_min=$(  echo $wline|awk -F\; '{ print $24 }')              # Rear Crontab Min field
        ssh_port=$(  echo $wline|awk -F\; '{ print $25 }')              # Port No. to SSH to System
        compress=$(  echo $wline|awk -F\; '{ print $26 }')              # Compress (1=Yes,0=No)
        
        # Virtual Machine export Info use to produce VM export schedule.
        vm_type=$(        echo $wline|awk -F\; '{ print $27 }')         # VM Type "vbox" for now
        export_sched=$(   echo $wline|awk -F\; '{ print $28 }')         # 1=Sched Active 0=Inactive
        export_ova=$(     echo $wline|awk -F\; '{ print $29 }')         # ova version 0.9, 1.0, 2.0
        export_mth=$(     echo $wline|awk -F\; '{ print $30 }')         # month of export 
        export_dom=$(     echo $wline|awk -F\; '{ print $31 }')         # Date in month to export 
        export_dow=$(     echo $wline|awk -F\; '{ print $32 }')         # Day of the week to export 
        export_hrs=$(     echo $wline|awk -F\; '{ print $33 }')         # Hour to start the export
        export_min=$(     echo $wline|awk -F\; '{ print $34 }')         # Minute to start the export
        export_host=$(    echo $wline|awk -F\; '{ print $35 }')         # VirtualBox Hosting VM
        server_vm=$(      echo $wline|awk -F\; '{ print $36 }')         # 0=Physical 1=Virtual 
        server_vm_ver=$(  echo $wline|awk -F\; '{ print $37 }')         # VM Addition version
        server_uptime=$(  echo $wline|awk -F\; '{ print $38 }')         # System uptime 
        server_lock=$(    echo $wline|awk -F\; '{ print $39 }')         # System Lock 0=no 1=yes

        sadm_write_log " "                                              # White Line
        sadm_write_log "---- [ $xcount ] ${fqdn_server} ----"           # Show count & ServerName

        # DISPLAY DATABASE COLUMN WE WILL USED, FOR DEBUGGING
        if [ "$SADM_DEBUG" -gt 4 ] 
            then sadm_write_log " " 
                 sadm_write_log "----------" 
                 sadm_write_log "I am in process_servers" 
                 sadm_write_log "These values come directly from the database."
                 sadm_write_log "Main Variables Column Name and Values we will rely on this the end."
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
                 sadm_write_log "vm_type         = $vm_type      "      # 1=VM, 0=Physical Machine
                 sadm_write_log "export_sched    = $export_sched "      # 1=Sched Active 0=Inactive
                 sadm_write_log "export_ova      = $export_ova   "      # ova version 0.9, 1.0, 2.0
                 sadm_write_log "export_mth      = $export_mth   "      # month of export 
                 sadm_write_log "export_dom      = $export_dom   "      # Date in month to export 
                 sadm_write_log "export_dow      = $export_dow   "      # Day of the week to export 
                 sadm_write_log "export_hrs      = $export_hrs   "      # Hour to start the export
                 sadm_write_log "export_min      = $export_min   "      # Minute to start the export
                 sadm_write_log "export_host     = $export_host  "      # VirtualBox Hosting VM
                 sadm_write_log "server_vm       = $server_vm  "        # 1=VirtualSystem 0=Physical
                 sadm_write_log "server_vm_ver   = $server_vm_ver "     # VM Addition version
                 sadm_write_log "server_uptime   = $server_uptime "     # System uptime 
                 sadm_write_log "server_lock     = $server_lock"        # System uptime 
        fi
        

        # Check if system is lock 
        sadm_lock_status "$server_name"                                 # Check if system is locked 
        if [ $? -eq 1 ]                                                 #If system is lock
            then sadm_write_log "[ WARNING ] System '$server_name' is locked, skipping it."
                 LOCK_FILE="${SADMIN}/${server_name}.lock"
                 sadm_write_log "  - Content of actual lock file : $(cat $LOCK_FILE)"
                 continue                        
        fi  


        # If not on the SADMIN server, test SSH connectivity and update the 'uptime' in SADMIN DB.
        declare -i connectivity_rc                                      # Make sure it's an integer
        connectivity_rc=0                                               # Default OK to SSH system
        if [ "$SADM_HOST_TYPE" != "S" ]                                 # If not on SADMIN Server
            then check_host_connectivity "$fqdn_server" "$ssh_port"     # Test SSH, Upd uptime in DB
                 connectivity_rc=$?                                     # 0=OK 1=Error 2+Warning
                 if [ "$SADM_DEBUG" -ne 0 ] 
                    then sadm_write_log "[ DEBUG ] '$fqdn_server' connectivity RC=$connectivity_rc"
                 fi
        fi 

        SYSTEM_ONLINE="N"                                               # Default, system not online
        case $connectivity_rc in
            0)  SYSTEM_ONLINE="Y"                                       # Able to connect to system
                ;;
            1)  ((ERROR_COUNT++))                                       # Error, Can't connect
                SYSTEM_ONLINE="N"                                       # Not able to connect 
                sadm_write_log "Total error(s) is now $ERROR_COUNT"
                #continue
                ;;
            2)  ((WARNING_COUNT++))                                     # Warn. sporadic,monitor off
                SYSTEM_ONLINE="N"                                       # Not able to connect 
                sadm_write_log "Total warning is now $WARNING_COUNT"
                #continue
                ;;
            *)  ((ERROR_COUNT++))                                       # Error, Can't connect
                SYSTEM_ONLINE="N"                                       # Not able to connect 
                sadm_write_err "[ ERROR ] Host Connectivity RC unknown '$RC'."
                ;;
        esac 
        if [ "$connectivity_rc" -eq 1 ] ; then continue ; fi            # System Down, return back
        if [ "$connectivity_rc" -eq 2 ] ; then continue ; fi            # Sporadic Sys,return back
        

        # Generate Crontab entry for O/S Update, if autoUpdate is ON, 
        if [ "$db_updauto" -eq 1 ] && [ "$SYSTEM_ONLINE" = "Y" ]        # If O/S Update Requested
            then update_osupdate_crontab "$server_name" "${server_dir}/bin/$OS_SCRIPT" "$db_updmin" "$db_updhrs" "$db_updmth" "$db_upddom" "$db_upddow" "$ssh_port"
        fi

        # Generate Crontab Entry for this server in Backup crontab work file, if online
        if [ "$backup_auto" -eq 1 ] && [ "$SYSTEM_ONLINE" = "Y" ]       # If Backup set to Yes 
            then update_backup_crontab "$server_name" "${server_dir}/bin/$BA_SCRIPT" "$backup_min" "$backup_hrs" "$backup_mth" "$backup_dom" "$backup_dow" "$ssh_port" "$compress"
        fi

        # Generate Crontab Entry for this server in ReaR crontab work file
        if [ $rear_auto -eq 1 ] && [ "$SYSTEM_ONLINE" = "Y" ]           # If Rear Backup set to Yes 
            then update_rear_crontab "$server_name" "${server_dir}/bin/$REAR_SCRIPT" "$rear_min" "$rear_hrs" "$rear_mth" "$rear_dom" "$rear_dow" "$ssh_port"
        fi
                
        # Generate Crontab Entry for this system in VirtualBox export 
        # System Don't need to be alive to do an export of the VM.
        # anemone,holmes,/opt/sadmin
        if [ "$server_vm" -eq 1 ]                                       # 1-Virtual System, 0=Hardw
            then find $SADM_WWW_DAT_DIR -name "vm_list.txt" -exec cat {} \; > $SADM_TMP_FILE2
                 grep -q "$server_name" $SADM_TMP_FILE2  
                 if [ $? -ne 0 ] 
                    then sadm_write_err "[ WARNING ] The system '$server_name' is set as a VM in database 'server_vm'=1"
                         sadm_write_err "[ WARNING ] But not in any 'vm_list' files under $SADM_WWW_DAT_DIR ? "                                                           
                 fi 
                 update_vmexport_crontab "$server_name" "${server_dir}/bin/$EXPORT_SCRIPT" "$export_min" "$export_hrs" "$export_mth" "$export_dom" "$export_dow" "$ssh_port" "$export_host"
        fi
                
        # Set remote $SADMIN/cfg Dir. and local www/dat/${server_name}/cfg directory.
        LDIR="${SADM_WWW_DAT_DIR}/${server_name}/cfg"                   # Local Receiving Dir.
        RDIR="${server_dir}/cfg"                                        # Remote cfg Directory

        # IF SYSTEM IS NOT ONLINE then no need to perform the rsync.
        if [ "$SYSTEM_ONLINE" = "N" ] ; then continue ; fi              # No rsync when offline


        # If client backup list was modified on master (if backup_list.tmp exist) then update client.
        if [ -r "$LDIR/backup_list.tmp" ]                               # If backup list was modify
           then if [ "$fqdn_server" != "$SADM_SERVER" ] && [ "$server_name" != "$SADM_HOSTNAME" ] 
                   then sadm_write_log "[ INFO ] Update the backup list on '${server_name}'"
                        rsync -ar -e "ssh -p $ssh_port" $LDIR/backup_list.tmp ${server_name}:$RDIR/backup_list.txt
                        RC=$?                                           # Save Command Return Code
                   else sadm_write_log "[ INFO ] Update then backup list on local system"
                        rsync -ar $LDIR/backup_list.tmp $SADM_CFG_DIR/backup_list.txt  # Local Rsync 
                        RC=$?                                           # Save Command Return Code
                fi
                if [ $RC -eq 0 ]                                        # If copy to client Worked
                    then sadm_write_log "[ OK ] Recent change in the backup list wre updated ${server_name}"
                         rm -f $LDIR/backup_list.tmp                    # Remove modified Local copy
                    else sadm_write_log "[ ERROR ] Syncing backup list with ${server_name}"
                fi
        fi

        # If backup exclude list was modified on master (if backup_exclude.tmp exist), update client
        if [ -r "$LDIR/backup_exclude.tmp" ]                            # Backup Exclude list modify
           then if [ "$fqdn_server" != "$SADM_SERVER" ] && [ "$server_name" != "$SADM_HOSTNAME" ]
                   then # Use rsync directory on SADMIN server to push new backup exclude list
                        rsync -ar -e "ssh -p $ssh_port" $LDIR/backup_exclude.tmp ${server_name}:$RDIR/backup_exclude.txt 
                        RC=$?                                           # Save Command Return Code
                   else # Use rsync directory on SADMIN server
                        rsync -ar $LDIR/backup_exclude.tmp $SADM_CFG_DIR/backup_exclude.txt # LocalRsync 
                        RC=$?                                           # Save Command Return Code
                fi
                if [ $RC -eq 0 ]                                        # If copy to client Worked
                    then sadm_write_log "$SADM_OK Modified Backup Exclude list updated on ${server_name}"
                         rm -f $LDIR/backup_exclude.tmp                 # Remove modified Local copy
                    else sadm_write_log "$SADM_ERROR Syncing Backup Exclude list with ${server_name}"
                fi
        fi

        # Build the name of the client footer that might have been modified Rear by user.
        REAR_USER_EXCLUDE="${SADM_WWW_DAT_DIR}/${server_name}/cfg/rear_exclude.tmp"     

        # Check if ReaR backup exclude list was modified (if backup_exclude.tmp exist), update client
        if [ -r "$REAR_USER_EXCLUDE" ]                                  # Rear Exclude option modify
           then update_rear_site_conf ${server_name}
                if [ "$fqdn_server" != "$SADM_SERVER" ] && [ "$server_name" != "sadmin" ] # Use ssh ?
                   then #sadm_write_log "rsync -var $REAR_CFG ${server_name}:/etc/rear/site.conf "
                        rsync -ar -e "ssh -p $ssh_port" $REAR_CFG ${server_name}:/etc/rear/site.conf 
                        if [ $? -eq 0 ] 
                            then sadm_write_log "$SADM_OK /etc/rear/site.conf updated on ${server_name}"
                            else sadm_write_log "$SADM_ERROR Trying to update /etc/rear/site.conf on ${server_name}"
                                 if [ $RC -ne 0 ] ; then ERROR_COUNT=$((ERROR_COUNT++)) ; fi  
                        fi
                        #
                        #sadm_write_log "rsync -var $REAR_USER_EXCLUDE ${server_name}:${RDIR}/rear_exclude.txt" 
                        rsync -ar -e "ssh -p $ssh_port" "$REAR_USER_EXCLUDE" "${server_name}:${RDIR}/rear_exclude.txt"
                        if [ $? -eq 0 ] 
                            then sadm_write_log "$SADM_OK ${RDIR}/rear_exclude.txt updated on ${server_name}"
                            else sadm_write_log "$SADM_ERROR Trying to update ${RDIR}/rear_exclude.txt on ${server_name}"
                                 if [ $RC -ne 0 ] ; then ERROR_COUNT=$((ERROR_COUNT++)) ; fi  
                        fi
                   else #sadm_write_log "rsync -var $REAR_CFG /etc/rear/site.conf" 
                        rsync -ar -e "ssh -p $ssh_port" $REAR_CFG /etc/rear/site.conf
                        if [ $? -eq 0 ] 
                            then sadm_write_log "$SADM_OK /etc/rear/site.conf updated on ${server_name}"
                            else sadm_write_log "$SADM_ERROR Trying to update /etc/rear/site.conf on ${server_name}"
                                 if [ $RC -ne 0 ] ; then ERROR_COUNT=$((ERROR_COUNT++)) ; fi  
                        fi
                        #
                        #sadm_write_log "rsync $REAR_USER_EXCLUDE ${SADM_CFG_DIR}/rear_exclude.txt" 
                        rsync -ar -e "ssh -p $ssh_port" "$REAR_USER_EXCLUDE" "${SADM_CFG_DIR}/rear_exclude.txt"
                        if [ $? -eq 0 ] 
                            then sadm_write_log "$SADM_OK ${SADM_CFG_DIR}/rear_exclude.txt updated on ${server_name}"
                            else sadm_write_log "$SADM_ERROR Trying to update ${SADM_CFG_DIR}/rear_exclude.txt on ${server_name}"
                                 if [ $RC -ne 0 ] ; then ERROR_COUNT=$((ERROR_COUNT++)) ; fi  
                        fi
                        RC=$?
                fi
        fi

        # Copy Site Common configuration files to client (If not on server)
        LDIR="${SADM_WWW_DAT_DIR}/${server_name}/cfg"                   # Local cfg Receiving Dir.
        RDIR="${server_dir}/cfg"                                        # Remote cfg Directory        
        if [ "$fqdn_server" != "$SADM_SERVER" ] && [ "$server_name" != "$SADM_HOSTNAME" ] # Use ssh or not
            then rem_cfg_files=( alert_group.cfg )
                 for WFILE in "${rem_cfg_files[@]}"
                   do
                   CFG_SRC="${SADM_CFG_DIR}/${WFILE}" 
                   CFG_DST="${fqdn_server}:${server_dir}/cfg/${WFILE}"
                   CFG_CMD="rsync -ar -e 'ssh -p $ssh_port' ${CFG_SRC} ${CFG_DST}"
                   if [ $SADM_DEBUG -gt 5 ] ; then sadm_write_log "$CFG_CMD" ; fi 
                   rsync -ar -e "ssh -p $ssh_port" "${CFG_SRC}" "${CFG_DST}" >> "$SADM_LOG" 2>&1
                   RC=$? 
                   if [ $RC -ne 0 ]
                      then sadm_write_log "$SADM_ERROR ($RC) doing ${CFG_CMD}"
                           ((ERROR_COUNT++))
                      else sadm_write_log "$SADM_OK ${CFG_CMD}" 
                   fi
                   done  
        fi 

        # Get remote $SADMIN/cfg Dir. and update local www/dat/${server_name}/cfg directory.
        if [ "$fqdn_server" != "$SADM_SERVER" ] && [ "$server_name" != "$SADM_HOSTNAME" ] # Use ssh or not
            then rsync_function "$fqdn_server:${RDIR}/" "${LDIR}/"    # Remote to Local rsync
                 RC=$?                                                  # Save Command Return Code
            else rsync_function "${RDIR}/" "${LDIR}/"                   # Local Rsync if on Master
                 RC=$?                                                  # Save Command Return Code
        fi
        if [ $RC -ne 0 ] ; then ((ERROR_COUNT++)) ; fi                  # rsync error, Incr Err Cntr
        chown -R $SADM_WWW_USER:$SADM_GROUP ${SADM_WWW_DAT_DIR}/${server_name} # Change Owner

        
        # Get remote $SADMIN/log Dir. and update local www/dat/${server_name}/log directory.
        LDIR="${SADM_WWW_DAT_DIR}/${server_name}/log"                   # Local Receiving Dir.
        RDIR="${server_dir}/log"                                        # Remote log Directory
        if [ "$fqdn_server" != "$SADM_SERVER" ] && [ "$server_name" != "$SADM_HOSTNAME" ] # Use ssh or not
            then rsync_function "${fqdn_server}:${RDIR}/" "$LDIR/"      # Remote to Local rsync
                 RC=$?                                                  # Save Command Return Code
            else rsync_function "${RDIR}/" "${LDIR}/"                   # Local Rsync if on Master
                 RC=$?                                                  # Save Command Return Code
        fi
        if [ $RC -ne 0 ] ; then ((ERROR_COUNT++)) ; fi                  # rsync error, Incr Err Cntr
        find $LDIR -type f -exec chown $SADM_WWW_USER:$SADM_WWW_GROUP {} \;
        find $LDIR -type f -exec chmod 666 {} \;

       # Rsync remote rch dir. onto local web rch dir/ (${SADMIN}/www/dat/${server_name}/rch) 
        LDIR="${SADM_WWW_DAT_DIR}/${server_name}/rch"                   # Local Receiving Dir. Path
        RDIR="${server_dir}/dat/rch"                                    # Remote RCH Directory Path
        if [ "$fqdn_server" != "$SADM_SERVER" ] && [ "$server_name" != "$SADM_HOSTNAME" ] # Use ssh or not
            then rsync_function "${fqdn_server}:${RDIR}/" "${LDIR}/"    # Remote to Local rsync
                 RC=$?                                                  # Save Command Return Code
            else rsync_function "${RDIR}/" "${LDIR}/"                   # Local Rsync if on Master
                 RC=$?                                                  # Save Command Return Code
        fi
        if [ $RC -ne 0 ] ; then ERROR_COUNT=$(($ERROR_COUNT+1)) ; fi    # rsync error, Incr Err Cntr
        find $LDIR -type f -exec chown $SADM_WWW_USER:$SADM_WWW_GROUP {} \;
        find $LDIR -type f -exec chmod 666 {} \;


        # Get remote $SADMIN/dat/rpt Dir. and update local www/dat/${server_name}/rpt directory.
        LDIR="$SADM_WWW_DAT_DIR/${server_name}/rpt"                     # Local www Receiving Dir.
        RDIR="${server_dir}/dat/rpt"                                    # Remote log Directory
        if [ "$fqdn_server" != "$SADM_SERVER" ] && [ "$server_name" != "$SADM_HOSTNAME" ] # Use ssh or not
            then rsync_function "${fqdn_server}:${RDIR}/" "${LDIR}/"    # Remote to Local rsync
                 RC=$?                                                  # Save Command Return Code
            else rsync_function "${RDIR}/" "${LDIR}/"                   # Local Rsync if on Master
                 RC=$?                                                  # Save Command Return Code
        fi
        if [ $RC -ne 0 ] ; then ((ERROR_COUNT++)) ; fi                  # rsync error, Incr Err Cntr
        find $LDIR -type f -exec chown $SADM_WWW_USER:$SADM_WWW_GROUP {} \;
        find $LDIR -type f -exec chmod 666 {} \;


        # Advise the user if the total error counter is different than zero.
        if [ $ERROR_COUNT -ne 0 ]                                       # If at Least 1 Error
           then sadm_write_log " "                                      # Separation Blank Line
                sadm_write_log "** Total error is now $ERROR_COUNT"     # Show Err. Count
        fi
        if [ $WARNING_COUNT -ne 0 ]                                     # If at Least 1 Warning
           then sadm_write_log "** Total warning is now $WARNING_COUNT" # Show Warning Count
        fi

        done < "$SADM_TMP_FILE1"                                        # Read active server list

    sadm_write_log " "                                                  # Separation Blank Line
    #sadm_write_log "${SADM_TEN_DASH}"                                  # Print 10 Dash line
    return $ERROR_COUNT                                                 # Return Total Error Count
}




# --------------------------------------------------------------------------------------------------
# check_all_rpt()
#
# Combine all clients *.rpt files and issues alert(s) if needed.
# Get all *.rpt files content and output it then a temp file ($SADM_TMP_FILE1).
# 
#  Example of rpt content : 
#   Warning;nomad;2018.09.16;11:00;linux;FILESYSTEM;Filesystem /usr at 86% > 85%;mail;sadmin
#   Error;nano;2018.09.16;11:00;SERVICE;DAEMON;Service crond|cron not running !;sadm;sadm
#   Error;raspi0;2018.09.16;11:00;linux;CPU;CPU at 100 pct for more than 240 min;mail;sadmin
#
# --------------------------------------------------------------------------------------------------
check_all_rpt()
{
    # Combine all *.rpt files into one $SADM_TMP_FILE3
    sadm_write_log "Verifying all systems monitors RePorTs files (*.rpt) :"
    find "$SADM_WWW_DAT_DIR"  -name "*.rpt" -exec cat {} \;  > "$SADM_TMP_FILE3"
    if [ "$SADM_DEBUG" -gt 2 ] 
        then sadm_write_log " " 
             sadm_write_log "File containing results"
             ls -l "$SADM_TMP_FILE3"
             sadm_write_log "Content of the file $SADM_TMP_FILE3" 
             cat "$SADM_TMP_FILE3" | while read wline ; do sadm_write_log "$wline"; done
    fi 

    # Process the file containing all *.rpt content (if any).
    if [ -s "$SADM_TMP_FILE3" ]                                         # If File Not Zero in Size
        then while read line                                            # Read Each Line of file
                do
                if [ "$SADM_DEBUG" -gt 5 ] ; then sadm_write_log "Processing Line=$line" ; fi
                ehost=$(echo "$line" | awk -F\; '{ print $2 }')         # Get Hostname for Event
                emess=$(echo "$line" | awk -F\; '{ print $7 }')         # Get Event Error Message
                wdate=$(echo "$line" | awk -F\; '{ print $3 }')         # Get Event Date
                wtime=$(echo "$line" | awk -F\; '{ print $4 }')         # Get Event Time
                etime="${wdate} ${wtime}"                               # Combine Event Date & Time
                if [ "${line:0:1}" = "W" ] || [ "${line:0:1}" = "w" ]   # If it is a WARNING
                    then etype="W"                                      # Set Event Type to Warning
                         egname=$(echo "$line" |awk -F\; '{ print $8 }') # Get Warning Alert Group
                         esub="$emess"                                  # Specify it is a Warning
                fi
                if [ "${line:0:1}" = "I" ] || [ "${line:0:1}" = "i" ]   # If it is an INFO
                    then etype="I"                                      # Set Event Type to Info
                         egname=$(echo "$line" |awk -F\; '{print $8}')  # Get Info Alert Group
                         esub="$emess"                                  # Specify it is an Info
                fi
                if [ "${line:0:1}" = "E" ] || [ "${line:0:1}" = "e" ]   # If it is an ERROR
                    then etype="E"                                      # Set Event Type to Error
                         egname=$(echo "$line" |awk -F\; '{print $9}')  # Get Error Alert Group
                         esub="$emess"                                  # Specify it is a Error
                fi
                emess2=$(echo -e "${emess}\nEvent Date/Time : ${etime}\n")
                if [ "$SADM_DEBUG" -gt 3 ] 
                    then sadm_write_log " " 
                         sadm_write_log "[ INFO ] sadm_send_alert $etype $etime $ehost sysmon $egname $esub $emess $eattach"
                fi

                ((alert_counter++))
                umess="${alert_counter}) $etime SysMon alert ($etype) on ${ehost} : ${emess} -"
                ((t_alert++))
                sadm_send_alert "$etype" "$etime" "$ehost" "SysMon" "$egname" "$esub" "$emess2" "$eattach"
                RC=$?
                sadm_write_log " "
                case $RC in
                    0)  ((t_ok++))
                        sadm_write_log "${umess} Alert sent successfully."
                        ;;
                    1)  ((t_error++))
                        sadm_write_log "${umess} Error submitting alert."
                        ;;
                    2)  ((t_duplicate++))
                        sadm_write_log "${umess} Alert already sent."
                        ;;
                    3)  ((t_oldies++))
                        sadm_write_log "${umess} Alert is older than 24 hrs."
                        ;;
                    *)  if [ "$SADM_DEBUG" -gt 0 ] 
                            then sadm_write_log "   - ERROR: Unknown return code $RC"
                        fi
                        ;;
                esac 

                done < "$SADM_TMP_FILE3" 
        else sadm_write_log "${BOLD}No error reported by any 'SysMon report files' (*.rpt).${NORMAL}" 
    fi

    # Print Alert submitted Summary
    sadm_write_log " "
    if [ $t_alert -ne 0 ]    
        then sadm_write_log "${BOLD}$t_alert System Monitor Alert(s) submitted${NORMAL}"
        else sadm_write_log "${BOLD}No System Monitor Alert(s) submitted${NORMAL}"
    fi
    sadm_write_log "   - New alert sent successfully : $t_ok" 
    sadm_write_log "   - Alert error trying to send  : $t_error"
    sadm_write_log "   - Alert older than 24 Hrs     : $t_oldies"
    sadm_write_log "   - Alert already sent          : $t_duplicate"
    sadm_write_log "${SADM_TEN_DASH}"                                # Print 10 Dash lineHistory

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
    sadm_write_log " "
    sadm_write_log "${BOLD}${YELLOW}Verifying all systems scripts results files (*.rch) :${NORMAL}"
    total_ok=0 ; total_error=0 ; total_oldies=0 ; total_duplicate=0     # Clear Function Totals
    find $SADM_WWW_DAT_DIR -type f -name '*.rch' -exec tail -1 {} \; > $SADM_TMP_FILE1 2>&1
    awk 'match($NF,/[0-1]/) { print }' $SADM_TMP_FILE1 >$SADM_TMP_FILE2 # Keep line ending with 0or1

    # IF NO FILE TO PROCESS
    if [ ! -s "$SADM_TMP_FILE2" ]                                       # If File Zero in Size
        then sadm_write_log "No error reported by any scripts files (*.rch)" 
             sadm_write_log "${SADM_TEN_DASH}"                          # Print 10 Dash 
             sadm_write_log ""                                          # Separation Blank Line
             return 0                                                   # Return to Caller
    fi

    # LOOP THROUGH EACH LINE IN THE CREATED FILE.
    alert_counter=0                                                     # Init alert counter
    cat $SADM_TMP_FILE2 | { while read line                             # Read Each Line of file
        do                
        NBFIELD=$(echo $line | awk '{print NF}')                        # How many fields on line ?

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
        if [ "$egtype" = "1" ] && [ "$ecode" = "1" ] || 
           [ "$egtype" = "2" ] && [ "$ecode" = "0" ] || [ "$egtype" = "3" ]  
           then ((total_alert++))                                       # Incr. Alert counter
                if [ "$SADM_DEBUG" -gt 2 ]                              # Under Debug Show Parameter
                   then dmess="'$etype' '$start_time' '$end_time' '$ehost' '$egname'"    # Build Mess to see Param.
                        dmess="$dmess '$esub' '$emess' '$eattach'"      # Build Mess to see Param.
                        sadm_write_log "sadm_send_alert $dmess RC=$RC"   # Show User Paramaters sent
                fi
                ((alert_counter++))                                     # Increase Submit AlertCount
                emess=$(echo -e "${emess}\nScript start time  : ${start_time}\n")
                emess=$(echo -e "${emess}\nScript end time    : ${end_time}\n")
                emess=$(echo -e "${emess}\nScript elapse time : ${elapse}\n")
                if [ $SADM_DEBUG -gt 2 ] ;then sadm_write "Email Message is:\n${emess}\n" ; fi
                sadm_send_alert "$etype" "$end_time" "$ehost" "$escript" "$egname" "$esub" "$emess" "$eattach"
                RC=$?
                if [ $SADM_DEBUG -gt 2 ] ;then sadm_write_log "RC=$RC" ;fi   # Debug Show ReturnCode
                case $RC in
                    0)  ((total_ok++))
                        sadm_write_log "${alert_counter}) $start_time alert ($etype) for $escript on ${ehost}: Alert was sent successfully."
                        ;;
                    1)  ((total_error++))
                        sadm_write_log "${alert_counter}) $start_time alert ($etype) for $escript on ${ehost}: Error submitting the alert."
                        ;;
                    2)  ((total_duplicate++))
                        sadm_write_log "${alert_counter}) $start_time alert ($etype) for $escript on ${ehost}: Alert already sent."
                        ;;
                    3)  ((total_oldies++))
                        sadm_write_log "${alert_counter}) $start_time alert ($etype) for $escript on ${ehost}: Alert is older than 24 hrs."
                        ;;
                    *)  sadm_write_log "   - ERROR: Unknown return code $RC";
                        ;;
                esac                                                    # End of case
        fi
        done 

        # Print Alert submitted Summary
        sadm_write_log " "                                               # Separation Blank Line
        sadm_write_log "${BOLD}$total_alert Script(s) Alert(s) submitted${NORMAL}"
        sadm_write_log "   - New alert sent successfully : $total_ok"
        sadm_write_log "   - Alert error trying to send  : $total_error"
        sadm_write_log "   - Alert older than 24 Hrs     : $total_oldies"
        sadm_write_log "   - Alert already sent          : $total_duplicate"
        sadm_write_log "${SADM_TEN_DASH}"                                # Print 10 Dash lineHistory
    }                                                              
}




# --------------------------------------------------------------------------------------------------
# crontab_update()
#
# Check checksum of current crontab versus the one created while processing each systems.
# If checksum is different, update the crontab file (For sadm_osupdate file and sadm_vackup file).
#
# --------------------------------------------------------------------------------------------------
crontab_update()
{
    sadm_write_log "${SADM_TEN_DASH}"    
    sadm_write_log "${BOLD}${YELLOW}Crontab Update Summary${NORMAL}"

    # O/S UPDATE CRONTAB FILE
    # Create sha1sum on newly created and actual backup crontab.
    # Compare the two sha1sum and if they are different, then the new crontab become the actual.
    # SADM_CRON_FILE="$SADM_CFG_DIR/.sadm_osupdate"   = Newly Reconstructed cron file
    # SADM_CRONTAB="/etc/cron.d/sadm_osupdate"        = Actual crontab O/S Update file
    nsha1="" ; asha1=""                                                 # Clear sha1sum results
    if [ -f "$SADM_CRON_FILE" ] ; then work_sha1=$(sha1sum "$SADM_CRON_FILE" |awk '{print $1}') ;fi 
    if [ -f "$SADM_CRONTAB" ]   ; then real_sha1=$(sha1sum "$SADM_CRONTAB"   |awk '{print $1}') ;fi 
    if [ "$work_sha1" != "$real_sha1" ]                                 # If any change to make 
       then cp "$SADM_CRON_FILE" "$SADM_CRONTAB"                        # Put in place New Crontab
            sadm_write_log "  - O/S update schedule crontab ($SADM_CRONTAB) was updated."
       else sadm_write_log "  - No need to update the O/S update schedule crontab '$SADM_CRONTAB'."
    fi
    chmod 644 "$SADM_CRONTAB" 
    chown root:root "$SADM_CRONTAB" 
    rm -f $SADM_CRON_FILE  >/dev/null 2>&1                              # Remove crontab work file


    # SADMIN BACKUP CRONTAB FILE
    # Create sha1sum on newly created and actual backup crontab.
    # Compare the two sha1sum and if they are different, then the new crontab become the actual.
    # SADM_BACKUP_NEWCRON="$SADM_CFG_DIR/.sadm_backup" = Newly reconstructed daily backup Cron file
    # SADM_BACKUP_CRONTAB="/etc/cron.d/sadm_backup"    = Actual crontab file for daily backup 
    nsha1="" ; asha1=""                                                 # Clear sha1sum results
    if [ -f "$SADM_BACKUP_NEWCRON" ] ; then nsha1=$(sha1sum "$SADM_BACKUP_NEWCRON" |awk '{print $1}') ;fi
    if [ -f "$SADM_BACKUP_CRONTAB" ] ; then asha1=$(sha1sum "$SADM_BACKUP_CRONTAB" |awk '{print $1}') ;fi 
    if [ "$nsha1" != "$asha1" ]                                         # New Different than Actual?
       then cp "$SADM_BACKUP_NEWCRON" "$SADM_BACKUP_CRONTAB"            # Put in place New Crontab
            sadm_write_log "  - Clients backup schedule crontab '$SADM_BACKUP_CRONTAB' updated." 
       else sadm_write_log "  - No need to update the backup crontab '$SADM_BACKUP_CRONTAB'."
    fi
    chmod 644 "$SADM_BACKUP_CRONTAB" 
    chown root:root "$SADM_BACKUP_CRONTAB"
    rm -f $SADM_BACKUP_NEWCRON  >/dev/null 2>&1                         # Remove crontab work file


    # SADMIN REAR CRONTAB FILE
    # Create sha1sum on newly created and live ReaR backup crontab.
    # Compare the two sha1sum and if they are different, then the new crontab become the actual.
    # SADM_REAR_NEWCRON="$SADM_CFG_DIR/.sadm_rear_backup"  = Newly reconstructed ReaR Crontab file
    # SADM_REAR_CRONTAB="/etc/cron.d/sadm_rear_backup"     = Actual crontab file Rear Crontab file
    nsha1="" ; asha1=""                                                 # Clear sha1sum results
    if [ -f "$SADM_REAR_NEWCRON" ] ;then nsha1=$(sha1sum "$SADM_REAR_NEWCRON" |awk '{print $1}') ;fi
    if [ -f "$SADM_REAR_CRONTAB" ] ;then asha1=$(sha1sum "$SADM_REAR_CRONTAB" |awk '{print $1}') ;fi 
    if [ "$nsha1" != "$asha1" ]                                         # New Different than Actual?
       then cp "$SADM_REAR_NEWCRON" "$SADM_REAR_CRONTAB"                # Put in place New Crontab
            sadm_write_log "  - Clients ReaR backup schedule crontab '$SADM_REAR_CRONTAB' was updated."
       else sadm_write_log "  - No need to update the ReaR backup crontab '$SADM_REAR_CRONTAB'."
    fi
    chmod 644 "$SADM_REAR_CRONTAB" 
    chown root:root "$SADM_REAR_CRONTAB" 
    rm -f $SADM_REAR_NEWCRON  >/dev/null 2>&1                           # Remove crontab work file


    # SADMIN VIRTUAL EXPORT CRONTAB 
    # Create sha1sum on newly and actual VM export crontab.
    # Compare the two sha1sum and if they are different, then the new crontab become the actual.
    # SADM_VMEXPORT_NEWCRON="$SADM_CFG_DIR/.sadm_vm_export"     = Newly rebuild export VM Crontab
    # SADM_VMEXPORT_CRONTAB="/etc/cron.d/sadm_vm"               = Actual crontab for VM export
    nsha1="" ; asha1=""
    if [ -f "$SADM_VMEXPORT_NEWCRON" ] ;then nsha1=$(sha1sum "$SADM_VMEXPORT_NEWCRON" |awk '{print $1}') ;fi
    if [ -f "$SADM_VMEXPORT_CRONTAB" ] ;then asha1=$(sha1sum "$SADM_VMEXPORT_CRONTAB" |awk '{print $1}') ;fi 
    if [ "$nsha1" != "$asha1" ]                                         # New Different than Actual?
       then cp "$SADM_VMEXPORT_NEWCRON" "$SADM_VMEXPORT_CRONTAB"        # Put in place New Crontab
            sadm_write_log "  - Virtual system export schedule crontab '$SADM_VMEXPORT_CRONTAB' updated."
       else sadm_write_log "  - No need to update virtual system export crontab '$SADM_VMEXPORT_CRONTAB'."
    fi
    chmod 644 "$SADM_VMEXPORT_CRONTAB" 
    chown root:root "$SADM_VMEXPORT_CRONTAB"
    rm -f $SADM_VMEXPORT_NEWCRON  >/dev/null 2>&1                       # Remove crontab work file

    sadm_write_log " "
    return 0
}






# --------------------------------------------------------------------------------------------------
#  update_server_uptime()
#
#  Update the system uptime in Server Table in SADMIN Database
#
#  Parameters:
#   1) server hostname to update (without domain name)
#   2) uptime value to store in Database
#
#  Return Value:
#   0) Successful update
#   1) Error when trying to record uptime
# --------------------------------------------------------------------------------------------------
update_server_uptime()
{
    WSERVER=$1                                                          # Server Name to Update
    WUPTIME=$2                                                          # Uptime value to store
    WCURDAT=$(date "+%C%y.%m.%d %H:%M:%S")                              # Get & Format Update Date

    SQL1="UPDATE server SET "                                           # SQL Update Statement
    SQL2="srv_uptime = '$WUPTIME', "                                    # System uptime value
    SQL3="srv_date_update = '${WCURDAT}' "                              # Last Update Date
    SQL4=" "                                                            # Last Boot Date
    SQL5="where srv_name = '${WSERVER}' ;"                              # Server name to update
    SQL="${SQL1}${SQL2}${SQL3}${SQL4}${SQL5}"                           # Create final SQL Statement

    WAUTH="-u $SADM_RW_DBUSER  -p$SADM_RW_DBPWD "                       # Set Authentication String 
    CMDLINE="$SADM_MYSQL $WAUTH "                                       # Join MySQL with Authen.
    CMDLINE="$CMDLINE -h $SADM_DBHOST $SADM_DBNAME -e '$SQL'"           # Build Full Command Line
    if [ "$SADM_DEBUG" -gt 5 ] ; then sadm_write_log "$CMDLINE" ; fi    # Debug = Write command Line

    # Execute SQL to Update Server O/S Data
    $SADM_MYSQL $WAUTH -h $SADM_DBHOST $SADM_DBNAME -e "$SQL" >>$SADM_LOG 2>&1
    if [ $? -ne 0 ]                                                     # If Error while updating
        then sadm_write_err "[ ERROR ] Database update failed to update 'uptime' ($WUPTIME) of $WSERVER"
             RCU=1                                                      # Set Error Code = 1
        else sadm_write_log "[ OK ] Success updating database 'uptime' ($WUPTIME) of $WSERVER"
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
        then sadm_write_log "Invalid number of argument received by function ${FUNCNAME}."
             sadm_write_log "Should be 8 we received $# : $* "           # Show what received
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
    echo "$asubject" | grep -q "$aserver"                               # Is server name in subject?
    if [ $? -ne 0 ] ; then asubject="$aserver $6" ; fi                  # Add server name in subject
    amessage="$7"                                                       # Save Alert Message
    aattach="$8"                                                        # Save Attachment FileName
    acounter="01"                                                       # Default alert Counter

    # If Alert group received is 'default', replace it with group specified in alert_group.cfg
    if [ "$agroup" = "default" ] 
       then galias=`grep -i "^default " $SADM_ALERT_FILE | head -1 | awk '{ print $3 }'` 
            agroup=`echo $galias | awk '{$1=$1;print}'`                 # Del Leading/Trailing Space
       else grep -i "^$agroup " $SADM_ALERT_FILE >/dev/null 2>&1        # Search in Alert Group File
            if [ $? -ne 0 ]                                             # Group Missing in GrpFile
                then sadm_write_log "[ ERROR ] Alert group '$agroup' missing from ${SADM_ALERT_FILE}"
                     sadm_write_log "  - Alert date/time : $atime"       # Show Event Date & Time
                     sadm_write_log "  - Alert subject   : $asubject"    # Show Event Subject
                     return 1                                           # Return Error to caller
            fi
    fi 

    # Display Values received and we will use in this function.
    if [ $LIB_DEBUG -gt 4 ]                                             # Debug Info List what Recv.
       then printf "\n\nFunction '${FUNCNAME}' parameters received :\n" # Print Function Name
            sadm_write_log "atype=$atype"                                # Show Alert Type
            sadm_write_log "atime=$atime"                                # Show Event Date & Time
            sadm_write_log "aserver=$aserver"                            # Show Server Name
            sadm_write_log "ascript=$ascript"                            # Show Script Name
            sadm_write_log "agroup=$agroup"                              # Show Alert Group
            sadm_write_log "asubject=\"$asubject\""                      # Show Alert Subject/Title
            sadm_write_log "amessage=\"$amessage\""                      # Show Alert Message
            sadm_write_log "aattachment=\"$aattach\""                    # Show Alert Attachment File
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
    agroup_type=$(grep -i "^$agroup " $SADM_ALERT_FILE |awk '{print $2}') # [S/M/T/C] Group
    agroup_type=$(echo "$agroup_type" |awk '{$1=$1;print}' |tr  "[:lower:]" "[:upper:]")
    if [ "$agroup_type" != "M" ] && [ "$agroup_type" != "S" ] &&
       [ "$agroup_type" != "T" ] && [ "$agroup_type" != "C" ] 
       then wmess="[ ERROR ] Invalid Group Type '$agroup_type' for '$agroup' in $SADM_ALERT_FILE"
            sadm_write_err " " ; sadm_write_err "${wmess}"
            return 1
    fi

    # Calculate some data that we will need later on 
    # Age of alert in Days (NbDaysOld), in Seconds (aage) & Nb. Alert Repeat per day (MaxRepeat)
    aepoch=$(sadm_date_to_epoch "$atime")                               # Convert AlertTime to Epoch
    cepoch=$(date +%s)                                                  # Get Current Epoch Time
    aage=$(expr $cepoch - $aepoch)                                      # Age of Alert in Seconds.
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
                        then wmsg="Alert already sent, you asked to sent alert only once."
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
             WaitSec=$(( acounter * SADM_ALERT_REPEAT ))                # Next Alert Elapse Seconds
             if [ $aage -le $WaitSec ]                                  # Repeat Time not reached
                then xcount=$(( WaitSec - aage))                        # Sec till nxt alarm is sent
                     nxt_epoch=$(( cepoch * xcount ))                   # Next Alarm Epoch     
                     nxt_time=$(sadm_epoch_to_date "$nxt_epoch")        # Next Alarm Date/Time
                     msg="Waiting - Next alert will be send in $xcount seconds around ${nxt_time}."
                     if [ "$LIB_DEBUG" -gt 4 ] ;then sadm_write "${msg}\n" ;fi 
                     return 2                                           # Return 2 =Duplicate Alert
             fi 
    fi  

    # Update Alarm Counter 
    ((acounter++))                                         # Increment Index by 1
    if [ $acounter -gt 1 ] ; then amessage="(Repeat) $amessage" ;fi     # Ins.Repeat in Msg if cnt>1
    acounter=$(printf "%02d" "$acounter")                               # Make counter two digits
    if [ "$LIB_DEBUG" -gt 4 ] ;then sadm_write "Repeat alert ($aepoch)-($acounter)-($alertid)\n" ;fi

    NxtInterval=$(echo "$acounter * $SADM_ALERT_REPEAT" | $SADM_BC)     # Next Alert Elapse Seconds 
    NxtEpoch=$(expr $NxtInterval + $aepoch)                             # Next repeat + ActualEpoch
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
    if [ "$LIB_DEBUG" -gt 4 ] ; then sadm_write_log "Alert Subject will be : $ws" ; fi

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
    body=$(printf "%s\n%s\n%s" "$mheader" "$amessage" "$mfooter")       # Construct Final Mess. Body
    if [ "$atype" = "S" ] && [ "$agroup_type" != "T" ]                  # If Script Alert, Not Texto
       then SNAME=$(echo ${ascript} |awk '{ print $1 }')                # Get Script Name
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
       M) aemail=$(grep -i "^$agroup " $SADM_ALERT_FILE |awk '{ print $3 }') # Get Emails of Group
          aemail=$(echo $aemail | awk '{$1=$1;print}')                  # Del Leading/Trailing Space
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
              then sadm_write_log "$SADM_CURL -s -d \"payload=$json\" ${slack_hook_url}"
          fi
          SRC=`$SADM_CURL -s -d "payload=$json" $slack_hook_url`        # Send Slack Message
          if [ "$LIB_DEBUG" -gt 4 ] ; then sadm_write_log "Status after send to Slack is ${SRC}" ;fi
          if [ $SRC = "ok" ]                                            # If Sent Successfully
              then RC=0                                                 # Set Return code to 0
                   wstatus="[ OK ] Slack message sent with success to $agroup ($SRC)" 
                   sadm_write_log "${wstatus}"                          # Advise User
              else wstatus="[ ERROR ] Sending Slack message to $agroup ($SRC)"
                   sadm_write_log "${wstatus}"                          # Advise User
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
                  then sadm_write_log "Member of '$agroup' alert group '$i' is not a type 'C' alert."
                       sadm_write_log "Alert not send to '$i', proceeding with next member."
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
    htype=$(echo $htype |tr "[:lower:]" "[:upper:]")                    # Make Alert Type Uppercase
    hdatetime=$(echo "$2"  | awk '{$1=$1;print}')                       # Save Event Date & Time
    hdate=$(echo "$2"      | awk '{ print $1 }')                        # Save Event Date
    htime=$(echo "$2"      | awk '{ print $2 }')                        # Save Event Time
    hgroup=$(echo "$3"     | awk '{$1=$1;print}')                       # SADM AlertGroup to Advise
    hserver=$(echo "$4"    | awk '{$1=$1;print}')                       # Save Server Name
    hsub="$5"                                                           # Save Alert Subject
    hcount="$6"                                                         # Save Alert Reference No.
    hstat="$7"                                                          # Save Alert Send Status
    hepoch=$(sadm_date_to_epoch "$hdatetime")                           # Convert Event Time to Epoch
    cdatetime=$(date "+%C%y%m%d_%H%M")                                  # Current Date & Time
    #
    hline=$(printf "%s;%s" "$hepoch" "$hcount")                         # Epoch and AlertSent Counter
    hline=$(printf "%s;%s;%s;%s" "$hline" "$htime" "$hdate" "$htype")   # Alert time,date,type
    hline=$(printf "%s;%s;%s;%s" "$hline" "$hserver" "$hgroup" "$hsub") # Alert Server,Group,Subject
    hline=$(printf "%s;%s;%s" "$hline" "$hstat" "$cdatetime")           # Alert Status,Cur Date/Time
    echo "$hline" >> "$SADM_ALERT_HIST"                                 # Write Alert History File
    if [ "$LIB_DEBUG" -gt 4 ] ; then sadm_write "Line added to History : $hline \n" ; fi 
}



# --------------------------------------------------------------------------------------------------
# main_process()
#
# Get information from all actives 'sadmin clients' to update/create "hostname.rpt" and 
# all the new or updated *.rch files.
#
# --------------------------------------------------------------------------------------------------
main_process()
{   
    PROCESS_ERROR=0                                                     # Init. Error count to 0
    
    # Create an empty global rpt file $SADMIN/www/dat/HOSTNAME/rpt/HOSTNAME_fetch.rpt
    if [ -f "$FETCH_RPT_GLOBAL" ] ;then rm -f "$FETCH_RPT_GLOBAL" ;fi   # rm global RPT file if exist
    touch "$FETCH_RPT_GLOBAL"                                           # Create global RPT file
    chown "$SADM_WWW_USER:$SADM_GROUP"  "$FETCH_RPT_GLOBAL"  
    chmod 664 "$FETCH_RPT_GLOBAL"

    # Create starting empty local rpt file $SADMIN/dat/rpt/HOSTNAME_fetch.rpt
    if [ -f "$FETCH_RPT_LOCAL" ] ; then rm -f "$FETCH_RPT_LOCAL" ; fi   # rm local RPT file if exist
    touch "$FETCH_RPT_LOCAL"                                            # Create EMPTY local RPTfile
    chown "$SADM_USER:$SADM_GROUP"  "$FETCH_RPT_LOCAL"  
    chmod 664 "$FETCH_RPT_LOCAL"


    # Process All Active Linux systems.
    process_servers "linux"                                             # Process Active Linux
    PROCESS_ERROR=$?                                                    # Save Nb. Errors in process

    # Print Total Scripts Errors
    sadm_write_log " "                                                  # Separation Blank Line
    sadm_write_log "${SADM_TEN_DASH}"                                   # Print 10 Dash lineHistory
    sadm_write_log "${BOLD}${YELLOW}Systems Rsync Summary${NORMAL}"     # Rsync Summary 
    sadm_write_log " - Total error(s)  : ${PROCESS_ERROR}"              # Display Total Linux Errors
    sadm_write_log " "                                                  # Separation Blank Line

    # Check if crontabs need to be updated (sadm_backup, sadm_osupdate, sadm_rear_backup, sadm_vm)
    crontab_update                                                      # Update crontab if changed

    # Create Global VM List $SADM_VMLIST & $SADM_VMHOSTS (If any VM to process)
    create_vm_list    

    
    # If Global RCH and RPT directories don't exist
    WDIR="${SADM_WWW_DAT_DIR}/${SADM_HOSTNAME}/rch"                     # Web Global RCH repo Dir 
    if [ ! -d "$WDIR" ] ; then mkdir -p "$WDIR" ; fi
    chown "$SADM_WWW_USER:$SADM_GROUP"  "$WDIR" 
    chmod 775 "$WDIR"

    WDIR="${SADM_WWW_DAT_DIR}/${SADM_HOSTNAME}/rpt"                     # Web Global RPT repo Dir 
    if [ ! -d "$WDIR" ] ; then mkdir -p "$WDIR" ; fi
    chown "$SADM_WWW_USER:$SADM_GROUP"  "$WDIR" 
    chmod 775 "$WDIR"


    # Copy local rpt and rch to Global www directories.
    if [ -r "$SADM_RPT_FILE" ] 
        then chmod 664 "$SADM_RPT_FILE"
             cp "$SADM_RPT_FILE" "${SADM_WWW_DAT_DIR}/${SADM_HOSTNAME}/rpt" 
             if [ $? -ne 0 ] 
                then sadm_write_err "[ ERROR ] cp $SADM_RPT_FILE ${SADM_WWW_DAT_DIR}/${SADM_HOSTNAME}/rpt"
                ((PROCESS_ERROR++))  
             fi 
    fi
    if [ -r "$SADM_RCH_FILE" ] 
        then chmod 664 "$SADM_RCH_FILE"
             cp "$SADM_RCH_FILE" "${SADM_WWW_DAT_DIR}/${SADM_HOSTNAME}/rch"
             if [ $? -ne 0 ] 
                then sadm_write_err "[ ERROR ] cp $SADM_RCH_FILE ${SADM_WWW_DAT_DIR}/${SADM_HOSTNAME}/rch"
                     ((PROCESS_ERROR++))                                        # Increase Error Counter 
             fi 
    fi

    # Check for Error or Alert to submit
    check_all_rpt                                                       # Check all *.rpt for Alert
    check_all_rch                                                       # Check all *.rch for Alert

    # Delete TMP work file before returning to caller 
    if [ ! -f "$REAR_TMP" ] ; then rm -f $REAR_TMP >/dev/null 2>&1 ; fi
    
    SADM_EXIT_CODE=$PROCESS_ERROR                                       # Save error count
    return $SADM_EXIT_CODE
}




# --------------------------------------------------------------------------------------------------
# Command line Options functions
# Evaluate Command Line Switch Options Upfront
# By Default (-h) Show Help Usage, (-v) Show Script Version,(-d0-9] Set Debug Level 
# --------------------------------------------------------------------------------------------------
function cmd_options()
{
    while getopts "d:hv" opt ; do                                       # Loop to process Switch
        case $opt in
            d) SADM_DEBUG=$OPTARG                                       # Get Debug Level Specified
               num=$(echo "$SADM_DEBUG" |grep -E "^\-?[0-9]?\.?[0-9]+$") # Valid if Level is Numeric
               if [ "$num" = "" ]                            
                  then printf "\nInvalid debug level.\n"                # Inform User Debug Invalid
                       show_usage                                       # Display Help Usage
                       exit 1                                           # Exit Script with Error
               fi
               printf "Debug level set to ${SADM_DEBUG}.\n"             # Display Debug Level
               ;;                                                       
            h) show_usage                                               # Show Help Usage
               exit 0                                                   # Back to shell
               ;;
            v) sadm_show_version                                        # Show Script Version Info
               exit 0                                                   # Back to shell
               ;;
           \?) printf "\nInvalid option: ${OPTARG}.\n"                  # Invalid Option Message
               show_usage                                               # Display Help Usage
               exit 1                                                   # Exit with Error
               ;;
        esac                                                            # End of case
    done                                                                # End of while
    return 
}







# Main Script Start HERE
# --------------------------------------------------------------------------------------------------
    cmd_options "$@"                                                    # Check command-line Options   
    sadm_start                                                          # Create Dir.,PID,log,rch
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if 'Start' went wrong
    main_process                                                        # rsync from all clients
    SADM_EXIT_CODE=$?                                                   # Save Function Result Code 
    sadm_stop $SADM_EXIT_CODE                                           # Close/Trim Log & Upd. RCH
    exit $SADM_EXIT_CODE                                                # Exit With Error code (0/1)
