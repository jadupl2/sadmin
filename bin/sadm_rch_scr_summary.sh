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
# Version Change Log 
#
# 2015_12_14    V1.0 Initial Version
# 2018_07_25    v1.1 Modify Look of Email Sent with option -m
#@2018_07_29    v1.2 Remove utilization of RCH for this interactive script (SADM_USE_RCH="N" )
#
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPT The Control-C
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
    export SADM_VER='1.2'                               # Current Script Version
    export SADM_LOG_TYPE="B"                            # Writelog goes to [S]creen [L]ogFile [B]oth
    export SADM_LOG_APPEND="N"                          # Append Existing Log or Create New One
    export SADM_LOG_HEADER="Y"                          # Show/Generate Script Header
    export SADM_LOG_FOOTER="Y"                          # Show/Generate Script Footer 
    export SADM_MULTIPLE_EXEC="Y"                       # Allow running multiple copy at same time ?
    export SADM_USE_RCH="N"                             # Generate Entry in Result Code History file

    # DON'T CHANGE THESE VARIABLES - They are used to pass information to SADMIN Standard Library.
    export SADM_PN=${0##*/}                             # Current Script name
    export SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1`   # Current Script name, without the extension
    export SADM_TPID="$$"                               # Current Script PID
    export SADM_EXIT_CODE=0                             # Current Script Exit Return Code

    # Load SADMIN Standard Shell Library 
    . ${SADMIN}/lib/sadmlib_std.sh                      # Load SADMIN Shell Standard Library

    # Default Value for these Global variables are defined in $SADMIN/cfg/sadmin.cfg file.
    # But some can overriden here on a per script basis.
    #export SADM_MAIL_TYPE=1                            # 0=NoMail 1=MailOnError 2=MailOnOK 3=Allways
    #export SADM_MAIL_ADDR="your_email@domain.com"      # Email to send log (To Override sadmin.cfg)
    #export SADM_MAX_LOGLINE=5000                       # When Script End Trim log file to 5000 Lines
    #export SADM_MAX_RCLINE=100                         # When Script End Trim rch file to 100 Lines
    #export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} " # SSH Command to Access Server 
#===================================================================================================



# --------------------------------------------------------------------------------------------------
#              V A R I A B L E S    L O C A L   T O     T H I S   S C R I P T
# --------------------------------------------------------------------------------------------------
#
FIELD_IN_RCH=8                                  ; export FIELD_IN_RCH   # Nb of field in a RCH File
line_per_page=20                                ; export line_per_page  # Nb of line per scr page
xcount=0                                        ; export xcount         # Index for our array
xline_count=0                                   ; export xline_count    # Line display counter
HTML_FILE="${SADM_TMP_DIR}/${SADM_INST}$$.html" ; export HTML_FILE      # HTML File sent to user


#===================================================================================================
#                H E L P       U S A G E    D I S P L A Y    F U N C T I O N 
#===================================================================================================
help()
{
    echo "smon usage : -m Mail report"
    echo "             -p No pager"
    echo "             -e Error report only"
    echo "             -w Watch 1st page in real time"
    echo "             -s [ServerName]"
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
             echo -e "                         `date +%H:%M:%S`"  
             echo -e "Count    Status  Server       Script   \c"
             echo -e "                         Date     Start      End    Elapse "
             echo -e "==================================================\c"
             echo -e "================================================${reset}"
    fi
}



#===================================================================================================
#                 D I S P L A Y    L I N E    D E T A I L    F U N C T I O N  
#===================================================================================================
display_detail_line()
{
    DLINE=$1                                                            # Save Line Received
    WSERVER=`echo $DLINE | awk '{ print $1 }'`                          # Extract Server Name
    WDATE1=` echo $DLINE | awk '{ print $2 }'`                          # Extract Date Started
    WTIME1=` echo $DLINE | awk '{ print $3 }'`                          # Extract Time Started
    WDATE2=` echo $DLINE | awk '{ print $4 }'`                          # Extract Date Started
    WTIME2=` echo $DLINE | awk '{ print $5 }'`                          # Extract Time Ended
    WELAPSE=`echo $DLINE | awk '{ print $6 }'`                          # Extract Time Ended
    WSCRIPT=`echo $DLINE | awk '{ print $7 }'`                          # Extract Script Name
    WRCODE=` echo $DLINE | awk '{ print $8 }'`                          # Extract Return Code 
    case "$WRCODE" in                                                   # Case on Return Code
        0 ) WRDESC="✔ Success"                                          # Code 0 = Success
            ;; 
        1 ) WRDESC="✖ Error  "                                          # Code 1 = Error
            ;;
        2 ) WRDESC="➜ Running"                                          # Code 2 = Script Running
            ;;
        * ) WRDESC="CODE $WRCODE"                                       # Illegal Code  Desc
            ;;                                                          
    esac
    RLINE1=`printf "[%04d] %10s %-12s %-30s " "$xcount" "$WRDESC" "${WSERVER}" "${WSCRIPT}"  `
    RLINE2=`printf "%s %s %s %s"  "${WDATE1}" "${WTIME1}" "${WTIME2}" ${WELAPSE}`
    RLINE="${RLINE1}${RLINE2}"                                          # Wrap 2 lines together
    if [ "$MAIL_ONLY" = "OFF" ]                                         # No Mail include color
        then if [ $WRCODE -eq 0 ] ; then echo -e "${white}\c" ;fi       # white For Good Finish Job
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
    find $SADM_WWW_DAT_DIR -type f -name "*.rch" -exec tail -1 {} \; > $SADM_TMP_FILE2
    sort -t' ' -rk8,8 -k2,3 -k7,7 $SADM_TMP_FILE2 > $SADM_TMP_FILE1     # Sort by Return Code & date
    if [ "$SERVER_NAME" != "" ]
        then grep -i "$SERVER_NAME" $SADM_TMP_FILE1 > $SADM_TMP_FILE2
             cp  $SADM_TMP_FILE2  $SADM_TMP_FILE1
    fi
    if [ ! -s "$SADM_TMP_FILE1" ]                                       # No rch file record ??
       then sadm_writelog "No RCH File to process - File is empty"        # Issue message to user
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
                 sadm_writelog "ERROR : Nb of field is not $FIELD_IN_RCH - Line was ignore : $wline"
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
        then echo "#<!DOCTYPE html><html><head><meta charset="utf-8" /><title>" >$HTML_FILE
             echo "</title></head><body><code>" >> $HTML_FILE
             awk '{ print  }' $SADM_TMP_FILE2 >> $HTML_FILE
             echo "</code></body></html>" >> $HTML_FILE
             cat $HTML_FILE | mail -s "SADM : Activity Summary Report"  $SADM_MAIL_ADDR
             #cat $HTML_FILE | sendmail -t -s "SADM : Activity Summary Report"  $SADM_MAIL_ADDR

    fi      
    return 0                                                            # Return Default return code
}





# --------------------------------------------------------------------------------------------------
#                       S T A R T     O F    T H E    S C R I P T 
# --------------------------------------------------------------------------------------------------
    sadm_start                                                          # Init Env. Dir & RC/Log File
    
    # Script can only be run on the sadmin server (files needed for report are ont it)
    if [ "$(sadm_get_hostname).$(sadm_get_domainname)" != "$SADM_SERVER" ]      # Only run on SADMIN Server
        then sadm_writelog "This script can be run only on the SADMIN server (${SADM_SERVER})"
             sadm_writelog "Process aborted"                            # Abort advise message
             echo "This script can be run only on the SADMIN server (${SADM_SERVER})"
             echo "Process aborted"                                     # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi

    PAGER="ON" ; ERROR_ONLY="OFF" ; MAIL_ONLY="OFF" ; WATCH="OFF"       # Set Switch Default Value
    SERVER_NAME=""                                                      # Set Switch Default Value
    while getopts "epmhws:" opt ; do                                    # Loop to process Switch
        case $opt in
            m) MAIL_ONLY="ON"                                           # Output goes to sysadmin
               PAGER="OFF"                                              # Mail need pager to be off
               ;;                                       
            e) ERROR_ONLY="ON"                                          # Display Only Error file 
               ;;
            s) SERVER_NAME="$OPTARG"                                    # Display Only Server Name
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
    
