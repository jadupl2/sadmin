#! /usr/bin/env bash
# --------------------------------------------------------------------------------------------------
#   Author:     Jacques Duplessis
#   Title:      sadm_osupdate.sh _ Linux O/S Update script
#   Synopsis:   This script is used to update the Linux OS Platform
#               Support Redhat/Centos v3,4,5,6,7 - Ubuntu - Debian V7,8 - Raspbian V7,8 - Fedora
#   Update  :   March 2015 -  J.Duplessis
#
# --------------------------------------------------------------------------------------------------
# 2016_11_06    V2.6 Insert Logic to Reboot the server after a successful update
#                    (If Specified in Server information in the Database)
#                    The script receive a Y or N (Uppercase) as the first command line parameter to
#                    indicate if a reboot is requested.
# 2016_11_10    v2.7 Script Return code (SADM_EXIT_CODE) was set to 0 even if Error were detected 
#                    when checking if update were available. 
#                    Now Script return an error (1) when checking for update.
# 2016_12_12    v2.8 Correction minor bug with shutdown reboot command on Raspberry Pi
#                    Now Checking if Script is running of SADMIN server at the beginning
#                    No automatic reboot on SADMIN server while it is use to start update on client
# 2017_04_09    v2.9 Added Support for Linux Mint
# 2017_04_10    v3.0 Not detecting Error correctly on Debian Family update, Add Error Message in Log
# 2017_07_08    v3.2 Now using DNF instead of yum for updating Fedora 25 and beyond.
# 2017_12_10    v3.4 No longer Support Redhat/CentOS 3 and 4
# 2018_06_05    v3.5 Adapt to new SADMIN Libr.
# 2018_06_09    v3.6 Change name of this script from sadm_osupdate_client to sadm_client_osupdate
# 2018_06_10    v3.7 Switch back to old name 
# 2018_07_11    v3.8 Code cleanup
# 2018_09_19    v3.9 Include Alert Group 
# 2018_10_24    v3.10 Command line option -d -r -h -v added.
# 2019_01_16 Improvement: v3.11 Add 'apt-get autoremove' when 'deb' package is use.
# 2019_05_23 Update: v3.12 Updated to use SADM_DEBUG instead of Local Variable DEBUG_LEVEL
# 2019_07_12 Update: v3.13 O/S update script now update the date and status in sysinfo.txt. 
# 2019_07_17 Update: v3.14 O/S update script now perform apt-get clean before update start on *.deb
# 2019_11_21 Update: v3.15 Add 'export DEBIAN_FRONTEND=noninteractive' prior to 'apt-get upgrade'.
# 2019_11_21 Update: v3.16 Email sent to SysAdmin if some package are kept back from update.
# 2020_01_18 Update: v3.17 Include everything in script log while running 'apt-get upgrade'. 
# 2020_01_21 Update: v3.18 Enhance the update checking process.
# 2020_02_17 Update: v3.19 Add error message when problem getting the list of package to update.
# 2020_03_03 Update: v3.20 Restructure some code and change help message. 
# 2020_04_01 Update: v3.21 Replace function sadm_writelog() with N/L incl. by sadm_write() No N/L Incl.
# 2020_04_28 Update: v3.22 Use 'apt-get dist-upgrade' instead of 'apt-get -y upgrade' on deb system.
# 2020_05_23 Update: v3.23 Replace 'reboot' instruction with 'shutdown -r' (Problem on some OS).
# 2020_07_29 Update: v3.24 Minor adjustments to screen and log presentation.
# 2020_12_12 Update: v3.25 Minor adjustments.
# 2021_05_04 Update: v3.26 Adjust some message format of the log.
# 2021_08_19 osupdate v3.27 Fix prompting issue on '.deb' distributions.
#@2022_04_27 osupdate v3.28 Use apt command instead of apt-get
#@2022_06_10 osupdate v3.29 Now list package to be updated when using rpm format.
# --------------------------------------------------------------------------------------------------
#set -x






