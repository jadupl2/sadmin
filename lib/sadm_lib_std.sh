#!/usr/bin/env sh
#===================================================================================================
#  Author:    Jacques Duplessis
#  Title      sadm_lib_std.sh
#  Date:      August 2015
#  Synopsis:  SADMIN  Shell Script Main Library
#  
# --------------------------------------------------------------------------------------------------
#set -x
# Description
# This file is not a stand-alone shell script; it provides functions to your scripts that source it.
# --------------------------------------------------------------------------------------------------
#
#===================================================================================================
trap 'exit 0' 2   # INTERCEPTE LE ^C    

#set -x


# --------------------------------------------------------------------------------------------------
#                             V A R I A B L E S      D E F I N I T I O N S
# --------------------------------------------------------------------------------------------------
#
HOSTNAME=`hostname -s`                          ; export HOSTNAME       # Current Host name
SADM_DASH=`printf %80s |tr " " "="`             ; export SADM_DASH      # 80 equals sign line
SADM_TEN_DASH=`printf %10s |tr " " "-"`         ; export SADM_TEN_DASH  # 10 dashes line
SADM_VAR1=""                                    ; export SADM_VAR1      # Temp Dummy Variable
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
SADM_PERF_DIR="$SADM_DAT_DIR/sar"               ; export SADM_PERF_DIR  # System Activty Report Dir
SADM_RCH_DIR="$SADM_DAT_DIR/rch"                ; export SADM_RCH_DIR   # Result Code History Dir
#
# SADMIN WEB SITE DIRECTORY DEFINITION
SADM_WWW_DIR="$SADM_BASE_DIR/www"               ; export SADM_WWW_DIR   # sadmin Web Site Directory
SADM_WWW_DIR_DAT="$SADM_BASE_DIR/www/dat"       ; export SADM_WWW_DIR_DAT # sadmin server Data Dir.
#
#
# SADM CONFIG FILE, LOGS, AND TEMP FILES USER CAN USE
SADM_CFG_FILE="$SADM_CFG_DIR/sadmin.cfg"             ; export SADM_CFG_FILE  # Config file name
SADM_TMP_FILE1="${SADM_TMP_DIR}/${SADM_INST}_1.$$"   ; export SADM_TMP_FILE1 # Temp Script Tmp File1 
SADM_TMP_FILE2="${SADM_TMP_DIR}/${SADM_INST}_2.$$"   ; export SADM_TMP_FILE2 # Temp Script Tmp File2
SADM_TMP_FILE3="${SADM_TMP_DIR}/${SADM_INST}_3.$$"   ; export SADM_TMP_FILE3 # Temp Script Tmp File3
LOG="${SADM_LOG_DIR}/${HOSTNAME}_${SADM_INST}.log"   ; export LOG            # Output LOG filename
RCLOG="${SADM_RCH_DIR}/${HOSTNAME}_${SADM_INST}.rch" ; export RCLOG          # Return Code History
#
# COMMANDS PATH REQUIRE TO RUN SADM
SADM_LSB_RELEASE=""                             ; export SADM_LSB_RELEASE # Command lsb_release Path
SADM_DMIDECODE=""                               ; export SADM_DMIDECODE # Command dmidecode Path
SADM_BC=""                                      ; export SADM_BC        # Command bc (Do Some Math)
SADM_FDISK=""                                   ; export SADM_FDISK     # fdisk (Read Disk Capacity)
SADM_WHICH=""                                   ; export SADM_WHICH     # which Path - Required
SADM_PRTCONF=""                                 ; export SADM_PRTCONF   # prtconf  Path - Required
SADM_PERL=""                                    ; export SADM_PERL      # perl Path (for epoch time)
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
#                         WRITE INFORMATION TO THE LOG
# --------------------------------------------------------------------------------------------------
#
sadm_logger() {
    SADM_MSG="$(date "+%C%y.%m.%d %H:%M:%S") - $@"
    case "$SADM_LOG_TYPE" in
        s|S) printf "%-s\n" "$SADM_MSG"
             ;; 
        l|L) printf "%-s\n" "$SADM_MSG" >> $LOG
             ;; 
        b|B) printf "%-s\n" "$SADM_MSG"
             printf "%-s\n" "$SADM_MSG" >> $LOG
             ;;
        *)   printf "Wrong value in \$SADM_LOG_TYPE ($SADM_LOG_TYPE) - Please set it correctly\n"
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
# THIS FUNCTION MAKE SURE THAT ALL SADM SHELL LIBRARIES (LIB/SADM_*) REQUIREMENTS ARE MET BEFORE USE
# IF THE REQUIRENMENT ARE NOT MET, THEN THE SCRIPT WILL ABORT INFORMING USER TO CORRECT SITUATION
# --------------------------------------------------------------------------------------------------
#
sadm_check_command_availibility() {
    SADM_CMD=$1                                                         # Save Parameter received
    if ${SADM_WHICH} ${SADM_CMD} >/dev/null 2>&1                        # command is found ?
        then SADM_VAR1=`${SADM_WHICH} ${SADM_CMD}`                      # Store Path of command
             return 0
        else SADM_VAR1=""                                               # Clear Path of command
             sadm_logger " "                                            # Inform User 
             sadm_logger "WARNING : Missing Requirement "
             sadm_logger "The ${SADM_CMD} command is not available on the system"
             #sadm_logger "Would you like me to install it for you (Y/N) ? "
             #read sadm_answer                                           # Read User answer
             #case "$sadm_answer" in                                     # Test Answer
             #   Y|y ) sadm_answer="Y"                                   # Make Answer Uppercase
             #         break                                             # Break of the loop
             #         ;;
             #   n|N ) sadm_answer="N"                                   # Make Answer Uppercase
             #         break                                             # Break of the loop
             #         ;;
             #     * ) ;;                                                # Other options stay in the loop
             #esac
             #
             #sadm_logger "ERROR : "                                       # That we will Abort
             #sadm_logger "The command $SADM_CMD is not present on this system."
             sadm_logger "You need to install it before we can used some functions of the SADMIN Library Tools"
             #sadm_logger "Run this command to correct the situation : "
             #if [ "$SADM_CMD" = "lscpu" ]
             #then sadm_logger "  - On RHEL, CentOS or Fedora run 'yum -y install util-linux-ng'"
             #     sadm_logger "  - On Ubuntu/Debian like distribution 'apt-get install util-linux'"
             #else sadm_logger "  - On RHEL, CentOS or Fedora run 'yum install redhat-lsb-core dmidecode'"
             #     sadm_logger "  - On Ubuntu/Debian like distribution 'apt-get install lsb-core dmidecode'"
             #fi
             sadm_logger " "
             sadm_logger "Once the software is installed, rerun this script"
             #sadm_logger "Script Aborted"
             #exit 1                                                     # Back to shell wirh error
    fi  
    return 1
}

