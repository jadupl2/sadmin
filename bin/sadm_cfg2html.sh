#! /usr/bin/env bash
#===================================================================================================
#   Author   :  Jacques Duplessis
#   Title    :  sadm_create_cfg2html.sh1
#   Synopsis :  Run the cfg2html tool & record files .
#   Version  :  1.0
#   Date     :  14 August 2013
#   Requires :  sh
#   SCCS-Id. :  @(#) create_cfg2html.sh 2.0 2013/08/14
#===================================================================================================
# 2.2 Correction in end_process function (Sept 2016)
# 2.3 When running from SADMIN server the rename of output file wasn't working (Nov 2016)
# 2.4 Install cfg2html from local copy is not present (Jan 2017)
# 2.5 Added support for LinuxMint (April 2017)
# 2018_01_03    v2.8 Add message to user stating that script is not supported on MacOS
# 2018_05_01    v2.9 On Fedora 27 and Up - cfg2html hang - So in will not run when Fedora 27 and Up
# 2018_06_03    v3.0 Adapt to new Shell Library, small corrections
# 2018_06_11    v3.1 Change Name to sadm_cfg2html.sh
# 2018_09_16    v3.2 Added Alert Group Script default
# 2018_09_16    v3.3 Added prefix 'cfg2html_' to files produced by cfg2html in $SADMIN/dat/dr.
# 2018_11_13    v3.4 Chown & Chmod of cfh2html produced files.
#@2019_03_18 Fix: v3.5 Fix problem that prevent running on Fedora.
#@2020_04_01 Update: v3.6 Replace function sadm_writelog() with N/L incl. by sadm_write() No N/L Incl.
#===================================================================================================
#
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPTE LE ^C
#set -x



#===================================================================================================
# To use the SADMIN tools and libraries, this section MUST be present near the top of your code.
# SADMIN Section - Setup SADMIN Global Variables and Load SADMIN Shell Library
#===================================================================================================

    # MAKE SURE THE ENVIRONMENT 'SADMIN' IS DEFINED, IF NOT EXIT SCRIPT WITH ERROR.
    if [ -z $SADMIN ] || [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]          # If SADMIN EnvVar not right
        then printf "\nPlease set 'SADMIN' environment variable to the install directory."
             EE="/etc/environment" ; grep "SADMIN=" $EE >/dev/null      # SADMIN in /etc/environment
             if [ $? -eq 0 ]                                            # Yes it is 
                then export SADMIN=`grep "SADMIN=" $EE |sed 's/export //g'|awk -F= '{print $2}'`
                     printf "\n'SADMIN' Environment variable was temporarily set to ${SADMIN}."
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
    export SADM_VER='3.6'                               # Your Current Script Version
    export SADM_LOG_TYPE="B"                            # Writelog goes to [S]creen [L]ogFile [B]oth
    export SADM_LOG_APPEND="N"                          # [Y]=Append Existing Log [N]=Create New One
    export SADM_LOG_HEADER="Y"                          # [Y]=Include Log Header  [N]=No log Header
    export SADM_LOG_FOOTER="Y"                          # [Y]=Include Log Footer  [N]=No log Footer
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




#===================================================================================================
# Scripts Variables 
#===================================================================================================
DEBUG_LEVEL=0                               ; export DEBUG_LEVEL        # 0=NoDebug Higher=+Verbose




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



# --------------------------------------------------------------------------------------------------
# Command line Options functions
# Evaluate Command Line Switch Options Upfront
# By Default (-h) Show Help Usage, (-v) Show Script Version,(-d0-9] Set Debug Level 
# --------------------------------------------------------------------------------------------------
function cmd_options()
{
    while getopts "htnvd:" opt ; do                                      # Loop to process Switch
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
           \?) printf "\nInvalid option: -$OPTARG"                      # Invalid Option Message
               show_usage                                               # Display Help Usage
               exit 1                                                   # Exit with Error
               ;;
        esac                                                            # End of case
    done                                                                # End of while
    return 
}


#===================================================================================================
#                                       Script Start HERE
#===================================================================================================

    cmd_options "$@"                                                    # Check command-line Options    
    sadm_start                                                          # Create Dir.,PID,log,rch
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if 'Start' went wrong

# If current user is not 'root', exit to O/S with error code 1 (Optional)
    if ! [ $(id -u) -eq 0 ]                                             # If Cur. user is not root 
        then sadm_write "Script can only be run by the 'root' user.\n"  # Advise User Message
             sadm_write "Process aborted.\n"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S with Error
    fi    

