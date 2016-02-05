#!/usr/bin/env sh
#===================================================================================================
#  Author:    Jacques Duplessis
#  Title      sadm_lib_std.sh
#  Date:      August 2015
#  Synopsis:  SADMIN  Shell Script Main Library
#  
# --------------------------------------------------------------------------------------------------
# Description
# This file is not a stand-alone shell script; it provides functions to your scripts that source it.
# --------------------------------------------------------------------------------------------------
#
#===================================================================================================
trap 'exit 0' 2                                                         # Intercepte The ^C    
#set -x


# --------------------------------------------------------------------------------------------------
#                             V A R I A B L E S      D E F I N I T I O N S
# --------------------------------------------------------------------------------------------------
#
HOSTNAME=`hostname -s`                          ; export HOSTNAME       # Current Host name
SADM_DASH=`printf %80s |tr " " "="`             ; export SADM_DASH      # 80 equals sign line
SADM_TEN_DASH=`printf %10s |tr " " "-"`         ; export SADM_TEN_DASH  # 10 dashes line
SADM_VAR1=""                                    ; export SADM_VAR1      # Temp Dummy Variable
SADM_STIME=""                                   ; export SADM_STIME     # Script Start Time
#
# SADMIN DIRECTORIES STRUCTURES DEFINITIONS
SADM_BASE_DIR=${SADMIN:="/sadmin"}              ; export SADM_BASE_DIR  # Script Root Base Dir.
SADM_BIN_DIR="$SADM_BASE_DIR/bin"               ; export SADM_BIN_DIR   # Script Root binary Dir.
SADM_TMP_DIR="$SADM_BASE_DIR/tmp"               ; export SADM_TMP_DIR   # Script Temp  directory
SADM_LIB_DIR="$SADM_BASE_DIR/lib"               ; export SADM_LIB_DIR   # Script Lib directory
SADM_LOG_DIR="$SADM_BASE_DIR/log"               ; export SADM_LOG_DIR   # Script log directory
SADM_CFG_DIR="$SADM_BASE_DIR/cfg"               ; export SADM_CFG_DIR   # Configuration Directory
SADM_SYS_DIR="$SADM_BASE_DIR/sys"               ; export SADM_SYS_DIR   # System related scripts
SADM_DAT_DIR="$SADM_BASE_DIR/dat"               ; export SADM_DAT_DIR   # Data directory
SADM_PKG_DIR="$SADM_BASE_DIR/pkg"               ; export SADM_PKG_DIR   # Package rpm,deb  directory
SADM_NMON_DIR="$SADM_DAT_DIR/nmon"              ; export SADM_NMON_DIR  # Where nmon file reside
SADM_DR_DIR="$SADM_DAT_DIR/dr"                  ; export SADM_DR_DIR    # Disaster Recovery  files 
SADM_SAR_DIR="$SADM_DAT_DIR/sar"                ; export SADM_SAR_DIR   # System Activty Report Dir
SADM_RCH_DIR="$SADM_DAT_DIR/rch"                ; export SADM_RCH_DIR   # Result Code History Dir
#
# SADMIN WEB SITE DIRECTORY DEFINITION
SADM_WWW_DIR="$SADM_BASE_DIR/www"               ; export SADM_WWW_DIR      # sadmin Web Site Dir.
SADM_WWW_DAT_DIR="$SADM_WWW_DIR/dat"            ; export SADM_WWW_DAT_DIR  # sadmin server Data Dir.
SADM_WWW_HTML_DIR="$SADM_WWW_DIR/html"          ; export SADM_WWW_HTML_DIR # sadmin server Data Dir.
#
#
# SADM CONFIG FILE, LOGS, AND TEMP FILES USER CAN USE
SADM_PID_FILE="${SADM_TMP_DIR}/${SADM_INST}.pid"            ; export SADM_PID_FILE   # PID file name
SADM_CFG_FILE="$SADM_CFG_DIR/sadmin.cfg"                    ; export SADM_CFG_FILE   # Cfg file name
SADM_CFG_HIDDEN="$SADM_CFG_DIR/.sadmin.cfg"                 ; export SADM_CFG_HIDDEN # Cfg file name
SADM_TMP_FILE1="${SADM_TMP_DIR}/${SADM_INST}_1.$$"          ; export SADM_TMP_FILE1  # Temp File 1 
SADM_TMP_FILE2="${SADM_TMP_DIR}/${SADM_INST}_2.$$"          ; export SADM_TMP_FILE2  # Temp File 2
SADM_TMP_FILE3="${SADM_TMP_DIR}/${SADM_INST}_3.$$"          ; export SADM_TMP_FILE3  # Temp File 3
SADM_LOG="${SADM_LOG_DIR}/${HOSTNAME}_${SADM_INST}.log"    ; export LOG              # Output LOG 
SADM_RCHLOG="${SADM_RCH_DIR}/${HOSTNAME}_${SADM_INST}.rch" ; export SADM_RCHLOG      # Return Code 
#
# COMMAND PATH REQUIRE TO RUN SADM
SADM_LSB_RELEASE=""                             ; export SADM_LSB_RELEASE # Command lsb_release Path
SADM_DMIDECODE=""                               ; export SADM_DMIDECODE # Command dmidecode Path
SADM_BC=""                                      ; export SADM_BC        # Command bc (Do Some Math)
SADM_FDISK=""                                   ; export SADM_FDISK     # fdisk (Read Disk Capacity)
SADM_WHICH=""                                   ; export SADM_WHICH     # which Path - Required
SADM_PRTCONF=""                                 ; export SADM_PRTCONF   # prtconf  Path - Required
SADM_PERL=""                                    ; export SADM_PERL      # perl Path (for epoch time)
SADM_MAIL=""                                    ; export SADM_MAIL      # Mail Pgm Path 
#


