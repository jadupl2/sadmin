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
# 2.2 Correction in end_process function (April 2014)
#
#===================================================================================================
#set -x



#
#===================================================================================================
# If You want to use the SADMIN Libraries, you need to add this section at the top of your script
#   Please refer to the file $sadm_base_dir/lib/sadm_lib_std.txt for a description of each
#   variables and functions available to you when using the SADMIN functions Library
#===================================================================================================

# --------------------------------------------------------------------------------------------------
# Global variables used by the SADMIN Libraries - Some influence the behavior of function in Library
# These variables need to be defined prior to load the SADMIN function Libraries
# --------------------------------------------------------------------------------------------------
SADM_PN=${0##*/}                           ; export SADM_PN             # Current Script name
SADM_VER='1.5'                             ; export SADM_VER            # This Script Version
SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1` ; export SADM_INST           # Script name without ext.
SADM_TPID="$$"                             ; export SADM_TPID           # Script PID
SADM_EXIT_CODE=0                           ; export SADM_EXIT_CODE      # Script Error Return Code
SADM_BASE_DIR=${SADMIN:="/sadmin"}         ; export SADM_BASE_DIR       # SADMIN Root Base Directory
SADM_LOG_TYPE="B"                          ; export SADM_LOG_TYPE       # 4Logger S=Scr L=Log B=Both
SADM_MULTIPLE_EXEC="N"                     ; export SADM_MULTIPLE_EXEC  # Run many copy at same time
SADM_DEBUG_LEVEL=0                         ; export SADM_DEBUG_LEVEL    # 0=NoDebug Higher=+Verbose

# --------------------------------------------------------------------------------------------------
# Define SADMIN Tool Library location and Load them in memory, so they are ready to be used
# --------------------------------------------------------------------------------------------------
[ -f ${SADM_BASE_DIR}/lib/sadm_lib_std.sh ]    && . ${SADM_BASE_DIR}/lib/sadm_lib_std.sh     # sadm std Lib
[ -f ${SADM_BASE_DIR}/lib/sadm_lib_server.sh ] && . ${SADM_BASE_DIR}/lib/sadm_lib_server.sh  # sadm server lib
#[ -f ${SADM_BASE_DIR}/lib/sadm_lib_screen.sh ] && . ${SADM_BASE_DIR}/lib/sadm_lib_screen.sh  # sadm screen lib

# --------------------------------------------------------------------------------------------------
# These Global Variables, get their default from the sadmin.cfg file, but can be overridden here
# --------------------------------------------------------------------------------------------------
#SADM_MAIL_ADDR="your_email@domain.com"    ; export ADM_MAIL_ADDR        # Default is in sadmin.cfg
SADM_MAIL_TYPE=1                          ; export SADM_MAIL_TYPE       # 0=No 1=Err 2=Succes 3=All
#SADM_CIE_NAME="Your Company Name"         ; export SADM_CIE_NAME        # Company Name
#SADM_USER="sadmin"                        ; export SADM_USER            # sadmin user account
#SADM_GROUP="sadmin"                       ; export SADM_GROUP           # sadmin group account
#SADM_MAX_LOGLINE=5000                     ; export SADM_MAX_LOGLINE     # Max Nb. Lines in LOG )
#SADM_MAX_RCLINE=100                       ; export SADM_MAX_RCLINE      # Max Nb. Lines in RCH file
#SADM_NMON_KEEPDAYS=40                     ; export SADM_NMON_KEEPDAYS   # Days to keep old *.nmon
#SADM_SAR_KEEPDAYS=40                      ; export SADM_NMON_KEEPDAYS   # Days to keep old *.nmon
 
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPTE LE ^C
#===================================================================================================
#


# --------------------------------------------------------------------------------------------------
#              V A R I A B L E S    L O C A L   T O     T H I S   S C R I P T
# --------------------------------------------------------------------------------------------------
#


#===================================================================================================
#                                Script Start HERE
#===================================================================================================
    sadm_start                                                          # Init Env. Dir & RC/Log File

    if ! $(sadm_is_root)                                                # Only ROOT can run Script
        then sadm_writelog "This script must be run by the ROOT user"   # Advise User Message
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi
    
    # Make sure that cfg2html is accessible on the server
    # If package not installed then used the SADMIN version located in $SADMIN_BASE_DIR/pkg
    # ----------------------------------------------------------------------------------------------
    CFG2HTML=`which cfg2html >/dev/null 2>&1`                           # Locate cfg2html
    if [ $? -eq 0 ]                                                     # if found
        then CFG2HTML=`which cfg2html`                                  # Save cfg2html path
        else if [ "$(sadm_get_osname)" = "AIX" ]                        # If on AIX & Not Found
                then CFG2HTML="$SADM_PKG_DIR/cfg2html/cfg2html"         # Use then one in /sadmin
                else sadm_writelog "Error : The command 'cfg2html' was not found"   # Not Found inform user
                     sadm_writelog "   Install it and re-run this script" # Not Found inform user
                     sadm_writelog "   For Ubuntu/Debian/Raspbian : sudo dpkg --install ${SADM_PKG_DIR}/cfg2html/cfg2html.deb"
                     sadm_writelog "   For RedHat/CentOS/Fedora   : rpm -Uvh ${SADM_PKG_DIR}/cfg2html/cfg2html.rpm"
                     sadm_stop 1                                        # Upd. RC & Trim Log 
                     exit 1                                             # Exit With Error
             fi
    fi
    export CFG2HTML                                                     
    if [ "$SADM_DEBUG_LEVEL" -gt 0 ]
        then sadm_writelog "COMMAND CFG2HTML : $CFG2HTML"               # Display Path if Debug
    fi
    
    # Run CFG2HTML
    CFG2VER=`$CFG2HTML -v | tr -d '\n'`
    sadm_writelog "Version use is $CFG2VER"
    sadm_writelog "Running : $CFG2HTML -H -o $SADM_DR_DIR"
    $CFG2HTML -H -o $SADM_DR_DIR >>$SADM_LOG 2>&1
    SADM_EXIT_CODE=$?
    sadm_writelog "Return code of the command is $SADM_EXIT_CODE"
    
    # Uniformize name of cfg2html so that the domain name is not include in the name
    if [ `hostname` != `hostname -s` ]
        then mv $(hostname).err  `hostname -s`.err
             mv $(hostname).html `hostname -s`.html
             mv $(hostname).txt  `hostname -s`.txt
             mv $(hostname).partitions.save `hostname -s`.partitions.save
    fi


    # Go Write Log Footer - Send email if needed - Trim the Log - Update the Recode History File
    sadm_stop $SADM_EXIT_CODE                                             # Upd. RCH File & Trim Log 
    exit $SADM_EXIT_CODE                                                  # Exit With Global Error (0/1)


