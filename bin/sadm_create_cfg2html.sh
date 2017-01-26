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
# 2.4 Install cfg2html from local copy is not present (Jab 2017)
#
#===================================================================================================
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
SADM_VER='2.4'                             ; export SADM_VER            # Script Version
SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1` ; export SADM_INST           # Script name without ext.
SADM_TPID="$$"                             ; export SADM_TPID           # Script PID
SADM_EXIT_CODE=0                           ; export SADM_EXIT_CODE      # Script Exit Return Code
SADM_BASE_DIR=${SADMIN:="/sadmin"}         ; export SADM_BASE_DIR       # SADMIN Root Base Dir.
SADM_LOG_TYPE="B"                          ; export SADM_LOG_TYPE       # 4Logger S=Scr L=Log B=Both
SADM_LOG_APPEND="N"                        ; export SADM_LOG_APPEND     # Append to Existing Log ?
SADM_MULTIPLE_EXEC="N"                     ; export SADM_MULTIPLE_EXEC  # Run many copy at same time
[ -f ${SADM_BASE_DIR}/lib/sadm_lib_std.sh ]    && . ${SADM_BASE_DIR}/lib/sadm_lib_std.sh     
[ -f ${SADM_BASE_DIR}/lib/sadm_lib_server.sh ] && . ${SADM_BASE_DIR}/lib/sadm_lib_server.sh  

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
    if [ $? -ne 0 ]                                                     # if found
       then if [ "$(sadm_get_osname)" = "AIX" ]                         # If on AIX & Not Found
               then CFG2HTML="$SADM_PKG_DIR/cfg2html/cfg2html"          # Use then one in /sadmin
               else sadm_writelog "Command 'cfg2html' was not found"    # Not Found inform user
                    sadm_writelog "We will install it now"              # Not Found inform user
                    if [ "$(sadm_get_osname)" = "REDHAT" ] || [ "$(sadm_get_osname)" = "CENTOS" ] || 
                       [ "$(sadm_get_osname)" = "FEDORA" ]                    
                       then rpm -Uvh ${SADM_PKG_DIR}/cfg2html/cfg2html.rpm
                    fi
                    if [ "$(sadm_get_osname)" = "UBUNTU" ] || [ "$(sadm_get_osname)" = "DEBIAN" ] || 
                       [ "$(sadm_get_osname)" = "RASPBIAN" ]                    
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
        then mv ${SADM_DR_DIR}/$(hostname).err  ${SADM_DR_DIR}/`hostname -s`.err
             mv ${SADM_DR_DIR}/$(hostname).html ${SADM_DR_DIR}/`hostname -s`.html
             mv ${SADM_DR_DIR}/$(hostname).txt  ${SADM_DR_DIR}/`hostname -s`.txt
             mv ${SADM_DR_DIR}/$(hostname).partitions.save ${SADM_DR_DIR}/`hostname -s`.partitions.save
    fi

    # Aix version of cfg2html leave unnecessary file every time it run - Here we delete those
    if [ "$(sadm_get_osname)" = "AIX" ]  
        then rm -f ${SADM_DR_DIR}/`hostname -s`_?.txt > /dev/null 2>&1
    fi
       

    # Go Write Log Footer - Send email if needed - Trim the Log - Update the Recode History File
    sadm_stop $SADM_EXIT_CODE                                             # Upd. RCH File & Trim Log 
    exit $SADM_EXIT_CODE                                                  # Exit With Global Error (0/1)


