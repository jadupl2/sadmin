#! /usr/bin/env sh
# --------------------------------------------------------------------------------------------------
#   Author   :  Jacques Duplessis
#   Title    :  sadm_housekeeping.sh
#   Synopsis :  Verify existence of SADMIN Dir. along with their Prot/Priv and purge old log,rch,nmon.
#   Version  :  1.0
#   Date     :  19 December 2015
#   Requires :  sh
#
#   The SADMIN Tool is free software; you can redistribute it and/or modify it under the terms
#   of the GNU General Public License as published by the Free Software Foundation; either
#   version 2 of the License, or (at your option) any later version.
#
#   SADMIN Tool are distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
#   without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#   See the GNU General Public License for more details.
#
# --------------------------------------------------------------------------------------------------
# 2017_08_08    v1.7 Add /sadmin/jac in the housekeeping and change 600 to 644 for configuration file
# 2017-10-10    v1.8 Remove deletion of release file on sadm client in /sadmin/cfg
# 2018-01-02    v1.9 Delete file not needed anymore
# 2018_05_14    v1.10 Correct problem on MacOS with change owner/group command
# 2018_06_04    v1.11 Add User Directories, Database Backup Directory, New Backup Cfg Files
# 2018_06_05    v1.12 Enhance Ouput Display - Add Missing Setup Dir, Review Purge Commands
# 2018_06_09    v1.13 Add Help and Version Function - Change Startup Order
# 2018_06_13    v1.14 Change all files in $SADMIN/cfg to 664.
# 2018_07_30    v1.15 Make sure sadmin crontab files in /etc/cron.d have proper owner & permission.
# 2018_09_16    v1.16 Include Cleaning of alert files needed only on SADMIN server.
# 2018_09_28    v1.17 Code Optimize and Cleanup
# 2018_10_27    v1.18 Remove old dir. not use anymore (if exist)
# 2018_11_02    v1.19 Code Maint. & Comment
#@2018_11_23    v1.20 An error is signal when the 'sadmin' account is lock, preventing cron to run.
#@2018_11_24    v1.21 Check SADM_USER status, give more precise explanation & corrective cmd if lock.
#
# --------------------------------------------------------------------------------------------------
#
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
    export SADM_VER='1.21'                              # Current Script Version
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








# --------------------------------------------------------------------------------------------------
#                               This Script environment variables
# --------------------------------------------------------------------------------------------------
DEBUG_LEVEL=0                               ; export DEBUG_LEVEL        # 0=NoDebug Higher=+Verbose
ERROR_COUNT=0                               ; export ERROR_COUNT        # Error Counter
LIMIT_DAYS=14                               ; export LIMIT_DAYS         # RCH+LOG Delete after
DIR_ERROR=0                                 ; export DIR_ERROR          # ReturnCode = Nb. of Errors
FILE_ERROR=0                                ; export FILE_ERROR         # ReturnCode = Nb. of Errors



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



# --------------------------------------------------------------------------------------------------
#             Check Daily if sadmin Account is lock (Disabling crontab script to work) 
# --------------------------------------------------------------------------------------------------
check_sadmin_account()
{
    lock_error=0
    sadm_writelog "${SADM_TEN_DASH}"
    sadm_writelog "Check status of account '$SADM_USER' ..." 

    if [ $(sadm_get_ostype) = "LINUX" ]                                 # On Linux Operating System
        then passwd -S $SADM_USER | grep -i 'locked' > /dev/null 2>&1   # Check if Account is locked
             if [ $? -eq 0 ]                                            # If Account is Lock
                then upass=`grep "^$SADM_USER" /etc/shadow | awk -F: '{ print $2 }'` # Get pwd hash
                     if [ "$upass" = "!!" ]                             # if passwd is '!!'' = NoPwd
                        then sadm_writelog "[ERROR] User $SADM_USER has no password" 
                             sadm_writelog "This is not secure, please assign one !!"
                             lock_error=1                               # Set Error Flag ON
                        else first2char=`echo $upass | cut -c1-2`       # Get passwd first two Char.
                             if [ "$first2char" = "!!" ]                # First 2 Char are '!!' 
                                then sadm_writelog "[ERROR] Account $SADM_USER is locked"
                                     sadm_writelog "Use 'passwd -u $SADM_USER' to unlock it."
                                     lock_error=1                       # Set Error Flag ON
                                else firstchar=`echo $upass | cut -c1`  # Get passwd first Char.
                                     if [ "$firstchar" = "!" ]          # First Char is "!'
                                        then sadm_writelog "[ERROR] Account $SADM_USER is locked"
                                             sadm_writelog "Use 'usermod -U $SADM_USER' to unlock it."
                                             lock_error=1               # Set Error Flag ON
                                        else sadm_writelog "We use 'passwd -S $SADM_USER' to check if user account is lock"
                                             sadm_writelog "You need to fix that, so the account unlock"
                                             lock_error=1               # Set Error Flag ON
                                     fi                                            
                             fi 
                     fi 
             fi
    fi
  
    if [ $(sadm_get_ostype) = "AIX" ]
        then lsuser -a account_locked $SADM_USER | grep -i 'true' >/dev/null 2>&1
             if [ $? -eq 0 ] 
                then sadm_writelog "[ERROR] Account $SADM_USER is locked and need to be unlock ..."
                     sadm_writelog "Please check the account and unlock it with these commands ;"
                     sadm_writelog "chsec -f /etc/security/lastlog -a 'unsuccessful_login_count=0' -s $SADM_USER"
                     sadm_writelog "chuser 'account_locked=false' $SADM_USER"
                     lock_error=1
             fi
    fi

    if [ $lock_error -eq 0 ] ; then sadm_writelog "[OK] No problem with '$SADM_USER' account." ; fi
    sadm_writelog "${SADM_TEN_DASH}"
    return $lock_error
}