# --------------------------------------------------------------------------------------------------
# THIS FUNCTION MAKE SURE THAT ALL SADM SHELL LIBRARIES (LIB/SADM_*) REQUIREMENTS ARE MET BEFORE USE
# IF THE REQUIRENMENT ARE NOT MET, THEN THE SCRIPT WILL ABORT INFORMING USER TO CORRECT SITUATION
# --------------------------------------------------------------------------------------------------
#
sadm_check_requirements() {
                           
# SYSTAT MUST BE INSTALLED _ nOT DEFAUT ON FEDORA 23
                           
                           
    # which command is needed to determine presence of command - Return Error if not found
    if which which >/dev/null 2>&1                                        # Try the command which 
        then SADM_WHICH=`which which`  ; export SADM_WHICH                # Save the Path of Which
#        then SADM_WHICH=`which --skip-alias which`  ; export SADM_WHICH # Save the Path of Which
        else sadm_logger "Error: Command 'which' isn't available - Install it and rerun this script"
             return 1                                                   # Return Error to Caller
    fi
    
    if [ "$(sadm_os_type)" = "LINUX" ]                                  # Under Linux
       then sadm_check_command_availibility lsb_release                 # lsb_release cmd available?
            SADM_LSB_RELEASE=$SADM_VAR1                                 # Save Command Path
            sadm_check_command_availibility dmidecode                   # dmidecode cmd available?
            SADM_DMIDECODE=$SADM_VAR1                                   # Save Command Path
            sadm_check_command_availibility fdisk                       # FDISK cmd available?
            SADM_FDISK=$SADM_VAR1                                       # Save Command Path
            sadm_check_command_availibility bc                          # bc cmd available?
            SADM_BC=$SADM_VAR1                                          # Save Command Path
       else if [ "$(sadm_os_type)" = "AIX" ]
               then sadm_check_command_availibility bc                  # bc cmd available?
                    SADM_BC=$SADM_VAR1                                  # Save Command Path
                    sadm_check_command_availibility prtconf             # prtconf cmd available?
                    SADM_PRTCONF=$SADM_VAR1                             # Save Command Path
            fi
    fi
    
    # Common Requirements
    sadm_check_command_availibility perl                                # perl needed (epoch time)
    SADM_PERL=$SADM_VAR1                                                # Save perl path
    return 0
}




