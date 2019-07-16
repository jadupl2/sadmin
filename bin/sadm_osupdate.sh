#! /usr/bin/env bash
# --------------------------------------------------------------------------------------------------
#   Author:     Jacques Duplessis
#   Title:      sadm_osupdate.sh _ Linux O/S Update script
#   Synopsis:   This script is used to update the Linux OS Platform
#               Support Redhat/Centos v3,4,5,6,7 - Ubuntu - Debian V7,8 - Raspbian V7,8 - Fedora
#   Update  :   March 2015 -  J.Duplessis
#
# --------------------------------------------------------------------------------------------------
# 2016_11_06    V2.6 Insert Logic to Reboot the server after a successfull update
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
# 2017_07_08    v3.2 Now using DNF instead of yum for updating Fedora 25 and beyong.
# 2017_12_10    v3.4 No longer Support Redhat/CentOS 3 and 4
# 2018_06_05    v3.5 Adapt to new SADMIN Libr.
# 2018_06_09    v3.6 Change name of this script from sadm_osupdate_client to sadm_client_osupdate
# 2018_06_10    v3.7 Switch back to old name 
# 2018_07_11    v3.8 Code cleanup
# 2018_09_19    v3.9 Include Alert Group 
# 2018_10_24    v3.10 Command line option -d -r -h -v added.
# 2019_01_16 Improvement: v3.11 Add 'apt-get autoremove' when 'deb' package is use.
# 2019_05_23  Update: v3.12 Updated to use SADM_DEBUG instead of Local Variable DEBUG_LEVEL
#@2019_07_12  Update: v3.13 O/S update script now update the date and status in sysinfo.txt. 
#
# --------------------------------------------------------------------------------------------------
#set -x





#===================================================================================================
#===================================================================================================
# SADMIN Section - Setup SADMIN Global Variables and Load SADMIN Shell Library
# To use the SADMIN tools and libraries, this section MUST be present near the top of your code.
#===================================================================================================

    # Make sure the 'SADMIN' environment variable defined and pointing to the install directory.
    if [ -z $SADMIN ] || [ "$SADMIN" = "" ]
        then # Check if the file /etc/environment exist, if not exit.
             missetc="Missing /etc/environment file, create it and add 'SADMIN=/InstallDir' line." 
             if [ ! -e /etc/environment ] ; then printf "${missetc}\n" ; exit 1 ; fi
             # Check if can use SADMIN definition line in /etc/environment to continue
             missenv="Please set 'SADMIN' environment variable to the install directory."
             grep "^SADMIN" /etc/environment >/dev/null 2>&1             # SADMIN line in /etc/env.? 
             if [ $? -eq 0 ]                                             # Yes use SADMIN definition
                 then export SADMIN=`grep "^SADMIN" /etc/environment | awk -F\= '{ print $2 }'` 
                      misstmp="Temporarily setting 'SADMIN' environment variable to '${SADMIN}'."
                      missvar="Add 'SADMIN=${SADMIN}' in /etc/environment to suppress this message."
                      if [ ! -e /bin/launchctl ] ; then printf "${missvar}" ; fi 
                      printf "\n${missenv}\n${misstmp}\n\n"
                 else missvar="Add 'SADMIN=/InstallDir' in /etc/environment to remove this message."
                      printf "\n${missenv}\n$missvar\n"                  # Advise user what to do   
                      exit 1                                             # Back to shell with Error
             fi
    fi 
        
    # Check if SADMIN environment variable is properly defined, check if can locate Shell Library.
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

    # USE AND CHANGE VARIABLES BELOW TO YOUR NEEDS (They influence execution of standard library.)
    export SADM_VER='3.13'                              # Your Current Script Version
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

    . ${SADMIN}/lib/sadmlib_std.sh                      # Ok now, load Standard Shell Library
    export SADM_OS_NAME=$(sadm_get_osname)              # Uppercase, REDHAT,CENTOS,UBUNTU,AIX,DEBIAN
    export SADM_OS_VERSION=$(sadm_get_osversion)        # O/S Full Version Number (ex: 7.6.5)
    export SADM_OS_MAJORVER=$(sadm_get_osmajorversion)  # O/S Major Version Number (ex: 7)