# Script not supported on MacOS
    if [ "$(sadm_get_ostype)" = "DARWIN" ]                              # If on MacOS 
       then sadm_write "This script is not supported on MacOS.\n"       # Advise User
            sadm_stop 0                                                 # Close and Trim Log
            exit 0                                                      # Exit To O/S
    fi

# Make sure that cfg2html is accessible on the server
# If package not installed then used the SADMIN version located in $SADMIN_BASE_DIR/pkg
# ----------------------------------------------------------------------------------------------
    CFG2HTML=`which cfg2html >/dev/null 2>&1`                           # Locate cfg2html
    if [ $? -ne 0 ]                                                     # if found
       then if [ "$(sadm_get_osname)" = "AIX" ]                         # If on AIX & Not Found
               then CFG2HTML="$SADM_PKG_DIR/cfg2html/cfg2html"          # Use then one in /sadmin
               else sadm_write "Command 'cfg2html' was not found.\n"    # Not Found inform user
                    sadm_write "We will install it now.\n"              # Not Found inform user
                    if [ "$(sadm_get_osname)" = "REDHAT" ] || [ "$(sadm_get_osname)" = "CENTOS" ] ||
                       [ "$(sadm_get_osname)" = "FEDORA" ]
                       then rpm -Uvh ${SADM_PKG_DIR}/cfg2html/cfg2html.rpm
                    fi
                    if [ "$(sadm_get_osname)" = "UBUNTU" ]   ||
                       [ "$(sadm_get_osname)" = "DEBIAN" ]   ||
                       [ "$(sadm_get_osname)" = "RASPBIAN" ] ||
                       [ "$(sadm_get_osname)" = "LINUXMINT" ]
                       then dpkg --install --force-confold ${SADM_PKG_DIR}/cfg2html/cfg2html.deb
                    fi
                    CFG2HTML=`which cfg2html >/dev/null 2>&1`           # Try Again to Locate cfg2html
                    if [ $? -ne 0 ]                                     # if Still not found
                        then sadm_write "Still the command 'cfg2html' can't be found.\n"
                             sadm_write "Install it and re-run this script.\n" # Not Found inform user
                             sadm_write "For Ubuntu/Debian/Raspbian : \n"
                             sadm_write " - sudo dpkg --install ${SADM_PKG_DIR}/cfg2html/cfg2html.deb\n"
                             sadm_write "For RedHat/CentOS/Fedora   : \n"
                             sadm_write " - sudo rpm -Uvh ${SADM_PKG_DIR}/cfg2html/cfg2html.rpm.\n"
                             sadm_stop 1                                # Upd. RC & Trim Log
                             exit 1                                     # Exit With Error
                        else sadm_write "Package cfg2html was installed successfully.\n"
                     fi
                     CFG2HTML=`which cfg2html`                          # Save cfg2html path
            fi
       else CFG2HTML=`which cfg2html`                                   # Save cfg2html path
    fi
    export CFG2HTML

    # Run CFG2HTML
    CFG2VER=`$CFG2HTML -v | tr -d '\n'`
    sadm_write "${CFG2VER}\nRunning : $CFG2HTML -H -o ${SADM_DR_DIR}.\n"
    $CFG2HTML -H -o $SADM_DR_DIR >>$SADM_LOG 2>&1
    SADM_EXIT_CODE=$?
    sadm_write "Return code of the command is ${SADM_EXIT_CODE}.\n"

    # Uniformize name of cfg2html output files so that the domain name is not include in the name.
    if [ `hostname` != `hostname -s` ]
        then mv ${SADM_DR_DIR}/$(hostname).err  ${SADM_DR_DIR}/cfg2html_`hostname -s`.err
             mv ${SADM_DR_DIR}/$(hostname).html ${SADM_DR_DIR}/cfg2html_`hostname -s`.html
             mv ${SADM_DR_DIR}/$(hostname).txt  ${SADM_DR_DIR}/cfg2html_`hostname -s`.txt
             mv ${SADM_DR_DIR}/$(hostname).partitions.save ${SADM_DR_DIR}/cfg2html_`hostname -s`.partitions.save
             chown ${SADM_USER}:${SADM_GROUP} ${SADM_DR_DIR}/cfg2html_`hostname -s`.*
             chmod 664 ${SADM_DR_DIR}/cfg2html_`hostname -s`.*

    fi

    # Aix version of cfg2html leave unnecessary file every time it run - Here we delete those
    if [ "$(sadm_get_osname)" = "AIX" ]
        then rm -f ${SADM_DR_DIR}/`hostname -s`_?.txt > /dev/null 2>&1
    fi

    # Go Write Log Footer - Send email if needed - Trim the Log - Update the Recode History File
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log
    exit $SADM_EXIT_CODE                                                # Exit With Global Error 
