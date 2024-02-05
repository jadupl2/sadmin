#! /usr/bin/env bash
#===================================================================================================
#   Author   :  Jacques Duplessis
#   Title    :  sadm_create_cfg2html.sh
#   Synopsis :  Run 'cfg2html' tool & produce system information files.
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
#@2024_01_02 client: v3.12 Code review to run cfg2html v7 & update SADMIN section to v1.56
#===================================================================================================
#
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPT LE ^C
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
export SADM_VER='3.12'                                      # Script version number
export SADM_PDESC="Run 'cfg2html' tool & produce system information files."
export SADM_ROOT_ONLY="Y"                                  # Run only by root ? [Y] or [N]
export SADM_SERVER_ONLY="N"                                # Run only on SADMIN server? [Y] or [N]
export SADM_LOG_TYPE="B"                                   # Write log to [S]creen, [L]og, [B]oth
export SADM_LOG_APPEND="N"                                 # Y=AppendLog, N=CreateNewLog
export SADM_LOG_HEADER="Y"                                 # Y=ProduceLogHeader N=NoHeader
export SADM_LOG_FOOTER="Y"                                 # Y=IncludeFooter N=NoFooter
export SADM_MULTIPLE_EXEC="N"                              # Run Simultaneous copy of script
export SADM_USE_RCH="Y"                                    # Update RCH History File (Y/N)
export SADM_DEBUG=0                                        # Debug Level(0-9) 0=NoDebug
export SADM_EXIT_CODE=0                                    # Script Default Exit Code
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
#export SADM_MAX_LOGLINE=400                                # Nb Lines to trim(0=NoTrim)
#export SADM_MAX_RCLINE=35                                  # Nb Lines to trim(0=NoTrim)
#export SADM_PID_TIMEOUT=7200                               # Sec. before PID Lock expire
#export SADM_LOCK_TIMEOUT=3600                              # Sec. before Del. System LockFile
# --------------- ---  E N D   O F   S A D M I N   C O D E    S E C T I O N  -----------------------



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
# Check if we need to update from version to 7 of cfg2html
# --------------------------------------------------------------------------------------------------
function update_cfg2html()
{
    if [ "$CFG2HTML" = "" ] ; then return 0 ; fi                        # If not install, no update

    #wversion=$($CFG2HTML -v | tail -1 | awk  '{ print $3 }')            # Get version third field
    #cur_version=$(echo $wversion | awk -F\. '{ print $1 }')             # Get 1st digit of version #
    #if [ "$cur_version" = "7" ] ; then return 0 ; fi                    # Current version is OK
    #sadm_write_log "Going to update 'cfg2html' from version $cur_version to version 7." 

    # Uninstall current version & install latest version.
    case "$(sadm_get_packagetype)" in
        "rpm")  package_name="cfg2html-linux"                           # rpm cfg2html package name
                sadm_write_log "Verifying if '$package_name' package is installed."
                rpm -qi $package_name >/dev/null 2>&1                   # Is the package installed ?
                if [ $? -eq 0 ]                                         # If cfg2html installed 
                    then sadm_write_log "Removing version 2 of '$package_name'." 
                         sadm_write_log "dnf remove -y $package_name"
                         dnf remove -y "$package_name" >>$SADM_LOG 2>&1 # Remove installed package
                         if [ $? -ne 0 ]                                # If error removing package
                            then sadm_write_err "Error removing '$package_name' package."
                                 return 1                               # Return Error to caller
                         fi 
                fi 
                #sadm_write_log " "
                sadm_write_log "Installing ${package_name} v7."
                sadm_write_log "dnf -y --nogpgcheck install ${SADM_PKG_DIR}/cfg2html/cfg2html.rpm"
                dnf -y --nogpgcheck install ${SADM_PKG_DIR}/cfg2html/cfg2html.rpm >>$SADM_LOG 2>&1
                if [ $? -ne 0 ]                                         # if error installing latest
                   then sadm_write_err "Error installing '$package_name' package."
                        return 1                                        # Return Error to caller
                fi 
                sadm_write_log "Latest version on '$package_name' in now installed."
                ;;  

        "deb")  package_name="cfg2html-linux"                           # deb cfg2html package name
                sadm_write_log "Verifying if '$package_name' package is installed."
                dpkg -s "$package_name" >/dev/null 2>&1                 # Is the package installed ?
                if [ $? -eq 0 ]                                         # If cfg2html installed 
                    then sadm_write_log "Removing version 2 of $package_name." 
                         sadm_write_log "apt remove -y $package_name"
                         apt remove -y "$package_name" >>$SADM_LOG 2>&1 # Remove installed package
                         if [ $? -ne 0 ]                                # If error removing package
                            then sadm_write_err "Error removing '$package_name' package."
                                 return 1                               # Return Error to caller
                         fi 
                fi 
                #sadm_write_log " "
                sadm_write_log "Installing '$package_name' v7 package."
                sadm_write_log "apt -y install ${SADM_PKG_DIR}/cfg2html/cfg2html.deb"
                apt -y install ${SADM_PKG_DIR}/cfg2html/cfg2html.deb >>$SADM_LOG 2>&1
                if [ $? -ne 0 ]                                         # if error installing latest
                   then sadm_write_err "Error installing '$package_name' package."
                        return 1                                        # Return Error to caller
                fi 
                sadm_write_log "Latest version on '$package_name' in now installed."
                ;;  

        *)      sadm_write_err "Invalid package type $(sadm_get_packagetype)."
                return 1                                                # Return Error to caller
                ;;  
    esac
}







