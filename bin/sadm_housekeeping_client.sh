#! /usr/bin/env sh
# --------------------------------------------------------------------------------------------------
#   Author   :  Jacques Duplessis
#   Title    :  sadm_housekeeping.sh
#   Synopsis : .Make some general housekeeping that we run once daily to get things running smoothly
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
# 1.7  Add /sadmin/jac in the housekeeping and change 600 to 644 for configuration file
#
# --------------------------------------------------------------------------------------------------
#
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
SADM_VER='1.7'                             ; export SADM_VER            # Script Version
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
ERROR_COUNT=0                               ; export ERROR_COUNT        # Error Counter
LIMIT_DAYS=14                               ; export LIMIT_DAYS         # RCH+LOG Delete after
DIR_ERROR=0                                 ; export DIR_ERROR          # ReturnCode = Nb. of Errors
FILE_ERROR=0                                ; export FILE_ERROR         # ReturnCode = Nb. of Errors



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
             sadm_writelog "Change $VAL_DIR owner to ${VAL_OWNER}.${VAL_GROUP}"
             chown ${VAL_OWNER}.${VAL_GROUP} $VAL_DIR 
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on 'chown' operation for $VALDIR"
                     ERROR_COUNT=$(($ERROR_COUNT+1))                    # Add Return Code To ErrCnt
                     RETURN_CODE=1                                      # Error = Return Code to 1
             fi
             ls -ld $VAL_DIR | tee -a $SADM_LOG
             if [ $RETURN_CODE = 0 ] ; then sadm_writelog "OK" ; fi
    fi
    return $RETURN_CODE    
}