# --------------------------------------------------------------------------------------------------
#                     THIS FUNCTION RETURN THE STRING RECEIVED TO UPPERCASE
# --------------------------------------------------------------------------------------------------
#
sadm_toupper() { 
    echo $1 | tr  "[:lower:]" "[:upper:]"
}


# --------------------------------------------------------------------------------------------------
#                       THIS FUNCTION RETURN THE STRING RECEIVED TO LOWERCASE 
# --------------------------------------------------------------------------------------------------
#
sadm_tolower() {
    echo $1 | tr  "[:upper:]" "[:lower:]"
}



# --------------------------------------------------------------------------------------------------
#     WRITE INFORMATION TO THE LOG (L) , TO SCREEN (S)  OR BOTH (B) DEPENDING ON $SADM_LOG_TYPE
# --------------------------------------------------------------------------------------------------
#
sadm_logger() {
    SADM_MSG="$(date "+%C%y.%m.%d %H:%M:%S") - $@"                      # Join Cur Date & Msg Recv.
    case "$SADM_LOG_TYPE" in                                            # Depending of LOG_TYPE
        s|S) printf "%-s\n" "$SADM_MSG"                                 # Write Msg To Screen
             ;; 
        l|L) printf "%-s\n" "$SADM_MSG" >> $SADM_LOG                    # Write Msg to Log File
             ;; 
        b|B) printf "%-s\n" "$SADM_MSG"                                 # Both = to Screen
             printf "%-s\n" "$SADM_MSG" >> $SADM_LOG                    # Both = to Log
             ;;
        *)   printf "Wrong value in \$SADM_LOG_TYPE ($SADM_LOG_TYPE)\n" # Advise User if Incorrect
    esac
}



# --------------------------------------------------------------------------------------------------
#                        CURRENT USER IS "ROOT"  OR NOT ?
#  IS_ROOT && ECHO "YOU ARE LOGGED IN AS ROOT." || ECHO "YOU ARE NOT LOGGED IN AS ROOT."
# --------------------------------------------------------------------------------------------------
#
sadm_is_root() {
   [ $(id -u) -eq 0 ] && return $TRUE || return $FALSE
}



# --------------------------------------------------------------------------------------------------
# THIS FUNCTION VERIFY IF THE COMMAND RECEIVED IN PARAMETER IS AVAILABLE ON THE SERVER 
# IF THE COMMAND EXIST, RETURN 0, IF IT DOESN' T EXIST RETURN 1
# --------------------------------------------------------------------------------------------------
#
sadm_check_command_availibility() {
    SADM_CMD=$1                                                         # Save Parameter received
    if ${SADM_WHICH} ${SADM_CMD} >/dev/null 2>&1                        # command is found ?
        then SADM_VAR1=`${SADM_WHICH} ${SADM_CMD}`                      # Store Path of command
             return 0                                                   # Return 0 if cmd found
        else SADM_VAR1=""                                               # Clear Path of command
             sadm_logger " "                                            # Inform User 
             sadm_logger "WARNING : Missing Requirement "
             sadm_logger "The ${SADM_CMD} command is not available on the system"
             sadm_logger "You need to install it before we can used functions of SADMIN Library"
             sadm_logger "Once the software is installed, rerun this script"
             sadm_logger "Will continue anyway, but some functionnality may not work"
    fi  
    return 1
}



# --------------------------------------------------------------------------------------------------
# THIS FUNCTION MAKE SURE THAT ALL SADM SHELL LIBRARIES (LIB/SADM_*) REQUIREMENTS ARE MET BEFORE USE
# IF THE REQUIRENMENT ARE NOT MET, THEN THE SCRIPT WILL ABORT INFORMING USER TO CORRECT SITUATION
# --------------------------------------------------------------------------------------------------
#
sadm_check_requirements() {
                           
    # which command is needed to determine presence of command - Return Error if not found
    if which which >/dev/null 2>&1                                      # Try the command which 
        then SADM_WHICH=`which which`  ; export SADM_WHICH              # Save the Path of Which
        else sadm_logger "Error : The command 'which' could not be found" 
             sadm_logger "        This program is often used by the SADMIN tools"
             sadm_logger "        Please install it and re-run this script"
             sadm_logger "        To install it, use the following command depending on your distro"
             sadm_logger "        Use 'yum install which' or 'apt-get install debianutils'"
             sadm_logger "Script Aborted"
             return 1                                                   # Return Error to Caller
    fi
    
    # Commands require on Linux O/S
    if [ "$(sadm_ostype)" = "LINUX" ]                                   # Under Linux
       then sadm_check_command_availibility lsb_release                 # lsb_release cmd available?
            SADM_LSB_RELEASE=$SADM_VAR1                                 # Save Command Path
            sadm_check_command_availibility dmidecode                   # dmidecode cmd available?
            SADM_DMIDECODE=$SADM_VAR1                                   # Save Command Path
            sadm_check_command_availibility fdisk                       # FDISK cmd available?
            SADM_FDISK=$SADM_VAR1                                       # Save Command Path
            sadm_check_command_availibility bc                          # bc cmd available?
            SADM_BC=$SADM_VAR1                                          # Save Command Path
            sadm_check_command_availibility mail                        # Mail cmd available?
            SADM_MAIL=$SADM_VAR1                                        # Save Command Path
    fi
    
    # Commands Require on Aix O/S
    if [ "$(sadm_ostype)" = "AIX" ]                                     # Under Aix O/S
       then sadm_check_command_availibility bc                          # bc cmd available?
            SADM_BC=$SADM_VAR1                                          # Save Command Path
            sadm_check_command_availibility prtconf                     # prtconf cmd available?
            SADM_PRTCONF=$SADM_VAR1                                     # Save Command Path
    fi
    
    # Commands require on Linux and Aix 
    sadm_check_command_availibility perl                                # perl needed (epoch time)
    SADM_PERL=$SADM_VAR1                                                # Save perl path
    return 0
}