# --------------------------------------------------------------------------------------------------
# Make sure that cfg2html is accessible on the server
# If package not installed then used the SADMIN version located in $SADMIN_BASE_DIR/pkg
# --------------------------------------------------------------------------------------------------
function main_process()
{
    ws=$(which cfg2html >/dev/null 2>&1)                                # cfg2html exist on system?
    if [ $? -eq 0 ]                                                     # Yes it does
        then CFG2HTML=$(which cfg2html)                                 # Get full path of cfg2html
             wversion=$($CFG2HTML -v | tail -1 | awk  '{ print $3 }')   # Get version third field
             cur_version=$(echo $wversion | awk -F\. '{ print $1 }')    # Get 1st digit of version #
             if [ "$cur_version" != "7" ]
                then update_cfg2html
                     if [ $? -ne 0 ] 
                        then sadm_write_err "Problem updating 'cfg2html'."
                             return 1 
                     fi 
             fi 
    fi


    CFG2HTML=$(which cfg2html)                                          # May have change if updated
    if [ $? -ne 0 ]                                                     # if not found
       then sadm_write_log "Command 'cfg2html' is not installed."       # Not Found inform user
            sadm_write_log "Installing 'cfg2html' ..."                  # Not Found inform user
            packname="cfg2html"

            if [ "$(sadm_get_packagetype)" = "rpm" ] 
                then sadm_write_log "dnf -y --nogpgcheck install ${SADM_PKG_DIR}/cfg2html/cfg2html.rpm"
                     dnf -y --nogpgcheck install ${SADM_PKG_DIR}/cfg2html/cfg2html.rpm >>$SADM_LOG 2>&1
                     if [ $? -ne 0 ]                                    # if error installing latest
                        then sadm_write_err "Error installing '$packname' package."
                             return 1                                   # Return Error to caller
                     fi 
            fi 

            if [ "$(sadm_get_packagetype)" = "deb" ] 
                then sadm_write_log "apt -y install ${SADM_PKG_DIR}/cfg2html/cfg2html.deb"
                     apt -y install ${SADM_PKG_DIR}/cfg2html/cfg2html.deb >>$SADM_LOG 2>&1
                     if [ $? -ne 0 ]                                    # if error installing latest
                        then sadm_write_err "Error installing '$packname' package."
                             return 1                                   # Return Error to caller
                     fi 
            fi

            # Now that it is supposed to be installed, check if available now.
            ws=$(which cfg2html >/dev/null 2>&1)                        # Try Again to Locate cfg2html
            if [ $? -ne 0 ]                                             # if Still not found
                then sadm_write_err "Still the command 'cfg2html' can't be found."
                     sadm_write_err "Install it & re-run this script."  # Not Found inform user
                     sadm_write_err "For Ubuntu/Debian/Mint,Raspbian : "
                     sadm_write_err " - sudo apt -y install ${SADM_PKG_DIR}/cfg2html/cfg2html.deb"
                     sadm_write_err "For Rocky,Alma,RedHat,CentOS,Fedora   : "
                     sadm_write_err " - sudo dnf -y install ${SADM_PKG_DIR}/cfg2html/cfg2html.rpm."
                     sadm_stop 1                                        # Upd. RC & Trim Log
                     exit 1                                             # Exit With Error
                else sadm_write_log "Package cfg2html was installed successfully."
             fi
             
    fi

    # Update cfg2html if necessary
    #update_cfg2html
    #if [ $? -ne 0 ] 
    #    then sadm_write_err "Problem updating 'cfg2html'."
    #         return 1 
    #fi

    # Run CFG2HTML
    export CFG2HTML=$(which cfg2html)                                   # Get cfg2html Path
    #CFG2VER=$($CFG2HTML -v | tr -d '\n')
    sadm_write_log " "
    #sadm_write_log "${CFG2VER}"
    sadm_write_log "Running : $CFG2HTML -o ${SADM_DR_DIR}"
    $CFG2HTML -o $SADM_DR_DIR | tee -a $SADM_LOG 2>&1
    SADM_EXIT_CODE=$?
    sadm_write_log "Return code of the command is ${SADM_EXIT_CODE}."

    # Uniformize name of cfg2html output files so that the domain name is not include in the name.
    if [ "$(hostname)" != "$(hostname -s)" ]
        then if [ -f "${SADM_DR_DIR}/$(hostname).err" ] 
                then mv "${SADM_DR_DIR}/$(hostname).err" "${SADM_DR_DIR}/cfg2html_$(hostname -s).err"
             fi 
             if [ -f "${SADM_DR_DIR}/$(hostname).html" ]
                then mv "${SADM_DR_DIR}/$(hostname).html" "${SADM_DR_DIR}/cfg2html_$(hostname -s).html"
             fi 
             if [ -f "${SADM_DR_DIR}/$(hostname).txt" ]
                then mv "${SADM_DR_DIR}/$(hostname).txt" "${SADM_DR_DIR}/cfg2html_$(hostname -s).txt"
             fi 
             if [ -f "${SADM_DR_DIR}/$(hostname).partitions.save" ] 
                then mv "${SADM_DR_DIR}/$(hostname).partitions.save" "${SADM_DR_DIR}/cfg2html_$(hostname -s).partitions.save"
             fi 
             chown ${SADM_USER}:${SADM_GROUP} ${SADM_DR_DIR}/cfg2html_$(hostname -s).*
             chmod 664 ${SADM_DR_DIR}/cfg2html_$(hostname -s).*

    fi
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
               num=$(echo "$SADM_DEBUG" | grep -E ^\-?[0-9]?\.?[0-9]+$) # Valid is Level is Numeric
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