# --------------------------------------------------------------------------------------------------
#                             General Directories Owner/Group and Privilege
# --------------------------------------------------------------------------------------------------
set_dir()
{
    VAL_DIR=$1
    VAL_OCTAL=$2
    VAL_OWNER=$3
    VAL_GROUP=$4
    RETURN_CODE=0

    if [ -d "$VAL_DIR" ]
        then sadm_writelog "${SADM_TEN_DASH}"
             sadm_writelog "Change $VAL_DIR to $VAL_OCTAL"
             chmod $VAL_OCTAL $VAL_DIR
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on 'chmod' operation for $VALDIR"
                     ERROR_COUNT=$(($ERROR_COUNT+1))                    # Add Return Code To ErrCnt
                     RETURN_CODE=1                                      # Error = Return Code to 1
             fi
             sadm_writelog "Change chmod gou-s $VAL_DIR"
             chmod gou-s $VAL_DIR
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on 'chmod' operation for $VALDIR"
                     ERROR_COUNT=$(($ERROR_COUNT+1))                    # Add Return Code To ErrCnt
                     RETURN_CODE=1                                      # Error = Return Code to 1
             fi
             sadm_writelog "Change $VAL_DIR owner to ${VAL_OWNER}:${VAL_GROUP}"
             chown ${VAL_OWNER}:${VAL_GROUP} $VAL_DIR
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on 'chown' operation for $VALDIR"
                     ERROR_COUNT=$(($ERROR_COUNT+1))                    # Add Return Code To ErrCnt
                     RETURN_CODE=1                                      # Error = Return Code to 1
             fi
             lsline=`ls -ld $VAL_DIR`
             sadm_writelog "$lsline"
             if [ $RETURN_CODE = 0 ] ; then sadm_writelog "OK" ; fi
    fi
    return $RETURN_CODE
}