# --------------------------------------------------------------------------------------------------
#                       R E T U R N      C U R R E N T    E P O C H   T I M E           
# --------------------------------------------------------------------------------------------------
sadm_get_epoch_time() {
    w_epoch_time=`${SADM_PERL} -e 'print time'`                         # Use Perl to get Epoch Time
    echo "$w_epoch_time"                                                # Return Epoch to Caller
}



# --------------------------------------------------------------------------------------------------
#    C O N V E R T   E P O C H   T I M E    R E C E I V E   T O    D A T E  (YYYY.MM.DD HH:MM:SS)
# --------------------------------------------------------------------------------------------------
sadm_epoch_to_date() {

    if [ $# -ne 1 ]                                                     # Should have rcv 1 Param
        then sadm_logger "No Parameter received by $FUNCNAME function"  # Show User Info on Error
             sadm_logger "Please correct your script - Script Aborted"  # Advise User to Correct
             sadm_stop 1                                                # Prepare to exit gracefully
             exit 1                                                     # Terminate the script
    fi
    wepoch=$1                                                           # Save Epoch Time Receivec

    # Verify if parameter received is all numeric - If not advice user and exit
    echo $wepoch | grep [^0-9] > /dev/null 2>&1                         # Grep for Number
    if [ "$?" -eq "0" ]                                                 # Not All Number
        then sadm_logger "Incorrect parameter received by \"sadm_epoch_to_date\" function"
             sadm_logger "Should recv. epoch time & received ($wepoch)" # Advise User
             sadm_logger "Please correct situation - Script Aborted"    # Advise that will abort
             sadm_stop 1                                                # Prepare to exit gracefully
             exit 1                                                     # Terminate the script
    fi
    
    # Format the Converted Epoch time obtain from Perl 
    WDATE=`$SADM_PERL -e "print scalar(localtime($wepoch))"`            # Perl Convert Epoch to Date
    YYYY=`echo    $WDATE | awk '{ print $5 }'`                          # Extract the Year 
    HMS=`echo     $WDATE | awk '{ print $4 }'`                          # Extract Hour:Min:Sec
    DD=`echo      $WDATE | awk '{ print $3 }'`                          # Extract Day Number
    MON_STR=`echo $WDATE | awk '{ print $2 }'`                          # Extract Month String
    if [ "$MON_STR" = "Jan" ] ; then MM=01 ; fi                         # Convert Jan to 01 
    if [ "$MON_STR" = "Feb" ] ; then MM=02 ; fi                         # Convert Feb to 02
    if [ "$MON_STR" = "Mar" ] ; then MM=03 ; fi                         # Convert Mar to 03
    if [ "$MON_STR" = "Apr" ] ; then MM=04 ; fi                         # Convert Apr to 04
    if [ "$MON_STR" = "May" ] ; then MM=05 ; fi                         # Convert May to 05
    if [ "$MON_STR" = "Jun" ] ; then MM=06 ; fi                         # Convert Jun to 06
    if [ "$MON_STR" = "Jul" ] ; then MM=07 ; fi                         # Convert Jul to 07
    if [ "$MON_STR" = "Aug" ] ; then MM=08 ; fi                         # Convert Aug to 08
    if [ "$MON_STR" = "Sep" ] ; then MM=09 ; fi                         # Convert Sep to 09
    if [ "$MON_STR" = "Oct" ] ; then MM=10 ; fi                         # Convert Oct to 10
    if [ "$MON_STR" = "Nov" ] ; then MM=11 ; fi                         # Convert Nov to 11
    if [ "$MON_STR" = "Dec" ] ; then MM=12 ; fi                         # Convert Dec to 12
    w_epoch_to_date="${YYYY}.${MM}.${DD} ${HMS}"                        # Combine Data to form Date
    echo "$w_epoch_to_date"                                             # Return converted date
}



# --------------------------------------------------------------------------------------------------
#    C O N V E R T   D A T E  (YYYY.MM.DD HH:MM:SS)  R E C E I V E    T O    E P O C H   T I M E  
# --------------------------------------------------------------------------------------------------
sadm_date_to_epoch() {
    if [ $# -ne 1 ]                                                     # Should have rcv 1 Param
        then sadm_logger "No Parameter received by $FUNCNAME function"  # Log Error Mess,
             sadm_logger "Please correct script please, script aborted" # Advise that will abort
             sadm_stop 1                                                # Prepare to exit gracefully
             exit 1                                                     # Terminate the script
    fi
    WDATE=$1                                                            # Save Received Date
    YYYY=`echo $WDATE | awk -F. '{ print $1 }'`                         # Extract Year from Rcv Date
    MTH=`echo   $WDATE | awk -F. '{ print $2 }'`                        # Extract MTH  from Rcv Date
    let MTH="$MTH -1"                                                   # Month less one for perl
    if [ "$MTH" -gt 0 ] ; then MTH=`echo $MTH | sed 's/^0//'` ; fi      # Remove Leading 0 from Mth
    DD=`echo   $WDATE | awk -F. '{ print $3 }' | awk '{ print $1 }' | sed 's/^0//'` # Extract Day
    HH=`echo   $WDATE | awk '{ print $2 }' | awk -F: '{ print $1 }' | sed 's/^0//'` # Extract Hours
    MM=`echo   $WDATE | awk '{ print $2 }' | awk -F: '{ print $2 }' | sed 's/^0//'` # Extract Min   
    SS=`echo   $WDATE | awk '{ print $2 }' | awk -F: '{ print $3 }' | sed 's/^0//'` # Extract Sec
    
    # Call Perl to Return Epoch Time for Date Received   
    sadm_date_to_epoch=`perl -e "use Time::Local; print timelocal($SS,$MM,$HH,$DD,$MTH,$YYYY)"`
    echo "$sadm_date_to_epoch"                                          # Return Epoch of Date Rcv.
}



# --------------------------------------------------------------------------------------------------
#    Calculate elapse time between date1 (YYYY.MM.DD HH:MM:SS) and date2 (YYYY.MM.DD HH:MM:SS)
#    Date 1 MUST be greater than date 2  (Date 1 = Like End time,  Date 2 = Start Time )
# --------------------------------------------------------------------------------------------------
sadm_elapse_time() {
    if [ $# -ne 2 ]                                                     # Should have rcv 1 Param
        then sadm_logger "Invalid number of parameter received by $FUNCNAME function"
             sadm_logger "Please correct script please, script aborted" # Advise that will abort
             sadm_stop 1                                                # Prepare to exit gracefully
             exit 1                                                     # Terminate the script
    fi
    w_endtime=$1                                                        # Save Ending Time
    w_starttime=$2                                                      # Save Start Time
    epoch_start=`sadm_date_to_epoch "$w_starttime"`                     # Get Epoch for Start Time
    epoch_end=`sadm_date_to_epoch   "$w_endtime"`                       # Get Epoch for End Time
    epoch_elapse=`echo "$epoch_end - $epoch_start" | $SADM_BC`          # Substract End - Start time
    whour=00 ; wmin=00 ; wsec=00
    
    # Calculate number of hours (1 hr = 3600 Seconds)
    if [ "$epoch_elapse" -gt 3600 ]                                     # If nb Sec Greater than 1Hr
        then whour=`echo "$epoch_elapse / 3600" | $SADM_BC`             # Calculate nb of Hours
             epoch_elapse=`echo "$epoch_elapse - ($whours * 3600)" | $SADM_BC` # Sub Hr*Sec from elapse
    fi

    # Calculate number of minutes 1 Min = 60 Seconds)
    if [ "$epoch_elapse" -gt 60 ]                                       # If more than 1 min left
       then  wmin=`echo "$epoch_elapse / 60" | $SADM_BC`                # Calc. Nb of minutes
             epoch_elapse=`echo  "$epoch_elapse - ($wmin * 60)" | $SADM_BC` # Sub Min*Sec from elapse
    fi
    wsec=$epoch_elapse                                                  # left is less than 60 sec
    sadm_elapse=`printf "%02d:%02d:%02d" ${whour} ${wmin} ${wsec}`      # Format Result
    echo "$sadm_elapse"                                                 # Return Result to caller
}



# --------------------------------------------------------------------------------------------------
#                THIS FUNCTION DETERMINE THE OS (DISTRIBUTION) VERSION NUMBER 
# --------------------------------------------------------------------------------------------------
sadm_osversion() {
    sadm_osversion="0.0"                                                # Default Value
    case "$(sadm_ostype)" in                                            
        "LINUX") sadm_osversion=`$SADM_LSB_RELEASE -sr`                 # Use lsb_release to Get Ver
                 ;; 
        "AIX")   sadm_osversion="`uname -v`.`uname -r`"                 # Get Aix Version 
                 ;;
    esac
    echo "$sadm_osversion"
}

# --------------------------------------------------------------------------------------------------
#                            RETURN THE OS (DISTRIBUTION) MAJOR VERSION
# --------------------------------------------------------------------------------------------------
sadm_osmajorversion() {
    case "$(sadm_ostype)" in
        "LINUX") sadm_osmajorversion=`echo $(sadm_osversion) | awk -F. '{ print $1 }'| tr -d ' '`
                 ;;
        "AIX")   sadm_osmajorversion=`uname -v`
                 ;;
    esac
    echo "$sadm_osmajorversion"
}