#---------------------------------------------------------------------------------------------------
# Values of these variables are taken from SADMIN config file ($SADMIN/cfg/sadmin.cfg file).
# They can be overridden here on a per script basis.
    #export SADM_ALERT_TYPE=1                           # 0=None 1=AlertOnErr 2=AlertOnOK 3=Always
    #export SADM_ALERT_GROUP="default"                  # Alert Group to advise (alert_group.cfg)
    #export SADM_MAIL_ADDR="your_email@domain.com"      # Email to send log (To override sadmin.cfg)
    #export SADM_MAX_LOGLINE=500                        # When script end Trim log to 500 Lines
    #export SADM_MAX_RCLINE=60                          # When script end Trim rch file to 60 Lines
    #export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} " # SSH Command to Access Server 
#===================================================================================================
#===================================================================================================




# --------------------------------------------------------------------------------------------------
#                                   Script Variables definition
# --------------------------------------------------------------------------------------------------

# Command to issue the shutdown / Reboot after the update if requested
REBOOT_CMD="/sbin/shutdown -r now"          ; export REBOOT_CMD         # Reboot Command

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
    printf "\n${SADM_PN} usage :"
    printf "\n\t-d   (Debug Level [0-9])"
    printf "\n\t-h   (Display this help message)"
    printf "\n\t-r   (Reboot server after update, if needed and if allowed in Database)"
    printf "\n\t-n   (Backup with NO compression)"
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



#===================================================================================================
#                  Run the script received if parameter (Return 0=Success 1= Error)
#===================================================================================================
run_command()
{
    SCRIPT=$1                                                           # Shell Script Name to Run
    CMDLINE="$*"                                                        # Command with All Parameter
    SCMD="${SADM_BIN_DIR}/${CMDLINE}"                                   # Full Path of the script

    if [ ! -x "${SADM_BIN_DIR}/${SCRIPT}" ]                               # If SCript do not exist
        then sadm_writelog "[ERROR] ${SADM_BIN_DIR}/${SCRIPT} Don't exist or can't execute" 
             sadm_writelog " " 
             return 1                                                   # Return Error to Caller
    fi 

    sadm_writelog "Running $SCMD ..."                                   # Show Command about to run
    $SCMD >/dev/null 2>&1                                               # Run the Script
    if [ $? -ne 0 ]                                                     # If Error was encounter
        then sadm_writelog "[ERROR] $SCRIPT Terminate with Error"       # Signal Error in Log
             sadm_writelog "Check Log for further detail about Error"   # Show user where to look
             sadm_writelog "${SADM_LOG_DIR}/${SADM_HOSTNAME}_${SCRIPT}.log" # Show Log Name    
             sadm_writelog " " 
             return 1                                                   # Return Error to Caller
        else sadm_writelog "[SUCCESS] Script $SCRIPT terminated"        # Advise user it's OK
             sadm_writelog " " 
    fi
    return 0                                                            # Return Success to Caller
}