# --------------------------------------------------------------------------------------------------
#                               General Directories Housekeeping Function
# --------------------------------------------------------------------------------------------------
dir_housekeeping()
{
    sadm_writelog "CLIENT DIRECTORIES HOUSEKEEPING STARTING"
    sadm_writelog " "
    ERROR_COUNT=0                                                       # Reset Error Count
    
      
    set_dir "$SADM_BASE_DIR"      "0775" "$SADM_USER" "$SADM_GROUP"     # set Priv SADMIN Base Dir
    ERROR_COUNT=$(($ERROR_COUNT+$?))                                    # Cumulate Err.Counter
    sadm_writelog "Total Error Count at $ERROR_COUNT"                   # Display Error Counter

    sadm_writelog "chmod g-s $SADM_BASE_DIR"                            # Show User what is done
    chmod g-s $SADM_BASE_DIR                                            # No Sticky Bit on Base Dir
    ERROR_COUNT=$(($ERROR_COUNT+$?))                                    # Cumulate Err.Counter
    sadm_writelog "Total Error Count at $ERROR_COUNT"                   # Display Error Counter

    set_dir "$SADM_BIN_DIR"       "0775" "$SADM_USER" "$SADM_GROUP"     # set Priv SADMIN BIN Dir
    ERROR_COUNT=$(($ERROR_COUNT+$?))                                    # Cumulate Err.Counter
    sadm_writelog "Total Error Count at $ERROR_COUNT"                   # Display Error Counter

    set_dir "$SADM_LIB_DIR"       "0775" "$SADM_USER" "$SADM_GROUP"     # set Priv SADMIN LIB Dir
    ERROR_COUNT=$(($ERROR_COUNT+$?))                                    # Cumulate Err.Counter
    sadm_writelog "Total Error Count at $ERROR_COUNT"                   # Display Error Counter

    set_dir "$SADM_TMP_DIR"       "1777" "$SADM_USER" "$SADM_GROUP"     # set Priv SADMIN TMP Dir
    ERROR_COUNT=$(($ERROR_COUNT+$?))                                    # Cumulate Err.Counter
    sadm_writelog "Total Error Count at $ERROR_COUNT"                   # Display Error Counter

    set_dir "$SADM_LOG_DIR"       "0775" "$SADM_USER" "$SADM_GROUP"     # set Priv SADMIN LOG Dir
    ERROR_COUNT=$(($ERROR_COUNT+$?))                                    # Cumulate Err.Counter
    sadm_writelog "Total Error Count at $ERROR_COUNT"                   # Display Error Counter

    set_dir "$SADM_CFG_DIR"       "0755" "$SADM_USER" "$SADM_GROUP"     # set Priv SADMIN CFG Dir
    ERROR_COUNT=$(($ERROR_COUNT+$?))                                    # Cumulate Err.Counter
    sadm_writelog "Total Error Count at $ERROR_COUNT"                   # Display Error Counter

    set_dir "$SADM_SYS_DIR"       "0775" "$SADM_USER" "$SADM_GROUP"     # set Priv SADMIN SYS Dir
    ERROR_COUNT=$(($ERROR_COUNT+$?))                                    # Cumulate Err.Counter
    sadm_writelog "Total Error Count at $ERROR_COUNT"                   # Display Error Counter

    set_dir "$SADM_DAT_DIR"       "0775" "$SADM_USER" "$SADM_GROUP"     # set Priv SADMIN DAT Dir
    ERROR_COUNT=$(($ERROR_COUNT+$?))                                    # Cumulate Err.Counter
    sadm_writelog "Total Error Count at $ERROR_COUNT"                   # Display Error Counter

    set_dir "$SADM_PKG_DIR"        "775" "$SADM_USER" "$SADM_GROUP"     # set Priv SADMIN PKG Dir
    ERROR_COUNT=$(($ERROR_COUNT+$?))                                    # Cumulate Err.Counter
    sadm_writelog "Total Error Count at $ERROR_COUNT"                   # Display Error Counter

    set_dir "$SADM_NMON_DIR"      "0775" "$SADM_USER" "$SADM_GROUP"     # set Priv SADMIN NMON Dir
    ERROR_COUNT=$(($ERROR_COUNT+$?))                                    # Cumulate Err.Counter
    sadm_writelog "Total Error Count at $ERROR_COUNT"                   # Display Error Counter

    set_dir "$SADM_DR_DIR"        "0775" "$SADM_USER" "$SADM_GROUP"     # set Priv SADMIN DR Dir
    ERROR_COUNT=$(($ERROR_COUNT+$?))                                    # Cumulate Err.Counter
    sadm_writelog "Total Error Count at $ERROR_COUNT"                   # Display Error Counter

    set_dir "$SADM_SAR_DIR"       "0775" "$SADM_USER" "$SADM_GROUP"     # set Priv SADMIN SAR Dir
    ERROR_COUNT=$(($ERROR_COUNT+$?))                                    # Cumulate Err.Counter
    sadm_writelog "Total Error Count at $ERROR_COUNT"                   # Display Error Counter

    set_dir "$SADM_RCH_DIR"       "0775" "$SADM_USER" "$SADM_GROUP"     # set Priv SADMIN RCH Dir
    ERROR_COUNT=$(($ERROR_COUNT+$?))                                    # Cumulate Err.Counter
    sadm_writelog "Total Error Count at $ERROR_COUNT"                   # Display Error Counter

    set_dir "$SADM_NET_DIR"       "0775" "$SADM_USER" "$SADM_GROUP"     # set Priv SADMIN RCH Dir
    ERROR_COUNT=$(($ERROR_COUNT+$?))                                    # Cumulate Err.Counter
    sadm_writelog "Total Error Count at $ERROR_COUNT"                   # Display Error Counter

    set_dir "$SADM_BASE_DIR/jac"  "0775" "$SADM_USER" "$SADM_GROUP"     # set Priv SADMIN RCH Dir
    ERROR_COUNT=$(($ERROR_COUNT+$?))                                    # Cumulate Err.Counter
    sadm_writelog "Total Error Count at $ERROR_COUNT"                   # Display Error Counter

    set_dir "$SADM_BASE_DIR/jac/bin" "0775" "$SADM_USER" "$SADM_GROUP"  # set Priv SADMIN RCH Dir
    ERROR_COUNT=$(($ERROR_COUNT+$?))                                    # Cumulate Err.Counter
    sadm_writelog "Total Error Count at $ERROR_COUNT"                   # Display Error Counter


    # $SADM_BASE_DIR is a filesystem - Put back lost+found to root
    if [ -d "$SADM_BASE_DIR/lost+found" ]
        then sadm_writelog "${SADM_TEN_DASH}"
             if [ "$(sadm_get_ostype)" = "AIX" ]
                then sadm_writelog "chown root.system $SADM_BASE_DIR/lost+found"   # Special Privilege
                     chown root.system $SADM_BASE_DIR/lost+found >/dev/null 2>&1 # Lost+Found Priv
                else sadm_writelog "chown root.root $SADM_BASE_DIR/lost+found"     # Special Privilege
                     chown root.root   $SADM_BASE_DIR/lost+found >/dev/null 2>&1 # Lost+Found Priv
             fi
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "OK"
                     sadm_writelog "Total Error Count at $ERROR_COUNT"
             fi
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
    sadm_writelog "CLIENT FILES HOUSEKEEPING STARTING"
    sadm_writelog " "
    sadm_writelog "${SADM_TEN_DASH}"


    # If we are not of the SADMIN Server, remove some server files
    if [ "$(sadm_get_fqdn)" != "$SADM_SERVER" ] 
       then sadm_writelog "Remove useless files on client"
            afile="$SADM_CFG_DIR/.crontab.txt"
            if [ -f $afile ] ; then rm -f $afile >/dev/null 2>&1 ; fi
            afile="$SADM_CFG_DIR/.pgpass"
            if [ -f $afile ] ; then rm -f $afile >/dev/null 2>&1 ; fi
            afile="$SADM_CFG_DIR/.release"
            if [ -f $afile ] ; then rm -f $afile >/dev/null 2>&1 ; fi
            afile="$SADM_CFG_DIR/holmes.cfg"
            if [ -f $afile ] ; then rm -f $afile >/dev/null 2>&1 ; fi
    fi


    # Make sure the configuration file is at 644
    sadm_writelog "chmod 0640 $SADM_CFG_FILE" 
    chmod 0640 $SADM_CFG_FILE
    ls -l $SADM_CFG_FILE | tee -a $SADM_LOG

    sadm_writelog "chmod 0640 $SADM_CFG_HIDDEN" 
    chmod 0640 $SADM_CFG_HIDDEN
    ls -l $SADM_CFG_HIDDEN | tee -a $SADM_LOG

    if [ -f $SADM_CFG_DIR/.crontab.txt ] 
        then sadm_writelog "chmod 0644 $SADM_CFG_DIR/.crontab.txt" 
             chmod 0644 $SADM_CFG_DIR/.crontab.txt
             ls -l $SADM_CFG_DIR/.crontab.txt | tee -a $SADM_LOG
    fi

    # Set Owner and Permission for Readme file
    if [ -f ${SADM_BASE_DIR}/README.md ]
        then chmod 644 ${SADM_BASE_DIR}/README.md
             chown ${SADM_USER}.${SADM_GROUP} ${SADM_BASE_DIR}/README.md
    fi

    # Make sure DAT Directory $SADM_DAT_DIR Directory files is own by sadmin
    if [ -d "$SADM_DAT_DIR" ]
        then sadm_writelog "${SADM_TEN_DASH}"
             sadm_writelog "find $SADM_DAT_DIR -type f -exec chown ${SADM_USER}.${SADM_GROUP} {} \;"
             find $SADM_DAT_DIR -type f -exec chown ${SADM_USER}.${SADM_GROUP} {} \; >/dev/null 2>&1 
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "OK"
                     sadm_writelog "Total Error Count at $ERROR_COUNT"
             fi
             sadm_writelog "find $SADM_DAT_DIR -type f -exec chmod 664 {} \;"
             find $SADM_DAT_DIR -type f -exec chmod 664 {} \; >/dev/null 2>&1 
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "OK"
                     sadm_writelog "Total Error Count at $ERROR_COUNT"
             fi
    fi

    # Make sure LOG Directory $SADM_LOG_DIR Directory files is own by sadmin
    if [ -d "$SADM_LOG_DIR" ]
        then sadm_writelog "${SADM_TEN_DASH}"
             sadm_writelog "find $SADM_LOG_DIR -type f -exec chown ${SADM_USER}.${SADM_GROUP} {} \;"
             find $SADM_LOG_DIR -type f -exec chown ${SADM_USER}.${SADM_GROUP} {} \; >/dev/null 2>&1 
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "OK"
                     sadm_writelog "Total Error Count at $ERROR_COUNT"
             fi
             sadm_writelog "find $SADM_LOG_DIR -type f -exec chmod 664 {} \;"
             find $SADM_LOG_DIR -type f -exec chmod 664 {} \; >/dev/null 2>&1 
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "OK"
                     sadm_writelog "Total Error Count at $ERROR_COUNT"
             fi
    fi

    # Make sure JAC (Use for Development) Directory have proper permission
    JACDIR="${SADM_BASE_DIR}/jac" 
    if [ -d "$JACDIR" ]
        then sadm_writelog "${SADM_TEN_DASH}"
             sadm_writelog "find $JACDIR -type f -exec chown ${SADM_USER}.${SADM_GROUP} {} \;"
             find $JACDIR -type f -exec chown ${SADM_USER}.${SADM_GROUP} {} \; >/dev/null 2>&1 
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "OK"
                     sadm_writelog "Total Error Count at $ERROR_COUNT"
             fi
             sadm_writelog "find $JACDIR -type f -exec chmod 664 {} \;"
             find $JACDIR -type f -exec chmod 775 {} \; >/dev/null 2>&1 
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "OK"
                     sadm_writelog "Total Error Count at $ERROR_COUNT"
             fi
    fi

             
    # Reset privilege on SADMIN SYS Directory files
    if [ -d "$SADM_SYS_DIR" ]
        then sadm_writelog "${SADM_TEN_DASH}"
             sadm_writelog "find $SADM_SYS_DIR -type f -exec chmod -R 774 {} \;"       # Change Files Privilege
             find $SADM_SYS_DIR -type f -exec chmod -R 774 {} \; >/dev/null 2>&1     # Change Files Privilege
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "OK"
                     sadm_writelog "Total Error Count at $ERROR_COUNT"
             fi
             sadm_writelog "find $SADM_SYS_DIR -type f -exec chown ${SADM_USER}.${SADM_GROUP} {} \;"
             find $SADM_SYS_DIR -type f -exec chown ${SADM_USER}.${SADM_GROUP} {} \; >/dev/null 2>&1 
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "OK"
                     sadm_writelog "Total Error Count at $ERROR_COUNT"
             fi
    fi
      
    # Reset privilege on SADMIN Bin Directory files
    if [ -d "$SADM_BIN_DIR" ]
        then sadm_writelog "${SADM_TEN_DASH}"
             sadm_writelog "find $SADM_BIN_DIR -type f -exec chmod -R 770 {} \;"       # Change Files Privilege
             find $SADM_BIN_DIR -type f -exec chmod -R 774 {} \; >/dev/null 2>&1     # Change Files Privilege
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "OK"
                     sadm_writelog "Total Error Count at $ERROR_COUNT"
             fi
             sadm_writelog "find $SADM_BIN_DIR -type f -exec chown ${SADM_USER}.${SADM_GROUP} {} \;"
             find $SADM_BIN_DIR -type f -exec chown ${SADM_USER}.${SADM_GROUP} {} \; >/dev/null 2>&1 
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "OK"
                     sadm_writelog "Total Error Count at $ERROR_COUNT"
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
                     sadm_writelog "Total Error Count at $ERROR_COUNT"
             fi
             sadm_writelog "find $SADM_LIB_DIR -type f -exec chown ${SADM_USER}.${SADM_GROUP} {} \;"
             find $SADM_LIB_DIR -type f -exec chown ${SADM_USER}.${SADM_GROUP} {} \; >/dev/null 2>&1 
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "OK"
                     sadm_writelog "Total Error Count at $ERROR_COUNT"
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
                     sadm_writelog "Total Error Count at $ERROR_COUNT"
             fi
             sadm_writelog "find $SADM_PKG_DIR -exec chown ${SADM_USER}.${SADM_GROUP} {} \;"
             find $SADM_PKG_DIR -exec chown ${SADM_USER}.${SADM_GROUP} {} \; >/dev/null 2>&1 
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "OK"
                     sadm_writelog "Total Error Count at $ERROR_COUNT"
             fi
    fi

    
    # Remove files older than 7 days in SADMIN TEMP Directory
    if [ -d "$SADM_TMP_DIR" ]
        then sadm_writelog "${SADM_TEN_DASH}"
             sadm_writelog "find $SADM_TMP_DIR -type f -mtime +7 -exec rm -f {} \;"
             find $SADM_TMP_DIR  -type f -mtime +7 -exec ls -l {} \; | tee -a $SADM_LOG
             sadm_writelog "find $SADM_TMP_DIR  -type f -mtime +7 -exec rm -f {} \;" 
             find $SADM_TMP_DIR  -type f -mtime +7 -exec rm -f {} \; >/dev/null 2>&1
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "OK"
                     sadm_writelog "Total Error Count at $ERROR_COUNT"
             fi
             sadm_writelog "${SADM_TEN_DASH}"
             sadm_writelog "Delete pid files once a day - To prevent cause script not to run"
             find $SADM_TMP_DIR  -type f -name "*.pid" -exec ls -l {} \; | tee -a $SADM_LOG
             sadm_writelog "find $SADM_TMP_DIR  -type f -name '*.pid' -exec rm -f {} \;" 
             find $SADM_TMP_DIR  -type f -name "*.pid" -exec rm -f {} \; >/dev/null 2>&1
    fi

    # Remove *.rch (Return Code History) files older than ${SADM_RCH_KEEPDAYS} days in SADMIN/DAT/RCH Dir.
    if [ -d "${SADM_RCH_DIR}" ]
        then sadm_writelog "${SADM_TEN_DASH}"
             sadm_writelog "Keep rch files for ${SADM_RCH_KEEPDAYS} days"
             sadm_writelog "Find any *.rch file older than ${SADM_RCH_KEEPDAYS} days in ${SADM_RCH_DIR} and delete them"
             find ${SADM_RCH_DIR} -type f -mtime +${SADM_RCH_KEEPDAYS} -name "*.rch" -exec ls -l {} \; | tee -a $SADM_LOG
             sadm_writelog "find ${SADM_RCH_DIR} -type f -mtime +${SADM_RCH_KEEPDAYS} -name '*.rch' -exec rm -f {} \;" 
             find ${SADM_RCH_DIR} -type f -mtime +${SADM_RCH_KEEPDAYS} -name "*.rch" -exec rm -f {} \; | tee -a $SADM_LOG
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "OK"
                     sadm_writelog "Total Error Count at $ERROR_COUNT"
             fi
    fi

    # Remove any *.log in SADMIN LOG Directory older than ${SADM_LOG_KEEPDAYS} days
    if [ -d "${SADM_LOG_DIR}" ]
        then sadm_writelog "${SADM_TEN_DASH}"
             sadm_writelog "Keep log files for ${SADM_LOG_KEEPDAYS} days"
             sadm_writelog "Find any *.log file older than ${SADM_LOG_KEEPDAYS} days in ${SADM_LOG_DIR} and delete them"
             find ${SADM_LOG_DIR} -type f -mtime +${SADM_LOG_KEEPDAYS} -name "*.log" -exec ls -l {} \; | tee -a $SADM_LOG
             sadm_writelog "find ${SADM_LOG_DIR} -type f -mtime +${SADM_LOG_KEEPDAYS} -name '*.log' -exec rm -f {} \;" 
             find ${SADM_LOG_DIR} -type f -mtime +${SADM_LOG_KEEPDAYS} -name "*.log" -exec rm -f {} \; | tee -a $SADM_LOG
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "OK"
                     sadm_writelog "Total Error Count at $ERROR_COUNT"
             fi
    fi

    # Delete old nmon files - As defined in the sadmin.cfg file
    if [ -d "${SADM_NMON_DIR}" ]
        then sadm_writelog "${SADM_TEN_DASH}"
             sadm_writelog "Keep nmon files for $SADM_NMON_KEEPDAYS days"
             sadm_writelog "List of nmon file that will be deleted"
             sadm_writelog "find $SADM_NMON_DIR -mtime +${SADM_NMON_KEEPDAYS} -type f -name *.nmon -exec ls -l {} \;"
             find $SADM_NMON_DIR -mtime +${SADM_NMON_KEEPDAYS} -type f -name "*.nmon" -exec ls -l {} \; >> $SADM_LOG 2>&1
             sadm_writelog "find $SADM_NMON_DIR -mtime +${SADM_NMON_KEEPDAYS} -type f -name '*.nmon' -exec rm {} \;" 
             find $SADM_NMON_DIR -mtime +${SADM_NMON_KEEPDAYS} -type f -name "*.nmon" -exec rm {} \; >/dev/null 2>&1
             if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "OK"
                     sadm_writelog "Total Error Count at $ERROR_COUNT"
             fi
    fi

    # Delete old sar files - As defined in the sadmin.cfg file
    if [ -d "${SADM_SAR_DIR}" ]
       then sadm_writelog "${SADM_TEN_DASH}"
            sadm_writelog "Keep sar files for $SADM_SAR_KEEPDAYS days"
            sadm_writelog "List of sar file that will be deleted"
            sadm_writelog "find $SADM_SAR_DIR -mtime +${SADM_SAR_KEEPDAYS} -type f -name *.sar -exec ls -l {} \;"
            find $SADM_SAR_DIR -mtime +${SADM_SAR_KEEPDAYS} -type f -name "*.sar" -exec ls -l {} \; >> $SADM_LOG 2>&1
            sadm_writelog "find $SADM_SAR_DIR -mtime +${SADM_SAR_KEEPDAYS} -type f -name '*.sar' -exec rm {} \;"
            find $SADM_SAR_DIR -mtime +${SADM_SAR_KEEPDAYS} -type f -name "*.sar" -exec rm {} \; >/dev/null 2>&1
            if [ $? -ne 0 ]
                then sadm_writelog "Error occured on the last operation."
                     ERROR_COUNT=$(($ERROR_COUNT+1))
                else sadm_writelog "OK"
                     sadm_writelog "Total Error Count at $ERROR_COUNT"
            fi
    fi

    return $ERROR_COUNT
}


