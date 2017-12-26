#!/usr/bin/env sh
# --------------------------------------------------------------------------------------------------
#   Author   :  Jacques Duplessis
#   Title    :  sadm_push_file.sh
#   Synopsis :  Use script to push file to all servers based on server type and O/S
#               
#   Version  :  1.0
#   Date     :  10 July 2015
#   Requires :  sh
# --------------------------------------------------------------------------------------------------
#
#set -x
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


#===================================================================================================
# If You want to use the SADMIN Libraries, you need to add this section at the top of your script
#   Please refer to the file $sadm_base_dir/lib/sadm_lib_std.txt for a description of each
#   variables and functions available to you when using the SADMIN functions Library
# --------------------------------------------------------------------------------------------------
# Global variables used by the SADMIN Libraries - Some influence the behavior of function in Library
# These variables need to be defined prior to load the SADMIN function Libraries
# --------------------------------------------------------------------------------------------------
SADM_PN=${0##*/}                           ; export SADM_PN             # Script name
SADM_VER='1.6'                             ; export SADM_VER            # Script Version
SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1` ; export SADM_INST           # Script name without ext.
SADM_TPID="$$"                             ; export SADM_TPID           # Script PID
SADM_EXIT_CODE=0                           ; export SADM_EXIT_CODE      # Script Exit Return Code
SADM_BASE_DIR=${SADMIN:="/sadmin"}         ; export SADM_BASE_DIR       # SADMIN Root Base Dir.
SADM_LOG_TYPE="B"                          ; export SADM_LOG_TYPE       # 4Logger S=Scr L=Log B=Both
SADM_LOG_APPEND="N"                        ; export SADM_LOG_APPEND     # Append to Existing Log ?
SADM_MULTIPLE_EXEC="N"                     ; export SADM_MULTIPLE_EXEC  # Run many copy at same time
[ -f ${SADM_BASE_DIR}/lib/sadmlib_std.sh ]    && . ${SADM_BASE_DIR}/lib/sadmlib_std.sh     
[ -f ${SADM_BASE_DIR}/lib/sadmlib_server.sh ] && . ${SADM_BASE_DIR}/lib/sadmlib_server.sh  

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
DEBUG_LEVEL=0                                   ; export DEBUG_LEVEL    # 0=NoDebug Higher=+Verbose
PN=${0##*/}                                     ; export PN             # Current Script name
VER='2.1'                                       ; export VER            # Program version
SYSADMIN="duplessis.jacques@gmail.com"          ; export SYSADMIN       # sysadmin email
DASH=`printf %100s |tr " " "="`                 ; export DASH           # 100 dashes line
INST=`echo "$PN" | awk -F\. '{ print $1 }'`     ; export INST           # Get Current script name
RC=0                                            ; export RC             # Set default Script Return Code
HOSTNAME=`hostname -s`                          ; export HOSTNAME       # Current Host name
OSNAME=`uname -s|tr '[:lower:]' '[:upper:]'`    ; export OSNAME         # Get OS Name (AIX or LINUX)
CUR_DATE=`date +"%Y_%m_%d"`                     ; export CUR_DATE       # Current Date
CUR_TIME=`date +"%H_%M_%S"`                     ; export CUR_TIME       # Current Time
#
GLOBAL_ERROR=0                                  ; export GLOBAL_ERROR   # Global Error Return Code
FILENAME="WILL BE ASKED"                        ; export FILENAME       # File name to copy 2 remote



# --------------------------------------------------------------------------------------------------
#                      Process Linux servers selected by the SQL
# --------------------------------------------------------------------------------------------------
process_linux_servers()
{
    if [ "$LINUX_UPDATE" = "N" ]
        then sadm_writelog "I Will process NO Linux Servers"
             return 0
    fi
    
    SQL1="SELECT srv_name, srv_ostype, srv_domain, srv_cat, srv_active from sadm.server  "
    MSINFO="Will process all Linux "
    case "$LINUX_TYPE" in
        d|D) MSINFO=`echo "$MSINFO Dev. servers " `
             SQL2="where srv_ostype = 'linux' and srv_active = True and srv_cat='Dev' "
             LINUX_TYPE="D"
             break
             ;;
        p|P) MSINFO=`echo "$MSINFO Prod. servers "` 
             SQL2="where srv_ostype = 'linux' and srv_active = True and srv_cat='Prod' "
             LINUX_TYPE="P"
             break
             ;;
        b|B) MSINFO=`echo "$MSINFO servers "` 
             SQL2="where srv_ostype = 'linux' and srv_active = True "
             LINUX_TYPE="B"
             break
             ;;
    esac
    sadm_writelog "$MSINFO"
    SQL3="order by srv_name; "
    SQL="${SQL1}${SQL2}${SQL3}"

    WAUTH="-u $SADM_RO_DBUSER  -p$SADM_RO_DBPWD "                       # Set Authentication String 
    CMDLINE="$SADM_MYSQL $WAUTH "                                       # Join MySQL with Authen.
    CMDLINE="$CMDLINE -h $SADM_DBHOST $SADM_DBNAME -N -e '$SQL' | tr '/\t/' '/,/'" # Build CmdLine
    if [ $DEBUG_LEVEL -gt 5 ] ; then sadm_writelog "$CMDLINE" ; fi      # Debug = Write command Line

    # Execute SQL to Update Server O/S Data
    $SADM_MYSQL $WAUTH -h $SADM_DBHOST $SADM_DBNAME -N -e "$SQL" | tr '/\t/' '/,/' >$SADM_TMP_FILE1

    while read wline
        do
        server_name=`  echo $wline|awk -F, '{ print $1 }'`
        server_os=`    echo $wline|awk -F, '{ print $2 }'`
        server_domain=`echo $wline|awk -F, '{ print $3 }'`
        server_type=`  echo $wline|awk -F, '{ print $4 }'`
        sadm_writelog "Processing Server : ${server_name}.${server_domain} ${server_os} ${server_type}"
        sadm_writelog "scp -q ${FILENAME} ${server_name}.${server_domain}:${FILENAME}"
        scp -q $FILENAME ${server_name}.${server_domain}:$FILENAME
        RC=$? ; sadm_writelog "Return Code is $RC" 
        if [ $RC -ne 0 ] 
            then sadm_writelog "Error ($RC) pushing file to ${server_name}.${server_domain}" 
                 sadm_writelog "Please correct the problem - Press [ENTER] to continue"
                 read dummy
        fi
        sadm_writelog "${DASH}"
        done < $SADM_TMP_FILE1
}


# --------------------------------------------------------------------------------------------------
#                      Process Linux servers selected by the SQL
# --------------------------------------------------------------------------------------------------
process_aix_servers()
{
    if [ "$AIX_UPDATE" = "N" ]
        then sadm_writelog "I Will process NO Aix Servers"
             return 0
    fi

    
    SQL1="SELECT srv_name, srv_ostype, srv_domain, srv_cat, srv_active from sadm.server  "
    MSINFO="Will process all Aix "
    case "$LINUX_TYPE" in
        d|D) MSINFO=`echo "$MSINFO Dev. servers " `
             SQL2="where srv_ostype = 'aix' and srv_active = True and srv_cat='Dev' "
             LINUX_TYPE="D"
             break
             ;;
        p|P) MSINFO=`echo "$MSINFO Prod. servers "` 
             SQL2="where srv_ostype = 'aix' and srv_active = True and srv_cat='Prod' "
             LINUX_TYPE="P"
             break
             ;;
        b|B) MSINFO=`echo "$MSINFO servers "` 
             SQL2="where srv_ostype = 'aix' and srv_active = True "
             LINUX_TYPE="B"
             break
             ;;
    esac
    sadm_writelog "$MSINFO"
    SQL3="order by srv_name; "
    SQL="${SQL1}${SQL2}${SQL3}"
    
    WAUTH="-u $SADM_RO_DBUSER  -p$SADM_RO_DBPWD "                       # Set Authentication String 
    CMDLINE="$SADM_MYSQL $WAUTH "                                       # Join MySQL with Authen.
    CMDLINE="$CMDLINE -h $SADM_DBHOST $SADM_DBNAME -N -e '$SQL' | tr '/\t/' '/,/'" # Build CmdLine
    if [ $DEBUG_LEVEL -gt 5 ] ; then sadm_writelog "$CMDLINE" ; fi      # Debug = Write command Line

    # Execute SQL to Update Server O/S Data
    $SADM_MYSQL $WAUTH -h $SADM_DBHOST $SADM_DBNAME -N -e "$SQL" | tr '/\t/' '/,/' >$SADM_TMP_FILE1

    while read wline
        do
        server_name=`  echo $wline|awk -F, '{ print $1 }'`
        server_os=`    echo $wline|awk -F, '{ print $2 }'`
        server_domain=`echo $wline|awk -F, '{ print $3 }'`
        server_type=`  echo $wline|awk -F, '{ print $4 }'`
        sadm_writelog "Processing Server : ${server_name}.${server_domain} ${server_os} ${server_type}"
        sadm_writelog "rcp ${FILENAME} ${server_name}.${server_domain}:${FILENAME}"
        rcp $FILENAME ${server_name}.${server_domain}:$FILENAME
        RC=$? ; sadm_writelog "Return Code is $RC" 
        if [ $RC -ne 0 ] 
            then sadm_writelog "Error ($RC) pushing file to ${server_name}.${server_domain}" 
                 sadm_writelog "Please correct the problem - Press [ENTER] to continue"
                 read dummy
        fi
        sadm_writelog "${DASH}"
        done < $SADM_TMP_FILE1

}


# --------------------------------------------------------------------------------------------------
#                               Ask User what to do 
# --------------------------------------------------------------------------------------------------
ask_user()
{
    tput clear

    # What is the file name and path to push to servers
    # ----------------------------------------------------------------------------------------------
    while : 
        do 
        echo -e "\n==============================================================================="
        echo -en "Specify the filename you want to push to Unix servers or (Q)uit? "
        read FILENAME
        case "$FILENAME" in
           q|Q )        exit 1
                        ;;
           * )          if [ ! -f "$FILENAME" ] 
                            then echo "File not found !" 
                            else break 
                        fi
                        ;;
        esac
    done

    # What to push the file to AIX Servers ? 
    # ----------------------------------------------------------------------------------------------
    while : 
        do 
        echo -e "\n==============================================================================="
        echo -en "Want to Update Aix Servers (Y/N) or (Q)uit? "
        read AIX_UPDATE
        case "$AIX_UPDATE" in
           o|O|Y|y )    AIX_UPDATE="Y"
                        break
                        ;;
           n|N )        AIX_UPDATE="N"
                        break
                        ;;
           q|Q )        exit 1
                        ;;
           * )          echo "Must enter (Y)es or (N)o or (Q)uit !"
                        ;;
        esac
    done

    # What to push the file to AIX Dev or Prod Servers or Both ? 
    # ----------------------------------------------------------------------------------------------
    AIX_TYPE="X"
    if [ "$AIX_UPDATE" = "Y" ]
        then while : 
                do 
                echo -e "\n==============================================================================="
                echo -en "Want to Update Aix (D)ev. or (P)rod. or (B)oth or (Q)uit (D/P/B/Q) ? "
                read AIX_TYPE
                case "$AIX_TYPE" in
                   d|D) AIX_TYPE="D"
                        break
                        ;;
                   p|P) AIX_TYPE="P"
                        break
                        ;;
                   b|B) AIX_TYPE="B"
                        break
                        ;;
                   q|Q) exit 1
                        ;;
                   * )  echo "Must enter D or P or B or Q !"
                        ;;
                esac
                done
    fi

    # What to push the file to Linux Servers ? 
    # ----------------------------------------------------------------------------------------------
    while : 
        do 
        echo -e "\n==============================================================================="
        echo -en "Want to Update Linux Servers (Y/N) ? "
        read LINUX_UPDATE
        case "$LINUX_UPDATE" in
           o|O|Y|y )    LINUX_UPDATE="Y"
                        break
                        ;;
           n|N )        LINUX_UPDATE="N"
                        break
                        ;;
           q|Q )        exit 1
                        ;;
           * )          echo "Must enter (Y)es or (N)o or (Q)uit !"
                        ;;
        esac
    done

    # What to push the file to Linux Dev or Prod Servers or Both ? 
    # ----------------------------------------------------------------------------------------------
    LINUX_TYPE="X"
    if [ "$LINUX_UPDATE" = "Y" ]
        then while : 
                do 
                echo -e "\n==============================================================================="
                echo -en "Want to Update Linux (D)ev. or (P)rod. or (B)oth or (Q)uit (D/P/B/Q) ? "
                read LINUX_TYPE
                case "$LINUX_TYPE" in
                   d|D) LINUX_TYPE="D"
                        break
                        ;;
                   p|P) LINUX_TYPE="P"
                        break
                        ;;
                   b|B) LINUX_TYPE="B"
                        break
                        ;;
                   q|Q) exit 1
                        ;;
                   * )  echo "Must enter D or P or B or Q !"
                        ;;
                esac
                done
    fi

    export AIX_UPDATE AIX_TYPE LINUX_UPDATE LINUX_TYPE FILENAME


    # Final OK before doing the job
    # ----------------------------------------------------------------------------------------------
    while : 
        do 
        echo -e "\n==============================================================================="
        echo "I will push the file $FILENAME"
        if [ "$AIX_UPDATE" = "N" ] 
            then echo "I will not push it to any Aix Servers"
            else MSINFO="I will push it to all Aix"
                 if [ "$AIX_TYPE" = "D" ] ; then MSINFO=`echo "$MSINFO Dev. servers " ` ; fi
                 if [ "$AIX_TYPE" = "P" ] ; then MSINFO=`echo "$MSINFO Prod. servers " ` ; fi
                 if [ "$AIX_TYPE" = "B" ] ; then MSINFO=`echo "$MSINFO servers " ` ; fi
                 echo "$MSINFO"
        fi
        if [ "$LINUX_UPDATE" = "N" ] 
            then echo "I will not push it to any Linux Servers"
            else MSINFO="I will push it to all Linux"
                 if [ "$LINUX_TYPE" = "D" ] ; then MSINFO=`echo "$MSINFO Dev. servers " ` ; fi
                 if [ "$LINUX_TYPE" = "P" ] ; then MSINFO=`echo "$MSINFO Prod. servers " ` ; fi
                 if [ "$LINUX_TYPE" = "B" ] ; then MSINFO=`echo "$MSINFO servers " ` ; fi
                 echo "$MSINFO"
        fi
        echo -en "Are you ok with this (Y)es or (N)o ? "
        read FINAL_ANSWER
        case "$FINAL_ANSWER" in
                   y|Y) break
                        ;;
                   n|n) exit 1
                        ;;
                   * )  echo "Must enter Y or N !"
                        ;;
        esac
        done
}




# --------------------------------------------------------------------------------------------------
#                                Script Start HERE
# --------------------------------------------------------------------------------------------------
    sadm_start                                                          # Init Env Dir & RC/Log File
    
    # OPTIONAL CODE - IF YOUR SCRIPT DOESN'T NEED TO RUN ON THE SADMIN MAIN SERVER, THEN REMOVE
    if [ "$(sadm_get_hostname).$(sadm_get_domainname)" != "$SADM_SERVER" ] # Only run on SADMIN 
        then sadm_writelog "This script can be run only on the SADMIN server (${SADM_SERVER})"
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi

    # OPTIONAL CODE - IF YOUR SCRIPT DOESN'T HAVE TO BE RUN BY THE ROOT USER, THEN YOU CAN REMOVE
    if ! $(sadm_is_root)                                                # Only ROOT can run Script
        then sadm_writelog "This script must be run by the ROOT user"   # Advise User Message
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi

    ask_user
    process_linux_servers
    LINUX_ERROR=$?                                                      # Nb. Error while processing
    process_aix_servers
    AIX_ERROR=$?                                                        # Nb. Error while processing
    SADM_EXIT_CODE=$(($AIX_ERROR+$LINUX_ERROR))                         # Total = AIX+Linux Errors

    # Go Write Log Footer - Send email if needed - Trim the Log - Update the Recode History File
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log 
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
