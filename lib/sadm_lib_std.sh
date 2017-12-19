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
# CHANGE LOG
# 2.0 Create log file earlier to prevent error message - 18 Jan - J.Duplessis
# 2.1 Added Support for Linux Mint - April 2017 - J.D.
# 2.2 Minor Modifications concerning Trimming the Log File
# 2.3 July 2017 - Jacques Duplessis
#       - Cosmetic change (Use only 50 Dash line at start & end of script)
# V2.4 Added SADM_ELOG (Email Log) to store error message encounter to send to user if requested
#      Split Second line of log header into two lines/ Change Timming Line
# 2017_08_12 JDuplessis
#   V2.5 Print FQDN instead of hostname and SADM Lib Ver. in header of the log
# 2017_08_27 JDuplessis
#   V2.6 If Log not in Append Mode, then no need to Trim - Change Log footer message accordingly
# 2017_09_23 JDuplessis
#   V2.7 Add SQLite3 Dir & Name Plus Correct Typo Error in sadm_stop when testing for log trimming or not 
# 2017_09_29 JDuplessis
#   V2.8 Correct chown on ${SADMIN}/dat/net and Test creation and chown on www directories
#===================================================================================================
trap 'exit 0' 2                                                         # Intercepte The ^C    
#set -x

# --------------------------------------------------------------------------------------------------
#                             V A R I A B L E S      D E F I N I T I O N S
# --------------------------------------------------------------------------------------------------
#
HOSTNAME=`hostname -s`                      ; export HOSTNAME           # Current Host name
SADM_HOSTNAME=`hostname -s`                 ; export SADM_HOSTNAME      # Current Host name
SADM_DASH=`printf %80s |tr " " "="`         ; export SADM_DASH          # 80 equals sign line
SADM_FIFTY_DASH=`printf %50s |tr " " "="`   ; export SADM_FIFTY_DASH    # 50 equals sign line
SADM_80_DASH=`printf %80s |tr " " "="`      ; export SADM_80_DASH       # 80 equals sign line
SADM_TEN_DASH=`printf %10s |tr " " "-"`     ; export SADM_TEN_DASH      # 10 dashes line
SADM_TWENTY_DASH=`printf %20s |tr " " "-"`  ; export SADM_TWENTY_DASH   # 20 dashes line
SADM_VAR1=""                                ; export SADM_VAR1          # Temp Dummy Variable
SADM_STIME=""                               ; export SADM_STIME         # Script Start Time
SADM_DEBUG_LEVEL=0                          ; export SADM_DEBUG_LEVEL   # 0=NoDebug Higher=+Verbose
DELETE_PID="Y"                              ; export DELETE_PID         # Default Delete PID On Exit 
SADM_LIB_VER="2.8"                          ; export SADM_LIB_VER       # This Library Version
#
# SADMIN DIRECTORIES STRUCTURES DEFINITIONS
SADM_BASE_DIR=${SADMIN:="/sadmin"}          ; export SADM_BASE_DIR      # Script Root Base Dir.
SADM_BIN_DIR="$SADM_BASE_DIR/bin"           ; export SADM_BIN_DIR       # Script Root binary Dir.
SADM_TMP_DIR="$SADM_BASE_DIR/tmp"           ; export SADM_TMP_DIR       # Script Temp  directory
SADM_LIB_DIR="$SADM_BASE_DIR/lib"           ; export SADM_LIB_DIR       # Script Lib directory
SADM_LOG_DIR="$SADM_BASE_DIR/log"           ; export SADM_LOG_DIR       # Script log directory
SADM_CFG_DIR="$SADM_BASE_DIR/cfg"           ; export SADM_CFG_DIR       # Configuration Directory
SADM_SYS_DIR="$SADM_BASE_DIR/sys"           ; export SADM_SYS_DIR       # System related scripts
SADM_DAT_DIR="$SADM_BASE_DIR/dat"           ; export SADM_DAT_DIR       # Data directory
SADM_PG_DIR="$SADM_BASE_DIR/pgsql"          ; export SADM_PG_DIR        # PostGres DataBase Dir
SADM_PKG_DIR="$SADM_BASE_DIR/pkg"           ; export SADM_PKG_DIR       # Package rpm,deb  directory
SADM_NMON_DIR="$SADM_DAT_DIR/nmon"          ; export SADM_NMON_DIR      # Where nmon file reside
SADM_DR_DIR="$SADM_DAT_DIR/dr"              ; export SADM_DR_DIR        # Disaster Recovery  files 
SADM_SAR_DIR="$SADM_DAT_DIR/sar"            ; export SADM_SAR_DIR       # System Activty Report Dir
SADM_RCH_DIR="$SADM_DAT_DIR/rch"            ; export SADM_RCH_DIR       # Result Code History Dir
SADM_NET_DIR="$SADM_DAT_DIR/net"            ; export SADM_NET_DIR       # Network SubNet Info Dir
SADM_RPT_DIR="$SADM_DAT_DIR/rpt"            ; export SADM_RPT_DIR       # SADM Sysmon Report Dir
SADM_WWW_DIR="$SADM_BASE_DIR/www"           ; export SADM_WWW_DIR       # Web Dir
SADM_DB_DIR="$SADM_WWW_DIR/db"              ; export SADM_DB_DIR        # SQLite3 Database Dir
#
# SADMIN WEB SITE DIRECTORIES DEFINITION
SADM_WWW_HTML_DIR="$SADM_WWW_DIR/html"                      ; export SADM_WWW_HTML_DIR # www html Dir
SADM_WWW_DAT_DIR="$SADM_WWW_DIR/dat"                        ; export SADM_WWW_DAT_DIR  # www Dat Dir
SADM_WWW_CFG_DIR="$SADM_WWW_DIR/cfg"                        ; export SADM_WWW_CFG_DIR  # www CFG Dir
SADM_WWW_LIB_DIR="$SADM_WWW_DIR/lib"                        ; export SADM_WWW_LIB_DIR  # www Lib Dir
SADM_WWW_IMG_DIR="$SADM_WWW_DIR/images"                     ; export SADM_WWW_IMG_DIR  # www Img Dir
SADM_WWW_RCH_DIR="$SADM_WWW_DAT_DIR/${SADM_HOSTNAME}/rch"   ; export SADM_WWW_RCH_DIR  # web rch dir
SADM_WWW_RPT_DIR="$SADM_WWW_DAT_DIR/${SADM_HOSTNAME}/rpt"   ; export SADM_WWW_RPT_DIR  # web rpt dir
SADM_WWW_SAR_DIR="$SADM_WWW_DAT_DIR/${SADM_HOSTNAME}/sar"   ; export SADM_WWW_SAR_DIR  # web sar dir
SADM_WWW_NET_DIR="$SADM_WWW_DAT_DIR/${SADM_HOSTNAME}/net"   ; export SADM_WWW_NET_DIR  # web net dir
SADM_WWW_DR_DIR="$SADM_WWW_DAT_DIR/${SADM_HOSTNAME}/dr"     ; export SADM_WWW_DR_DIR   # web dr dir
SADM_WWW_NMON_DIR="$SADM_WWW_DAT_DIR/${SADM_HOSTNAME}/nmon" ; export SADM_WWW_NMON_DIR # web nmon dir
SADM_WWW_TMP_DIR="$SADM_WWW_DIR/tmp"                        ; export SADM_WWW_TMP_DIR  # web tmp dir
SADM_WWW_LOG_DIR="$SADM_WWW_DAT_DIR/${SADM_HOSTNAME}/log"   ; export SADM_WWW_LOG_DIR  # web log dir
#
#
# SADM CONFIG FILE, LOGS, AND TEMP FILES USER CAN USE
SADM_PID_FILE="${SADM_TMP_DIR}/${SADM_INST}.pid"            ; export SADM_PID_FILE   # PID file name
SADM_CFG_FILE="$SADM_CFG_DIR/sadmin.cfg"                    ; export SADM_CFG_FILE   # Cfg file name
SADM_DB_FILE="$SADM_DB_DIR/sadm.db"                         ; export SADM_CFG_FILE   # SQLite DB
SADM_REL_FILE="$SADM_CFG_DIR/.release"                      ; export SADM_REL_FILE   # Release Ver.
SADM_CRON_FILE="$SADM_WWW_CFG_DIR/.crontab.txt"             ; export SADM_CRON_FILE  # Work crontab
SADM_CRONTAB="/etc/cron.d/sadmin"                           ; export SADM_CRONTAB    # Final crontab
SADM_CFG_HIDDEN="$SADM_CFG_DIR/.sadmin.cfg"                 ; export SADM_CFG_HIDDEN # Cfg file name
SADM_TMP_FILE1="${SADM_TMP_DIR}/${SADM_INST}_1.$$"          ; export SADM_TMP_FILE1  # Temp File 1 
SADM_TMP_FILE2="${SADM_TMP_DIR}/${SADM_INST}_2.$$"          ; export SADM_TMP_FILE2  # Temp File 2
SADM_TMP_FILE3="${SADM_TMP_DIR}/${SADM_INST}_3.$$"          ; export SADM_TMP_FILE3  # Temp File 3
SADM_ELOG="${SADM_TMP_DIR}/${SADM_INST}_E.log"              ; export SADM_ELOG       # Email Log Tmp 
SADM_LOG="${SADM_LOG_DIR}/${SADM_HOSTNAME}_${SADM_INST}.log"    ; export LOG         # Output LOG 
SADM_RCHLOG="${SADM_RCH_DIR}/${SADM_HOSTNAME}_${SADM_INST}.rch" ; export SADM_RCHLOG # Return Code 
#
# COMMAND PATH REQUIRE TO RUN SADM
SADM_LSB_RELEASE=""                         ; export SADM_LSB_RELEASE   # Command lsb_release Path
SADM_DMIDECODE=""                           ; export SADM_DMIDECODE     # Command dmidecode Path
SADM_BC=""                                  ; export SADM_BC            # Command bc (Do Some Math)
SADM_FDISK=""                               ; export SADM_FDISK         # fdisk (Read Disk Capacity)
SADM_WHICH=""                               ; export SADM_WHICH         # which Path - Required
SADM_PERL=""                                ; export SADM_PERL          # perl Path (for epoch time)
SADM_MAIL=""                                ; export SADM_MAIL          # Mail Pgm Path
SADM_LSCPU=""                               ; export SADM_LSCPU         # Path to lscpu Command
SADM_NMON=""                                ; export SADM_NMON          # Path to nmon Command
SADM_PARTED=""                              ; export SADM_PARTED        # Path to parted Command
SADM_ETHTOOL=""                             ; export SADM_ETHTOOL       # Path to ethtool Command
SADM_PSQL=""                                ; export SADM_PSQL          # Path to PostGresql Exec.
SADM_SSH=""                                 ; export SADM_SSH           # Path to ssh Exec.
SADM_SSH_PORT=""                            ; export SADM_SSH_PORT      # Default SSH Port
SADM_MYSQL=""                               ; export SADM_MYSQL         # Default mysql FQDN
#
# SADM CONFIG FILE VARIABLES (Values defined here Will be overrridden by SADM CONFIG FILE Content)
SADM_MAIL_ADDR="your_email@domain.com"      ; export SADM_MAIL_ADDR     # Default is in sadmin.cfg
SADM_MAIL_TYPE=1                            ; export SADM_MAIL_TYPE     # 0=No 1=Err 2=Succes 3=All
SADM_CIE_NAME="Your Company Name"           ; export SADM_CIE_NAME      # Company Name
SADM_USER="sadmin"                          ; export SADM_USER          # sadmin user account
SADM_GROUP="sadmin"                         ; export SADM_GROUP         # sadmin group account
SADM_WWW_USER="apache"                      ; export SADM_WWW_USER      # /sadmin/www owner 
SADM_WWW_GROUP="apache"                     ; export SADM_WWW_GROUP     # /sadmin/www group
SADM_MAX_LOGLINE=5000                       ; export SADM_MAX_LOGLINE   # Max Nb. Lines in LOG )
SADM_MAX_RCLINE=100                         ; export SADM_MAX_RCLINE    # Max Nb. Lines in RCH file
SADM_NMON_KEEPDAYS=60                       ; export SADM_NMON_KEEPDAYS # Days to keep old *.nmon
SADM_SAR_KEEPDAYS=60                        ; export SADM_SAR_KEEPDAYS  # Days to keep old *.sar
SADM_RCH_KEEPDAYS=60                        ; export SADM_RCH_KEEPDAYS  # Days to keep old *.rch
SADM_LOG_KEEPDAYS=60                        ; export SADM_LOG_KEEPDAYS  # Days to keep old *.log
SADM_DBNAME="sadmin"                        ; export SADM_DBNAME        # MySQL DataBase Name
SADM_DBHOST="sadmin.maison.ca"              ; export SADM_DBHOST        # MySQL DataBase Host
SADM_DBPORT=3306                            ; export SADM_DBPORT        # MySQL Listening Port
SADM_RW_DBUSER=""                           ; export SADM_RW_DBUSER     # MySQL Read/Write User 
SADM_RW_DBPWD=""                            ; export SADM_RW_DBPWD      # MySQL Read/Write Passwd
SADM_RO_DBUSER=""                           ; export SADM_RO_DBUSER     # MySQL Read Only User 
SADM_RO_DBPWD=""                            ; export SADM_RO_DBPWD      # MySQL Read Only Passwd
SADM_SERVER=""                              ; export SADM_SERVER        # Server FQDN Name
SADM_DOMAIN=""                              ; export SADM_DOMAIN        # Default Domain Name
SADM_NETWORK1=""                            ; export SADM_NETWORK1      # Network 1 to Scan 
SADM_NETWORK2=""                            ; export SADM_NETWORK2      # Network 2 to Scan 
SADM_NETWORK3=""                            ; export SADM_NETWORK3      # Network 3 to Scan 
SADM_NETWORK4=""                            ; export SADM_NETWORK4      # Network 4 to Scan 
SADM_NETWORK5=""                            ; export SADM_NETWORK5      # Network 5 to Scan 
DBPASSFILE="${SADM_CFG_DIR}/.dbpass"        ; export DBPASSFILE         # MySQL Passwd File
SADM_RELEASE=`cat $SADM_REL_FILE`           ; export SADM_RELEASE       # SADM Release Ver. Number