# --------------------------------------------------------------------------------------------------
#                        G E T    C U R R E N T    E P O C H   T I M E           
# --------------------------------------------------------------------------------------------------
sadm_epoch_time() {
    sadm_epoch_time=`${SADM_PERL} -e 'print time'`
    echo "$sadm_epoch_time"
}



# --------------------------------------------------------------------------------------------------
#    C O N V E R T   E P O C H   T I M E    R E C E I V E   T O    D A T E  (YYYY.MM.DD HH:MM:SS)
# --------------------------------------------------------------------------------------------------
sadm_epoch_to_date() {

    if [ $# -ne 1 ]                                                     # Should have rcv 1 Param
        then sadm_logger "No Parameter received by $FUNCNAME function"
             sadm_logger "Please correct your script please - Script Aborted"
             sadm_stop 1                                                # Prepare to exit gracefully
             exit 1                                                     # Terminate the script
    fi
    wepoch=$1                                                           # Save Epoch Time Receivec

    # Verify if parameter received is all numeric - If not advice user and exit
    echo $wepoch | grep [^0-9] > /dev/null 2>&1                         # Grep for Number
    if [ "$?" -eq "0" ]                                                 # Not All Number
        then sadm_logger "Incorrect parameter received by \"sadm_epoch_to_date\" function"
             sadm_logger "Should have received an epoch time and it received ($wepoch) instead"
             sadm_logger "Please correct your script please - Script Aborted"
             sadm_stop 1                                                # Prepare to exit gracefully
             exit 1                                                     # Terminate the script
    fi
    
    # Format the Converted Epoch time obtain from Perl 
    WDATE=`$SADM_PERL -e "print scalar(localtime($wepoch))"`            # Convert Epoch to Date
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

    sadm_epoch_to_date="${YYYY}.${MM}.${DD} ${HMS}"                     # Combine Data to form Date
    echo "$sadm_epoch_to_date"                                          # Return converted date
}


# --------------------------------------------------------------------------------------------------
#    C O N V E R T   D A T E  (YYYY.MM.DD HH:MM:SS)  R E C E I V E    T O    E P O C H   T I M E  
# --------------------------------------------------------------------------------------------------
sadm_date_to_epoch() {

    if [ $# -ne 1 ]                                                     # Should have rcv 1 Param
        then sadm_logger "No Parameter received by $FUNCNAME function"
             sadm_logger "Please correct your script please - Script Aborted"
             sadm_stop 1                                                # Prepare to exit gracefully
             exit 1                                                     # Terminate the script
    fi
    WDATE=$1                                                            # Save Received Date

    YYYY=`echo $WDATE | awk -F. '{ print $1 }'`
    MTH=`echo   $WDATE | awk -F. '{ print $2 }'`
    let MTH="$MTH -1"
    DD=`echo   $WDATE | awk -F. '{ print $3 }' | awk '{ print $1 }'`
    HH=`echo   $WDATE | awk '{ print $2 }' | awk -F: '{ print $1 }'`
    MM=`echo   $WDATE | awk '{ print $2 }' | awk -F: '{ print $2 }'`
    SS=`echo   $WDATE | awk '{ print $2 }' | awk -F: '{ print $3 }'`
    #echo "perl -e \"use Time::Local; print timelocal(${SS},${MM},${HH},${DD},${MTH},${YYYY})\""
    sadm_date_to_epoch=`perl -e "use Time::Local; print timelocal(${SS},${MM},${HH},${DD},${MTH},${YYYY})"`
    #sadm_date_to_epoch=`perl -e "use Time::Local; print timelocal($SS,$MM,$HH,$DD,$MTH,$YYYY)"`
    echo "$sadm_date_to_epoch"
}





# --------------------------------------------------------------------------------------------------
#                           THIS FUNCTION DETERMINE THE OS VERSION NUMBER 
# --------------------------------------------------------------------------------------------------
sadm_os_version() {
    sadm_os_version="0.0"                                               # Default Value
    case "$(sadm_os_type)" in
        "LINUX") sadm_os_version=`$SADM_LSB_RELEASE -sr`                # Ise lsb_release to Get Ver
                 ;; 
        "AIX")   #VER1=`oslevel -r | awk -F\- '{ print $1 }' | cut -c1-1`    # Get Major Version No.
                 #VER2=`oslevel -r | awk -F\- '{ print $1 }' | cut -c2-2`    # Get Minor Version No
                 #VER3=`oslevel -r | awk -F\- '{ print $2 }'`                # Get TTL Level
                 #sadm_os_version="${VER1}.${VER2}"                          # Make OS Version Uniform
                 sadm_os_version="`uname -v`.`uname -r`"                     # Make OS Version Uniform
                 ;;
    esac
    echo "$sadm_os_version"
}