#===================================================================================================
# To use the SADMIN tools and libraries, this section MUST be present near the top of your code.
# SADMIN Section - Setup SADMIN Global Variables and Load SADMIN Shell Library
#===================================================================================================

    # MAKE SURE THE ENVIRONMENT 'SADMIN' IS DEFINED, IF NOT EXIT SCRIPT WITH ERROR.
    if [ -z $SADMIN ] || [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]          # If SADMIN EnvVar not right
        then printf "\nPlease set 'SADMIN' environment variable to the install directory.\n"
             EE="/etc/environment" ; grep "SADMIN=" $EE >/dev/null      # SADMIN in /etc/environment
             if [ $? -eq 0 ]                                            # Yes it is 
                then export SADMIN=`grep "SADMIN=" $EE |sed 's/export //g'|awk -F= '{print $2}'`
                     printf "'SADMIN' Environment variable temporarily set to ${SADMIN}.\n"
                else exit 1                                             # No SADMIN Env. Var. Exit
             fi
    fi 

    # USE CONTENT OF VARIABLES BELOW, BUT DON'T CHANGE THEM (Used by SADMIN Standard Library).
    export SADM_PN=${0##*/}                             # Current Script filename(with extension)
    export SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1`   # Current Script filename(without extension)
    export SADM_TPID="$$"                               # Current Script PID
    export SADM_HOSTNAME=`hostname -s`                  # Current Host name without Domain Name
    export SADM_OS_TYPE=`uname -s | tr '[:lower:]' '[:upper:]'` # Return LINUX,AIX,DARWIN,SUNOS 

    # USE AND CHANGE VARIABLES BELOW TO YOUR NEEDS (They influence execution of standard library).
    export SADM_VER='3.29'                              # Your Current Script Version
    export SADM_LOG_TYPE="B"                            # Writelog goes to [S]creen [L]ogFile [B]oth
    export SADM_LOG_APPEND="N"                          # [Y]=Append Existing Log [N]=Create New One
    export SADM_LOG_HEADER="Y"                          # [Y]=Include Log Header [N]=No log Header
    export SADM_LOG_FOOTER="Y"                          # [Y]=Include Log Footer [N]=No log Footer
    export SADM_MULTIPLE_EXEC="N"                       # Allow running multiple copy at same time ?
    export SADM_USE_RCH="Y"                             # Generate Entry in Result Code History file
    export SADM_DEBUG=0                                 # Debug Level - 0=NoDebug Higher=+Verbose
    export SADM_TMP_FILE1=""                            # Temp File1 you can use, Libr will set name
    export SADM_TMP_FILE2=""                            # Temp File2 you can use, Libr will set name
    export SADM_TMP_FILE3=""                            # Temp File3 you can use, Libr will set name
    export SADM_EXIT_CODE=0                             # Current Script Default Exit Return Code

    . ${SADMIN}/lib/sadmlib_std.sh                      # Load Standard Shell Library Functions
    export SADM_OS_NAME=$(sadm_get_osname)              # O/S in Uppercase,REDHAT,CENTOS,UBUNTU,...
    export SADM_OS_VERSION=$(sadm_get_osversion)        # O/S Full Version Number  (ex: 7.6.5)
    export SADM_OS_MAJORVER=$(sadm_get_osmajorversion)  # O/S Major Version Number (ex: 7)

#---------------------------------------------------------------------------------------------------
# Values of these variables are loaded from SADMIN config file ($SADMIN/cfg/sadmin.cfg file).
# They can be overridden here, on a per script basis (if needed).
    #export SADM_ALERT_TYPE=1                           # 0=None 1=AlertOnErr 2=AlertOnOK 3=Always
    #export SADM_ALERT_GROUP="default"                  # Alert Group to advise (alert_group.cfg)
    #export SADM_MAIL_ADDR="your_email@domain.com"      # Email to send log (To override sadmin.cfg)
    #export SADM_MAX_LOGLINE=500                        # When script end Trim log to 500 Lines
    #export SADM_MAX_RCLINE=35                          # When script end Trim rch file to 35 Lines
    #export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} " # SSH Command to Access Server 
#===================================================================================================




# --------------------------------------------------------------------------------------------------
#                                   Script Variables definition
# --------------------------------------------------------------------------------------------------

# Default to no reboot after an update
WREBOOT="N"                                 ; export WREBOOT            # Def. NoReboot after update


# Sysinfo report file (Wil update last O/S Update date/time and status)
HPREFIX="${SADM_DR_DIR}/$(sadm_get_hostname)"   ; export HPREFIX        # Output File Loc & Name
HWD_FILE="${HPREFIX}_sysinfo.txt"               ; export HWD_FILE       # Hardware File Info



# --------------------------------------------------------------------------------------------------
#       H E L P      U S A G E   A N D     V E R S I O N     D I S P L A Y    F U N C T I O N
# --------------------------------------------------------------------------------------------------
show_usage()
{
    printf "\nUsage: %s%s [options]" "${BOLD}${CYAN}" $(basename "$0")
    printf "\n\t${BOLD}${YELLOW}-d${NORMAL} Set Debug (Verbose) Level [0-9]"
    printf "\n\t${BOLD}${YELLOW}-h${NORMAL} Display this help message"
    printf "\n\t${BOLD}${YELLOW}-v${NORMAL} Show Script Version Info"
    printf "\n\t${BOLD}${YELLOW}-r${NORMAL} Reboot server after update (if needed & config allowed)"
    printf "\n\n" 
}





#===================================================================================================
#                  Run the script received if parameter (Return 0=Success 1= Error)
#===================================================================================================
run_command()
{
    SCRIPT=$1                                                           # Shell Script Name to Run
    CMDLINE="$*"                                                        # Command with All Parameter
    SCMD="${SADM_BIN_DIR}/${CMDLINE}"                                   # Full Path of the script

    if [ ! -x "${SADM_BIN_DIR}/${SCRIPT}" ]                             # If SCript do not exist
        then sadm_write "[ERROR] ${SADM_BIN_DIR}/${SCRIPT} Don't exist or can't execute\n\n" 
             return 1                                                   # Return Error to Caller
    fi 

    sadm_write "Running $SCMD ...\n"                                    # Show Command about to run
    $SCMD >/dev/null 2>&1                                               # Run the Script
    if [ $? -ne 0 ]                                                     # If Error was encounter
        then sadm_write "[ERROR] $SCRIPT Terminate with Error\n"        # Signal Error in Log
             sadm_write "Check Log for further detail about Error\n"    # Show user where to look
             sadm_write "${SADM_LOG_DIR}/${SADM_HOSTNAME}_${SCRIPT}.log\n\n" # Show Log Name    
             return 1                                                   # Return Error to Caller
        else sadm_write "[SUCCESS] Script $SCRIPT terminated.\n\n"      # Advise user it's OK
    fi
    return 0                                                            # Return Success to Caller
}




# --------------------------------------------------------------------------------------------------
# Function to check update available before beginning update
# Function Return :
#   - 0 IF UPDATE ARE AVAILABLE
#   - 1 IF NO UPDATE ARE AVAILABLE
#   - 2 IF PROBLEM CHECKING FOR UPDATE
# --------------------------------------------------------------------------------------------------
check_available_update()
{
    x_version="$(sadm_get_osmajorversion).$(sadm_get_osminorversion)"
    sadm_writelog "Verifying update availability for $(sadm_get_osname) v$(sadm_get_osversion)"
    
    case "$(sadm_get_osname)" in

        "REDHAT"|"CENTOS" ) 
            case "$(sadm_get_osmajorversion)" in
                [2-5])  UpdateStatus=1                                  # No Update available
                        sadm_write "No more update for Redhat/CentOS v$(sadm_get_osmajorversion)\n"
                        sadm_write "This version have reach end of life.\n"
                        ;;
                [6-7])  sadm_write "Checking if update are available, with 'yum check-update'.\n"
                        yum check-update >> $SADM_LOG 2>&1              # List Available update
                        rc=$?                                           # Save Exit Code
                        case $rc in
                            100) UpdateStatus=0                         # Update Exist
                                 dnf check-update                       # List Available update
                                 sadm_write "${SADM_OK} Update available.\n" # Update the log
                                 ;;
                            0)   UpdateStatus=1                         # No Update available
                                 sadm_write "${SADM_OK} No Update available.\n"
                                 ;;
                            *)   UpdateStatus=2                         # Problem Abort Update
                                 sadm_write "${SADM_ERROR} encountered, update aborted.\n"  
                                 sadm_write "For more information check the log ${SADM_LOG}.\n"
                                 ;;
                        esac
                        ;;
                * )     sadm_write "Checking if update are available, with 'dnf check-update'.\n"
                        dnf check-update >> $SADM_LOG 2>&1              # List Available update
                        rc=$?                                           # Save Exit Code
                        case $rc in
                            100) UpdateStatus=0                         # Update Exist
                                 dnf check-update                       # List Available update
                                 sadm_write "${SADM_OK} Update available.\n" # Update the log
                                 ;;
                            0)   UpdateStatus=1                         # No Update available
                                 sadm_write "${SADM_OK} No Update available.\n"
                                 ;;
                            *)   UpdateStatus=2                         # Problem Abort Update
                                 sadm_write "${SADM_ERROR} encountered, update aborted.\n"  
                                 sadm_write "For more information check the log ${SADM_LOG}\n"
                                 ;;
                        esac
                        ;;
            esac
            ;;
            
        "FEDORA"|"ALMALINUX"|"ROCKY" )
            sadm_write "Checking for new update, with 'dnf check-update'\n"  # Update the log
            dnf check-update >> $SADM_LOG 2>&1                          # List Available update
            rc=$?                                                       # Save Exit Code
            case $rc in
                100) UpdateStatus=0                                     # Update Exist
                     dnf check-update                                   # List Available update
                     sadm_write "${SADM_OK} Update available.\n"        # Update the log
                     ;;
                  0) UpdateStatus=1                                     # No Update available
                     sadm_write "${SADM_OK} No Update available.\n"
                     ;;
                  *) UpdateStatus=2                                     # Problem Abort Update
                     sadm_write "${SADM_ERROR} encountered, update aborted.\n" # Update the log
                     sadm_write "For more information check the log ${SADM_LOG}\n"
                     ;;
            esac
            ;;

        "OPENSUSE"|"SUSE" )
            sadm_write "Not supporting $(sadm_get_osname) yet.\n"
            UpdateStatus=1                                              # No Update available
            sadm_write "${SADM_OK} No Update available.\n"
            ;;

        # Ubuntu, Debian, Raspian, Linux MInt, ...
        * ) 
            sadm_writelog "Start with a clean of APT cache, running 'apt-get clean'" 
            apt-get clean  >>$SADM_LOG 2>>$SADM_ELOG                    # Cleanup /var/cache/apt
            rc=$?                                                       # Save Exit Code
            if [ $rc -ne 0 ] 
                then sadm_writelog "[ ERROR ] while cleaning apt cache, return code ${rc}" 
                else sadm_writelog "[ OK ] APT cache is now cleaned." 
            fi
            sadm_writelog " "
            sadm_writelog "Update the APT package repository cache with 'apt-get update'" 
            apt-get update   >>$SADM_LOG 2>>$SADM_ELOG                  # Updating the apt-cache
            rc=$?                                                       # Save Exit Code
            if [ "$rc" -ne 0 ]
               then UpdateStatus=2                                      # 2=Problem checking update
                    sadm_writelog "[ ERROR ] We had problem running the 'apt-get update' command." 
                    sadm_writelog "We had a return code of ${rc}." 
                    sadm_writelog "For more information check the log ${SADM_LOG}."
                    sadm_writelog " " ; sadm_writelog " "
               else sadm_writelog "[ OK ] The cache have been updated."
                    sadm_writelog " " ; sadm_writelog " "
                    sadm_writelog "Retrieving list of upgradable packages." 
                    sadm_writelog "Running 'apt list --upgradable'."
                    NB_UPD=`apt list --upgradable 2>/dev/null | grep -v 'Listing...' | wc -l`
                    if [ "$NB_UPD" -ne 0 ]
                        then sadm_writelog "There are ${NB_UPD} update available."
                             apt list --upgradable 2>/dev/null |grep -iv "listing"  >$SADM_TMP_FILE3 
                             if [ $? -ne 0 ] 
                                then sadm_writelog "Error getting list of packages to update."
                                     sadm_writelog "Script aborted ..." 
                                     sadm_stop 1
                                     exit 1
                                else sadm_writelog "Packages that will be updated."
                                     nl $SADM_TMP_FILE3
                                     UpdateStatus=0                     # 0= Update are available
                             fi 
                        else UpdateStatus=1                             # 1= No Update are available
                             sadm_writelog "[ OK ] No Update available."
                    fi
                    sadm_writelog " " 
            fi
            ;;
    esac 
    
    return $UpdateStatus                                                # 0=UpdExist 1=NoUpd 2=Abort

}


# --------------------------------------------------------------------------------------------------
# Function to update the server with up2date command (RHEL/CentOS v3 v4)
# --------------------------------------------------------------------------------------------------
run_up2date()
{
    sadm_write "${SADM_TEN_DASH}\n"
    sadm_write "Starting the $(sadm_get_osname) update  process ...\n"
    sadm_write "Running \"up2date --nox -u\"\n"
    up2date --nox -u  >>$SADM_LOG 2>>$SADM_ELOG
    rc=$?
    sadm_write "Return Code is ${rc}.\n"
    if [ $rc -ne 0 ]
       then sadm_write "Problem getting list of the update.\n"
            sadm_write "Update not performed - Processing aborted.\n"
       else sadm_write "Update Succeeded - Return Code is 0.\n"
    fi
    sadm_write "${SADM_TEN_DASH}\n"
    return $rc

}


# --------------------------------------------------------------------------------------------------
#                 Function to update the server with yum command
# --------------------------------------------------------------------------------------------------
run_yum()
{
    sadm_write "${SADM_TEN_DASH}\n"
    sadm_write "Starting $(sadm_get_osname) update process ...\n"
    sadm_write "Running : yum -y update\n"
    yum -y update   >>$SADM_LOG 2>>$SADM_ELOG
    rc=$?
    sadm_write "Return Code after yum program update is ${rc}.\n"
    sadm_write "${SADM_TEN_DASH}\n"
    return $rc
}


# --------------------------------------------------------------------------------------------------
#                 Function to update the server with dnf command
# --------------------------------------------------------------------------------------------------
run_dnf()
{
    sadm_write "${SADM_TEN_DASH}\n"
    sadm_write "Starting $(sadm_get_osname) update process ...\n"
    sadm_write "Running : dnf -y update\n"
    dnf -y update  >>$SADM_LOG 2>>$SADM_ELOG 
    rc=$?
    sadm_write "Return Code after dnf program update is ${rc}.\n"
    sadm_write "${SADM_TEN_DASH}\n"
    return $rc
}






# --------------------------------------------------------------------------------------------------
#                 Function to update the server with apt-get command
# --------------------------------------------------------------------------------------------------
run_apt_get()
{
    sadm_write "Starting $(sadm_get_osname) update process ...\n"
    
    CMD="DEBIAN_FRONTEND='noninteractive' apt -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' upgrade"
    sadm_writelog "Running: $CMD"
    DEBIAN_FRONTEND='noninteractive' apt -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' upgrade
    RC=$?
    if [ "$RC" -ne 0 ]
       then sadm_writelog "Return Code of \"apt -y upgrade\" is ${RC}."
            return $RC
       else sadm_writelog "[OK] \"apt -y upgrade\" done with success."
    fi

    CMD="DEBIAN_FRONTEND='noninteractive' apt -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' dist-upgrade"
    sadm_writelog "Running: $CMD"
    DEBIAN_FRONTEND='noninteractive' apt -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' dist-upgrade
    RC=$?
    if [ "$RC" -ne 0 ]
       then sadm_writelog "Return Code of \"apt -y dist-upgrade\" is ${RC}."
            return $RC
       else sadm_writelog "[OK] \"apt -y dist-upgrade\" ran with success."
    fi
    
    sadm_write "\nRemove orphaned packages, running 'apt autoremove'.\n"
    apt autoremove -y >>$SADM_LOG 2>&1
    RC=$?
    if [ "$RC" -ne 0 ]
        then sadm_write "Return Code of \"apt-get autoremove -y\" is ${RC}\n"
             return $RC
    fi
    
    # Verify a last time to see if any package are kept back from update.
    # - If the dependencies have changed on one of the packages you have installed so that a new 
    #   package must be installed to perform the upgrade then that will be listed as "kept-back".
    sadm_write "\nCheck if there are update that are kept back ...\n"
    NB_UPD=`apt list --upgradable 2>/dev/null | grep -v 'Listing...' | wc -l`
    if [ "$NB_UPD" -ne 0 ]
       then sadm_write "There are ${NB_UPD} update available.\n"
            apt list --upgradable 2>/dev/null | grep -v 'Listing...' | nl
            sadm_write "Advise SysAdmin - Send warning email that some update are kept back.\n"
            msub="SADM WARNING: Update are kept back on system $SADM_HOSTNAME" 
            body1=`date`
            body2=$(printf "\n\n${msub}\nThere are ${NB_UPD} update available\n\n")
            body3=`apt list --upgradable 2>/dev/null | grep -v 'Listing...' | nl` 
            body4=$(printf "\nSome dependencies may have changed on one of the packages you have installed, ")
            body5="or maybe some new package must be installed to perform the upgrade."
            body6="They are then listed as 'kept-back'."
            body7="run apt-get install <list of packages kept back>."
            mbody=`echo -e "${body1}\n${body2}\n${body3}\n${body4}\n${body5}\n${body6}\n\n${body7}\n\nHave a nice day."`
            #printf "%s" "$mbody" | $SADM_MUTT -s "$msub" "$SADM_MAIL_ADDR" >>$SADM_LOG 2>&1 
            sadm_sendmail "$SADM_MAIL_ADDR" "$msub" "$mbody" ""
    fi

    sadm_write "System Updated with Success.\n"
    return 0
}



# --------------------------------------------------------------------------------------------------
# Update $SADMIN/dat/dr/`hostname -s`_sysinfo.txt (Update the O/S Update date & Status)
# --------------------------------------------------------------------------------------------------
update_sysinfo_file()
{
    FINAL_CODE=$1                                                       # Exit code of O/S Update

    if [ $SADM_DEBUG -gt 0 ] 
        then sadm_write "Updating 'O/S Update' date & status in ${HWD_FILE}.\n"
    fi
    grep -vi "SADM_OSUPDATE_" $HWD_FILE > $SADM_TMP_FILE1               # Remove lines to update
    if [ "$SADM_EXIT_CODE" -eq 0 ]                                      # O/S Update was a success
        then echo "SADM_OSUPDATE_STATUS                  = S"  >> $SADM_TMP_FILE1   # Success
        else echo "SADM_OSUPDATE_STATUS                  = F"  >> $SADM_TMP_FILE1   # Failed
    fi
    TODAY=`date "+%Y.%m.%d %H:%M:%S"`                                   # Get Current Date/Time
    echo "SADM_OSUPDATE_DATE                    = $TODAY"  >> $SADM_TMP_FILE1 # Last OS Update Date
    rm -f  $HWD_FILE  >/dev/null 2>&1                                   # Remove sysinfo.txt file
    cp $SADM_TMP_FILE1 $HWD_FILE                                        # Replace with updated one
}



# --------------------------------------------------------------------------------------------------
# Function to perform the O/S Update for all Operating Systems.
# --------------------------------------------------------------------------------------------------
perform_osupdate()
{
    case "$(sadm_get_osname)" in                                        # Test OS Name
        "REDHAT"|"CENTOS"|"ALMALINUX"|"ROCKY" )
            case "$(sadm_get_osmajorversion)" in
                [2-4])  sadm_write "No more update for Redhat/CentOS v$(sadm_get_osmajorversion).\n"
                        sadm_write "This version have reach end of life.\n"
                        ;;
                [5-7])  run_yum                                         # V 5 and above use yum cmd
                        SADM_EXIT_CODE=$?                               # Save Return Code
                        ;;
                *)      run_dnf                                         # V 8 and up use dnf
                        SADM_EXIT_CODE=$?                               # Save Return Code
                        ;; 
            esac
            ;;

        "FEDORA" ) 
            run_dnf
            SADM_EXIT_CODE=$?
            ;;

        "SUSE"|"OPENSUSE" ) 
            sadm_write "$(sadm_get_osname) is not yet supported.\n"
            sadm_write "Please report it to SADMIN Web Site at this email : \n"
            sadm_write "support@sadmin.ca\n"
            ;;
            
        * ) 
            run_apt_get
            SADM_EXIT_CODE=$?
            ;;
    esac
    return $SADM_EXIT_CODE
}


# --------------------------------------------------------------------------------------------------
# Main Process 
# --------------------------------------------------------------------------------------------------
#
main_process()
{
    # Check for Automatic Update
    UPDATE_AVAILABLE="N"                                                # Assume No Upd. Available
    check_available_update                                              # Update Avail./apt-get upd
    RC=$?                                                               # 0=UpdAvail 1=NoUpd 2=Error
    case $RC in                     
        0)  UPDATE_AVAILABLE="Y"                                        # Set Upd to be done Flag ON
            perform_osupdate                                            # Go Perform O/S Update
            SADM_EXIT_CODE=$?                                           # Save exit code of update
            ;;
        1)  SADM_EXIT_CODE=0                                            # No Update Final Code to 0
            ;;
        2)  SADM_EXIT_CODE=1                                            # Error Encountered set to 1
            ;;
      100)  SADM_EXIT_CODE=1                                            # Problem with repo
            ;;
        *)  SADM_EXIT_CODE=1                                            # Error Encountered set to 1
            sadm_write "Check_available_update return code is invalid (${RC}).\n"
            ;;
    esac 

    # Update the Date & Status of update in Sysinfo File ($SADMIN/dat/dr/`hostname -s`_sysinfo.txt).
    update_sysinfo_file $SADM_EXIT_CODE                                 # Upd. Sysinfo Date & Status

    # If Reboot was requested and update were available and update was successful, then reboot.
    SADM_SRV_NAME=`echo $SADM_SERVER | awk -F\. '{ print $1 }'`         # Need a No FQDN of SADM Srv
    if [ "$WREBOOT" = "Y" ] && [ "$UPDATE_AVAILABLE" = "Y" ] && [ "$SADM_EXIT_CODE" -eq 0 ]     
        then sadm_write "Update successful, system will reboot in 1 Minute.\n"
             shutdown -r +1 "System will reboot in 1 minute."           # Issue Shutdown & Reboot
    fi

    return $SADM_EXIST_CODE
}




# --------------------------------------------------------------------------------------------------
# Command line Options functions
# Evaluate Command Line Switch Options Upfront
# By Default (-h) Show Help Usage, (-v) Show Script Version,(-d0-9] Set Debug Level 
# --------------------------------------------------------------------------------------------------
function cmd_options()
{
    while getopts "hrvd:" opt ; do                                      # Loop to process Switch
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
            r) WREBOOT="Y"                                              # Reboot after Upd. if allow
               SADM_SRV_NAME=`echo $SADM_SERVER | awk -F\. '{ print $1 }'` # SADMIN Hostname
               if [ "$HOSTNAME" = "$SADM_SRV_NAME" ]                    # We are on SADM Master Srv
                  then  printf "No Automatic reboot on the SADMIN Main server - $SADM_SERVER \n"
                        printf "Automatic reboot cancelled for this server.\n"
                        printf "You will need to reboot system at your chosen time.\n\n"
                        WREBOOT="N"                                     # No Auto Reboot on SADM Srv
                  else  printf "Reboot requested after successfull update.\n"  
               fi
               ;;
        esac                                                            # End of case
    done                                                                # End of while
    return 
}




# --------------------------------------------------------------------------------------------------
# S T A R T   O F   M A I N    P R O G R A M
# --------------------------------------------------------------------------------------------------
#
    cmd_options "$@"                                                    # Check command-line Options
    sadm_start                                                          # SADMIN Initialization
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if Init went wrong
    if ! [ $(id -u) -eq 0 ]                                             # If Cur. user is not root
        then sadm_write "Script can only be run by the 'root' user.\n"  # Advise User Message
             sadm_writelog "Try 'sudo ${0##*/}'."                       # Suggest using sudo
             sadm_write "Process aborted.\n"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S with Error
    fi
    main_process                                                        # Check/Perform O/S Update
    SADM_EXIT_CODE=$?                                                   # Save Status returned 
    if [ $SADM_EXIT_CODE -ne 0 ] ; then cat $SADM_ELOG ; fi
    sadm_stop "$SADM_EXIT_CODE"                                         # End Process with exit Code
    exit  "$SADM_EXIT_CODE"                                             # Exit script
