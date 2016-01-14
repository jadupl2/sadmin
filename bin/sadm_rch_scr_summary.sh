#! /usr/bin/env sh
# --------------------------------------------------------------------------------------------------
#   Author      :  Jacques Duplessis
#   Title       :  template.sh
#   Script name :  sadm_rch_scr_summary.sh
#   Synopsis    :  Display from CLI the Result File (RCH Files) Summary
#   Version     :  1.5
#   Date        :  14 December 2015
#   Requires    :  sh

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
SADM_MAIL_TYPE=1                               ; export SADM_MAIL_TYPE  # 0=No 1=Err 2=Succes 3=All
SADM_MAX_LOGLINE=5000                          ; export SADM_MAX_LOGLINE # Max Nb. Lines in LOG )
SADM_MAX_RCLINE=100                            ; export SADM_MAX_RCLINE # Max Nb. Lines in RCH LOG
#***************************************************************************************************
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPTE LE ^C
#
#


# --------------------------------------------------------------------------------------------------
#              V A R I A B L E S    L O C A L   T O     T H I S   S C R I P T
# --------------------------------------------------------------------------------------------------
#
FIELD_IN_RCH=6                                  ; export FIELD_IN_RCH   # Nb of field in a RCH File
line_per_page=20                                ; export line_per_page  # Nb of line per scr page
xcount=0                                        ; export xcount         # Index for our array
xline_count=0                                   ; export xline_count    # Line display counter



#===================================================================================================
#                H E L P       U S A G E    D I S P L A Y    F U N C T I O N 
#===================================================================================================
help()
{
    echo "smon usage : -m Mail report"
    echo "             -p No pager"
    echo "             -e Error report only"
    echo "             -w Watch 1st page in real time"
}





#===================================================================================================
#               D I S P L A Y    S C R E E N    H E A D I N G     F U N C T I O N 
#===================================================================================================
display_heading()
{
    if [ "$PAGER" = "ON" ] || ( [ "$PAGER" = "OFF" ]  &&  [ "$WATCH" = "ON" ] )
        then tput clear ; 
             echo -e "${bblue}${white}\c"
             echo -e "`date +%Y/%m/%d`                    Server Farm Scripts Summary Report \c"  
             echo -e "                   `date +%H:%M:%S`"  
             echo -e "Count    Status     Date    Server       Script   \c"
             echo -e "                       Start      End     "
             echo -e "==================================================\c"
             echo -e "==========================================${reset}"
    fi
}



#===================================================================================================
#                 D I S P L A Y    L I N E    D E T A I L    F U N C T I O N  
#===================================================================================================
display_detail_line()
{
    DLINE=$1                                                            # Save Line Received
    WSERVER=`echo $DLINE | awk '{ print $1 }'`                          # Extract Server Name
    WDATE1=`echo $DLINE  | awk '{ print $2 }'`                          # Extract Date Started
    WTIME1=`echo $DLINE  | awk '{ print $3 }'`                          # Extract Time Started
    WTIME2=`echo $DLINE  | awk '{ print $4 }'`                          # Extract Time Ended
    WSCRIPT=`echo $DLINE | awk '{ print $5 }'`                          # Extract Script Name
    WRCODE=`echo $DLINE  | awk '{ print $6 }'`                          # Extract Return Code 
    case "$WRCODE" in                                                   # Case on Return Code
        0 ) WRDESC="✔ Success"                                          # Code 0 = Success
            ;; 
        1 ) WRDESC="✖ Error  "                                          # Code 1 = Error
            ;;
        2 ) WRDESC="➜ Running"                                          # Code 2 = Script Running
            ;;
        * ) WRDESC="CODE ${WRCODE}"                                     # Illegal Code  Desc
            ;;                                                          
    esac
    RLINE1=`printf "[%04d] %11s %-s %-12s " "$xcount" "$WRDESC" "${WDATE1}" "${WSERVER}" `
    RLINE2=`printf "%-30s %s  %s" "${WSCRIPT}" "${WTIME1}" "${WTIME2}"`
    RLINE="${RLINE1}${RLINE2}"                                          # Wrap 2 lines together
    if [ "$MAIL_ONLY" = "OFF" ]                                         # No Mail include color
        then if [ $WRCODE -eq 0 ] ; then echo -e "${blue}\c" ;fi        # Blue For Good Finish Job
             if [ $WRCODE -eq 1 ] ; then echo -e "${red}\c"   ;fi       # Red completed with Error
             if [ $WRCODE -eq 2 ] ; then echo -e "${green}\c"   ;fi     # Green for running job
             echo -e "${RLINE}${reset}"                                 # Display Line
        else echo "$RLINE" >> $SADM_TMP_FILE2                           # Add Line to Mail File 
    fi
}