# --------------------------------------------------------------------------------------------------
#                            RETURN THE OS MAJOR VERSION
# --------------------------------------------------------------------------------------------------
sadm_os_major_version() {
    case "$(sadm_os_type)" in
        "LINUX") sadm_os_major_version=`echo $(sadm_os_version) | awk -F. '{ print $1 }'| tr -d ' '`
                 ;;
        "AIX")   sadm_os_major_version=`uname -v`
                 ;;
    esac
    echo "$sadm_os_major_version"
}

# --------------------------------------------------------------------------------------------------
#                RETURN THE OS TYPE (LINUX, AIX) -- ALWAYS RETURNED IN UPPERCASE
# --------------------------------------------------------------------------------------------------
sadm_os_type() {
    sadm_os_type=`uname -s | tr '[:lower:]' '[:upper:]'`                # Get OS Name (AIX or LINUX)
    echo "$sadm_os_type"
}

#
# --------------------------------------------------------------------------------------------------
#                             RETURN THE OS PROJECT CODE NAME
# --------------------------------------------------------------------------------------------------
sadm_os_code_name() {
    if [ "$(sadm_os_type)" = "LINUX" ] ; then sadm_os_code_name=`$SADM_LSB_RELEASE -sc`; fi
    if [ "$(sadm_os_type)" = "AIX" ]   ; then sadm_os_code_name="IBM_AIX" ; fi
    echo "$sadm_os_code_name"
}


# --------------------------------------------------------------------------------------------------
#                   RETURN THE OS  NAME (ALWAYS RETURNED IN UPPERCASE)
# --------------------------------------------------------------------------------------------------
sadm_os_name() {
    if [ "$(sadm_os_type)" = "LINUX" ]
        then sadm_os_name=`$SADM_LSB_RELEASE -si | tr '[:lower:]' '[:upper:]'`
             if [ "$sadm_os_name" = "REDHATENTERPRISESERVER" ] ; then sadm_os_name="REDHAT" ; fi
    fi 
    if [ "$(sadm_os_type)" = "AIX" ]   ; then sadm_os_name="AIX" ; fi
    echo "$sadm_os_name"
}


