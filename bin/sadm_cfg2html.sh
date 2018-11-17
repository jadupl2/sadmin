#! /usr/bin/env sh
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
#@2018_11_13    v3.4 Chown & Chmod of cfh2html produced files.
#===================================================================================================
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
    export SADM_VER='3.4'                               # Current Script Version
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
    #export SADM_ALERT_GROUP="default"                   # AlertGroup Used to Alert (alert_group.cfg)
    #export SADM_MAIL_ADDR="your_email@domain.com"      # Email to send log (To Override sadmin.cfg)
    #export SADM_MAX_LOGLINE=1000                       # When Script End Trim log file to 1000 Lines
    #export SADM_MAX_RCLINE=125                         # When Script End Trim rch file to 125 Lines
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
show_version()
{
    printf "\n${SADM_PN} - Version $SADM_VER"
    printf "\nSADMIN Shell Library Version $SADM_LIB_VER"
    printf "\n$(sadm_get_osname) - Version $(sadm_get_osversion)"
    printf " - Kernel Version $(sadm_get_kernel_version)"
    printf "\n\n" 
}




#===================================================================================================
#                                Script Start HERE
#===================================================================================================

# Evaluate Command Line Switch Options Upfront
# (-h) Show Help Usage, (-v) Show Script Version,(-d0-9] Set Debug Level 
    while getopts "hvd:" opt ; do                                       # Loop to process Switch
        case $opt in
            d) DEBUG_LEVEL=$OPTARG                                      # Get Debug Level Specified
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

# Script not supported on MacOS
    if [ "$(sadm_get_ostype)" = "DARWIN" ]                              # If on MacOS 
       then sadm_writelog "This script is not supported on MacOS"       # Advise User
             sadm_stop 0                                                # Close and Trim Log
             exit 0                                                     # Exit To O/S
    fi

# Bug - Hang on Fedora 27 and Up - Skip Execution
    if [ "$(sadm_get_osname)" = "FEDORA" ] && [ "$(sadm_get_osmajorversion)" > "26" ] 
       then sadm_writelog "This script is not supported on Fedora higher than 26"  # Advise User
             sadm_stop 0                                                # Close and Trim Log
             exit 0                                                     # Exit To O/S
    fi

# Make sure that cfg2html is accessible on the server
# If package not installed then used the SADMIN version located in $SADMIN_BASE_DIR/pkg
# ----------------------------------------------------------------------------------------------
    CFG2HTML=`which cfg2html >/dev/null 2>&1`                           # Locate cfg2html
    if [ $? -ne 0 ]                                                     # if found
       then if [ "$(sadm_get_osname)" = "AIX" ]                         # If on AIX & Not Found
               then CFG2HTML="$SADM_PKG_DIR/cfg2html/cfg2html"          # Use then one in /sadmin
               else sadm_writelog "Command 'cfg2html' was not found"    # Not Found inform user
                    sadm_writelog "We will install it now"              # Not Found inform user
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
                        then sadm_writelog "Still the command 'cfg2html' can't be found"
                             sadm_writelog "Install it and re-run this script" # Not Found inform user
                             sadm_writelog "For Ubuntu/Debian/Raspbian : "
                             sadm_writelog " - sudo dpkg --install ${SADM_PKG_DIR}/cfg2html/cfg2html.deb"
                             sadm_writelog "For RedHat/CentOS/Fedora   : "
                             sadm_writelog " - sudo rpm -Uvh ${SADM_PKG_DIR}/cfg2html/cfg2html.rpm"
                             sadm_stop 1                                # Upd. RC & Trim Log
                             exit 1                                     # Exit With Error
                        else sadm_writelog "Package cfg2html was installed successfully"
                     fi
                     CFG2HTML=`which cfg2html`                          # Save cfg2html path
            fi
       else CFG2HTML=`which cfg2html`                                   # Save cfg2html path
    fi
    export CFG2HTML

    # Run CFG2HTML
    CFG2VER=`$CFG2HTML -v | tr -d '\n'`
    sadm_writelog "$CFG2VER" ;  sadm_writelog ""
    sadm_writelog "Running : $CFG2HTML -H -o $SADM_DR_DIR"
    $CFG2HTML -H -o $SADM_DR_DIR >>$SADM_LOG 2>&1
    SADM_EXIT_CODE=$?
    sadm_writelog "Return code of the command is $SADM_EXIT_CODE"

    # Uniformize name of cfg2html so that the domain name is not include in the name
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
    sadm_stop $SADM_EXIT_CODE                                             # Upd. RCH File & Trim Log
    exit $SADM_EXIT_CODE                                                  # Exit With Global Error (0/1)