# --------------------------------------------------------------------------------------------------
#                               General Directories Housekeeping Function
# --------------------------------------------------------------------------------------------------
dir_housekeeping()
{
    sadm_writelog " "
    sadm_writelog "$SADM_80_DASH"
    sadm_writelog "CLIENT DIRECTORIES HOUSEKEEPING STARTING"
    sadm_writelog " "
    ERROR_COUNT=0                                                       # Reset Error Count

    # Remove Old Ver.1 Dir. Not use anymore
    if [ -d "${SADM_DAT_DIR}/sar" ]
        then sadm_writelog "Directory ${SADM_DAT_DIR}/sar should exist anymore."
             sadm_writelog "I am deleting it now."
             rm -fr ${SADM_DAT_DIR}/sar
    fi

    # Remove Old Ver.1 Dir. Not use anymore
    if [ -d "${SADM_BASE_DIR}/jac" ]
       then sadm_writelog "Directory ${SADM_BASE_DIR}/jac should exist anymore."
            sadm_writelog "I am deleting it now."
            rm -fr ${SADM_BASE_DIR}/jac
    fi

    set_dir "$SADM_BASE_DIR"      "0775" "$SADM_USER" "$SADM_GROUP"     # set Priv SADMIN Base Dir
    ERROR_COUNT=$(($ERROR_COUNT+$?))                                    # Cumulate Err.Counter
    if [ $ERROR_COUNT -ne 0 ] ; then sadm_writelog "Total Error Count at $ERROR_COUNT" ;fi

    set_dir "$SADM_BIN_DIR"       "0775" "$SADM_USER" "$SADM_GROUP"     # set Priv SADMIN BIN Dir
    ERROR_COUNT=$(($ERROR_COUNT+$?))                                    # Cumulate Err.Counter
    if [ $ERROR_COUNT -ne 0 ] ; then sadm_writelog "Total Error Count at $ERROR_COUNT" ;fi

    set_dir "$SADM_CFG_DIR"       "0775" "$SADM_USER" "$SADM_GROUP"     # set Priv SADMIN CFG Dir
    ERROR_COUNT=$(($ERROR_COUNT+$?))                                    # Cumulate Err.Counter
    if [ $ERROR_COUNT -ne 0 ] ; then sadm_writelog "Total Error Count at $ERROR_COUNT" ;fi

    set_dir "$SADM_DAT_DIR"       "0775" "$SADM_USER" "$SADM_GROUP"     # set Priv SADMIN DAT Dir
    ERROR_COUNT=$(($ERROR_COUNT+$?))                                    # Cumulate Err.Counter
    if [ $ERROR_COUNT -ne 0 ] ; then sadm_writelog "Total Error Count at $ERROR_COUNT" ;fi

    set_dir "$SADM_DOC_DIR"       "0775" "$SADM_USER" "$SADM_GROUP"     # set Priv SADMIN LIB Dir
    ERROR_COUNT=$(($ERROR_COUNT+$?))                                    # Cumulate Err.Counter
    if [ $ERROR_COUNT -ne 0 ] ; then sadm_writelog "Total Error Count at $ERROR_COUNT" ;fi

    set_dir "$SADM_LIB_DIR"       "0775" "$SADM_USER" "$SADM_GROUP"     # set Priv SADMIN LIB Dir
    ERROR_COUNT=$(($ERROR_COUNT+$?))                                    # Cumulate Err.Counter
    if [ $ERROR_COUNT -ne 0 ] ; then sadm_writelog "Total Error Count at $ERROR_COUNT" ;fi

    set_dir "$SADM_LOG_DIR"       "0775" "$SADM_USER" "$SADM_GROUP"     # set Priv SADMIN LOG Dir
    ERROR_COUNT=$(($ERROR_COUNT+$?))                                    # Cumulate Err.Counter
    if [ $ERROR_COUNT -ne 0 ] ; then sadm_writelog "Total Error Count at $ERROR_COUNT" ;fi

    set_dir "$SADM_PKG_DIR"        "775" "$SADM_USER" "$SADM_GROUP"     # set Priv SADMIN PKG Dir
    ERROR_COUNT=$(($ERROR_COUNT+$?))                                    # Cumulate Err.Counter
    if [ $ERROR_COUNT -ne 0 ] ; then sadm_writelog "Total Error Count at $ERROR_COUNT" ;fi

    set_dir "$SADM_SETUP_DIR"        "775" "$SADM_USER" "$SADM_GROUP"   # set Priv on setup Dir
    ERROR_COUNT=$(($ERROR_COUNT+$?))                                    # Cumulate Err.Counter
    if [ $ERROR_COUNT -ne 0 ] ; then sadm_writelog "Total Error Count at $ERROR_COUNT" ;fi

    set_dir "$SADM_SYS_DIR"       "0775" "$SADM_USER" "$SADM_GROUP"     # set Priv SADMIN SYS Dir
    ERROR_COUNT=$(($ERROR_COUNT+$?))                                    # Cumulate Err.Counter
    if [ $ERROR_COUNT -ne 0 ] ; then sadm_writelog "Total Error Count at $ERROR_COUNT" ;fi

    set_dir "$SADM_TMP_DIR"       "1777" "$SADM_USER" "$SADM_GROUP"     # set Priv SADMIN TMP Dir
    ERROR_COUNT=$(($ERROR_COUNT+$?))                                    # Cumulate Err.Counter
    if [ $ERROR_COUNT -ne 0 ] ; then sadm_writelog "Total Error Count at $ERROR_COUNT" ;fi

    set_dir "$SADM_USR_DIR"  "0775" "$SADM_USER" "$SADM_GROUP"          # set Priv User  Dir
    ERROR_COUNT=$(($ERROR_COUNT+$?))                                    # Cumulate Err.Counter
    if [ $ERROR_COUNT -ne 0 ] ; then sadm_writelog "Total Error Count at $ERROR_COUNT" ;fi

    set_dir "$SADM_UBIN_DIR" "0775" "$SADM_USER" "$SADM_GROUP"          # set Priv User bin Dir
    ERROR_COUNT=$(($ERROR_COUNT+$?))                                    # Cumulate Err.Counter
    if [ $ERROR_COUNT -ne 0 ] ; then sadm_writelog "Total Error Count at $ERROR_COUNT" ;fi

    set_dir "$SADM_ULIB_DIR" "0775" "$SADM_USER" "$SADM_GROUP"          # set Priv User lib Dir
    ERROR_COUNT=$(($ERROR_COUNT+$?))                                    # Cumulate Err.Counter
    if [ $ERROR_COUNT -ne 0 ] ; then sadm_writelog "Total Error Count at $ERROR_COUNT" ;fi

    set_dir "$SADM_UDOC_DIR" "0775" "$SADM_USER" "$SADM_GROUP"          # set Priv User Doc Dir
    ERROR_COUNT=$(($ERROR_COUNT+$?))                                    # Cumulate Err.Counter
    if [ $ERROR_COUNT -ne 0 ] ; then sadm_writelog "Total Error Count at $ERROR_COUNT" ;fi

    set_dir "$SADM_UMON_DIR" "0775" "$SADM_USER" "$SADM_GROUP"          # set SysMon Script User Dir
    ERROR_COUNT=$(($ERROR_COUNT+$?))                                    # Cumulate Err.Counter
    if [ $ERROR_COUNT -ne 0 ] ; then sadm_writelog "Total Error Count at $ERROR_COUNT" ;fi

    # Subdirectories of $SADMIN/dat
    set_dir "$SADM_NMON_DIR"      "0775" "$SADM_USER" "$SADM_GROUP"     # set Priv SADMIN NMON Dir
    ERROR_COUNT=$(($ERROR_COUNT+$?))                                    # Cumulate Err.Counter
    if [ $ERROR_COUNT -ne 0 ] ; then sadm_writelog "Total Error Count at $ERROR_COUNT" ;fi

    set_dir "$SADM_DR_DIR"        "0775" "$SADM_USER" "$SADM_GROUP"     # set Disaster Recovery Dir
    ERROR_COUNT=$(($ERROR_COUNT+$?))                                    # Cumulate Err.Counter
    if [ $ERROR_COUNT -ne 0 ] ; then sadm_writelog "Total Error Count at $ERROR_COUNT" ;fi

    set_dir "$SADM_RCH_DIR"       "0775" "$SADM_USER" "$SADM_GROUP"     # set SADMIN RCH Dir
    ERROR_COUNT=$(($ERROR_COUNT+$?))                                    # Cumulate Err.Counter
    if [ $ERROR_COUNT -ne 0 ] ; then sadm_writelog "Total Error Count at $ERROR_COUNT" ;fi

    set_dir "$SADM_DBB_DIR"       "0775" "$SADM_USER" "$SADM_GROUP"     # Database Backup Dir
    ERROR_COUNT=$(($ERROR_COUNT+$?))                                    # Cumulate Err.Counter
    if [ $ERROR_COUNT -ne 0 ] ; then sadm_writelog "Total Error Count at $ERROR_COUNT" ;fi

    set_dir "$SADM_NET_DIR"       "0775" "$SADM_USER" "$SADM_GROUP"     # set SADMIN Network Dir
    ERROR_COUNT=$(($ERROR_COUNT+$?))                                    # Cumulate Err.Counter
    if [ $ERROR_COUNT -ne 0 ] ; then sadm_writelog "Total Error Count at $ERROR_COUNT" ;fi

    # $SADM_BASE_DIR is a filesystem - Put back lost+found to root
    if [ -d "$SADM_BASE_DIR/lost+found" ]
        then sadm_writelog "${SADM_TEN_DASH}"
             if [ "$(sadm_get_ostype)" = "AIX" ]
                then sadm_writelog "chown root:system $SADM_BASE_DIR/lost+found"   # Special Privilege
                     chown root:system $SADM_BASE_DIR/lost+found >/dev/null 2>&1 # Lost+Found Priv
                else sadm_writelog "chown root:root $SADM_BASE_DIR/lost+found"     # Special Privilege
                     chown root:root   $SADM_BASE_DIR/lost+found >/dev/null 2>&1 # Lost+Found Priv
             fi
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "OK"
                     sadm_writelog "Total Error Count at $ERROR_COUNT"
             fi
    fi


    # Remove Directory that should only be there on the SADMIN Server not the client.
    if [ "$(sadm_get_fqdn)" != "$SADM_SERVER" ]
       then sadm_writelog "${SADM_TEN_DASH}"
            sadm_writelog "Remove useless Directories on client (if any) ..."
            #
            # Remove Database Backup Directory on SADMIN Client if it exist
            if [ -d "$SADM_DBB_DIR" ]
                then sadm_writelog "Directory $SADM_DBB_DIR should exist only on SADMIN server."
                     sadm_writelog "I am deleting it now."
                     rm -fr $SADM_DBB_DIR
            fi
            # Remove Network Scan Directory on SADMIN Client if it exist
            if [ -d "$SADM_NET_DIR" ]
                then sadm_writelog "Directory $SADM_NET_DIR should exist only on SADMIN server."
                     sadm_writelog "I am deleting it now."
                     rm -fr $SADM_NET_DIR
            fi
            # Remove Web Site Directory on SADMIN Client if it exist
            if [ -d "$SADM_WWW_DIR" ]
                then sadm_writelog "Directory $SADM_WWW_DIR should exist only on SADMIN server."
                     sadm_writelog "I am deleting it now."
                     rm -fr $SADM_WWW_DIR
            fi
            sadm_writelog "${SADM_TEN_DASH}"
    fi

    return $ERROR_COUNT
}