#===================================================================================================
# Create a file containing last line of all *.rch locate within $SADMIN/wwww/dat.
# Then sort it in Return Code Revrese order then by date , then by server into $SADM_TMP_FILE1 
# Then line are loaded into an array.
# While reading each line, if any line doessn't have 6 fiels it is added into copied $SADM_TMP_FILE3
#
#===================================================================================================
load_array()
{
    # ReturnCodeHistory (RCH) files are collected from servers farm via "sadm_rch_rsync.sh" (crontab)
    # A Temp file that containing the last line of each *.rch file present in ${SADMIN}/www/dat dir.
    # ----------------------------------------------------------------------------------------------
    find $SADM_WWW_DIR_DAT -type f -name "*.rch" -exec tail -1 {} \; > $SADM_TMP_FILE2
    sort -t' ' -rk6,6 -k2,2 -k1,1 $SADM_TMP_FILE2 > $SADM_TMP_FILE1     # Sort by Return Code & date
    if [ ! -s "$SADM_TMP_FILE1" ]                                       # No rch file record ??
       then sadm_logger "No RCH File to process - File is empty"        # Issue message to user
            return 1                                                    # Exit Function 
    fi

    
    # Now we put each line of all rch file the temp file into an array
    xcount=0 ; array=""                                                 # Initialize Array & Index
    touch $SADM_TMP_FILE3                                               # rch format error file 
    while read wline                                                    # Read Line from TEMP3 file
        do                                                              # Start of loop
        WNB_FIELD=`echo $wline | wc -w`                                 # Check Nb. Of field in Line
        if [ "$WNB_FIELD" -ne "$FIELD_IN_RCH" ]                         # If NB.Field ! What Expected
            then echo $wline >> $SADM_TMP_FILE3                         # Save Line in TEMP3 file
                 sadm_logger "ERROR : Nb of field is not $FIELD_IN_RCH - Line was ignore : $wline"
                 continue                                               # Go on and read next line
        fi
        array[$xcount]="$wline"                                         # Put Line in Array
        xcount=$(($xcount+1))                                           # Increment Array Index
        done < $SADM_TMP_FILE1                                          # ENd Loop - Input FileName
    return 0
}