# --------------------------------------------------------------------------------------------------
#                      Function to check update available before beginning update
# Function Return
# - 0 IF UPDATE ARE AVAILABLE
# - 1 IF NO UPDATE ARE AVAILABLE
# - 2 IF PROBLEM CHECKING FOR UPDATE
# --------------------------------------------------------------------------------------------------
check_available_update()
{
    sadm_writelog "Verifying Update Availibility for $(sadm_get_osname) $(sadm_get_osmajorversion)"
    
    case "$(sadm_get_osname)" in

        "REDHAT"|"CENTOS" ) 
            case "$(sadm_get_osmajorversion)" in
                [3-4])  UpdateStatus=1                                      # No Update available
                        ;;
                [5-7])  sadm_writelog "Running \"yum check-update\""        # Update the log
                        yum check-update >> $SADM_LOG 2>&1                  # List Available update
                        rc=$?                                               # Save Exit Code
                        sadm_writelog "Return Code is $rc"                  # Exit code to log
                        case $rc in
                            100) UpdateStatus=0                             # Update Exist
                                 sadm_writelog "Update are available"       # Update the log
                                 ;;
                              0) UpdateStatus=1                             # No Update available
                                 sadm_writelog "No Update available"
                                 ;;
                              *) UpdateStatus=2                             # Problem Abort Update
                                 sadm_writelog "Error Encountered - Update aborted"  # Update the log
                                 sadm_writelog "For more information check the log $SADM_LOG"
                                 ;;
                        esac
                        ;;
            esac
            ;;
            
        "FEDORA" )
            case "$(sadm_get_osmajorversion)" in
                [1-24]) sadm_writelog "Running \"yum check-update\""        # Update the log
                        yum check-update >> $SADM_LOG 2>&1                  # List Available update
                        rc=$?                                               # Save Exit Code
                        sadm_writelog "Return Code is $rc"                  # Exit code to log
                        case $rc in
                            100) UpdateStatus=0                             # Update Exist
                                 sadm_writelog "Update are available"       # Update the log
                                 ;;
                              0) UpdateStatus=1                             # No Update available
                                 sadm_writelog "No Update available"
                                 ;;
                              *) UpdateStatus=2                             # Problem Abort Update
                                 sadm_writelog "Error Encountered - Update aborted"  # Update the log
                                 sadm_writelog "For more information check the log $SADM_LOG"
                                 ;;
                        esac
                        ;; 
               [24-99]) sadm_writelog "Running \"dnf check-update\""        # Update the log
                        dnf check-update >> $SADM_LOG 2>&1                  # List Available update
                        rc=$?                                               # Save Exit Code
                        sadm_writelog "Return Code after \"yum check-update\" is $rc" # Exit code to log
                        case $rc in
                            100) UpdateStatus=0                             # Update Exist
                                 sadm_writelog "Update are available"       # Update the log
                                 ;;
                              0) UpdateStatus=1                             # No Update available
                                 sadm_writelog "No Update available"
                                 ;;
                              *) UpdateStatus=2                             # Problem Abort Update
                                 sadm_writelog "Error Encountered - Update aborted"  # Update the log
                                 sadm_writelog "For more information check the log $SADM_LOG"
                                 ;;
                        esac
                        ;;
            esac
            ;;
    
    
        "UBUNTU"|"DEBIAN"|"RASPBIAN"|"LINUXMINT" ) 
            sadm_writelog "Resynchronize index files with Internet Sources"
            sadm_writelog "Running \"apt-get update\""                 # Msg Get package list 
            apt-get update  >> $SADM_LOG 2>&1                          # Get Package List From Repo
            rc=$?                                                      # Save Exit Code
            if [ "$rc" -ne 0 ]
               then UpdateStatus=2
                    sadm_writelog "We had problem running the \"apt-get update\" command" 
                    sadm_writelog "We had a return code of $rc" 
                    sadm_writelog "For more information check the log $SADM_LOG"
               else sadm_writelog "Return Code of apt-get update is $rc" # Show  Return Code
                    sadm_writelog "Querying list of package that will be updated"
                    NB_UPD=`apt-get -s dist-upgrade |awk '/^Inst/ { print $2 }' |wc -l |tr -d ' '`
                    apt-get -s dist-upgrade |awk '/^Inst/ { print $2 }'
                    if [ "$NB_UPD" -ne 0 ]
                       then UpdateStatus=0
                            sadm_writelog "${NB_UPD} Updates are available"
                       else UpdateStatus=1
                            sadm_writelog "No Update available"
                    fi
            fi
            ;;
    esac 
    
    sadm_writelog " "
    return $UpdateStatus                                                # 0=UpdExist 1=NoUpd 2=Abort

}




# --------------------------------------------------------------------------------------------------
#             Function to update the server with up2date command (RHEL3 and RHEL4)
# --------------------------------------------------------------------------------------------------
run_up2date()
{
    sadm_writelog "${SADM_TEN_DASH}"
    sadm_writelog "Starting the $(sadm_get_osname) update  process ..."
    sadm_writelog "Running \"up2date --nox -u\""
    up2date --nox -u >>$SADM_LOG 2>&1
    rc=$?
    sadm_writelog "Return Code is $rc"
    if [ $rc -ne 0 ]
       then sadm_writelog "Problem getting list of the update"
            sadm_writelog "Update not performed - Processing aborted"
       else sadm_writelog "Update Succeeded - Return Code is 0"
    fi
    sadm_writelog "${SADM_TEN_DASH}"
    return $rc

}