# --------------------------------------------------------------------------------------------------
#                                 RETURN THE HOSTNAME (SHORT)
# --------------------------------------------------------------------------------------------------
sadm_hostname() {
    if [ "$(sadm_os_type)" = "LINUX" ]                                  # Under Linux
        then sadm_hostname=`hostname -s`                                # Get rid of domain name
    fi
    if [ "$(sadm_os_type)" = "AIX" ]                                    # Under AIX
        then sadm_hostname=`hostname`                                   # Get HostName
    fi
    echo "$sadm_hostname"
}




# --------------------------------------------------------------------------------------------------
#                                 RETURN THE DOMAINNAME (SHORT)
# --------------------------------------------------------------------------------------------------
sadm_domainname() {
    case "$(sadm_os_type)" in
        "LINUX")    sadm_domainname=`hostname -d`
                    ;;
        "AIX")      sadm_domainname=`namerslv -s | grep domain | awk '{ print $2 }'`
                    ;;
    esac
    echo "$sadm_domainname"
}




# --------------------------------------------------------------------------------------------------
#                              RETURN THE IP OF THE CURRENT HOSTNAME
# --------------------------------------------------------------------------------------------------
sadm_host_ip() {
    case "$(sadm_os_type)" in
        "LINUX") sadm_host_ip=`getent hosts $(sadm_hostname).$(sadm_domainname) |awk '{ print $1 }' |head -1`
                 ;;
        "AIX")   sadm_host_ip=`host $(sadm_hostname).$(sadm_domainname) | awk '{ print $3 }'` 
                 ;;
    esac    
    echo "$sadm_host_ip"
}



# --------------------------------------------------------------------------------------------------
#                     Return if running 32 or 64 Bits Kernel version
# --------------------------------------------------------------------------------------------------
sadm_kernel_bitmode() { 
    case "$(sadm_os_type)" in
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
    sadm_kernel_version=`uname -r`
    echo "$sadm_kernel_version"
}


# --------------------------------------------------------------------------------------------------
#            LOAD SADMIN CONFIGURATION FILE AND SET GLOBAL VARIABLES ACCORDINGLY
# --------------------------------------------------------------------------------------------------
#
sadm_load_sadmin_config_file() {
    if [ ! -f "$SADM_CFG_FILE" ]
       then echo "# SADMIN - Configuration file - Created on `date`"             > $SADM_CFG_FILE
            echo "#"                                                            >> $SADM_CFG_FILE
            echo "# Email when error and log report are sent"                   >> $SADM_CFG_FILE
            echo "SADM_MAIL_ADDR = root@localhost"                              >> $SADM_CFG_FILE        
            echo "#"                                                            >> $SADM_CFG_FILE
            echo "#"                                                            >> $SADM_CFG_FILE
            echo "# Put your Company name here"                                 >> $SADM_CFG_FILE
            echo "SADM_CIE_NAME = Company_Name"                                 >> $SADM_CFG_FILE
            echo "#"                                                            >> $SADM_CFG_FILE
            echo "#"                                                            >> $SADM_CFG_FILE
            echo "# Default Option for sending email after a script is ended"   >> $SADM_CFG_FILE
            echo "# Option Can be overridden by changing SADM_MAIL_TYPE in Script header"  >> $SADM_CFG_FILE
            echo "# 0=No Mail Sent    1=On Error Only    2=On Success Only    3=Always send email" >> $SADM_CFG_FILE
            echo "SADM_MAIL_TYPE = 3"                                           >> $SADM_CFG_FILE
            echo "#"                                                            >> $SADM_CFG_FILE
            echo "#"                                                            >> $SADM_CFG_FILE
            echo "# sadmin fully qualified server name"                         >> $SADM_CFG_FILE
            echo "SADM_SERVER = sadmin"                                         >> $SADM_CFG_FILE
            echo "#"                                                            >> $SADM_CFG_FILE
       else SADM_MAIL_ADDR=`grep -i "^SADM_MAIL_ADDR" $SADM_CFG_FILE |awk -F= '{print $2 }' |tr -d ' '`
            SADM_CIE_NAME=`grep  -i "^SADM_CIE_NAME"  $SADM_CFG_FILE |awk -F= '{print $2 }' |sed -e 's/^[ \t]*//'`
            SADM_MAIL_TYPE=`grep -i "^SADM_MAIL_TYPE" $SADM_CFG_FILE |awk -F= '{print $2 }' |tr -d ' '`
            SADM_SERVER=`grep -i "^SADM_SERVER"       $SADM_CFG_FILE |awk -F= '{print $2 }' |tr -d ' '`
    fi
    export SADM_MAIL_ADDR SADM_CIE_NAME SADM_MAIL_TYPE SADM_SERVER
}


