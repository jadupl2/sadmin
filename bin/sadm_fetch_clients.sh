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
# 2016_12_12  v1.6 Major changes to include ssh test to each server and alert when not working
# 2017_02_09  v1.8 Change Script name and change SADM server default crontab
# 2017_04_04  v1.9 Cosmetic - Remove blank lines inside processing servers
# 2017_07_07  v2.0 Remove Ping before doing the SSH to each server (Not really needed)
# 2017_07_20  v2.1 When Error Detected - The Error is included at the top of Email (Simplify Diag)
# 2017_08_03  v2.2 Minor Bug Fix
# 2017_08_24  v2.3 Rewrote section of code & Message more concise
# 2017_08_29  v2.4 Bug Fix - Corrected problem when retrying rsync when failed
# 2017_08_30  v2.5 If SSH test to server fail, try a second time (Prevent false Error)
# 2017_12_17  v2.6 Modify to use MySQL instead of PostGres
# 2018_02_08  v2.8 Fix compatibility problem with 'dash' shell
# 2018_02_10  v2.9 Rsync on SADMIN server (locally) is not using ssh
# 2018_04_05  v2.10 Do not copy web Interface crontab from backup unless file exist
# 2018_05_06  v2.11 Remove URL from Email when Error are detecting while fetching data
# 2018_05_06  v2.12 Small Modification for New Libr Version
# 2018_06_29  v2.13 Use SADMIN Client Dir in Database instead of assuming /sadmin as root dir
# 2018_07_08  v2.14 O/S Update crontab file is recreated and updated if needed at end of script.
# 2018_07_14  v2.15 Fix Problem Updating O/S Update crontab when running with the dash shell.
# 2018_07_21  v2.16 Give Explicit Error when cannot connect to Database
# 2018_07_27  v2.17 O/S Update Script will store each server output log in $SADMIN/tmp for 7 days.
# 2018_08_08  v2.18 Server not responding to SSH wasn't include in O/S update crontab,even active
# 2018_09_14  v2.19 Alert are now send to Production Alert Group (sprod-->Slack Channel sadm_prod)
# 2018_09_18  v2.20 Alert Minors fixes
# 2018_09_26  v2.21 Include Subject Field in Alert and Add Info field from SysMon
# 2018_09_26  v2.22 Reformat Error message for alerting systsem
# 2018_10_04  v2.23 Supplemental message about o/s update crontab modification
# 2018_11_28  v2.24 Added Fetch to MacOS Client 
# 2018_12_30  Fixed: v2.25 Problem updating O/S Update crontab when some MacOS clients were used.
# 2018_12_30  Added: sadm_fetch_client.sh v2.26 - Diminish alert while system reboot after O/S Update.
# 2019_01_05  Added: sadm_fetch_client.sh v2.27 - Using sudo to start o/s update in cron file.
# 2019_01_11  Feature: sadm_fetch_client.sh v2.28 - Now update sadm_backup crontab when needed.
# 2019_01_12  Feature: sadm_fetch_client.sh v2.29 - Now update Backup List and Exclude on Clients.
# 2019_01_18  Fix: sadm_fetch_client.sh v2.30 - Fix O/S Update crontab generation.
# 2019_01_26  Added: v2.31 Add to test if crontab file exist, when run for first time.
# 2019_02_19  Added: v2.32 Copy script rch file in global dir after each run.
# 2019_04_12  Fix: v2.33 Create Web rch directory, if not exist when script run for the first time.
# 2019_04_17  Update: v2.34 Show Processing message only when active servers are found.
# 2019_05_07  Update: v2.35 Change Send Alert parameters for Library 
# 2019_05_23  Update: v2.36 Updated to use SADM_DEBUG instead of Local Variable DEBUG_LEVEL
# 2019_06_06  Fix: v2.37 Fix problem sending alert when SADM_ALERT_TYPE was set 2 or 3.
# 2019_06_07  New: v2.38 An alert status summary of all systems is displayed at the end.
# 2019_06_19  Update: v2.39 Cosmetic change to alerts summary and alert subject.
#@2019_07_12  Update: v3.00 Fix script path for backup and o/s update in respective crontab file.
#@2019_07_24  Update: v3.1 Major revamp of code.
#@2019_08_23  Update: v3.2 Remove Crontab work file (Cleanup)
#@2019_08_29 Fix: v3.3 Correct problem with CR in site.conf 
#@2019_08_31 Update: v3.4 More consice of alert email subject.
# --------------------------------------------------------------------------------------------------
#
#   Copyright (C) 2016 Jacques Duplessis <jacques.duplessis@sadmin.ca>
#
#   The SADMIN Tool is free software; you can redistribute it and/or modify it under the terms
#   of the GNU General Public License as published by the Free Software Foundation; either
#   version 2 of the License, or (at your option) any later version.
#
#   SADMIN Tools are distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
#   without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#   See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with this program.
#   If not, see <http://www.gnu.org/licenses/>.
#
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPT the ^C
#set -x