# --------------------------------------------------------------------------------------------------
#                 Function to update the server with yum command
# --------------------------------------------------------------------------------------------------
run_yum()
{
    sadm_writelog "${SADM_TEN_DASH}"
    sadm_writelog "Starting $(sadm_get_osname) update process ..."
    sadm_writelog "Running : yum -y update"
    yum -y update  >>$SADM_LOG 2>&1
    rc=$?
    sadm_writelog "Return Code after yum program update is $rc"
    sadm_writelog "${SADM_TEN_DASH}"
    return $rc
}


# --------------------------------------------------------------------------------------------------
#                 Function to update the server with dnf command
# --------------------------------------------------------------------------------------------------
run_dnf()
{
    sadm_writelog "${SADM_TEN_DASH}"
    sadm_writelog "Starting $(sadm_get_osname) update process ..."
    sadm_writelog "Running : dnf -y update"
    dnf -y update  >>$SADM_LOG 2>&1
    rc=$?
    sadm_writelog "Return Code after dnf program update is $rc"
    sadm_writelog "${SADM_TEN_DASH}"
    return $rc
}


# --------------------------------------------------------------------------------------------------
#                 Function to update the server with apt-get command
# --------------------------------------------------------------------------------------------------
run_apt_get()
{
    sadm_writelog "${SADM_TEN_DASH}"
    sadm_writelog "Starting $(sadm_get_osname) update process ..."
    
    sadm_writelog "${SADM_TEN_DASH}"
        sadm_writelog "Running : apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' upgrade"
    apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade >>$SADM_LOG 2>&1
    RC=$?
    if [ "$RC" -ne 0 ]
       then sadm_writelog "Return Code of \"apt-get -y upgrade\" is $RC"
            return $RC
    fi
    
    sadm_writelog "${SADM_TEN_DASH}"
    sadm_writelog "Running : apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' dist-upgrade"
    apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade >>$SADM_LOG 2>&1
    RC=$?
    if [ "$RC" -ne 0 ]
        then sadm_writelog "Return Code of \"apt-get -y dist-upgrade\" is $RC"
             return $RC
    fi
    
    sadm_writelog "${SADM_TEN_DASH}"
    sadm_writelog "Running : apt-get autoremove"
    apt-get autoremove -y >>$SADM_LOG 2>&1
    RC=$?
    if [ "$RC" -ne 0 ]
        then sadm_writelog "Return Code of \"apt-get autoremove -y\" is $RC"
             return $RC
    fi
    
    sadm_writelog "${SADM_TEN_DASH}"
    sadm_writelog "Success execution of apt-get upgrade & apt-get dist-upgrade & apt-get autoremove"
    return 0
}