# --------------------------------------------------------------------------------------------------
#                     THIS FUNCTION RETURN THE STRING RECEIVED TO UPPERCASE
# --------------------------------------------------------------------------------------------------
sadm_toupper() { 
    echo $1 | tr  "[:lower:]" "[:upper:]"
}


# --------------------------------------------------------------------------------------------------
#                       THIS FUNCTION RETURN THE STRING RECEIVED TO LOWERCASE 
# --------------------------------------------------------------------------------------------------
sadm_tolower() {
    echo $1 | tr  "[:upper:]" "[:lower:]"
}



# --------------------------------------------------------------------------------------------------
#     WRITE INFORMATION TO THE LOG (L) , TO SCREEN (S)  OR BOTH (B) DEPENDING ON $SADM_LOG_TYPE
# --------------------------------------------------------------------------------------------------
#
sadm_writelog() {
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
             ;;
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
# Check if variable is an integer - Return 1, if not an intener - Return 0 if it is an integer
# --------------------------------------------------------------------------------------------------
sadm_isnumeric() {
    wnum=$1
    if [ "$wnum" -eq "$wnum" ] 2>/dev/null ; then return 0 ; else return 1 ; fi
}

    


# --------------------------------------------------------------------------------------------------
#                TRIM THE FILE RECEIVED AS FIRST PARAMETER (MAX LINES IN LOG AS 2ND PARAMATER)
# --------------------------------------------------------------------------------------------------
sadm_trimfile() {
    wfile=$1 ; maxline=$2                                               # Save FileName et Nb Lines
    wreturn_code=0                                                      # Return Code of function
    
    # Test Number of parameters received
    if [ $# -ne 2 ]                                                     # Should have rcv 1 Param
        then sadm_writelog "sadm_trimfile: Should receive 2 Parameters" # Show User Info on Error
             sadm_writelog "Have received $# parameters ($*)"           # Advise User to Correct
             return 1                                                   # Return Error to Caller
    fi
    
    # Test if filename received exist
    if [ ! -r "$wfile" ]                                                # Check if File Rcvd Exist
        then sadm_writelog "sadm_trimfile : Can't read file $1"         # Advise user
             return 1                                                   # Return Error to Caller
    fi

 #   # Test if Second Parameter Received is an integer
    sadm_isnumeric "$maxline"                                           # Test if an Integer
    if [ $? -ne 0 ]                                                     # If not an Integer
        then wreturn_code=1                                             # Return Code report error
             sadm_writelog "sadm_trimfile: Nb of line invalid ($2)"     # Advise User
             return 1                                                   # Return Error to Caller
    fi
    
    #tmpfile=`mktemp --tmpdir=${SADM_TMP_DIR}`                          # Problem in RHEL4 
    tmpfile="${SADM_TMP_DIR}/${SADM_INST}.$$"                           # Create Temp Work FileName    
    if [ $? -ne 0 ] ; then wreturn_code=1 ; fi                          # Return Code report error

    tail -${maxline} $wfile > $tmpfile                                  # Trim file to Desired Nb.
    if [ $? -ne 0 ] ; then wreturn_code=1 ; fi                          # Return Code report error
    rm -f ${wfile} > /dev/null                                          # Remove Original Log
    if [ $? -ne 0 ] ; then wreturn_code=1 ; fi                          # Return Code report error
    mv ${tmpfile} ${wfile}                                              # Move Tmp to original
    if [ $? -ne 0 ] ; then wreturn_code=1 ; fi                          # Return Code report error
    chmod 664 ${wfile}                                                  # Make permission to 664
    if [ $? -ne 0 ] ; then wreturn_code=1 ; fi                          # Return Code report error
    rm -f ${tmpfile} >/dev/null 2>&1                                    # Remove Temp Work File
    if [ $? -ne 0 ] ; then wreturn_code=1 ; fi                          # Return Code report error
    return ${wreturn_code}                                              # Return to Caller 
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
             sadm_writelog " "                                            # Inform User 
             sadm_writelog "WARNING : The \"${SADM_CMD}\" command is not available on $HOSTNAME"
             sadm_writelog "To fully benefit the SADMIN Library & give you accurate information"
             sadm_writelog "We will install the package that include the command \"${SADM_CMD}\""
             sadm_writelog "SADMIN Will install it for you ... One moment"
             #sadm_writelog "Once the software is installed, rerun this script"
             #sadm_writelog "Will continue anyway, but some functionnality may not work as expected"
    fi  
    return 1
}


# --------------------------------------------------------------------------------------------------
#       THIS FUNCTION IS USED TO INSTALL A MISSING PACKAGE THAT IS REQUIRED BY SADMIN TOOLS
#                       THE PACKAGE TO INSTALL IS RECEIVED AS A PARAMETER
# --------------------------------------------------------------------------------------------------
#
sadm_install_package() 
{
    # Check if we received at least a parameter
    if [ $# -ne 2 ]                                                      # Should have rcv 1 Param
        then sadm_writelog "Nb. Parameter received by $FUNCNAME function is incorrect"
             sadm_writelog "Please correct your script - Script Aborted" # Advise User to Correct
             sadm_stop 1                                                 # Prepare exit gracefully
             exit 1                                                      # Terminate the script
    fi
    PACKAGE_RPM=$1                                                       # RedHat/CentOS/Fedora Pkg
    PACKAGE_DEB=$2                                                       # Ubuntu/Debian/Raspian Deb
    

    # Install the Package under RedHat/CentOS/Fedora
    if [ "$(sadm_get_osname)" = "REDHAT" ] || [ "$(sadm_get_osname)" = "CENTOS" ] || 
       [ "$(sadm_get_osname)" = "FEDORA" ]
        then sadm_writelog "Starting installation of ${PACKAGE_RPM} under $(sadm_get_osname)"
             case "$(sadm_get_osmajorversion)" in
                [3|4]) sadm_writelog "Current version of O/S is $(sadm_get_osmajorversion)"
                       sadm_writelog "Running \"up2date --nox -i ${PACKAGE_RPM}\""
                       up2date --nox -i ${PACKAGE_RPM} >>$SADM_LOG 2>&1
                       rc=$?
                       sadm_writelog "Return Code after installing ${PACKAGE_RPM} is $rc"
                       break
                       ;;
              [5|6|7]) sadm_writelog "Current version of O/S is $(sadm_get_osmajorversion)"
                       sadm_writelog "Running \"yum -y install ${PACKAGE_RPM}\"" # Install Command
                       yum -y install ${PACKAGE_RPM} >> $SADM_LOG 2>&1      # List Available update
                       rc=$?                                            # Save Exit Code
                       sadm_writelog "Return Code after in installation of ${PACKAGE_RPM} is $rc"
                       break
                       ;;
             esac
    fi
    
    # Install the Package under Debian/*Ubuntu/RaspberryPi 
    if [ "$(sadm_get_osname)" = "UBUNTU" ] || [ "$(sadm_get_osname)" = "RASPBIAN" ] ||
       [ "$(sadm_get_osname)" = "DEBIAN" ] || [ "$(sadm_get_osname)" = "LINUXMINT" ] 
        then sadm_writelog "Resynchronize package index files from their sources via Internet"
             sadm_writelog "Running \"apt-get update\""                 # Msg Get package list 
             apt-get update > /dev/null 2>&1                            # Get Package List From Repo
             rc=$?                                                      # Save Exit Code
             if [ "$rc" -ne 0 ]
                then sadm_writelog "We had problem running the \"apt-get update\" command" 
                     sadm_writelog "We had a return code $rc" 
                else sadm_writelog "Return Code after apt-get update is $rc"  # Show  Return Code
                     sadm_writelog "Installing the Package ${PACKAGE_DEB} now"
                     sadm_writelog "apt-get -y install ${PACKAGE_DEB}"
                     apt-get -y install ${PACKAGE_DEB}
                     rc=$?                                              # Save Exit Code
                     sadm_writelog "Return Code after installation of ${PACKAGE_DEB} is $rc" 
             fi
    fi         
    sadm_writelog " "
    return $rc                                                          # 0=Installed 1=Error
}


# --------------------------------------------------------------------------------------------------
# THIS FUNCTION MAKE SURE THAT ALL SADM SHELL LIBRARIES (LIB/SADM_*) REQUIREMENTS ARE MET BEFORE USE
# IF THE REQUIRENMENT ARE NOT MET, THEN THE SCRIPT WILL ABORT INFORMING USER TO CORRECT SITUATION
# --------------------------------------------------------------------------------------------------
#
sadm_check_requirements() {
                           
    # The 'which' command is needed to determine presence of command - Return Error if not found
    if which which >/dev/null 2>&1                                      # Try the command which 
        then SADM_WHICH=`which which`  ; export SADM_WHICH              # Save the Path of Which
        else sadm_writelog " ERROR : The command 'which' couldn't be found" 
             sadm_writelog " This program is often used by the SADMIN tools"
             sadm_writelog " Please install it and re-run this script"
             sadm_writelog " To install it, use the following command depending on your distro"
             sadm_writelog " Use 'yum install which' or 'apt-get install debianutils'"
             sadm_writelog " *** Script Aborted"
             return 1                                                   # Return Error to Caller
    fi
    
    # Commands require on Linux O/S ----------------------------------------------------------------
    if [ "$(sadm_get_ostype)" = "LINUX" ]                               # Under Linux
       then sadm_check_command_availibility "lsb_release"               # lsb_release cmd available?
            SADM_LSB_RELEASE=$SADM_VAR1                                 # Save Command Path
            sadm_check_command_availibility "dmidecode"                 # dmidecode cmd available?
            SADM_DMIDECODE=$SADM_VAR1                                   # Save Command Path
            sadm_check_command_availibility "fdisk"                     # FDISK cmd available?
            SADM_FDISK=$SADM_VAR1                                       # Save Command Path
            
            # Check Availibility of the "nmon" command
            sadm_check_command_availibility "nmon"                      # Command available?
            if [ "$SADM_VAR1" = "" ]                                    # If Command not found
               then sadm_install_package "nmon" "nmon"                  # Go Install Missing Package
                    if [ $? -eq 0 ]                                     # If Install Went OK
                       then sadm_check_command_availibility nmon        # Check if command now Avail
                    fi
            fi
            SADM_NMON=$SADM_VAR1                                        # Save Command Path
           
            # Check Availibility of the "ethtool" command
            sadm_check_command_availibility "ethtool"                   # Command available?
            if [ "$SADM_VAR1" = "" ]                                    # If Command not found
               then sadm_install_package "ethtool" "ethtool"            # Go Install Missing Package
                    if [ $? -eq 0 ]                                     # If Install Went OK
                       then sadm_check_command_availibility ethtool     # Check if command now Avail
                    fi
            fi
            SADM_ETHTOOL=$SADM_VAR1                                     # Save Command Path
            
            # Check Availibility of the "parted" command
            sadm_check_command_availibility "parted"                    # Command available?
            if [ "$SADM_VAR1" = "" ]                                    # If Command not found
               then sadm_install_package "parted" "parted"              # Go Install Missing Package
                    if [ $? -eq 0 ]                                     # If Install Went OK
                       then sadm_check_command_availibility "parted"    # Check if command now Avail
                    fi
            fi
            SADM_PARTED=$SADM_VAR1                                      # Save Command Path
            
            sadm_check_command_availibility "mail"                      # Mail cmd available?
            if [ "$SADM_VAR1" = "" ]                                    # If Command not found
               then sadm_install_package "mailx" "mailutils"            # Go Install Missing Package
                    if [ $? -eq 0 ]                                     # If Install Went OK
                       then sadm_check_command_availibility "mail"      # Check if command now Avail
                    fi               

            fi
            SADM_MAIL=$SADM_VAR1                                        # Save Command Path

            sadm_check_command_availibility lscpu                       # lscpu cmd available?
            SADM_LSCPU=$SADM_VAR1                                       # Save Command Path
            #if [ "$SADM_VAR1" = "" ]                                    # If Command not found
            #   then sadm_install_package "util-linux" "util-linux"      # Go Install RPM/DEBIAN pkg
            #        if [ $? -eq 0 ]                                     # If Install Went OK
            #           then sadm_check_command_availibility "lscpu"     # Check if command now Avail
            #        fi               
            #fi
    fi
    
    # Commands Require on Aix O/S ------------------------------------------------------------------
    if [ "$(sadm_get_ostype)" = "AIX" ]                                 # Under Aix O/S
       then sadm_check_command_availibility "bc"                        # bc cmd available?
            SADM_BC=$SADM_VAR1                                          # Save Command Path
            sadm_check_command_availibility "mail"                      # mail cmd available?
            SADM_MAIL=$SADM_VAR1       
            sadm_check_command_availibility "nmon"                      # nmon cmd available?
            SADM_NMON=$SADM_VAR1       
            if [ "$SADM_VAR1" = "" ]                                    # If Command not found
               then NMON_WDIR="${SADM_PKG_DIR}/nmon/aix/" 
                    NMON_EXE="nmon_aix$(sadm_get_osmajorversion)$(sadm_get_osminorversion)"
                    NMON_USE="${NMON_WDIR}${NMON_EXE}"
                    if [ ! -x "$NMON_USE" ]
                        then sadm_writelog "The nmon for AIX $(sadm_get_osversion) isn't available"
                             sadm_writelog "The nmon executable we need is $NMON_USE" 
                        else sadm_writelog "ln -s ${NMON_USE} /usr/bin/nmon" 
                             ln -s ${NMON_USE} /usr/bin/nmon
                             if [ $? -eq 0 ] ; then SADM_NMON="/usr/bin/nmon" ; fi 
                    fi
            fi
    fi
    
    # Commands require on ALL platform 
    sadm_check_command_availibility "perl"                              # perl needed (epoch time)
    SADM_PERL=$SADM_VAR1                                                # Save perl path
    sadm_check_command_availibility "ssh"                               # ssh needed (epoch time)
    SADM_SSH=$SADM_VAR1                                                 # Save ssh path
    sadm_check_command_availibility "bc"                                # bc cmd available?
    SADM_BC=$SADM_VAR1                                                  # Save Command Path
    sadm_check_command_availibility "mail"                              # Mail cmd available?
    SADM_MAIL=$SADM_VAR1                                                # Save Command Path

    # If on the SADMIN Server mysql MUST be present - Check Availibility of the mysql command.
    SADM_MYSQL=""                                                       # Default mysql Location
    if [ "$(sadm_get_fqdn)" = "$SADM_SERVER" ]                            # Only Check on SADMIN Srv
        then sadm_check_command_availibility "mysql"                      # Command available?
             if [ "$SADM_VAR1" = "" ]                                    # If Command not found
                then sadm_install_package "mysql" "mysql"                  # Go Install Missing Package
                     if [ $? -eq 0 ]                                     # If Install Went OK
                        then sadm_check_command_availibility mysql       # Check if command now Avail
                             if [ $? -eq 0 ] 
                                then SADM_MYSQL=$SADM_VAR1                                        # Save Command Path
                                else sadm_writelog "Please install mysql software"
                                     sadm_stop 1
                             fi
                        else sadm_writelog "Please install mysql software"
                             sadm_stop 1
                    fi
             else
                SADM_MYSQL=$SADM_VAR1                                        # Save Command Path
             fi
    fi
    return 0
}



# --------------------------------------------------------------------------------------------------
#      Called when we need to advise the user of an error or when his attention is required.
# --------------------------------------------------------------------------------------------------
alert_user()    {
    
    # Save Received Parameters
    a_type=$1                                                           # Proto M=Mail T=Text P=Page
    a_severity=$2                                                       # E=Error W=Warning I=info
    a_server=$3                                                         # Problematic Server Name 
    a_group=$4                                                          # Destination alert group
    a_mess=$5                                                           # Alert Message
    a_exit_code=0                                                       # Def. Function Return Code

    # Build the SADM uniform Subject Prefix - Based on Alert Severity Received
    case "$a_severity" in                                               # Depend on Severity E/W/I
        e|E) a_prefix="SADM: ERROR "                                    # Error SADM Subject Prefix        
             ;; 
        w|W) a_prefix="SADM: WARNING "                                  # Warning SADM Subject Prefix                 
             ;; 
        i|I) a_prefix="SADM: INFO "                                     # Info SADM Subject Prefix                 
             ;; 
          *) a_prefix="SADM: N/A "                                      # Invalid SADM Subject Prefix                 
             a_exit_code=1                                              # Something went wrong in fct.
             ;; 
    esac

    # Send the Alert Message using the Protocol requested
    case "$a_type" in 
        m|M) if [ "$SADM_MAIL" == "" ] 
                then sadm_writelog "Function 'alert_user' was requested to send an email" 
                     sadm_writelog "But the mail program was not found (SADM_MAIL=${SADM_MAIL})" 
                     sadm_writelog "Correct the situation and try again"
                     a_exit_code=1                                      # Something went wrong 
                else a1_msg="`date` ${a_server} ${a_prefix}${a_mess}"   # Build Email Alert Message
                     echo "${a1_msg}" | $SADM_MAIL -s "${a_prefix}${a_mess}" $SADM_MAIL_ADDR
                     a_exit_code=$?                                     # Set Return Code 
             fi
             ;; 
          *) a1_msg="`date` ${a_server} ${a_prefix}"                    # Invalid Protocol Received
             a2_msg="Function 'alert_user' received an invalid first parameter ($a_type)" 
             a3_msg="${a1_msg}${a2_msg}"                                # Advise usr something wrong
             echo "`date` ${a_server} $a3_msg" |$SADM_MAIL -s "SADM: ALERT $a_mess" $SADM_MAIL_ADDR
             a_exit_code=1                                              # Something went wrong 
             ;; 
    esac

    return $a_exit_code
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
        then sadm_writelog "No Parameter received by $FUNCNAME function"  # Show User Info on Error
             sadm_writelog "Please correct your script - Script Aborted"  # Advise User to Correct
             sadm_stop 1                                                # Prepare to exit gracefully
             exit 1                                                     # Terminate the script
    fi
    wepoch=$1                                                           # Save Epoch Time Receivec

    # Verify if parameter received is all numeric - If not advice user and exit
    echo $wepoch | grep [^0-9] > /dev/null 2>&1                         # Grep for Number
    if [ "$?" -eq "0" ]                                                 # Not All Number
        then sadm_writelog "Incorrect parameter received by \"sadm_epoch_to_date\" function"
             sadm_writelog "Should recv. epoch time & received ($wepoch)" # Advise User
             sadm_writelog "Please correct situation - Script Aborted"    # Advise that will abort
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
        then sadm_writelog "No Parameter received by $FUNCNAME function"  # Log Error Mess,
             sadm_writelog "Please correct script please, script aborted" # Advise that will abort
             sadm_stop 1                                                # Prepare to exit gracefully
             exit 1                                                     # Terminate the script
    fi

    WDATE=$1                                                            # Save Received Date
    YYYY=`echo $WDATE | awk -F. '{ print $1 }'`                         # Extract Year from Rcv Date
    MTH=` echo $WDATE | awk -F. '{ print $2 }'`                         # Extract MTH  from Rcv Date
    DD=`echo   $WDATE | awk -F. '{ print $3 }' | awk '{ print $1 }'`    # Extract Day
    HH=`echo   $WDATE | awk '{ print $2 }' | awk -F: '{ print $1 }'`    # Extract Hours
    MM=`echo   $WDATE | awk '{ print $2 }' | awk -F: '{ print $2 }'`    # Extract Min   
    SS=`echo   $WDATE | awk '{ print $2 }' | awk -F: '{ print $3 }'`    # Extract Sec