# --------------------------------------------------------------------------------------------------
#                RETURN THE OS TYPE (LINUX, AIX) -- ALWAYS RETURNED IN UPPERCASE
# --------------------------------------------------------------------------------------------------
sadm_ostype() {
    sadm_ostype=`uname -s | tr '[:lower:]' '[:upper:]'`                # Get OS Name (AIX or LINUX)
    echo "$sadm_ostype"
}



# --------------------------------------------------------------------------------------------------
#                             RETURN THE OS PROJECT CODE NAME
# --------------------------------------------------------------------------------------------------
sadm_oscodename() {
    if [ "$(sadm_ostype)" = "LINUX" ] ; then sadm_oscodename=`$SADM_LSB_RELEASE -sc`; fi
    if [ "$(sadm_ostype)" = "AIX" ]   ; then sadm_oscodename="IBM_AIX" ; fi
    echo "$sadm_oscodename"
}



# --------------------------------------------------------------------------------------------------
#                   RETURN THE OS  NAME (ALWAYS RETURNED IN UPPERCASE)
# --------------------------------------------------------------------------------------------------
sadm_osname() {
    if [ "$(sadm_ostype)" = "LINUX" ]
        then sadm_osname=`$SADM_LSB_RELEASE -si | tr '[:lower:]' '[:upper:]'`
             if [ "$sadm_osname" = "REDHATENTERPRISESERVER" ] ; then sadm_osname="REDHAT" ; fi
             if [ "$sadm_osname" = "REDHATENTERPRISEAS" ]     ; then sadm_osname="REDHAT" ; fi
    fi 
    if [ "$(sadm_ostype)" = "AIX" ]   ; then sadm_osname="AIX" ; fi
    echo "$sadm_osname"
}



