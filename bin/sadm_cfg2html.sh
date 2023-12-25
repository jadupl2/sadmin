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
# 2019_03_18 Fix: v3.5 Fix problem that prevent running on Fedora.
# 2020_04_01 Update: v3.6 Replace function sadm_writelog() with N/L incl. by sadm_write() No N/L Incl.
# 2021_07_20 client: v3.7 Fix problem with cfg2html on Fedora 34.
# 2021_07_21 client: v3.7a cfg2html hang on Fedora 34, had to use -n to make it complete.
# 2021_07_21 client: v3.8 Fix problem with cfg2html on Fedora 34.
# 2022_05_05 client: v3.9 Update code for RHEL, CentOS, AlmaLinux & Rocky Linux v9.
# 2022_07_28 client: v3.10 Updated to use new SADMIN section 1.51
#===================================================================================================
#
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPT LE ^C
#set -x




# ---------------------------------------------------------------------------------------
# SADMIN CODE SECTION 1.51
# Setup for Global Variables and load the SADMIN standard library.
# To use SADMIN tools, this section MUST be present near the top of your code.    
# ---------------------------------------------------------------------------------------

# MAKE SURE THE ENVIRONMENT 'SADMIN' VARIABLE IS DEFINED, IF NOT EXIT SCRIPT WITH ERROR.
if [ -z $SADMIN ] || [ ! -r "$SADMIN/lib/sadmlib_std.sh" ] # SADMIN defined ? SADMIN Libr. exist   
    then if [ -r /etc/environment ] ; then source /etc/environment ;fi # Last chance defining SADMIN
         if [ -z $SADMIN ] || [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]    # Still not define = Error
            then printf "\nPlease set 'SADMIN' environment variable to the install directory.\n"
                 exit 1                                    # No SADMIN Env. Var. Exit
         fi
fi 