# --------------------------------------------------------------------------------------------------
#                           S T A R T   O F   M A I N    P R O G R A M
# --------------------------------------------------------------------------------------------------
#
    sadm_start                                                          # Make sure Dir. Struc. exist
    if ! [ $(id -u) -eq 0 ]                                             # If Cur. user is not root 
        then sadm_writelog "This script must be run by the ROOT user"   # Advise User Message
             sadm_writelog "Process aborted"                            # Abort Process message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi

    # Switch for Help Usage (-h) or Activate Debug Level (-d[1-9])
    WREBOOT="N"                                                         # No Reboot by Default
    while getopts "hvnrd:" opt ; do                                      # Loop to process Switch
        case $opt in
            d) SADM_DEBUG=$OPTARG                                      # Get Debug Level Specified
               ;;                                                       # No stop after each page
            r) WREBOOT="Y"                                              # Reboot after Upd. if allow
               sadm_writelog "Reboot requested after successfull update"                
               ;;
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
    if [ $SADM_DEBUG -gt 0 ]                                           # If Debug is Activated
        then printf "\nDebug activated, Level ${SADM_DEBUG}"           # Display Debug Level
             printf "\nBackup compression is $COMPRESS"                 # Show Status of compression
    fi

    # Check if Actual Server is the Main SADMIN server - No automatic Reboot for that server
    SADM_SRV_NAME=`echo $SADM_SERVER | awk -F\. '{ print $1 }'`         # Need a No FQDM of SADM Srv
    if [ "$HOSTNAME" = "$SADM_SRV_NAME" ]                               # We are on SADM Master Srv
        then sadm_writelog "No Automatic reboot on the SADMIN Main server ($SADM_SERVER)"
             sadm_writelog "Automatic reboot cancelled for this server"
             sadm_writelog "You will need to reboot system at your choosen time."
             sadm_writelog " "
             WREBOOT="N"
    fi


    UPDATE_AVAILABLE=0                                                  # Assume No Upd. Available
    check_available_update                                              # Update Avail./apt-get upd
    RC=$?                                                               # 0=UpdAvail 1=NoUpd 2=Error
    if [ "$RC" -eq 0 ]                                                  # If Update are Available
       then UPDATE_AVAILABLE=1                                          # Set Upd to be done Flag ON
            case "$(sadm_get_osname)" in                                # Test OS Name
                "REDHAT"|"CENTOS" )
                        if [ $(sadm_get_osmajorversion) -lt 8 ]
                            then    run_yum                             # V 5 and above use yum cmd
                                    SADM_EXIT_CODE=$?                   # Save Return Code
                            else    run_dnf                             # V 8 and up use dnf
                                    SADM_EXIT_CODE=$?                   # Save Return Code
                        fi
                        ;; 
                                
                "FEDORA" ) 
                        run_dnf
                        SADM_EXIT_CODE=$?
                        ;;

                "UBUNTU"|"DEBIAN"|"RASPBIAN"|"LINUXMINT" )
                        run_apt_get
                        SADM_EXIT_CODE=$?
                        ;;

                *)
                        sadm_writelog "This OS ($(sadm_get_osname)) is not yet supported"
                        sadm_writelog "Please report it to SADMIN Web Site at this email :"
                        sadm_writelog "support@sadmin.ca"
                        ;;
            esac
       else if [ $RC -eq 1 ]                                            # If No Update Avail
                then SADM_EXIT_CODE=0                                   # No Update Final Code to 0
                else SADM_EXIT_CODE=1                                   # Error Encountered set to 1
            fi
    fi

    ### Update $SADMIN/dat/dr/`hostname -s`_sysinfo.txt (Update the O/S Update date & Status)
    sadm_writelog "Updating last 'O/S Update' date and status in $HWD_FILE"
    grep -vi "SADM_OSUPDATE_" $HWD_FILE > $SADM_TMP_FILE1               # Remove lines to update
    if [ "$SADM_EXIT_CODE" -eq 0 ]                                      # O/S Update was a success
        then echo "SADM_OSUPDATE_STATUS                  = S"  >> $SADM_TMP_FILE1   # Success
        else echo "SADM_OSUPDATE_STATUS                  = F"  >> $SADM_TMP_FILE1   # Failed
    fi
    TODAY=`date "+%Y.%m.%d %H:%M:%S"`                                   # Get Current Date/Time
    echo "SADM_OSUPDATE_DATE                    = $TODAY"  >> $SADM_TMP_FILE1 # Last OS Update Date
    rm -f  $HWD_FILE                                                    # Remove sysinfo.txt file
    cp $SADM_TMP_FILE1 $HWD_FILE                                        # Replace with updated one


    # If Reboot was requested and update was applied successfully, then reboot
    SADM_SRV_NAME=`echo $SADM_SERVER | awk -F\. '{ print $1 }'`         # Need a No FQDN of SADM Srv
    if [ "$WREBOOT" = "Y" ]                                             # If Reboot was requested
       then if [ $UPDATE_AVAILABLE -eq 0 ]                              # If Update was Applied
               then sadm_writelog "No reboot since no update was applied" 
               else if [ "$SADM_EXIT_CODE" -eq 0 ]                      # If Update was a success
                       then sadm_writelog "Update successful, server will reboot in 1 Minute"
                            sadm_writelog "Running \"${REBOOT_CMD}\" in 1 Minute" 
                            echo "${REBOOT_CMD}" | at now + 1 Minute 
                       else sadm_writelog "Update failed, no reboot will be done"
                    fi
                    sadm_writelog "${SADM_DASH}"
            fi
    fi

    sadm_stop "$SADM_EXIT_CODE"                                         # End Process with exit Code
    exit  "$SADM_EXIT_CODE"                                             # Exit script
