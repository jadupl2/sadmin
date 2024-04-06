#! /usr/bin/env bash
# --------------------------------------------------------------------------------------------------
#   Author      :  Jacques Duplessis
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
# 2018_09_24 v1.7 Change HTML layout of Email and multiples little changes
# 2018_09_27 v1.8 Add list of scripts ran today in HTML page send in (-m) Mail option 
# 2018_10_07 v1.9 Add message when searching for a particular server (-s option)
# 2018_11_21 v1.10 Add Change some Email header Titles.
# 2019_04_02 Fix: v1.11 Doesn't report an error anymore when last line is blank.
# 2019_05_07 cmdline v1.12 Change send_alert calling parameters
# 2019_06_07 cmdline v1.13 Updated to adapt to the new field (alarm type) in RCH file.
# 2019_06_11 cmdline v1.14 Change screen & email message when an invalid '.rch' format is encountered.
# 2019_08_13 cmdline v1.15 Fix bug when using -m option (Email report), Error not on top of report.
# 2019_08_25 cmdline v1.16 Put running scripts and scripts with error on top of email report.
# 2020_04_06 cmdline v1.17 Allow simultaneous execution of this script.
# 2020_05_23 cmdline v1.18 Changing the way to get SADMIN variable in /etc/environment 
# 2022_05_11 cmdline v1.19 Replace "sadm_send_alert()" call by "sadm_sendmail()". 
# 2022_08_17 cmdline v1.20 Updated with new SADMIN section v1.52
# 2023_10_27 cmdline v1.21 Exclude script specify in 'SADM_MONITOR_RECENT_EXCLUDE' variable in sadmin.cfg.
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPT The Control-C
#set -x





# ------------------- S T A R T  O F   S A D M I N   C O D E    S E C T I O N  ---------------------
# v1.56 - Setup for Global Variables and load the SADMIN standard library.
#       - To use SADMIN tools, this section MUST be present near the top of your code.    

# Make Sure Environment Variable 'SADMIN' Is Defined.
if [ -z "$SADMIN" ] || [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]            # SADMIN defined? Libr.exist
    then if [ -r /etc/environment ] ; then source /etc/environment ;fi  # LastChance defining SADMIN
         if [ -z "$SADMIN" ] || [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]   # Still not define = Error
            then printf "\nPlease set 'SADMIN' environment variable to the install directory.\n"
                 exit 1                                                 # No SADMIN Env. Var. Exit
         fi
fi 

