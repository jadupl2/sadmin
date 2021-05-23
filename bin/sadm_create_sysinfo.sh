#! /usr/bin/env bash
# --------------------------------------------------------------------------------------------------
#   Author   :  Jacques Duplessis
#   Title    :  sadm_create_sysinfo.sh
#   Synopsis : .Run once a day to collect hardware & some software info of system (Use for DR)
#   Version  :  1.5
#   Date     :  13 November 2015
#   Requires :  sh
#
#
#   Note        :   All scripts (Shell,Python,php) and screen output are formatted to have and use
#                   a 100 characters per line. Comments in script always begin at column 73. You
#                   will have a better experience, if you set screen width to have at least 100 Chr.
#
# --------------------------------------------------------------------------------------------------
# Change Log
#
# 2016_08_08    v1.8 Added lsblk output to script
# 2016_12_03    v1.9 Replace lsblk by parted to output disk name and size
# 2016_12_09    v2.0 Added lsdev to PVS_FILE in Aix
# 2017_12_10    v2.1 Added field SADM_UPDATE_DATE to sysinfo.txt file
# 2017_12_12    v2.2 Corrected Problem related to vgs returned info (< sign return now)
# 2018_01_02    v2.3 Now put information in less files (disks, lvm and network file)
# 2018_01_03    v2.4 Added New system file output & add OSX Commands for Network,System & Disk Info.
# 2018_06_03    v2.5 Revisited and adapt to new Libr.
# 2018_06_09    v2.6 Add SADMIN root dir & Date/Status of last O/S Update in ${HOSTNAME}_sysinfo.txt
# 2018_06_11    v2.7 Change name to sadm_create_sysinfo.sh
# 2018_09_19    v2.8 Update Default Alert Group
# 2018_09_20    v2.9 Change Error Message when can't find last Update date in when RCH file missing
# 2018_10_02    v3.0 The O/S Update Status was not reported correctly (because of rch format change)
# 2018_10_20    v3.1 Show user what to do when can't get last O/S update date.
# 2018_10_21    v3.2 More info were added about the system and network in report file.
# 2018_11_07    v3.3 System Report show only last 10 booting date/time
# 2018_11_13    v3.4 Restructure script for Performance
# 2018_11_20    v3.5 Added some Aix lsattr command for system information.
# 2018_12_22    v3.6 Minor fix for MacOS
# 2019_01_01    Added: sadm_create_sysinfo v3.7 - Use scutil for more Network Info. on MacOS
# 2019_01_01    Added: sadm_create_sysinfo v3.8 - Use lshw to list Disks and Network Info on Linux.
# 2019_01_01    Added: sadm_create_sysinfo v3.9 - Use lsblk to list Disks Partitions and Filesystems
# 2019_01_01    Added: sadm_create_sysinfo v3.10 - Added lspci, lsscsi and create hardware html list
# 2019_01_28 Added: v3.11 Change Header of files produced by this script.
# 2019_03_17 Change: v3.12 PCI hardware list moved to end of system report file.
# 2019_07_07 Fix: v3.13 O/S Update was indicating 'Failed' when it should have been 'Success'.
# 2019_10_13 Update: v3.14 Collect Server Architecture to be store later on in Database.
# 2019_10_30 Update: v3.15 Remove utilization on 'facter' for collecting info (Not always available)
# 2019_11_22 Fix: v3.16 Problem with 'nmcli -t' on Ubuntu,Debian corrected.
# 2020_01_13 Update: v3.17 Collect 'rear' version to show on rear schedule web page.
# 2020_03_08 Update: v3.18 Collect more information about Disks, Partitions, Network and fix lsblk.
# 2020_04_05 Update: v3.19 Replace function sadm_writelog() with NL incl. by sadm_write() No NL Incl
# 2020_06_09 Update: v3.20 New log at each execution & log not trimmed anymore ($SADM_MAX_LOGLINE=0)
# 2020_12_12 Update: v3.21 Add SADM_PID_TIMEOUT and SADM_LOCK_TIMEOUT Variables.
#@2021_05_10 nolog: v3.22 Error message change "sadm_osupdate_farm.sh" to "sadm_osupdate_starter"
#@2021_05_22 Update: v3.23 Standardize command line options & Update SADMIN code section
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPTE LE ^C
#set -x




# ---------------------------------------------------------------------------------------
# SADMIN CODE SECTION 1.50
# Setup for Global Variables and load the SADMIN standard library.
# To use SADMIN tools, this section MUST be present near the top of your code.    
# ---------------------------------------------------------------------------------------

# MAKE SURE THE ENVIRONMENT 'SADMIN' VARIABLE IS DEFINED, IF NOT EXIT SCRIPT WITH ERROR.
if [ -z $SADMIN ] || [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]    
    then printf "\nPlease set 'SADMIN' environment variable to the install directory.\n"
         EE="/etc/environment" ; grep "SADMIN=" $EE >/dev/null 
         if [ $? -eq 0 ]                                   # Found SADMIN in /etc/env.
            then export SADMIN=`grep "SADMIN=" $EE |sed 's/export //g'|awk -F= '{print $2}'`
                 printf "'SADMIN' environment variable temporarily set to ${SADMIN}.\n"
            else exit 1                                    # No SADMIN Env. Var. Exit
         fi
fi 

