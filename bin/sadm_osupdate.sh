#!/bin/sh
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
# --------------------------------------------------------------------------------------------------
#set -x





#===================================================================================================
# Setup SADMIN Global Variables and Load SADMIN Shell Library
#
    # TEST IF SADMIN LIBRARY IS ACCESSIBLE
    if [ -z "$SADMIN" ]                                 # If SADMIN Environment Var. is not define
        then echo "Please set 'SADMIN' Environment Variable to install directory." 
             exit 1                                     # Exit to Shell with Error
    fi
    if [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]            # SADM Shell Library not readable
        then echo "SADMIN Library can't be located"     # Without it, it won't work 
             exit 1                                     # Exit to Shell with Error
    fi

    # CHANGE THESE VARIABLES TO YOUR NEEDS - They influence execution of SADMIN standard library.
    export SADM_VER='3.7'                               # Current Script Version
    export SADM_LOG_TYPE="B"                            # Output goes to [S]creen [L]ogFile [B]oth
    export SADM_LOG_APPEND="N"                          # Append Existing Log or Create New One
    export SADM_LOG_HEADER="Y"                          # Show/Generate Header in script log (.log)
    export SADM_LOG_FOOTER="Y"                          # Show/Generate Footer in script log (.log)
    export SADM_MULTIPLE_EXEC="N"                       # Allow running multiple copy at same time ?
    export SADM_USE_RCH="Y"                             # Generate entry in Return Code History .rch

    # DON'T CHANGE THESE VARIABLES - They are used to pass information to SADMIN Standard Library.
    export SADM_PN=${0##*/}                             # Current Script name
    export SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1`   # Current Script name, without the extension
    export SADM_TPID="$$"                               # Current Script PID
    export SADM_EXIT_CODE=0                             # Current Script Exit Return Code

    # Load SADMIN Standard Shell Library 
    . ${SADMIN}/lib/sadmlib_std.sh                      # Load SADMIN Shell Standard Library

    # Default Value for these Global variables are defined in $SADMIN/cfg/sadmin.cfg file.
    # But some can overriden here on a per script basis.
    export SADM_MAIL_TYPE=3                            # 0=NoMail 1=MailOnError 2=MailOnOK 3=Allways
    #export SADM_MAIL_ADDR="your_email@domain.com"      # Email to send log (To Override sadmin.cfg)
    #export SADM_MAX_LOGLINE=5000                       # When Script End Trim log file to 5000 Lines
    #export SADM_MAX_RCLINE=100                         # When Script End Trim rch file to 100 Lines
    #export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} " # SSH Command to Access Server 
#===================================================================================================




# --------------------------------------------------------------------------------------------------
#                               Script Variables definition
# --------------------------------------------------------------------------------------------------

# Command to issue the shutdown / Reboot after the update if requested
REBOOT_CMD="/sbin/shutdown -r now"          ; export REBOOT_CMD         # Reboot Command

# Default to no reboot after an update
WREBOOT="N"                                 ; export WREBOOT            # Def. NoReboot after update

#echo "Starting full system update..."
#echo "Checking sudo permissions..."
#sudo ls >/dev/null
#sudo apt update
#sudo apt dist-upgrade -yy
#sudo apt-get autoremove -yy
#sudo apt-get autoclean
#echo "--------------------"
#echo "- Update Complete! -"
#echo "--------------------"


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
    sadm_writelog "Success execution of apt-get upgrade & apt-get dist-upgrade"
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


    # If Parameter #1 received is "Y", then server will reboot after update (Default No Reboot)
    if [ $# -eq 1 ]                                                     # If one Param. Recv.
        then WREBOOT=`sadm_toupper $1`                                  # Make sure it is UpperCase
             if [ "$WREBOOT" = "Y" ]                                    # Unless Recv. Param #1=Y
                then sadm_writelog "Reboot requested after successfull update" 
                     WREBOOT="Y" 
                else sadm_writelog "Reboot isn't requested after update"
             fi
    fi

    # Check if Actual Server is the Main SADMIN server - No automatic Reboot for that server
    SADM_SRV_NAME=`echo $SADM_SERVER | awk -F\. '{ print $1 }'`         # Need a No FQDM of SADM Srv
    if [ "$HOSTNAME" = "$SADM_SRV_NAME" ]                               # We are on SADM Master Srv
        then sadm_writelog "Automatic reboot cancelled for this server"
             sadm_writelog "No Automatic reboot on the SADMIN Main server ($SADM_SERVER)"
             sadm_writelog "You will need to reboot system at your choosen time."
             sadm_writelog " "
             WREBOOT="N"
    fi


    UPDATE_AVAILABLE=0                                                  # Assume No Upd. Available
    check_available_update                                              # Check if Update is Avail.
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
                        sadm_writelog "webadmin@sadmin.ca"
                        ;;
            esac
       else if [ $RC -eq 1 ]                                            # If No Update Avail
                then SADM_EXIT_CODE=0                                   # No Update Final Code to 0
                else SADM_EXIT_CODE=1                                   # Error Encountered set to 1
            fi
    fi

    # If Reboot was requested and update was applied successfully, then reboot
    SADM_SRV_NAME=`echo $SADM_SERVER | awk -F\. '{ print $1 }'`         # Need a No FQDM of SADM Srv
    if [ "$WREBOOT" = "Y" ]                                             # If Reboot was requested
       then if [ $UPDATE_AVAILABLE -eq 0 ]                              # If Update was Applied
               then sadm_writelog "No reboot since no update was applied" 
               else if [ "$SADM_EXIT_CODE" -eq 0 ]                      # If Update was a success
                       then sadm_writelog "Update successfull, server will reboot in 1 Minute"
                            sadm_writelog "Running \"${REBOOT_CMD}\" in 1 Minute" 
                            echo "${REBOOT_CMD}" | at now + 1 Minute 
                       else sadm_writelog "Update failed, no reboot will be done"
                    fi
                    sadm_writelog "${SADM_DASH}"
            fi
    fi

    sadm_stop "$SADM_EXIT_CODE"                                         # End Process with exit Code
    exit  "$SADM_EXIT_CODE"                                             # Exit script