# YOU CAN USE THE VARIABLES BELOW, BUT DON'T CHANGE THEM (Used by SADMIN Standard Library).
export SADM_PN=${0##*/}                                    # Script name(with extension)
export SADM_INST=$(echo "$SADM_PN" |cut -d'.' -f1)         # Script name(without extension)
export SADM_TPID="$$"                                      # Script Process ID.
export SADM_HOSTNAME=$(hostname -s)                        # Host name without Domain Name
export SADM_OS_TYPE=$(uname -s |tr '[:lower:]' '[:upper:]') # Return LINUX,AIX,DARWIN,SUNOS 
export SADM_USERNAME=$(id -un)                             # Current user name.

# YOU CAB USE & CHANGE VARIABLES BELOW TO YOUR NEEDS (They influence execution of SADMIN Library).
export SADM_VER='1.21'                                     # Script version number
export SADM_PDESC="Scripts monitoring from command line that show status of all result file (RCH)."  
export SADM_ROOT_ONLY="N"                                  # Run only by root ? [Y] or [N]
export SADM_SERVER_ONLY="N"                                # Run only on SADMIN server? [Y] or [N]
export SADM_EXIT_CODE=0                                    # Script Default Exit Code
export SADM_LOG_TYPE="B"                                   # Log [S]creen [L]og [B]oth
export SADM_LOG_APPEND="N"                                 # Y=AppendLog, N=CreateNewLog
export SADM_LOG_HEADER="N"                                 # Y=ProduceLogHeader N=NoHeader
export SADM_LOG_FOOTER="N"                                 # Y=IncludeFooter N=NoFooter
export SADM_MULTIPLE_EXEC="Y"                              # Run Simultaneous copy of script
export SADM_USE_RCH="N"                                    # Update RCH History File (Y/N)
export SADM_DEBUG=0                                        # Debug Level(0-9) 0=NoDebug
export SADM_TMP_FILE1=$(mktemp "$SADMIN/tmp/${SADM_INST}1_XXX") 
export SADM_TMP_FILE2=$(mktemp "$SADMIN/tmp/${SADM_INST}2_XXX") 
export SADM_TMP_FILE3=$(mktemp "$SADMIN/tmp/${SADM_INST}3_XXX") 

# LOAD SADMIN SHELL LIBRARY AND SET SOME O/S VARIABLES.
. "${SADMIN}/lib/sadmlib_std.sh"                           # Load SADMIN Shell Library
export SADM_OS_NAME=$(sadm_get_osname)                     # O/S Name in Uppercase
export SADM_OS_VERSION=$(sadm_get_osversion)               # O/S Full Ver.No. (ex: 9.0.1)
export SADM_OS_MAJORVER=$(sadm_get_osmajorversion)         # O/S Major Ver. No. (ex: 9)
#export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} "   # SSH CMD to Access Systems

# VALUES OF VARIABLES BELOW ARE LOADED FROM SADMIN CONFIG FILE ($SADMIN/cfg/sadmin.cfg)
# BUT THEY CAN BE OVERRIDDEN HERE, ON A PER SCRIPT BASIS (IF NEEDED).
#export SADM_ALERT_TYPE=1                                   # 0=No 1=OnError 2=OnOK 3=Always
#export SADM_ALERT_GROUP="default"                          # Alert Group to advise
#export SADM_MAIL_ADDR="your_email@domain.com"              # Email to send log
#export SADM_MAX_LOGLINE=500                                # Nb Lines to trim(0=NoTrim)
#export SADM_MAX_RCLINE=35                                  # Nb Lines to trim(0=NoTrim)
#export SADM_PID_TIMEOUT=7200                               # Sec. before PID Lock expire
#export SADM_LOCK_TIMEOUT=3600                              # Sec. before Del. System LockFile
# --------------- ---  E N D   O F   S A D M I N   C O D E    S E C T I O N  -----------------------







# --------------------------------------------------------------------------------------------------
#              V A R I A B L E S    L O C A L   T O     T H I S   S C R I P T
# --------------------------------------------------------------------------------------------------
#
FIELD_IN_RCH=10                                 ; export FIELD_IN_RCH   # Nb of field in a RCH File
line_per_page=20                                ; export line_per_page  # Nb of line per scr page
xcount=0                                        ; export xcount         # Index for our array
xline_count=0                                   ; export xline_count    # Line display counter
HTML_FILE="${SADM_TMP_DIR}/${SADM_INST}.html"   ; export HTML_FILE      # HTML File sent to user
DEBUG_LEVEL=0                                   ; export DEBUG_LEVEL    # 0=NoDebug Higher=+Verbose
URL_VIEW_FILE='/view/log/sadm_view_file.php'    ; export URL_VIEW_FILE  # View File Content URL
SADM_TMP_FILE4=$(mktemp "$SADMIN/tmp/${SADM_INST}4_XXX") 


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





#===================================================================================================
#               D I S P L A Y    S C R E E N    H E A D I N G     F U N C T I O N 
#===================================================================================================
display_heading()
{
    if [ "$PAGER" = "ON" ] || ( [ "$PAGER" = "OFF" ]  &&  [ "$WATCH" = "ON" ] )
        then #tput clear ; 
             #echo -e "`date +%Y/%m/%d`                           Server Farm Scripts Summary Report \c"
             #echo -e "                            `date +%H:%M:%S`"  
             htitle="Server Farm Scripts Summary Report v${SADM_VER}"
             printf "%-32s %-65s " "`date +%Y/%m/%d`" "$htitle" 
             printf "%8s\n" "`date +%H:%M:%S`"
             printf "%67s     %-8s %-7s %-9s %-5s\n" "Start" "Start" "End" "Elapse" "Alert"
             printf "%-6s %-7s %-12s %-32s" "Count" "Status" "Server" "Script"
             printf "%6s %9s %8s %8s   %s\n" "Date" "Time" "Time" "Time" "Group/Type"
             printf "%108s\n" |tr " " "="
    fi
}



#===================================================================================================
#                 D I S P L A Y    L I N E    D E T A I L    F U N C T I O N  
#===================================================================================================
display_detail_line()
{
    DLINE=$1                                                            # Save Line Received
    WSERVER=` echo $DLINE | awk '{ print $1 }'`                         # Extract Server Name
    WDATE1=`  echo $DLINE | awk '{ print $2 }'`                         # Extract Date Started
    WTIME1=`  echo $DLINE | awk '{ print $3 }'`                         # Extract Time Started
    WDATE2=`  echo $DLINE | awk '{ print $4 }'`                         # Extract Date Started
    WTIME2=`  echo $DLINE | awk '{ print $5 }'`                         # Extract Time Ended
    WELAPSE=` echo $DLINE | awk '{ print $6 }'`                         # Extract Time Ended
    WSCRIPT=` echo $DLINE | awk '{ print $7 }'`                         # Extract Script Name
    WALERT=`  echo $DLINE | awk '{ print $8 }'`                         # Extract Alert Group Name
    WTYPE=`   echo $DLINE | awk '{ print $9 }'`                         # Extract Alert Group Type
    WRCODE=`  echo $DLINE | awk '{ print $10 }'`                        # Extract Last Field RCHCode
    case "$WRCODE" in                                                   # Case on RCH Return Code
        0 ) WRDESC="✔ Success"                                          # Code 0 = Success
            ;; 
        1 ) WRDESC="✖ Error  "                                          # Code 1 = Error
            ;;
        2 ) WRDESC="➜ Running"                                          # Code 2 = Script Running
            ;;
        * ) WRDESC="CODE $WRCODE"                                       # Illegal Code  Desc
            ;;                                                          
    esac
    RLINE1=`printf "%04d %10s %-12s %-30s " "$xcount" "$WRDESC" "${WSERVER}" "${WSCRIPT}"  `
    RLINE2=`printf "%s %s %s %s %s/%s"  "${WDATE1}" "${WTIME1}" "${WTIME2}" "${WELAPSE}" "${WALERT}" "${WTYPE}"`
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
    # SADMIN Server get ReturnCodeHistory (RCH) files from all clients via "sadm_fetch_clients.sh".
    # This is done at regular interval from the server crontab,(/etc/cron.d/sadm_server).
    # A temp file containing the LAST line of each *.rch file present in ${SADMIN}/www/dat dir.
    # ----------------------------------------------------------------------------------------------
    find $SADM_WWW_DAT_DIR -type f -name "*.rch" -exec tail -1 {} \; > $SADM_TMP_FILE2
    sort -t' ' -rk10,10 -k2,3 -k7,7 $SADM_TMP_FILE2 > $SADM_TMP_FILE1   # Sort by Return Code & date
    
    # Don´t shown script name specify in $SADMIN/cfg/sadmin.cfg under 'SADM_MONITOR_RECENT_EXCLUDE'
    for i in ${SADM_MONITOR_RECENT_EXCLUDE//,/ }
        do
        #sed "'/$i/d'" "$SADM_TMP_FILE1"
        grep -vi "$i" $SADM_TMP_FILE1 >  $SADM_TMP_FILE4
        cp $SADM_TMP_FILE4 $SADM_TMP_FILE1
    done


    # If Option '-s hostname' use on the command line to get the report for only one system.
    if [ "$SERVER_NAME" != "" ]                                         # CmdLine -s 1 server Report
        then sadm_write "Searching for $SERVER_NAME in RCH files.\n"    # Search ServerName in RCH
             grep -i "$SERVER_NAME" $SADM_TMP_FILE1 > $SADM_TMP_FILE2   # Keep only that server
             cp  $SADM_TMP_FILE2  $SADM_TMP_FILE1                       # That become working file
    fi

    # Check if working file is empty, then nothing to report
    if [ ! -s "$SADM_TMP_FILE1" ]                                       # No rch file record ??
       then sadm_write "No RCH File to process.\n"                      # Issue message to user
            return 1                                                    # Exit Function 
    fi
    
    # Now we put the last line of all rch file from the working temp file into an array.
    xcount=0 ; array=""                                                 # Initialize Array & Index
    touch $SADM_TMP_FILE3                                               # Field Number dont' match
    while read wline                                                    # Read Line from TEMP3 file
        do                                                              # Start of loop
        WNB_FIELD=`echo $wline | wc -w`                                 # Check Nb. Of field in Line
        if [ "$WNB_FIELD" -eq 0 ] ; then continue ; fi                  # Ignore Blank Line
        if [ "$WNB_FIELD" -ne "$FIELD_IN_RCH" ]                         # If NB.Field don't match
            then echo $wline >> $SADM_TMP_FILE3                         # Faulty Line to TMP3 file
                 SMESS1="[ERROR] Lines in RCH file should have ${FIELD_IN_RCH} fields," 
                 SMESS2="${SMESS1} line below have $WNB_FIELD and is ignore." 
                 sadm_write "${SMESS2}\n"                                # Advise User Line in Error
                 sadm_write "'$wline'\n"                                # Show Faulty Line to User
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
        WALERT=` echo -e $wline | awk '{ print $8 }'`                   # Extract Alert Group Name
        WTYPE=`  echo -e $wline | awk '{ print $9 }'`                   # Extract Alert Group Type
        WRCODE=` echo -e $wline | awk '{ print $10 }'`                  # Extract Return Code 
        
        # Create Status Code Description
        WRDESC="CODE $WRCODE"                                           # Illegal Code  Desc
        if [ "$WRCODE" = "0" ] ; then WRDESC="✔ Success" ; fi           # Code 0 = Success
        if [ "$WRCODE" = "1" ] ; then WRDESC="✖ Error  " ; fi           # Code 1 = Error
        if [ "$WRCODE" = "2" ] ; then WRDESC="➜ Running" ; fi           # Code 2 = Running
        
        # Insert Line in HTML Table
        echo -e "<tr>"  >> $HTML_FILE

        # Set Background Color - Color at https://www.w3schools.com/tags/ref_colornames.asp
        if (( $xcount%2 == 0 ))
           then BCOL="#ffffcc" ; FCOL="#000000" 
           else BCOL="#f2ffcc" ; FCOL="#000000"
        fi
        if [ "$WRCODE" = "0" ] ; then BCOL="#f2ffcc" ; FCOL="#000000" ; fi  # 0 = Success = Beige
        if [ "$WRCODE" = "1" ] ; then BCOL="Red"     ; FCOL="#000000" ; fi  # 1 = Error = Red
        if [ "$WRCODE" = "2" ] ; then BCOL="Yellow"  ; FCOL="#000000" ; fi  # 2 = Running = Yellow

        echo -e "<td align=center bgcolor=$BCOL><font color=$FCOL>$xcount</font></td>"  >> $HTML_FILE
        echo -e "<td align=center bgcolor=$BCOL><font color=$FCOL>$WDATE1</font></td>"  >> $HTML_FILE
        echo -e "<td align=center bgcolor=$BCOL><font color=$FCOL>$WRDESC</font></td>"  >> $HTML_FILE
        echo -e "<td align=center bgcolor=$BCOL><font color=$FCOL>$WSERVER</font></td>" >> $HTML_FILE

        # Insert Name of the Script with link to log if log is accessible
        echo -e "<td align=center bgcolor=$BCOL><font color=$FCOL>" >> $HTML_FILE
        LOGFILE="${WSERVER}_${WSCRIPT}.log"                             # Assemble log Script Name
        LOGNAME="${SADM_WWW_DAT_DIR}/${WSERVER}/log/${LOGFILE}"         # Add Dir. Path to Name
        LOGURL="https://sadmin.${SADM_DOMAIN}/${URL_VIEW_FILE}?filename=${LOGNAME}" # Url to View Log
        if [ -r "$LOGNAME" ]                                            # If log is Readable
            then echo "<a href='$LOGURL' "            >> $HTML_FILE     # Link to Access the Log
                 echo "title='View Script Log File'>" >> $HTML_FILE     # ToolTip to Show User
                 echo -e "$WSCRIPT</font></a></td>"   >> $HTML_FILE     # End of Link Definition
            else echo -e "$WSCRIPT</font></td>"       >> $HTML_FILE     # No Log = No LInk
        fi
        
        echo -e "<td align=center bgcolor=$BCOL><font color=$FCOL>$WTIME1</font></td>"  >> $HTML_FILE
        echo -e "<td align=center bgcolor=$BCOL><font color=$FCOL>$WTIME2</font></td>"  >> $HTML_FILE
        echo -e "<td align=center bgcolor=$BCOL><font color=$FCOL>$WELAPSE</font></td>" >> $HTML_FILE
        echo -e "<td align=center bgcolor=$BCOL><font color=$FCOL>$WALERT</font></td>" >> $HTML_FILE
        echo -e "</tr>\n" >> $HTML_FILE

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
    echo -e "<!DOCTYPE html><html>"                > $HTML_FILE
    echo -e "<head>"                              >> $HTML_FILE
    echo -e "<style>"                             >> $HTML_FILE
    #echo -e "th { color: white; background-color: #5e39ad;     padding: 5px; }"  >> $HTML_FILE
    echo -e "th { color: white; background-color: #9C905C;     padding: 5px; }"  >> $HTML_FILE
    echo -e "td { color: white; border-bottom: 1px solid #ddd; padding: 5px; }"  >> $HTML_FILE
#    echo -e "tr:nth-child(even) { background-color: #000000; }" >> $HTML_FILE
#    echo -e "tr:nth-child(odd)  { background-color: #f2f2f2; }" >> $HTML_FILE
    echo -e "tr:nth-child(even) { background-color: #E0D78C; }" >> $HTML_FILE
    echo -e "tr:nth-child(odd)  { background-color: #F5F5F5; }" >> $HTML_FILE
    echo -e "table, th, td { border: 0px solid black; border-collapse: collapse; }"  >> $HTML_FILE
    echo -e "</style>"                            >> $HTML_FILE
    echo -e "<meta charset='utf-8' />"            >> $HTML_FILE
    echo -e "<title>SADMIN Daily Summary Report</title>" >> $HTML_FILE
    echo -e "</head>\n<body>\n"         >> $HTML_FILE
    echo -e "<br><center><h1>Scripts Daily Report for `date`</h1></center>\n" >> $HTML_FILE

    # Produce Report of error/running scripts ------------------------------------------------------
    sadm_write "Producing Summary Report of 'Failed' scripts ...\n"
    xcount=0                                                            # Clear Line Counter  
    rm -f $SADM_TMP_FILE1 >/dev/null 2>&1                               # Make Sure it doesn't exist
    for wline in "${array[@]}"                                          # Process till End of array
        do                                                                          
        WRCODE=` echo $wline | awk '{ print $10 }'`                     # Extract Return Code 
        if [ "$WRCODE" = "0" ] ; then continue ; fi                     # If Script Succeeded = Skip 
        echo "$wline" >> $SADM_TMP_FILE1                                # Write Event to Tmp File1
        done 
    if [ -s "$SADM_TMP_FILE1" ]                                         # If Input file Size > 0 
        then sort -t' ' -rk10,10 $SADM_TMP_FILE1 > $SADM_TMP_FILE2      # Sort File by Return Code
             rch2html "$SADM_TMP_FILE2" "Latest error/running scripts"  # Print RCH File in HTML
    fi

    # Produce Report for Today ---------------------------------------------------------------------
    DATE1=`date --date="today" +"%Y.%m.%d"`                         # Date 1 day ago YYY.MM.DD
    sadm_write "Producing Email Summary Report for Today ($DATE1) ...\n"
    if [ $DEBUG_LEVEL -gt 0 ] ; then sadm_write "Date for Today : $DATE1 \n" ; fi
    # Isolate Today Event & Sort by Event Time afterward.
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
             rch2html "$SADM_TMP_FILE2" "Scripts executed Today ($DATE1)" 
    fi 

    # Produce Report for Yesterday -----------------------------------------------------------------
    DATE1=`date --date="yesterday" +"%Y.%m.%d"`                         # Date 1 day ago YYY.MM.DD
    sadm_write "Producing Email Summary Report for yesterday ($DATE1) ...\n"
    if [ $DEBUG_LEVEL -gt 0 ] ; then sadm_write "Date for 1 day ago  : $DATE1 \n" ; fi
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
             rch2html "$SADM_TMP_FILE2" "Scripts that was executed Yesterday ($DATE1)" 
    fi 

    # Produce Report for 2 days ago ----------------------------------------------------------------
    #DATE2=`date --date="-2 days" +"%Y.%m.%d"`                           # Date 2 days ago YYY.MM.DD
    #sadm_write "Producing Email Summary Report for 2 days ago ($DATE2) ...\n"
    #if [ $DEBUG_LEVEL -gt 0 ] ; then sadm_write "Date for 2 day ago  : $DATE2 \n" ;fi 
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
    sadm_write "Producing Email Summary Report for Status older than $SADM_RCH_KEEPDAYS days ($DATE3) ...\n"
    if [ $DEBUG_LEVEL -gt 0 ] ; then sadm_write "Date for $SADM_RCH_KEEPDAYS day ago: $DATE3 \n" ;fi 
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
        then sadm_write "Summary Report sent to $SADM_MAIL_ADDR \n"
        else sadm_write "Problem sending report to $SADM_MAIL_ADDR \n"
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
# Command line Options functions
# Evaluate Command Line Switch Options Upfront
# By Default (-h) Show Help Usage, (-v) Show Script Version,(-d0-9] Set Debug Level 
# --------------------------------------------------------------------------------------------------
function cmd_options()
{
    PAGER="ON" ; ERROR_ONLY="OFF" ; MAIL_ONLY="OFF" ; WATCH="OFF"       # Set Switch Default Value
    SERVER_NAME=""                                                      # Set Switch Default Value

    while getopts "hvd:epmws:" opt ; do                                 # Loop to process Switch
        case $opt in
            d) SADM_DEBUG=$OPTARG                                       # Get Debug Level Specified
               num=$(echo "$SADM_DEBUG" |grep -E "^\-?[0-9]?\.?[0-9]+$") # Valid if Level is Numeric
               if [ "$num" = "" ]                            
                  then printf "\nInvalid debug level.\n"                # Inform User Debug Invalid
                       show_usage                                       # Display Help Usage
                       exit 1                                           # Exit Script with Error
               fi
               printf "Debug level set to ${SADM_DEBUG}.\n"             # Display Debug Level
               ;;                                                       
            h) show_usage                                               # Show Help Usage
               exit 0                                                   # Back to shell
               ;;
            v) sadm_show_version                                        # Show Script Version Info
               exit 0                                                   # Back to shell
               ;;
            m) MAIL_ONLY="ON"                                           # Output goes to sysadmin
               PAGER="OFF"                                              # Mail need pager to be off
               ;;                                       
            e) ERROR_ONLY="ON"                                          # Display Only Error file 
               ;;
            s) SERVER_NAME="$OPTARG"                                    # Display One Server Name
               ;;
            w) WATCH="ON"                                               # Display 1st page Only        
               PAGER="OFF"                                              # Watch need pager to be off
               ;;                                                       # And it's refresh every Min
            p) PAGER="OFF"                                              # Display Continiously    
               ;;                                                       # No stop after each page
           \?) printf "\nInvalid option: ${OPTARG}.\n"                  # Invalid Option Message
               show_usage                                               # Display Help Usage
               exit 1                                                   # Exit with Error
               ;;
        esac                                                            # End of case
    done                                                                # End of while
    return 
}