# --------------------------------------------------------------------------------------------------
#                                 RETURN THE HOSTNAME (SHORT)
# --------------------------------------------------------------------------------------------------
sadm_hostname() {
    if [ "$(sadm_ostype)" = "LINUX" ]                                  # Under Linux
        then sadm_hostname=`hostname -s`                                # Get rid of domain name
    fi
    if [ "$(sadm_ostype)" = "AIX" ]                                    # Under AIX
        then sadm_hostname=`hostname`                                   # Get HostName
    fi
    echo "$sadm_hostname"
}




# --------------------------------------------------------------------------------------------------
#                                 RETURN THE DOMAINNAME (SHORT)
# --------------------------------------------------------------------------------------------------
sadm_domainname() {
    case "$(sadm_ostype)" in
        "LINUX") sadm_domainname=`host $(sadm_hostname) |head -1 |awk '{ print $1 }' |cut -d. -f2-3` 
                 ;;
        "AIX")   sadm_domainname=`namerslv -s | grep domain | awk '{ print $2 }'`
                 ;;
    esac
    echo "$sadm_domainname"
}



# --------------------------------------------------------------------------------------------------
#                              RETURN THE IP OF THE CURRENT HOSTNAME
# --------------------------------------------------------------------------------------------------
sadm_host_ip() {
    case "$(sadm_ostype)" in
        "LINUX") sadm_host_ip=`host $(sadm_hostname) |awk '{ print $4 }' |head -1` 
                 ;;
        "AIX")   sadm_host_ip=`host $(sadm_hostname).$(sadm_domainname) |head -1 |awk '{ print $3 }'` 
                 ;;
    esac    
    echo "$sadm_host_ip"
}



# --------------------------------------------------------------------------------------------------
#                     Return if running 32 or 64 Bits Kernel version
# --------------------------------------------------------------------------------------------------
sadm_kernel_bitmode() { 
    case "$(sadm_ostype)" in
        "LINUX")   sadm_kernel_bitmode=`getconf LONG_BIT`
                   ;;
        "AIX")     sadm_kernel_bitmode=`getconf KERNEL_BITMODE`
                   ;;
    esac
    echo "$sadm_kernel_bitmode"
}



# --------------------------------------------------------------------------------------------------
#                                 RETURN KERNEL RUNNING VERSION
# --------------------------------------------------------------------------------------------------
sadm_kernel_version() {
    case "$(sadm_ostype)" in
        "LINUX")   sadm_kernel_version=`uname -r | cut -d. -f1-3`
                   ;;
        "AIX")     sadm_kernel_version=`uname -r`
                   ;;
    esac
    
    echo "$sadm_kernel_version"
}