# --------------------------------------------------------------------------------------------------
#                               General Files Housekeeping Function
# --------------------------------------------------------------------------------------------------
file_housekeeping()
{
    sadm_writelog " "
    sadm_writelog " "
    sadm_writelog " "
    sadm_writelog "$SADM_80_DASH"
    sadm_writelog "CLIENT FILES HOUSEKEEPING STARTING"
    sadm_writelog " "


    # Remove files that should only be there on the SADMIN Server not the client.
    if [ "$(sadm_get_fqdn)" != "$SADM_SERVER" ]
       then sadm_writelog "${SADM_TEN_DASH}"
            sadm_writelog "Remove useless files on client (if any) ..."
            #
            afile="$SADM_WWW_LIB_DIR/.crontab.txt"
            if [ -f $afile ] ; then rm -f $afile >/dev/null 2>&1 ; fi
            #
            afile="$SADM_CFG_DIR/.dbpass"
            if [ -f $afile ] ; then rm -f $afile >/dev/null 2>&1 ; fi
            #
            afile="$SADM_CFG_DIR/.alert_history.seq"
            if [ -f $afile ] ; then rm -f $afile >/dev/null 2>&1 ; fi
            #
            afile="$SADM_CFG_DIR/alert_history.seq"
            if [ -f $afile ] ; then rm -f $afile >/dev/null 2>&1 ; fi
            #
            afile="$SADM_CFG_DIR/.alert_history.txt"
            if [ -f $afile ] ; then rm -f $afile >/dev/null 2>&1 ; fi
            #
            afile="$SADM_CFG_DIR/alert_history.txt"
            if [ -f $afile ] ; then rm -f $afile >/dev/null 2>&1 ; fi
    fi

    # Make sure crontab for SADMIN client have proper permission and owner
    afile="/etc/cron.d/sadm_client"
    if [ -f "$afile" ]
        then sadm_writelog "${SADM_TEN_DASH}"
             sadm_writelog "Make sure crontab for SADMIN client have proper permission and owner"
             sadm_writelog "chmod 0644 $afile"
             chmod 0644 $afile
             sadm_writelog "chown root:root $afile"
             chown root:root $afile
             lsline=`ls -l $afile`
             sadm_writelog "$lsline"
    fi

    # Make sure crontab for SADMIN server have proper permission and owner
    afile="/etc/cron.d/sadm_server"
    if [ -f "$afile" ]
        then sadm_writelog "${SADM_TEN_DASH}"
             sadm_writelog "Make sure crontab for SADMIN server have proper permission and owner"
             sadm_writelog "chmod 0644 $afile"
             chmod 0644 $afile
             sadm_writelog "chown root:root $afile"
             chown root:root $afile
             lsline=`ls -l $afile`
             sadm_writelog "$lsline"
    fi

    # Make sure crontab for O/S Update have proper permission and owner
    afile="/etc/cron.d/sadm_osupdate"
    if [ -f "$afile" ]
        then sadm_writelog "${SADM_TEN_DASH}"
             sadm_writelog "Make sure crontab for O/S Update have proper permission and owner"
             sadm_writelog "chmod 0644 $afile"
             chmod 0644 $afile
             sadm_writelog "chown root:root $afile"
             chown root:root $afile
             lsline=`ls -l $afile`
             sadm_writelog "$lsline"
    fi


    # Set Owner and Permission for Readme file
    if [ -f ${SADM_BASE_DIR}/README.md ]
        then sadm_writelog "chmod 0644 ${SADM_BASE_DIR}/README.md"
             chmod 664 ${SADM_BASE_DIR}/README.md
             chown ${SADM_USER}:${SADM_GROUP} ${SADM_BASE_DIR}/README.md
             lsline=`ls -l ${SADM_BASE_DIR}/README.md`
             sadm_writelog "$lsline"
    fi

    # Set Owner and Permission for license file
    if [ -f ${SADM_BASE_DIR}/LICENSE ]
        then sadm_writelog "chmod 0644 ${SADM_BASE_DIR}/LICENSE"
             chmod 664 ${SADM_BASE_DIR}/LICENSE
             chown ${SADM_USER}:${SADM_GROUP} ${SADM_BASE_DIR}/LICENSE
             lsline=`ls -l ${SADM_BASE_DIR}/LICENSE`
             sadm_writelog "$lsline"
    fi
    sadm_writelog "${SADM_TEN_DASH}"
    sadm_writelog " "

    # Make sure DAT Directory $SADM_DAT_DIR Directory files is own by sadmin
    if [ -d "$SADM_DAT_DIR" ]
        then sadm_writelog "${SADM_TEN_DASH}"
             sadm_writelog "find $SADM_DAT_DIR -type f -exec chown ${SADM_USER}:${SADM_GROUP} {} \;"
             find $SADM_DAT_DIR -type f -exec chown ${SADM_USER}:${SADM_GROUP} {} \; >/dev/null 2>&1
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "OK"
                     if [ $ERROR_COUNT -ne 0 ] ;then sadm_writelog "Total Error at $ERROR_COUNT" ;fi
             fi
             sadm_writelog "find $SADM_DAT_DIR -type f -exec chmod 664 {} \;"
             find $SADM_DAT_DIR -type f -exec chmod 664 {} \; >/dev/null 2>&1
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "OK"
                     if [ $ERROR_COUNT -ne 0 ] ;then sadm_writelog "Total Error at $ERROR_COUNT" ;fi
             fi
    fi

    # Make sure LOG Directory $SADM_LOG_DIR Directory files is own by sadmin
    if [ -d "$SADM_LOG_DIR" ]
        then sadm_writelog "${SADM_TEN_DASH}"
             sadm_writelog "find $SADM_LOG_DIR -type f -exec chown ${SADM_USER}:${SADM_GROUP} {} \;"
             find $SADM_LOG_DIR -type f -exec chown ${SADM_USER}:${SADM_GROUP} {} \; >/dev/null 2>&1
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "OK"
                     if [ $ERROR_COUNT -ne 0 ] ;then sadm_writelog "Total Error at $ERROR_COUNT" ;fi
             fi
             sadm_writelog "find $SADM_LOG_DIR -type f -exec chmod 664 {} \;"
             find $SADM_LOG_DIR -type f -exec chmod 664 {} \; >/dev/null 2>&1
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "OK"
                     if [ $ERROR_COUNT -ne 0 ] ;then sadm_writelog "Total Error at $ERROR_COUNT" ;fi
             fi
    fi

    # Make sure User (Use for Development) Directory have proper permission
    if [ -d "${SADM_USR_DIR}" ]
        then sadm_writelog "${SADM_TEN_DASH}"
             sadm_writelog "find ${SADM_USR_DIR} -type f -exec chown ${SADM_USER}:${SADM_GROUP} {} \;"
             find ${SADM_USR_DIR} -type f -exec chown ${SADM_USER}:${SADM_GROUP} {} \; >/dev/null 2>&1
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "OK"
                     if [ $ERROR_COUNT -ne 0 ] ;then sadm_writelog "Total Error at $ERROR_COUNT" ;fi
             fi
             sadm_writelog "find ${SADM_USR_DIR} -type f -exec chmod 664 {} \;"
             find ${SADM_USR_DIR} -type f -exec chmod 664 {} \; >/dev/null 2>&1
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "OK"
                     if [ $ERROR_COUNT -ne 0 ] ;then sadm_writelog "Total Error at $ERROR_COUNT" ;fi
             fi
             sadm_writelog "find ${SADM_UBIN_DIR} -type f -exec chmod 775 {} \;"
             find ${SADM_UBIN_DIR} -type f -exec chmod 775 {} \; >/dev/null 2>&1
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "OK"
                     if [ $ERROR_COUNT -ne 0 ] ;then sadm_writelog "Total Error at $ERROR_COUNT" ;fi
             fi
             sadm_writelog "find ${SADM_UMON_DIR} -type f -exec chmod 775 {} \;"
             find ${SADM_UMON_DIR} -type f -exec chmod 775 {} \; >/dev/null 2>&1
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "OK"
                     if [ $ERROR_COUNT -ne 0 ] ;then sadm_writelog "Total Error at $ERROR_COUNT" ;fi
             fi
    fi


    # Reset privilege on SADMIN SYS Directory files
    if [ -d "$SADM_CFG_DIR" ]
        then sadm_writelog "${SADM_TEN_DASH}"
             sadm_writelog "find $SADM_CFG_DIR -type f -exec chmod -R 664 {} \;" # Change Files Priv
             find $SADM_CFG_DIR -type f -exec chmod -R 664 {} \; >/dev/null 2>&1 # Change Files Priv
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "OK"
                     if [ $ERROR_COUNT -ne 0 ] ;then sadm_writelog "Total Error at $ERROR_COUNT" ;fi
             fi
             sadm_writelog "find $SADM_CFG_DIR -type f -exec chown ${SADM_USER}:${SADM_GROUP} {} \;"
             find $SADM_CFG_DIR -type f -exec chown ${SADM_USER}:${SADM_GROUP} {} \; >/dev/null 2>&1
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "OK"
                     if [ $ERROR_COUNT -ne 0 ] ;then sadm_writelog "Total Error at $ERROR_COUNT" ;fi
             fi
    fi

    # Reset privilege on SADMIN SYS Directory files
    if [ -d "$SADM_SYS_DIR" ]
        then sadm_writelog "${SADM_TEN_DASH}"
             sadm_writelog "find $SADM_SYS_DIR -type f -exec chmod -R 774 {} \;" # Change Files Priv
             find $SADM_SYS_DIR -type f -exec chmod -R 774 {} \; >/dev/null 2>&1 # Change Files Priv
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "OK"
                     if [ $ERROR_COUNT -ne 0 ] ;then sadm_writelog "Total Error at $ERROR_COUNT" ;fi
             fi
             sadm_writelog "find $SADM_SYS_DIR -type f -exec chown ${SADM_USER}:${SADM_GROUP} {} \;"
             find $SADM_SYS_DIR -type f -exec chown ${SADM_USER}:${SADM_GROUP} {} \; >/dev/null 2>&1
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "OK"
                     if [ $ERROR_COUNT -ne 0 ] ;then sadm_writelog "Total Error at $ERROR_COUNT" ;fi
             fi
    fi

    # Reset privilege on SADMIN Bin Directory files
    if [ -d "$SADM_BIN_DIR" ]
        then sadm_writelog "${SADM_TEN_DASH}"
             sadm_writelog "find $SADM_BIN_DIR -type f -exec chmod -R 770 {} \;"       # Change Files Privilege
             find $SADM_BIN_DIR -type f -exec chmod -R 775 {} \; >/dev/null 2>&1     # Change Files Privilege
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "OK"
                     if [ $ERROR_COUNT -ne 0 ] ;then sadm_writelog "Total Error at $ERROR_COUNT" ;fi
             fi
             sadm_writelog "find $SADM_BIN_DIR -type f -exec chown ${SADM_USER}:${SADM_GROUP} {} \;"
             find $SADM_BIN_DIR -type f -exec chown ${SADM_USER}:${SADM_GROUP} {} \; >/dev/null 2>&1
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "OK"
                     if [ $ERROR_COUNT -ne 0 ] ;then sadm_writelog "Total Error at $ERROR_COUNT" ;fi
             fi
    fi

    # Reset privilege on SADMIN Bin Directory files
    if [ -d "$SADM_LIB_DIR" ]
        then sadm_writelog "${SADM_TEN_DASH}"
             sadm_writelog "find $SADM_LIB_DIR -type f -exec chmod -R 770 {} \;"
             find $SADM_LIB_DIR -type f -exec chmod -R 774 {} \; >/dev/null 2>&1
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "OK"
                     if [ $ERROR_COUNT -ne 0 ] ;then sadm_writelog "Total Error at $ERROR_COUNT" ;fi
             fi
             sadm_writelog "find $SADM_LIB_DIR -type f -exec chown ${SADM_USER}:${SADM_GROUP} {} \;"
             find $SADM_LIB_DIR -type f -exec chown ${SADM_USER}:${SADM_GROUP} {} \; >/dev/null 2>&1
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "OK"
                     if [ $ERROR_COUNT -ne 0 ] ;then sadm_writelog "Total Error at $ERROR_COUNT" ;fi
             fi
    fi


    # Reset privilege on SADMIN PKG Directory files
    if [ -d "$SADM_PKG_DIR" ]
        then sadm_writelog "${SADM_TEN_DASH}"
             sadm_writelog "find $SADM_PKG_DIR -exec chmod -R 755 {} \;"
             find $SADM_PKG_DIR -exec chmod -R 775 {} \; >/dev/null 2>&1
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "OK"
                     if [ $ERROR_COUNT -ne 0 ] ;then sadm_writelog "Total Error at $ERROR_COUNT" ;fi
             fi
             sadm_writelog "find $SADM_PKG_DIR -exec chown ${SADM_USER}:${SADM_GROUP} {} \;"
             find $SADM_PKG_DIR -exec chown ${SADM_USER}:${SADM_GROUP} {} \; >/dev/null 2>&1
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "OK"
                     if [ $ERROR_COUNT -ne 0 ] ;then sadm_writelog "Total Error at $ERROR_COUNT" ;fi
             fi
    fi


    # Remove files older than 7 days in SADMIN TEMP Directory
    if [ -d "$SADM_TMP_DIR" ]
        then sadm_writelog "${SADM_TEN_DASH}"
             sadm_writelog "find $SADM_TMP_DIR  -type f -mtime +7 -exec rm -f {} \;"
             find $SADM_TMP_DIR  -type f -mtime +7 -exec ls -l {} \; | tee -a $SADM_LOG
             find $SADM_TMP_DIR  -type f -mtime +7 -exec rm -f {} \; >/dev/null 2>&1
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "OK"
                     if [ $ERROR_COUNT -ne 0 ] ;then sadm_writelog "Total Error at $ERROR_COUNT" ;fi
             fi
             sadm_writelog "${SADM_TEN_DASH}"
             sadm_writelog "Delete pid files once a day - This prevent script not to run"
             sadm_writelog "find $SADM_TMP_DIR  -type f -name '*.pid' -exec rm -f {} \;"
             find $SADM_TMP_DIR  -type f -name "*.pid" -exec ls -l {} \; | tee -a $SADM_LOG
             find $SADM_TMP_DIR  -type f -name "*.pid" -exec rm -f {} \; >/dev/null 2>&1
    fi

    # Remove *.rch (Return Code History) files older than ${SADM_RCH_KEEPDAYS} days in SADMIN/DAT/RCH Dir.
    if [ -d "${SADM_RCH_DIR}" ]
        then sadm_writelog "${SADM_TEN_DASH}"
             sadm_writelog "You have chosen to keep *.rch files for ${SADM_RCH_KEEPDAYS} days (sadmin.cfg)."
             sadm_writelog "Find any *.rch file older than ${SADM_RCH_KEEPDAYS} days in ${SADM_RCH_DIR} and delete them"
             sadm_writelog "List of rch file that will be deleted"
             find ${SADM_RCH_DIR} -type f -mtime +${SADM_RCH_KEEPDAYS} -name "*.rch" -exec ls -l {} \; | tee -a $SADM_LOG
             sadm_writelog "find ${SADM_RCH_DIR} -type f -mtime +${SADM_RCH_KEEPDAYS} -name '*.rch' -exec rm -f {} \;"
             find ${SADM_RCH_DIR} -type f -mtime +${SADM_RCH_KEEPDAYS} -name "*.rch" -exec rm -f {} \; | tee -a $SADM_LOG
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "OK"
                     if [ $ERROR_COUNT -ne 0 ] ;then sadm_writelog "Total Error at $ERROR_COUNT" ;fi
             fi
    fi

    # Remove any *.log in SADMIN LOG Directory older than ${SADM_LOG_KEEPDAYS} days
    if [ -d "${SADM_LOG_DIR}" ]
        then sadm_writelog "${SADM_TEN_DASH}"
             sadm_writelog "You have chosen to keep *.log files for ${SADM_LOG_KEEPDAYS} days (sadmin.cfg)."
             sadm_writelog "Find any *.log file older than ${SADM_LOG_KEEPDAYS} days in ${SADM_LOG_DIR} and delete them"
             sadm_writelog "List of log file that will be deleted"
             find ${SADM_LOG_DIR} -type f -mtime +${SADM_LOG_KEEPDAYS} -name "*.log" -exec ls -l {} \; | tee -a $SADM_LOG
             sadm_writelog "find ${SADM_LOG_DIR} -type f -mtime +${SADM_LOG_KEEPDAYS} -name '*.log' -exec rm -f {} \;"
             find ${SADM_LOG_DIR} -type f -mtime +${SADM_LOG_KEEPDAYS} -name "*.log" -exec rm -f {} \; | tee -a $SADM_LOG
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "OK"
                     if [ $ERROR_COUNT -ne 0 ] ;then sadm_writelog "Total Error at $ERROR_COUNT" ;fi
             fi
    fi

    # Delete old nmon files - As defined in the sadmin.cfg file
    if [ -d "${SADM_NMON_DIR}" ]
        then sadm_writelog "${SADM_TEN_DASH}"
             sadm_writelog "You have chosen to keep *.nmon files for $SADM_NMON_KEEPDAYS days (sadmin.cfg)."
             sadm_writelog "List of nmon file that will be deleted"
             sadm_writelog "find $SADM_NMON_DIR -mtime +${SADM_NMON_KEEPDAYS} -type f -name *.nmon -exec ls -l {} \;"
             find $SADM_NMON_DIR -mtime +${SADM_NMON_KEEPDAYS} -type f -name "*.nmon" -exec ls -l {} \; >> $SADM_LOG 2>&1
             sadm_writelog "find $SADM_NMON_DIR -mtime +${SADM_NMON_KEEPDAYS} -type f -name '*.nmon' -exec rm {} \;"
             find $SADM_NMON_DIR -mtime +${SADM_NMON_KEEPDAYS} -type f -name "*.nmon" -exec rm {} \; >/dev/null 2>&1
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "OK"
                     if [ $ERROR_COUNT -ne 0 ] ;then sadm_writelog "Total Error at $ERROR_COUNT" ;fi
             fi
    fi

    return $ERROR_COUNT
}