#===================================================================================================
# To use the SADMIN tools and libraries, this section MUST be present near the top of your code.
# SADMIN Section - Setup SADMIN Global Variables and Load SADMIN Shell Library
#===================================================================================================

    # Is 'SADMIN' environment variable defined ?. If not try to use /etc/environment SADMIN value.
    if [ -z $SADMIN ] || [ "$SADMIN" = "" ]                             # If SADMIN EnvVar not right
        then missetc="Missing /etc/environment file, create it and add 'SADMIN=/InstallDir' line." 
             if [ ! -e /etc/environment ] ; then printf "${missetc}\n" ; exit 1 ; fi
             missenv="Please set 'SADMIN' environment variable to the install directory."
             grep "^SADMIN" /etc/environment >/dev/null 2>&1            # SADMIN line in /etc/env.? 
             if [ $? -eq 0 ]                                            # Yes use SADMIN definition
                 then export SADMIN=`grep "^SADMIN" /etc/environment | awk -F\= '{ print $2 }'` 
                      misstmp="Temporarily setting 'SADMIN' environment variable to '${SADMIN}'."
                      missvar="Add 'SADMIN=${SADMIN}' in /etc/environment to suppress this message."
                      if [ ! -e /bin/launchctl ] ; then printf "${missvar}" ; fi 
                      printf "\n${missenv}\n${misstmp}\n\n"
                 else missvar="Add 'SADMIN=/InstallDir' in /etc/environment to remove this message."
                      printf "\n${missenv}\n$missvar\n"                 # Recommendation to user    
                      exit 1                                            # Back to shell with Error
             fi
    fi 
        
    # Check if the SADMIN Shell Library is accessible, if not advise user and exit with error.
    if [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]                            # Shell Library not readable
        then missenv="Please set 'SADMIN' environment variable to the install directory."
             printf "${missenv}\nSADMIN library ($SADMIN/lib/sadmlib_std.sh) can't be located\n"     
             exit 1                                                     # Exit to Shell with Error
    fi

    # USE CONTENT OF VARIABLES BELOW, BUT DON'T CHANGE THEM (Used by SADMIN Standard Library).
    export SADM_PN=${0##*/}                             # Current Script filename(with extension)
    export SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1`   # Current Script filename(without extension)
    export SADM_TPID="$$"                               # Current Script PID
    export SADM_HOSTNAME=`hostname -s`                  # Current Host name without Domain Name
    export SADM_OS_TYPE=`uname -s | tr '[:lower:]' '[:upper:]'` # Return LINUX,AIX,DARWIN,SUNOS 

    # USE AND CHANGE VARIABLES BELOW TO YOUR NEEDS (They influence execution of standard library).
    export SADM_VER='3.4'                               # Your Current Script Version
    export SADM_LOG_TYPE="B"                            # Writelog goes to [S]creen [L]ogFile [B]oth
    export SADM_LOG_APPEND="Y"                          # [Y]=Append Existing Log [N]=Create New One
    export SADM_LOG_HEADER="Y"                          # [Y]=Include Log Header [N]=No log Header
    export SADM_LOG_FOOTER="Y"                          # [Y]=Include Log Footer [N]=No log Footer
    export SADM_MULTIPLE_EXEC="N"                       # Allow running multiple copy at same time ?
    export SADM_USE_RCH="Y"                             # Generate Entry in Result Code History file
    export SADM_DEBUG=0                                 # Debug Level - 0=NoDebug Higher=+Verbose
    export SADM_TMP_FILE1=""                            # Temp File1 you can use, Libr will set name
    export SADM_TMP_FILE2=""                            # Temp File2 you can use, Libr will set name
    export SADM_TMP_FILE3=""                            # Temp File3 you can use, Libr will set name
    export SADM_EXIT_CODE=0                             # Current Script Default Exit Return Code

    . ${SADMIN}/lib/sadmlib_std.sh                      # Ok now, load Standard Shell Library
    export SADM_OS_NAME=$(sadm_get_osname)              # Uppercase, REDHAT,CENTOS,UBUNTU,AIX,DEBIAN
    export SADM_OS_VERSION=$(sadm_get_osversion)        # O/S Full Version Number (ex: 7.6.5)
    export SADM_OS_MAJORVER=$(sadm_get_osmajorversion)  # O/S Major Version Number (ex: 7)

#---------------------------------------------------------------------------------------------------
# Values of these variables are loaded from SADMIN config file ($SADMIN/cfg/sadmin.cfg file).
# They can be overridden here, on a per script basis (if needed).
    #export SADM_ALERT_TYPE=1                           # 0=None 1=AlertOnErr 2=AlertOnOK 3=Always
    #export SADM_ALERT_GROUP="default"                  # Alert Group to advise (alert_group.cfg)
    #export SADM_MAIL_ADDR="your_email@domain.com"      # Email to send log (To override sadmin.cfg)
    export SADM_MAX_LOGLINE=5000                        # When script end Trim log to 500 Lines
    #export SADM_MAX_RCLINE=60                          # When script end Trim rch file to 60 Lines
    #export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} " # SSH Command to Access Server 
#===================================================================================================





#===================================================================================================
# Scripts Variables 
#===================================================================================================
OS_SCRIPT="sadm_osupdate_farm.sh"                 ; export OS_SCRIPT    # OSUpdate Script in crontab
BA_SCRIPT="sadm_backup.sh"                        ; export BA_SCRIPT    # Backup Script 
REAR_SCRIPT="sadm_rear_backup.sh"                 ; export REAR_SCRIPT  # ReaR Backup Script 
REAR_TMP="${SADMIN}/tmp/rear_site.tmp$$"          ; export REAR_TMP     # New ReaR site.conf tmp file
REAR_CFG="${SADMIN}/tmp/rear_site.cfg$$"          ; export REAR_CFG     # Will be new /etc/site.conf
#
REBOOT_SEC=900                                    ; export REBOOT_SEC   # O/S Upd Reboot Nb Sec.wait
RCH_FIELD=10                                      ; export RCH_FIELD    # Nb. of field on rch file.
#
# Reset Alert Totals Counters
export total_alert=0  ; export total_duplicate=0 ; export total_ok=0 ; export total_error=0      
export total_oldies=0



# --------------------------------------------------------------------------------------------------
# H E L P      U S A G E   D I S P L A Y    F U N C T I O N
# --------------------------------------------------------------------------------------------------
show_usage()
{
    printf "\n${SADM_PN} usage :"
    printf "\n\t-d   (Debug Level [0-9])"
    printf "\n\t-h   (Display this help message)"
    printf "\n\t-v   (Show Script Version Info)"
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
# ---------
# Example of line generated
# 15 04 * * 06 root /sadmin/bin/sadm_osupdate_farm.sh -s nano >/dev/null 2>&1
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
                do                                                      # Get Y or N for the Month                 wchar=`expr substr "$cmonth" $i 1`
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
    cline="$cline $SADM_USER sudo $cscript -s $cserver >/dev/null 2>&1";   
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
# ---------
# Example of line generated
# 15 04 * * 06 root /sadmin/bin/sadm_osupdate_farm.sh -s nano >/dev/null 2>&1
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
                do                                                      # Get Y or N for the Month                 wchar=`expr substr "$cmonth" $i 1`
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
    cline="$cline $SADM_USER sudo $SADM_SSH_CMD $cserver \"$cscript\" >/dev/null 2>&1";   
    if [ $SADM_DEBUG -gt 0 ] ; then sadm_writelog "cline=.$cline.";fi  # Show Cron Line Now

    echo "$cline" >> $SADM_REAR_NEWCRON                               # Output Line to Crontab cfg
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
# ---------
# Example of line generated
# 15 04 * * 06 root /sadmin/bin/sadm_osupdate_farm.sh -s nano >/dev/null 2>&1
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
                do                                                      # Get Y or N for the Month                 wchar=`expr substr "$cmonth" $i 1`
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
    cline="$cline $SADM_USER sudo $SADM_SSH_CMD $cserver \"$cscript\" >/dev/null 2>&1";   
    if [ $SADM_DEBUG -gt 0 ] ; then sadm_writelog "cline=.$cline.";fi  # Show Cron Line Now

    echo "$cline" >> $SADM_BACKUP_NEWCRON                               # Output Line to Crontab cfg
}

#===================================================================================================
# Generic rsync function, use to collect client files (*.rpt,*.log,*.rch,) 
# rsync remote SADM client with local directories
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
        rsync -var --delete ${REMOTE_DIR} ${LOCAL_DIR} >/dev/null 2>&1  # rsync selected directory
        RC=$?                                                           # save error number

        # Consider Error 24 as none critical (Partial transfer due to vanished source files)
        if [ $RC -eq 24 ] ; then RC=0 ; fi                              # Source File Gone is OK

        if [ $RC -ne 0 ]                                                # If Error doing rsync
           then if [ $RETRY -lt 3 ]                                     # If less than 3 retry
                   then sadm_writelog "[ RETRY $RETRY ] rsync -var --delete ${REMOTE_DIR} ${LOCAL_DIR}"
                   else sadm_writelog "[ ERROR $RETRY ] rsync -var --delete ${REMOTE_DIR} ${LOCAL_DIR}"
                        break
                fi
           else sadm_writelog "[ OK ] rsync -var --delete ${REMOTE_DIR} ${LOCAL_DIR}"
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

    # Build the name of the client footer of modified Rear exclude option file.
    REAR_USER_EXCLUDE="${SADM_WWW_DAT_DIR}/${WSERVER}/cfg/rear_exclude.tmp"     

    # If client did not modified the ReaR Exclude option file, then retrun to caller.
    if [ ! -r "$REAR_USER_EXCLUDE" ] ; then return 0 ; fi
    
    # Start creating the header of ReaR site.conf file into a temp. file for now.
    echo  "# Create a bootable ISO9660 image on disk as rear-$(hostname).iso" > $REAR_TMP
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
    cat $REAR_TMP $REAR_USER_EXCLUDE | tr -d '\r' > $REAR_CFG           # Concat & Remove CR in file
    #sadm_writelog "scp -P${SADM_SSH_PORT} $REAR_CFG ${WSERVER}:/etc/rear/site.conf" 
    #scp -P${SADM_SSH_PORT}  $REAR_CFG ${WSERVER}:/etc/rear/site.conf
    #if [ $? -eq 0 ] ; then sadm_writelog "[OK] /etc/rear/site.conf is updated on ${WSERVER}" ;fi
}




# --------------------------------------------------------------------------------------------------
# Process Operating System received in parameter (aix/linux,darwin)
# --------------------------------------------------------------------------------------------------
process_servers()
{
    WOSTYPE=$1                                                          # Should be aix/linux/darwin

    # Select from Database active systems with selected O/S & output result in $SADM_TMP_FILE1
    SQL="SELECT srv_name,srv_ostype,srv_domain,srv_monitor,srv_sporadic,srv_active,srv_sadmin_dir," 
    SQL="${SQL} srv_update_minute,srv_update_hour,srv_update_dom,srv_update_month,srv_update_dow,"
    SQL="${SQL} srv_update_auto,srv_backup,srv_backup_month,srv_backup_dom,srv_backup_dow,"
    SQL="${SQL} srv_backup_hour,srv_backup_minute,"
    SQL="${SQL} srv_img_backup,srv_img_month,srv_img_dom,srv_img_dow,srv_img_hour,srv_img_minute "
    SQL="${SQL} from server"
    SQL="${SQL} where srv_ostype = '${WOSTYPE}' and srv_active = True "
    SQL="${SQL} order by srv_name; "                                    # Order Output by ServerName

    # Setup connection parameters
    WAUTH="-u $SADM_RO_DBUSER  -p$SADM_RO_DBPWD "                       # Set Authentication String 
    CMDLINE="$SADM_MYSQL $WAUTH "                                       # Join MySQL with Authen.
    CMDLINE="$CMDLINE -h $SADM_DBHOST $SADM_DBNAME -N -e '$SQL' | tr '/\t/' '/,/'" # Build CmdLine
    if [ $SADM_DEBUG -gt 5 ] ; then sadm_writelog "$CMDLINE" ; fi      # Debug = Write command Line

    # Test Database Connection
    $SADM_MYSQL $WAUTH -h $SADM_DBHOST -e "show databases;" > /dev/null 2>&1
    if [ $? -ne 0 ]                                                     # Error Connecting to DB
        then sadm_writelog "Error connecting to Database"               # Access Denied
             return 1                                                   # Return Error to Caller
    fi 

    # Execute SQL to list active servers of the right O/S Type
    $SADM_MYSQL $WAUTH -h $SADM_DBHOST $SADM_DBNAME -N -e "$SQL" | tr '/\t/' '/,/' >$SADM_TMP_FILE1
    
    # If file was not created or has a zero lenght, then no actives systems were found
    if [ ! -s "$SADM_TMP_FILE1" ] || [ ! -r "$SADM_TMP_FILE1" ]         # File has zero length?
        then sadm_writelog " "
             sadm_writelog "${SADM_TEN_DASH}"                           # Print 10 Dash line
             sadm_writelog "No Active '$WOSTYPE' system found."         # Not ACtive Server MSG
             sadm_writelog "${SADM_TEN_DASH}"                           # Print 10 Dash line
             return 0                                                   # Return Error to Caller
    fi 

    sadm_writelog " "
    sadm_writelog "Processing active '$WOSTYPE' server(s)"              # Display/Log O/S type
    sadm_writelog " "

    # If on Linux, create the standard header for the O/S update and the backup crontab file.
    if [ "$WOSTYPE" = "linux" ] 
        then #
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
             #
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
             #
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
             
    fi

    xcount=0; ERROR_COUNT=0;
    while read wline                                                    # Data in File then read it
        do                                                              # Line by Line
        xcount=`expr $xcount + 1`                                       # Incr Server Counter Var.
        server_name=`    echo $wline|awk -F, '{ print $1 }'`            # Extract Server Name
        server_os=`      echo $wline|awk -F, '{ print $2 }'`            # Extract O/S (linux/aix)
        server_domain=`  echo $wline|awk -F, '{ print $3 }'`            # Extract Domain of Server
        server_monitor=` echo $wline|awk -F, '{ print $4 }'`            # Monitor t=True f=False
        server_sporadic=`echo $wline|awk -F, '{ print $5 }'`            # Sporadic t=True f=False
        server_dir=`     echo $wline|awk -F, '{ print $7 }'`            # SADMIN Dir on Client 
        fqdn_server=`    echo ${server_name}.${server_domain}`          # Create FQN Server Name
        #
        db_updmin=`     echo $wline|awk -F, '{ print $8 }'`            # crontab Update Min field
        db_updhrs=`     echo $wline|awk -F, '{ print $9 }'`            # crontab Update Hrs field
        db_upddom=`     echo $wline|awk -F, '{ print $10 }'`           # crontab Update DOM field
        db_updmth=`     echo $wline|awk -F, '{ print $11 }'`           # crontab Update Mth field
        db_upddow=`     echo $wline|awk -F, '{ print $12 }'`           # crontab Update DOW field 
        db_updauto=`    echo $wline|awk -F, '{ print $13 }'`           # crontab Update DOW field 
        #
        backup_auto=`   echo $wline|awk -F, '{ print $14 }'`           # crontab Backup 1=Yes 0=No 
        backup_mth=`    echo $wline|awk -F, '{ print $15 }'`           # crontab Backup Mth field
        backup_dom=`    echo $wline|awk -F, '{ print $16 }'`           # crontab Backup DOM field
        backup_dow=`    echo $wline|awk -F, '{ print $17 }'`           # crontab Backup DOW field 
        backup_hrs=`    echo $wline|awk -F, '{ print $18 }'`           # crontab Backup Hrs field
        backup_min=`    echo $wline|awk -F, '{ print $19 }'`           # crontab Backup Min field
        #
        rear_auto=`     echo $wline|awk -F, '{ print $20 }'`           # Rear Crontab 1=Yes 0=No 
        rear_mth=`      echo $wline|awk -F, '{ print $21 }'`           # Rear Crontab Mth field
        rear_dom=`      echo $wline|awk -F, '{ print $22 }'`           # Rear Crontab DOM field
        rear_dow=`      echo $wline|awk -F, '{ print $23 }'`           # Rear Crontab DOW field 
        rear_hrs=`      echo $wline|awk -F, '{ print $24 }'`           # Rear Crontab Hrs field
        rear_min=`      echo $wline|awk -F, '{ print $25 }'`           # Rear Crontab Min field
        #
        sadm_writelog "${SADM_TEN_DASH}"                                # Print 10 Dash line
        sadm_writelog "Processing [$xcount] ${fqdn_server}"             # Print Counter/Server Name

        # To Display Database Column we will used, for debugging
        if [ $SADM_DEBUG -gt 7 ] 
            then sadm_writelog "Column Name and Value before processing them."
                 sadm_writelog "server_name   = $server_name"           # Server Name to run script
                 sadm_writelog "backup_auto   = $backup_auto"           # Run Backup ? 1=Yes 0=No 
                 sadm_writelog "backup_mth    = $backup_mth"            # Month String YNYNYNYNYNY..
                 sadm_writelog "backup_dom    = $backup_dom"            # Day of MOnth String YNYN..
                 sadm_writelog "backup_dow    = $backup_dow"            # Day of Week String YNYN...
                 sadm_writelog "backup_hrs    = $backup_hrs"            # Hour to run script
                 sadm_writelog "backup_min    = $backup_min"            # Min. to run Script
                 sadm_writelog "fqdn_server   = $fqdn_server"           # Name of Output file
        fi

        # IF SERVER NAME CAN'T BE RESOLVED - SIGNAL ERROR AND CONTINUE WITH NEXT SERVER
        if ! host  $fqdn_server >/dev/null 2>&1
           then SMSG="[ ERROR ] Can't process '$fqdn_server', hostname can't be resolved"
                sadm_writelog "$SMSG"                                   # Advise user
                echo "$SMSG" >> $SADM_ELOG                              # Log Err. to Email Log
                ERROR_COUNT=$(($ERROR_COUNT+1))                         # Consider Error -Incr Cntr
                if [ $ERROR_COUNT -ne 0 ]
                   then sadm_writelog "Total ${WOSTYPE} error(s) is now $ERROR_COUNT"
                fi
                continue                                                # skip this server
        fi

        # On Linux & O/S AutoUpdate is ON, Generate Crontab entry in O/S Update crontab work file
        if [ "$WOSTYPE" = "linux" ] && [ "$db_updauto" -eq 1 ]          # If O/S Update Scheduled
            then update_osupdate_crontab "$server_name" "${SADM_BIN_DIR}/$OS_SCRIPT" "$db_updmin" "$db_updhrs" "$db_updmth" "$db_upddom" "$db_upddow"
        fi

        # Generate Crontab Entry for this server in Backup crontab work file
        #if [ "$WOSTYPE" = "linux" ] && [ $backup_auto -eq 1 ]          # If Backup set to Yes 
        if [ $backup_auto -eq 1 ]                                       # If Backup set to Yes 
            then update_backup_crontab "$server_name" "${server_dir}/bin/$BA_SCRIPT" "$backup_min" "$backup_hrs" "$backup_mth" "$backup_dom" "$backup_dow"
        fi

        # Generate Crontab Entry for this server in ReaR crontab work file
        if [ "$WOSTYPE" = "linux" ] && [ $rear_auto -eq 1 ]            # If Rear Backup set to Yes 
            then update_rear_crontab "$server_name" "${server_dir}/bin/$REAR_SCRIPT" "$rear_min" "$rear_hrs" "$rear_mth" "$rear_dom" "$rear_dow"
        fi
                
        # Test to prevent false Alert when the server is rebooting after a O/S Update.
        # Wait 15 minutes (900 Seconds) before signaling a problem.
        rch_osupd_name="${SADM_WWW_DAT_DIR}/${server_name}/rch/${server_name}_sadm_osupdate.rch"
        if [ -r "$rch_osupd_name" ] 
            then rch_epoch=`stat --printf='%Y\n' $rch_osupd_name`
                 cur_epoch=$(sadm_get_epoch_time)
                 upd_elapse=`echo $cur_epoch - $rch_epoch | $SADM_BC`
                  if [ $SADM_DEBUG -gt 0 ] 
                        then sadm_writelog "Last O/S Update done $upd_elapse sec. ago ($rch_osupd_name)." 
                  fi
        fi


        # TEST SSH TO SERVER
        if [ "$fqdn_server" != "$SADM_SERVER" ]                         # If Not on SADMIN Try SSH
            then $SADM_SSH_CMD $fqdn_server date > /dev/null 2>&1       # SSH to Server for date
                 RC=$?                                                  # Save Error Number
                 if [ $RC -ne 0 ] &&  [ "$server_sporadic" = "1" ]      # SSH don't work & Sporadic
                    then sadm_writelog "[ WARNING ] Can't SSH to sporadic server $fqdn_server"
                         continue                                       # Go process next server
                 fi
                 if [ $RC -ne 0 ] &&  [ "$server_monitor" = "0" ]       # SSH don't work/Monitor OFF
                    then sadm_writelog "[ WARNING ] Can't SSH to $fqdn_server - Monitoring SSH is OFF"
                         continue                                       # Go process next server
                 fi
                RETRY=0                                                 # Set Retry counter to zero
                while [ $RETRY -lt 3 ]                                  # Retry rsync 3 times
                    do
                    let RETRY=RETRY+1                                   # Incr Retry counter
                    $SADM_SSH_CMD $fqdn_server date > /dev/null 2>&1    # SSH to Server for date
                    RC=$?                                               # Save Error Number
                    if [ $RC -ne 0 ]                                    # If Error doing ssh
                        then if [ $RETRY -lt 3 ]                        # If less than 3 retry
                                then sadm_writelog "[ RETRY $RETRY ] $SADM_SSH_CMD $fqdn_server date"
                                else if "$upd_elapse" -gt "$REBOOT_SEC" ] 
                                        then sadm_writelog "[ ERROR $RETRY ] $SADM_SSH_CMD $fqdn_server date"
                                             ERROR_COUNT=$(($ERROR_COUNT+1))    # Consider Error -Incr Cntr
                                             sadm_writelog "Total ${WOSTYPE} error(s) is now $ERROR_COUNT"
                                             SMSG="[ ERROR ] Can't SSH to server '${fqdn_server}'"  
                                             sadm_writelog "$SMSG"              # Display Error Msg
                                             echo "$SMSG" >> $SADM_ELOG         # Log Err. to Email Log
                                             echo "COMMAND : $SADM_SSH_CMD $fqdn_server date" >> $SADM_ELOG
                                             echo "----------" >> $SADM_ELOG 
                                             continue
                                        else sadm_writelog "Waiting for reboot to finish after O/S Update."
                                             sadm_writelog "O/S Update started $upd_elapse seconds ago."
                                             sadm_writelog "Will continue with next server."
                                             continue 
                                     fi
                             fi
                        else sadm_writelog "[ OK ] $SADM_SSH_CMD $fqdn_server date"
                             break
                    fi
                    done
        fi




        # Set remote $SADMIN/cfg Dir. and local www/dat/${server_name}/cfg directory.
        LDIR="${SADM_WWW_DAT_DIR}/${server_name}/cfg"                   # cfg Local Receiving Dir.
        RDIR="${server_dir}/cfg"                                        # Remote cfg Directory

        # If client backup list was modified on master (if backup_list.tmp exist) then update client.
        if [ -r "$LDIR/backup_list.tmp" ]                               # If backup list was modify
           then if [ "$fqdn_server" != "$SADM_SERVER" ]                 # If Not on SADMIN Server
                   then rsync $LDIR/backup_list.tmp ${server_name}:$RDIR/backup_list.txt # Rem.Rsync
                   else rsync $LDIR/backup_list.tmp $SADM_CFG_DIR/backup_list.txt  # Local Rsync 
                fi
                RC=$?                                                   # Save Command Return Code
                if [ $RC -eq 0 ]                                        # If copy to client Worked
                    then sadm_writelog "[OK] Modified Backup list updated on ${server_name}"
                         rm -f $LDIR/backup_list.tmp                    # Remove modified Local copy
                    else sadm_writelog "[ERROR] Syncing backup list with ${server_name}"
                fi
        fi

        # If backup exclude list was modified on master (if backup_exclude.tmp exist), update client
        if [ -r "$LDIR/backup_exclude.tmp" ]                            # Backup Exclude list modify
           then if [ "$fqdn_server" != "$SADM_SERVER" ]                 # If Not on SADMIN Server
                   then rsync $LDIR/backup_exclude.tmp ${server_name}:$RDIR/backup_exclude.txt 
                   else rsync $LDIR/backup_exclude.tmp $SADM_CFG_DIR/backup_exclude.txt # LocalRsync 
                fi
                RC=$?                                                   # Save Command Return Code
                if [ $RC -eq 0 ]                                        # If copy to client Worked
                    then sadm_writelog "[OK] Modified Backup Exclude list updated on ${server_name}"
                         rm -f $LDIR/backup_exclude.tmp                 # Remove modified Local copy
                    else sadm_writelog "[ERROR] Syncing Backup Exclude list with ${server_name}"
                fi
        fi

        # Build the name of the client footer that might have been modified Rear by user.
        REAR_USER_EXCLUDE="${SADM_WWW_DAT_DIR}/${server_name}/cfg/rear_exclude.tmp"     

        # Check if ReaR backup exclude list was modified (if backup_exclude.tmp exist), update client
        if [ -r "$REAR_USER_EXCLUDE" ]                                  # Rear Exclude option modify
           then update_rear_site_conf ${server_name}
                if [ "$fqdn_server" != "$SADM_SERVER" ]                 # If Not on SADMIN Server
                   then #sadm_writelog "rsync -var $REAR_CFG ${server_name}:/etc/rear/site.conf "
                        rsync $REAR_CFG ${server_name}:/etc/rear/site.conf 
                        if [ $? -eq 0 ] 
                            then sadm_writelog "[ OK ] /etc/rear/site.conf updated on ${server_name}"
                        fi
                        #sadm_writelog "rsync -var $REAR_USER_EXCLUDE ${server_name}:${SADM_CFG_DIR}/rear_exclude.txt" 
                        rsync $REAR_USER_EXCLUDE ${server_name}:${SADM_CFG_DIR}/rear_exclude.txt 
                   else #sadm_writelog "rsync -var $REAR_CFG /etc/rear/site.conf" 
                        rsync $REAR_CFG /etc/rear/site.conf
                        if [ $? -eq 0 ] 
                            then sadm_writelog "[ OK ] /etc/rear/site.conf updated on ${server_name}"
                        fi
                        rsync $REAR_USER_EXCLUDE ${SADM_CFG_DIR}/rear_exclude.txt
                fi
                RC=$?                                                   # Save Command Return Code
                if [ $RC -eq 0 ]                                        # If copy to client Worked
                    then sadm_writelog "[OK] Modified ReaR site option file on ${server_name}"
                         rm -f $LDIR/backup_exclude.tmp                 # Remove modified Local copy
                    else sadm_writelog "[ERROR] Syncing ReaR site option file on ${server_name}"
                fi
        fi

        # Get remote $SADMIN/cfg Dir. and update local www/dat/${server_name}/cfg directory.
        if [ "$fqdn_server" != "$SADM_SERVER" ]                         # If Not on SADMIN Try SSH 
            then rsync_function "${fqdn_server}:${RDIR}/" "${LDIR}/"    # Remote to Local rsync
            else rsync_function "${RDIR}/" "${LDIR}/"                   # Local Rsync if on Master
        fi
        if [ $RC -ne 0 ] ; then ERROR_COUNT=$(($ERROR_COUNT+1)) ; fi    # rsync error, Incr Err Cntr
        chown -R $SADM_WWW_USER:$SADM_WWW_GROUP ${SADM_WWW_DAT_DIR}/${server_name} # Change Owner

        
        # Get remote $SADMIN/log Dir. and update local www/dat/${server_name}/log directory.
        LDIR="${SADM_WWW_DAT_DIR}/${server_name}/log"                   # Local Receiving Dir.
        RDIR="${server_dir}/log"                                        # Remote log Directory
        if [ "$fqdn_server" != "$SADM_SERVER" ]                         # If Not on SADMIN Try SSH 
            then rsync_function "${fqdn_server}:${RDIR}/" "${LDIR}/"    # Remote to Local rsync
            else rsync_function "${RDIR}/" "${LDIR}/"                   # Local Rsync if on Master
        fi
        if [ $RC -ne 0 ] ; then ERROR_COUNT=$(($ERROR_COUNT+1)) ; fi    # rsync error, Incr Err Cntr


       # Rsync remote rch dir. onto local web rch dir/ (${SADMIN}/www/dat/${server_name}/rch) 
        LDIR="${SADM_WWW_DAT_DIR}/${server_name}/rch"                   # Local Receiving Dir. Path
        RDIR="${server_dir}/dat/rch"                                    # Remote RCH Directory Path
        if [ "$fqdn_server" != "$SADM_SERVER" ]                         # If Not on SADMIN Try SSH 
            then rsync_function "${fqdn_server}:${RDIR}/" "${LDIR}/"    # Remote to Local rsync
            else rsync_function "${RDIR}/" "${LDIR}/"                   # Local Rsync if on Master
        fi
        if [ $RC -ne 0 ] ; then ERROR_COUNT=$(($ERROR_COUNT+1)) ; fi    # rsync error, Incr Err Cntr


        # Get remote $SADMIN/dat/rpt Dir. and update local www/dat/${server_name}/rpt directory.
        LDIR="$SADM_WWW_DAT_DIR/${server_name}/rpt"                     # Local www Receiving Dir.
        RDIR="${server_dir}/dat/rpt"                                    # Remote log Directory
        if [ "$fqdn_server" != "$SADM_SERVER" ]                         # If Not on SADMIN Try SSH 
            then rsync_function "${fqdn_server}:${RDIR}/" "${LDIR}/"    # Remote to Local rsync
            else rsync_function "${RDIR}/" "${LDIR}/"                   # Local Rsync if on Master
        fi
        if [ $RC -ne 0 ] ; then ERROR_COUNT=$(($ERROR_COUNT+1)) ; fi    # rsync error, Incr Err Cntr


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
    sadm_writelog "Verifying all systems 'Sysmon report file' (*.rpt) for Warning, Info and Errors."
    sadm_writelog " "
    #find $SADM_WWW_DAT_DIR -type f -name '*.rpt' -exec cat {} \; 
    find $SADM_WWW_DAT_DIR -type f -name '*.rpt' -exec cat {} \; > $SADM_TMP_FILE1

    # Process the file containing all *.rpt content (if any).
    if [ -s "$SADM_TMP_FILE1" ]                                         # If File Not Zero in Size
        then cat $SADM_TMP_FILE1 | while read line                      # Read Each Line of file
                do
                if [ $SADM_DEBUG -gt 0 ] ; then sadm_writelog "Processing Line=$line" ; fi
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
                if [ $SADM_DEBUG -gt 0 ] 
                    then sadm_writelog "sadm_send_alert $etype $etime $ehost sysmon $egname $esub $emess $eattach"
                fi
                sadm_writelog "$etime alert ($etype) from 'SysMon' on ${ehost}: $emess"
                sadm_send_alert "$etype" "$etime" "$ehost" "SysMon" "$egname" "$esub" "$emess" "$eattach"
                done 
        else sadm_writelog  "No error reported by SysMon report files (*.rpt)" 
    fi
    sadm_writelog "${SADM_TEN_DASH}"                                    # Print 10 Dash lineHistory

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
    sadm_writelog " "
    sadm_writelog "Verifying all systems [R]esult [C]ode [H]istory (*.rch) files."
    find $SADM_WWW_DAT_DIR -type f -name '*.rch' -exec tail -1 {} \; > $SADM_TMP_FILE1 2>&1
    awk 'match($NF,/[0-1]/) { print }' $SADM_TMP_FILE1 >$SADM_TMP_FILE2 # Keep line ending with 0or1

    # If No file to process
    if [ ! -s "$SADM_TMP_FILE2" ]                                       # If File Zero in Size
        then sadm_writelog  "No error reported by any scripts files (*.rch)" 
             sadm_writelog "${SADM_TEN_DASH}"                           # Print 10 Dash 
             sadm_writelog " "                                          # Separation Blank Line
             return 0                                                   # Return to Caller
    fi

    # Loop through each line in the created file.
    alert_counter=0                                                     # Init alert counter
    cat $SADM_TMP_FILE2 | { while read line                             # Read Each Line of file
        do                
        NBFIELD=`echo $line | awk '{ print NF }'`                       # How many fields on line ?

        # Each line MUST have the right number of field ($NBFIELD) to be process, else skip line.
        if [ $SADM_DEBUG -gt 5 ] ;then sadm_writelog "Processing Line: ${line} ($NBFIELD)" ;fi
        if [ "${NBFIELD}" != "${RCH_FIELD}" ]                           # If abnormal nb. of field
           then sadm_writelog "Line below have ${NBFIELD} but it should have ${RCH_FIELD}."
                sadm_writelog "This line is skipped: $line"
                sadm_writelog " "
                continue 
        fi

        # Extract each field from the current line and prepare alert content.
        ehost=`echo $line   | awk '{ print $1 }'`                       # Host Name of Event
        wdate=`echo $line   | awk '{ print $4 }'`                       # Get Script Ending Date 
        wtime=`echo $line   | awk '{ print $5 }' `                      # Get Script Ending Time 
        wtime=`echo ${wtime:0:5}`                                       # Eliminate the Seconds
        etime="${wdate} ${wtime}"                                       # Combine Event Date & Time
        escript=`echo $line | awk '{ print $7 }'`                       # Script Name 
        egname=`echo $line  | awk '{ print $8 }'`                       # Alert Group Name
        egtype=`echo $line  | awk '{ print $9 }'`                       # Alert Group Type [0,1,2,3]
        ecode=`echo $line   | awk '{ print $10 }'`                      # Return Code (0,1)
        etype="S"                                                       # Event Type = S = Script 
        if [ "$ecode" = "1" ]                                           # Script Ended with Error
           then esub="Error on $ehost while running ${escript}."        # Alert Subject
                emess="Script '$escript' failed on ${ehost}."           # Alert Message
           else esub="Successfully ran '$escript' on ${ehost}."         # Alert Subject
                emess="Successfully ran '$escript' on ${ehost}."        # Alert Message
        fi
        elogfile="${ehost}_${escript}.log"                              # Build Log File Name
        elogname="${SADM_WWW_DAT_DIR}/${ehost}/log/${elogfile}"         # Build Log Full Path File
        if [ -e "$elogname" ]                                           # If Log file exist
           then eattach="$elogname"                                     # Set Attachment to LogName
           else eattach=""                                              # Clear Attachment LogName
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
                   then dmess="'$etype' '$etime' '$ehost' '$egname'"    # Build Mess to see Param.
                        dmess="$dmess '$esub' '$emess' '$eattach'"      # Build Mess to see Param.
                        sadm_writelog "sadm_send_alert $dmess RC=$RC"   # Show User Paramaters sent
                fi
                alert_counter=`expr $alert_counter + 1`                 # Increase Submit AlertCount
                sadm_writelog " " 
                sadm_writelog "${alert_counter}) $etime alert ($etype) for $escript on ${ehost}: $emess"
                sadm_send_alert "$etype" "$etime" "$ehost" "$escript" "$egname" "$esub" "$emess" "$eattach"
                RC=$?
                if [ $SADM_DEBUG -gt 0 ] ;then sadm_writelog "RC=$RC" ;fi # Debug Show ReturnCode
                case $RC in
                    0)  total_ok=`expr $total_ok + 1`
                        sadm_writelog "   - Alert was sent successfully." 
                        ;;
                    1)  total_error=`expr $total_error + 1`
                        sadm_writelog "   - Error submitting the alert."
                        ;;
                    2)  total_duplicate=`expr $total_duplicate + 1`
                        sadm_writelog "   - Alert already sent."
                        ;;
                    3)  total_oldies=`expr $total_oldies + 1`
                        sadm_writelog "   - Alert is older than 24 hrs."
                        ;;
                    *)  sadm_writelog "   - ERROR: Unknown return code $RC"
                        ;;
                esac                                                    # End of case
        fi
        done 

        # Print Alert submitted Summary
        sadm_writelog " "                                               # Separation Blank Line
        sadm_writelog "${SADM_TEN_DASH}"                                # Print 10 Dash lineHistory
        sadm_writelog "$total_alert Alert(s) submitted"
        sadm_writelog "   - New alert sent successfully : $total_ok"
        sadm_writelog "   - Alert error trying to send  : $total_error"
        sadm_writelog "   - Alert older than 24 Hrs     : $total_oldies"
        sadm_writelog "   - Alert already sent          : $total_duplicate"
        sadm_writelog "${SADM_TEN_DASH}"                                # Print 10 Dash lineHistory
    }                                                              
}


  

# --------------------------------------------------------------------------------------------------
# Get from all actives servers the new hostname.rpt file and all the new or updated *.rch files.
# --------------------------------------------------------------------------------------------------
main_process()
{
    # Process All Active Linux/Aix servers
    LINUX_ERROR=0; AIX_ERROR=0 ; MAC_ERROR=0                            # Init. Error count to 0
    process_servers "linux"                                             # Process Active Linux
    LINUX_ERROR=$?                                                      # Save Nb. Errors in process
    process_servers "aix"                                               # Process Active Aix
    AIX_ERROR=$?                                                        # Save Nb. Errors in process
    process_servers "darwin"                                            # Process Active MacOS
    MAC_ERROR=$?                                                        # Save Nb. Errors in process

    # Print Total Script Errors
    sadm_writelog "${SADM_TEN_DASH}"                                    # Print 10 Dash line
    sadm_writelog "System Sync Summary"                                 # Rsync Summary 
    SADM_EXIT_CODE=$(($AIX_ERROR+$LINUX_ERROR+$MAC_ERROR))              # ExitCode=AIX+Linux+Mac Err
    sadm_writelog " - Total Linux error(s)  : ${LINUX_ERROR}"           # Display Total Linux Errors
    sadm_writelog " - Total Aix error(s)    : ${AIX_ERROR}"             # Display Total Aix Errors
    sadm_writelog " - Total Mac error(s)    : ${MAC_ERROR}"             # Display Total Mac Errors
    sadm_writelog " - Script Total Error(s) : ${SADM_EXIT_CODE}"        # Display Total Script Error
    sadm_writelog "${SADM_TEN_DASH}"                                    # Print 10 Dash lineHistory
    sadm_writelog " "                                                   # Separation Blank Line

    # Check for Error or Alert to submit
    check_all_rpt                                                       # Check all *.rpt for Alert
    check_all_rch                                                       # Check all *.rch for Alert

    if [ $(sadm_get_ostype) = "LINUX" ] ; then crontab_update ; fi      # Update crontab if needed
    
    # This script is run regularely (every 5 minutes), we copy the updated .rch file in 
    # the directory used by web interface, otherwise it shows as running most of the times
    if [ ! -d ${SADM_WWW_DAT_DIR}/${SADM_HOSTNAME}/rch ]                # Web RCH repo Dir not exist
        then mkdir -p ${SADM_WWW_DAT_DIR}/${SADM_HOSTNAME}/rch          # Create it
    fi
    cp $SADM_RCHLOG ${SADM_WWW_DAT_DIR}/${SADM_HOSTNAME}/rch            # cp rch for instant Status

    return $SADM_EXIT_CODE
}



# --------------------------------------------------------------------------------------------------
# Check checksum of current crontab versus the one created while processing each systems.
# If checksum is different, update the crontab file (For sadm_osupdate file and sadm_vackup file).
# --------------------------------------------------------------------------------------------------
crontab_update()
{

    # Create New O/S Update crontab sha1sum
    if [ -f ${SADM_CRON_FILE} ] ; then work_sha1=`sha1sum ${SADM_CRON_FILE} |awk '{print $1}'` ;fi 
    # Create Actual O/S Update crontab sha1sum
    if [ -f ${SADM_CRONTAB} ]   ; then real_sha1=`sha1sum ${SADM_CRONTAB}   |awk '{print $1}'` ;fi 

    if [ "$work_sha1" != "$real_sha1" ]                                 # New Different than Actual?
       then cp ${SADM_CRON_FILE} ${SADM_CRONTAB}                        # Put in place New Crontab
            chmod 644 $SADM_CRONTAB ; chown root:root ${SADM_CRONTAB}   # Set crontab Perm.
            sadm_writelog "O/S Update crontab was updated ..."          # Advise user
       else sadm_writelog "No need to update O/S Update crontab ..."    # CheckSum Equal no update
    fi
    rm -f ${SADM_CRON_FILE} >>/dev/null 2>&1                            # Remove crontab work file
    sadm_writelog "${SADM_TEN_DASH}"                                    # Print 10 Dash lineHistory
    sadm_writelog " "                                                   # Separation Blank Line


    # Create New backup crontab sha1sum
    if [ -f ${SADM_BACKUP_NEWCRON} ] ; then nsha1=`sha1sum ${SADM_BACKUP_NEWCRON} |awk '{print $1}'` ;fi
    # Create Actual backup crontab sha1sum
    if [ -f ${SADM_BACKUP_CRONTAB} ] ; then asha1=`sha1sum ${SADM_BACKUP_CRONTAB} |awk '{print $1}'` ;fi 

    if [ "$nsha1" != "$asha1" ]                                         # New Different than Actual?
       then cp ${SADM_BACKUP_NEWCRON} ${SADM_BACKUP_CRONTAB}            # Put in place New Crontab
            chmod 644 $SADM_BACKUP_CRONTAB ; chown root:root ${SADM_BACKUP_CRONTAB}
            sadm_writelog "Clients backup schedule crontab was updated" # Advise user
       else sadm_writelog "No need to update Backup crontab ..."        # CheckSum Equal no update
    fi
    rm -f ${SADM_BACKUP_NEWCRON} >>/dev/null 2>&1                       # Remove crontab work file
    sadm_writelog "${SADM_TEN_DASH}"                                    # Print 10 Dash line
    sadm_writelog " "                                                   # Separation Blank Line
 

    # Create New ReaR crontab sha1sum
    if [ -f ${SADM_REAR_NEWCRON} ] ; then nsha1=`sha1sum ${SADM_REAR_NEWCRON} |awk '{print $1}'` ;fi
    # Create Actual backup crontab sha1sum
    if [ -f ${SADM_REAR_CRONTAB} ] ; then asha1=`sha1sum ${SADM_REAR_CRONTAB} |awk '{print $1}'` ;fi 

    if [ "$nsha1" != "$asha1" ]                                         # New Different than Actual?
       then cp ${SADM_REAR_NEWCRON} ${SADM_REAR_CRONTAB}                # Put in place New Crontab
            chmod 644 $SADM_REAR_CRONTAB ; chown root:root ${SADM_REAR_CRONTAB}
            sadm_writelog "Clients ReaR backup schedule crontab was updated" # Advise user
       else sadm_writelog "No need to update ReaR backup crontab ..."   # CheckSum Equal no update
    fi
    rm -f ${SADM_REAR_NEWCRON} >>/dev/null 2>&1                         # Remove crontab work file
    sadm_writelog "${SADM_TEN_DASH}"                                    # Print 10 Dash line
    sadm_writelog " "                                                   # Separation Blank Line
 
}



# --------------------------------------------------------------------------------------------------
#                                       Script Start HERE
# --------------------------------------------------------------------------------------------------

    sadm_start                                                          # Init Env Dir & RC/Log File
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if Problem 

    # If current user is not 'root', exit to O/S with error code 1 (Optional)
    if ! [ $(id -u) -eq 0 ]                                             # If Cur. user is not root 
        then sadm_writelog "Script can only be run by the 'root' user"  # Advise User Message
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S with Error
    fi

    # If we are not on the SADMIN Server, exit to O/S with error code 1 (Optional)
    if [ "$(sadm_get_fqdn)" != "$SADM_SERVER" ]                         # Only run on SADMIN 
        then sadm_writelog "Script can run only on SADMIN server (${SADM_SERVER})"
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close/Trim Log & Del PID
             exit 1                                                     # Exit To O/S with error
    fi

    # Evaluate Command Line Switch Options Upfront
    # (-h) Show Help Usage, (-v) Show Script Version,(-d0-9] Set Debug Level 
    while getopts "hvd:" opt ; do                                       # Loop to process Switch
        case $opt in
            d) SADM_DEBUG=$OPTARG                                       # Get Debug Level Specified
               num=`echo "$SADM_DEBUG" | grep -E ^\-?[0-9]?\.?[0-9]+$`  # Valid is Level is Numeric
               if [ "$num" = "" ]                                       # No it's not numeric 
                  then printf "\nDebug Level specified is invalid\n"    # Inform User Debug Invalid
                       show_usage                                       # Display Help Usage
                       exit 0
               fi
               ;;                                                       # No stop after each
            h) show_usage                                               # Show Help Usage
               exit 0                                                   # Back to shell
               ;;
            v) sadm_show_version                                        # Show Script Version
               exit 0                                                   # Back to shell
               ;;
           \?) printf "\nInvalid option: -$OPTARG"                      # Invalid Option Mes
               show_usage                                               # Display Help Usage
               exit 1                                                   # Exit with Error
               ;;
        esac                                                            # End of case
    done                         
    if [ $SADM_DEBUG -gt 0 ] ; then printf "\nDebug activated, Level ${SADM_DEBUG}\n" ; fi

    main_process                                                        # rsync from all clients
    SADM_EXIT_CODE=$?                                                   # Save Function Result Code 
    sadm_stop $SADM_EXIT_CODE                                           # Close/Trim Log & Upd. RCH
    exit $SADM_EXIT_CODE                                                # Exit With Error code (0/1)