# USE VARIABLES BELOW, BUT DON'T CHANGE THEM (Used by SADMIN Standard Library).
export SADM_PN=${0##*/}                                    # Script name(with extension)
export SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1`          # Script name(without extension)
export SADM_TPID="$$"                                      # Script Process ID.
export SADM_HOSTNAME=`hostname -s`                         # Host name without Domain Name
export SADM_OS_TYPE=`uname -s |tr '[:lower:]' '[:upper:]'` # Return LINUX,AIX,DARWIN,SUNOS 

# USE & CHANGE VARIABLES BELOW TO YOUR NEEDS (They influence execution of SADMIN Library).
export SADM_VER='3.23'                                     # Script Version
export SADM_EXIT_CODE=0                                    # Script Default Exit Code
export SADM_LOG_TYPE="B"                                   # Log [S]creen [L]og [B]oth
export SADM_LOG_APPEND="N"                                 # Y=AppendLog, N=CreateNewLog
export SADM_LOG_HEADER="Y"                                 # Y=ProduceLogHeader N=NoHeader
export SADM_LOG_FOOTER="Y"                                 # Y=IncludeFooter N=NoFooter
export SADM_MULTIPLE_EXEC="N"                              # Run Simultaneous copy ?
export SADM_PID_TIMEOUT=7200                               # Sec. before PID Lock expire
export SADM_LOCK_TIMEOUT=3600                              # Sec. before Del. LockFile
export SADM_USE_RCH="Y"                                    # Update RCH HistoryFile 
export SADM_DEBUG=0                                        # Debug Level(0-9) 0=NoDebug
export SADM_TMP_FILE1="${SADMIN}/tmp/${SADM_INST}_1.$$"    # Tmp File1 for you to use
export SADM_TMP_FILE2="${SADMIN}/tmp/${SADM_INST}_2.$$"    # Tmp File2 for you to use
export SADM_TMP_FILE3="${SADMIN}/tmp/${SADM_INST}_3.$$"    # Tmp File3 for you to use

# LOAD SADMIN SHELL LIBRARY AND SET SOME O/S VARIABLES.
. ${SADMIN}/lib/sadmlib_std.sh                             # LOAD SADMIN Shell Library
export SADM_OS_NAME=$(sadm_get_osname)                     # O/S Name in Uppercase
export SADM_OS_VERSION=$(sadm_get_osversion)               # O/S Full Ver.No. (ex: 9.0.1)
export SADM_OS_MAJORVER=$(sadm_get_osmajorversion)         # O/S Major Ver. No. (ex: 9)

# VALUES OF VARIABLES BELOW ARE LOADED FROM SADMIN CONFIG FILE ($SADMIN/cfg/sadmin.cfg)
# THEY CAN BE OVERRIDDEN HERE, ON A PER SCRIPT BASIS (IF NEEDED).
#export SADM_ALERT_TYPE=1                                   # 0=No 1=OnError 2=OnOK 3=Always
#export SADM_ALERT_GROUP="default"                          # Alert Group to advise
#export SADM_MAIL_ADDR="your_email@domain.com"              # Email to send log
export SADM_MAX_LOGLINE=0                                # Nb Lines to trim(0=NoTrim)
#export SADM_MAX_RCLINE=35                                  # Nb Lines to trim(0=NoTrim)
#export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} "   # SSH CMD to Access Server
# ---------------------------------------------------------------------------------------








#===================================================================================================
# Scripts Variables
#===================================================================================================
DASH_LINE=`printf %79s |tr " " "-"`             ; export DASH_LINE      # 79 minus sign line

# Name of all Output Files
HPREFIX="${SADM_DR_DIR}/$(sadm_get_hostname)"   ; export HPREFIX        # Output File Loc & Name
HWD_FILE="${HPREFIX}_sysinfo.txt"               ; export HWD_FILE       # Hardware File Info
PRTCONF_FILE="${HPREFIX}_prtconf.txt"           ; export PRTCONF_FILE   # prtconf output file
DISKS_FILE="${HPREFIX}_diskinfo.txt"            ; export DISKS_FILE     # disk Inofrmation File
LVM_FILE="${HPREFIX}_lvm.txt"                   ; export LVM_FILE       # lvm Information File
NET_FILE="${HPREFIX}_network.txt"               ; export NET_FILE       # Network Information File
SYSTEM_FILE="${HPREFIX}_system.txt"             ; export SYSTEM_FILE    # System Information File
LSHW_FILE="${HPREFIX}_lshw.html"                ; export LSHW_FILE      # System Hardware in HTML 

# Path to Command used in this Script
LVS=""                                          ; export LVS            # LV Summary Cmd with Path
LVSCAN=""                                       ; export LVSCAN         # LV Scan Cmd with Path
LVDISPLAY=""                                    ; export LVDISPLAY      # LV Display Cmd with Path
VGS=""                                          ; export VGS            # VG Summary Cmd with Path
VGSCAN=""                                       ; export VGSCAN         # VG Scan Cmd with Path
VGDISPLAY=""                                    ; export VGDISPLAY      # VG Display Cmd with Path
PVS=""                                          ; export PVS            # Physical Vol Cmd with Path
PVSCAN=""                                       ; export PVSCAN         # PV Scan Cmd with Path
PVDISPLAY=""                                    ; export PVDISPLAY      # PV Display Cmd with Path
NETSTAT=""                                      ; export NETSTAT        # netstat Cmd with Path
IP=""                                           ; export IP             # ip Cmd with Path
DF=""                                           ; export DF             # df Cmd with Path
IFCONFIG=""                                     ; export IFCONFIG       # ifconfig Cmd with Path
DMIDECODE=""                                    ; export DMIDECODE      # dmidecode Cmd with Path
SADM_CPATH=""                                   ; export SADM_CPATH     # Tmp Var Store Cmd Path
LSBLK=""                                        ; export LSBLK          # lsblk Cmd Path
BLKID=""                                        ; export BLKID          # blkid Cmd Path
HWINFO=""                                       ; export HWINFO         # hwinfo Cmd Path
LSVG=""                                         ; export LSVG           # Aix LSVG Command Path
LSPV=""                                         ; export LSPV           # Aix LSPV Command Path
PRTCONF=""                                      ; export PRTCONF        # Aix Print Config Cmd
DISKUTIL=""                                     ; export DISKUTIL       # OSX Diskutil command
NETWORKSETUP=""                                 ; export NETWORKSETUP   # OSX networksetup command
HOSTINFO=""                                     ; export HOSTINFO       # OSX hostinfo command
SWVERS=""                                       ; export SWVERS         # OSX sw_vers Command
SYSTEMPROFILER=""                               ; export SYSTEMPROFILER # OSX system_profiler Cmd.
IPCONFIG=""                                     ; export IPCONFIG       # OSX ipconfig Cmd.
LSHW=""                                         ; export LSHW           # Linux List Hardware (lshw)
NMCLI=""                                        ; export NMCLI          # Linux Network Manager CLI
HOSTNAMECTL=""                                  ; export HOSTNAMECTL    # Linux HostNameCTL Command
OSUPDATE_DATE=""                                ; export OSUPDATE_DATE  # Date of Last O/S Update
OSUPDATE_STATUS=""                              ; export OSUPDATE_STATUS # Status (S,F,R) O/S Update
LSBRELEASE=""                                   ; export LSBRELEASE     # lsb_release Location
MIITOOL=""                                      ; export MIITOOL        # mii-tool command location
ETHTOOL=""                                      ; export ETHTOOL        # ethtool command location
UNAME=""                                        ; export UNAME          # uname  command location
UPTIME=""                                       ; export UPTIME         # uptime command location
LAST=""                                         ; export LAST           # last command location
LSATTR=""                                       ; export LSATTR         # lsattr command location
SYSCTL=""                                       ; export SYSCTL         # sysctl command location
SCUTIL=""                                       ; export SCUTIL         # MacOS to list DNS Param.
LSSCSI=""                                       ; export LSSCSI         # List SCSI Device Info.
LSPCI=""                                        ; export LSPCI          # List PCI Components

# --------------------------------------------------------------------------------------------------
#       H E L P      U S A G E   A N D     V E R S I O N     D I S P L A Y    F U N C T I O N
# --------------------------------------------------------------------------------------------------
show_usage()
{
    printf "\n${SADM_PN} usage :"
    printf "\n\t-d   (Debug Level [0-9])"
    printf "\n\t-h   (Display this help message)"
    printf "\n\t-v   (Show Script Version Info)"
    printf "\n\n"
}




# ==================================================================================================
# Check if the package name received as parameter is available on the server
#   - If command is found, $SADM_CPATH is set to full command path (return 0)
#   - If command is not found, $SADM_CPATH is set empty "" (return 1)
# ==================================================================================================
#
command_available()
{
    SADM_PKG=$1

    # Check if only one parameter was received and if parameter is not empty
    #-----------------------------------------------------------------------------------------------
    if [ $# -ne 1 ] || [ -z "$SADM_PKG" ]
        then sadm_write "$SADM_ERROR : Invalid parameter received by command_available function\n"
             sadm_write "        Parameter received = $* \n"
             sadm_write "        Please correct error in the script.\n"
             return 1
    fi


    # Check if command can be located and set SADM_CPATH accordingly
    #-----------------------------------------------------------------------------------------------
    SADM_CPATH=`which $SADM_PKG > /dev/null 2>&1`
    if [ $? -eq 0 ]
        then SADM_CPATH=`$SADM_WHICH $SADM_PKG`
        else SADM_CPATH=""
    fi
    export SADM_CPATH

    # If SADM_DEBUG is activated then display Package Name and Full path to it
    #-----------------------------------------------------------------------------------------------
    if [ $SADM_DEBUG -gt 0 ]
        then if [ ! -z $SADM_CPATH ]
                then SADM_MSG=`printf "%-10s %-15s : %-30s" "[OK]" "$SADM_PKG" "$SADM_CPATH"`
                else SADM_MSG=`printf "%-10s %-15s : %-30s" "[NA]" "$SADM_PKG" "Not Found"`
             fi
             sadm_write "${SADM_MSG}\n"
    fi

    # If Package was located return 0 else return 1
    #-----------------------------------------------------------------------------------------------
    if [ -z "$SADM_CPATH" ] ; then return 1 ; else return 0 ; fi
}


# ==================================================================================================
#     - Set command path used in the script (Some path are different on some RHEL Version)
#     - Check if Input exist and is readable
# ==================================================================================================
#
pre_validation()
{
    sadm_write "Verifying command availability ...\n"

    # The which command is needed to determine presence of command - Return Error if not found
    #-----------------------------------------------------------------------------------------------
    if ! which which >/dev/null 2>&1
        then sadm_write "The command 'which' isn't available - Install it and rerun this script.\n"
             return 1
    fi

    # Check the availibility of some commands that will be used in this script
    # If command is found the uppercase command variable is set to full command path
    # If command isn't found the uppercase command variable is set nothing
    #-----------------------------------------------------------------------------------------------
    if [ "$SADM_OS_TYPE"  = "AIX" ]
        then    command_available "lspv"        ; LSPV=$SADM_CPATH      # Cmd Path or Blank !found
                command_available "lsvg"        ; LSVG=$SADM_CPATH      # Cmd Path or Blank !found
                command_available "lsattr"      ; LSATTR=$SADM_CPATH    # Cmd Path or Blank !found
                command_available "prtconf"     ; PRTCONF=$SADM_CPATH   # Cmd Path or Blank !found
        else    command_available "lvs"         ; LVS=$SADM_CPATH       # Cmd Path or Blank !found
                command_available "lvscan"      ; LVSCAN=$SADM_CPATH    # Cmd Path or Blank !found
                command_available "lvdisplay"   ; LVDISPLAY=$SADM_CPATH # Cmd Path or Blank !found
                command_available "vgs"         ; VGS=$SADM_CPATH       # Cmd Path or Blank !found
                command_available "vgscan"      ; VGSCAN=$SADM_CPATH    # Cmd Path or Blank !found
                command_available "vgdisplay"   ; VGDISPLAY=$SADM_CPATH # Cmd Path or Blank !found
                command_available "pvs"         ; PVS=$SADM_CPATH       # Cmd Path or Blank !found
                command_available "pvscan"      ; PVSCAN=$SADM_CPATH    # Cmd Path or Blank !found
                command_available "pvdisplay"   ; PVDISPLAY=$SADM_CPATH # Cmd Path or Blank !found
                command_available "ip"          ; IP=$SADM_CPATH        # Cmd Path or Blank !found
                command_available "dmidecode"   ; DMIDECODE=$SADM_CPATH # Cmd Path or Blank !found
                command_available "lsblk"       ; LSBLK=$SADM_CPATH     # Cmd Path or Blank !found
                command_available "blkid"       ; BLKID=$SADM_CPATH     # Cmd Path or Blank !found
                command_available "hwinfo"      ; HWINFO=$SADM_CPATH    # Cmd Path or Blank !found
                command_available "diskutil"    ; DISKUTIL=$SADM_CPATH  # Cmd Path or Blank !found
                command_available "networksetup" ; NETWORKSETUP=$SADM_CPATH  # NetworkSetup Cmd Path
                command_available "hostinfo"    ; HOSTINFO=$SADM_CPATH  # HostInfo Cmd Path
                command_available "sw_vers"     ; SWVERS=$SADM_CPATH    # sw_ver Cmd Path
                command_available "system_profiler" ; SYSTEMPROFILER=$SADM_CPATH # Profiler Cmd Path
                command_available "ipconfig"    ; IPCONFIG=$SADM_CPATH  # ipconfig Cmd Path
                command_available "lshw"        ; LSHW=$SADM_CPATH      # lshw Cmd Path
                command_available "nmcli"       ; NMCLI=$SADM_CPATH     # nmcli Cmd Path
                command_available "hostnamectl" ; HOSTNAMECTL=$SADM_CPATH   # hostnamectl Cmd Path
                command_available "lsb_release" ; LSBRELEASE=$SADM_CPATH    # lsb_release Cmd Path
                command_available "mii-tool"    ; MIITOOL=$SADM_CPATH   # mii-tool Cmd Path
                command_available "ethtool"     ; ETHTOOL=$SADM_CPATH   # ethtool Cmd Path
                command_available "sysctl"      ; SYSCTL=$SADM_CPATH    # Cmd Path or Blank !found
                command_available "scutil"      ; SCUTIL=$SADM_CPATH    # CmdPath="" if not found
                command_available "lsscsi"      ; LSSCSI=$SADM_CPATH    # CmdPath="" if not found
                command_available "rear"        ; REAR=$SADM_CPATH      # CmdPath="" if not found
                command_available "lspci"       ; LSPCI=$SADM_CPATH     # CmdPath="" if not found
    fi

    # Aix, Linux and MacOS Common Commands
    command_available "df"          ; DF=$SADM_CPATH                    # Cmd Path or Blank !found
    command_available "netstat"     ; NETSTAT=$SADM_CPATH               # Cmd Path or Blank !found
    command_available "ifconfig"    ; IFCONFIG=$SADM_CPATH              # Cmd Path or Blank !found
    command_available "uname"       ; UNAME=$SADM_CPATH                 # Cmd Path or Blank !found
    command_available "uptime"      ; UPTIME=$SADM_CPATH                # Cmd Path or Blank !found
    command_available "last"        ; LAST=$SADM_CPATH                  # Cmd Path or Blank !found

    return 0
}



# ==================================================================================================
#       First parameter is the command name to run (Example 'pvscan')
#       Second parameter is the fully qualified command name (Example '/sbin/pvscan')
#       Third paramter is the name of the ouput file
# ==================================================================================================
write_file_header()
{
    SOSNAME="$SADM_OS_NAME" ; SOSVER="$SADM_OS_MAJORVER"
    WTITLE=$1
    WFILE=$2
    echo "# ${SADM_DASH}"       >$WFILE 2>&1
    echo "# SADMIN Release $(sadm_get_release) - $SADM_PN v$SADM_VER" >>$WFILE 2>&1
    echo "# $SADM_CIE_NAME - `date`"                 >>$WFILE 2>&1
    echo "# $WTITLE on $(sadm_get_fqdn) - $SOSNAME V${SOSVER}" >>$WFILE
    echo "# ${SADM_DASH}"                             >>$WFILE 2>&1
    echo "#"                                         >>$WFILE 2>&1
}


# ==================================================================================================
#       First parameter is the command name to run (Example 'pvscan')
#       Second parameter is the fully qualified command name (Example '/sbin/pvscan')
#       Third paramter is the name of the ouput file
# ==================================================================================================
create_command_output()
{
    SCMD_NAME=$1 ; SCMD_PATH=$2 ; SCMD_TXT=$3
    if [ ! -z "$SCMD_PATH" ]
        then sadm_write "Creating $SCMD_TXT ...\n"
             write_file_header "$SCMD_NAME" "$SCMD_TXT"
             $SCMD_PATH >> $SCMD_TXT 2>&1
        else sadm_write "The command $SCMD_NAME is not available.\n"
             write_file_header "$SCMD_NAME" "$SCMD_TXT"
    fi
    chown ${SADM_USER}:${SADM_GROUP} ${SCMD_TXT}
}


# ==================================================================================================
#       This function get the last o/s update date and status from the rch file
# ==================================================================================================
# 
# Example of content for input file :
# yoda 2019.07.02 11:33:38 2019.07.02 11:34:29 00:00:51 sadm_osupdate default 1 0
# yoda 2019.07.03 02:05:06 2019.07.03 02:05:34 00:00:28 sadm_osupdate default 1 0

# ==================================================================================================
set_last_osupdate_date()
{

    # Verify if the o/s update rch file exist
    RCHFILE="${SADM_RCH_DIR}/$(sadm_get_hostname)_sadm_osupdate.rch"
    if [ ! -r "$RCHFILE" ]
        then sadm_write "\nMissing O/S Update RCH file ($RCHFILE).\n"
             sadm_write "Can't determine last O/S Update Date/Time & Status.\n"
             sadm_write "Situation will resolve by itself, when you run your first O/S update for this system\n."
             sadm_write "You can run 'sadm_osupdate_starter.sh $(sadm_get_hostname)' on $SADM_SERVER to update this system.\n"
             sadm_write "You will then get a valid 'rch' file.\n\n"
             OSUPDATE_DATE=""
             OSUPDATE_STATUS="U"
             return 1
    fi

    # Get Last Update Date from Return History File
    sadm_write "Getting last O/S Update date from $RCHFILE ...\n"
    OSUPDATE_DATE=`tail -1 ${RCHFILE} |awk '{printf "%s %s", $4,$5}'`
    if [ $? -ne 0 ]
        then sadm_write "Can't determine last O/S Update Date ...\n"
             sadm_write "You should run 'sadm_osupdate_starter.sh $(sadm_get_hostname)' on $SADM_SERVER to update this server.\n"
             sadm_write "You will then get a valid 'rch' file ${RCHFILE}.\n\n"
             return 1
    fi

    # Get the Status of the last O/S update
    RCH_CODE=`tail -1 ${RCHFILE} |awk '{printf "%s", $NF}'`
    if [ $? -ne 0 ]
        then sadm_write "Can't determine last O/S Update Status ...\n"
             return 1
    fi
    case "$RCH_CODE" in
        0)  OSUPDATE_STATUS="S"
            ;;
        1)  OSUPDATE_STATUS="F"
            ;;
        2)  OSUPDATE_STATUS="R"
            ;;
      "*")  OSUPDATE_STATUS="U"
            ;;
    esac
    return 0
}

# ==================================================================================================
#               Print File Received (P1) to file received (P2)
# ==================================================================================================
print_file ()
{
    # Parameters received should always by two - If not write error to log and return to caller
    if [ $# -ne 2 ]
        then sadm_write "${SADM_ERROR} : Function ${FUNCNAME[0]} didn't receive 2 parameters.\n"
             sadm_write "Function received $* and this isn't valid\n"
             return 1
    fi

    wfile=$1                                                            # What file to print
    wout=$2                                                             # Where to print the file

    # Check if file to print is readable
    if [ ! -r $wfile ]                                                  # If file not readable
        then sadm_write "File to print '$wfile' can be found.\n"        # Inform User
             return 1
    fi

    echo " " >> $wout
    echo "#${DASH_LINE}"  >> $wout
    echo "# File: $wfile " >> $wout                                      # Include name of the file
    echo "#${DASH_LINE}"  >> $wout
    grep -Evi "^#|^$" $wfile >> $wout                                    # Output file to Desire file
    return 0
}


# ==================================================================================================
# Execute command at write output to report file.
# Param #1 : Command to execute
# PAram #2 : Output Report File Name
# ==================================================================================================
execute_command()
{
    # Validate number of Parameters Received
    if [ $# -ne 2 ]
        then sadm_write "$SADM_ERROR Function ${FUNCNAME[0]} didn't receive 2 parameters.\n"
             sadm_write "Function received $* and this isn't valid.\n"
             return 1
    fi 

    ECMD=$1                                                             # Command to Execute
    EFILE=$2                                                            # Output Report File Name

    echo "#"                        >> $EFILE
    echo "#${DASH_LINE}"            >> $EFILE
    echo "# Command: $ECMD"         >> $EFILE
    if [ $SADM_DEBUG -gt 4 ] ;then echo "Command executed is ${ECMD}." ; fi
    echo "#${DASH_LINE}"            >> $EFILE
    echo "#"                        >> $EFILE
    eval $ECMD                      >> $EFILE 2>&1
    echo "#"                        >> $EFILE
    return 0
}

# ==================================================================================================
#               Create Misc. Linux config file for Disaster Recovery Purpose
# ==================================================================================================
create_linux_config_files()
{

    # Collect Disk Information ---------------------------------------------------------------------
    write_file_header "Disks Information" "$DISKS_FILE"
    sadm_write "Creating $DISKS_FILE ...\n"

    if [ "$HWINFO" != "" ]
        then CMD="hwinfo --block --short"
             execute_command "$CMD" "$DISKS_FILE" 
    fi

    if [ "$DF" != "" ]
        then CMD="df -hP"
             execute_command "$CMD" "$DISKS_FILE" 
    fi

    if [ "$LSBLK" != "" ] 
        then CMD="$LSBLK" 
             execute_command "$CMD" "$DISKS_FILE" 
             CMD="$LSBLK -f" 
             execute_command "$CMD" "$DISKS_FILE" 
    fi

    if [ "$BLKID" != "" ]
        then CMD="blkid"
             execute_command "$CMD" "$DISKS_FILE" 
    fi


    if [ "$SADM_PARTED" != "" ]
        then CMD="$SADM_PARTED -l | grep '^Disk' | grep -vE 'mapper|Disk Flags:'"
             execute_command "$CMD" "$DISKS_FILE" 
    fi


    if [ "$SADM_OS_TYPE"  = "DARWIN" ]                                # If running in OSX
        then if [ "$DISKUTIL" != "" ]
                then CMD="$DISKUTIL list"
                     execute_command "$CMD" "$DISKS_FILE" 
             fi
    fi

    # List Disks Name, Size, Manufacturer, Serial, Model, ...
    if [ "$LSHW" != "" ]
        then CMD="$LSHW -C disk | grep -Ei 'product|vendor|physical|logical name|size:'"
             execute_command "$CMD" "$DISKS_FILE" 
    fi


    # Collect LVM Information ----------------------------------------------------------------------
    write_file_header "Logical Volume" "$LVM_FILE"
    sadm_write "Creating $LVM_FILE ...\n"
    if [ "$PVS"       != "" ] ; then CMD="$PVS"       ; execute_command "$CMD" "$LVM_FILE" ; fi
    if [ "$PVSCAN"    != "" ] ; then CMD="$PVSCAN"    ; execute_command "$CMD" "$LVM_FILE" ; fi
    if [ "$PVDISPLAY" != "" ] ; then CMD="$PVDISPLAY" ; execute_command "$CMD" "$LVM_FILE" ; fi
    if [ "$VGS"       != "" ] ; then CMD="$VGS"       ; execute_command "$CMD" "$LVM_FILE" ; fi
    if [ "$VGSCAN"    != "" ] ; then CMD="$VGSCAN"    ; execute_command "$CMD" "$LVM_FILE" ; fi
    if [ "$VGDISPLAY" != "" ] ; then CMD="$VGDISPLAY" ; execute_command "$CMD" "$LVM_FILE" ; fi
    if [ "$LVS"       != "" ] ; then CMD="$LVS"       ; execute_command "$CMD" "$LVM_FILE" ; fi
    if [ "$LVSCAN"    != "" ] ; then CMD="$LVSCAN"    ; execute_command "$CMD" "$LVM_FILE" ; fi
    if [ "$LVDISPLAY" != "" ] ; then CMD="$LVDISPLAY" ; execute_command "$CMD" "$LVM_FILE" ; fi


    # Collect Network Information ------------------------------------------------------------------
    write_file_header "Network Information" "$NET_FILE"
    sadm_write "Creating $NET_FILE ...\n"

    if [ -d "/sys/class/net" ] && [ "$MIITOOL" != "" ]
        then for w in `ls -1 /sys/class/net  --color=never | grep -v "^lo"`
                do
                CMD="$MIITOOL $w 2>/dev/null" 
                execute_command "$CMD" "$NET_FILE"
                done
    fi

    if [ -d "/sys/class/net" ] && [ "$ETHTOOL" != "" ]
        then for w in `ls -1 /sys/class/net  --color=never | grep -v "^lo"`
                do
                CMD="$ETHTOOL $w" 
                execute_command "$CMD" "$NET_FILE"
                done
    fi

    if [ "$NMCLI" != "" ]
        then for w in `$NMCLI --terse --fields DEVICE device | awk -F: '{ print $1 }'| grep -v lo `
                do
                CMD="$NMCLI device show $w"
                execute_command "$CMD" "$NET_FILE" 
                CMD="$NMCLI -p -f general device show $w"
                execute_command "$CMD" "$NET_FILE"
                done
             CMD="$NMCLI dev status"
             execute_command "$CMD" "$NET_FILE"
    fi

    if [ "$IP" != "" ]
        then CMD="$IP addr"
             execute_command "$CMD" "$NET_FILE" 
    fi

    if [ "$IFCONFIG" != "" ]
        then CMD="$IFCONFIG -a"
             execute_command "$CMD" "$NET_FILE" 
    fi

    if [ "$NETSTAT" != "" ]
        then CMD="$NETSTAT -rn"
             execute_command "$CMD" "$NET_FILE" 
    fi

    # MacOS Network Information
    if [ "$NETWORKSETUP" != "" ]                            
        then CMD="$NETWORKSETUP -listallhardwareports "
             execute_command "$CMD" "$NET_FILE" 
    fi

    # MacOS List Ethernet Interface and IP
    if [ "$SCUTIL" != "" ]                            
        then CMD="$SCUTIL --nwi "
             execute_command "$CMD" "$NET_FILE" 
    fi

    # MacOS DNS Info
    if [ "$SCUTIL" != "" ]                            
        then CMD="$SCUTIL --dns "
             execute_command "$CMD" "$NET_FILE" 
    fi

    # Linux Network Device Info (Speed,Mac,IPAddr,Vendor,...)
    if [ "$LSHW" != "" ]                            
        then CMD="$LSHW -C network"
             execute_command "$CMD" "$NET_FILE" 
    fi

    # Networdk Card Information 
    if [ "$HWINFO" != "" ]
        then CMD="hwinfo --netcard | grep -Ei 'model|driver'"
             execute_command "$CMD" "$NET_FILE" 
    fi


    # Network Device information
    if [ "$IPCONFIG" != "" ]
        then FirstTime=0 ; index=0
             while [ $index -le 10 ]                                    # Process from en0 to en9
                do
                $IPCONFIG getpacket en${index} >/dev/null 2>&1          # Get Info about Interface
                if [ $? -eq 0 ]                                         # If Device in use
                    then CMD="$IPCONFIG getpacket en${index}"
                         execute_command "$CMD" "$NET_FILE"
                fi
                index=$((index + 1))
                done
    fi

    if [ -d "/etc/sysconfig/network-scripts" ]
        then for xfile in `ls -1 /etc/sysconfig/network-scripts/ifcfg*`
                do
                if [ "$xfile" != "/etc/sysconfig/network-scripts/ifcfg-lo" ]
                    then print_file "$xfile" "$NET_FILE"
                fi
                done
    fi
    
    if [ -r '/etc/network/interfaces' ] ; then print_file "/etc/network/interfaces" "$NET_FILE" ; fi
    if [ -r '/etc/hosts' ]              ; then print_file "/etc/hosts"              "$NET_FILE" ; fi
    if [ -r '/etc/resolv.conf' ]        ; then print_file "/etc/resolv.conf"        "$NET_FILE" ; fi
    if [ -r '/etc/host.conf' ]          ; then print_file "/etc/host.conf"          "$NET_FILE" ; fi
    if [ -r '/etc/ssh.conf' ]           ; then print_file "/etc/ssh.conf"           "$NET_FILE" ; fi
    if [ -r '/etc/sshd.conf' ]          ; then print_file "/etc/sshd.conf"          "$NET_FILE" ; fi
    if [ -r '/etc/ntp.conf' ]           ; then print_file "/etc/ntp.conf"           "$NET_FILE" ; fi


    # Collect System Information -------------------------------------------------------------------
    write_file_header "System Information" "$SYSTEM_FILE"
    sadm_write "Creating $SYSTEM_FILE ...\n"

    if [ "$UNAME" != "" ]
        then CMD="$UNAME -a"
             execute_command "$CMD" "$SYSTEM_FILE" 
    fi

    if [ "$UPTIME" != "" ]
        then CMD="$UPTIME"
             execute_command "$CMD" "$SYSTEM_FILE" 
    fi

    if [ "$LAST" != "" ]
        then CMD="$LAST | grep -i boot | head -10 | nl" 
             execute_command "$CMD" "$SYSTEM_FILE" 
    fi

    if [ "$HOSTINFO" != "" ]
        then CMD="$HOSTINFO"
             execute_command "$CMD" "$SYSTEM_FILE" 
    fi

    if [ "$SWVERS" != "" ]
        then CMD="$SWVERS"
             execute_command "$CMD" "$SYSTEM_FILE" 
    fi

    if [ "$LSHW" != "" ]
        then CMD="$LSHW -C system"
             execute_command "$CMD" "$SYSTEM_FILE" 
    fi

    if [ "$LSBRELEASE" != "" ]
        then CMD="$LSBRELEASE -a"
             execute_command "$CMD" "$SYSTEM_FILE" 
    fi

    if [ "$SYSTEMPROFILER" != "" ]
        then CMD="$SYSTEMPROFILER SPSoftwareDataType"
             execute_command "$CMD" "$SYSTEM_FILE" 
    fi

    if [ "$HOSTNAMECTL" != "" ]
        then CMD="$HOSTNAMECTL"
             execute_command "$CMD" "$SYSTEM_FILE" 
    fi

    if [ "$LSHW" != "" ]
        then CMD="$LSHW -short"
             execute_command "$CMD" "$SYSTEM_FILE" 
    fi

    if [ "$LSPCI" != "" ]
        then CMD="$LSPCI -k 2>/dev/null"
             execute_command "$CMD" "$SYSTEM_FILE" 
    fi
    
    # Create List of Hardware in HTML
    if [ "$LSHW" != "" ]
        then sadm_write "Creating $LSHW_FILE ...\n"
             $LSHW -html > $LSHW_FILE                                   # Create Hardware HTML File
    fi

}


# ==================================================================================================
#                 Create Misc. AIX config file for Disaster Recovery Purpose
# ==================================================================================================
create_aix_config_files()
{
    if [ "$PRTCONF" != "" ] ; then create_command_output "prtconf" "$PRTCONF" "$SYSTEM_FILE"  ; fi

    # Collect Disk Information ---------------------------------------------------------------------
    write_file_header "Disks Information" "$DISKS_FILE"
    sadm_write "Creating $DISKS_FILE ...\n"

    if [ "$DF" != "" ]
        then CMD="$DF -m"
             execute_command "$CMD" "$DISKS_FILE" 
    fi

    # List SCSI Devices, Queue_Depth, Timeout, ...
    if [ "$LSSCSI" != "" ]
        then CMD="$LSSCSI -L"
             execute_command "$CMD" "$DISKS_FILE" 
             CMD="$LSSCSI -lsd"
             execute_command "$CMD" "$DISKS_FILE" 
    fi

    if [ "$LSPV" != "" ]
        then CMD="$LSPV"
             execute_command "$CMD" "$DISKS_FILE" 
             $LSPV | awk '{ print $1 }' | while read PV
                do
                CMD="$LSPV $PV"
                execute_command "$CMD" "$DISKS_FILE" 
                done
            CMD="lsdev -Cc disk"
            execute_command "$CMD" "$DISKS_FILE" 
    fi

    # Collect LVM Information ----------------------------------------------------------------------
    write_file_header "Logical Volume" "$LVM_FILE"
    sadm_write "Creating $LVM_FILE ...\n"
    
    if [ "$LSVG" != "" ]
        then CMD="lsvg"
             execute_command "$CMD" "$LVM_FILE" 
             CMD="lsvg -o | lsvg -i"
             execute_command "$CMD" "$LVM_FILE" 
             CMD="$LSVG | xargs $LSVG -l "
             execute_command "$CMD" "$LVM_FILE" 
    fi


    # Collect Network Information ------------------------------------------------------------------
    write_file_header "Network Information" "$NET_FILE"
    sadm_write "Creating $NET_FILE ...\n"

    if [ "$IFCONFIG" != "" ]
        then CMD="$IFCONFIG -a"
             execute_command "$CMD" "$NET_FILE" 
    fi

    if [ "$NETSTAT" != "" ]
        then CMD="$NETSTAT -rn"
             execute_command "$CMD" "$NET_FILE" 
    fi


    # Collect System Information -------------------------------------------------------------------
    if [ "$LSATTR" != "" ]
        then CMD="$LSATTR -El sys0 -a realmem"
             execute_command "$CMD" "$SYSTEM_FILE" 
    fi

    if [ "$LSATTR" != "" ]
        then CMD="$LSATTR -E -l sys0"
             execute_command "$CMD" "$SYSTEM_FILE" 
    fi

    
}


# ==================================================================================================
#        C R E A T E     S E R V E R    C O N F I G U R A T I O N    S U M M A R Y   F I L E
# ==================================================================================================
create_summary_file()
{

    sadm_write "Creating $HWD_FILE ...\n"
    echo "# $SADM_CIE_NAME - SysInfo Report File - `date`"                           >  $HWD_FILE
    echo "# This file is use to update the SADMIN server inventory."                 >> $HWD_FILE
    echo "#                                                    "                     >> $HWD_FILE

    if [ "$SADM_OS_TYPE"  = "LINUX" ]                                   # O/S Upd RCH Only on Linux
        then set_last_osupdate_date                                     # Get Last O/S Update Date
             if [ $? -ne 0 ] ; then SADM_EXIT_CODE=0 ; fi               # Don't signal an error
        else OSUPDATE_DATE=""                                           # For Mac & Aix 
             OSUPDATE_STATUS="U"                                        # Status Unknown
    fi 

    echo "SADM_OS_TYPE                          = $(sadm_get_ostype)"                >> $HWD_FILE
    echo "SADM_UPDATE_DATE                      = $(date "+%Y-%m-%d %H:%M:%S")"      >> $HWD_FILE
    echo "SADM_HOSTNAME                         = $(sadm_get_hostname)"              >> $HWD_FILE
    echo "SADM_DOMAINNAME                       = $(sadm_get_domainname)"            >> $HWD_FILE
    echo "SADM_HOST_IP                          = $(sadm_get_host_ip)"               >> $HWD_FILE
    echo "SADM_SERVER_TYPE [V]irtual [P]hysical = $(sadm_server_type)"               >> $HWD_FILE
    echo "SADM_OS_VERSION                       = $(sadm_get_osversion)"             >> $HWD_FILE
    echo "SADM_OS_MAJOR_VERSION                 = $(sadm_get_osmajorversion)"        >> $HWD_FILE
    echo "SADM_OS_NAME                          = $(sadm_get_osname)"                >> $HWD_FILE
    echo "SADM_OS_CODE_NAME                     = $(sadm_get_oscodename)"            >> $HWD_FILE
    echo "SADM_KERNEL_VERSION                   = $(sadm_get_kernel_version)"        >> $HWD_FILE
    echo "SADM_KERNEL_BITMODE (32 or 64)        = $(sadm_get_kernel_bitmode)"        >> $HWD_FILE
    echo "SADM_SERVER_MODEL                     = $(sadm_server_model)"              >> $HWD_FILE
    echo "SADM_SERVER_SERIAL                    = $(sadm_server_serial)"             >> $HWD_FILE
    echo "SADM_SERVER_MEMORY (in MB)            = $(sadm_server_memory)"             >> $HWD_FILE
    echo "SADM_SERVER_HARDWARE_BITMODE          = $(sadm_server_hardware_bitmode)"   >> $HWD_FILE
    echo "SADM_SERVER_NB_CPU                    = $(sadm_server_nb_cpu)"             >> $HWD_FILE
    echo "SADM_SERVER_CPU_SPEED (in MHz)        = $(sadm_server_cpu_speed)"          >> $HWD_FILE
    echo "SADM_SERVER_ARCH                      = $(sadm_server_arch)"               >> $HWD_FILE
    echo "SADM_SERVER_NB_SOCKET                 = $(sadm_server_nb_socket)"          >> $HWD_FILE
    echo "SADM_SERVER_CORE_PER_SOCKET           = $(sadm_server_core_per_socket)"    >> $HWD_FILE
    echo "SADM_SERVER_THREAD_PER_CORE           = $(sadm_server_thread_per_core)"    >> $HWD_FILE
    echo "SADM_SERVER_IPS                       = $(sadm_server_ips)"                >> $HWD_FILE
    echo "SADM_SERVER_DISKS (Size in MB)        = $(sadm_server_disks)"              >> $HWD_FILE
    echo "SADM_SERVER_VG(s) (Size in MB)        = $(sadm_server_vg)"                 >> $HWD_FILE
    echo "SADM_OSUPDATE_DATE                    = ${OSUPDATE_DATE}"                  >> $HWD_FILE
    echo "SADM_OSUPDATE_STATUS                  = ${OSUPDATE_STATUS}"                >> $HWD_FILE
    echo "SADM_ROOT_DIRECTORY                   = ${SADMIN}"                         >> $HWD_FILE
    if [ "$REAR" != "" ] ;then REAR_VER=`$REAR -V | awk '{print $2}'` ; else REAR_VER="N/A" ; fi
    echo "SADM_REAR_VERSION                     = $REAR_VER"                         >> $HWD_FILE

    return $SADM_EXIT_CODE
}




# --------------------------------------------------------------------------------------------------
# Command line Options functions
# Evaluate Command Line Switch Options Upfront
# By Default (-h) Show Help Usage, (-v) Show Script Version,(-d0-9] Set Debug Level 
# --------------------------------------------------------------------------------------------------
function cmd_options()
{
    while getopts "d:hv" opt ; do                                       # Loop to process Switch
        case $opt in
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
           \?) printf "\nInvalid option: ${OPTARG}.\n"                  # Invalid Option Message
               show_usage                                               # Display Help Usage
               exit 1                                                   # Exit with Error
               ;;
        esac                                                            # End of case
    done                                                                # End of while
    return 
}



#===================================================================================================
#                                       Script Start HERE
#===================================================================================================
#

    cmd_options "$@"                                                    # Check command-line Options
    sadm_start                                                          # Create Dir.,PID,log,rch
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if 'Start' went wrong
    if ! [ $(id -u) -eq 0 ]                                             # If Cur. user is not root
        then sadm_write "Script can only be run by the 'root' user.\n"  # Advise User Message
             sadm_write "Process aborted.\n"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S with Error
    fi

    # Set the PATH to each commands that may be used 
    pre_validation                                                      # Cmd present ?
    SADM_EXIT_CODE=$?                                                   # Save Function Return code
    if [ $SADM_EXIT_CODE -ne 0 ]                                        # Which Command missing
        then sadm_stop $SADM_EXIT_CODE                                  # Upd. RC & Trim Log & RCH
             exit 1
    fi

    if [ "$SADM_OS_TYPE"  = "AIX"   ]                                 # If running in AIX
        then create_aix_config_files                                    # Collect Aix Info
        else create_linux_config_files                                  # Collect Linux/OSX Info
    fi
    create_summary_file                                                 # Create Summary File for DB
    SADM_EXIT_CODE=$?                                                   # Save Function Return code
    sadm_stop $SADM_EXIT_CODE                                           # Upd RCH & Trim Log & RCH
    exit $SADM_EXIT_CODE                                                # Exit Glob. Err.Code (0/1)