#jacques@mycroftw:~/Documents/Dev/sadmin/bin$ date -j -f "%Y/%m/%d %T" "2009/10/15 04:58:06" +"%s"
#1255597086
#jacques@holmes:~$ date "+%s" -d "2009/10/15 04:58:06"
#1255597086
    #sadm_writelog "OSTYPE = $(sadm_get_ostype) - date $YYYY/$MTH/$DD $HH:$MM:$SS"
    case "$(sadm_get_ostype)" in                                            
        "LINUX")    DD= `printf "%02d" $DD` 
                    MTH=`printf "%02d" $MTH`
                    HH=` printf "%02d" $HH`
                    MM=` printf "%02d" $MM`
                    SS=` printf "%02d" $SS`                   
                    sadm_date_to_epoch=`date +"%s" -d "$YYYY/$MTH/$DD $HH:$MM:$SS" `
                    ;; 
        "AIX")      if [ "$MTH" -gt 0 ] ; then MTH=`echo $MTH | sed 's/^0//'` ; fi      # Remove Leading 0 from Mth
                    MTH=`echo "$MTH -1" | $SADM_BC`
                    DD=`echo   $WDATE | awk -F. '{ print $3 }' | awk '{ print $1 }' | sed 's/^0//'` # Extract Day
                    HH=`echo   $WDATE | awk '{ print $2 }' | awk -F: '{ print $1 }' | sed 's/^0//'` # Extract Hours
                    MM=`echo   $WDATE | awk '{ print $2 }' | awk -F: '{ print $2 }' | sed 's/^0//'` # Extract Min   
                    SS=`echo   $WDATE | awk '{ print $2 }' | awk -F: '{ print $3 }' | sed 's/^0//'` # Extract Sec
                    sadm_date_to_epoch=`perl -e "use Time::Local; print timelocal($SS,$MM,$HH,$DD,$MTH,$YYYY)"`
                    ;;
        "DARWIN")   #set -x 
                    DD=` printf "%02d" $DD` 
                    MTH=`printf "%02d" $MTH`
                    HH=` printf "%02d" $HH`
                    MM=` printf "%02d" $MM`
                    SS=` printf "%02d" $SS`                   
                    sadm_date_to_epoch=`date -j -f "%Y/%m/%d %T" "$YYYY/$MTH/$DD $HH:$MM:$SS" +"%s"`
                    ;;   
    esac
    # Call Perl to Return Epoch Time for Date Received   
    #sadm_writelog ("timelocal $SS , $MM , $HH , $DD ,$MTH , $YYYY")
    #sadm_date_to_epoch=`perl -e "use Time::Local; print timelocal($SS,$MM,$HH,$DD,$MTH,$YYYY)"`
    #sadm_writelog "epoch is $sadm_date_to_epoch"
    echo "$sadm_date_to_epoch"                                          # Return Epoch of Date Rcv.
}