# --------------------------------------------------------------------------------------------------
#                   SADM INITIALIZE FUNCTION - EXECUTE BEFORE DOING ANYTHING
# --------------------------------------------------------------------------------------------------
#
sadm_start() { 
    # If log Directory doesn't exist, create it.
    if [ ! -d "$SADM_LOG_DIR" ]  ; then mkdir -p $SADM_LOG_DIR   ; chmod 2775 $SADM_LOG_DIR  ; export SADM_LOG_DIR ; fi

    # If TMP Directory doesn't exist, create it.
    if [ ! -d "$SADM_TMP_DIR" ]  ; then mkdir -p $SADM_TMP_DIR   ; chmod 1777 $SADM_TMP_DIR  ; export SADM_TMP_DIR ; fi

    # If LIB Directory doesn't exist, create it.
    if [ ! -d "$SADM_LIB_DIR" ]  ; then mkdir -p $SADM_LIB_DIR   ; chmod 2775 $SADM_LIB_DIR  ; export SADM_LIB_DIR ; fi

    # If Custom Configuration Directory doesn't exist, create it.
    if [ ! -d "$SADM_CFG_DIR" ]  ; then mkdir -p $SADM_CFG_DIR   ; chmod 2775 $SADM_CFG_DIR  ; export SADM_CFG_DIR ; fi

    # If System Configuration Directory doesn't exist, create it.
    if [ ! -d "$SADM_SYS_DIR" ]  ; then mkdir -p $SADM_SYS_DIR   ; chmod 2775 $SADM_SYS_DIR  ; export SADM_SYS_DIR ; fi

    # If Data Directory doesn't exist, create it.
    if [ ! -d "$SADM_DAT_DIR" ]  ; then mkdir -p $SADM_DAT_DIR   ; chmod 2775 $SADM_DAT_DIR  ; export SADM_DAT_DIR ; fi

    # If Package Directory doesn't exist, create it.
    if [ ! -d "$SADM_PKG_DIR" ]  ; then mkdir -p $SADM_PKG_DIR   ; chmod 2775 $SADM_PKG_DIR  ; export SADM_PKG_DIR ; fi

    # If Sysadmin Web Site Directory doesn't exist, create it.
    if [ ! -d "$SADM_WWW_DIR" ]  ; then mkdir -p $SADM_WWW_DIR   ; chmod 2775 $SADM_WWW_DIR  ; export SADM_WWW_DIR ; fi

    # If Sysadmin Web Data Directory doesn't exist, create it.
    if [ ! -d "$SADM_WWW_DIR_DAT" ]
        then mkdir -p $SADM_WWW_DIR_DAT ; chmod 2775 $SADM_WWW_DIR_DAT  ; export SADM_WWW_DIR_DAT
    fi

    # If NMON Directory doesn't exist, create it.
    if [ ! -d "$SADM_NMON_DIR" ]  ; then mkdir -p $SADM_NMON_DIR ; chmod 2775 $SADM_NMON_DIR ; export SADM_NMON_DIR ; fi

    # If Disaster Recovery Information Directory doesn't exist, create it.
    if [ ! -d "$SADM_DR_DIR" ]  ; then mkdir -p $SADM_DR_DIR ; chmod 2775 $SADM_DR_DIR    ; export SADM_DR_DIR ; fi

    # If Performance Server Data Directory doesn't exist, create it.
    if [ ! -d "$SADM_PERF_DIR" ]  ; then mkdir -p $SADM_PERF_DIR ; chmod 2775 $SADM_PERF_DIR ; export SADM_PERF_DIR ; fi

    # If Return Code History Directory doesn't exist, create it.
    if [ ! -d "$SADM_RCH_DIR" ]  ; then mkdir -p $SADM_RCH_DIR ; chmod 2775 $SADM_RCH_DIR ; export SADM_RCH_DIR ; fi

    # If LOG directory doesn't exist, Create it and Make it writable and that it is empty on startup
    if [ ! -e "$LOG" ]      ; then touch $LOG  ;chmod 664 $LOG  ;fi
    > $LOG

    # If Return Log doesn't exist, Create it and Make sure it have right permission
    if [ ! -e "$RCLOG" ]    ; then touch $RCLOG ;chmod 664 $RCLOG ; export RCLOG ;fi

    if [ -e "${SADM_TMP_DIR}/${SADM_INST}" ]
       then sadm_logger "Script is already running ... "
            sadm_logger "PID File ${SADM_TMP_DIR}/${SADM_INST} exist ..."
            sadm_logger "Will not launch a second copy of this script"
            exit 1
       else echo "$TPID" > ${SADM_TMP_DIR}/${SADM_INST}.pid
    fi

    # Write Starting Info in the Log
    sadm_logger "${SADM_DASH}"
    sadm_logger "`date`"
    sadm_logger "Starting ${SADM_PN} version ${SADM_VER} on $(sadm_hostname)"
    sadm_logger "$(sadm_os_type) $(sadm_os_name) $(sadm_os_version) $(sadm_os_code_name)"
    sadm_logger "${SADM_DASH}"
    sadm_logger " "


    # Record Date & Time the script is starting in the
    sadm_start_time=`date "+%C%y.%m.%d %H:%M:%S"` ; export sadm_start_time
    echo "$(sadm_hostname) ${sadm_start_time} ........ ${SADM_INST} 2" >>$RCLOG
}




