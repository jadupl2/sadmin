#! /usr/bin/env bash
# --------------------------------------------------------------------------------------------------
#   Author   :  Jacques Duplessis
#   Title    :  sadm_prereq_install.sh
#   Synopsis : .
#   Version  :  1.1
#   Date     :  30 March 2017
#   Requires :  sh and SADM shell Library
#
#   Copyright (C) 2016 Jacques Duplessis <duplessis.jacques@gmail.com>
#
#   The SADMIN Tool is free software; you can redistribute it and/or modify it under the terms
#   of the GNU General Public License as published by the Free Software Foundation; either
#   version 2 of the License, or (at your option) any later version.

#   SADMIN Tools are distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
#   without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#   See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with this program.
#   If not, see <http://www.gnu.org/licenses/>.
# --------------------------------------------------------------------------------------------------
# Change Log
#   v1.6  Enhancements/Corrections Version Log 
# 2018_02_17 JDuplessis
#   v1.7  Update & Bug Fixes
# 2018_02_19 JDuplessis
#   v1.8  Update & Bug Fixes
# 
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPTE LE ^C
#set -x


#===================================================================================================
# If You want to use the SADMIN Libraries, you need to add this section at the top of your script
#   Please refer to the file $sadm_base_dir/lib/sadm_lib_std.txt for a description of each
#   variables and functions available to you when using the SADMIN functions Library
# --------------------------------------------------------------------------------------------------
# Global variables used by the SADMIN Libraries - Some influence the behavior of function in Library
# These variables need to be defined prior to load the SADMIN function Libraries
# --------------------------------------------------------------------------------------------------
SADM_PN=${0##*/}                           ; export SADM_PN             # Script name
SADM_HOSTNAME=`hostname -s`                ; export SADM_HOSTNAME       # Current Host name
SADM_VER='1.8'                             ; export SADM_VER            # Script Version
SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1` ; export SADM_INST           # Script name without ext.
SADM_TPID="$$"                             ; export SADM_TPID           # Script PID
SADM_EXIT_CODE=0                           ; export SADM_EXIT_CODE      # Script Exit Return Code
SADM_BASE_DIR=${SADMIN:="/sadmin"}         ; export SADM_BASE_DIR       # SADMIN Root Base Dir.
SADM_LOG_TYPE="L"                          ; export SADM_LOG_TYPE       # 4Logger S=Scr L=Log B=Both
SADM_LOG_APPEND="N"                        ; export SADM_LOG_APPEND     # Append to Existing Log ?
SADM_MULTIPLE_EXEC="N"                     ; export SADM_MULTIPLE_EXEC  # Run many copy at same time
[ -f ${SADM_BASE_DIR}/lib/sadmlib_std.sh ]    && . ${SADM_BASE_DIR}/lib/sadmlib_std.sh     

# These variables are defined in sadmin.cfg file - You can also change them on a per script basis 
SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT}" ; export SADM_SSH_CMD  # SSH Command to Access Farm
SADM_MAIL_TYPE=1                           ; export SADM_MAIL_TYPE      # 0=No 1=Err 2=Succes 3=All
#SADM_MAX_LOGLINE=5000                       ; export SADM_MAX_LOGLINE   # Max Nb. Lines in LOG )
#SADM_MAX_RCLINE=100                         ; export SADM_MAX_RCLINE    # Max Nb. Lines in RCH file
#SADM_MAIL_ADDR="your_email@domain.com"      ; export ADM_MAIL_ADDR      # Email Address of owner
#===================================================================================================
#



# --------------------------------------------------------------------------------------------------
#                               This Script environment variables
# --------------------------------------------------------------------------------------------------
DEBUG_LEVEL=0                               ; export DEBUG_LEVEL        # 0=NoDebug Higher=+Verbose




# --------------------------------------------------------------------------------------------------
#                H E L P       U S A G E    D I S P L A Y    F U N C T I O N 
# --------------------------------------------------------------------------------------------------
help()
{
    echo " "
    echo "sadm_prereq_install.sh usage : "
    echo "Will perform a dry run unless the '-y' is given" 
    echo "             -y Will perform installation needed"
    echo "             -h This help message"
    echo " "
}


# --------------------------------------------------------------------------------------------------
#       THIS FUNCTION IS USED TO INSTALL A MISSING PACKAGE THAT IS REQUIRED BY SADMIN TOOLS
#                       THE PACKAGE TO INSTALL IS RECEIVED AS A PARAMETER
# --------------------------------------------------------------------------------------------------
#
install_package() 
{
    # Check if we received at least 4 parameters
    if [ $# -ne 4 ]                                                     # Should have rcv 4 Param
        then printf "\nNb. Parameter received by $FUNCNAME function is incorrect"
             printf "\n    1st=DRYRUN ON/OFF       2nd=CommandName "
             printf "\n    3rd=RPM_PackageName     4th=DEB_PackageName"
             printf "\nPlease correct script - Script Aborted"          # Advise User to Correct
             sadm_stop 1                                                # Prepare exit gracefully
             exit 1                                                     # Terminate the script
    fi
    P_DRYRUN=`sadm_toupper $1`                                          # DRYRUN ON or OFF 
    P_COMMAND=$2                                                        # Command to Make Avail.
    P_PACKAGE_RPM=$3                                                    # RedHat/CentOS/Fedora Pkg
    P_PACKAGE_DEB=$4                                                    # Ubuntu/Debian/Raspian Deb
    printf "\nCurrent O/S is $(sadm_get_osname) - Version $(sadm_get_osmajorversion)"
    
    # Install the Package under RedHat/CentOS/Fedora
    if [ "$(sadm_get_osname)" = "REDHAT" ] || [ "$(sadm_get_osname)" = "CENTOS" ] || 
       [ "$(sadm_get_osname)" = "FEDORA" ]
        then if [ "$P_DRYRUN" = "OFF" ] 
                then printf "\nInstalling $P_COMMAND command included in package ${P_PACKAGE_RPM}"
                     yum -y --enablerepo=epel install ${P_PACKAGE_RPM} >>$SADM_LOG 2>&1 
                     ERROR_COUNT=$?                                              # Save Exit Code
                     printf "\nReturn Code after installing ${P_PACKAGE_RPM}: $ERROR_COUNT"
                else 
                     printf "\nWould run \"yum -y --enablerepo=epel install ${P_PACKAGE_RPM}\""
             fi
    fi
    
    # Install the Package under Debian/*Ubuntu/RaspberryPi 
    if [ "$(sadm_get_osname)" = "UBUNTU" ] || [ "$(sadm_get_osname)" = "RASPBIAN" ] ||
       [ "$(sadm_get_osname)" = "DEBIAN" ] || [ "$(sadm_get_osname)" = "LINUXMINT" ] 
        then if [ "$P_DRYRUN" = "OFF" ] 
                then printf "\nInstalling $P_COMMAND command included in package ${P_PACKAGE_DEB}"
                     printf "\nSynchronize package index files with their sources"
                     printf "\napt-get update"                                  # Msg Get package list 
                     apt-get update > /dev/null 2>&1                    # Get Package List From Repo
                     rc1=$?                                              # Save Exit Code
                     if [ "$rc1" -ne 0 ]
                        then printf "\nWe had problem running the \"apt-get update\" command" 
                             printf "\nWe had a return code $rc1" 
                     fi
                     printf "\nInstalling Package ${P_PACKAGE_DEB}"
                     printf "\napt-get -y install ${P_PACKAGE_DEB}"
                     apt-get -y install ${P_PACKAGE_DEB}
                     rc2=$?                                              # Save Exit Code
                     if [ "$rc2" -ne 0 ]
                        then printf "\nProblem running 'apt-get install update ${P_PACKAGE_DEB}'" 
                             printf "\nWe had a return code $rc2" 
                     fi
                     ERROR_COUNT=$(($rc1+$rc2))                         # Add Return Code Together
                     printf "\nReturn Code after installing ${P_PACKAGE_DEB}: $ERROR_COUNT" 
             fi
        else printf "\nWould Installing Package ${P_PACKAGE_DEB}"
             printf "\nWould run apt-get update"                                  # Msg Get package list 
             printf "\nWould run apt-get -y install ${P_PACKAGE_DEB}"
    fi         
    printf "\n "

    return $ERROR_COUNT                                                          # 0=Installed 1=Error
}

    
 # ----------------------------------------------------------------------------------------------
 # Make sure that cfg2html is accessible on the server
 # If package not installed then used the SADMIN version located in $SADMIN_BASE_DIR/pkg
 # ----------------------------------------------------------------------------------------------
 sadm_install_cfg2html()
 {
    printf "\nInstalling \"cfg2html\""
    printf "\nCurrent O/S is $(sadm_get_osname) - Version $(sadm_get_osmajorversion)"

    if [ "$(sadm_get_osname)" = "AIX" ]                         # If on AIX & Not Found
       then printf "\ncp $SADM_PKG_DIR/cfg2html/cfg2html /usr/bin/cfg2html"
            if [ "$P_DRYRUN" = "ON" ] ; then return 0 ; fi
            cp $SADM_PKG_DIR/cfg2html/cfg2html /usr/bin/cfg2html 
            return $?
    fi

    if [ "$(sadm_get_osname)" = "REDHAT" ] || [ "$(sadm_get_osname)" = "CENTOS" ] || 
       [ "$(sadm_get_osname)" = "FEDORA" ]                    
       then printf "\nrpm -Uvh ${SADM_PKG_DIR}/cfg2html/cfg2html.rpm"
            if [ "$P_DRYRUN" = "ON" ] ; then return 0 ; fi
            rpm -Uvh ${SADM_PKG_DIR}/cfg2html/cfg2html.rpm
            return $?
    fi

    if [ "$(sadm_get_osname)" = "UBUNTU" ]   || [ "$(sadm_get_osname)" = "DEBIAN" ] || 
       [ "$(sadm_get_osname)" = "RASPBIAN" ] || [ "$(sadm_get_osname)" = "LINUXMINT" ]                   
       then printf "\ndpkg --install --force-confold ${SADM_PKG_DIR}/cfg2html/cfg2html.deb"
            if [ "$P_DRYRUN" = "ON" ] ; then return 0 ; fi
            dpkg --install --force-confold ${SADM_PKG_DIR}/cfg2html/cfg2html.deb
            return $?
    fi
    return 0
}



# --------------------------------------------------------------------------------------------------
#                      S c r i p t    M a i n     P r o c e s s 
# --------------------------------------------------------------------------------------------------
main_process()
{
    if [ "$DRYRUN" = "ON" ] ;then printf "\nRUNNING IN DRYRUN MODE - NOTHING WILL BE INSTALL\n" ;fi

    # Check if command which is installed - If not install it if not running in dryrun mode
    SCMD="which"
    printf "\nChecking availability of command $SCMD" 
    if which $SCMD >/dev/null 2>&1                                      # Try the command which 
       then printf "\nCommand \"${SCMD}\" is available [OK]" 
       else install_package "$DRYRUN" "$SCMD" "which" "debianutils"     # Install related RPMorDEB 
    fi 
    printf "\n "            

    # Check if command nmon is installed - If not install it if not running in dryrun mode
    SCMD="nmon"
    printf "\nChecking availability of command $SCMD" 
    if which $SCMD >/dev/null 2>&1                                    # Try the command which 
       then printf "\nCommand \"${SCMD}\" is available [OK]" 
       else install_package "$DRYRUN" "$SCMD" "nmon" "nmon" # Install related RPMorDEB 
    fi            
    printf "\n " 

    # Check if command mail is installed - If not install it if not running in dryrun mode
    SCMD="mail"
    printf "\nChecking availability of command $SCMD" 
    if which $SCMD >/dev/null 2>&1                                      # Test if command is avail.
       then printf "\nCommand \"${SCMD}\" is available [OK]" 
       else install_package "$DRYRUN" "$SCMD" "mailx" "mailutils"       # Install related RPMorDEB 
    fi            
    printf "\n " 

    # Check if command ethtool is installed - If not install it if not running in dryrun mode
    SCMD="ethtool"
    printf "\nChecking availability of command $SCMD" 
    if which $SCMD >/dev/null 2>&1                                      # Test if command is avail. 
       then printf "\nCommand \"${SCMD}\" is available [OK]" 
       else install_package "$DRYRUN" "$SCMD" "ethtool" "ethtool"       # Install related RPMorDEB 
    fi            
    printf "\n " 

    # Check if command lscpu is installed - If not install it if not running in dryrun mode
    SCMD="lsb_release"
    printf "\nChecking availability of command $SCMD" 
    if which $SCMD >/dev/null 2>&1                                      # Test if command is avail. 
       then printf "\nCommand \"${SCMD}\" is available [OK]" 
       else install_package "$DRYRUN" "$SCMD" "redhat-lsb-core" "lsb_release"  # Install related RPMorDEB 
    fi            
    printf "\n "
    
    # Check if command lscpu is installed - If not install it if not running in dryrun mode
    SCMD="dmidecode"
    printf "\nChecking availability of command $SCMD" 
    if which $SCMD >/dev/null 2>&1                                      # Test if command is avail. 
       then printf "\nCommand \"${SCMD}\" is available [OK]" 
       else install_package "$DRYRUN" "$SCMD" "dmidecode" "dmidecode"   # Install related RPMorDEB 
    fi            
    printf "\n "
    
    # Check if command lscpu is installed - If not install it if not running in dryrun mode
    SCMD="fdisk"
    printf "\nChecking availability of command $SCMD" 
    if which $SCMD >/dev/null 2>&1                                      # Test if command is avail. 
       then printf "\nCommand \"${SCMD}\" is available [OK]" 
       else install_package "$DRYRUN" "$SCMD" "util-linux" "util-linux" # Install related RPMorDEB 
    fi            
    printf "\n "
    
    # Check if command lscpu is installed - If not install it if not running in dryrun mode
    SCMD="lscpu"
    printf "\nChecking availability of command $SCMD" 
    if which $SCMD >/dev/null 2>&1                                      # Test if command is avail. 
       then printf "\nCommand \"${SCMD}\" is available [OK]" 
       else install_package "$DRYRUN" "$SCMD" "util-linux" "util-linux" # Install related RPMorDEB 
    fi            
    printf "\n " 

    # Check if command parted is installed - If not install it if not running in dryrun mode
    SCMD="bc"
    printf "\nChecking availability of command $SCMD" 
    if which $SCMD >/dev/null 2>&1                                      # Test if command is avail. 
       then printf "\nCommand \"${SCMD}\" is available [OK]" 
       else install_package "$DRYRUN" "$SCMD" "bc" "bc"                 # Install related RPMorDEB 
    fi            
    printf "\n " 
  
    # Check if command parted is installed - If not install it if not running in dryrun mode
    SCMD="parted"
    printf "\nChecking availability of command $SCMD" 
    if which $SCMD >/dev/null 2>&1                                      # Test if command is avail. 
       then printf "\nCommand \"${SCMD}\" is available [OK]" 
       else install_package "$DRYRUN" "$SCMD" "parted" "parted"         # Install related RPMorDEB 
    fi            
    printf "\n " 
  
    # Check if command cfg2html is installed - If not install it if not running in dryrun mode
    SCMD="cfg2html"
    printf "\nChecking availability of command $SCMD" 
    if which $SCMD >/dev/null 2>&1                                      # Test if command is avail. 
       then printf "\nCommand \"${SCMD}\" is available [OK]" 
       else sadm_install_cfg2html                                       # Install related RPMorDEB 
    fi            
    printf "\n " 

    # Test if perl module DateTime is installed - If not install it
    SCMD="DateTime"
    printf "\nChecking availability of Perl Module '${SCMD}'"
    perl -e 'use DateTime' >/dev/null 2>&1                              # Test if command is avail.
    if [ $? -eq 0 ] 
       then printf "\nPerl Module '${SCMD}' is available [OK]" 
       else install_package "$DRYRUN" "$SCMD" "perl-DateTime" "libdatetime-perl libwww-perl"
    fi
    printf "\n "
  
    
    return 0                                                            # Return Default return code
}

  

# --------------------------------------------------------------------------------------------------
#         Make sure the sadmin group and sadmin user are created - If not created them
# --------------------------------------------------------------------------------------------------
check_groups_and_users()
{
    # Check if 'sadmin' group exist - If not create it.
    printf "\nChecking if ${SADM_GROUP} group is created"
    grep "^${SADM_GROUP}:"  /etc/group >/dev/null 2>&1                  # $SADMIN Group Defined ?
    if [ $? -ne 0 ]                                                     # SADM_GROUP not Defined
        then printf "\nGroup ${SADM_GROUP} not present"                 # Advise user will create
             if [ "$DRYRUN" = "OFF" ]
                then groupadd ${SADM_GROUP}                             # Create SADM_GROUP
                     if [ $? -ne 0 ]                                    # Error creating Group 
                        then printf "\nError when creating group ${SADM_GROUP}"
                             printf "\nProcess Aborted"                 # Abort got be created
                             sadm_stop 1                                # Terminate Gracefully
                        else printf "\nGroup ${SADM_GROUP} Created"     # Advise user will create
                     fi
             fi
        else printf "\nGroup ${SADM_GROUP} already Created [OK]"        # Advise user will create 
    fi
    printf "\n "

    # Check is 'sadmin' user exist user - if not create it and make it part of 'sadmin' group.
    printf "\nChecking if ${SADM_USER} user is created"
    grep "^${SADM_USER}:" /etc/passwd >/dev/null 2>&1                   # $SADMIN User Defined ?
    if [ $? -ne 0 ]                                                     # NO Not There
        then printf "\nUser $SADM_USER not present"                     # Advise user will create
             if [ "$DRYRUN" = "OFF" ]
                then useradd -d '/sadmin' -c 'SADMIN user' -g $SADM_GROUP -e '' $SADM_USER
                     if [ $? -ne 0 ]                                    # Error creating user 
                         then printf "\nError when creating user ${SADM_USER}"
                              printf "\nProcess Aborted"                # Abort got be created
                              sadm_stop 1                               # Terminate Gracefully
                         else printf "\nUser ${SADM_USER} is created"   # Advise user created
                     fi
             fi
        else printf "\nUser ${SADM_USER} already Created [OK]"          # Advise user will create 
    fi
    printf "\n "
    return 0
}


# --------------------------------------------------------------------------------------------------
#                                Script Start HERE
# --------------------------------------------------------------------------------------------------
    SADM_LOG_TYPE="L"                                                   # Log to file Only,no screen
    sadm_start                                                          # Init Env Dir & RC/Log File
    if ! $(sadm_is_root)                                                # Is it root running script?
        then printf "\nScript can only be run by the 'root' user"       # Advise User Message
             printf "\nProcess aborted"                                 # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi

    printf "\nSADMIN Requirements Verification - v${SADM_VER}\n"    
    printf "============================================"
    # Optional Command line switches    
    DRYRUN="ON" ;                                                       # Set Switch Default Value
    while getopts "y" opt ; do                                          # Loop to process Switch
        case $opt in
            y) DRYRUN="OFF"                                             # Display Continiously    
               ;;                                                       # No stop after each page
            h) help                                                     # Display Help Usage
               sadm_stop 0                                              # Close the shop
               exit 0                                                   # Back to shell 
               ;;
           \?) echo "Invalid option: -$OPTARG" >&2                      # Invalid Option Message
               help                                                     # Display Help Usage
               exit 1                                                   # Exit with Error
               ;;
        esac                                                            # End of case
    done  
    check_groups_and_users                                              # Check sadmin User & Group
    main_process                                                        # Main Process
    SADM_EXIT_CODE=$?                                                   # Save Process Exit Code
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log 
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