# --------------------------------------------------------------------------------------------------
#    Calculate elapse time between date1 (YYYY.MM.DD HH:MM:SS) and date2 (YYYY.MM.DD HH:MM:SS)
#    Date 1 MUST be greater than date 2  (Date 1 = Like End time,  Date 2 = Start Time )
# --------------------------------------------------------------------------------------------------
sadm_elapse_time() {
    if [ $# -ne 2 ]                                                     # Should have rcv 1 Param
        then sadm_writelog "Invalid number of parameter received by $FUNCNAME function"
             sadm_writelog "Please correct script please, script aborted" # Advise that will abort
             sadm_stop 1                                                # Prepare to exit gracefully
             exit 1                                                     # Terminate the script
    fi
    w_endtime=$1                                                        # Save Ending Time
    w_starttime=$2                                                      # Save Start Time
    epoch_start=`sadm_date_to_epoch "$w_starttime"`                     # Get Epoch for Start Time
    epoch_end=`sadm_date_to_epoch   "$w_endtime"`                       # Get Epoch for End Time
    epoch_elapse=`echo "$epoch_end - $epoch_start" | $SADM_BC`          # Substract End - Start time

    if [ "$epoch_elapse" = "" ] ; then epoch_elapse=0 ; fi              # If nb Sec Greater than 1Hr
    whour=00 ; wmin=00 ; wsec=00

    # Calculate number of hours (1 hr = 3600 Seconds)
    if [ "$epoch_elapse" -gt 3599 ]                                     # If nb Sec Greater than 1Hr
        then whour=`echo "$epoch_elapse / 3600" | $SADM_BC`             # Calculate nb of Hours
             epoch_elapse=`echo "$epoch_elapse - ($whour * 3600)" | $SADM_BC` # Sub Hr*Sec from elapse
    fi
    
    # Calculate number of minutes 1 Min = 60 Seconds)
    if [ "$epoch_elapse" -gt 59 ]                                       # If more than 1 min left
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
sadm_get_osversion() {
    wosversion="0.0"                                                    # Default Value
    case "$(sadm_get_ostype)" in                                            
        "LINUX")    wosversion=`$SADM_LSB_RELEASE -sr`                  # Use lsb_release to Get Ver
                    ;; 
        "AIX")      wosversion="`uname -v`.`uname -r`"                  # Get Aix Version 
                    ;;
        "DARWIN")   wosversion=`sw_vers -productVersion`                # Get O/S Version on MacOS
                    ;;   
    esac
    echo "$wosversion"
}