# USE VARIABLES BELOW, BUT DON'T CHANGE THEM (Used by SADMIN Standard Library).
export SADM_PN=${0##*/}                                    # Script name(with extension)
export SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1`          # Script name(without extension)
export SADM_TPID="$$"                                      # Script Process ID.
export SADM_HOSTNAME=`hostname -s`                         # Host name without Domain Name
export SADM_OS_TYPE=`uname -s |tr '[:lower:]' '[:upper:]'` # Return LINUX,AIX,DARWIN,SUNOS 

# USE & CHANGE VARIABLES BELOW TO YOUR NEEDS (They influence execution of SADMIN Library).
export SADM_VER='3.10'                                      # Script version number
export SADM_PDESC="SADMIN template shell script"           # Script Optional Desc.(Not use if empty)
export SADM_EXIT_CODE=0                                    # Script Default Exit Code
export SADM_LOG_TYPE="B"                                   # Log [S]creen [L]og [B]oth
export SADM_LOG_APPEND="N"                                 # Y=AppendLog, N=CreateNewLog
export SADM_LOG_HEADER="Y"                                 # Y=ProduceLogHeader N=NoHeader
export SADM_LOG_FOOTER="Y"                                 # Y=IncludeFooter N=NoFooter
export SADM_MULTIPLE_EXEC="N"                              # Run Simultaneous copy of script
export SADM_PID_TIMEOUT=7200                               # Sec. before PID Lock expire
export SADM_LOCK_TIMEOUT=3600                              # Sec. before Del. System LockFile
export SADM_USE_RCH="Y"                                    # Update RCH History File (Y/N)
export SADM_DEBUG=0                                        # Debug Level(0-9) 0=NoDebug
export SADM_TMP_FILE1="${SADMIN}/tmp/${SADM_INST}_1.$$"    # Tmp File1 for you to use
export SADM_TMP_FILE2="${SADMIN}/tmp/${SADM_INST}_2.$$"    # Tmp File2 for you to use
export SADM_TMP_FILE3="${SADMIN}/tmp/${SADM_INST}_3.$$"    # Tmp File3 for you to use
export SADM_ROOT_ONLY="Y"                                  # Run only by root ? [Y] or [N]
export SADM_SERVER_ONLY="N"                                # Run only on SADMIN server? [Y] or [N]

# LOAD SADMIN SHELL LIBRARY AND SET SOME O/S VARIABLES.
. ${SADMIN}/lib/sadmlib_std.sh                             # Load SADMIN Shell Library
export SADM_OS_NAME=$(sadm_get_osname)                     # O/S Name in Uppercase
export SADM_OS_VERSION=$(sadm_get_osversion)               # O/S Full Ver.No. (ex: 9.0.1)
export SADM_OS_MAJORVER=$(sadm_get_osmajorversion)         # O/S Major Ver. No. (ex: 9)

# VALUES OF VARIABLES BELOW ARE LOADED FROM SADMIN CONFIG FILE ($SADMIN/cfg/sadmin.cfg)
# BUT THEY CAN BE OVERRIDDEN HERE, ON A PER SCRIPT BASIS (IF NEEDED).
#export SADM_ALERT_TYPE=1                                   # 0=No 1=OnError 2=OnOK 3=Always
#export SADM_ALERT_GROUP="default"                          # Alert Group to advise
#export SADM_MAIL_ADDR="your_email@domain.com"              # Email to send log
#export SADM_MAX_LOGLINE=500                                # Nb Lines to trim(0=NoTrim)
#export SADM_MAX_RCLINE=35                                  # Nb Lines to trim(0=NoTrim)
#export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} "   # SSH CMD to Access Systems
# -----



#===================================================================================================
# Scripts Variables 
#===================================================================================================




# --------------------------------------------------------------------------------------------------
# Show script command line options
# --------------------------------------------------------------------------------------------------
show_usage()
{
    printf "\nUsage: %s%s%s [options]" "${BOLD}${CYAN}" $(basename "$0") "${NORMAL}"
    printf "\nDesc.: %s" "${BOLD}${CYAN}${SADM_PDESC}${NORMAL}"
    printf "\n\n${BOLD}${GREEN}Options:${NORMAL}"
    printf "\n   ${BOLD}${YELLOW}[-d 0-9]${NORMAL}\t\tSet Debug (verbose) Level"
    printf "\n   ${BOLD}${YELLOW}[-h]${NORMAL}\t\t\tShow this help message"
    printf "\n   ${BOLD}${YELLOW}[-v]${NORMAL}\t\t\tShow script version information"
    printf "\n\n" 
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
               num=`echo "$SADM_DEBUG" | grep -E ^\-?[0-9]?\.?[0-9]+$`  # Valid is Level is Numeric
               if [ "$num" = "" ]                            
                  then printf "\nDebug Level specified is invalid.\n"   # Inform User Debug Invalid
                       show_usage                                       # Display Help Usage
                       exit 1                                           # Exit Script with Error
               fi
               printf "Debug Level set to ${SADM_DEBUG}.\n"             # Display Debug Level
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






# --------------------------------------------------------------------------------------------------
# Make sure that cfg2html is accessible on the server
# If package not installed then used the SADMIN version located in $SADMIN_BASE_DIR/pkg
# --------------------------------------------------------------------------------------------------
function main_process()
{

    CFG2HTML=`which cfg2html >/dev/null 2>&1`                           # Locate cfg2html
    if [ $? -ne 0 ]                                                     # if found
       then if [ "$(sadm_get_osname)" = "AIX" ]                         # If on AIX & Not Found
               then CFG2HTML="$SADM_PKG_DIR/cfg2html/cfg2html"          # Use then one in /sadmin
               else sadm_write "Command 'cfg2html' was not found.\n"    # Not Found inform user
                    sadm_write "We will install it now.\n"              # Not Found inform user
                    if [ "$(sadm_get_osname)"  = "REDHAT" ]     || 
                        [ "$(sadm_get_osname)" = "CENTOS" ]     || 
                        [ "$(sadm_get_osname)" = "ALMA" ]       || 
                        [ "$(sadm_get_osname)" = "ROCKY" ]      || 
                        [ "$(sadm_get_osname)" = "FEDORA" ]
                        then rpm -Uvh ${SADM_PKG_DIR}/cfg2html/cfg2html.rpm
                    fi 
                    if [ "$(sadm_get_osname)" = "UBUNTU" ]   || 
                       [ "$(sadm_get_osname)" = "DEBIAN" ]   ||
                       [ "$(sadm_get_osname)" = "RASPBIAN" ] ||
                       [ "$(sadm_get_osname)" = "MINT" ]
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
    if [ "$(sadm_get_osname)" = "FEDORA" ]
        then sadm_write "${CFG2VER}\nRunning : $CFG2HTML -n -H -o ${SADM_DR_DIR}\n"
             $CFG2HTML -n -H -o $SADM_DR_DIR >>$SADM_LOG 2>&1
             SADM_EXIT_CODE=$?
        else sadm_write "${CFG2VER}\nRunning : $CFG2HTML -H -o ${SADM_DR_DIR}\n"
             $CFG2HTML -H -o $SADM_DR_DIR >>$SADM_LOG 2>&1
             SADM_EXIT_CODE=$?
    fi 
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
}




#===================================================================================================
#                                       Script Start HERE
#===================================================================================================

    cmd_options "$@"                                                    # Check command-line Options    
    sadm_start                                                          # Create Dir.,PID,log,rch
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if 'Start' went wrong
    main_process
    SADM_EXIT_CODE=$?
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log
    exit $SADM_EXIT_CODE                                                # Exit With Global Error 
