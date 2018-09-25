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
# 2015_12_14 V1.0 Initial Version
# 2018_07_25 v1.1 Modify Look of Email Sent with option -m
# 2018_07_29 v1.2 Remove utilization of RCH for this interactive script (SADM_USE_RCH="N" )
# 2018_07_29 v1.3 Remove Log Header & Footer, Change Email & Help Format.
# 2018_08_27 v1.4 New Email format when using -m command line switch, View script log from email.
# 2018_09_18 v1.5 Email when using -m command line switch include ow the Alert Group
# 2018_09_23 v1.6 Added email to sysadmin when rch have invalid format
#@2018_09_24 v1.7 Change HTML layout of Email and multiples little changes
#
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPT The Control-C
#set -x




#===================================================================================================
#               Setup SADMIN Global Variables and Load SADMIN Shell Library
#===================================================================================================
#
    # Test if 'SADMIN' environment variable is defined
    if [ -z "$SADMIN" ]                                 # If SADMIN Environment Var. is not define
        then echo "Please set 'SADMIN' Environment Variable to the install directory." 
             exit 1                                     # Exit to Shell with Error
    fi

    # Test if 'SADMIN' Shell Library is readable 
    if [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]            # SADM Shell Library not readable
        then echo "SADMIN Library can't be located"     # Without it, it won't work 
             exit 1                                     # Exit to Shell with Error
    fi

    # CHANGE THESE VARIABLES TO YOUR NEEDS - They influence execution of SADMIN standard library.
    export SADM_VER='1.7'                               # Current Script Version
    export SADM_LOG_TYPE="B"                            # Writelog goes to [S]creen [L]ogFile [B]oth
    export SADM_LOG_APPEND="Y"                          # Append Existing Log or Create New One
    export SADM_LOG_HEADER="N"                          # Show/Generate Script Header
    export SADM_LOG_FOOTER="N"                          # Show/Generate Script Footer 
    export SADM_MULTIPLE_EXEC="Y"                       # Allow running multiple copy at same time ?
    export SADM_USE_RCH="N"                             # Generate Entry in Result Code History file

    # DON'T CHANGE THESE VARIABLES - They are used to pass information to SADMIN Standard Library.
    export SADM_PN=${0##*/}                             # Current Script name
    export SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1`   # Current Script name, without the extension
    export SADM_TPID="$$"                               # Current Script PID
    export SADM_EXIT_CODE=0                             # Current Script Exit Return Code
    . ${SADMIN}/lib/sadmlib_std.sh                      # Load SADMIN Shell Standard Library
#
#---------------------------------------------------------------------------------------------------
#
    # Default Value for these Global variables are defined in $SADMIN/cfg/sadmin.cfg file.
    # But they can be overriden here on a per script basis.
    #export SADM_ALERT_TYPE=1                            # 0=None 1=AlertOnErr 2=AlertOnOK 3=Allways
    #export SADM_ALERT_GROUP="default"                   # AlertGroup Used to Alert (alert_group.cfg)
    #export SADM_MAIL_ADDR="your_email@domain.com"      # Email to send log (To Override sadmin.cfg)
    #export SADM_MAX_LOGLINE=1000                       # When Script End Trim log file to 1000 Lines
    #export SADM_MAX_RCLINE=125                         # When Script End Trim rch file to 125 Lines
    #export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} " # SSH Command to Access Server 
#
#===================================================================================================



# --------------------------------------------------------------------------------------------------
#              V A R I A B L E S    L O C A L   T O     T H I S   S C R I P T
# --------------------------------------------------------------------------------------------------
#
FIELD_IN_RCH=9                                  ; export FIELD_IN_RCH   # Nb of field in a RCH File
line_per_page=20                                ; export line_per_page  # Nb of line per scr page
xcount=0                                        ; export xcount         # Index for our array
xline_count=0                                   ; export xline_count    # Line display counter
HTML_FILE="${SADM_TMP_DIR}/${SADM_INST}.html"   ; export HTML_FILE      # HTML File sent to user
DEBUG_LEVEL=0                                   ; export DEBUG_LEVEL    # 0=NoDebug Higher=+Verbose
URL_VIEW_FILE='/view/log/sadm_view_file.php'    ; export URL_VIEW_FILE  # View File Content URL


# --------------------------------------------------------------------------------------------------
#       H E L P      U S A G E   A N D     V E R S I O N     D I S P L A Y    F U N C T I O N
# --------------------------------------------------------------------------------------------------
show_usage()
{
    printf "\n${SADM_PN} usage :"
    printf "\n\t-p   (No pager)"
    printf "\n\t-e   (Error report only)"
    printf "\n\t-w   (Watch 1st page in real time)"
    printf "\n\t-s   ([ServerName])"    
    printf "\n\t-m   (Mail report)"
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
#               D I S P L A Y    S C R E E N    H E A D I N G     F U N C T I O N 
#===================================================================================================
display_heading()
{
    if [ "$PAGER" = "ON" ] || ( [ "$PAGER" = "OFF" ]  &&  [ "$WATCH" = "ON" ] )
        then tput clear ; 
             echo -e "${bblue}${white}\c"
             echo -e "`date +%Y/%m/%d`                           Server Farm Scripts Summary Report \c"
             echo -e "                            `date +%H:%M:%S`"  
             echo -e "Count    Status  Server       Script   \c"
             echo -e "                         Date     Start      End    Elapse  Alert Grp"
             echo -e "==================================================\c"
             echo -e "==========================================================${reset}"
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
    WALERT=` echo $DLINE | awk '{ print $8 }'`                          # Extract Alert Code
    WRCODE=` echo $DLINE | awk '{ print $9 }'`                          # Extract Return Code 
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
    RLINE2=`printf "%s %s %s %s %s"  "${WDATE1}" "${WTIME1}" "${WTIME2}" "${WELAPSE}" "${WALERT}"`
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
#
# Create a file containing last line of all *.rch locate within $SADMIN/wwww/dat.
# Then sort it by Return Code in Reverse order then by date , then by server into $SADM_TMP_FILE1 
# Then line are loaded into an array.
# While reading each line, if any line don't have $FIELD_IN_RCH fields it's added to $SADM_TMP_FILE3
#
#===================================================================================================
load_array()
{
    # SADMIN Server get ReturnCodeHistory (RCH) files from all clients via "sadm_fetch_clients.sh" 
    # This is done at regular interval from the server crontab,(/etc/cron.d/sadm_server)
    # A Temp file that containing the LAST line of each *.rch file present in ${SADMIN}/www/dat dir.
    # ----------------------------------------------------------------------------------------------
    find $SADM_WWW_DAT_DIR -type f -name "*.rch" -exec tail -1 {} \; > $SADM_TMP_FILE2
    sort -t' ' -rk9,9 -k2,3 -k7,7 $SADM_TMP_FILE2 > $SADM_TMP_FILE1     # Sort by Return Code & date

    # If Option -s was used on the command line to get the report for only the one specified.
    if [ "$SERVER_NAME" != "" ]                                         # CmdLine -s 1 server Report
        then grep -i "$SERVER_NAME" $SADM_TMP_FILE1 > $SADM_TMP_FILE2   # Keep only that server
             cp  $SADM_TMP_FILE2  $SADM_TMP_FILE1                       # That become working file
    fi

    # Check if working file is empty, then nothing to report
    if [ ! -s "$SADM_TMP_FILE1" ]                                       # No rch file record ??
       then sadm_writelog "No RCH File to process"                      # Issue message to user
            return 1                                                    # Exit Function 
    fi
    
    # Now we put the last line of all rch file from the working temp file into an array.
    xcount=0 ; array=""                                                 # Initialize Array & Index
    touch $SADM_TMP_FILE3                                               # Field Number dont' match
    while read wline                                                    # Read Line from TEMP3 file
        do                                                              # Start of loop
        WNB_FIELD=`echo $wline | wc -w`                                 # Check Nb. Of field in Line
        if [ "$WNB_FIELD" -ne "$FIELD_IN_RCH" ]                         # If NB.Field don't match
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
# Return Code History Summary Report Email Heading
#===================================================================================================
email_rch_heading()
{
    RTITLE=$1
    echo -e "\n<center><table border=0>"  >> $HTML_FILE
    echo -e "\n<thead>"             >> $HTML_FILE

    echo -e "\n<tr>"                >> $HTML_FILE
    echo -e "\n<th colspan=9 dt-head-center>${RTITLE}</th>" >> $HTML_FILE
    echo -e "\n</tr>"               >> $HTML_FILE

    echo -e "\n<tr>"                >> $HTML_FILE
    echo -e "\n<th>Count</th>"      >> $HTML_FILE
    echo -e "\n<th>Date</th>"       >> $HTML_FILE
    echo -e "\n<th>Status</th>"     >> $HTML_FILE
    echo -e "\n<th>Server</th>"     >> $HTML_FILE
    echo -e "\n<th>Script/Log</th>" >> $HTML_FILE
    echo -e "\n<th>Start</th>"      >> $HTML_FILE
    echo -e "\n<th>End</th>"        >> $HTML_FILE
    echo -e "\n<th>Elapse</th>"     >> $HTML_FILE
    echo -e "\n<th>AlertGroup</th>" >> $HTML_FILE
    echo -e "\n</tr>"               >> $HTML_FILE

    echo -e "\n</thead>"            >> $HTML_FILE
    echo -e "\n"                    >> $HTML_FILE
}


#===================================================================================================
# Print Return Code History File in HTML Table
#===================================================================================================
rch2html()
{
    RCH_FILE=$1                                                         # Print this RCHFile in HTML
    RCH_TITLE=$2                                                        # Table Title
    
    xcount=0                                                            # Clear Line Counter  
    while read wline                                                    # Read Line from TEMP2 file
        do                                                                          
        if [ "$xcount" -eq 0 ]                                          # If no line print yet
            then email_rch_heading "$RCH_TITLE"
        fi 
        xcount=$(($xcount+1))                                           # Incr. Cumulative Lineno

        # Split Line Received
        WSERVER=`echo -e $wline | awk '{ print $1 }'`                   # Extract Server Name
        WDATE1=` echo -e $wline | awk '{ print $2 }'`                   # Extract Date Started
        WTIME1=` echo -e $wline | awk '{ print $3 }'`                   # Extract Time Started
        WDATE2=` echo -e $wline | awk '{ print $4 }'`                   # Extract Date Started
        WTIME2=` echo -e $wline | awk '{ print $5 }'`                   # Extract Time Ended
        WELAPSE=`echo -e $wline | awk '{ print $6 }'`                   # Extract Time Ended
        WSCRIPT=`echo -e $wline | awk '{ print $7 }'`                   # Extract Script Name
        WALERT=` echo -e $wline | awk '{ print $8 }'`                   # Extract Alert Group 
        WRCODE=` echo -e $wline | awk '{ print $9 }'`                   # Extract Return Code 
        WRDESC="CODE $WRCODE"                                           # Illegal Code  Desc
        if [ "$WRCODE" = "0" ] ; then WRDESC="✔ Success" ; fi           # Code 0 = Success
        if [ "$WRCODE" = "1" ] ; then WRDESC="✖ Error  " ; fi           # Code 1 = Error
        if [ "$WRCODE" = "2" ] ; then WRDESC="➜ Running" ; fi           # Code 2 = Running
        
        # Insert Line in HTML Table
        echo -e "\n<tr>"  >> $HTML_FILE

        # Set Background Color - Color at https://www.w3schools.com/tags/ref_colornames.asp
        if (( $xcount%2 == 0 ))
           then BCOL="#ffffcc" ; FCOL="#000000" 
           else BCOL="#f2ffcc" ; FCOL="#000000"
        fi
        #if [ "$WRCODE" = "0" ] ; then BCOL="#f2ffcc" ; FCOL="#000000" ; fi  # 0 = Success = Beige
        if [ "$WRCODE" = "1" ] ; then BCOL="Red"     ; FCOL="#000000" ; fi  # 1 = Error = Red
        if [ "$WRCODE" = "2" ] ; then BCOL="Yellow"  ; FCOL="#000000" ; fi  # 2 = Running = Yellow

        echo -e "\n<td align=center bgcolor=$BCOL><font color=$FCOL>$xcount</font></td>"  >> $HTML_FILE
        echo -e "\n<td align=center bgcolor=$BCOL><font color=$FCOL>$WDATE1</font></td>"  >> $HTML_FILE
        echo -e "\n<td align=center bgcolor=$BCOL><font color=$FCOL>$WRDESC</font></td>"  >> $HTML_FILE
        echo -e "\n<td align=center bgcolor=$BCOL><font color=$FCOL>$WSERVER</font></td>" >> $HTML_FILE

        # Insert Name of the Script with link to log if log is accessible
        echo -e "\n<td align=center bgcolor=$BCOL><font color=$FCOL>" >> $HTML_FILE
        LOGFILE="${WSERVER}_${WSCRIPT}.log"                             # Assemble log Script Name
        LOGNAME="${SADM_WWW_DAT_DIR}/${WSERVER}/log/${LOGFILE}"         # Add Dir. Path to Name
        LOGURL="http://sadmin.${SADM_DOMAIN}/${URL_VIEW_FILE}?filename=${LOGNAME}" # Url to View Log
        if [ -r "$LOGNAME" ]                                            # If log is Readable
            then echo "<a href='$LOGURL' "            >> $HTML_FILE     # Link to Access the Log
                 echo "title='View Script Log File'>" >> $HTML_FILE     # ToolTip to Show User
                 echo -e "$WSCRIPT</font></a></td>"   >> $HTML_FILE     # End of Link Definition
            else echo -e "$WSCRIPT</font></td>"       >> $HTML_FILE     # No Log = No LInk
        fi
        
        echo -e "\n<td align=center bgcolor=$BCOL><font color=$FCOL>$WTIME1</font></td>"  >> $HTML_FILE
        echo -e "\n<td align=center bgcolor=$BCOL><font color=$FCOL>$WTIME2</font></td>"  >> $HTML_FILE
        echo -e "\n<td align=center bgcolor=$BCOL><font color=$FCOL>$WELAPSE</font></td>" >> $HTML_FILE
        echo -e "\n<td align=center bgcolor=$BCOL><font color=$FCOL>$WALERT</font></td>" >> $HTML_FILE
        echo -e "\n</tr>" >> $HTML_FILE

        done < $RCH_FILE                                               # Read From Created File
    echo -e "\n</table></center><br><br>" >> $HTML_FILE                 # End of Table
    return 
} 




#===================================================================================================
# Produce and Send Email Summary Report Function
#===================================================================================================
mail_report()
{
    # Create Summary Report HTML Header
    echo -e "<!DOCTYPE html><html>\n"                > $HTML_FILE
    echo -e "<head>\n"                              >> $HTML_FILE
    echo -e "<style>\n"                             >> $HTML_FILE
    echo -e "th { color: white; background-color: #5e39ad;     padding: 5px; }\n"  >> $HTML_FILE
    echo -e "td { color: white; border-bottom: 1px solid #ddd; padding: 5px; }\n"  >> $HTML_FILE
    echo -e "tr:nth-child(even) { background-color: #000000; }\n" >> $HTML_FILE
    echo -e "tr:nth-child(odd)  { background-color: #f2f2f2; }\n" >> $HTML_FILE
    echo -e "</style>\n"                            >> $HTML_FILE
    echo -e "<meta charset='utf-8' />\n"            >> $HTML_FILE
    echo -e "<title>\n"                             >> $HTML_FILE
    echo -e "</title>\n</head>\n<body>\n\n"         >> $HTML_FILE
    echo -e "<br><center><h1>Scripts Daily Report for `date`</h1></center><br>\n" >> $HTML_FILE

    # Produce Report of script running or failed ---------------------------------------------------
    sadm_writelog "Producing Summary Report of 'Failed' scripts ..."
    xcount=0                                                            # Clear Line Counter  
    rm -f $SADM_TMP_FILE1 >/dev/null 2>&1                               # Make Sure it doesn't exist
    for wline in "${array[@]}"                                          # Process till End of array
        do                                                                          
        WRCODE=` echo $wline | awk '{ print $9 }'`                      # Extract Return Code 
        if [ "$WRCODE" != "1" ] ; then continue ; fi                    # If Script Succeeded = Skip 
        echo "$wline" >> $SADM_TMP_FILE1                                # Write Event to Tmp File1
        done 
    if [ -s "$SADM_TMP_FILE1" ]                                         # If Input file Size > 0 
        then sort -t' ' -rk8,8 $SADM_TMP_FILE1 > $SADM_TMP_FILE2        # Sort File by Return Code
             rch2html "$SADM_TMP_FILE2" "List of scripts that 'Failed'" # Print RCH File in HTML
    fi

    # Produce Report for Yesterday -----------------------------------------------------------------
    DATE1=`date --date="yesterday" +"%Y.%m.%d"`                         # Date 1 day ago YYY.MM.DD
    sadm_writelog "Producing Email Summary Report for yesterday ($DATE1) ..."
    if [ $DEBUG_LEVEL -gt 0 ] ; then sadm_writelog "Date for 1 day ago  : $DATE1" ; fi
    # Isolate Yesterday Event & Sort by Event Time afterward.
    xcount=0                                                            # Clear Line Counter  
    rm -f $SADM_TMP_FILE1 >/dev/null 2>&1                               # Make Sure it doesn't exist
    for wline in "${array[@]}"                                          # Process till End of array
        do                                                                          
        WDATE1=` echo -e $wline | awk '{ print $2 }'`                   # Extract Event Date Started
        if [ "$WDATE1" != "$DATE1" ] ; then continue ; fi               # If Not the Day Wanted
        echo "$wline" >> $SADM_TMP_FILE1                                # Write Event to Tmp File1
        done 
    if [ -s "$SADM_TMP_FILE1" ]                                         # If Input file Size > 0 
        then sort -t' ' -k3,3 $SADM_TMP_FILE1 > $SADM_TMP_FILE2         # Sort File by Start time
             rch2html "$SADM_TMP_FILE2" "List of scripts executed Yesterday ($DATE1)" 
    fi 

    # Produce Report for 2 days ago ----------------------------------------------------------------
    #DATE2=`date --date="-2 days" +"%Y.%m.%d"`                           # Date 2 days ago YYY.MM.DD
    #sadm_writelog "Producing Email Summary Report for 2 days ago ($DATE2) ..."
    #if [ $DEBUG_LEVEL -gt 0 ] ; then sadm_writelog "Date for 2 day ago  : $DATE2" ;fi 
    ## Isolate 2 Days Ago Event & Sort by Event Time afterward.
    #xcount=0                                                            # Clear Line Counter  
    #rm -f $SADM_TMP_FILE1 >/dev/null 2>&1                                    # Make Sure it doesn't exist
    #for wline in "${array[@]}"                                          # Process till End of array
    #    do                                                                          
    #    WDATE1=` echo -e $wline | awk '{ print $2 }'`                   # Extract Event Date Started
    #    if [ "$WDATE1" != "$DATE2" ] ; then continue ; fi               # If Not the Day Wanted
    #    echo "$wline" >> $SADM_TMP_FILE1                                     # Write Event to Tmp File1
    #    done 
    #if [ -s "$SADM_TMP_FILE1" ]                                              # If Input file Size > 0 
    #    then sort -t' ' -k3,3 $SADM_TMP_FILE1 > $SADM_TMP_FILE2                   # Sort File by Start time
    #         rch2html "$SADM_TMP_FILE2" "Scripts Status of 2 days ago ($DATE2)" # Print RCH File in HTML
    #fi

    # Produce Report of what is old than number of days to keep rch in sadmin.cfg ------------------
    DATE3=`date --date="-$SADM_RCH_KEEPDAYS days" +"%Y%m%d"`            # Date XX Days Ago YYYY.MM.DD
    sadm_writelog "Producing Email Summary Report for Status older than $SADM_RCH_KEEPDAYS days ($DATE3) ..."
    if [ $DEBUG_LEVEL -gt 0 ] ; then sadm_writelog "Date for $SADM_RCH_KEEPDAYS day ago: $DATE3" ;fi 
    xcount=0                                                            # Clear Line Counter  
    rm -f $SADM_TMP_FILE1 >/dev/null 2>&1                               # Make Sure it doesn't exist
    for wline in "${array[@]}"                                          # Process till End of array
        do                                                                          
        WDATE1=` echo -e $wline | awk '{ print $2 }'| tr -d '\.'`       # Extract Event Date Started
        if [ "$WDATE1" -gt "$DATE3" ] ; then continue ; fi              # If Not the Day Wanted
        echo "$wline" >> $SADM_TMP_FILE1                                # Write Event to Tmp File1
        done 
    if [ -s "$SADM_TMP_FILE1" ]                                         # If Input file Size > 0 
        then sort -t' ' -k3,3 $SADM_TMP_FILE1 > $SADM_TMP_FILE2         # Sort File by Start time
             rch2html "$SADM_TMP_FILE2" "Scripts Status older than $SADM_RCH_KEEPDAYS days ($DATE3)"  
    fi                                                                  # Print RCH File in HTML

    echo -e "</body></html>"       >> $HTML_FILE                        # Terminate HTML Page

    # Send Email 
    mutt -e 'set content_type="text/html"' $SADM_MAIL_ADDR -s "Scripts Summary Report" <$HTML_FILE
    SADM_EXIT_CODE=$?
    if [ "$SADM_EXIT_CODE" = "0" ]
        then sadm_writelog "Summary Report sent to $SADM_MAIL_ADDR"
        else sadm_writelog "Problem sending report to $SADM_MAIL_ADDR"
    fi
    return 
}

#===================================================================================================
#   P R O C E S S    A L L   L A S T   L I N E    O F    E  A C H   ReturnCodeHistory   F I L E 
#===================================================================================================
main_process()
{
    load_array                                                          # Load Array lastLine of RCH
    if [ "$ERROR_ONLY" = "ON" ]                                         # If only Error Switch is ON
        then if [ ! -s "$SADM_TMP_FILE3" ]                              # Check something in file
                 then echo "No error to report (All *.rch files have $FIELD_IN_RCH fields)"
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
                            then echo "This page will refresh every 60 seconds"
                                 sleep 60                               # Sleep 60 Seconds
                                 return 0                               # Return to Caller
                         fi
                 fi
        fi
        xcount=$(($xcount+1))                                           # Incr. Cumulative Lineno
        xline_count=$(($xline_count+1))                                 # Incr. Lineno on Page
        display_detail_line "$wline"                                    # Go Display Line
        done
    
    # If Mail Switch is ON - Send what usually displayed to Sysadmin
    if [ "$MAIL_ONLY" = "ON" ] ; then mail_report ; fi                  # mail switch ON = Email Rep

    return 0                                                            # Return Default return code
}





# --------------------------------------------------------------------------------------------------
#                       S T A R T     O F    T H E    S C R I P T 
# --------------------------------------------------------------------------------------------------

# Evaluate Command Line Switch Options Upfront
# (-h) Show Help Usage, (-v) Show Script Version,(-d0-9] Set Debug Level 

    PAGER="ON" ; ERROR_ONLY="OFF" ; MAIL_ONLY="OFF" ; WATCH="OFF"       # Set Switch Default Value
    SERVER_NAME=""                                                      # Set Switch Default Value
    while getopts "hvd:epmws:" opt ; do                                 # Loop to process Switch
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
            d) DEBUG_LEVEL=$OPTARG                                      # Get Debug Level Specified
               num=`echo "$DEBUG_LEVEL" | grep -E ^\-?[0-9]?\.?[0-9]+$` # Valid is Level is Numeric
               if [ "$num" = "" ]                                       # No it's not numeric 
                  then printf "\nDebug Level specified is invalid\n"    # Inform User Debug Invalid
                       show_usage                                       # Display Help Usage
                       exit 0
               fi
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

    # Get the last line of all rch files in $SADMIN/www, sort results and Display them
    if [ "$WATCH" = "ON" ]                                              # If WATCH switch is ON
        then while :                                                    # Repeat the main process
                do                                                      # Repeat until CTRL-C 
                main_process                                            # Main Process
                done
        else main_process                                               # main Process all lines
    fi
    SADM_EXIT_CODE=$?                                                   # Save Process Exit Code

    # Record in rch file that didn't have 9 fields (Wrong format) were written to SADM_TMP_FILE3
    if [ -s "$SADM_TMP_FILE3" ]                                         # If File size > than 0
        then wsubject="Invalid formatted line(s) in RCH file(s)"        # Mail Message
             echo "$wsubject"                                           # Display Msg to user
             nl $SADM_TMP_FILE3                                         # Display file content
             wmess="$SADM_PN - `date`\nSee attachment for the list of lines without $FIELD_IN_RCH fields.\n"
             alert_sysadmin 'M' 'W' "$SADM_HOSTNAME" "$wsubject" "$wmess" "$SADM_TMP_FILE3"
             #sadm_send_alert "W" "$SADM_HOSTNAME" "default" "$wsubject" ""
    fi

    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log 
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
    