# --------------------------------------------------------------------------------------------------
#            LOAD SADMIN CONFIGURATION FILE AND SET GLOBAL VARIABLES ACCORDINGLY
# --------------------------------------------------------------------------------------------------
#
sadm_load_sadmin_config_file() 
{
    # Set the Default Values - in case we could not load the SADMIN Config File
    SADM_MAIL_ADDR="root@localhost"           ; export SADM_MAIL_ADDR     # Default email address
    SADM_CIE_NAME="Your Company Name"         ; export SADM_CIE_NAME      # Company Name
    SADM_MAIL_TYPE=3                          ; export SADM_MAIL_TYPE     # Send Email after each run
    SADM_SERVER=`host sadmin | cut -d' ' -f1` ; export SADM_SERVER        # SADMIN server
    SADM_USER="sadmin"                        ; export SADM_USER          # sadmin user account
    SADM_GROUP="sadmin"                       ; export SADM_GROUP         # sadmin group account
    SADM_MAX_LOGLINE=5000                     ; export SADM_MAX_LOGLINE   # Max Line in each *.log
    SADM_MAX_RCLINE=100                       ; export SADM_MAX_RCLINE    # Max Line in each *.rch
    SADM_NMON_KEEPDAYS=40                     ; export SADM_NMON_KEEPDAYS # Days to keep old *.nmon
    SADM_SAR_KEEPDAYS=40                      ; export SADM_SAR_KEEPDAYS  # Days ro keep old *.sar
    

    # Configuration file MUST be present - If .sadm_config exist, then create sadm_config from it.
    if [ ! -r "$SADM_CFG_FILE" ]
        then if [ ! -r "$SADM_CFG_HIDDEN" ] 
                then sadm_logger "****************************************************************"
                     sadm_logger "SADMIN Configuration file is not found - $SADM_CFG_FILE "
                     sadm_logger "Even the config template file cannot be found - $SADM_CFG_HIDDEN"
                     sadm_logger "Copy both files from another system to this server"
                     sadm_logger "Or restore the files from a backup"
                     sadm_logger "Review the file content."
                     sadm_logger "****************************************************************"
                else sadm_logger "****************************************************************"
                     sadm_logger "The configuration file $SADM_CFG_FILE do not exist."
                     sadm_logger "Will continue using template configuration file $SADM_CFG_HIDDEN"
                     sadm_logger "Please review the configuration file."
                     sadm_logger "cp $SADM_CFG_HIDDEN $SADM_CFG_FILE"   # Install Default cfg  file
                     cp $SADM_CFG_HIDDEN $SADM_CFG_FILE                 # Install Default cfg  file
                     sadm_logger "****************************************************************"
             fi
    fi
    
    
    # Loop for reading the sadmin configuration file
    while read wline 
        do
        FC=`echo $wline | cut -c1`
        if [ "$FC" = "#" ] || [ ${#wline} -eq 0 ] ; then continue ; fi
        #
        echo "$wline" |grep -i "^SADM_MAIL_ADDR" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_MAIL_ADDR=`echo "$wline"     | cut -d= -f2 |tr -d ' '` ; fi
        #
        echo "$wline" |grep -i "^SADM_CIE_NAME" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_CIE_NAME=`echo "$wline" |cut -d= -f2 |sed -e 's/^[ \t]*//'` ;fi
        #
        echo "$wline" |grep -i "^SADM_MAIL_TYPE" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_MAIL_TYPE=`echo "$wline"     |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_SERVER" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_SERVER=`echo "$wline"        |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_USER" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_USER=`echo "$wline"          |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_GROUP" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_GROUP=`echo "$wline"         |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_MAX_LOGLINE" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_MAX_LOGLINE=`echo "$wline"   |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_MAX_RCHLINE" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_MAX_RCLINE=`echo "$wline"    |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_NMON_KEEPDAYS" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_NMON_KEEPDAYS=`echo "$wline" |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_SAR_KEEPDAYS" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_SAR_KEEPDAYS=`echo "$wline"  |cut -d= -f2 |tr -d ' '` ;fi
        #
        done < $SADM_CFG_FILE

        # For Debugging Purpose - Display Final Value of configuration file
        if [ "$SADM_DEBUG_LEVEL" -gt "8" ]
            then sadm_logger ""
                 sadm_logger "SADM_DEBUG_LEVEL $SADM_DEBUG_LEVEL Information"
                 sadm_logger "  - SADM_MAIL_ADDR=$SADM_MAIL_ADDR"         # Default email address
                 sadm_logger "  - SADM_CIE_NAME=$SADM_CIE_NAME"           # Company Name
                 sadm_logger "  - SADM_MAIL_TYPE=$SADM_MAIL_TYPE"         # Send Email after each run
                 sadm_logger "  - SADM_SERVER=$SADM_SERVER"               # SADMIN server
                 sadm_logger "  - SADM_USER=$SADM_USER"                   # sadmin user account
                 sadm_logger "  - SADM_GROUP=$SADM_GROUP"                 # sadmin group account
                 sadm_logger "  - SADM_MAX_LOGLINE=$SADM_MAX_LOGLINE"     # Max Line in each *.log
                 sadm_logger "  - SADM_MAX_RCLINE=$SADM_MAX_RCLINE"       # Max Line in each *.rch
                 sadm_logger "  - SADM_NMON_KEEPDAYS=$SADM_NMON_KEEPDAYS" # Days to keep old *.nmon
                 sadm_logger "  - SADM_SAR_KEEPDAYS=$SADM_SAR_KEEPDAYS"   # Days ro keep old *.sar
        fi                 
        return 0
}



# --------------------------------------------------------------------------------------------------
#                   SADM INITIALIZE FUNCTION - EXECUTE BEFORE DOING ANYTHING
# What this function do.
#   1) Make sure All SADM Directories and sub-directories exist and they have proper permission
#   2) Make sure the log file exist with proper permission ($SADM_LOG)
#   3) Make sure the Return Code History Log exist and have the right permission
#   4) Create script PID file - If it exist and user want to run only 1 copy of script, then abort
#   5) Add line in the [R]eturn [C]ode [H]istory file stating script is started (Code 2)
#   6) Write HostName - Script name and version - O/S Name and version to the Log file ($SADM_LOG)
# --------------------------------------------------------------------------------------------------
#
sadm_start() {

    # If log Directory doesn't exist, create it.
    if [ ! -d "$SADM_LOG_DIR" ]
        then mkdir -p $SADM_LOG_DIR
             chmod 2775 $SADM_LOG_DIR
    fi

    # If TMP Directory doesn't exist, create it.
    if [ ! -d "$SADM_TMP_DIR" ]
        then mkdir -p $SADM_TMP_DIR
             chmod 1777 $SADM_TMP_DIR
    fi

    # If LIB Directory doesn't exist, create it.
    if [ ! -d "$SADM_LIB_DIR" ]
        then mkdir -p $SADM_LIB_DIR
             chmod 2775 $SADM_LIB_DIR
    fi

    # If Custom Configuration Directory doesn't exist, create it.
    if [ ! -d "$SADM_CFG_DIR" ]
        then mkdir -p $SADM_CFG_DIR
             chmod 2775 $SADM_CFG_DIR
    fi

    # If System Startup/Shutdown Script Directory doesn't exist, create it.
    if [ ! -d "$SADM_SYS_DIR" ]
        then mkdir -p $SADM_SYS_DIR
             chmod 2775 $SADM_SYS_DIR
    fi

    # If Data Directory doesn't exist, create it.
    if [ ! -d "$SADM_DAT_DIR" ]
        then mkdir -p $SADM_DAT_DIR
             chmod 2775 $SADM_DAT_DIR
    fi

    # If Package Directory doesn't exist, create it.
    if [ ! -d "$SADM_PKG_DIR" ]
        then mkdir -p $SADM_PKG_DIR
             chmod 2775 $SADM_PKG_DIR
    fi

    # If Sysadmin Web Site Directory doesn't exist, create it.
    if [ ! -d "$SADM_WWW_DIR" ]
        then mkdir -p $SADM_WWW_DIR
             chmod 2775 $SADM_WWW_DIR
    fi

    # If Sysadmin Web Data Directory doesn't exist, create it.
    if [ ! -d "$SADM_WWW_DAT_DIR" ]
        then mkdir -p $SADM_WWW_DAT_DIR
             chmod 2775 $SADM_WWW_DAT_DIR  
    fi
    
    # If Sysadmin Web Data Directory doesn't exist, create it.
    if [ ! -d "$SADM_WWW_HTML_DIR" ]
        then mkdir -p $SADM_WWW_HTML_DIR
             chmod 2775 $SADM_WWW_HTML_DIR  
    fi

    # If NMON Directory doesn't exist, create it.
    if [ ! -d "$SADM_NMON_DIR" ]
        then mkdir -p $SADM_NMON_DIR
             chmod 2775 $SADM_NMON_DIR
    fi

    # If Disaster Recovery Information Directory doesn't exist, create it.
    if [ ! -d "$SADM_DR_DIR" ]
        then mkdir -p $SADM_DR_DIR
             chmod 2775 $SADM_DR_DIR
    fi

    # If Performance Server Data Directory doesn't exist, create it.
    if [ ! -d "$SADM_SAR_DIR" ]
        then mkdir -p $SADM_SAR_DIR
             chmod 2775 $SADM_SAR_DIR
    fi

    # If Return Code History Directory doesn't exist, create it.
    if [ ! -d "$SADM_RCH_DIR" ]
        then mkdir -p $SADM_RCH_DIR
             chmod 2775 $SADM_RCH_DIR
    fi

    # If LOG File doesn't exist, Create it and Make it writable 
    if [ ! -e "$SADM_LOG" ]
        then touch $SADM_LOG
             chmod 664 $SADM_LOG
    fi

    # If Return Code History Log doesn't exist, Create it and Make sure it have right permission
    if [ ! -e "$SADM_RCHLOG" ]
        then touch $SADM_RCHLOG
             chmod 664 $SADM_RCHLOG
    fi

    # If PID FIle exist and User want to run only 1 copy of the script - Abort Script
    if [ -e "${SADM_PID_FILE}" ] && [ "$SADM_MULTIPLE_EXEC" = "N" ]
       then sadm_logger "Script is already running ... "
            sadm_logger "PID File ${SADM_PID_FILE} exist ..."
            sadm_logger "Will not launch a second copy of this script"
            exit 1
       else echo "$TPID" > $SADM_PID_FILE
    fi

    # Feed the Return Code History File stating the script is started
    SADM_STIME=`date "+%C%y.%m.%d %H:%M:%S"` ; export SADM_STIME
    echo "$(sadm_hostname) $SADM_STIME .......... ........ ........ $SADM_INST 2" >>$SADM_RCHLOG
    
    # Write Starting Info in the Log
    sadm_logger "${SADM_DASH}"
    sadm_logger "Starting ${SADM_PN} - Version ${SADM_VER} on $(sadm_hostname)"
    sadm_logger "$(sadm_ostype) $(sadm_osname) $(sadm_osversion) $(sadm_oscodename)"
    sadm_logger "${SADM_DASH}"
    sadm_logger " "
    return 0 
}




# --------------------------------------------------------------------------------------------------
#                                  SADM END OF PROCESS FUNCTION
# What this function do.
#   1) If Exit Code is not zero, change it to 1.
#   2) Get Actual Time and Calculate the Execution Time.
#   3) Writing the Script Footer in the Log (Script Return code, Execution Time, ...)
#   4) Update the RCH File (Start/End/Elapse Time and the Result Code)
#   5) Trim The RCH File Based on User choice in sadmin.cfg
#   6) Write to Log the user mail alerting type choose by user (sadmin.cfg)
#   7) Trim the Log based on user selection in sadmin.cfg
#   8) Send Email to sysadmin (if user selected that option in sadmin.cfg)
#   9) Delete the PID File of the script (SADM_PID_FILE)
#  10) Delete the Uers 3 TMP Files (SADM_TMP_FILE1, SADM_TMP_FILE2, SADM_TMP_FILE3)
# --------------------------------------------------------------------------------------------------
#
sadm_stop() {    
    SADM_EXIT_CODE=$1                                                   # Save Exit Code Received
    if [ "$SADM_EXIT_CODE" -ne 0 ] ; then SADM_EXIT_CODE=1 ; fi         # Making Sure code is 1 or 0
 
    # Start Writing Log Footer
    sadm_logger " "                                                     # Blank Line
    sadm_logger "${SADM_DASH}"                                          # Dash Line
    sadm_logger "Script return code is $SADM_EXIT_CODE"                 # Final Exit Code to log
    
    # Get End time and Calculate Elapse Time
    sadm_end_time=`date "+%C%y.%m.%d %H:%M:%S"` ; export sadm_end_time  # Get & Format End Time
    sadm_elapse=`sadm_elapse_time "$sadm_end_time" "$SADM_STIME"`       # Get Elapse - End-Start
    sadm_logger "Script execution time is $sadm_elapse"                 # Log the Elapse Time

    # Update the [R]eturn [C]ode [H]istory File
    RCHLINE="$(sadm_hostname) $SADM_STIME $sadm_end_time"               # Format Part1 of RCH File
    RCHLINE="$RCHLINE $sadm_elapse $SADM_INST $SADM_EXIT_CODE"          # Format Part2 of RCH File
    echo "$RCHLINE" >>$SADM_RCHLOG                                      # Append Line to  RCH File
    
    # Trim the RCH File based on Variable $SADM_MAX_RCLINE define in sadmin.cfg
    sadm_logger "Trimming $SADM_RCHLOG to ${SADM_MAX_RCLINE} lines."    # Advise user of trimm value
    tail -${SADM_MAX_RCLINE} $SADM_RCHLOG > $SADM_RCHLOG.$$             # Trim File in Temp file
    rm -f $SADM_RCHLOG > /dev/null                                      # Remove Original RCH file
    mv $SADM_RCHLOG.$$ $SADM_RCHLOG                                     # Move Tmp File to RCH File
    chmod 664 $SADM_RCHLOG                                              # Make permission to 664

    # Write email choice in the log footer
    if [ "$SADM_MAIL" = "" ] ; then SADM_MAIL_TYPE=4 ; fi               # Mail not Install - no Mail
    case $SADM_MAIL_TYPE in
      0)  sadm_logger "User requested no mail when script end (Fail or Success)"
          ;;
      1)  if [ "$SADM_EXIT_CODE" -ne 0 ]
             then sadm_logger "User requested mail only if script fail - Will send mail"
             else sadm_logger "User requested mail only if script fail - Will not send mail"
          fi
          ;;
      2)  if [ "$SADM_EXIT_CODE" -eq 0 ]
             then sadm_logger "User requested mail only on Success of script - Will send mail"
             else sadm_logger "User requested mail only on Success of script - Will not send mail"
          fi 
          ;;
      3)  sadm_logger "User requested mail either Success or Error of script - Will send mail"
          ;;
      4)  sadm_logger "No Mail can be send until the mail command is install"
          sadm_logger "On CentOS/Red Hat/Fedora - enter command \'yum -y mailx\'"
          ;;
      *)  sadm_logger "The SADM_MAIL_TYPE is not set properly - Should be between 0 and 3"
          sadm_logger "It is now set to $SADM_MAIL_TYPE"
          ;;
    esac

    sadm_logger "Trimming $SADM_LOG to ${SADM_MAX_LOGLINE} lines."      # Inform user trimming value
    sadm_logger "`date` - End of ${SADM_PN}"                            # Write End Time To Log
    sadm_logger "${SADM_DASH}"                                          # Write 80 Dash Line
    sadm_logger " "                                                     # Blank Line
    
    # Maintain Script log at a reasonnable size specified in ${SADM_MAX_LOGLINE}
    tail -${SADM_MAX_LOGLINE} $SADM_LOG > $SADM_LOG.$$                  # Trim file to Desired Nb.
    rm -f $SADM_LOG > /dev/null                                         # Remove Original Log
    mv $SADM_LOG.$$ $SADM_LOG                                           # Move Tmp to LOG
    chmod 664 $SADM_$SADM_LOG                                           # Make permission to 664
       
    
    # Inform UnixAdmin By Email based on his seected choice
    case $SADM_MAIL_TYPE in
      1)  if [ "$SADM_EXIT_CODE" -ne 0 ] && [ "$SADM_MAIL" != "" ]      # Mail On Error Only
             then wsub="SADM : ERROR of $SADM_PN on $(sadm_hostname)"   # Format Mail Subject
                  cat $SADM_LOG | $SADM_MAIL -s "$wsub" $SADM_MAIL_ADDR # Send Email to SysAdmin
          fi
          ;;
      2)  if [ "$SADM_EXIT_CODE" -eq 0 ] && [ "$SADM_MAIL" != "" ]      # Mail On Success Only
             then wsub="SADM : SUCCESS of $SADM_PN on $(sadm_hostname)" # Format Mail Subject
                  cat $SADM_LOG | $SADM_MAIL -s "$wsub" $SADM_MAIL_ADDR # Send Email to SysAdmin
          fi 
          ;;
      3)  if [ "$SADM_EXIT_CODE" -eq 0 ] && [ "$SADM_MAIL" != "" ]      # Always mail
              then wsub="SADM : SUCCESS of $SADM_PN on $(sadm_hostname)" # Format Mail Subject
              else wsub="SADM : ERROR of $SADM_PN on $(sadm_hostname)"  # Format Mail Subject
          fi
          cat $SADM_LOG | $SADM_MAIL -s "$wsub" $SADM_MAIL_ADDR         # Send Email to SysAdmin
          ;;
    esac
    
    # Delete Temporary files used
    if [ -e "$SADM_PID_FILE"  ] ; then rm -f $SADM_PID_FILE  >/dev/null 2>&1 ; fi
    if [ -e "$SADM_TMP_FILE1" ] ; then rm -f $SADM_TMP_FILE1 >/dev/null 2>&1 ; fi
    if [ -e "$SADM_TMP_FILE2" ] ; then rm -f $SADM_TMP_FILE2 >/dev/null 2>&1 ; fi
    if [ -e "$SADM_TMP_FILE3" ] ; then rm -f $SADM_TMP_FILE3 >/dev/null 2>&1 ; fi
    return $SADM_EXIT_CODE
}


# --------------------------------------------------------------------------------------------------
#                                THING TO DO WHEN FIRST CALLED
# --------------------------------------------------------------------------------------------------
#
    # Make sure ALL basic requirement are met - If not then exit 1
    sadm_check_requirements                                             # Check Lib Requirements
    if [ $? -ne 0 ] ; then exit 1 ; fi                                  # If Requirement are not met
    
    # Load SADMIN Configuration file
    sadm_load_sadmin_config_file                                        # Load SADM cfg file