# --------------------------------------------------------------------------------------------------
#                                Script Start HERE
# --------------------------------------------------------------------------------------------------
    sadm_start                                                          # Init SADM Env. RC/Log File

    # Script can be run only by root user
    if ! $(sadm_is_root)                                                # Only ROOT can run Script
        then sadm_writelog "Script must be run by ROOT user"            # Advise User Message
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi

    # Check if 'sadmin' group exist - If not create it.
    grep "^${SADM_GROUP}:"  /etc/group >/dev/null 2>&1                  # $SADMIN Group Defined ?
    if [ $? -ne 0 ]                                                     # SADM_GROUP not Defined
        then sadm_writelog "Group ${SADM_GROUP} not present"            # Advise user will create
             sadm_writelog "Creating the ${SADM_GROUP} group"           # Advise user will create
             groupadd ${SADM_GROUP}                                     # Create SADM_GROUP
             if [ $? -ne 0 ]                                            # Error creating Group 
                then sadm_writelog "Error when creating group ${SADM_GROUP}"
                     sadm_writelog "Process Aborted"                    # Abort got be created
                     sadm_stop 1                                        # Terminate Gracefully
             fi
    fi
    
    # Check is 'sadmin' user exist user - if not create it and make it part of 'sadmin' group.
    grep "^${SADM_USER}:" /etc/passwd >/dev/null 2>&1                   # $SADMIN User Defined ?
    if [ $? -ne 0 ]                                                     # NO Not There
        then sadm_writelog "User $SADM_USER not present"                # Advise user will create
             sadm_writelog "The user will now be created"               # Advise user will create
             useradd -d '/sadmin' -c 'SADMIN user' -g $SADM_GROUP -e '' $SADM_USER
             if [ $? -ne 0 ]                                            # Error creating user 
                then sadm_writelog "Error when creating user ${SADM_USER}"
                     sadm_writelog "Process Aborted"                    # Abort got be created
                     sadm_stop 1                                        # Terminate Gracefully
             fi
    fi
    
    dir_housekeeping                                                    # Do Dir HouseKeeping
    DIR_ERROR=$?                                                        # ReturnCode = Nb. of Errors
    
    file_housekeeping                                                   # Do File HouseKeeping
    FILE_ERROR=$?                                                       # ReturnCode = Nb. of Errors
    
    SADM_EXIT_CODE=$(($DIR_ERROR+$FILE_ERROR))                          # ExitCode = DIR+File Errors
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
    
