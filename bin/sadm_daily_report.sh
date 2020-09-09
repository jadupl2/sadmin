#! /usr/bin/env bash
# --------------------------------------------------------------------------------------------------
#   Author      :  Jacques Duplessis
#   Script name :  sadm_daily_report.sh
#   Synopsis    :  Display Last 24 Hrs Activities Summary & biggest Backup Files and Directories. 
#   Version     :  1.0
#   Date        :  30 Juillet 2020
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
#
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPT The Control-C
#set -x




#===================================================================================================
# To use the SADMIN tools and libraries, this section MUST be present near the top of your code.
# SADMIN Section - Setup SADMIN Global Variables and Load SADMIN Shell Library
#===================================================================================================

    # MAKE SURE THE ENVIRONMENT 'SADMIN' IS DEFINED, IF NOT EXIT SCRIPT WITH ERROR.
    if [ -z $SADMIN ] || [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]          # If SADMIN EnvVar not right
        then printf "\nPlease set 'SADMIN' environment variable to the install directory."
             EE="/etc/environment" ; grep "SADMIN=" $EE >/dev/null      # SADMIN in /etc/environment
             if [ $? -eq 0 ]                                            # Yes it is 
                then export SADMIN=`grep "SADMIN=" $EE |sed 's/export //g'|awk -F= '{print $2}'`
                     printf "\n'SADMIN' Environment variable was temporarily set to ${SADMIN}.\n"
                else exit 1                                             # No SADMIN Env. Var. Exit
             fi
    fi 

    # USE CONTENT OF VARIABLES BELOW, BUT DON'T CHANGE THEM (Used by SADMIN Standard Library).
    export SADM_PN=${0##*/}                             # Current Script filename(with extension)
    export SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1`   # Current Script filename(without extension)
    export SADM_TPID="$$"                               # Current Script PID
    export SADM_HOSTNAME=`hostname -s`                  # Current Host name without Domain Name
    export SADM_OS_TYPE=`uname -s | tr '[:lower:]' '[:upper:]'` # Return LINUX,AIX,DARWIN,SUNOS 

    # USE AND CHANGE VARIABLES BELOW TO YOUR NEEDS (They influence execution of standard library).
    export SADM_VER='1.0'                               # Your Current Script Version
    export SADM_LOG_TYPE="B"                            # Writ#set -x
    export SADM_LOG_APPEND="N"                          # [Y]=Append Existing Log [N]=Create New One
    export SADM_LOG_HEADER="Y"                          # [Y]=Include Log Header  [N]=No log Header
    export SADM_LOG_FOOTER="Y"                          # [Y]=Include Log Footer  [N]=No log Footer
    export SADM_MULTIPLE_EXEC="N"                       # Allow running multiple copy at same time ?
    export SADM_USE_RCH="Y"                             # Generate Entry in Result Code History file
    export SADM_DEBUG=0                                 # Debug Level - 0=NoDebug Higher=+Verbose
    export SADM_TMP_FILE1=""                            # Temp File1 you can use, Libr will set name
    export SADM_TMP_FILE2=""                            # Temp File2 you can use, Libr will set name
    export SADM_TMP_FILE3=""                            # Temp File3 you can use, Libr will set name
    export SADM_EXIT_CODE=0                             # Current Script Default Exit Return Code

    . ${SADMIN}/lib/sadmlib_std.sh                      # Load Standard Shell Library Functions
    export SADM_OS_NAME=$(sadm_get_osname)              # O/S in Uppercase,REDHAT,CENTOS,UBUNTU,...
    export SADM_OS_VERSION=$(sadm_get_osversion)        # O/S Full Version Number  (ex: 7.6.5)
    export SADM_OS_MAJORVER=$(sadm_get_osmajorversion)  # O/S Major Version Number (ex: 7)

#---------------------------------------------------------------------------------------------------
# Values of these variables are loaded from SADMIN config file ($SADMIN/cfg/sadmin.cfg file).
# They can be overridden here, on a per script basis (if needed).
    #export SADM_ALERT_TYPE=1                           # 0=None 1=AlertOnErr 2=AlertOnOK 3=Always
    #export SADM_ALERT_GROUP="default"                  # Alert Group to advise (alert_group.cfg)
    #export SADM_MAIL_ADDR="your_email@domain.com"      # Email to send log (To override sadmin.cfg)
    #export SADM_MAX_LOGLINE=500                        # At the end Trim log to 500 Lines(0=NoTrim)
    #export SADM_MAX_RCLINE=35                          # At the end Trim rch to 35 Lines (0=NoTrim)
    #export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} " # SSH Command to Access Server 
#===================================================================================================


  

#===================================================================================================
# Global Scripts Variables 
#===================================================================================================

export FIELD_IN_RCH=10                                                  # Nb of field in a RCH File
export TOTAL_ERROR=0                                                    # Total Error in script
#
# Backup Report 
export bb_file=$(mktemp --suffix ".txt")                                # Biggest Backup Files
export bb_dir=$(mktemp --suffix ".txt")                                 # Biggest Backup Directories
export bb_fcount=20                                                     # Nb Files to show in report
export bb_dcount=20                                                     # Nb Dir. to show in report


# The Backup Information are taken from SADMIN Configuration file ($SADMIN/cfg/sadmin.cfg)
# (Example below)
# $SADM_BACKUP_NFS_SERVER          NFS Backup IP or Server Name        : .batnas.maison.ca.
# $SADM_BACKUP_NFS_MOUNT_POINT     NFS Backup Mount Point              : ./volume1/backup_linux.
# The field indicate the number of fields included in each line of an '*.rch' file.

# Define NFS local mount point
if [ "$SADM_OS_TYPE" = "DARWIN" ]                                       # If on MacOS
    then export LOCAL_MOUNT="/preserve/daily_report.$$nfs"              # NFS Mount Point for OSX
    else export LOCAL_MOUNT="/mnt/daily_report.$$"                      # NFS Mount Point for Linux
fi  

# Previous data for summary script
line_per_page=20                                ; export line_per_page  # Nb of line per scr page
xcount=0                                        ; export xcount         # Index for our array
xline_count=0                                   ; export xline_count    # Line display counter
HTML_FILE="${SADM_TMP_DIR}/${SADM_INST}.html"   ; export HTML_FILE      # HTML File sent to user
DEBUG_LEVEL=0                                   ; export DEBUG_LEVEL    # 0=NoDebug Higher=+Verbose
URL_VIEW_FILE='/view/log/sadm_view_file.php'    ; export URL_VIEW_FILE  # View File Content URL







# --------------------------------------------------------------------------------------------------
# Show Script command line option
# --------------------------------------------------------------------------------------------------
show_usage()
{
    printf "\n$Syntax: {SADM_PN} [-d|-h|-v|-p|-w|-s|-m]"
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
        then tput clear ; 
             #echo -e "`date +%Y/%m/%d`                           Server Farm Scripts Summary Report \c"
             #echo -e "                            `date +%H:%M:%S`"  
             printf "%-32s %-65s " "`date +%Y/%m/%d`" "Server Farm Scripts Summary Report" 
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
# SADMIN Server get ReturnCodeHistory (RCH) files from all clients via "sadm_fetch_clients.sh" 
# This is done at regular interval from the SADMIN server crontab, via '/etc/cron.d/sadm_server'
#    
# Create a file containing last line of all *.rch locate within $SADMIN/wwww/dat sub-directories.
# Then sort it by Return Code in Reverse order then by date, then by server into $SADM_TMP_FILE1 
# Then lines are loaded into an array.
# While reading each line, if any line don't have $FIELD_IN_RCH fields it's added to $SADM_TMP_FILE3
#
#===================================================================================================
load_array()
{
    # Create temp file containing the LAST line of each *.rch file present in ${SADMIN}/www/dat dir.
    find $SADM_WWW_DAT_DIR -type f -name "*.rch" -exec tail -1 {} \; > $SADM_TMP_FILE2
    sort -t' ' -rk10,10 -k2,3 -k7,7 $SADM_TMP_FILE2 > $SADM_TMP_FILE1   # Sort by Return Code & date

    # If cmdline option '-s' is used, we keep only the selected server in the temp work file.
    if [ "$SERVER_NAME" != "" ]                                         # CmdLine -s 1 server Report
        then sadm_write "Searching for $SERVER_NAME in RCH files.\n"    # Search ServerName in RCH
             grep -i "$SERVER_NAME" $SADM_TMP_FILE1 > $SADM_TMP_FILE2   # Keep only that server
             cp  $SADM_TMP_FILE2  $SADM_TMP_FILE1                       # That become working file
    fi

    # Check if working temp file is empty, then nothing to report
    if [ ! -s "$SADM_TMP_FILE1" ]                                       # No rch file record ??
       then sadm_write "No RCH File to process.\n"                      # Issue message to user
            return 1                                                    # Exit Function 
    fi
    
    # Now we put the last line of all rch file from the working temp file into an array.
    xcount=0 ; array=""                                                 # Initialize Array & Index
    touch $SADM_TMP_FILE3                                               # RCH Format Error file
    while read wline                                                    # Read Line from TEMP3 file
        do                                                              # Start of loop
        WNB_FIELD=`echo $wline | wc -w`                                 # Check Nb. Of field in Line
        if [ "$WNB_FIELD" -eq 0 ] ; then continue ; fi                  # Ignore Blank Line
        if [ "$WNB_FIELD" -ne "$FIELD_IN_RCH" ]                         # If NB.Field don't match
            then echo $wline >> $SADM_TMP_FILE3                         # Faulty Line to TMP3 file
                 SMESS1="$SADM_ERROR Lines in RCH file should have ${FIELD_IN_RCH} fields," 
                 SMESS2="${SMESS1} line below have $WNB_FIELD and is ignore." 
                 sadm_write "${SMESS2}\n"                               # Advise User Line in Error
                 sadm_write "'$wline'\n"                                # Show Faulty Line to User
                 continue                                               # Go on and read next line
        fi
        array[$xcount]="$wline"                                         # Insert line in Array
        xcount=$(($xcount+1))                                           # Increment Array Index
        done < $SADM_TMP_FILE1                                          # End Loop - Input FileName
    return 0
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
    echo -e "tr:nth-child(even) { background-color: #E0D78C; }" >> $HTML_FILE
    echo -e "tr:nth-child(odd)  { background-color: #F5F5F5; }" >> $HTML_FILE
    echo -e "table, th, td { border: 0px solid black; border-collapse: collapse; }"  >> $HTML_FILE
    echo -e "</style>"                            >> $HTML_FILE
    echo -e "<meta charset='utf-8' />"            >> $HTML_FILE
    echo -e "<title>SADMIN Daily Report</title>" >> $HTML_FILE
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

# ==================================================================================================
# Send Reports Generated by Email.
# ==================================================================================================
send_email_report()
{

    body="Here's the Daily SADMIN Report "
    subject="Daily SADMIN Report"
    if [ "$SADM_OS_NAME" = "REDHAT" ] || [ "$SADM_OS_NAME" = "CENTOS" ] || [ "$SADM_OS_NAME" = "FEDORA" ]
        then echo "$body" | mail -s "$subject" -a $bb_dir -a $bb_file $SADM_MAIL_ADDR  
        else echo "$body" | mail -s "$subject" --attach=$bb_dir --attach=$bb_file $SADM_MAIL_ADDR
    fi 
}



# ==================================================================================================
# Mount the NFS Directory where all the ReaR backup files are stored 
# Produce a list of the latest backup for every systems.
# ==================================================================================================
rear_report() 
{

    # Make sure Local mount point exist.
    REAR_NFS_MOUNT_POINT="/mnt/rearnfs.$$" 
    if [ ! -d ${REAR_NFS_MOUNT_POINT} ] 
        then sadm_write "Create NFS local mount point ReaR directory (${REAR_NFS_MOUNT_POINT}).\n" 
             mkdir ${REAR_NFS_MOUNT_POINT} ; chmod 775 ${REAR_NFS_MOUNT_POINT} 
     fi

    # Mount the NFS Mount point 
    sadm_write "\n" 
    sadm_write "Mount the NFS share on $SADM_REAR_NFS_SERVER system.\n"
    umount ${REAR_NFS_MOUNT_POINT} > /dev/null 2>&1                     # Assure not already mounted
    sadm_write "mount ${SADM_REAR_NFS_SERVER}:${SADM_REAR_NFS_MOUNT_POINT} ${REAR_NFS_MOUNT_POINT} "
    mount ${SADM_REAR_NFS_SERVER}:${SADM_REAR_NFS_MOUNT_POINT} ${REAR_NFS_MOUNT_POINT} >>$SADM_LOG 2>&1
    if [ $? -ne 0 ]
        then RC=1
             sadm_write "$SADM_ERROR NFS Mount failed - Process Aborted.\n"
             umount ${REAR_NFS_MOUNT_POINT} > /dev/null 2>&1
             rmdir  ${REAR_NFS_MOUNT_POINT} > /dev/null 2>&1
             return 1
    fi
    sadm_write "$SADM_OK \n"
    df -h | grep ${REAR_NFS_MOUNT_POINT} | sed 's/%//g' | while read wline ; do sadm_write "${wline}\n"; done


}


# ==================================================================================================
# Mount the NFS Backup Directory where all the backup files are stored
# ==================================================================================================
mount_nfs_backup()
{
    # Make sur the Local Mount Point Exist ---------------------------------------------------------
    if [ ! -d ${LOCAL_MOUNT} ]                                          # Mount Point doesn't exist
        then sadm_write "Create local mount point ${LOCAL_MOUNT}\n"     # Advise user we create Dir.
             mkdir ${LOCAL_MOUNT}                                       # Create if not exist
             if [ $? -ne 0 ]                                            # If Error trying to mount
                then sadm_write "${SADM_ERROR} Creating local mount point - Process aborted.\n"
                return 1                                                # End Function with error
             fi
             chmod 775 ${LOCAL_MOUNT}                                   # Change Permission 
    fi

    # Mount the NFS Drive - Where the Backup file will reside -----------------------------------------
    REM_MOUNT="${SADM_BACKUP_NFS_SERVER}:${SADM_BACKUP_NFS_MOUNT_POINT}"
    #sadm_write "Mounting NFS Drive on ${SADM_BACKUP_NFS_SERVER} "       # Show NFS Server Name
    umount ${LOCAL_MOUNT} > /dev/null 2>&1                              # Make sure not mounted
    if [ "$SADM_OS_TYPE" = "DARWIN" ]                                   # If on MacOS
        then sadm_write "mount -t nfs -o resvport,rw ${REM_MOUNT} ${LOCAL_MOUNT} "
             mount -t nfs -o resvport,rw ${REM_MOUNT} ${LOCAL_MOUNT} >>$SADM_LOG 2>&1
             RC=$?                                                      # Save Return Code
        else sadm_write "mount ${REM_MOUNT} ${LOCAL_MOUNT} "            # If on Linux/Aix
             mount ${REM_MOUNT} ${LOCAL_MOUNT} >>$SADM_LOG 2>&1         # Mount NFS Drive
             RC=$?                                                      # Save Return Code
    fi
    if [ $RC -ne 0 ]                                                    # If Error trying to mount
        then sadm_write "${SADM_ERROR}\n"                               # Error - Advise User
             return 1                                                   # End Function with error
        else sadm_write "${SADM_SUCCESS}\n"                             # NFS Mount Succeeded Msg
    fi
    return 0
}



# ==================================================================================================
# Unmount NFS Backup Directory
# ==================================================================================================
umount_nfs_backup()
{
    sadm_write "Unmounting NFS mount directory ${LOCAL_MOUNT} "
    umount $LOCAL_MOUNT >> $SADM_LOG 2>&1                               # Umount Just to make sure
    if [ $? -ne 0 ]                                                     # If Error trying to mount
        then sadm_write "${SADM_ERROR}\n"
             return 1                                                   # End Function with error
        else sadm_write "${SADM_SUCCESS}\n" 
    fi
    return 0
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

    # Mount the NFS Backup Directory (mount batnas.maison.ca:/volume1/backup_linux /mnt/backup)
    mount_nfs_backup                                                           # Mount NFS Dir.
    if [ $? -ne 0 ] ; then umount_nfs_backup ; sadm_stop 1 ; exit 1 ; fi       # If Error While Mount NFS

    # Generating a list of the biggest backup files.
    SAVE_PWD=$(pwd)                                                     # Save Current Working Dir.
    cd ${LOCAL_MOUNT}                                                   # CD in Backup Directory
    sadm_write "Generating report of the $bb_fcount biggest backup files "
    echo "List of the $bb_fcount biggest backup files." > $bb_file
    find . -type f -exec ls -s1 {} \; | sort -rn | head -$bb_fcount | nl >> $bb_file 2>&1
    if [ $? -ne 0 ]                                                     # If Error running find
        then sadm_write "${SADM_ERROR}\n"                               # Signal Error to user
             TOTAL_ERROR=$(($TOTAL_ERROR+1))                            # Incr. Cumulative Total Err
        else sadm_write "${SADM_SUCCESS}\n"                             # Signal Success to User
    fi

    # Generating a list of the biggest backup Directories.
    sadm_write "Generating report of the $bb_dcount biggest backup directories "
    echo "List of the $bb_dcount biggest backup directories" > $bb_dir
    du -kx . | sort -rn |  head -$bb_dcount | nl >> $bb_dir 2>&1
    if [ $? -ne 0 ]                                                     # If Error running find
        then sadm_write "${SADM_ERROR}\n"                               # Signal Error to user
             TOTAL_ERROR=$(($TOTAL_ERROR+1))                            # Incr. Cumulative Total Err
        else sadm_write "${SADM_SUCCESS}\n"                             # Signal Success to User
    fi
    cd $SAVE_PWD                                                        # Return to original Dir.
    umount_nfs_backup                                                   # Umounting NFS Drive

    tput clear  
    sadm_write "${BOLD}${BLUE}Biggest Backup Files Report${NORMAL}\n"
    cat $bb_file
    #echo "Press [ENTER] to continue" ; read dummy

    tput clear  
    sadm_write "${BOLD}${BLUE}Biggest Backup Directories Report${NORMAL}\n"
    cat $bb_dir
    #echo "Press [ENTER] to continue" ; read dummy

    send_email_report


#    # Process each line in the array just loaded and display them
#    # ----------------------------------------------------------------------------------------------
#    xcount=0; xline_count=0 ;                                           # Clear Index and Linecount
#    rm -f $SADM_TMP_FILE2                                               # Clear Email file
#    for wline in "${array[@]}"                                          # Process till End of array
#        do                                                                          
#        if [ "$xcount" -eq 0 ]  ; then display_heading ; fi             # 1st Time display heading
#        if [ "$xline_count" -ge "$line_per_page" ]                      # If End of Page length
#            then if [ "$PAGER" = "ON" ]                                 # If Pager is on
#                    then echo "Press [ENTER] for next page or CTRL-C to end"
#                         read dummy                                     # Wait till enter is press
#                         display_heading                                # Clr Screen & Display Head
#                         if [ "$xcount" -ne 0 ] ;then xline_count=0 ;fi # Reset Line no on page
#                    else if [ "$WATCH" = "ON" ]                         # If No Pager & Watch ON
#                            then echo "This page will refresh every 60 seconds"
#                                 sleep 60                               # Sleep 60 Seconds
#                                 return 0                               # Return to Caller
#                         fi
#                 fi
#        fi
#        xcount=$(($xcount+1))                                           # Incr. Cumulative Lineno
#        xline_count=$(($xline_count+1))                                 # Incr. Lineno on Page
#        display_detail_line "$wline"                                    # Go Display Line
#        done
#    
#    # If Mail Switch is ON - Send what usually displayed to Sysadmin
#    if [ "$MAIL_ONLY" = "ON" ] ; then mail_report ; fi                  # mail switch ON = Email Rep
#
    # Delete NFS Local Mount point
    if [ -d "$LOCAL_MOUNT" ] ; then rm -f "$LOCAL_MOUNT" >/dev/null 2>&1 ; fi 

    return 0                                                            # Return Default return code
}


#===================================================================================================
# Process all your active(s) server(s) found in Database.
#===================================================================================================
process_servers()
{
    sadm_write "${BOLD}${YELLOW}Processing All Active(s) Server(s) ...${NORMAL}\n"

    # Put Rows you want in the select. 
    # See rows available in 'table_structure_server.pdf' in $SADMIN/doc/database_info directory
    SQL="SELECT srv_name,srv_desc,srv_ostype,srv_domain,srv_monitor,srv_sporadic,srv_active" 
    SQL="${SQL},srv_sadmin_dir,srv_backup,srv_img_backup "

    # Build SQL to select active server(s) from Database.
    SQL="${SQL} from server"                                            # From the Server Table
    SQL="${SQL} where srv_active = True"                                # Select only Active Servers
    SQL="${SQL} order by srv_name; "                                    # Order Output by ServerName
    
    # Execute SQL Query to Create CSV in SADM Temporary work file ($SADM_TMP_FILE1)
    CMDLINE="$SADM_MYSQL -u $SADM_RO_DBUSER  -p$SADM_RO_DBPWD "         # MySQL Auth/Read Only User
    if [ $SADM_DEBUG -gt 5 ] ; then sadm_write "${CMDLINE}\n" ; fi      # Debug Show Auth cmdline
    $CMDLINE -h $SADM_DBHOST $SADM_DBNAME -Ne "$SQL" | tr '/\t/' '/,/' >$SADM_TMP_FILE1
    if [ ! -s "$SADM_TMP_FILE1" ] || [ ! -r "$SADM_TMP_FILE1" ]         # File not readable or 0 len
        then sadm_write "$SADM_WARNING No Active Server were found.\n"  # Not Active Server MSG
             return 0                                                   # Return Status to Caller
    fi 
    
    tput clear 
    echo "WORK FILE" 
    cat $SADM_TMP_FILE1
    return 0 
#   debian10,Debian 10 - Test Server,linux,maison.ca,1,1,1,/opt/sadmin,1,1
#   debian9,Debian 9 Test System,linux,maison.ca,1,0,1,/opt/sadmin,1,1
#   fedora32,Fedora 32 - Test Server,linux,maison.ca,1,0,1,/opt/sadmin,1,1
#   gumby,Red Hat Enterprise V5,linux,maison.ca,1,0,1,/sadmin,1,1
#   holmes,sadmin,dns,wiki,history,dhcp..,linux,maison.ca,1,0,1,/sadmin,1,1
#   lestrade,Ubuntu 20.04 Desktop,linux,maison.ca,1,0,1,/opt/sadmin,1,1
#   nomad,CentOS 6 Server,linux,maison.ca,1,0,1,/sadmin,1,1
#   raspi0,Raspberry Pi Model Zero W R1.1,linux,maison.ca,1,0,1,/opt/sadmin,1,0
#   
    xcount=0; ERROR_COUNT=0;                                            # Set Server & Error Counter
    while read wline                                                    # Read Tmp file Line by Line
        do
        xcount=$(($xcount+1))                                           # Increase Server Counter
        server_name=$(echo $wline      |awk -F, '{print $1}')           # Extract Server Name
        server_desc=$(echo $wline      |awk -F, '{print $2}')           # Extract Server Description
        server_os=$(echo $wline        |awk -F, '{print $3}')           # O/S (linux/aix/darwin)
        server_domain=$(echo $wline    |awk -F, '{print $4}')           # Extract Domain of Server
        server_monitor=$(echo $wline   |awk -F, '{print $5}')           # Monitor  1=True 0=False
        server_sporadic=$(echo $wline  |awk -F, '{print $6}')           # Sporadic 1=True 0=False
        server_active=$(echo $wline    |awk -F, '{print $7}')           # Active   1=Yes  0=No
        server_rootdir=$(echo $wline   |awk -F, '{print $8}')           # Client SADMIN Root Dir.
        server_backup=$(echo $wline    |awk -F, '{print $9}')           # Backup Schd 1=True 0=False
        server_img_backup=$(echo $wline|awk -F, '{print $10}')          # ReaR Sched. 1=True 0=False
        #
        fqdn_server=`echo ${server_name}.${server_domain}`              # Create FQDN Server Name
        sadm_write "\n"                                                 # Blank Line
        sadm_write "${SADM_TEN_DASH}\n"                                 # Ten Dashes Line    
        sadm_write "Processing ($xcount) ${fqdn_server}.\n"             # Server Count & FQDN Name 

        # Check if server name can be resolve - If not, we won't be able to SSH to it.
        host  $fqdn_server >/dev/null 2>&1                              # Try to resolve Hostname
        if (( $? ))                                                     # If hostname not resolvable
            then SMSG="$SADM_ERROR Can't process '$fqdn_server', hostname can't be resolved."
                 sadm_writelog "${SMSG}"                                # Advise user & Feed log
                 ERROR_COUNT=$(($ERROR_COUNT+1))                        # Increase Error Counter
                 sadm_write "Total error(s) : ${ERROR_COUNT}\n"         # Show Total Error Count
                 continue                                               # Continue with next Server
        fi

        # Try a SSH to Host Name
        if [ $SADM_DEBUG -gt 0 ] ;then sadm_write "$SADM_SSH_CMD $fqdn_server date\n" ; fi 
        if [ "$fqdn_server" != "$SADM_SERVER" ]                         # If Not on SADMIN Server
            then $SADM_SSH_CMD $fqdn_server date > /dev/null 2>&1       # SSH to Server & Run 'date'
                 RC=$?                                                  # Save Return Code Number
            else RC=0                                                   # No SSH to SADMIN Server
        fi
        if [ $SADM_DEBUG -gt 0 ] ;then sadm_write "Return Code: ${RC}\n" ;fi # Show SSH Status

        # If SSH failed and it's a Sporadic Server, Show Warning and continue with next system.
        if [ $RC -ne 0 ] &&  [ "$server_sporadic" = "1" ]               # SSH don't work & Sporadic
            then sadm_writelog "${SADM_WARNING} Can't SSH to sporadic system ${fqdn_server}."
                 sadm_write "Continuing with next system\n"             # Not Error if Sporadic Srv. 
                 continue                                               # Continue with next system
        fi

        # If SSH Failed & Monitoring is Off, Show Warning and continue with next system.
        if [ $RC -ne 0 ] &&  [ "$server_monitor" = "0" ]                # SSH don't work/Monitor OFF
            then sadm_writelog "$SADM_WARNING Can't SSH to $fqdn_server - Monitoring is OFF"
                 sadm_write "Continuing with next system\n"             # Not Error if don't Monitor
                 continue                                               # Continue with next system
        fi

        # If All SSH test failed, Issue Error Message and continue with next system
        if (( $RC ))                                                    # If SSH to Server Failed
            then SMSG="$SADM_ERROR Can't SSH to '${fqdn_server}'"       # Problem with SSH
                 sadm_writelog "${SMSG}"                                # Show/Log Error Msg
                 ERROR_COUNT=$(($ERROR_COUNT+1))                        # Increase Error Counter
                 continue                                               # Continue with next system
        fi
        if [ "$fqdn_server" != "$SADM_SERVER" ]                         # If not on SADMIN Server
            then sadm_writelog "$SADM_OK SSH to ${fqdn_server} work"     # Good SSH Work on Client
            else sadm_writelog "$SADM_OK No SSH using 'root' on the SADMIN Server ($SADM_SERVER)"
        fi

        # PROCESSING CAN BE PUT HERE
        # ........
        # ........
        done < $SADM_TMP_FILE1
    return $ERROR_COUNT                                                 # Return Err Count to caller
}



# --------------------------------------------------------------------------------------------------
# Command line Options functions
# Evaluate Command Line Switch Options Upfront
# By Default (-h) Show Help Usage, (-v) Show Script Version,(-d0-9] Set Debug Level 
# --------------------------------------------------------------------------------------------------
function cmd_options()
{
    # Set command line switch default
    PAGER="ON" ; ERROR_ONLY="OFF" ; MAIL_ONLY="OFF"                     # Set Switch Default Value
    SERVER_NAME=""                                                      # All Servers Default Value

    while getopts "hvd:epms:" opt ; do                                  # Loop to process Switch
        case $opt in
            m) MAIL_ONLY="ON"                                           # Output goes to sysadmin
               PAGER="OFF"                                              # Mail need pager to be off
               ;;                                       
            e) ERROR_ONLY="ON"                                          # Display Only Error file 
               ;;
            s) SERVER_NAME="$OPTARG"                                    # Display Only Server Name
               ;;
            p) PAGER="OFF"                                              # Display Continiously    
               ;;                                                       # No stop after each page
            d) SADM_DEBUG=$OPTARG                                       # Get Debug Level Specified
               num=`echo "$SADM_DEBUG" | grep -E ^\-?[0-9]?\.?[0-9]+$`  # Valid is Level is Numeric
               if [ "$num" = "" ]                                       # No it's not numeric 
                  then printf "\nDebug Level specified is invalid.\n"   # Inform User Debug Invalid
                       show_usage                                       # Display Help Usage
                       exit 1                                           # Exit Script with Error
               fi
               printf "Debug Level set to ${SADM_DEBUG}."               # Display Debug Level
               ;;                                                       
            h) show_usage                                               # Show Help Usage
               exit 0                                                   # Back to shell
               ;;
            v) sadm_show_version                                        # Show Script Version Info
               exit 0                                                   # Back to shell
               ;;
           \?) printf "\nInvalid option: -${OPTARG}.\n"                 # Invalid Option Message
               show_usage                                               # Display Help Usage
               exit 1                                                   # Exit with Error
               ;;
        esac                                                            # End of case
    done                                                                # End of while
    return 
}



# --------------------------------------------------------------------------------------------------
#                       S T A R T     O F    T H E    S C R I P T 
# --------------------------------------------------------------------------------------------------

    cmd_options "$@"                                                    # Check command-line Options    
    sadm_start                                                          # Create Dir.,PID,log,rch
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if 'Start' went wrong

    # If current user is not 'root', exit to O/S with error code 1 (Optional)
    if ! [ $(id -u) -eq 0 ]                                             # If Cur. user is not root 
        then sadm_write "Script can only be run by the 'root' user, process aborted.\n"
             sadm_write "Try sudo %s" "${0##*/}\n"                      # Suggest using sudo
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi

    # If we are not on the SADMIN Server, exit to O/S with error code 1 (Optional)
    if [ "$(sadm_get_fqdn)" != "$SADM_SERVER" ]                         # Only run on SADMIN 
        then sadm_write "Script can only be run on (${SADM_SERVER}), process aborted.\n"
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi
    process_servers
    main_process                                                        # main Process
    SADM_EXIT_CODE=$?                                                   # Save Process Exit Code
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log 
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
    