# --------------------------------------------------------------------------------------------------
#                       S T A R T     O F    T H E    S C R I P T 
# --------------------------------------------------------------------------------------------------    cmd_options "$@"                                                    # Check command-line Options
    cmd_options "$@"                                                    # Check command-line Options
    sadm_start                                                    # Init Env. Dir & RC/Log File

    # Get the last line of all rch files in $SADMIN/www, sort results and Display them
    if [ "$WATCH" = "ON" ]                                              # If WATCH switch is ON
        then while :                                                    # Repeat the main process
                do                                                      # Repeat until CTRL-C 
                main_process                                            # Main Process
                done
        else main_process                                               # main Process all lines
    fi
    SADM_EXIT_CODE=$?                                                   # Save Process Exit Code

    # If invalid rch (not $FIELD_IN_RCH fileds in it), send email to sysadmin to check it out.
    if [ -s "$SADM_TMP_FILE3" ]                                         # If File size > than 0
        then wsubject="$SADM_INST - Invalid formatted line(s) in RCH file(s)"        # Mail Message
             printf "\n-----\n$wsubject\n"                              # Display Msg to user
             nl $SADM_TMP_FILE3                                         # Display file content
             wmess="See attachment for the list of lines without $FIELD_IN_RCH fields."
             wtime=$(date "+%Y.%m.%d %H:%M")
             sadm_sendmail "$SADM_MAIL_ADDR" "$wsubject" "$wmess" "$SADM_TMP_FILE3"
    fi
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log 
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
    