#===================================================================================================
#   P R O C E S S    A L L   L A S T   L I N E    O F    E  A C H   ReturnCodeHistory   F I L E 
#===================================================================================================
main_process()
{
    load_array                                                          # Load RCH Array
    if [ "$ERROR_ONLY" = "ON" ]                                         # If only Error Switch is ON
        then tput clear                                                 # Clear the Screen
             if [ -s "$SADM_TMP_FILE3" ]                                # Check something in file
                 then nl $SADM_TMP_FILE3                                # Display Error file with no.
                 else echo "No error to report (All *.rch files have $FIELD_IN_RCH fields)"
             fi
             return 0                                                   # Return to caller
    fi 
        
    # Process each line in the array just loaded and display them
    # ----------------------------------------------------------------------------------------------
    xcount=0; xline_count=0 ;                                           # Clear Index and Linecount
    rm -f $SADM_TMP_FILE2                                               # Clear Email file
    for wline in "${array[@]}"                                          # Process till End of array
        do                                                                          
        if [ "$xcount" -eq 0 ]  ; then display_heading ; fi             # 1st Time display heading
        if [ "$xline_count" -ge "$line_per_page" ]                      # If End of Page length
            then if [ "$PAGER" = "ON" ]                                 # If Pager is on
                    then echo "Press [ENTER] for next page or CTRL-C to end"
                         read dummy                                     # Wait till enter is press
                         display_heading                                # Clr Screen & Display Head
                         if [ "$xcount" -ne 0 ] ;then xline_count=0 ;fi # Reset Line no on page
                    else if [ "$WATCH" = "ON" ]                         # If No Pager & Watch ON
                            then echo "This page will refresh every 15 seconds"
                                 sleep 15                               # Sleep 15 Seconds
                                 return 0                               # Return to Caller
                         fi
                 fi
        fi
        xcount=$(($xcount+1))                                           # Incr. Cumulative Lineno
        xline_count=$(($xline_count+1))                                 # Incr. Lineno on Page
        display_detail_line "$wline"                                    # Go Display Line
        done
    
    # If Mail Switch is ON - Send what usually displayed to Sysadmin
    if [ "$MAIL_ONLY" = "ON" ]                                          # If mail Switch is ON
        then cat $SADM_TMP_FILE2 | mail -s "SADM : Activity Summary Report"  $SADM_MAIL_ADDR
    fi      
    return 0                                                            # Return Default return code
}





# --------------------------------------------------------------------------------------------------
#                       S T A R T     O F    T H E    S C R I P T 
# --------------------------------------------------------------------------------------------------
    sadm_start                                                          # Init Env. Dir & RC/Log File
    
    # Script can only be run on the sadmin server (files needed for report are ont it)
    if [ "$(sadm_hostname).$(sadm_domainname)" != "$SADM_SERVER" ]      # Only run on SADMIN Server
        then sadm_logger "This script can be run only on the SADMIN server (${SADM_SERVER})"
             sadm_logger "Process aborted"                              # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi

    PAGER="ON" ; ERROR_ONLY="OFF" ; MAIL_ONLY="OFF" ; WATCH="OFF"       # Set Switch Default Value
    while getopts "epmhw" opt ; do                                      # Loop to process Switch
        case $opt in
            m) MAIL_ONLY="ON"                                           # Output goes to sysadmin
               PAGER="OFF"                                              # Mail need pager to be off
               ;;                                       
            e) ERROR_ONLY="ON"                                          # Display Only Error file 
               ;;
            w) WATCH="ON"                                               # Display 1st page Only        
               PAGER="OFF"                                              # Watch need pager to be off
               ;;                                                       # And it's refresh every Min
            p) PAGER="OFF"                                              # Display Continiously    
               ;;                                                       # No stop after each page
            h) help                                                     # Display Help Usage
               sadm_stop 0                                              # Close the shop
               exit 0                                                   # Back to shell 
               ;;
           \?) echo "Invalid option: -$OPTARG" >&2                      # Invalid Option Message
               help                                                     # Display Help Usage
               exit 1                                                   # Exit with Error
               ;;
        esac                                                            # End of case
        done                                                            # End of loop

    # Get the last line of all rch files in $SADMIN/www, sort results and Display them
    if [ "$WATCH" = "ON" ]                                              # If WATCH switch is ON
        then while :                                                    # Repeat the main process
                do                                                      # Repeat until CTRL-C 
                main_process                                            # Main Process
                done
        else main_process                                               # main Process all lines
    fi
    SADM_EXIT_CODE=$?                                                   # Save Process Exit Code
    
    # Record in rch file that didn't have six fields (Wrong format) were written to SADM_TMP_FILE3
    if [ -s "$SADM_TMP_FILE3" ]                                         # If File size > than 0
        then tput clear                                                 # Clear the Screen
             echo "Error identified in some \"rch\" files"              # Display Msg to user
             nl $SADM_TMP_FILE3                                         # Display file content
    fi
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log 
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
    