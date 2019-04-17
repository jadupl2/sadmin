#! /usr/bin/env sh
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
#@2019_04_12  Fix: v2.33 Create Web rch directory, if not exist when script run for the first time.
#@2019_04_17  Update: v2.34 Show Processing message only when active servers are found.
# --------------------------------------------------------------------------------------------------
#
#   Copyright (C) 2016 Jacques Duplessis <duplessis.jacques@gmail.com>
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
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPTE LE ^C
#set -x



#===================================================================================================
# Setup SADMIN Global Variables and Load SADMIN Shell Library
#===================================================================================================
#
    # TEST IF SADMIN LIBRARY IS ACCESSIBLE
    if [ -z "$SADMIN" ]                                 # If SADMIN Environment Var. is not define
        then echo "Please set 'SADMIN' Environment Variable to the install directory." 
             exit 1                                     # Exit to Shell with Error
    fi
    if [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]            # SADM Shell Library not readable
        then echo "SADMIN Library can't be located"     # Without it, it won't work 
             exit 1                                     # Exit to Shell with Error
    fi

    # CHANGE THESE VARIABLES TO YOUR NEEDS - They influence execution of SADMIN standard library.
    export SADM_VER='2.34'                              # Current Script Version
    export SADM_LOG_TYPE="B"                            # Writelog goes to [S]creen [L]ogFile [B]oth
    export SADM_LOG_APPEND="N"                          # Append Existing Log or Create New One
    export SADM_LOG_HEADER="Y"                          # Show/Generate Script Header
    export SADM_LOG_FOOTER="Y"                          # Show/Generate Script Footer 
    export SADM_MULTIPLE_EXEC="N"                       # Allow running multiple copy at same time ?
    export SADM_USE_RCH="Y"                             # Generate Entry in Result Code History file

    # DON'T CHANGE THESE VARIABLES - They are used to pass information to SADMIN Standard Library.
    export SADM_PN=${0##*/}                             # Current Script name
    export SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1`   # Current Script name, without the extension
    export SADM_TPID="$$"                               # Current Script PID
    export SADM_EXIT_CODE=0                             # Current Script Exit Return Code

    # Load SADMIN Standard Shell Library 
    . ${SADMIN}/lib/sadmlib_std.sh                      # Load SADMIN Shell Standard Library

    # Default Value for these Global variables are defined in $SADMIN/cfg/sadmin.cfg file.
    # But some can overriden here on a per script basis.
    #export SADM_ALERT_TYPE=1                            # 0=None 1=AlertOnErr 2=AlertOnOK 3=Allways
    #export SADM_ALERT_GROUP="sprod"                     # AlertGroup Used to Alert (alert_group.cfg)
    #export SADM_MAIL_ADDR="your_email@domain.com"      # Email to send log (To Override sadmin.cfg)
    #export SADM_MAX_LOGLINE=1000                       # When Script End Trim log file to 1000 Lines
    #export SADM_MAX_RCLINE=125                         # When Script End Trim rch file to 125 Lines
    #export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} " # SSH Command to Access Server 
#===================================================================================================


  

#===================================================================================================
# Scripts Variables 
#===================================================================================================
DEBUG_LEVEL=0                                   ; export DEBUG_LEVEL    # 0=NoDebug Higher=+Verbose
OS_SCRIPT="${SADM_BIN_DIR}/sadm_osupdate_farm.sh"; export OS_SCRIPT     # OSUpdate Script in crontab
BA_SCRIPT="${SADM_BIN_DIR}/sadm_backup.sh"      ; export BA_SCRIPT      # Backup Script in crontab
REBOOT_SEC=900                                  ; export REBOOT_SEC     # O/S Upd Reboot Nb Sec.wait


# --------------------------------------------------------------------------------------------------
#       H E L P      U S A G E   A N D     V E R S I O N     D I S P L A Y    F U N C T I O N
# --------------------------------------------------------------------------------------------------
show_usage()
{
    printf "\n${SADM_PN} usage :"
    printf "\n\t-d   (Debug Level [0-9])"
    printf "\n\t-h   (Display this help message)"
    printf "\n\t-v   (Show Script Version Info)"
    printf "\n\n" 
}
show_version()
{
    printf "\n${SADM_PN} - Version $SADM_VER"
    printf "\nSADMIN Shell Library Version $SADM_LIB_VER"
    printf "\n$(sadm_get_osname) - Version $(sadm_get_osversion)"
    printf " - Kernel Version $(sadm_get_kernel_version)"
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
    if [ $DEBUG_LEVEL -gt 5 ] 
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
    if [ $DEBUG_LEVEL -gt 5 ] ; then sadm_writelog "cline=.$cline.";fi  # Show Cron Line Now


    # Construct DATE of the month (1-31) to run and add it to crontab line ($cline) ----------------
    flag_dom=0
    if [ "$cdom" = "YNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN" ]                 # If it's to run every Date
        then cline="$cline *"                                           # Then use a Star for Date
        else fdom=""                                                    # Clear Final Date of Month
             for i in $(seq 2 32)
                do    
                wchar=`expr substr $cdom $i 1`
                if [ $DEBUG_LEVEL -gt 5 ] ; then echo "cdom[$i] = $wchar" ; fi
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
    if [ $DEBUG_LEVEL -gt 5 ] ; then sadm_writelog "cline=.$cline.";fi  # Show Cron Line Now


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
    if [ $DEBUG_LEVEL -gt 5 ] ; then sadm_writelog "cline=.$cline.";fi  # Show Cron Line Now


    # Construct the day of the week (0-6) to run the script and add it to crontab line ($cline) ----
    flag_dow=0
    if [ "$cdow" = "YNNNNNNN" ]                                         # 1st Char=Y Run all dayWeek
        then cline="$cline *"                                           # Then use Star for All Week
        else fdow=""                                                    # Final Day of Week Flag
             for i in $(seq 2 8)                                        # Check Each Day 2-8 = 0-6
                do                                                      # Day of the week (dow)
                wchar=`expr substr "$cdow" $i 1`                        # Get Char of loop
                if [ $DEBUG_LEVEL -gt 5 ] ; then echo "cdow[$i] = $wchar" ; fi
                if [ "$wchar" = "Y" ]                                   # If Day is Yes 
                    then xday=`expr $i - 2`                             # Adjust Indx to Crontab Day
                         if [ $DEBUG_LEVEL -gt 5 ] ; then echo "xday = $xday" ; fi
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
    if [ $DEBUG_LEVEL -gt 5 ] ; then sadm_writelog "cline=.$cline.";fi  # Show Cron Line Now
    
    
    # Add User, script name and script parameter to crontab line -----------------------------------
    # SCRIPT WILL RUN ONLY IF LOCATED IN $SADMIN/BIN 
    # $SADM_TMP_DIR
    #cline="$cline root $cscript -s $cserver >/dev/null 2>&1";   
    cline="$cline $SADM_USER sudo $cscript -s $cserver >/dev/null 2>&1";   
    #cline="$cline root $cscript -s $cserver > ${SADM_TMP_DIR}/sadm_osupdate_${cserver}.log 2>&1";   
    if [ $DEBUG_LEVEL -gt 0 ] ; then sadm_writelog "cline=.$cline.";fi  # Show Cron Line Now

    echo "$cline" >> $SADM_CRON_FILE                                    # Output Line to Crontab cfg
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
    if [ $DEBUG_LEVEL -gt 5 ] 
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
    if [ $DEBUG_LEVEL -gt 5 ] ; then sadm_writelog "cline=.$cline.";fi  # Show Cron Line Now


    # Construct DATE of the month (1-31) to run and add it to crontab line ($cline) ----------------
    flag_dom=0
    if [ "$cdom" = "YNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN" ]                 # If it's to run every Date
        then cline="$cline *"                                           # Then use a Star for Date
        else fdom=""                                                    # Clear Final Date of Month
             for i in $(seq 2 32)
                do    
                wchar=`expr substr $cdom $i 1`
                if [ $DEBUG_LEVEL -gt 5 ] ; then echo "cdom[$i] = $wchar" ; fi
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
    if [ $DEBUG_LEVEL -gt 5 ] ; then sadm_writelog "cline=.$cline.";fi  # Show Cron Line Now


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
    if [ $DEBUG_LEVEL -gt 5 ] ; then sadm_writelog "cline=.$cline.";fi  # Show Cron Line Now


    # Construct the day of the week (0-6) to run the script and add it to crontab line ($cline) ----
    flag_dow=0
    if [ "$cdow" = "YNNNNNNN" ]                                         # 1st Char=Y Run all dayWeek
        then cline="$cline *"                                           # Then use Star for All Week
        else fdow=""                                                    # Final Day of Week Flag
             for i in $(seq 2 8)                                        # Check Each Day 2-8 = 0-6
                do                                                      # Day of the week (dow)
                wchar=`expr substr "$cdow" $i 1`                        # Get Char of loop
                if [ $DEBUG_LEVEL -gt 5 ] ; then echo "cdow[$i] = $wchar" ; fi
                if [ "$wchar" = "Y" ]                                   # If Day is Yes 
                    then xday=`expr $i - 2`                             # Adjust Indx to Crontab Day
                         if [ $DEBUG_LEVEL -gt 5 ] ; then echo "xday = $xday" ; fi
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
    if [ $DEBUG_LEVEL -gt 5 ] ; then sadm_writelog "cline=.$cline.";fi  # Show Cron Line Now
    
    
    # Add User, script name and script parameter to crontab line -----------------------------------
    # SCRIPT WILL RUN ONLY IF LOCATED IN $SADMIN/BIN 
    # $SADM_TMP_DIR
    cline="$cline $SADM_USER sudo $SADM_SSH_CMD $cserver \"$cscript\" >/dev/null 2>&1";   
    if [ $DEBUG_LEVEL -gt 0 ] ; then sadm_writelog "cline=.$cline.";fi  # Show Cron Line Now

    echo "$cline" >> $SADM_BACKUP_NEWCRON                               # Output Line to Crontab cfg
}

#===================================================================================================
#                Function use to rsync remote SADM client with local directories
#===================================================================================================
rsync_function()
{
    # Parameters received should always by two - If not write error to log and return to caller
    if [ $# -ne 2 ]
        then sadm_writelog "Error: Function ${FUNCNAME[0]} didn't receive 2 parameters"
             sadm_writelog "Function received $* and this isn't valid"
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
        RETRY=`expr $RETRY + 1`                                        # Incr Retry counter.
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
    #sadm_writelog "chmod 664 ${LOCAL_DIR}*" 
    chmod 664 ${LOCAL_DIR}*
    return $RC
}




# --------------------------------------------------------------------------------------------------
#                      Process servers O/S selected by parameter received (aix/linux)
# --------------------------------------------------------------------------------------------------
process_servers()
{
    WOSTYPE=$1                                                          # Should be aix or linux

    # Select From Database Active Servers with selected O/s & output result in $SADM_TMP_FILE1
    # See rows available in 'table_structure_server.pdf' in $SADMIN/doc/pdf/database directory
    SQL="SELECT srv_name,srv_ostype,srv_domain,srv_monitor,srv_sporadic,srv_active,srv_sadmin_dir," 
    SQL="${SQL} srv_update_minute,srv_update_hour,srv_update_dom,srv_update_month,srv_update_dow,"
    SQL="${SQL} srv_update_auto,srv_backup,srv_backup_month,srv_backup_dom,srv_backup_dow,"
    SQL="${SQL} srv_backup_hour,srv_backup_minute "
    SQL="${SQL} from server"
    SQL="${SQL} where srv_ostype = '${WOSTYPE}' and srv_active = True "
    SQL="${SQL} order by srv_name; "                                    # Order Output by ServerName

    WAUTH="-u $SADM_RO_DBUSER  -p$SADM_RO_DBPWD "                       # Set Authentication String 
    CMDLINE="$SADM_MYSQL $WAUTH "                                       # Join MySQL with Authen.
    CMDLINE="$CMDLINE -h $SADM_DBHOST $SADM_DBNAME -N -e '$SQL' | tr '/\t/' '/,/'" # Build CmdLine
    if [ $DEBUG_LEVEL -gt 5 ] ; then sadm_writelog "$CMDLINE" ; fi      # Debug = Write command Line

    # Test Database Connection
    $SADM_MYSQL $WAUTH -h $SADM_DBHOST -e "show databases;" > /dev/null 2>&1
    if [ $? -ne 0 ]                                                     # Error Connecting to DB
        then sadm_writelog "Error connecting to Database"               # Access Denied
             return 1                                                   # Return Error to Caller
    fi 

    # Execute SQL to Update Server O/S Data
    $SADM_MYSQL $WAUTH -h $SADM_DBHOST $SADM_DBNAME -N -e "$SQL" | tr '/\t/' '/,/' >$SADM_TMP_FILE1
    
    # If File was not created or has a zero lenght then No Actives Servers were found
    if [ ! -s "$SADM_TMP_FILE1" ] || [ ! -r "$SADM_TMP_FILE1" ]         # File has zero length?
        then sadm_writelog "No Active $WOSTYPE server were found."      # Not ACtive Server MSG
             return 0                                                   # Return Error to Caller
    fi 

    sadm_writelog " "
    sadm_writelog "Processing active '$WOSTYPE' server(s)"              # Display/Log O/S type
    sadm_writelog " "

    # Create Crontab File Header 
    if [ "$WOSTYPE" = "linux" ] 
        then # Header for O/S Update Crontab File
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
        db_updmin=`      echo $wline|awk -F, '{ print $8 }'`            # crontab Update Min field
        db_updhrs=`      echo $wline|awk -F, '{ print $9 }'`            # crontab Update Hrs field
        db_upddom=`      echo $wline|awk -F, '{ print $10 }'`           # crontab Update DOM field
        db_updmth=`      echo $wline|awk -F, '{ print $11 }'`           # crontab Update Mth field
        db_upddow=`      echo $wline|awk -F, '{ print $12 }'`           # crontab Update DOW field 
        db_updauto=`     echo $wline|awk -F, '{ print $13 }'`           # crontab Update DOW field 
        backup_auto=`    echo $wline|awk -F, '{ print $14 }'`           # crontab Backup 1=Yes 0=No 
        backup_mth=`     echo $wline|awk -F, '{ print $15 }'`           # crontab Backup Mth field
        backup_dom=`     echo $wline|awk -F, '{ print $16 }'`           # crontab Backup DOM field
        backup_dow=`     echo $wline|awk -F, '{ print $17 }'`           # crontab Backup DOW field 
        backup_hrs=`     echo $wline|awk -F, '{ print $18 }'`           # crontab Backup Hrs field
        backup_min=`     echo $wline|awk -F, '{ print $19 }'`           # crontab Backup Min field

        sadm_writelog "${SADM_TEN_DASH}"                                # Print 10 Dash line
        sadm_writelog "Processing [$xcount] ${fqdn_server}"             # Print Counter/Server Name

        # To Display Database Column we will used, for debugging
        if [ $DEBUG_LEVEL -gt 7 ] 
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

        # On Linux & AutoUpdate is ON, Generate Crontab for server in O/S Update crontab work file
        if [ "$WOSTYPE" = "linux" ] && [ "$db_updauto" -eq 1 ]          # If O/S Update Scheduled
            then update_osupdate_crontab "$server_name" "$OS_SCRIPT" "$db_updmin" "$db_updhrs" "$db_updmth" "$db_upddom" "$db_upddow"
        fi

        # Generate Crontab Entry for this server in Backup crontab work file
        if [ "$WOSTYPE" = "linux" ] && [ $backup_auto -eq 1 ]          # If Backup set to Yes 
            then update_backup_crontab "$server_name" "$BA_SCRIPT" "$backup_min" "$backup_hrs" "$backup_mth" "$backup_dom" "$backup_dow"
        fi
                
        # Test to prevent false Alert when the server is rebooting after a O/S Update.
        # Wait 15 minutes (900 Seconds) before signaling a problem.
        rch_osupd_name="${SADM_WWW_DAT_DIR}/${server_name}/rch/${server_name}_sadm_osupdate.rch"
        if [ -r "$rch_osupd_name" ] 
            then rch_epoch=`stat --printf='%Y\n' $rch_osupd_name`
                 cur_epoch=$(sadm_get_epoch_time)
                 upd_elapse=`echo $cur_epoch - $rch_epoch | $SADM_BC`
                  if [ $DEBUG_LEVEL -gt 0 ] 
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

        # MAKE SURE RCH RECEIVING DIRECTORY EXIST ON THIS SERVER & RSYNC
        LDIR="${SADM_WWW_DAT_DIR}/${server_name}/rch"                   # Local Receiving Dir.
        RDIR="${server_dir}/dat/rch"                                    # Remote RCH Directory
        if [ "$fqdn_server" != "$SADM_SERVER" ]                         # If Not on SADMIN Try SSH 
            then rsync_function "${fqdn_server}:${RDIR}/" "${LDIR}/"    # Remote to Local rsync
            else rsync_function "${RDIR}/" "${LDIR}/"                   # Local Rsync if on Master
        fi
        if [ $RC -ne 0 ] ; then ERROR_COUNT=$(($ERROR_COUNT+1)) ; fi    # rsync error, Incr Err Cntr

        
        # MAKE SURE CFG RECEIVING DIRECTORY EXIST ON THIS SERVER & RSYNC
        LDIR="${SADM_WWW_DAT_DIR}/${server_name}/cfg"                   # cfg Local Receiving Dir.
        RDIR="${server_dir}/cfg"                                        # Remote cfg Directory
        
        # Check if server backup list was modified (if backup_list_tmp exist) and update actual.
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

        # Check if backup exclude list was modified (if backup_list_tmp exist) & update actual
        if [ -r "$LDIR/backup_exclude.tmp" ]                            # Backup Exclude list modify
           then if [ "$fqdn_server" != "$SADM_SERVER" ]                 # If Not on SADMIN Server
                   then rsync $LDIR/backup_exclude.tmp ${server_name}:$RDIR/backup_exclude.txt # Rem.Rsync
                   else rsync $LDIR/backup_exclude.tmp $SADM_CFG_DIR/backup_exclude.txt  # Local Rsync 
                fi
                RC=$?                                                   # Save Command Return Code
                if [ $RC -eq 0 ]                                        # If copy to client Worked
                    then sadm_writelog "[OK] Modified Backup Exclude list updated on ${server_name}"
                         rm -f $LDIR/backup_exclude.tmp                 # Remove modified Local copy
                    else sadm_writelog "[ERROR] Syncing Backup Exclude list with ${server_name}"
                fi
        fi

        # Rsync the $SADMIN/cfg Directory - Get Server cfg Dir. and update local cfg directory.
        if [ "$fqdn_server" != "$SADM_SERVER" ]                         # If Not on SADMIN Try SSH 
            then rsync_function "${fqdn_server}:${RDIR}/" "${LDIR}/"    # Remote to Local rsync
            else rsync_function "${RDIR}/" "${LDIR}/"                   # Local Rsync if on Master
        fi
        if [ $RC -ne 0 ] ; then ERROR_COUNT=$(($ERROR_COUNT+1)) ; fi    # rsync error, Incr Err Cntr
        chown -R $SADM_WWW_USER:$SADM_WWW_GROUP ${SADM_WWW_DAT_DIR}/${server_name}                                   # Files in Dir. Modifiable

        
        # MAKE SURE LOG RECEIVING DIRECTORY EXIST ON THIS SERVER & RSYNC
        LDIR="${SADM_WWW_DAT_DIR}/${server_name}/log"                   # Local Receiving Dir.
        RDIR="${server_dir}/log"                                        # Remote log Directory
        if [ "$fqdn_server" != "$SADM_SERVER" ]                         # If Not on SADMIN Try SSH 
            then rsync_function "${fqdn_server}:${RDIR}/" "${LDIR}/"    # Remote to Local rsync
            else rsync_function "${RDIR}/" "${LDIR}/"                   # Local Rsync if on Master
        fi
        if [ $RC -ne 0 ] ; then ERROR_COUNT=$(($ERROR_COUNT+1)) ; fi    # rsync error, Incr Err Cntr

        # MAKE SURE RPT RECEIVING DIRECTORY EXIST ON THIS SERVER & RSYNC
        LDIR="$SADM_WWW_DAT_DIR/${server_name}/rpt"                     # Local www Receiving Dir.
        RDIR="${server_dir}/dat/rpt"                                    # Remote log Directory
        if [ "$fqdn_server" != "$SADM_SERVER" ]                         # If Not on SADMIN Try SSH 
            then rsync_function "${fqdn_server}:${RDIR}/" "${LDIR}/"    # Remote to Local rsync
            else rsync_function "${RDIR}/" "${LDIR}/"                   # Local Rsync if on Master
        fi
        if [ $RC -ne 0 ] ; then ERROR_COUNT=$(($ERROR_COUNT+1)) ; fi    # rsync error, Incr Err Cntr

        # IF ERROR OCCURED DISPLAY NUMBER OF ERROR
        if [ $ERROR_COUNT -ne 0 ]                                       # If at Least 1 Error
           then sadm_writelog " "                                       # Separation Blank Line
                sadm_writelog "** Total ${WOSTYPE} error(s) is now $ERROR_COUNT" # Show Err. Count
        fi

        done < $SADM_TMP_FILE1

    sadm_writelog " "                                                   # Separation Blank Line
    sadm_writelog "${SADM_TEN_DASH}"                                    # Print 10 Dash line
    
    return $ERROR_COUNT                                                 # Return Total Error Count
}



# --------------------------------------------------------------------------------------------------
# Check SysMon report files (*.rpt) received for errors & for failed Script (Last line of all *.rch)
# --------------------------------------------------------------------------------------------------
check_for_alert()
{

    # ----------
    # Process All Error/Warning collected by SysMon 
    # Get all *.rpt files content and output it then a temp file.
    #  Example : 
    #  find $SADM_WWW_DAT_DIR -type f -name *.rpt -exec cat {} \;
    #   Warning;nomad;2018.09.16;11:00;linux;FILESYSTEM;Filesystem /usr at 86% > 85%;mail;sadmin
    #   Error;nano;2018.09.16;11:00;SERVICE;DAEMON;Service crond|cron not running !;sadm;sadm
    #   Error;holmes;2018.09.16;11:02;linux;FILESYSTEM;Filesystem /usr at 85% > 85%;sprod;sprod
    #   Error;raspi0;2018.09.16;11:00;linux;CPU;CPU at 100 pct for more than 240 min;mail;sadmin
    # ----------
    sadm_writelog "Check All Servers SysMon Report Files for Warning and Errors"
    find $SADM_WWW_DAT_DIR -type f -name '*.rpt' -exec cat {} \; 
    find $SADM_WWW_DAT_DIR -type f -name '*.rpt' -exec cat {} \; > $SADM_TMP_FILE1
    if [ -s "$SADM_TMP_FILE1" ]                                         # If File Not Zero in Size
        then cat $SADM_TMP_FILE1 | while read line                      # Read Each Line of file
                do
                if [ $DEBUG_LEVEL -gt 0 ] ; then sadm_writelog "Processing Line=$line" ; fi
                ehost=`echo $line | awk -F\; '{ print $2 }'`            # Get Hostname for Event
                emess=`echo $line | awk -F\; '{ print $7 }'`            # Get Event Error Message
                if [ ${line:0:1} = "W" ] || [ ${line:0:1} = "w" ]       # If it is a Warning
                    then etype="W"                                      # Set Event Type to Warning
                         egroup=`echo $line | awk -F\; '{ print $8 }'`  # Get Warning Alert Group
                         esubject="$emess"                              # Specify it is a Warning
                fi
                if [ ${line:0:1} = "I" ] || [ ${line:0:1} = "i" ]       # If it is an Info
                    then etype="I"                                      # Set Event Type to Info
                         egroup=`echo $line | awk -F\; '{ print $8 }'`  # Get Info Alert Group
                         esubject="$emess"                              # Specify it is an Info
                fi
                if [ ${line:0:1} = "E" ] || [ ${line:0:1} = "e" ]       # If it is an Info
                    then etype="E"                                      # Set Event Type to Error
                         egroup=`echo $line | awk -F\; '{ print $9 }'`  # Get Error Alert Group
                         esubject="$emess"                              # Specify it is a Error
                fi
                if [ $DEBUG_LEVEL -gt 0 ] 
                    then sadm_writelog "sadm_send_alert $etype $ehost $egroup $esubject $emess" 
                fi
                sadm_send_alert "$etype" "$ehost" "$egroup" "$esubject" "$emess" ""   # Send Alert 
                done 
        else sadm_writelog  "No error reported by SysMon report files (*.rpt)" 
    fi
    sadm_writelog "${SADM_TEN_DASH}"                                    # Print 10 Dash lineHistory


    # ----------
    # Process All Error encountered in scripts (last Line of rch that end with a 1)
    # Example of line in rch file
    #   holmes 2018.09.18 11:48:53 2018.09.18 11:48:53 00:00:00 sadm_template default 1
    # ----------
    # Gather all last line of all *rch files that end with a 1 (Error)
    sadm_writelog " "
    sadm_writelog "Check All Servers [R]esult [C]ode [H]istory Scripts Files for Errors"
    find $SADM_WWW_DAT_DIR -type f -name '*.rch' -exec tail -1 {} \;| awk 'match($9,/1/) { print }' 
    find $SADM_WWW_DAT_DIR -type f -name '*.rch' -exec tail -1 {} \;| awk 'match($9,/1/) { print }' > $SADM_TMP_FILE2 2>&1
    if [ -s "$SADM_TMP_FILE2" ]                                         # If File Not Zero in Size
        then cat $SADM_TMP_FILE2 | while read line                      # Read Each Line of file
                do                
                if [ $DEBUG_LEVEL -gt 0 ] ; then sadm_writelog "Processing Line=$line" ; fi
                etype="S"                                               # Set Script Event Type 
                ehost=`echo $line   | awk '{ print $1 }'`               # Get Hostname for Event
                edate=`echo $line   | awk '{ print $4 }'`               # Get Script Ending Date 
                etime=`echo $line   | awk '{ print $5 }'`               # Get Script Ending Time 
                escript=`echo $line | awk '{ print $7 }'`               # Get Script Name 
                egroup=`echo $line  | awk '{ print $8 }'`               # Get Script Alert Group
                esubject="$escript reported an error on $ehost"
                emess="Script $escript failed at $etime on $edate"      # Create Script Error Mess.
                if [ $DEBUG_LEVEL -gt 0 ] 
                    then sadm_writelog "sadm_send_alert $etype $ehost $egroup $esubject $emess" 
                fi
                sadm_send_alert "$etype" "$ehost" "$egroup" "$esubject" "$emess" "" # Send Alert 
                done 
        else sadm_writelog  "No error reported by any scripts files (*.rch)" 
    fi
    sadm_writelog "${SADM_TEN_DASH}"                                    # Print 10 Dash lineHistory
    sadm_writelog " "                                                   # Separation Blank Line

}



# --------------------------------------------------------------------------------------------------
#                                       Script Start HERE
# --------------------------------------------------------------------------------------------------

# Evaluate Command Line Switch Options Upfront
# (-h) Show Help Usage, (-v) Show Script Version,(-d0-9] Set Debug Level 
    while getopts "hvd:" opt ; do                                       # Loop to process Switch
        case $opt in
            d) DEBUG_LEVEL=$OPTARG                                      # Get Debug Level Specified
               num=`echo "$DEBUG_LEVEL" | grep -E ^\-?[0-9]?\.?[0-9]+$` # Valid is Level is Numeric
               if [ "$num" = "" ]                                       # No it's not numeric 
                  then printf "\nDebug Level specified is invalid\n"    # Inform User Debug Invalid
                       show_usage                                       # Display Help Usage
                       exit 0
               fi
               ;;                                                       # No stop after each page
            h) show_usage                                               # Show Help Usage
               exit 0                                                   # Back to shell
               ;;
            v) show_version                                             # Show Script Version Info
               exit 0                                                   # Back to shell
               ;;
           \?) printf "\nInvalid option: -$OPTARG"                      # Invalid Option Message
               show_usage                                               # Display Help Usage
               exit 1                                                   # Exit with Error
               ;;
        esac                                                            # End of case
    done                                                                # End of while
    if [ $DEBUG_LEVEL -gt 0 ] ; then printf "\nDebug activated, Level ${DEBUG_LEVEL}\n" ; fi

    # Call SADMIN Initialization Procedure
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

    # Process All Active Linux/Aix servers
    LINUX_ERROR=0; AIX_ERROR=0                                          # Init. Error count to 0
    process_servers "linux"                                             # Process Active Linux
    LINUX_ERROR=$?                                                      # Save Nb. Errors in process
    process_servers "aix"                                               # Process Active Aix
    AIX_ERROR=$?                                                        # Save Nb. Errors in process
    process_servers "darwin"                                            # Process Active MacOS
    MAC_ERROR=$?                                                        # Save Nb. Errors in process

    # Print Total Script Errors
    sadm_writelog " "                                                   # Separation Blank Line
    sadm_writelog "${SADM_TEN_DASH}"                                    # Print 10 Dash line
    SADM_EXIT_CODE=$(($AIX_ERROR+$LINUX_ERROR+$MAC_ERROR))              # ExitCode=AIX+Linux+Mac Err
    sadm_writelog "Total Linux error(s)  : ${LINUX_ERROR}"              # Display Total Linux Errors
    sadm_writelog "Total Aix error(s)    : ${AIX_ERROR}"                # Display Total Aix Errors
    sadm_writelog "Total Mac error(s)    : ${MAC_ERROR}"                # Display Total Mac Errors
    sadm_writelog "Script Total Error(s) : ${SADM_EXIT_CODE}"           # Display Total Script Error
    sadm_writelog "${SADM_TEN_DASH}"                                    # Print 10 Dash lineHistory
    sadm_writelog " "                                                   # Separation Blank Line

    # Update O/S Update Crontab if we need too -  Linux ONLY - Can't while in web interface
    if [ $(sadm_get_ostype) = "LINUX" ] 
        then if [ -f ${SADM_CRON_FILE} ] 
                then work_sha1=`sha1sum ${SADM_CRON_FILE} | awk '{ print $1 }'` # New crontab sha1sum
                     if [ -f ${SADM_CRONTAB} ]                                  # Current Crontab exist ?
                        then real_sha1=`sha1sum ${SADM_CRONTAB}   | awk '{ print $1 }'` # Actual crontab sha1sum
                             if [ "$work_sha1" != "$real_sha1" ]                # New Different than Actual?
                                then cp ${SADM_CRON_FILE} ${SADM_CRONTAB}       # Put in place New Crontab
                                     chmod 644 $SADM_CRONTAB ; chown root:root ${SADM_CRONTAB}  # Set contab Perm.
                                     sadm_writelog "O/S Update crontab was updated ..." # Advise user
                                else sadm_writelog "No changes made to O/S Update schedule ..."
                                     sadm_writelog "No need to update O/S Update crontab ..."
                             fi
                             sadm_writelog "${SADM_TEN_DASH}"                   # Print 10 Dash lineHistory
                             sadm_writelog " "                                  # Separation Blank Line
                     fi
             fi
    fi 

    # Update Client Backup Crontab, if we need too -  Linux ONLY - Can't while in web interface
    if [ $(sadm_get_ostype) = "LINUX" ] 
        then if [ -f ${SADM_BACKUP_NEWCRON} ] 
                then work_sha1=`sha1sum ${SADM_BACKUP_NEWCRON} |awk '{ print $1 }'` # New crontab sha1sum
                     if [ -f ${SADM_BACKUP_CRONTAB} ]
                        then real_sha1=`sha1sum ${SADM_BACKUP_CRONTAB} |awk '{ print $1 }'` # Actual crontab sha1sum
                             if [ "$work_sha1" != "$real_sha1" ]                # New Different than Actual?
                                then cp ${SADM_BACKUP_NEWCRON} ${SADM_BACKUP_CRONTAB}   # Put in place New Crontab
                                     chmod 644 $SADM_BACKUP_CRONTAB ; chown root:root ${SADM_BACKUP_CRONTAB}
                                     sadm_writelog "Clients backup schedule crontab was updated ..." # Advise user
                                else sadm_writelog "No changes made to Backup schedule ..."
                                     sadm_writelog "No need to update Backup crontab ..."
                             fi
                             sadm_writelog "${SADM_TEN_DASH}"                   # Print 10 Dash line
                             sadm_writelog " "                                  # Separation Blank Line
                     fi
             fi
    fi 

    # Check All *.rpt files (For Warning and Errors) and all *.rch (For Errors) & Issue Alerts
    check_for_alert                                                     # Report Alert if Any

    sadm_stop $SADM_EXIT_CODE                                           # Close/Trim Log & Upd. RCH

    # Since fetch client in run regularely put a copy of the rch in dir. used for web interface
    # Otherwise it shows as running most fo the times
    if [ ! -d ${SADM_WWW_DAT_DIR}/${SADM_HOSTNAME}/rch ]                # If Web Dir. not exist
        then mkdir -p ${SADM_WWW_DAT_DIR}/${SADM_HOSTNAME}/rch          # Create it
    fi
    cp $SADM_RCHLOG ${SADM_WWW_DAT_DIR}/${SADM_HOSTNAME}/rch            # cp rch for instant Status

    exit $SADM_EXIT_CODE                                                # Exit With Error code (0/1)
