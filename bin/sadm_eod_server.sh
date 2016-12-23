#! /usr/bin/env sh
# --------------------------------------------------------------------------------------------------
#   Author   :  Jacques Duplessis
#   Title    :  sadm_eod_server.sh
#   Synopsis :  This script must be run once a day early in the morning, so it is finish when
#               you arrive at work.
#               It run multiple script that rsync stat. and info file from client to this server
#   Version  :  1.0
#   Date     :  11 December 2016
#   Requires :  sh
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
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPTE LE ^C
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
SADM_VER='1.0'                             ; export SADM_VER            # This Script Version
SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1` ; export SADM_INST           # Script name without ext.
SADM_TPID="$$"                             ; export SADM_TPID           # Script PID
SADM_EXIT_CODE=0                           ; export SADM_EXIT_CODE      # Script Error Return Code
SADM_BASE_DIR=${SADMIN:="/sadmin"}         ; export SADM_BASE_DIR       # SADMIN Root Base Directory
SADM_LOG_TYPE="B"                          ; export SADM_LOG_TYPE       # 4Logger S=Scr L=Log B=Both
SADM_LOG_APPEND="N"                        ; export SADM_LOG_APPEND     # Append to Existing Log ?
SADM_MULTIPLE_EXEC="N"                     ; export SADM_MULTIPLE_EXEC  # Run many copy at same time

# --------------------------------------------------------------------------------------------------
# Define SADMIN Tool Library location and Load them in memory, so they are ready to be used
# --------------------------------------------------------------------------------------------------
[ -f ${SADM_BASE_DIR}/lib/sadm_lib_std.sh ]    && . ${SADM_BASE_DIR}/lib/sadm_lib_std.sh     
[ -f ${SADM_BASE_DIR}/lib/sadm_lib_server.sh ] && . ${SADM_BASE_DIR}/lib/sadm_lib_server.sh  

#
# SADM CONFIG FILE VARIABLES (Values defined here Will be overrridden by SADM CONFIG FILE Content)
#SADM_MAIL_ADDR="your_email@domain.com"      ; export ADM_MAIL_ADDR      # Default is in sadmin.cfg
SADM_MAIL_TYPE=1                            ; export SADM_MAIL_TYPE     # 0=No 1=Err 2=Succes 3=All
#SADM_CIE_NAME="Your Company Name"           ; export SADM_CIE_NAME      # Company Name
#SADM_USER="sadmin"                          ; export SADM_USER          # sadmin user account
#SADM_GROUP="sadmin"                         ; export SADM_GROUP         # sadmin group account
#SADM_WWW_USER="apache"                      ; export SADM_WWW_USER      # /sadmin/www owner 
#SADM_WWW_GROUP="apache"                     ; export SADM_WWW_GROUP     # /sadmin/www group
#SADM_MAX_LOGLINE=5000                       ; export SADM_MAX_LOGLINE   # Max Nb. Lines in LOG )
#SADM_MAX_RCLINE=100                         ; export SADM_MAX_RCLINE    # Max Nb. Lines in RCH file
#SADM_NMON_KEEPDAYS=60                       ; export SADM_NMON_KEEPDAYS # Days to keep old *.nmon
#SADM_SAR_KEEPDAYS=60                        ; export SADM_SAR_KEEPDAYS  # Days to keep old *.sar
#SADM_RCH_KEEPDAYS=60                        ; export SADM_RCH_KEEPDAYS  # Days to keep old *.rch
#SADM_LOG_KEEPDAYS=60                        ; export SADM_LOG_KEEPDAYS  # Days to keep old *.log
#SADM_PGUSER="postgres"                      ; export SADM_PGUSER        # PostGres User Name
#SADM_PGGROUP="postgres"                     ; export SADM_PGGROUP       # PostGres Group Name
#SADM_PGDB="sadmin"                          ; export SADM_PGDB          # PostGres DataBase Name
#SADM_PGSCHEMA="sadm_schema"                 ; export SADM_PGSCHEMA      # PostGres DataBase Schema
#SADM_PGHOST="sadmin.maison.ca"              ; export SADM_PGHOST        # PostGres DataBase Host
#SADM_PGPORT=5432                            ; export SADM_PGPORT        # PostGres Listening Port
#SADM_RW_PGUSER=""                           ; export SADM_RW_PGUSER     # Postgres Read/Write User 
#SADM_RW_PGPWD=""                            ; export SADM_RW_PGPWD      # PostGres Read/Write Passwd
#SADM_RO_PGUSER=""                           ; export SADM_RO_PGUSER     # Postgres Read Only User 
#SADM_RO_PGPWD=""                            ; export SADM_RO_PGPWD      # PostGres Read Only Passwd
#SADM_SERVER=""                              ; export SADM_SERVER        # Server FQN Name
#SADM_DOMAIN=""                              ; export SADM_DOMAIN        # Default Domain Name

#===================================================================================================
#






# --------------------------------------------------------------------------------------------------
#              V A R I A B L E S    L O C A L   T O     T H I S   S C R I P T
# --------------------------------------------------------------------------------------------------


# --------------------------------------------------------------------------------------------------
#                                Script Start HERE
# --------------------------------------------------------------------------------------------------
    sadm_start                                                          # Init Env Dir & RC/Log File
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if Problem 
    

    # Script Got to be run by root user
    if ! $(sadm_is_root)                                                # Only ROOT can run Script
        then sadm_writelog "This script must be run by the ROOT user"   # Advise User Message
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi


    # Once a day - Delete old rch and log files & chown+chmod on SADMIN Server
    SCMD="${SADM_BIN_DIR}/sadm_housekeeping_server.sh"
    sadm_writelog " " ; sadm_writelog "Running $SCMD ..."
    $SCMD >/dev/null 2>&1
    if [ $? -ne 0 ]                                                     # If Error was encounter
        then sadm_writelog "Error encounter in $SCMD"                   # Signal Error in Log 
             SADM_EXIT_CODE=1                                           # Script Global Error to 1
        else sadm_writelog "Script $SCMD terminated with success"       # Advise user it's OK
    fi

    # Collect from all servers Hardware info, Perf. Stat, ((nmon and sar)
    SCMD="${SADM_BIN_DIR}/sadm_daily_data_collection.sh "
    sadm_writelog " " ; sadm_writelog "Running $SCMD ..."
    $SCMD >/dev/null 2>&1
    if [ $? -ne 0 ]                                                     # If Error was encounter
        then sadm_writelog "Error encounter in $SCMD"                   # Signal Error in Log 
             SADM_EXIT_CODE=1                                           # Script Global Error to 1
        else sadm_writelog "Script $SCMD terminated with success"       # Advise user it's OK
    fi

    #  Daily DataBase Update with the Data Collected
    SCMD="${SADM_BIN_DIR}/sadm_daily_database_update.py"
    sadm_writelog " " ; sadm_writelog "Running $SCMD ..."
    $SCMD >/dev/null 2>&1
    if [ $? -ne 0 ]                                                     # If Error was encounter
        then sadm_writelog "Error encounter in $SCMD"                   # Signal Error in Log 
             SADM_EXIT_CODE=1                                           # Script Global Error to 1
        else sadm_writelog "Script $SCMD terminated with success"       # Advise user it's OK
    fi

    # Scan the Subnet Selected - Inventory IP Address Avail.
    SCMD="${SADM_BIN_DIR}/sadm_subnet_lookup.py"
    sadm_writelog " " ; sadm_writelog "Running $SCMD ..."
    $SCMD >/dev/null 2>&1
    if [ $? -ne 0 ]                                                     # If Error was encounter
        then sadm_writelog "Error encounter in $SCMD"                   # Signal Error in Log 
             SADM_EXIT_CODE=1                                           # Script Global Error to 1
        else sadm_writelog "Script $SCMD terminated with success"       # Advise user it's OK
    fi

    # Send email to SysAdmin Daily Reporting Summary of Script Activity
    #SCMD="${SADM_BIN_DIR}/sadm_rch_scr_summary.sh -m"
    #sadm_writelog " " ; sadm_writelog "Running $SCMD ..."
    #$SCMD >/dev/null 2>&1
    #if [ $? -ne 0 ]                                                     # If Error was encounter
    #    then sadm_writelog "Error encounter in $SCMD"                   # Signal Error in Log 
    #         SADM_EXIT_CODE=1                                           # Script Global Error to 1
    #    else sadm_writelog "Script $SCMD terminated with success"       # Advise user it's OK
    #fi

    # Go Write Log Footer - Send email if needed - Trim the Log - Update the Recode History File
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log 
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