# --------------------------------------------------------------------------------------------------
#                            RETURN THE OS (DISTRIBUTION) MAJOR VERSION
# --------------------------------------------------------------------------------------------------
sadm_get_osmajorversion() {
    case "$(sadm_get_ostype)" in
        "LINUX")    wosmajorversion=`echo $(sadm_get_osversion) | awk -F. '{ print $1 }'| tr -d ' '`
                    ;;
        "AIX")      wosmajorversion=`uname -v`
                    ;;
        "DARWIN")   wosmajorversion=`sw_vers -productVersion | awk -F '.' '{print $1 "." $2}'`
                    ;;                 
    esac
    echo "$wosmajorversion"
}


# --------------------------------------------------------------------------------------------------
#                            RETURN THE OS (DISTRIBUTION) MINOR VERSION
# --------------------------------------------------------------------------------------------------
sadm_get_osminorversion() {
    case "$(sadm_get_ostype)" in
        "LINUX")    wosminorversion=`echo $(sadm_get_osversion) | awk -F. '{ print $2 }'| tr -d ' '`
                    ;;
        "AIX")      wosminorversion=`uname -r`
                    ;;
        "DARWIN")   wosminorversion=`sw_vers -productVersion | awk -F '.' '{print $3 }'`
                    ;;
    esac
    echo "$wosminorversion"
}

# --------------------------------------------------------------------------------------------------
#                RETURN THE OS TYPE (LINUX, AIX) -- ALWAYS RETURNED IN UPPERCASE
# --------------------------------------------------------------------------------------------------
sadm_get_ostype() {
    sadm_get_ostype=`uname -s | tr '[:lower:]' '[:upper:]'`             # OS Name (AIX/LINUX/DARWIN)
    echo "$sadm_get_ostype"
}


# --------------------------------------------------------------------------------------------------
#                             RETURN THE OS PROJECT CODE NAME
# --------------------------------------------------------------------------------------------------
sadm_get_oscodename() {
    if [ "$(sadm_get_ostype)" == "LINUX" ] ; then woscodename=`$SADM_LSB_RELEASE -sc`; fi
    if [ "$(sadm_get_ostype)" == "AIX" ]   ; then woscodename="IBM_AIX" ; fi
    if [ "$(sadm_get_ostype)" == "DARWIN" ] 
        then wver="$(sadm_get_osmajorversion)"
             if [ "$wver"  == "10.0" ]  ; then woscodename="Cheetah"          ;fi
             if [ "$wver"  == "10.1" ]  ; then woscodename="Puma"             ;fi
             if [ "$wver"  == "10.2" ]  ; then woscodename="Jaguar"           ;fi
             if [ "$wver"  == "10.3" ]  ; then woscodename="Panther"          ;fi
             if [ "$wver"  == "10.4" ]  ; then woscodename="Tiger"            ;fi
             if [ "$wver"  == "10.5" ]  ; then woscodename="Leopard"          ;fi
             if [ "$wver"  == "10.6" ]  ; then woscodename="Snow Leopard"     ;fi
             if [ "$wver"  == "10.7" ]  ; then woscodename="Lion"             ;fi
             if [ "$wver"  == "10.8" ]  ; then woscodename="Mountain Lion"    ;fi
             if [ "$wver"  == "10.9" ]  ; then woscodename="Mavericks"        ;fi
             if [ "$wver"  == "10.10" ] ; then woscodename="Yosemite"         ;fi
             if [ "$wver"  == "10.11" ] ; then woscodename="El Capitan"       ;fi
             if [ "$wver"  == "10.12" ] ; then woscodename="Sierra"           ;fi
             if [ "$wver"  == "10.13" ] ; then woscodename="High Sierra"      ;fi
    fi
    echo "$woscodename"
}


# --------------------------------------------------------------------------------------------------
#                   RETURN THE OS  NAME (ALWAYS RETURNED IN UPPERCASE)
# --------------------------------------------------------------------------------------------------
sadm_get_osname() {
    if [ "$(sadm_get_ostype)" = "LINUX" ]
        then wosname=`$SADM_LSB_RELEASE -si | tr '[:lower:]' '[:upper:]'`
             if [ "$wosname" = "REDHATENTERPRISESERVER" ] ; then wosname="REDHAT" ; fi
             if [ "$wosname" = "REDHATENTERPRISEAS" ]     ; then wosname="REDHAT" ; fi
    fi 
    if [ "$(sadm_get_ostype)" = "AIX" ]   ; then wosname="AIX" ; fi
    if [ "$(sadm_get_ostype)" == "DARWIN" ]; 
        then wosname=`sw_vers -productName | tr -d ' '`
             wosname=`echo $wosname | tr '[:lower:]' '[:upper:]'`
    fi
    echo "$wosname"
}



# --------------------------------------------------------------------------------------------------
#                                 RETURN SADMIN RELEASE VERSION NUMBER
# --------------------------------------------------------------------------------------------------
sadm_get_release() {
    if [ -r "$SADM_REL_FILE" ]
        then wrelease=`cat $SADM_REL_FILE`
        else wrelease="00.00"
    fi
    echo "$wrelease"
}