# --------------------------------------------------------------------------------------------------
#                                  SADM END OF PROCESS FUNCTION
# --------------------------------------------------------------------------------------------------
#
sadm_stop() {    
    SADM_EXIT_CODE=$1
    if [ "$SADM_EXIT_CODE" -ne 0 ] ; then SADM_EXIT_CODE=1 ; fi             # Making Sure code is 1 or 0
 
    # Maintain Backup RC File log at a reasonnable size.
    sadm_logger " "
    sadm_logger "${SADM_DASH}"
    sadm_logger "Script return code is $SADM_EXIT_CODE"
    sadm_logger "Script took $SECONDS seconds to run"
    sadm_logger "====="
    
    # Check to make sure the mail command is install
    ADM_MAIL=`which mail >/dev/null 2>&1`
    if [ $? -eq 0 ]
        then ADM_MAIL=`which mail`
        else sadm_logger "Warning : The command 'mail' was not found"
             SADM_MAIL_TYPE=4
    fi
    export ADM_MAIL 
     
    # Write email choice in the log footer
    case $SADM_MAIL_TYPE in
        0)  sadm_logger "No mail is requested when script end - No Mail Sent"
            ;;
        1)  if [ "$SADM_EXIT_CODE" -ne 0 ]
               then sadm_logger "Mail is requested only on Error of the script - Mail Sent"
               else sadm_logger "Mail is requested only on Error of the script - No Mail Sent"
            fi
            ;;
        2)  if [ "$SADM_EXIT_CODE" -eq 0 ]
               then sadm_logger "Mail is requested only on Success of this script - Mail Sent"
               else sadm_logger "Mail is requested only on Success of this script - No Mail Sent"
            fi 
            ;;
        3)  sadm_logger "Mail is requested either Success or Error of this script - Mail Sent"
            ;;
        4)  sadm_logger "No Mail can be send until the mail command is install (yum -y mailx)"
            ;;
    esac
    
    # Update the Return Code File
    sadm_end_time=`date "+%H:%M:%S"`
    echo "$(sadm_hostname) ${sadm_start_time} ${sadm_end_time} $SADM_INST $SADM_EXIT_CODE" >>$RCLOG
    
    sadm_logger "====="
    sadm_logger "Trimming $RCLOG to ${SADM_MAX_RCLINE} lines."
    tail -${SADM_MAX_RCLINE} $RCLOG > $RCLOG.$$
    rm -f $RCLOG > /dev/null
    mv $RCLOG.$$ $RCLOG
    chmod 666 $RCLOG

    # Maintain Script log at a reasonnable size specified in ${SADM_MAX_LOGLINE}
    sadm_logger "Trimming $LOG to ${SADM_MAX_LOGLINE} lines."
    cat $LOG >> $LOG.$$
    tail -${SADM_MAX_LOGLINE} $LOG > $LOG.$$
    rm -f $LOG > /dev/null
    mv $LOG.$$ $LOG

    sadm_logger "====="
    sadm_logger "`date` end of ${SADM_PN}."
    sadm_logger "${SADM_DASH}"
   

    # Inform UnixAdmin By Email based on his slected choice
    case $SADM_MAIL_TYPE in
        1)  if [ "$SADM_EXIT_CODE" -ne 0 ]
               then cat $LOG | mail -s "SADM : ERROR of $SADM_PN on $(sadm_hostname)"  $SADM_MAIL_ADDR # On Error
            fi
            ;;
        2)  if [ "$SADM_EXIT_CODE" -eq 0 ]
               then cat $LOG | mail -s "SADM : SUCCESS of $SADM_PN on $(sadm_hostname)" $SADM_MAIL_ADDR # On Success
            fi 
            ;;
        3)  if [ "$SADM_EXIT_CODE" -eq 0 ]                                              # Always mail
                then cat $LOG | mail -s "SADM : SUCCESS of $SADM_PN on $(sadm_hostname)" $SADM_MAIL_ADDR
                else cat $LOG | mail -s "SADM : ERROR of $SADM_PN on $(sadm_hostname)"  $SADM_MAIL_ADDR
            fi
            ;;
    esac

    # Delete PID File
    rm -f  ${SADM_TMP_DIR}/${SADM_INST}.pid > /dev/null 2>&1

    # Delete Temproray files used
    rm -f  ${SADM_TMP_DIR}/${SADM_INST} > /dev/null 2>&1
    if [ -e "$SADM_TMP_FILE1" ] ; then rm -f $SADM_TMP_FILE1 >/dev/null 2>&1 ; fi
    if [ -e "$SADM_TMP_FILE2" ] ; then rm -f $SADM_TMP_FILE2 >/dev/null 2>&1 ; fi
    if [ -e "$SADM_TMP_FILE3" ] ; then rm -f $SADM_TMP_FILE3 >/dev/null 2>&1 ; fi

    return $SADM_EXIT_CODE
}


# --------------------------------------------------------------------------------------------------
#                                THING TO DO WHEN FIRST CALLED
# --------------------------------------------------------------------------------------------------
#
    
    # Make sure basic requirement are met - If not then exit 1
    sadm_check_requirements                                             # Check Lib Requirements
    if [ $? -ne 0 ] ; then exit 1 ; fi                                  # If Requirement are not met
    
    # Load SADMIN Configuration file
    sadm_load_sadmin_config_file                                        # Load SADM cfg file

    # Date Calculation Tool
    case "$(sadm_os_type)" in
        "LINUX")   EPOCH="${SADM_BASE_DIR}/bin/sadm_epoch"      
                   ;;
        "AIX")     EPOCH="${SADM_BASE_DIR}/bin/sadm_epoch_aix"      
                   ;;
    esac    
    if [ -f /etc/os-release ] && [ $(grep -i "^ID=" /etc/os-release |awk -F= '{ print $2 }') = "raspbian" ]
        then EPOCH="${SADM_BASE_DIR}/bin/sadm_epoch_arm" 
    fi        
    export EPOCH
    