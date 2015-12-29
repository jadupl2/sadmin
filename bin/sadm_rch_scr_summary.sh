#! /usr/bin/env sh
# --------------------------------------------------------------------------------------------------
#   Author   :  Jacques Duplessis
#   Title    :  template.sh
#   Synopsis : .
#   Version  :  1.0
#   Date     :  14 November 2015
#   Requires :  sh

#   The SADMIN Tool is free software; you can redistribute it and/or modify it under the terms
#   of the GNU General Public License as published by the Free Software Foundation; either
#   version 2 of the License, or (at your option) any later version.

#   SADMIN Tool are distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
#   without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#   See the GNU General Public License for more details.
#
# --------------------------------------------------------------------------------------------------
# 1.6   
#set -x

#
#
#***************************************************************************************************
#  USING SADMIN LIBRARY SETUP
#   THESE VARIABLES GOT TO BE DEFINED PRIOR TO LOADING THE SADM LIBRARY (sadm_lib_std.sh) SCRIPT
#   THESE VARIABLES ARE USE AND NEEDED BY ALL THE SADMIN SCRIPT LIBRARY.
#
#   CALLING THE sadm_lib_std.sh SCRIPT DEFINE SOME SHELL FUNCTION AND GLOBAL VARIABLES THAT CAN BE
#   USED BY ANY SCRIPTS TO STANDARDIZE, ADD FLEXIBILITY AND CONTROL TO SCRIPTS THAT USER CREATE.
#
#   PLEASE REFER TO THE FILE $SADM_BASE_DIR/lib/sadm_lib_std.txt FOR A DESCRIPTION OF EACH
#   VARIABLES AND FUNCTIONS AVAILABLE TO SCRIPT DEVELOPPER.
# --------------------------------------------------------------------------------------------------
SADM_PN=${0##*/}                               ; export SADM_PN         # Current Script name
SADM_VER='1.5'                                 ; export SADM_VER        # This Script Version
SADM_INST=`echo "$SADM_PN" |awk -F\. '{print $1}'` ; export SADM_INST   # Script name without ext.
SADM_TPID="$$"                                 ; export SADM_TPID       # Script PID
SADM_EXIT_CODE=0                               ; export SADM_EXIT_CODE  # Script Error Return Code
SADM_BASE_DIR=${SADMIN:="/sadmin"}             ; export SADM_BASE_DIR   # Script Root Base Directory
SADM_LOG_TYPE="L"                              ; export SADM_LOG_TYPE   # 4Logger S=Scr L=Log B=Both
#
[ -f ${SADM_BASE_DIR}/lib/sadm_lib_std.sh ]    && . ${SADM_BASE_DIR}/lib/sadm_lib_std.sh     # sadm std Lib
[ -f ${SADM_BASE_DIR}/lib/sadm_lib_server.sh ] && . ${SADM_BASE_DIR}/lib/sadm_lib_server.sh  # sadm server lib
[ -f ${SADM_BASE_DIR}/lib/sadm_lib_screen.sh ] && . ${SADM_BASE_DIR}/lib/sadm_lib_screen.sh  # sadm screen lib
#
# VARIABLES THAT CAN BE CHANGED PER SCRIPT (DEFAULT CAN BE CHANGED IN $SADM_BASE_DIR/cfg/sadmin.cfg)
#SADM_MAIL_ADDR="your_email@domain.com"        ; export ADM_MAIL_ADDR    # Default is in sadmin.cfg
SADM_MAIL_TYPE=1                               ; export SADM_MAIL_TYPE   # 0=No 1=Err 2=Succes 3=All
SADM_MAX_LOGLINE=5000                          ; export SADM_MAX_LOGLINE # Max Nb. Lines in LOG )
SADM_MAX_RCLINE=100                            ; export SADM_MAX_RCLINE  # Max Nb. Lines in RCH LOG
#***************************************************************************************************
#
#





# --------------------------------------------------------------------------------------------------
#              V A R I A B L E S    L O C A L   T O     T H I S   S C R I P T
# --------------------------------------------------------------------------------------------------
#
Debug=true                                      ; export Debug          # Debug increase Verbose
#
MUSER="query"                                   ; export MUSER          # MySql User
MPASS="query"                                   ; export MPASS          # MySql Password
MHOST="sysinfo.maison.ca"                       ; export MHOST          # Mysql Host
MYSQL="$(which mysql)"                          ; export MYSQL          # Location of mysql program
#
FIELD_IN_RCH=6                                  ; export FIELD_IN_RCH   # Nb of field in a RCH File
line_per_page=20                                ; export line_per_page  # Nb of line per scr page



# --------------------------------------------------------------------------------------------------
#                      S c r i p t    M a i n     P r o c e s s 
# --------------------------------------------------------------------------------------------------
main_process()
{
    find $SADM_WWW_DIR_DAT -type f -name "*.rch" -exec tail -1 {} \; > $SADM_TMP_FILE2
    sort -t' ' -rnk 6 $SADM_TMP_FILE2 > $SADM_TMP_FILE1
    
    if [ ! -s "$SADM_TMP_FILE1" ]
       then sadm_logger "No RCH File to process - File is empty"
            return 0
    fi

    
    xcount=0; xline_count=0
    while read wline
        do
        array[$xcount]="$wline"    
        xcount=$(($xcount+1))
        done < $SADM_TMP_FILE1
    
    
    xcount=0; xline_count=0
    for index in "${!array[@]}"
    do
        wline="${array[index]}"
        WNB_FIELD=`echo $wline | wc -w` 
        if [ "$WNB_FIELD" -ne "$FIELD_IN_RCH" ]
        then echo $wline >> $SADM_TMP_FILE3
                 sadm_logger "ERROR : Nb of field is not $FIELD_IN_RCH - Line was ignore : $wline"
                 continue
        fi
        if [ "$xcount" -eq 0 ]
            then tput clear
                 echo "Status"
                 echo "$DASH"
        fi
        if [ "$xline_count" -ge "$line_per_page" ] 
            then echo "Press [ENTER] for next page or CTRL-C to end"
                 read dummy
                 tput clear
                 echo "Status"
                 echo "$DASH"
                 if [ "$xcount" -ne 0 ] ; then xline_count=0 ; fi
        fi
        xcount=$(($xcount+1))
        xline_count=$(($xline_count+1))
        WSERVER=`echo $wline | awk '{ print $1 }'`
        WDATE1=`echo $wline  | awk '{ print $2 }'`
        WTIME1=`echo $wline  | awk '{ print $3 }'`
        WTIME2=`echo $wline  | awk '{ print $4 }'`
        WSCRIPT=`echo $wline | awk '{ print $5 }'`
        WRCODE=`echo $wline  | awk '{ print $6 }'`
        case "$WRCODE" in                                               # Test Answer
            0 ) WRDESC="Success $WRCODE"
                ;; 
            1 ) WRDESC="Error $WRCODE"
                ;;
            2 ) WRDESC="Running $WRCODE"
                ;;
            * ) WRDESC="CODE ${WRCODE}"
                ;;                                                     # Other stay in the loop
        esac
        #echo "WRDESC=$WRDESC"
        #echo "WSERVER=$WSERVER"
        #echo "WDATE1=$WDATE1"
        #echo "WTIME1=$WTIME1"
        #echo "WTIME2=$WTIME2"
        #echo "WSCRIPT=$WSCRIPT"
        RLINE=`printf "[%04d] %-12s %-10s %-30s %s  %s  %s" "$xcount" "$WRDESC" "${WSERVER}" "${WSCRIPT}" "${WDATE1}" "${WTIME1}" "${WTIME2}"`
        echo "${RLINE}"

    done
    return 0                                                            # Return Default return code
}




# --------------------------------------------------------------------------------------------------
#                                Script Start HERE
# --------------------------------------------------------------------------------------------------
    sadm_start                                                          # Init Env. Dir & RC/Log File
    
    if [ "$(sadm_hostname).$(sadm_domainname)" != "$SADM_SERVER" ]      # Only run on SADMIN Server
        then sadm_logger "This script can be run only on the SADMIN server (${SADM_SERVER})"
             sadm_logger "Process aborted"                              # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi

    if ! $(sadm_is_root)                                                # Only ROOT can run Script
        then sadm_logger "This script must be run by the ROOT user"     # Advise User Message
             sadm_logger "Process aborted"                              # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi

    main_process                                                        # Main Process
    SADM_EXIT_CODE=$?                                                   # Save Process Exit Code

    # Go Write Log Footer - Send email if needed - Trim the Log - Update the Recode History File
    sadm_stop $SADM_EXIT_CODE                                                # Upd. RCH File & Trim Log 
    exit $SADM_EXIT_CODE                                                     # Exit With Global Err (0/1)