# --------------------------------------------------------------------------------------------------
#                                 RETURN THE HOSTNAME (SHORT)
# --------------------------------------------------------------------------------------------------
sadm_get_hostname() {
    if [ "$(sadm_get_ostype)" = "LINUX" ]                               # Under Linux
        then whostname=`hostname -s`                                    # Get rid of domain name
    fi
    if [ "$(sadm_get_ostype)" = "AIX" ]                                 # Under AIX
        then whostname=`hostname | awk -F. '{ print $1 }'`              # Get HostName
    fi
    echo "$whostname"
}


# --------------------------------------------------------------------------------------------------
#                                 RETURN THE DOMAINNAME (SHORT)
# --------------------------------------------------------------------------------------------------
sadm_get_domainname() {
    case "$(sadm_get_ostype)" in
        "LINUX") wdomainname=`host ${SADM_HOSTNAME} |head -1 |awk '{ print $1 }' |cut -d. -f2-3` 
                 ;;
        "AIX")   wdomainname=`namerslv -s | grep domain | awk '{ print $2 }'`
                 ;;
    esac
    if [ "$wdomainname" = "" ] ; then wdomainname="$SADM_DOMAIN" ; fi
    echo "$wdomainname"
}



# --------------------------------------------------------------------------------------------------
#                        RETURN THE FULLY QUALIFIED NAME OF THE SYSTEM
# --------------------------------------------------------------------------------------------------
sadm_get_fqdn() {
    echo "${SADM_HOSTNAME}.$(sadm_get_domainname)"
}


# --------------------------------------------------------------------------------------------------
#                              RETURN THE IP OF THE CURRENT HOSTNAME
# --------------------------------------------------------------------------------------------------
sadm_get_host_ip() {
    case "$(sadm_get_ostype)" in
        "LINUX") whost_ip=`host ${SADM_HOSTNAME} |awk '{ print $4 }' |head -1` 
                 ;;
        "AIX")   whost_ip=`host ${SADM_HOSTNAME}.$(sadm_get_domainname) |head -1 |awk '{ print $3 }'` 
                 ;;
    esac    
    echo "$whost_ip"
}



# --------------------------------------------------------------------------------------------------
#                     Return if running 32 or 64 Bits Kernel version
# --------------------------------------------------------------------------------------------------
sadm_get_kernel_bitmode() { 
    case "$(sadm_get_ostype)" in
        "LINUX")   wkernel_bitmode=`getconf LONG_BIT`
                   ;;
        "AIX")     wkernel_bitmode=`getconf KERNEL_BITMODE`
                   ;;
    esac
    echo "$wkernel_bitmode"
}



# --------------------------------------------------------------------------------------------------
#                                 RETURN KERNEL RUNNING VERSION
# --------------------------------------------------------------------------------------------------
sadm_get_kernel_version() {
    case "$(sadm_get_ostype)" in
        "LINUX")   wkernel_version=`uname -r | cut -d. -f1-3`
                   ;;
        "AIX")     wkernel_version=`uname -r`
                   ;;
    esac
    
    echo "$wkernel_version"
}