# --------------------------------------------------------------------------------------------------
#                                Script Start HERE
# --------------------------------------------------------------------------------------------------

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

    sadm_start                                                          # Init Env Dir & RC/Log File
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if Problem

    # If current user is not 'root', exit to O/S with error code 1 (Optional)
    if ! [ $(id -u) -eq 0 ]                                             # If Cur. user is not root
        then sadm_writelog "Script can only be run by the 'root' user"  # Advise User Message
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S with Error
    fi

    # Check if 'sadmin' group exist - If not create it.
    grep "^${SADM_GROUP}:"  /etc/group >/dev/null 2>&1                  # $SADMIN Group Defined ?
    if [ $? -ne 0 ]                                                     # SADM_GROUP not Defined
        then sadm_writelog "Group ${SADM_GROUP} not present"            # Advise user will create
             sadm_writelog "Create group or change 'SADM_GROUP' value in $SADMIN/sadmin.cfg"
             #sadm_writelog "Creating the ${SADM_GROUP} group"           # Advise user will create
             #groupadd ${SADM_GROUP}                                     # Create SADM_GROUP
             #if [ $? -ne 0 ]                                            # Error creating Group
             #   then sadm_writelog "Error when creating group ${SADM_GROUP}"
                     sadm_writelog "Process Aborted"                    # Abort got be created
                     sadm_stop 1                                        # Terminate Gracefully
             #fi
    fi

    # Check is 'sadmin' user exist user - if not create it and make it part of 'sadmin' group.
    grep "^${SADM_USER}:" /etc/passwd >/dev/null 2>&1                   # $SADMIN User Defined ?
    if [ $? -ne 0 ]                                                     # NO Not There
        then sadm_writelog "User $SADM_USER not present"                # usr in sadmin.cfg not found
             sadm_writelog "Create user or change 'SADM_USER' value in $SADMIN/sadmin.cfg"
             #sadm_writelog "The user will now be created"               # Advise user will create
             #useradd -d '/sadmin' -c 'SADMIN user' -g $SADM_GROUP -e '' $SADM_USER
             #if [ $? -ne 0 ]                                            # Error creating user
             #   then sadm_writelog "Error when creating user ${SADM_USER}"
                     sadm_writelog "Process Aborted"                    # Abort got be created
                     sadm_stop 1                                        # Terminate Gracefully
             #fi
    fi

    #sadm_writelog "FQDN = $(sadm_get_fqdn) - SADM_SERVER = $SADM_SERVER"
    dir_housekeeping                                                    # Do Dir HouseKeeping
    DIR_ERROR=$?                                                        # ReturnCode = Nb. of Errors
    file_housekeeping                                                   # Do File HouseKeeping
    FILE_ERROR=$?                                                       # ReturnCode = Nb. of Errors
    check_sadmin_account                                                # Check sadmin Acc. if Lock
    ACC_ERROR=$?                                                        # Return 1 if Locked 

    SADM_EXIT_CODE=$(($DIR_ERROR+$FILE_ERROR+$ACC_ERROR))               # Error= DIR+File+Lock Func.
    sadm_stop $SADM_EXIT_CODE                                           # Close/Trim Log & Del PID
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
