#! /usr/bin/env bash
# --------------------------------------------------------------------------------------------------
#   Author      :  Jacques Duplessis
#   Script name :  sadm_daily_report.sh
#   Synopsis    :  Produce reports of the last 24 hrs activities and email it to the sysadmin.
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
# 2020_09_23 V1.1 In Progress September 
#@2020_10_01 Update: v1.2 First Release
#@2020_10_05 Update: v1.3 Daily Backup Report & ReaR Backup Report now available.
#@2020_10_06 Fix: v1.4 Bug that get Current backup size in yellow, when shouldn't.
#@2020_10_06 Update: v1.5 Minor Typo Corrections
#@2020_10_29 Update: v1.6 Change CmdLine Switch & Storix Daily report is working
#
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPT The Control-C
#set -x




#===================================================================================================
# SADMIN Section - Setup SADMIN Global Variables and Load SADMIN Shell Library
# To use the SADMIN tools and libraries, this section MUST be present near the top of your code.
#===================================================================================================
#
    # MAKE SURE THE ENVIRONMENT 'SADMIN' IS DEFINED, IF NOT EXIT SCRIPT WITH ERROR.
    if [ -z $SADMIN ] || [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]          # If SADMIN EnvVar not right
        then printf "\nPlease set 'SADMIN' environment variable to the install directory.\n"
             EE="/etc/environment" ; grep "SADMIN=" $EE >/dev/null      # SADMIN in /etc/environment
             if [ $? -eq 0 ]                                            # Yes it is 
                then export SADMIN=`grep "SADMIN=" $EE |sed 's/export //g'|awk -F= '{print $2}'`
                     printf "'SADMIN' Environment variable temporarily set to ${SADMIN}.\n"
                else exit 1                                             # No SADMIN Env. Var. Exit
             fi
    fi 

    # USE VARIABLES BELOW, BUT DON'T CHANGE THEM (Used by SADMIN Standard Library).
    export SADM_PN=${0##*/}                             # Current Script filename(with extension)
    export SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1`   # Current Script filename(without extension)
    export SADM_TPID="$$"                               # Current Script Process ID.
    export SADM_HOSTNAME=`hostname -s`                  # Current Host name without Domain Name
    export SADM_OS_TYPE=`uname -s | tr '[:lower:]' '[:upper:]'` # Return LINUX,AIX,DARWIN,SUNOS 

    # USE AND CHANGE VARIABLES BELOW TO YOUR NEEDS (They influence execution of SADMIN Std Libr.).
    export SADM_VER='1.6'                               # Current Script Version
    export SADM_EXIT_CODE=0                             # Current Script Default Exit Return Code
    export SADM_LOG_TYPE="B"                            # writelog go to [S]creen [L]ogFile [B]oth
    export SADM_LOG_APPEND="N"                          # [Y]=Append Existing Log [N]=Create New One
    export SADM_LOG_HEADER="Y"                          # [Y]=Include Log Header  [N]=No log Header
    export SADM_LOG_FOOTER="Y"                          # [Y]=Include Log Footer  [N]=No log Footer
    export SADM_MULTIPLE_EXEC="N"                       # Allow running multiple copy at same time ?
    export SADM_USE_RCH="Y"                             # Gen. History Entry in ResultCodeHistory 
    export SADM_DEBUG=0                                 # Debug Level - 0=NoDebug Higher=+Verbose
    export SADM_TMP_FILE1=""                            # Tmp File1 you can use, Libr. will set name
    export SADM_TMP_FILE2=""                            # Tmp File2 you can use, Libr. will set name
    export SADM_TMP_FILE3=""                            # Tmp File3 you can use, Libr. will set name

    # LOAD SADMIN SHELL LIBRARY AND SET SOME O/S VARIABLES.
    . ${SADMIN}/lib/sadmlib_std.sh                      # LOAD SADMIN Standard Shell Libr. Functions
    export SADM_OS_NAME=$(sadm_get_osname)              # O/S in Uppercase,REDHAT,CENTOS,UBUNTU,...
    export SADM_OS_VERSION=$(sadm_get_osversion)        # O/S Full Version Number  (ex: 9.0.1)
    export SADM_OS_MAJORVER=$(sadm_get_osmajorversion)  # O/S Major Version Number (ex: 9)

    # VALUES OF VARIABLES BELOW ARE LOADED FROM SADMIN CONFIG FILE ($SADMIN/CFG/SADMIN.CFG FILE).
    # THEY CAN BE OVERRIDDEN HERE, ON A PER SCRIPT BASIS (IF NEEDED).
    #export SADM_ALERT_TYPE=1                           # 0=None 1=AlertOnError 2=AlertOnOK 3=Always
    #export SADM_ALERT_GROUP="default"                  # Alert Group to advise (alert_group.cfg)
    #export SADM_MAIL_ADDR="your_email@domain.com"      # Email to send log (Override sadmin.cfg)
    #export SADM_MAX_LOGLINE=500                        # At the end Trim log to 500 Lines(0=NoTrim)
    #export SADM_MAX_RCLINE=35                          # At the end Trim rch to 35 Lines (0=NoTrim)
    #export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} " # SSH Command to Access Server 
#===================================================================================================


  

#===================================================================================================
# Global Scripts Variables 
#===================================================================================================
#
export FIELD_IN_RCH=10                                                  # Nb of field in a RCH File
export TOTAL_ERROR=0                                                    # Total Error in script
export URL_VIEW_FILE='/view/log/sadm_view_file.php'                     # View log File Content URL

# If the size of Today & Yesterday Backup/ReaR this percentage, it will highlight in yellow
export WPCT=50                                                          # Size PCT Diff.Threshold


# Set command line switch default
export BACKUP_REPORT="ON"                                               # Backup Report Activated
export REAR_REPORT="ON"                                                 # ReaR Report Activated
export SCRIPT_REPORT="ON"                                               # Scripts Report Activated
export STORIX_REPORT="OFF"                                              # Storix Report De-Activated

# Output HTML page for each type of report.
export HTML_BFILE="${SADM_TMP_DIR}/backup_report.html"                  # Backup Report HTML File 
export HTML_RFILE="${SADM_TMP_DIR}/rear_report.html"                    # ReaR Backup Rep. HTML File 
export HTML_XFILE="${SADM_TMP_DIR}/storix_report.html"                  # Storix Rep. HTML File 
export HTML_SFILE="${SADM_TMP_DIR}/scripts_report.html"                 # Scripts Rep. HTML File 

# Define NFS local mount point depending of O/S
if [ "$SADM_OS_TYPE" = "DARWIN" ]                                       # If on MacOS
    then export LOCAL_MOUNT="/preserve/daily_report"                    # NFS Mount Point for OSX
    else export LOCAL_MOUNT="/mnt/daily_report"                         # NFS Mount Point for Linux
fi  

# Variable used for the Rear Report.
export rear_script_name="sadm_rear_backup"                              # Name of ReaR Backup Script
export REAR_INTERVAL=7                                                  # Day between ReaR Backup
URL_REAR_SCHED='/crud/srv/sadm_server_rear_backup.php?sel=SYSTEM&back=/view/sys/sadm_view_rear.php' 

# Variables fused for the Storix Daily Report
ISODIR="iso"                                                            # NFS SubDir for Storix ISO 
IMGDIR="image"                                                          # NFS SubDir for Storix Img
STWARN=14                                                               # Backup Older = Yellow 

# Backup Report Variables.
# Different format of Today and Yesterday Date used to produce Backup Report
backup_script_name="sadm_backup"                                        # Name of DailyBackup Script
URL_UPD_SCHED='/crud/srv/sadm_server_backup.php?sel=SYSTEM&back/view/sys/sadm_view_backup.php'
export TODAY=`date "+%Y.%m.%d"`                                         # Today Date YYYY.MM.DD
export YESTERDAY=$(date --date="yesterday" +"%Y.%m.%d")                 # Yesterday Date YYYY.MM.DD
export TOUCH_TODAY=`date "+%Y/%m/%d"`                                   # Today Date YYYY/MM/DD
export TOUCH_YESTERDAY=$(date --date="yesterday" +"%Y/%m/%d")           # Yesterday Date YYYY/MM/DD
export UND_YESTERDAY=$(date --date="yesterday" +"%Y_%m_%d")             # Yesterday Date YYYY_MM_DD





# --------------------------------------------------------------------------------------------------
# Show Script command line option
# --------------------------------------------------------------------------------------------------
show_usage()
{
    printf "\n$Syntax: {SADM_PN} [-d|-h|-v|-b|-r|-s]"
    printf "\n\t-d   (Debug Level [0-9])"
    printf "\n\t-h   (Display this help message)"
    printf "\n\t-v   (Show Script Version Info)"
    printf "\n\t-b   (Don't produce and email the Backup report)"
    printf "\n\t-r   (Don't produce and email the ReaR report)"
    printf "\n\t-d   (Don't produce and email the Scripts report)"
    printf "\n\t-s   (Produce and email the Storix report (If installed))"
    printf "\n\n" 
}





# ==================================================================================================
# Mount the NFS $1 on ${LOCAL_MOUNT}
# ==================================================================================================
mount_nfs()
{
    REM_MOUNT="$1"                                                      # Remote NFS Mount Point
    if [ ! -d ${LOCAL_MOUNT} ]                                          # Mount Point doesn't exist
        then mkdir -p ${LOCAL_MOUNT}                                    # Create if not exist
             if [ $? -ne 0 ]                                            # If Error trying to mount
                then sadm_writelog "${SADM_ERROR} Creating local mount point."
                     return 1                                           # End Function with error
                else sadm_writelog "${SADM_OK} Local mount point created."
             fi
             chmod 775 ${LOCAL_MOUNT}                                   # Change Permission 
    fi

    # Make sure it's not already mounted or in use (Umount it)
    cd $SADM_TMP_DIR                                                    # Make sure ! in LOCAL_MOUNT                                           
    umount ${LOCAL_MOUNT} > /dev/null 2>&1                              # Make sure not mounted

    # Mount the NFS mount point.
    if [ "$SADM_OS_TYPE" = "DARWIN" ]                                   # If on MacOS
        then mount -t nfs -o resvport,rw ${REM_MOUNT} ${LOCAL_MOUNT} >>$SADM_LOG 2>&1
             RC=$?                                                      # Save Return Code
        else mount ${REM_MOUNT} ${LOCAL_MOUNT} >>$SADM_LOG 2>&1         # Mount NFS Drive
             RC=$?                                                      # Save Return Code
    fi
    if [ $RC -ne 0 ]                                                    # If Error trying to mount
        then sadm_writelog "${SADM_ERROR} Mount ${REM_MOUNT} ${LOCAL_MOUNT}" # Error - Advise User
             return 1                                                   # End Function with error
        else sadm_writelog "${SADM_OK} Mount ${REM_MOUNT} ${LOCAL_MOUNT}" # NFS Mount Succeeded Msg
    fi
    return 0
}




# ==================================================================================================
# Unmount NFS Directory and delete the local mount point
# ==================================================================================================
unmount_nfs()
{
    cd $SADM_TMP_DIR                                                    # Make sure not in UmountDir
    umount $LOCAL_MOUNT >> $SADM_LOG 2>&1                               # Umount Just to make sure
    if [ $? -ne 0 ]                                                     # If Error trying to mount
        then sadm_writelog "${SADM_ERROR} Unmount NFS mount directory ${LOCAL_MOUNT}"                               # Show user Error Unmounting
             return 1                                                   # End Function with error
        else sadm_writelog "${SADM_OK} Unmount directory ${LOCAL_MOUNT}" # Show Unmount Result
             rm -f $LOCAL_MOUNT >/dev/null 2>&1                         # Remove Local Mount Point
    fi
    return 0
}





# ==================================================================================================
# Mount the NFS Directory where all the ReaR backup files are stored 
# Produce a list of the latest backup for every systems.
# ==================================================================================================
script_report() 
{
    script_error=0                                                      # Greater than 0 if error 
    if [ -f "$HTML_SFILE" ] ;then rm -f $HTML_SFILE >/dev/null 2>&1 ;fi # Output HTML Report file. 

    sadm_writelog " "                                  
    sadm_writelog "${BOLD}${YELLOW}Creating the Daily Script Report${NORMAL}"  

    sadm_writelog "${SADM_OK} Create Script Web Page." 

    # Produce the report heading
    report_heading "Daily Script Report - `date +%a` `date +%d/%m/%Y`" "$HTML_SFILE"  



    echo -e "</table>\n</body>\n</html>" >> $HTML_SFILE                 # End of HTML Page


    # Set Report by Email to SADMIN Administrator
    subject="Daily Script Report"                                        # Send Backup Report by mail
    export EMAIL="$SADM_MAIL_ADDR"                                      # Set the FROM Email 
    mutt -e 'set content_type=text/html' -s "$subject" $SADM_MAIL_ADDR < $HTML_SFILE
    SADM_EXIT_CODE=$?                                                   # Save mutt return code
    if [ $SADM_EXIT_CODE -eq 0 ]                                        # If mail sent successfully
        then sadm_writelog "${SADM_OK} Script report sent to $SADM_MAIL_ADDR"      
        else sadm_writelog "${SADM_ERROR} Sending script report email to $SADM_MAIL_ADDR"
    fi

    sadm_write "${BOLD}${YELLOW}End of the Script Report ...${NORMAL}\n" 
    sadm_write "\n"
    return 0
}





# ==================================================================================================
# Mount the NFS Directory where all the ReaR backup files are stored 
# Produce a list of the latest backup for every systems.
# ==================================================================================================
rear_report() 
{
    rear_backup_error=0                                                 # Set to 1 if error in func.
    if [ -f "$SADM_TMP_FILE2" ] ; then rm -f $SADM_TMP_FILE2 >/dev/null 2>&1 ; fi 
    if [ -f "$HTML_RFILE" ] ; then rm -f $HTML_RFILE >/dev/null 2>&1 ; fi 

    sadm_write "\n"                                  
    sadm_write "${BOLD}${YELLOW}Creating the ReaR Backup Report${NORMAL}\n"  

    # Put Rows you want in the select. 
    # See rows available in 'table_structure_server.pdf' in $SADMIN/doc/database_info directory
    SQL="SELECT srv_name,srv_desc,srv_ostype,srv_domain,srv_monitor,srv_sporadic,srv_active" 
    SQL="${SQL},srv_sadmin_dir,srv_backup,srv_img_backup,srv_arch "

    # Build SQL to select active server(s) from Database.
    SQL="${SQL} from server"                                            # From the Server Table
    SQL="${SQL} where srv_ostype = 'linux'"                             # ReaR Avail. Only on Linux
    SQL="${SQL} order by srv_name; "                                    # Order Output by ServerName
    
    # Execute SQL Query to Create CSV in SADM Temporary work file ($SADM_TMP_FILE1)
    CMDLINE="$SADM_MYSQL -u $SADM_RO_DBUSER  -p$SADM_RO_DBPWD "         # MySQL Auth/Read Only User
    #if [ $SADM_DEBUG -gt 5 ] ; then sadm_write "${CMDLINE}\n" ; fi      # Debug Show Auth cmdline
    $CMDLINE -h $SADM_DBHOST $SADM_DBNAME -Ne "$SQL" | tr '/\t/' '/;/' >$SADM_TMP_FILE1
    if [ ! -s "$SADM_TMP_FILE1" ] || [ ! -r "$SADM_TMP_FILE1" ]         # File not readable or 0 len
        then sadm_write "$SADM_WARNING No Active Server were found.\n"  # Not Active Server MSG
             return 0                                                   # Return Status to Caller
    fi 

    # Mount NFS Rear Backup Directory
    NFSMOUNT="${SADM_REAR_NFS_SERVER}:${SADM_REAR_NFS_MOUNT_POINT}"     # Remote NFS Mount Point
    mount_nfs "$NFSMOUNT"                                               # Go and Mount NFS Dir.
    if [ $? -ne 0 ] ; then return 1 ; fi                                # Can't Mount back to caller
    
    # Produce the report heading
    report_heading "ReaR Backup Report - `date +%a` `date +%d/%m/%Y`" "$HTML_RFILE"  

    xcount=0                                                            # Set Server & Error Counter
    while read wline                                                    # Read Tmp file Line by Line
        do
        server_name=$(echo $wline      |awk -F\; '{print $1}')          # Extract Server Name
        server_desc=$(echo $wline      |awk -F\; '{print $2}')          # Extract Server Description
        server_os=$(echo $wline        |awk -F\; '{print $3}')          # O/S (linux/aix/darwin)
        server_domain=$(echo $wline    |awk -F\; '{print $4}')          # Extract Domain of Server
        server_monitor=$(echo $wline   |awk -F\; '{print $5}')          # Monitor  1=True 0=False
        server_sporadic=$(echo $wline  |awk -F\; '{print $6}')          # Sporadic 1=True 0=False
        server_active=$(echo $wline    |awk -F\; '{print $7}')          # Active   1=Yes  0=No
        server_rootdir=$(echo $wline   |awk -F\; '{print $8}')          # Client SADMIN Root Dir.
        server_backup=$(echo $wline    |awk -F\; '{print $9}')          # Backup Schd 1=True 0=False
        server_img_backup=$(echo $wline|awk -F\; '{print $10}')         # ReaR Sched. 1=True 0=False
        server_arch=$(      echo $wline|awk -F\; '{print $11}')         # Server Architecture
        fqdn_server=`echo ${server_name}.${server_domain}`              # Create FQDN Server Name

        # ReaR Backup only Supported under these Architecture
        if [ "$server_arch" != "x86_64" ] && [ "$server_arch" != "i686" ] && 
           [ "$server_arch" != "i386" ]
           then continue
        fi 
        #
        if [ "$SADM_DEBUG" -gt 4 ]                                      # If Debug Show System name
           then sadm_write "\n"                                         # Space line
                sadm_write "${SADM_TEN_DASH}\n"                         # Ten Dashes Line    
                sadm_write "Processing ${server_name}.\n"               # Server Name
        fi 
        #

        # Calculate Today ($CUR_TOTAL) and Yesterday ($PRV_TOTAL) Backup Size in MB
        CUR_TOTAL=0                                                     # Reset Today Backup Size 
        PRV_TOTAL=0                                                     # Reset Previous Backup Size
        if [ -d ${LOCAL_MOUNT}/${server_name} ]                         # If Server Backup Dir Exist
           then cd ${LOCAL_MOUNT}/${server_name}                        # CD into Backup Dir.
                rear_file="${LOCAL_MOUNT}/${server_name}/rear_${server_name}.tar.gz" 
                if [ -s $rear_file ] 
                   then TSIZE=$(stat --format=%s $rear_file)
                        CUR_TOTAL=$(echo "$TSIZE /1024/1024" | bc)      # Convert Backup Size in MB
                   else CUR_TOTAL=0
                fi 
                rear_file2=$(ls -1tr *.tar.gz | tail -2 | head -1)
                if [ -s $rear_file2 ] 
                   then TSIZE=$(stat --format=%s $rear_file2)
                        PRV_TOTAL=$(echo "$TSIZE /1024/1024" | bc)      # Convert Backup Size in MB
                   else PRV_TOTAL=0
                fi 
        fi

        # Get the last line of the backup RCH file for the system.
        RCH_FILE="${SADM_WWW_DAT_DIR}/${server_name}/rch/${server_name}_${rear_script_name}.rch"
        if [ -s $RCH_FILE ]                                             # If System Backup RCH Exist
            then RCH_LINE=$(tail -1 $RCH_FILE)                          # Get last line in RCH File
            else #echo "RCH file ${RCH_FILE} not found or is empty."     # Advise user no RCH File
                 start_end="---------- -------- ---------- -------- --------" # Start/End Date/Time
                 RCH_LINE="${server_name} ${start_end} ${rear_script_name} default 1 3" 
        fi 

        # The RCH line should have 10 ($FIELD_IN_RCH) fields, if not set error to 1 & advise user.
        NBFIELD=`echo $RCH_LINE | awk '{ print NF }'`                   # How many fields on line ?
        if [ "${NBFIELD}" != "${FIELD_IN_RCH}" ]                        # If abnormal nb. of field
           then sadm_write "Format error in this RCH file : ${RCH_FILE}\n"
                sadm_write "Line below have ${NBFIELD} but it should have ${FIELD_IN_RCH}.\n"
                sadm_write "The backup for this server is skipped: ${RCH_LINE}\n"
                sadm_write "\n"
                rear_backup_error=1                                          # Func. Return Code now at 1
                continue 
        fi        
        if [ $SADM_DEBUG -gt 5 ] 
            then printf "The RCH Filename of ${server_name} backup of is ${RCH_FILE}\n"
                 printf "The last Line in the file is : ${RCH_LINE}\n"
        fi 

        # Split the RCH Line 
        WSERVER=`echo -e $RCH_LINE | awk '{ print $1 }'`                # Extract Server Name
        WDATE1=` echo -e $RCH_LINE | awk '{ print $2 }'`                # Extract Date Started
        WTIME1=` echo -e $RCH_LINE | awk '{ print $3 }'`                # Extract Time Started
        WDATE2=` echo -e $RCH_LINE | awk '{ print $4 }'`                # Extract Date Started
        WTIME2=` echo -e $RCH_LINE | awk '{ print $5 }'`                # Extract Time Ended
        WELAPSE=`echo -e $RCH_LINE | awk '{ print $6 }'`                # Extract Time Ended
        WSCRIPT=`echo -e $RCH_LINE | awk '{ print $7 }'`                # Extract Script Name
        WALERT=` echo -e $RCH_LINE | awk '{ print $8 }'`                # Extract Alert Group Name
        WTYPE=`  echo -e $RCH_LINE | awk '{ print $9 }'`                # Extract Alert Group Type
        WRCODE=` echo -e $RCH_LINE | awk '{ print $10 }'`               # Extract Return Code 

        # Set the backup Status Description
        case "$WRCODE" in                                               # Case on RCH Return Code
            0 ) WSTATUS="Success" 
                ;; 
            1 ) WSTATUS="Failed"
                ;;
            2 ) WSTATUS="Running"
                ;;
            3 ) WSTATUS="No Backup"
                ;;
            * ) WRDESC="CODE $WRCODE ?"                                 # Illegal Code  Desc
                ;;                                                          
        esac
        
        # Build backup line to be written to work file (Will be sorted later)
        BLINE="${WDATE1},${WTIME1},${WELAPSE},${WSTATUS},${server_name}" 
        BLINE="${BLINE},${server_desc},${server_img_backup}"
        BLINE="${BLINE},${CUR_TOTAL},${PRV_TOTAL},${server_sporadic}" 
        echo "$BLINE" >> $SADM_TMP_FILE2                                # Write Info to work file
        done < $SADM_TMP_FILE1

    # Umount NFS Mount point, Sort the Work File (By Date/Time) then produce report it HTML format.
    unmount_nfs                                                         # UnMount NFS Backup Dir.
    sort $SADM_TMP_FILE2 > $SADM_TMP_FILE1                              # Sort Tmp file by Date/Time
    while read wline                                                    # Read Tmp file Line by Line
        do
        xcount=$(($xcount+1))                                           # Increase Line Counter
        backup_line "${wline},${xcount},$HTML_RFILE,R"                  # Insert line in HTML Page
        done < $SADM_TMP_FILE1                                          # Read Sorted file

    echo -e "</table>\n</body>\n</html>" >> $HTML_RFILE                 # End of HTML Page

    # Set Report by Email to SADMIN Administrator
    subject="ReaR Backup Report"                                        # Send Backup Report by mail
    export EMAIL="$SADM_MAIL_ADDR"                                      # Set the FROM Email 
    mutt -e 'set content_type=text/html' -s "$subject" $SADM_MAIL_ADDR < $HTML_RFILE
    SADM_EXIT_CODE=$?                                                   # Save mutt return code
    if [ $SADM_EXIT_CODE -eq 0 ]                                        # If mail sent successfully
        then sadm_writelog "${SADM_OK} ReaR Backup Report sent to $SADM_MAIL_ADDR"      
        else sadm_writelog "${SADM_ERROR} Failed to send the ReaR Backup Report to $SADM_MAIL_ADDR"
    fi

    sadm_write "${BOLD}${YELLOW}End of the ReaR Backup Report ...${NORMAL}\n" 
    sadm_write "\n"

    return $rear_backup_error                                          # Return Err Count to caller
}



#===================================================================================================
# Report Heading
#===================================================================================================
storix_heading()
{
    RTITLE=$1                                                           # Report Title

    echo -e "<!DOCTYPE html><html>" > $HTML_XFILE
    echo -e "<head>" >> $HTML_XFILE
    echo -e "\n<meta charset='utf-8' />" >> $HTML_XFILE
    #
    echo -e "\n<style>" >> $HTML_XFILE
    echo -e "th { color: white; background-color: #0000ff; padding: 5px; }" >> $HTML_XFILE
    echo -e "td { color: white; border-bottom: 1px solid #ddd; padding: 5px; }" >> $HTML_XFILE
    echo -e "tr:nth-child(odd)  { background-color: #F5F5F5; }" >> $HTML_XFILE
    echo -e "table, th, td { border: 1px solid black; border-collapse: collapse; }" >> $HTML_XFILE
    echo -e "</style>" >> $HTML_XFILE
    #
    echo -e "\n<title>$RTITLE</title>" >> $HTML_XFILE
    echo -e "</head>\n" >> $HTML_XFILE
    echo -e "<body>" >> $HTML_XFILE
    echo -e "<br>\n<center><h1>${RTITLE}</h1></center>" >> $HTML_XFILE
    echo -e "\n<center><table border=0>" >> $HTML_XFILE
    #
    echo -e "\n<thead>" >> $HTML_XFILE
    echo -e "<tr>" >> $HTML_XFILE
    echo -e "<th colspan=1 dt-head-center></th>" >> $HTML_XFILE
    echo -e "<th colspan=4 align=center>Last Backup Execution</th>" >> $HTML_XFILE
    echo -e "<th colspan=2></th>" >> $HTML_XFILE
    echo -e "<th align=center>System</th>" >> $HTML_XFILE
    echo -e "<th align=center>Backup</th>" >> $HTML_XFILE
    echo -e "<th align=center>Backup</th>" >> $HTML_XFILE
    echo -e "<th align=center>ISO</th>" >> $HTML_XFILE
    echo -e "<th align=center>ISO</th>" >> $HTML_XFILE
    echo -e "</tr>" >> $HTML_XFILE
    #
    echo -e "<tr>" >> $HTML_XFILE
    echo -e "<th align=center>No</th>" >> $HTML_XFILE
    echo -e "<th align=center>Date</th>" >> $HTML_XFILE
    echo -e "<th align=center>Time</th>" >> $HTML_XFILE
    echo -e "<th align=center>Elapse</th>" >> $HTML_XFILE
    echo -e "<th align=center>Status</th>"  >> $HTML_XFILE
    echo -e "<th align=center>System</th>" >> $HTML_XFILE
    echo -e "<th align=left>Description</th>" >> $HTML_XFILE    
    echo -e "<th align=left>Sporadic</th>" >> $HTML_XFILE
    echo -e "<th align=center>Date</th>" >> $HTML_XFILE
    echo -e "<th align=center>Size</th>" >> $HTML_XFILE
    echo -e "<th align=center>Date</th>" >> $HTML_XFILE
    echo -e "<th align=center>Size</th>" >> $HTML_XFILE
    echo -e "</tr>" >> $HTML_XFILE
    echo -e "</thead>\n" >> $HTML_XFILE
    return 0
}


#===================================================================================================
# Add the receiving line into the Backup report page
#===================================================================================================
storix_line()
{
    # Extract fields from parameters received.
    BACKUP_INFO=$*                                                      # Comma Sep. Info Line
    WDATE1=$(      echo $BACKUP_INFO | awk -F\; '{ print $1 }')         # Most Recent Backup Date
    WTIME1=$(      echo $BACKUP_INFO | awk -F\; '{ print $2 }')         # Most Recent Backup Time
    WELAPSE=$(     echo $BACKUP_INFO | awk -F\; '{ print $3 }')         # Recent Backup Elapse Time
    WSTATUS=$(     echo $BACKUP_INFO | awk -F\; '{ print $4 }')         # Storix Backup Status
    WSERVER=$(     echo $BACKUP_INFO | awk -F\; '{ print $5 }')         # Server System Name
    WDESC=$(       echo $BACKUP_INFO | awk -F\; '{ print $6 }')         # Server System Description
    WACT=$(        echo $BACKUP_INFO | awk -F\; '{ print $7 }')         # DB System Description
    BACKUP_SIZE=$( echo $BACKUP_INFO | awk -F\; '{ print $8 }')         # Current Backup Total MB
    ISO_SIZE=$(    echo $BACKUP_INFO | awk -F\; '{ print $9 }')         # ISO Size MB
    WSPORADIC=$(   echo $BACKUP_INFO | awk -F\; '{ print $10 }')        # Sporadic Server=1 else=0
    ISO_DATE=$(    echo $BACKUP_INFO | awk -F\; '{ print $11 }')        # Date ISO was created
    ST_DATE=$(     echo $BACKUP_INFO | awk -F\; '{ print $12 }')        # Date of Storix TOC File
    WCOUNT=$(      echo $BACKUP_INFO | awk -F\; '{ print $13 }')        # Line Counter
    #sadm_writelog "ISO_SIZE=$ISO_SIZE for ${WSERVER}"

    # Alternate background color at every line
    if (( $WCOUNT %2 == 0 ))                                            # Modulo on line counter
       then BCOL="#00FFFF" ; FCOL="#000000"                             # Pair count color
       else BCOL="#F0FFFF" ; FCOL="#000000"                             # Impair line color
    fi

    # Beginning to Insert Line in HTML_XFILE Table
    echo -e "<tr>"  >> $HTML_XFILE                                      # Begin backup line
    echo -e "<td align=center bgcolor=$BCOL><font color=$FCOL>$WCOUNT</font></td>"  >> $HTML_XFILE

    # Backup older than $STWARN = yellow background & tooltips indicate nb days elapse since backup
    ebackup_date=`echo "$WDATE1" | sed 's/\./\//g'`                     # Replace dot by '/' in date
    backup_date=`echo "$WDATE1" | sed 's/\./-/g'`                       # Replace dot by '-' in date
    epoch_backup=`date -d "$ebackup_date" "+%s"`                        # Backup Date in Epoch Time
    epoch_now=`date "+%s"`                                              # Today in Epoch Time
    diff=$(($epoch_now - $epoch_backup))                                # Nb. Seconds between
    days=$(($diff/(60*60*24)))                                          # Convert Sec. to Days
    if [ $days -gt $STWARN ]                                            # Backup taken too far away
       then echo -n "<td title='Last Backup done $days days ago' " >>$HTML_XFILE 
            echo -n "align=center bgcolor='Yellow'>" >>$HTML_XFILE      # Yellow Background
            echo "<font color=$FCOL>$backup_date</font></td>" >>$HTML_XFILE
       else if [ "$backup_date" != "$ST_DATE" ] ||  [ "$backup_date" != "$ISO_DATE" ] 
               then echo -n "<td title='Backup Date different than ISO or Image date' " >>$HTML_XFILE 
                    echo -n "align=center bgcolor='Yellow'>" >>$HTML_XFILE      # Yellow Background
                    echo "<font color=$FCOL>$backup_date</font></td>" >>$HTML_XFILE  # Show Backup Date
               else echo "<td align=center bgcolor=$BCOL><font color=$FCOL>$backup_date</font></td>" >>$HTML_XFILE
            fi
    fi 

    # Backup Time & Elapse time
    echo "<td align=center bgcolor=$BCOL><font color=$FCOL>$WTIME1</font></td>"  >> $HTML_XFILE
    echo "<td align=center bgcolor=$BCOL><font color=$FCOL>$WELAPSE</font></td>" >> $HTML_XFILE

    # Backup Status
    echo -e "<td align=center bgcolor=$BCOL><font color=$FCOL>" >> $HTML_XFILE
    LOGFILE="${WSERVER}_${WSCRIPT}.log"                                 # Assemble log Script Name
    LOGNAME="${SADM_WWW_DAT_DIR}/${WSERVER}/log/${LOGFILE}"             # Add Dir. Path to Name
    LOGURL="http://sadmin.${SADM_DOMAIN}/${URL_VIEW_FILE}?filename=${LOGNAME}"  # Url to View Log
    if [ -r "$LOGNAME" ]                                                # If log is Readable
        then echo -n "<a href='$LOGURL 'title='View Backup Log File'>" >>$HTML_XFILE
             echo "${WSTATUS}</font></a></td>" >>$HTML_XFILE 
        else echo -e "${WSTATUS}</font></td>" >> $HTML_XFILE            # No Log = No LInk
    fi

    # Server Name & Descrition 
    echo "<td align=center bgcolor=$BCOL><font color=$FCOL>$WSERVER</font></td>" >> $HTML_XFILE
    echo "<td align=left bgcolor=$BCOL><font color=$FCOL>$WDESC</font></td>"     >> $HTML_XFILE

    # Show if Server is Sporadic or not.
    if [ "$WSPORADIC" =  "0" ] 
       then echo "<td align=center bgcolor=$BCOL><font color=$FCOL>No</font></td>"  >>$HTML_XFILE
       else echo "<td align=center bgcolor=$BCOL><font color=$FCOL>Yes</font></td>" >>$HTML_XFILE
    fi

    # Show Date and Size of Storix Backup
    if [ "$backup_date" != "$ST_DATE" ] 
        then echo -n "<td title='Execution Backup Date different than Image file date' " >>$HTML_XFILE 
             echo " align=center bgcolor='Yellow'><font color=$FCOL>$ST_DATE</font></td>" >>$HTML_XFILE
        else echo "<td align=center bgcolor=$BCOL><font color=$FCOL>$ST_DATE</font></td>" >>$HTML_XFILE
    fi 
    if [ $BACKUP_SIZE -eq 0 ] 
        then echo "<td align=center bgcolor='Yellow'><font color=$FCOL>$BACKUP_SIZE MB</font></td>" >>$HTML_XFILE
        else echo "<td align=center bgcolor=$BCOL><font color=$FCOL>$BACKUP_SIZE MB</font></td>" >>$HTML_XFILE
    fi 

    # Show Storix Date & ISO Size
    if [ "$backup_date" != "$ISO_DATE" ] 
        then echo -n "<td title='Execution Backup Date different than ISO file date' " >>$HTML_XFILE
             echo " align=center bgcolor='Yellow'><font color=$FCOL>$ISO_DATE</font></td>" >>$HTML_XFILE
        else echo "<td align=center bgcolor=$BCOL><font color=$FCOL>$ISO_DATE</font></td>" >>$HTML_XFILE
    fi 
    if [ $ISO_SIZE -eq 0 ]                                
        then echo -en "<td title='No ISO was found' align=center bgcolor='Yellow'>" >>$HTML_XFILE
             echo -e "<font color=$FCOL>${ISO_SIZE} MB</font></td>" >> $HTML_XFILE
        else echo -en "<td align=center bgcolor=$BCOL><font color=$FCOL> " >> $HTML_XFILE
             echo -e " ${ISO_SIZE} MB</font></td>" >> $HTML_XFILE
    fi 

    echo -e "</tr>\n" >> $HTML_XFILE
    return 
} 



#===================================================================================================
# Produce the Storix Image Backup report and email it to the SADMIN Administrator.
#===================================================================================================
storix_report()
{
    storix_error=0                                                      # Set to 1 if error in func.
    if [ -f "$SADM_TMP_FILE2" ] ; then rm -f $SADM_TMP_FILE2 >/dev/null 2>&1 ; fi 
    if [ -f "$HTML_XFILE" ] ; then rm -f $HTML_XFILE >/dev/null 2>&1 ; fi     

    sadm_write "\n"
    sadm_write "${BOLD}${YELLOW}Creating the Storix Daily Backup Report${NORMAL}\n" 

    # Put Rows you want in the select. 
    # See rows available in 'table_structure_server.pdf' in $SADMIN/doc/database_info directory
    SQL="SELECT srv_name,srv_desc,srv_ostype,srv_domain,srv_monitor,srv_sporadic,srv_active" 
    SQL="${SQL},srv_sadmin_dir,srv_backup,srv_img_backup,srv_arch "

    # Build SQL to select active server(s) from Database.
    SQL="${SQL} from server"                                            # From the Server Table
    SQL="${SQL} where srv_ostype = 'linux'"                             # ReaR Avail. Only on Linux
    SQL="${SQL} order by srv_name; "                                    # Order Output by ServerName
    
    # Execute SQL Query to Create CSV in SADM Temporary work file ($SADM_TMP_FILE1)
    CMDLINE="$SADM_MYSQL -u $SADM_RO_DBUSER  -p$SADM_RO_DBPWD "         # MySQL Auth/Read Only User
    $CMDLINE -h $SADM_DBHOST $SADM_DBNAME -Ne "$SQL" | tr '/\t/' '/;/' >$SADM_TMP_FILE1
    if [ ! -s "$SADM_TMP_FILE1" ] || [ ! -r "$SADM_TMP_FILE1" ]         # File not readable or 0 len
        then sadm_write "$SADM_WARNING No Active Server were found.\n"  # Not Active Server MSG
             return 0                                                   # Return Status to Caller
    fi 
    if [ "$SADM_DEBUG" -gt 4 ]                                          # If Debug Show SQL Results
       then sadm_writelog " "                                             # Space line
            sadm_writelog "Output of the SQL Query for producing the Backup Report."
            cat $SADM_TMP_FILE1 | while read wline ; do sadm_writelog "${wline}"; done
            sadm_writelog " "                                             # Space line
    fi

    NFSMOUNT="${SADM_STORIX_NFS_SERVER}:${SADM_STORIX_NFS_MOUNT_POINT}" # Remote NFS Mount Point
    mount_nfs "$NFSMOUNT"                                               # Go and Mount NFS Dir.
    if [ $? -ne 0 ] ; then return 1 ; fi                                # Can't Mount back to caller

    # Produce the report Heading
    storix_heading "Daily Storix Backup Report - `date +%a` `date +%d/%m/%Y`" 
    xcount=0                                                            # Set Server & Error Counter
    while read wline                                                    # Read Tmp file Line by Line
        do
        server_name=$(echo $wline      |awk -F\; '{print $1}')           # Extract Server Name
        server_desc=$(echo $wline      |awk -F\; '{print $2}')           # Extract Server Description
        server_os=$(echo $wline        |awk -F\; '{print $3}')           # O/S (linux/aix/darwin)
        server_domain=$(echo $wline    |awk -F\; '{print $4}')           # Extract Domain of Server
        server_monitor=$(echo $wline   |awk -F\; '{print $5}')           # Monitor  1=True 0=False
        server_sporadic=$(echo $wline  |awk -F\; '{print $6}')           # Sporadic 1=True 0=False
        server_active=$(echo $wline    |awk -F\; '{print $7}')           # Active   1=Yes  0=No
        server_rootdir=$(echo $wline   |awk -F\; '{print $8}')           # Client SADMIN Root Dir.
        server_backup=$(echo $wline    |awk -F\; '{print $9}')           # Backup Schd 1=True 0=False
        server_img_backup=$(echo $wline|awk -F\; '{print $10}')          # ReaR Sched. 1=True 0=False
        server_arch=$(      echo $wline|awk -F\; '{print $11}')          # Server Architecture        
        fqdn_server=`echo ${server_name}.${server_domain}`              # Create FQDN Server Name
        
        if [ "$SADM_DEBUG" -gt 4 ]                                      # If Debug Show System name
           then sadm_writelog " "                                       # Space line
                sadm_writelog "${SADM_TEN_DASH}"                        # Ten Dashes Line    
                sadm_writelog "Handling ${server_name} ${server_arch}"  # Server Name & Architecture
        fi 
 
        # ReaR Backup only Supported under these Architecture
        if [ "$server_arch" != "x86_64" ] && [ "$server_arch" != "i686" ] && 
           [ "$server_arch" != "i386" ]
           then #sadm_writelog "${SADM_WARNING} ${server_name} architecture ($server_arch) not supported by Storix."
                continue                                                # Storix run Intel Platform
        fi 

        # Get Information about Storix ISO 
        ISO_NAME="No ISO" ; ISO_SIZE=0 ; ISO_DATE="N/A" ; ISO_EPOCH=0   # Default if no ISO found
        if [ -d ${LOCAL_MOUNT}/${ISODIR} ]                              # If Server Backup Dir Exist
           then ls -l ${LOCAL_MOUNT}/${ISODIR}/*.iso | grep -i ${server_name} > /dev/null 2>&1
                if [ $? -eq 0 ]                                         # ISO exist for server ?
                   then ISO_NAME=$(ls -1 ${LOCAL_MOUNT}/${ISODIR}/*.iso | grep -i ${server_name} |head -1)
                        ISO_SIZE=$(stat  --format=%s ${ISO_NAME})
                        ISO_SIZE=$(echo "$ISO_SIZE /1024/1024" | bc)    # Convert Backup Size in MB
                        ISO_DATE=$(stat  --format=%y ${ISO_NAME} | awk '{print $1}')
                        ISO_EPOCH=$(stat --format=%Y ${ISO_NAME} | awk '{print $1}')
                   else sadm_writelog "${SADM_WARNING} - No ISO was found for system ${server_name}"
                fi 
           else sadm_writelog "${SADM_ERROR} - ISO Directory doesn't exist (${LOCAL_MOUNT}/${ISODIR})"
        fi
        #sadm_writelog "1- ISO_SIZE=$ISO_SIZE for ${server_name}"

        # Check if at least one TOC file exist for the current server
        STTOT=0                                                         # Defaut Storix Backup Size
        SAVPWD=`pwd`                                                    # Save Current Working Dir.
        cd ${LOCAL_MOUNT}/${IMGDIR}                                     # Move into Image Directory
        ls -1tr SB*${server_name}*:TOC:* > /dev/null 2>&1               # At Least 1 TOC For System?
        if [ $? -ne 0 ]                                                 # Bo TOC = No Backup
           then sadm_writelog "${SADM_WARNING} - No Storix image found for system ${server_name}"
           else STTOC=$(ls -1tr SB*${server_name}*:TOC:* | tail -1)     # Get lastest TOC FileName
                ST_DATE=$(stat  --format=%y ${STTOC} |awk '{print $1}') # Get TOC Modifcation Date
                STSEQ=$(echo $STTOC | awk -F: '{print $5}')             # Get Backup ID Number
                wback_size="${SADM_TMP_DIR}/daily_storix.size"          # WorkFile, Calc Backup Size
                rm -f $wback_size > /dev/null 2>&1                      # Del. Size Work File
                find ${LOCAL_MOUNT}/${IMGDIR} -name "SB*" -exec ls -l {} \; | grep "${STSEQ}" > $wback_size
                if [ -s $wback_size ]                                   # Backup File Not Found or 0
                   then TOTAL=$(awk '{sum += $5} END {print sum}' $wback_size)  # Add each file size 
                        STTOT=$(echo "$TOTAL /1024/1024" | bc)          # Convert Backup Size in MB
                fi 
        fi 
        cd ${SAVPWD}                                                    # Move out of NFS Directory
        #echo "STTOT=$STTOT"



        # Get the last line of the backup RCH file for the system.
        RCH_FILE="${SADM_WWW_DAT_DIR}/${server_name}/rch/${server_name}_storix_client_post_job.rch"
        if [ -s $RCH_FILE ]                                             # If System Backup RCH Exist
            then RCH_LINE=$(tail -1 $RCH_FILE)                          # Get last line in RCH File
            else #echo "RCH file ${RCH_FILE} not found or is empty."     # Advise user no RCH File
                 start_end="---------- -------- ---------- -------- --------" # Start/End Date/Time
                 RCH_LINE="${server_name} ${start_end} ${backup_script_name} default 1 3" 
        fi 

        # The RCH line should have 10 ($FIELD_IN_RCH) fields, if not set error to 1 & advise user.
        NBFIELD=`echo $RCH_LINE | awk '{ print NF }'`                   # How many fields on line ?
        if [ "${NBFIELD}" != "${FIELD_IN_RCH}" ]                        # If abnormal nb. of field
           then sadm_write "${SADM_ERROR} Format error in this RCH file : ${RCH_FILE}\n"
                sadm_write "Line below have ${NBFIELD} but it should have ${FIELD_IN_RCH}.\n"
                sadm_write "The backup for this server is skipped: ${RCH_LINE}\n"
                sadm_write "\n"
                storix_error=1                                          # Func. Return Code now at 1
                continue 
        fi        
        if [ $SADM_DEBUG -gt 5 ] 
            then printf "The RCH Filename of ${server_name} backup of is ${RCH_FILE}\n"
                 printf "The last Line in the file is : ${RCH_LINE}\n"
        fi 

        # Split the RCH Line 
        WSERVER=` echo -e $RCH_LINE | awk '{ print $1 }'`               # Extract Server Name
        WDATE1=`  echo -e $RCH_LINE | awk '{ print $2 }'`               # Extract Date Started
        WTIME1=`  echo -e $RCH_LINE | awk '{ print $3 }'`               # Extract Time Started
        WDATE2=`  echo -e $RCH_LINE | awk '{ print $4 }'`               # Extract Date Started
        WTIME2=`  echo -e $RCH_LINE | awk '{ print $5 }'`               # Extract Time Ended
        WELAPSE=` echo -e $RCH_LINE | awk '{ print $6 }'`               # Extract Time Ended
        WSCRIPT=` echo -e $RCH_LINE | awk '{ print $7 }'`               # Extract Script Name
        WALERT=`  echo -e $RCH_LINE | awk '{ print $8 }'`               # Extract Alert Group Name
        WTYPE=`   echo -e $RCH_LINE | awk '{ print $9 }'`               # Extract Alert Group Type
        WRCODE=`  echo -e $RCH_LINE | awk '{ print $10 }'`              # Extract Return Code 

        # Set the backup Status Description
        case "$WRCODE" in                                               # Case on RCH Return Code
            0 ) WSTATUS="Success" 
                ;; 
            1 ) WSTATUS="Failed"
                ;;
            2 ) WSTATUS="Running"
                ;;
            3 ) WSTATUS="No Backup"
                ;;
            * ) WRDESC="CODE $WRCODE ?"                                 # Illegal Code  Desc
                ;;                                                          
        esac
        
        # Build backup line to be written to work file (Will then be sorted later)
        BLINE="${WDATE1};${WTIME1};${WELAPSE};${WSTATUS};${server_name}" 
        BLINE="${BLINE};${server_desc};${server_backup};${STTOT};${ISO_SIZE}"
        BLINE="${BLINE};${server_sporadic};${ISO_DATE};${ST_DATE}"
        echo "${BLINE}" >> $SADM_TMP_FILE2                                # Write Info to work file
        done < $SADM_TMP_FILE1

    # Umount NFS Mount point, Sort the Work File (By Date/Time) then produce report it HTML format.
    unmount_nfs                                                         # UnMount NFS Backup Dir.
    sort $SADM_TMP_FILE2 > $SADM_TMP_FILE1                              # Sort Tmp file by Date/Time
    while read wline                                                    # Read Tmp file Line by Line
        do
        xcount=$(($xcount+1))                                           # Increase Line Counter
        storix_line "${wline};${xcount}"                                # Insert line in HTML Page
        done < $SADM_TMP_FILE1                                          # Read Sorted file

    echo -e "</table>\n</body>\n</html>" >> $HTML_XFILE                 # End of HTML Page

    # Set Report by Email to SADMIN Administrator
    subject="Storix Daily Backup Report"                                # Send Backup Report by mail
    export EMAIL="$SADM_MAIL_ADDR"                                      # Set the FROM Email 
    mutt -e 'set content_type=text/html' -s "$subject" $SADM_MAIL_ADDR < $HTML_XFILE
    SADM_EXIT_CODE=$?                                                   # Save mutt return code
    if [ $SADM_EXIT_CODE -eq 0 ]                                        # If mail sent successfully
        then sadm_writelog "${SADM_OK} Daily Backup Report sent to $SADM_MAIL_ADDR"      
        else sadm_writelog "${SADM_ERROR} Failed to send the Daily Backup Report to $SADM_MAIL_ADDR"
    fi

    # End of Storix Report
    sadm_write "${BOLD}${YELLOW}End of Daily Backup Report ...${NORMAL}\n"   
    sadm_write "\n"                                                     # White line in log & Screen
    return $SADM_EXIT_CODE                                              # Return Err Count to caller
}



#===================================================================================================
# Produce the backup report and email it to the SADMIN Administrator.
#===================================================================================================
backup_report()
{
    backup_error=0                                                      # Set to 1 if error in func.
    if [ -f "$SADM_TMP_FILE2" ] ; then rm -f $SADM_TMP_FILE2 >/dev/null 2>&1 ; fi 
    if [ -f "$HTML_BFILE" ] ; then rm -f $HTML_BFILE >/dev/null 2>&1 ; fi     

    sadm_write "\n"
    sadm_write "${BOLD}${YELLOW}Creating the Daily Backup Report${NORMAL}\n" 

    # Put Rows you want in the select. 
    # See rows available in 'table_structure_server.pdf' in $SADMIN/doc/database_info directory
    SQL="SELECT srv_name,srv_desc,srv_ostype,srv_domain,srv_monitor,srv_sporadic,srv_active" 
    SQL="${SQL},srv_sadmin_dir,srv_backup,srv_img_backup "

    # Build SQL to select active server(s) from Database.
    SQL="${SQL} from server"                                            # From the Server Table
    #SQL="${SQL} where srv_active = True"                                # Select only Active Servers
    SQL="${SQL} order by srv_name; "                                    # Order Output by ServerName
    
    # Execute SQL Query to Create CSV in SADM Temporary work file ($SADM_TMP_FILE1)
    CMDLINE="$SADM_MYSQL -u $SADM_RO_DBUSER  -p$SADM_RO_DBPWD "         # MySQL Auth/Read Only User
    #if [ $SADM_DEBUG -gt 5 ] ; then sadm_write "${CMDLINE}\n" ; fi      # Debug Show Auth cmdline
    $CMDLINE -h $SADM_DBHOST $SADM_DBNAME -Ne "$SQL" | tr '/\t/' '/;/' >$SADM_TMP_FILE1
    if [ ! -s "$SADM_TMP_FILE1" ] || [ ! -r "$SADM_TMP_FILE1" ]         # File not readable or 0 len
        then sadm_write "$SADM_WARNING No Active Server were found.\n"  # Not Active Server MSG
             return 0                                                   # Return Status to Caller
    fi 
    if [ "$SADM_DEBUG" -gt 7 ]                                          # If Debug Show SQL Results
       then sadm_writelog " "                                             # Space line
            sadm_writelog "Output of the SQL Query for producing the Backup Report."
            cat $SADM_TMP_FILE1 | while read wline ; do sadm_write "${wline}"; done
            sadm_writelog " "                                             # Space line
    fi

    NFSMOUNT="${SADM_BACKUP_NFS_SERVER}:${SADM_BACKUP_NFS_MOUNT_POINT}" # Remote NFS Mount Point
    mount_nfs "$NFSMOUNT"                                               # Go and Mount NFS Dir.
    if [ $? -ne 0 ] ; then return 1 ; fi                                # Can't Mount back to caller

    # Produce the report Heading
    sadm_writelog "${SADM_OK} Create Backup Web Page." 
    report_heading "Daily Backup Report - `date +%a` `date +%d/%m/%Y`" "$HTML_BFILE" 

    xcount=0                                                            # Set Server & Error Counter
    while read wline                                                    # Read Tmp file Line by Line
        do
        server_name=$(echo $wline      |awk -F\; '{print $1}')           # Extract Server Name
        server_desc=$(echo $wline      |awk -F\; '{print $2}')           # Extract Server Description
        server_os=$(echo $wline        |awk -F\; '{print $3}')           # O/S (linux/aix/darwin)
        server_domain=$(echo $wline    |awk -F\; '{print $4}')           # Extract Domain of Server
        server_monitor=$(echo $wline   |awk -F\; '{print $5}')           # Monitor  1=True 0=False
        server_sporadic=$(echo $wline  |awk -F\; '{print $6}')           # Sporadic 1=True 0=False
        server_active=$(echo $wline    |awk -F\; '{print $7}')           # Active   1=Yes  0=No
        server_rootdir=$(echo $wline   |awk -F\; '{print $8}')           # Client SADMIN Root Dir.
        server_backup=$(echo $wline    |awk -F\; '{print $9}')           # Backup Schd 1=True 0=False
        server_img_backup=$(echo $wline|awk -F\; '{print $10}')          # ReaR Sched. 1=True 0=False
        fqdn_server=`echo ${server_name}.${server_domain}`              # Create FQDN Server Name
        #
        if [ "$SADM_DEBUG" -gt 4 ]                                      # If Debug Show System name
           then sadm_writelog " "                                       # Space line
                sadm_writelog "${SADM_TEN_DASH}"                        # Ten Dashes Line    
                sadm_writelog "Processing ${server_name}."              # Server Name
        fi 
        #

        # Calculate Today ($CUR_TOTAL) and Yesterday ($PRV_TOTAL) Backup Size in MB
        CUR_TOTAL=0                                                     # Reset Today Backup Size 
        PRV_TOTAL=0                                                     # Reset Previous Backup Size
        if [ -d ${LOCAL_MOUNT}/${server_name} ]                         # If Server Backup Dir Exist
           then touch_file="${SADM_TMP_DIR}/daily_report.time"          # Backup Ref Touch File Time
                wback_size="${SADM_TMP_DIR}/daily_report.size"          # WorkFile, Calc Backup Size
                cd ${LOCAL_MOUNT}/${server_name}                        # CD into Backup Dir.
                touch -d "$TOUCH_TODAY" $touch_file                     # TouchFile=Today Date/Time 
                find . -type f -newer $touch_file -exec stat --format=%s {} \; > $wback_size
                if [ -s $wback_size ]                                   # Backup File Not Found or 0
                   then TOTAL=$(awk '{sum += $1} END {print sum}' $wback_size) # Add each file size 
                        CUR_TOTAL=$(echo "$TOTAL /1024/1024" | bc)      # Convert Backup Size in MB
                fi 
                touch -d "$TOUCH_YESTERDAY" $touch_file                 # TouchFile=Yesterday  
                rm -f $wback_size > /dev/null 2>&1                      # Del. Size Work File
                find . -type f -newer $touch_file -exec ls -l {} \; | grep "$UND_YESTERDAY" > $wback_size
                if [ -s $wback_size ]                                   # Backup File Not Found or 0
                   then TOTAL=$(awk '{sum += $5} END {print sum}' $wback_size) # Add each file size 
                        PRV_TOTAL=$(echo "$TOTAL /1024/1024" | bc)      # Convert Backup Size in MB
                fi 
        fi

        # Get the last line of the backup RCH file for the system.
        RCH_FILE="${SADM_WWW_DAT_DIR}/${server_name}/rch/${server_name}_${backup_script_name}.rch"
        if [ -s $RCH_FILE ]                                             # If System Backup RCH Exist
            then RCH_LINE=$(tail -1 $RCH_FILE)                          # Get last line in RCH File
            else #echo "RCH file ${RCH_FILE} not found or is empty."     # Advise user no RCH File
                 start_end="---------- -------- ---------- -------- --------" # Start/End Date/Time
                 RCH_LINE="${server_name} ${start_end} ${backup_script_name} default 1 3" 
        fi 

        # The RCH line should have 10 ($FIELD_IN_RCH) fields, if not set error to 1 & advise user.
        NBFIELD=`echo $RCH_LINE | awk '{ print NF }'`                   # How many fields on line ?
        if [ "${NBFIELD}" != "${FIELD_IN_RCH}" ]                        # If abnormal nb. of field
           then sadm_write "Format error in this RCH file : ${RCH_FILE}\n"
                sadm_write "Line below have ${NBFIELD} but it should have ${FIELD_IN_RCH}.\n"
                sadm_write "The backup for this server is skipped: ${RCH_LINE}\n"
                sadm_write "\n"
                backup_error=1                                          # Func. Return Code now at 1
                continue 
        fi        
        if [ $SADM_DEBUG -gt 5 ] 
            then printf "The RCH Filename of ${server_name} backup of is ${RCH_FILE}\n"
                 printf "The last Line in the file is : ${RCH_LINE}\n"
        fi 

        # Split the RCH Line 
        WSERVER=`echo -e $RCH_LINE | awk '{ print $1 }'`                # Extract Server Name
        WDATE1=` echo -e $RCH_LINE | awk '{ print $2 }'`                # Extract Date Started
        WTIME1=` echo -e $RCH_LINE | awk '{ print $3 }'`                # Extract Time Started
        WDATE2=` echo -e $RCH_LINE | awk '{ print $4 }'`                # Extract Date Started
        WTIME2=` echo -e $RCH_LINE | awk '{ print $5 }'`                # Extract Time Ended
        WELAPSE=`echo -e $RCH_LINE | awk '{ print $6 }'`                # Extract Time Ended
        WSCRIPT=`echo -e $RCH_LINE | awk '{ print $7 }'`                # Extract Script Name
        WALERT=` echo -e $RCH_LINE | awk '{ print $8 }'`                # Extract Alert Group Name
        WTYPE=`  echo -e $RCH_LINE | awk '{ print $9 }'`                # Extract Alert Group Type
        WRCODE=` echo -e $RCH_LINE | awk '{ print $10 }'`               # Extract Return Code 

        # Set the backup Status Description
        case "$WRCODE" in                                               # Case on RCH Return Code
            0 ) WSTATUS="Success" 
                ;; 
            1 ) WSTATUS="Failed"
                ;;
            2 ) WSTATUS="Running"
                ;;
            3 ) WSTATUS="No Backup"
                ;;
            * ) WRDESC="CODE $WRCODE ?"                                 # Illegal Code  Desc
                ;;                                                          
        esac
        
        # Build backup line to be written to work file (Will be sorted later)
        BLINE="${WDATE1},${WTIME1},${WELAPSE},${WSTATUS},${server_name}" 
        BLINE="${BLINE},${server_desc},${server_backup}"
        BLINE="${BLINE},${CUR_TOTAL},${PRV_TOTAL},${server_sporadic}" 
        echo "$BLINE" >> $SADM_TMP_FILE2                                # Write Info to work file
        done < $SADM_TMP_FILE1

    # Umount NFS Mount point, Sort the Work File (By Date/Time) then produce report it HTML format.
    unmount_nfs                                                         # UnMount NFS Backup Dir.
    sort $SADM_TMP_FILE2 > $SADM_TMP_FILE1                              # Sort Tmp file by Date/Time
    while read wline                                                    # Read Tmp file Line by Line
        do
        xcount=$(($xcount+1))                                           # Increase Line Counter
        backup_line "${wline},${xcount},$HTML_BFILE,B"                  # Insert line in HTML Page
        done < $SADM_TMP_FILE1                                          # Read Sorted file

    echo -e "</table>\n</body>\n</html>" >> $HTML_BFILE                 # End of HTML Page

    # Set Report by Email to SADMIN Administrator
    subject="Daily Backup Report"                                       # Send Backup Report by mail
    export EMAIL="$SADM_MAIL_ADDR"                                      # Set the FROM Email 
    mutt -e 'set content_type=text/html' -s "$subject" $SADM_MAIL_ADDR < $HTML_BFILE
    SADM_EXIT_CODE=$?                                                   # Save mutt return code
    if [ $SADM_EXIT_CODE -eq 0 ]                                        # If mail sent successfully
        then sadm_writelog "${SADM_OK} Daily Backup Report sent to $SADM_MAIL_ADDR"      
        else sadm_writelog "${SADM_ERROR} Failed to send the Daily Backup Report to $SADM_MAIL_ADDR"
    fi

    sadm_write "${BOLD}${YELLOW}End of Daily Backup Report ...${NORMAL}\n"   
    sadm_write "\n"                                                     # White line in log & Screen
    return $SADM_EXIT_CODE                                              # Return Err Count to caller
}



#===================================================================================================
# Report Heading
#===================================================================================================
report_heading()
{
    RTITLE=$1                                                           # Report Title
    HTML=$2                                                             # HTML Report File Name

    echo -e "<!DOCTYPE html><html>" > $HTML
    echo -e "<head>" >> $HTML
    echo -e "\n<meta charset='utf-8' />"            >> $HTML
    #
    echo -e "\n<style>" >> $HTML
    echo -e "th { color: white; background-color: #0000ff; padding: 5px; }" >> $HTML
    echo -e "td { color: white; border-bottom: 1px solid #ddd; padding: 5px; }" >> $HTML
    echo -e "tr:nth-child(odd)  { background-color: #F5F5F5; }" >> $HTML
    echo -e "table, th, td { border: 1px solid black; border-collapse: collapse; }" >> $HTML
    echo -e "</style>" >> $HTML
    #
    echo -e "\n<title>$RTITLE</title>" >> $HTML
    echo -e "</head>\n" >> $HTML
    echo -e "<body>" >> $HTML
    echo -e "<br>\n<center><h1>${RTITLE}</h1></center>" >> $HTML
    echo -e "\n<center><table border=0>" >> $HTML
    #
    echo -e "\n<thead>" >> $HTML
    #
    #echo -e "<tr>" >> $HTML
    #echo -e "<th colspan=10 dt-head-center>${RTITLE}</th>" >> $HTML
    #echo -e "</tr>" >> $HTML
    #
    echo -e "<tr>" >> $HTML
    echo -e "<th colspan=1 dt-head-center></th>" >> $HTML
    echo -e "<th colspan=4 align=center>Last Backup</th>" >> $HTML
    echo -e "<th align=center>Schedule</th>" >> $HTML
    echo -e "<th colspan=2></th>" >> $HTML
    echo -e "<th align=center>System</th>" >> $HTML
    echo -e "<th align=center>Current</th>" >> $HTML
    echo -e "<th align=center>Previous</th>" >> $HTML
    echo -e "</tr>" >> $HTML
    #
    echo -e "<tr>" >> $HTML
    echo -e "<th align=center>No</th>" >> $HTML
    echo -e "<th align=center>Date</th>" >> $HTML
    echo -e "<th align=center>Time</th>" >> $HTML
    echo -e "<th align=center>Elapse</th>" >> $HTML
    echo -e "<th align=center>Status</th>"  >> $HTML
    echo -e "<th align=left>Activated</th>" >> $HTML
    echo -e "<th align=center>System</th>" >> $HTML
    echo -e "<th align=left>Description</th>" >> $HTML    
    echo -e "<th align=left>Sporadic</th>" >> $HTML
    echo -e "<th align=center>Size</th>" >> $HTML
    echo -e "<th align=center>Size</th>" >> $HTML
    echo -e "</tr>" >> $HTML
    #
    echo -e "</thead>\n" >> $HTML
    return 0
}



#===================================================================================================
# Add the receiving line into the Backup report page
#===================================================================================================
backup_line()
{
    # Extract fields from parameters received.
    BACKUP_INFO=$*                                                      # Comma Sep. Info Line
    WDATE1=$(     echo $BACKUP_INFO | awk -F, '{ print $1 }')           # Backup Script RCH Line
    WTIME1=$(     echo $BACKUP_INFO | awk -F, '{ print $2 }')           # DB System Description
    WELAPSE=$(    echo $BACKUP_INFO | awk -F, '{ print $3 }')           # DB System Description
    WSTATUS=$(    echo $BACKUP_INFO | awk -F, '{ print $4 }')           # DB System Description
    WSERVER=$(    echo $BACKUP_INFO | awk -F, '{ print $5 }')           # DB System Description
    WDESC=$(      echo $BACKUP_INFO | awk -F, '{ print $6 }')           # DB System Description
    WACT=$(       echo $BACKUP_INFO | awk -F, '{ print $7 }')           # DB System Description
    WCUR_TOTAL=$( echo $BACKUP_INFO | awk -F, '{ print $8 }')           # Current Backup Total MB
    WPRV_TOTAL=$( echo $BACKUP_INFO | awk -F, '{ print $9 }')           # Yesterday Backup Total MB
    WSPORADIC=$(  echo $BACKUP_INFO | awk -F, '{ print $10 }')          # Sporadic Server=1 else=0
    WCOUNT=$(     echo $BACKUP_INFO | awk -F, '{ print $11 }')          # Line Counter
    HTML=$(       echo $BACKUP_INFO | awk -F, '{ print $12 }')          # HTML Output File Name
    RTYPE=$(      echo $BACKUP_INFO | awk -F, '{ print $13 }')          # R=RearBackup B=DailyBackup
                                                                        # S=Storix Report

    # Alternate background color at every line
    if (( $WCOUNT %2 == 0 ))                                            # Modulo on line counter
       then BCOL="#00FFFF" ; FCOL="#000000"                             # Pair count color
       else BCOL="#F0FFFF" ; FCOL="#000000"                             # Impar line color
    fi

    # Beginning to Insert Line in HTML Table
    echo -e "<tr>"  >> $HTML                                            # Begin backup line
    echo -e "<td align=center bgcolor=$BCOL><font color=$FCOL>$WCOUNT</font></td>"  >> $HTML

    # Storix Backup Date is not today (May be Missed, Sporadic, ...) Show in Yellow Background
    if [ "$RTYPE" = "S" ]                                               # If Backup Report 
       then if [ "$TODAY" = "$WDATE1" ]
               then echo "<td align=center bgcolor=$BCOL><font color=$FCOL>$WDATE1</font></td>" >>$HTML
               else if [ "$WDATE1" = "----------" ] 
                       then echo -n "<td title='No backup recorded' " >>$HTML 
                       else backup_date=`echo "$WDATE1" | sed 's/\./\//g'`      # Replace dot by '/' in date
                            epoch_backup=`date -d "$backup_date" "+%s"`         # Backup Date in Epoch Time
                            epoch_now=`date "+%s"`                              # Today in Epoch Time
                            diff=$(($epoch_now - $epoch_backup))                # Nb. Seconds between
                            days=$(($diff/(60*60*24)))                          # Convert Sec. to Days
                            echo -n "<td title='Last Backup done $days days ago' " >>$HTML   
                    fi
                    echo -n "align=center bgcolor='Yellow'>" >>$HTML      # Yellow Background
                    echo "<font color=$FCOL>$WDATE1</font></td>" >>$HTML  # Show Backup Date
            fi
    fi 

    # Backup Date is not today (May be Missed, Sporadic, ...) Show in Yellow Background
    if [ "$RTYPE" = "B" ]                                               # If Backup Report 
       then if [ "$TODAY" = "$WDATE1" ]
               then echo "<td align=center bgcolor=$BCOL><font color=$FCOL>$WDATE1</font></td>" >>$HTML
               else if [ "$WDATE1" = "----------" ] 
                       then echo -n "<td title='No backup recorded' " >>$HTML 
                       else backup_date=`echo "$WDATE1" | sed 's/\./\//g'`      # Replace dot by '/' in date
                            epoch_backup=`date -d "$backup_date" "+%s"`         # Backup Date in Epoch Time
                            epoch_now=`date "+%s"`                              # Today in Epoch Time
                            diff=$(($epoch_now - $epoch_backup))                # Nb. Seconds between
                            days=$(($diff/(60*60*24)))                          # Convert Sec. to Days
                            echo -n "<td title='Last Backup done $days days ago' " >>$HTML   
                    fi
                    echo -n "align=center bgcolor='Yellow'>" >>$HTML      # Yellow Background
                    echo "<font color=$FCOL>$WDATE1</font></td>" >>$HTML  # Show Backup Date
            fi
    fi 

    # ReaR Backup Date 
    if [ "$RTYPE" == "R" ]                                               # If Backup Report 
       then if [ "$WDATE1" = "----------" ] 
               then echo -n "<td title='No backup recorded' " >>$HTML 
                    echo -n "align=center bgcolor='Yellow'>" >>$HTML      # Yellow Background
               else backup_date=`echo "$WDATE1" | sed 's/\./\//g'`              # Replace dot by '/' in date
                    epoch_backup=`date -d "$backup_date" "+%s"`                 # Backup Date in Epoch Time
                    epoch_now=`date "+%s"`                                      # Today in Epoch Time
                    diff=$(($epoch_now - $epoch_backup))                        # Difference in Nb. Seconds
                    days=$(($diff/(60*60*24)))                                  # Convert Sec. to Days
                    if [ $days -gt $REAR_INTERVAL ] 
                       then echo -n "<td title='Last Backup done $days days ago' " >>$HTML  
                            echo -n "align=center bgcolor='Yellow'>" >>$HTML      # Yellow Background
                       else echo "<td align=center bgcolor=$BCOL>" >>$HTML 
                    fi 
            fi
            echo "<font color=$FCOL>$WDATE1</font></td>" >>$HTML  # Show Backup Date
    fi 

    # Backup Time & Elapse time
    echo "<td align=center bgcolor=$BCOL><font color=$FCOL>$WTIME1</font></td>"  >> $HTML
    echo "<td align=center bgcolor=$BCOL><font color=$FCOL>$WELAPSE</font></td>" >> $HTML
    #echo "<td align=center bgcolor=$BCOL><font color=$FCOL>$WSTATUS</font></td>" >> $HTML

    # Server Name - (If you click on it it will show the backup script log.)
    echo -e "<td align=center bgcolor=$BCOL><font color=$FCOL>" >> $HTML
    LOGFILE="${WSERVER}_${WSCRIPT}.log"                                 # Assemble log Script Name
    LOGNAME="${SADM_WWW_DAT_DIR}/${WSERVER}/log/${LOGFILE}"             # Add Dir. Path to Name
    LOGURL="http://sadmin.${SADM_DOMAIN}/${URL_VIEW_FILE}?filename=${LOGNAME}"  # Url to View Log
    if [ -r "$LOGNAME" ]                                                # If log is Readable
        then echo -n "<a href='$LOGURL 'title='View Backup Log File'>" >>$HTML
             echo "${WSTATUS}</font></a></td>" >>$HTML 
        else echo -e "${WSTATUS}</font></td>" >> $HTML                  # No Log = No LInk
    fi

    # Backup Schedule Status - Activated or Deactivated (show in Yellow background)
    if [ "$RTYPE" = "B" ]                                               # If Backup Report 
       then URL_SCHED_UPDATE=$(echo "${URL_UPD_SCHED/SYSTEM/$WSERVER}") # URL To Modify Backup Sched
       else URL_SCHED_UPDATE=$(echo "${URL_REAR_SCHED/SYSTEM/$WSERVER}")         # URL To Modify Backup Sched
    fi
    if [ $WACT -eq 0 ] 
       then echo "<td align=center bgcolor='Yellow'><font color=$FCOL>"         >>$HTML
            echo -n "<a href='http://sadmin.${SADM_DOMAIN}/$URL_SCHED_UPDATE "  >>$HTML
            echo "'title='Schedule Deactivated, click to modify'>No</font></a></td>" >>$HTML
       else echo "<td align=center bgcolor=$BCOL><font color=$FCOL>"            >>$HTML    
            echo -n "<a href='http://sadmin.${SADM_DOMAIN}/$URL_SCHED_UPDATE "  >>$HTML
            echo "'title='Click to modify Backup Schedule'>Yes</font></a></td>"          >>$HTML
    fi

    # Server Name & Descrition (From DB)
    echo "<td align=center bgcolor=$BCOL><font color=$FCOL>$WSERVER</font></td>" >> $HTML
    echo "<td align=left bgcolor=$BCOL><font color=$FCOL>$WDESC</font></td>"     >> $HTML

    # Sporadic Server or Not 
    if [ "$WSPORADIC" =  "0" ] 
       then echo "<td align=center bgcolor=$BCOL><font color=$FCOL>No</font></td>"  >>$HTML
       else echo "<td align=center bgcolor=$BCOL><font color=$FCOL>Yes</font></td>" >>$HTML
    fi

    # CUURENT BACKUP SIZE - Show in Yellow if : 
    #   - Today Backup Size is 0
    #   - If Today Backup Size vs Yesterday Backup Size is greater than threshold ($WPCT) go yellow
    if [ $WCUR_TOTAL -eq 0 ]                                            # If Today Backup Size is 0
        then echo -en "<td title='No Backup situation' align=center bgcolor='Yellow'>" >>$HTML
             echo -e "<font color=$FCOL>${WCUR_TOTAL} MB</font></td>" >> $HTML
        else if [ $WPRV_TOTAL -eq 0 ]                                   # If Yesterday Backup Size=0
                then echo -en "<td align=center bgcolor=$BCOL><font color=$FCOL>" >>$HTML
                     echo -e " ${WCUR_TOTAL} MB</font></td>" >>$HTML
                else if [ $WCUR_TOTAL -ge $WPRV_TOTAL ]                 # Today Backup >= Yesterday
                        then PCT=`echo "$WCUR_TOTAL / $WPRV_TOTAL" | bc -l`  
                             PCT=`printf "%.2f" $PCT | awk -F. '{print $2}'` # Backup Size Incr. Pct
                             if [ $PCT -ge $WPCT ]                      # Inc Greater than threshold
                                then echo -en "<td align=center bgcolor='Yellow' " >>$HTML
                                     echo "title='Backup ${WPCT}% bigger than yesterday'>" >>$HTML
                                     echo "<font color=$FCOL>${WCUR_TOTAL} MB</font></td>" >>$HTML
                                else echo -n "<td align=center bgcolor=$BCOL>" >>$HTML
                                     echo "<font color=$FCOL>${WCUR_TOTAL} MB</font></td>" >>$HTML
                             fi
                        else PCT=`echo "$WPRV_TOTAL / $WCUR_TOTAL" | bc -l` 
                             PCT=`printf "%.2f" $PCT | awk -F. '{print $2}'` # Backup Size Decr. Pct
                             if [ $PCT -ge $WPCT ] && [ $PCT -ne 0 ]         # Decr. less than threshold
                                then echo -n "<td title='Backup ${WPCT}% smaller than yesterday' " >>$HTML
                                     echo "align=center bgcolor='Yellow'> " >> $HTML
                                     echo "<font color=$FCOL>${WCUR_TOTAL} MB</font></td>" >>$HTML
                                else echo -n "<td align=center bgcolor=$BCOL>" >>$HTML
                                     echo "<font color=$FCOL>${WCUR_TOTAL} MB</font></td>" >>$HTML
                             fi
                     fi 
             fi 
    fi 


    # If Yesterday Backup Size is 0, show it in Yellow.
    if [ $WPRV_TOTAL -eq 0 ]                                
        then echo -en "<td title='No Backup situation' align=center bgcolor='Yellow'>" >>$HTML
             echo -e "<font color=$FCOL>${WPRV_TOTAL} MB</font></td>" >> $HTML
        else echo -en "<td align=center bgcolor=$BCOL><font color=$FCOL> " >> $HTML
             echo -e " ${WPRV_TOTAL} MB</font></td>" >> $HTML
    fi 

    echo -e "</tr>\n" >> $HTML
    return 
} 



# --------------------------------------------------------------------------------------------------
# Command line Options functions
# Evaluate Command Line Switch Options Upfront
# By Default (-h) Show Help Usage, (-v) Show Script Version,(-d0-9] Set Debug Level 
# By Default all report will be produce and email to sysadmin (Except Storix report)
# --------------------------------------------------------------------------------------------------
function cmd_options()
{
    OPTION_SELECTED=0                                                   # Default no option selected
    while getopts "hvd:brsx" opt ; do                                   # Loop to process Switch
        case $opt in
            b) BACKUP_REPORT="OFF"                                      # De-Activate Backup report
               OPTION_SELECTED=$(($OPTION_SELECTED+1))                  # Incr. Nb. Option Selected
               ;;                                       
            r) REAR_REPORT="OFF"                                        # De-Activate ReaR Report
               OPTION_SELECTED=$(($OPTION_SELECTED+1))                  # Incr. Nb. Option Selected
               ;;
            s) SCRIPT_REPORT="OFF"                                      # De-Activate Script Report
               OPTION_SELECTED=$(($OPTION_SELECTED+1))                  # Incr. Nb. Option Selected
               ;;
            x) STORIX_REPORT="ON"                                       # Produce Storix Reports
               OPTION_SELECTED=$(($OPTION_SELECTED+1))                  # Incr. Nb. Option Selected
               ;;
            d) SADM_DEBUG=$OPTARG                                       # Get Debug Level Specified
               num=`echo "$SADM_DEBUG" | grep -E ^\-?[0-9]?\.?[0-9]+$`  # Valid is Level is Numeric
               if [ "$num" = "" ]                                       # No it's not numeric 
                  then printf "\nDebug Level specified is invalid.\n"   # Inform User Debug Invalid
                       show_usage                                       # Display Help Usage
                       exit 1                                           # Exit Script with Error
               fi
               printf "Debug Level set to ${SADM_DEBUG}.\n"             # Display Debug Level
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

    if [ "$BACKUP_REPORT" = "ON" ]                                      # If CmdLine -b was used
        then backup_report                                              # Produce Backup Report 
             RC=$?                                                      # Save the Return Code
             SADM_EXIT_CODE=$(($SADM_EXIT_CODE+$RC))                    # Add ReturnCode to ExitCode
    fi 
    if [ "$REAR_REPORT" = "ON" ]                                        # If CmdLine -r was used
        then rear_report                                                # Produce ReaR Backup Report 
             RC=$?                                                      # Save the Return Code
             SADM_EXIT_CODE=$(($SADM_EXIT_CODE+$RC))                    # Add ReturnCode to ExitCode
    fi 
    if [ "$STORIX_REPORT" = "ON" ]                                      # If CmdLine -x was used
        then storix_report                                              # Produce Storix Backup Rep. 
             RC=$?                                                      # Save the Return Code
             SADM_EXIT_CODE=$(($SADM_EXIT_CODE+$RC))                    # Add ReturnCode to ExitCode
    fi 
    if [ "$SCRIPT_REPORT" = "ON" ]                                      # If CmdLine -s was used
        then script_report                                              # Produce Script Report 
             RC=$?                                                      # Save the Return Code
             SADM_EXIT_CODE=$(($SADM_EXIT_CODE+$RC))                    # Add ReturnCode to ExitCode
    fi 

    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log 
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
    