# --------------------------------------------------------------------------------------------------
#            LOAD SADMIN CONFIGURATION FILE AND SET GLOBAL VARIABLES ACCORDINGLY
# --------------------------------------------------------------------------------------------------
#
sadm_load_config_file() {

    # Configuration file MUST be present - If .sadm_config exist, then create sadm_config from it.
    if [ ! -r "$SADM_CFG_FILE" ]
        then if [ ! -r "$SADM_CFG_HIDDEN" ] 
                then echo "****************************************************************"
                     echo "SADMIN Configuration file not found - $SADM_CFG_FILE "
                     echo "Even the config template file can't be found - $SADM_CFG_HIDDEN"
                     echo "Copy both files from another system to this server"
                     echo "Or restore the files from a backup"
                     echo "Review the file content."
                     echo "****************************************************************"
                     sadm_stop 1
                else echo "****************************************************************"
                     echo "The configuration file $SADM_CFG_FILE do not exist."
                     echo "Will continue using template configuration file $SADM_CFG_HIDDEN"
                     echo "Please review the configuration file."
                     echo "cp $SADM_CFG_HIDDEN $SADM_CFG_FILE"   # Install Default cfg  file
                     cp $SADM_CFG_HIDDEN $SADM_CFG_FILE                 # Install Default cfg  file
                     echo "****************************************************************"
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
        echo "$wline" |grep -i "^SADM_DOMAIN" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_DOMAIN=`echo "$wline"        |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_USER" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_USER=`echo "$wline"          |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_GROUP" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_GROUP=`echo "$wline"         |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_WWW_USER" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_WWW_USER=`echo "$wline"          |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_WWW_GROUP" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_WWW_GROUP=`echo "$wline"         |cut -d= -f2 |tr -d ' '` ;fi
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
        echo "$wline" |grep -i "^SADM_RCH_KEEPDAYS" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_RCH_KEEPDAYS=`echo "$wline"  |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_LOG_KEEPDAYS" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_LOG_KEEPDAYS=`echo "$wline"  |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_DBNAME" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_DBNAME=`echo "$wline"  |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_DBHOST" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_DBHOST=`echo "$wline"  |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_DBPORT" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_DBPORT=`echo "$wline"  |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_RW_DBUSER" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_RW_DBUSER=`echo "$wline"  |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_RW_DBPWD" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_RW_DBPWD=`echo "$wline"  |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_RO_DBUSER" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_RO_DBUSER=`echo "$wline"  |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_RO_DBPWD" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_RO_DBPWD=`echo "$wline"  |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_SSH_PORT" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_SSH_PORT=`echo "$wline"  |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_NETWORK1" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_NETWORK1=`echo "$wline"  |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_NETWORK2" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_NETWORK2=`echo "$wline"  |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_NETWORK3" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_NETWORK3=`echo "$wline"  |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_NETWORK4" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_NETWORK4=`echo "$wline"  |cut -d= -f2 |tr -d ' '` ;fi
        #
        echo "$wline" |grep -i "^SADM_NETWORK5" > /dev/null 2>&1
        if [ $? -eq 0 ] ; then SADM_NETWORK5=`echo "$wline"  |cut -d= -f2 |tr -d ' '` ;fi
        #
        done < $SADM_CFG_FILE

        # For Debugging Purpose - Display Final Value of configuration file
        if [ "$SADM_DEBUG_LEVEL" -gt 8 ]
            then sadm_writelog ""
                 sadm_writelog "EXPORTED VARIABLES THAT ARE SET AFTER READING THE CONFIG FILE " 
                 sadm_writelog "SADM_DEBUG_LEVEL $SADM_DEBUG_LEVEL Information"
                 sadm_writelog "CONFIGURATION FILE IS $SADM_CFG_FILE"
                 sadm_writelog "  - SADM_MAIL_ADDR=$SADM_MAIL_ADDR"         # Default email address
                 sadm_writelog "  - SADM_CIE_NAME=$SADM_CIE_NAME"           # Company Name
                 sadm_writelog "  - SADM_MAIL_TYPE=$SADM_MAIL_TYPE"         # Send Email after each run
                 sadm_writelog "  - SADM_SERVER=$SADM_SERVER"               # SADMIN server
                 sadm_writelog "  - SADM_DOMAIN=$SADM_DOMAIN"               # SADMIN Domain Default
                 sadm_writelog "  - SADM_SSH_PORT=$SADM_SSH_PORT"           # SADMIN SSH TCP Port
                 sadm_writelog "  - SADM_USER=$SADM_USER"                   # sadmin user account
                 sadm_writelog "  - SADM_GROUP=$SADM_GROUP"                 # sadmin group account
                 sadm_writelog "  - SADM_WWW_USER=$SADM_WWW_USER"           # sadmin user account
                 sadm_writelog "  - SADM_WWW_GROUP=$SADM_WWW_GROUP"         # sadmin group account
                 sadm_writelog "  - SADM_MAX_LOGLINE=$SADM_MAX_LOGLINE"     # Max Line in each *.log
                 sadm_writelog "  - SADM_MAX_RCLINE=$SADM_MAX_RCLINE"       # Max Line in each *.rch
                 sadm_writelog "  - SADM_NMON_KEEPDAYS=$SADM_NMON_KEEPDAYS" # Days to keep old *.nmon
                 sadm_writelog "  - SADM_SAR_KEEPDAYS=$SADM_SAR_KEEPDAYS"   # Days ro keep old *.sar
                 sadm_writelog "  - SADM_RCH_KEEPDAYS=$SADM_NMON_KEEPDAYS"  # Days to keep old *.rch
                 sadm_writelog "  - SADM_LOG_KEEPDAYS=$SADM_SAR_KEEPDAYS"   # Days ro keep old *.log
                 sadm_writelog "  - SADM_PGUSER=$SADM_PGUSER"               # PostGres User Name
                 sadm_writelog "  - SADM_PGGROUP=$SADM_PGGROUP"             # PostGres Group Name
                 sadm_writelog "  - SADM_PGDB=$SADM_PGDB"                   # PostGres DataBase Name
                 sadm_writelog "  - SADM_PGSCHEMA=$SADM_PGSCHEMA"           # PostGres DataBase Schema
                 sadm_writelog "  - SADM_PGHOST=$SADM_PGHOST"               # PostGres DataBase Host
                 sadm_writelog "  - SADM_PGPORT=$SADM_PGPORT"               # PostGres Listening Port
                 sadm_writelog "  - SADM_RW_PGUSER=$SADM_RW_PGUSER"         # PostGres RW User
                 sadm_writelog "  - SADM_RW_PGPWD=$SADM_RW_PGPWD"           # PostGres RW User Pwd
                 sadm_writelog "  - SADM_RO_PGUSER=$SADM_RO_PGUSER"         # PostGres RO User
                 sadm_writelog "  - SADM_RO_PGPWD=$SADM_RO_PGPWD"           # PostGres RO User Pwd
                 sadm_writelog "  - SADM_NETWORK1 = $SADM_NETWORK1"         # Subnet to Scan
                 sadm_writelog "  - SADM_NETWORK2 = $SADM_NETWORK2"         # Subnet to Scan
                 sadm_writelog "  - SADM_NETWORK3 = $SADM_NETWORK3"         # Subnet to Scan
                 sadm_writelog "  - SADM_NETWORK4 = $SADM_NETWORK4"         # Subnet to Scan
                 sadm_writelog "  - SADM_NETWORK5 = $SADM_NETWORK5"         # Subnet to Scan
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
    [ ! -d "$SADM_LOG_DIR" ] && mkdir -p $SADM_LOG_DIR
    chmod 0775 $SADM_LOG_DIR
    chown ${SADM_USER}:${SADM_GROUP} $SADM_LOG_DIR           

    # If LOG File doesn't exist, Create it and Make it writable 
    [ ! -e "$SADM_LOG" ] && touch $SADM_LOG
    chmod 664 $SADM_LOG
    chown ${SADM_USER}:${SADM_GROUP} ${SADM_LOG}

    # If Email LOG File doesn't exist, Create it and Make it writable 
    rm -f $SADM_ELOG >> /dev/null
    touch $SADM_ELOG
    chmod 664 $SADM_ELOG
    chown ${SADM_USER}:${SADM_GROUP} ${SADM_ELOG}

    # If TMP Directory doesn't exist, create it.
    [ ! -d "$SADM_TMP_DIR" ] && mkdir -p $SADM_TMP_DIR
    chmod 1777 $SADM_TMP_DIR
    chown ${SADM_USER}:${SADM_GROUP} $SADM_TMP_DIR

    # If LIB Directory doesn't exist, create it.
    [ ! -d "$SADM_LIB_DIR" ] && mkdir -p $SADM_LIB_DIR
    chmod 0775 $SADM_LIB_DIR
    chown ${SADM_USER}:${SADM_GROUP} $SADM_LIB_DIR

    # If Custom Configuration Directory doesn't exist, create it.
    [ ! -d "$SADM_CFG_DIR" ] && mkdir -p $SADM_CFG_DIR
    chmod 0775 $SADM_CFG_DIR
    chown ${SADM_USER}:${SADM_GROUP} $SADM_CFG_DIR

    # If System Startup/Shutdown Script Directory doesn't exist, create it.
    [ ! -d "$SADM_SYS_DIR" ] && mkdir -p $SADM_SYS_DIR
    chmod 0775 $SADM_SYS_DIR
    chown ${SADM_USER}:${SADM_GROUP} $SADM_SYS_DIR

    # If PostGres DataBase Directories doesn't exist, create it. (If on SADM Server)
    if [ ! -d "$SADM_PG_DIR" ] && [ "${SADM_HOSTNAME}.$(sadm_get_domainname)" = "$SADM_SERVER" ]    
        then mkdir -p $SADM_PG_DIR
             mkdir -p $SADM_PG_DIR/data
             mkdir -p $SADM_PG_DIR/backups
             chmod -R 0700 $SADM_PG_DIR
             chown -R ${SADM_PGUSER}.${SADM_PGGROUP} $SADM_PG_DIR
    fi

    # If Data Directory doesn't exist, create it.
    [ ! -d "$SADM_DAT_DIR" ] && mkdir -p $SADM_DAT_DIR
    chmod 0775 $SADM_DAT_DIR
    chown ${SADM_USER}:${SADM_GROUP} $SADM_DAT_DIR

    # If Package Directory doesn't exist, create it.
    [ ! -d "$SADM_PKG_DIR" ] && mkdir -p $SADM_PKG_DIR
    chmod 0775 $SADM_PKG_DIR
    chown ${SADM_USER}:${SADM_GROUP} $SADM_PKG_DIR

    # If SADM Server Web Site Directory doesn't exist, create it.
    if [ ! -d "$SADM_WWW_DIR" ] && [ "$(sadm_get_fqdn)" = "$SADM_SERVER" ] # Only on SADMIN Server
        then mkdir -p $SADM_WWW_DIR
             chmod 0775 $SADM_WWW_DIR
             chown ${SADM_WWW_USER}:${SADM_WWW_GROUP} $SADM_WWW_DIR
    fi

    # If SADM Server Web Site Data Directory doesn't exist, create it.
    if [ ! -d "$SADM_WWW_DAT_DIR" ] && [ "$(sadm_get_fqdn)" = "$SADM_SERVER" ]    
        then mkdir -p $SADM_WWW_DAT_DIR
             chmod 0775 $SADM_WWW_DAT_DIR  
             chown ${SADM_WWW_USER}:${SADM_WWW_GROUP} $SADM_WWW_DIR
    fi
    
    # If SADM Server Web Site HTML Directory doesn't exist, create it.
    if [ ! -d "$SADM_WWW_HTML_DIR" ] && [ "$(sadm_get_fqdn)" = "$SADM_SERVER" ]    
        then mkdir -p $SADM_WWW_HTML_DIR
             chmod 0775 $SADM_WWW_HTML_DIR  
             chown ${SADM_WWW_USER}:${SADM_WWW_GROUP} $SADM_WWW_HTML_DIR
    fi

    # If SADM Server Web Site LIB Directory doesn't exist, create it.
    if [ ! -d "$SADM_WWW_LIB_DIR" ] && [ "$(sadm_get_fqdn)" = "$SADM_SERVER" ]
        then mkdir -p $SADM_WWW_LIB_DIR
             chmod 0775 $SADM_WWW_LIB_DIR  
             chown ${SADM_WWW_USER}:${SADM_WWW_GROUP} $SADM_WWW_LIB_DIR
    fi


    # If SADM Server Web Site Images Directory doesn't exist, create it.
    if [ ! -d "$SADM_WWW_IMG_DIR" ] && [ "$(sadm_get_fqdn)" = "$SADM_SERVER" ]
        then mkdir -p $SADM_WWW_IMG_DIR
             chmod 0775 $SADM_WWW_IMG_DIR  
             chown ${SADM_WWW_USER}:${SADM_WWW_GROUP} $SADM_WWW_IMG_DIR
    fi

    # If NMON Directory doesn't exist, create it.
    [ ! -d "$SADM_NMON_DIR" ] && mkdir -p $SADM_NMON_DIR
    chmod 0775 $SADM_NMON_DIR
    chown ${SADM_USER}:${SADM_GROUP} $SADM_NMON_DIR

    # If Disaster Recovery Information Directory doesn't exist, create it.
    [ ! -d "$SADM_DR_DIR" ] && mkdir -p $SADM_DR_DIR
    chmod 0775 $SADM_DR_DIR
    chown ${SADM_USER}:${SADM_GROUP} $SADM_DR_DIR

    # If Network/Subnet Information Directory doesn't exist, create it.
    [ ! -d "$SADM_NET_DIR" ] && mkdir -p $SADM_NET_DIR
    chmod 0775 $SADM_NET_DIR
    chown ${SADM_USER}:${SADM_GROUP} $SADM_NET_DIR

    #If SADM Sysmon Report Directory doesn't exist, create it.
    [ ! -d "$SADM_RPT_DIR" ] && mkdir -p $SADM_RPT_DIR
    chmod 0775 $SADM_RPT_DIR
    chown ${SADM_USER}:${SADM_GROUP} $SADM_RPT_DIR

    # If Performance Server Data Directory doesn't exist, create it.
    [ ! -d "$SADM_SAR_DIR" ] && mkdir -p $SADM_SAR_DIR
    chmod 0775 $SADM_SAR_DIR
    chown ${SADM_USER}:${SADM_GROUP} $SADM_SAR_DIR

    # If Return Code History Directory doesn't exist, create it.
    [ ! -d "$SADM_RCH_DIR" ] && mkdir -p $SADM_RCH_DIR
    chmod 0775 $SADM_RCH_DIR
    chown ${SADM_USER}:${SADM_GROUP} $SADM_RCH_DIR

    # If user don't want to append to existing log - Clear it - Else we will append to it.
    if [ "$SADM_LOG_APPEND" != "Y" ] ; then echo " " > $SADM_LOG ; fi
    
    # If Return Code History Log doesn't exist, Create it and Make sure it have right permission
    [ ! -e "$SADM_RCHLOG" ] && touch $SADM_RCHLOG
    chmod 664 $SADM_RCHLOG
    chown ${SADM_USER}:${SADM_GROUP} ${SADM_RCHLOG}

    # Feed the Return Code History File stating the script is started
    SADM_STIME=`date "+%C%y.%m.%d %H:%M:%S"` ; export SADM_STIME
    echo "${SADM_HOSTNAME} $SADM_STIME .......... ........ ........ $SADM_INST 2" >>$SADM_RCHLOG
    
    # Write Starting Info in the Log
    sadm_writelog "${SADM_80_DASH}"
    sadm_writelog "Starting ${SADM_PN} V${SADM_VER} - SADM Lib. V${SADM_LIB_VER}"
    sadm_writelog "Server Name: $(sadm_get_fqdn) - Type: $(sadm_get_ostype)" 
    sadm_writelog "O/S: $(sadm_get_osname) $(sadm_get_osversion) - Code Name: $(sadm_get_oscodename)"
    sadm_writelog "${SADM_TWENTY_DASH}"
    sadm_writelog " "

    # If PID FIle exist and User want to run only 1 copy of the script - Abort Script
    if [ -e "${SADM_PID_FILE}" ] && [ "$SADM_MULTIPLE_EXEC" = "N" ]
       then sadm_writelog "Script is already running ... "
            sadm_writelog "PID File ${SADM_PID_FILE} exist ..."
            sadm_writelog "Will not launch a second copy of this script"
            DELETE_PID="N"                                              # No Dele PID Since running
            sadm_stop 1 
            exit 1
       else echo "$TPID" > $SADM_PID_FILE
    fi
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
    sadm_writelog " "                                                   # Blank Line
    sadm_writelog "${SADM_TWENTY_DASH}"                                 # 20 Dash Line
    sadm_writelog "Script return code is $SADM_EXIT_CODE"               # Final Exit Code to log
    
    # Get End time and Calculate Elapse Time
    sadm_end_time=`date "+%C%y.%m.%d %H:%M:%S"` ; export sadm_end_time  # Get & Format End Time
    sadm_elapse=`sadm_elapse_time "$sadm_end_time" "$SADM_STIME"`       # Get Elapse - End-Start
    sadm_writelog "Script execution time is $sadm_elapse"               # Log the Elapse Time

    # Append ending line to the [R]eturn [C]ode [H]istory File
    RCHLINE="${SADM_HOSTNAME} $SADM_STIME $sadm_end_time"               # Format Part1 of RCH File
    RCHLINE="$RCHLINE $sadm_elapse $SADM_INST $SADM_EXIT_CODE"          # Format Part2 of RCH File
    echo "$RCHLINE" >>$SADM_RCHLOG                                      # Append Line to  RCH File
    
    # Trim the RCH File based on Variable $SADM_MAX_RCLINE define in sadmin.cfg
    sadm_writelog "Trim History $SADM_RCHLOG to ${SADM_MAX_RCLINE} lines" # Advise of trimm value
    sadm_trimfile "$SADM_RCHLOG" "$SADM_MAX_RCLINE"                     # Trim file to Desired Nb.
    chmod 664 ${SADM_RCHLOG}                                            # Writable by O/G Readable W
    chown ${SADM_USER}:${SADM_GROUP} ${SADM_RCHLOG}                     # Change RCH file Owner

    # Write email choice in the log footer
    if [ "$SADM_MAIL" = "" ] ; then SADM_MAIL_TYPE=4 ; fi               # Mail not Install - no Mail
    case $SADM_MAIL_TYPE in
      0)  sadm_writelog "User requested no mail when script end (Fail or Success)"
          ;;
      1)  if [ "$SADM_EXIT_CODE" -ne 0 ]
             then sadm_writelog "User requested mail only if script fail - Will send mail"
             else sadm_writelog "User requested mail only if script fail - Will not send mail"
          fi
          ;;
      2)  if [ "$SADM_EXIT_CODE" -eq 0 ]
             then sadm_writelog "User requested mail only on Success of script - Will send mail"
             else sadm_writelog "User requested mail only on Success of script - Will not send mail"
          fi 
          ;;
      3)  sadm_writelog "User requested mail either Success or Error of script - Will send mail"
          ;;
      4)  sadm_writelog "No Mail can be send until the mail command is install"
          sadm_writelog "On CentOS/Red Hat/Fedora  - enter command 'yum -y mail'"
          sadm_writelog "On Ubuntu/Debian/Raspbian/LinuxMint - use 'apt-get install mailutils'"
          ;;
      *)  sadm_writelog "The SADM_MAIL_TYPE is not set properly - Should be between 0 and 3"
          sadm_writelog "It is now set to $SADM_MAIL_TYPE"
          ;;
    esac

    sadm_writelog "Trim log $SADM_LOG to ${SADM_MAX_LOGLINE} lines" # Inform user trimming 
    sadm_writelog "`date` - End of ${SADM_PN}"                          # Write End Time To Log
    sadm_writelog "${SADM_80_DASH}"                                  # Write 80 Dash Line
    sadm_writelog " "                                                   # Blank Line
    sadm_writelog " "                                                   # Blank Line
    sadm_writelog " "                                                   # Blank Line
    sadm_writelog " "                                                   # Blank Line
    
    # Maintain Script log at a reasonnable size specified in ${SADM_MAX_LOGLINE}
    cat $SADM_LOG > /dev/null                                           # Force buffer to flush
    sadm_trimfile "$SADM_LOG" "$SADM_MAX_LOGLINE"                       # Trim file to Desired Nb.
    chmod 664 ${SADM_LOG}                                               # Writable by O/G Readable W
    chown ${SADM_USER}:${SADM_GROUP} ${SADM_LOG}                        # Change RCH file Owner
    
    # Inform UnixAdmin By Email based on his selected choice
    case $SADM_MAIL_TYPE in
      1)  if [ "$SADM_EXIT_CODE" -ne 0 ] && [ "$SADM_MAIL" != "" ]      # Mail On Error Only
             then wsub="SADM : ERROR of $SADM_PN on ${SADM_HOSTNAME}"   # Format Mail Subject
                  cat $SADM_LOG | $SADM_MAIL -s "$wsub" $SADM_MAIL_ADDR # Send Email to SysAdmin
          fi
          ;;
      2)  if [ "$SADM_EXIT_CODE" -eq 0 ] && [ "$SADM_MAIL" != "" ]      # Mail On Success Only
             then wsub="SADM : SUCCESS of $SADM_PN on ${SADM_HOSTNAME}" # Format Mail Subject
                  cat $SADM_LOG | $SADM_MAIL -s "$wsub" $SADM_MAIL_ADDR # Send Email to SysAdmin
          fi 
          ;;
      3)  if [ "$SADM_EXIT_CODE" -eq 0 ] && [ "$SADM_MAIL" != "" ]      # Always mail
              then wsub="SADM : SUCCESS of $SADM_PN on ${SADM_HOSTNAME}" # Format Mail Subject
              else wsub="SADM : ERROR of $SADM_PN on ${SADM_HOSTNAME}"  # Format Mail Subject
          fi
          cat $SADM_LOG | $SADM_MAIL -s "$wsub" $SADM_MAIL_ADDR         # Send Email to SysAdmin
          ;;
    esac
    
    # Normally we Delete the PID File when exiting Script
    # But when script is already running (DELETE_PID is set to "N"),we don't want to delete PID file
    if ( [ -e "$SADM_PID_FILE"  ] && [ "$DELETE_PID" = "Y" ] )
        then rm -f $SADM_PID_FILE  >/dev/null 2>&1 
    fi

    # Delete Temporary files used
    if [ -e "$SADM_TMP_FILE1" ] ; then rm -f $SADM_TMP_FILE1 >/dev/null 2>&1 ; fi
    if [ -e "$SADM_TMP_FILE2" ] ; then rm -f $SADM_TMP_FILE2 >/dev/null 2>&1 ; fi
    if [ -e "$SADM_TMP_FILE3" ] ; then rm -f $SADM_TMP_FILE3 >/dev/null 2>&1 ; fi
    return $SADM_EXIT_CODE
}


# --------------------------------------------------------------------------------------------------
#                                THING TO DO WHEN FIRST CALLED
# --------------------------------------------------------------------------------------------------
#
    
    # Load SADMIN Configuration file
    sadm_load_config_file                                               # Load SADM cfg file

    # Make sure ALL basic requirement are met - If not then exit 1
    sadm_check_requirements                                             # Check Lib Requirements
    if [ $? -ne 0 ] ; then exit 1 ; fi                                  # If Requirement are not met
