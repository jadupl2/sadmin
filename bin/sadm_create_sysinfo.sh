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
# 2021_05_10 nolog: v3.22 Change error message "sadm_osupdate_farm.sh" to "sadm_osupdate_starter".
# 2021_05_22 nolog: v3.23 Standardize command line options & Update SADMIN code section
# 2021_06_03 client v3.24 Include script version in sysinfo text file generated
# 2022_01_10 client v3.25 Include memory module information in system information file.
# 2022_01_11 client v3.26 Added more disks information.
# 2022_02_17 client v3.27 Fix error writing network information file.
# 2022_02_17 client v3.28 Now show last O/S update status and date.
# 2022_03_04 client v3.29 Added more info about disks, filesystems and partition size.
# 2022_04_10 client v3.30 Change for RHEL/Rocky/AlmaLinux/CentOS v9, 'lsb_release' command is gone.
# 2022_04_19 client v3.31 Now include information from 'inxi' command (if available).
# 2022_07_20 client v3.32 When using 'inxi' suppress color escape sequence from generated files.
# 2022_07_21 client v3.33 Small enhancement in network information section.
# 2022_08_25 client v3.34 Update to SADMIN Section 1.52
# 2022_09_22 client v3.35 LVM information are now written into the Disk information file.
# 2023_01_12 client v3.36 Update gathering network information.
# 2023_12_26 client v3.37 Update SADMIN section
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # Intercept the ^C
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
export SADM_VER='3.37'                                     # Script version number
export SADM_PDESC="Collect hardware & software info of system" # Script Description
export SADM_LOG_TYPE="B"                                   # Log [S]creen [L]og [B]oth
export SADM_LOG_APPEND="N"                                 # Y=AppendLog, N=CreateNewLog
export SADM_LOG_HEADER="Y"                                 # Y=ProduceLogHeader N=NoHeader
export SADM_LOG_FOOTER="Y"                                 # Y=IncludeFooter N=NoFooter
export SADM_MULTIPLE_EXEC="N"                              # Run Simultaneous copy of script
export SADM_PID_TIMEOUT=7200                               # Sec. before PID Lock expire
export SADM_LOCK_TIMEOUT=3600                              # Sec. before Del. System LockFile
export SADM_USE_RCH="Y"                                    # Update RCH History File (Y/N)
export SADM_DEBUG=0                                        # Debug Level(0-9) 0=NoDebug
export SADM_EXIT_CODE=0                                    # Script Default Exit Code
export SADM_ROOT_ONLY="Y"                                  # Run only by root ? [Y] or [N]
export SADM_SERVER_ONLY="N"                                # Run only on SADMIN server? [Y] or [N]
export SADM_EXIT_CODE=0                                    # Script Default Exit Code
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
#export SADM_MAX_LOGLINE=400                                # Nb Lines to trim(0=NoTrim)
#export SADM_MAX_RCLINE=35                                  # Nb Lines to trim(0=NoTrim)
#export SADM_PID_TIMEOUT=7200                               # Sec. before PID Lock expire
#export SADM_LOCK_TIMEOUT=3600                              # Sec. before Del. System LockFile
# --------------- ---  E N D   O F   S A D M I N   C O D E    S E C T I O N  -----------------------







#===================================================================================================
# Scripts Variables
#===================================================================================================
export OSRELEASE="/etc/os-release"

# Name of all Output Files
export HPREFIX="${SADM_DR_DIR}/$(sadm_get_hostname)"                    # Output File Loc & Name
export HWD_FILE="${HPREFIX}_sysinfo.txt"                                # Hardware File Info
export PRTCONF_FILE="${HPREFIX}_prtconf.txt"                            # prtconf output file
export DISKS_FILE="${HPREFIX}_diskinfo.txt"                             # disk Inofrmation File
export LVM_FILE="${HPREFIX}_lvm.txt"                                    # lvm Information File
export NET_FILE="${HPREFIX}_network.txt"                                # Network Information File
export SYSTEM_FILE="${HPREFIX}_system.txt"                              # System Information File
export LSHW_FILE="${HPREFIX}_lshw.html"                                 # System Hardware in HTML 

# Path to Command used in this Script
export LVS=""                                                           # LV Summary Cmd with Path
export LVSCAN=""                                                        # LV Scan Cmd with Path
export LVDISPLAY=""                                                     # LV Display Cmd with Path
export VGS=""                                                           # VG Summary Cmd with Path
export VGSCAN=""                                                        # VG Scan Cmd with Path
export VGDISPLAY=""                                                     # VG Display Cmd with Path
export PVS=""                                                           # Physical Vol Cmd with Path
export PVSCAN=""                                                        # PV Scan Cmd with Path
export PVDISPLAY=""                                                     # PV Display Cmd with Path
export NETSTAT=""                                                       # netstat Cmd with Path
export IP=""                                                            # ip Cmd with Path
export DF=""                                                            # df Cmd with Path
export IFCONFIG=""                                                      # ifconfig Cmd with Path
export DMIDECODE=""                                                     # dmidecode Cmd with Path
export SADM_CPATH=""                                                    # Tmp Var Store Cmd Path
export LSBLK=""                                                         # lsblk Cmd Path
export BLKID=""                                                         # blkid Cmd Path
export HWINFO=""                                                        # hwinfo Cmd Path
export INXI=""                                                          # inxi Cmd Path
export LSVG=""                                                          # Aix LSVG Command Path
export LSPV=""                                                          # Aix LSPV Command Path
export PRTCONF=""                                                       # Aix Print Config Cmd
export DISKUTIL=""                                                      # OSX Diskutil command
export NETWORKSETUP=""                                                  # OSX networksetup command
export HOSTINFO=""                                                      # OSX hostinfo command
export SWVERS=""                                                        # OSX sw_vers Command
export SYSTEMPROFILER=""                                                # OSX system_profiler Cmd.
export IPCONFIG=""                                                      # OSX ipconfig Cmd.
export LSHW=""                                                          # Linux List Hardware (lshw)
export NMCLI=""                                                         # Linux Network Manager CLI
export HOSTNAMECTL=""                                                   # Linux HostNameCTL Command
export OSUPDATE_DATE=""                                                 # Date of Last O/S Update
export OSUPDATE_STATUS=""                                               # Status (S,F,R) O/S Update
export MIITOOL=""                                                       # mii-tool command location
export ETHTOOL=""                                                       # ethtool command location
export UNAME=""                                                         # uname  command location
export UPTIME=""                                                        # uptime command location
export LAST=""                                                          # last command location
export LSATTR=""                                                        # lsattr command location
export SYSCTL=""                                                        # sysctl command location
export SCUTIL=""                                                        # MacOS to list DNS Param.
export LSSCSI=""                                                        # List SCSI Device Info.
export LSPCI=""                                                         # List PCI Components
export VBOXMANAGE=""                                                    # VirtualBox Manager



# --------------------------------------------------------------------------------------------------
# Show script command line options
# --------------------------------------------------------------------------------------------------
show_usage()
{
    printf "\nUsage: %s%s%s [options]" "${BOLD}${CYAN}" $(basename "$0") "${NORMAL}"
    printf "\nDesc.: %s" "${BOLD}${CYAN}${SADM_PDESC}${NORMAL}"
    printf "\n\n${BOLD}${GREEN}Options:${NORMAL}"
    printf "\n   ${BOLD}${YELLOW}[-d 0-9]${NORMAL}\t\tSet Debug (verbose) Level"
    printf "\n   ${BOLD}${YELLOW}[-h]${NORMAL}\t\t\tShow this help message"
    printf "\n   ${BOLD}${YELLOW}[-v]${NORMAL}\t\t\tShow script version information"
    printf "\n\n" 
}



# ==================================================================================================
#""
# Check if the package name received as parameter is available on the server
#   - If command is found, $SADM_CPATH is set to full command path (return 0)
#   - If command is not found, $SADM_CPATH is set empty "" (return 1)
#""
# ==================================================================================================
#
command_available()
{
    SADM_PKG=$1
    if [ $# -ne 1 ] || [ -z "$SADM_PKG" ]
        then sadm_write_err "[ ERROR ] Command '$SADM_PKG' is not available on this system."
             sadm_write_err " - Parameter received = '$*' "
             sadm_write_err " - Please correct error in the script."
             return 1
    fi

    # Ff command (SADM_PKG) exist, Return command full Path, else return blank in CPATH
    if [[ $(type -P $SADM_PKG > /dev/null 2>&1) -eq 0 ]] 
        then SADM_CPATH=$(type -P $SADM_PKG) 
        else SADM_CPATH="" 
    fi

    # If SADM_DEBUG is activated then display Package Name and Full path to it
    if [ $SADM_DEBUG -gt 0 ]
        then if [ ! -z $SADM_CPATH ]                                    # If CPATH not Blank
                then SADM_MSG=$(printf "%-10s %-15s : %-30s" "[ OK ]" "$SADM_PKG" "$SADM_CPATH")
                else SADM_MSG=$(printf "%-10s %-15s : %-30s" "[ INFO ]" "$SADM_PKG" "Not Found")
             fi
             sadm_write_log "${SADM_MSG}"
    fi

    if [ -z "$SADM_CPATH" ] ; then return 1 ; else return 0 ; fi
}



# ==================================================================================================
#""
#     - Set command path used in the script (Some path are different on some RHEL Version)
#     - Check if Input exist and is readable
#""
# ==================================================================================================
#
pre_validation()
{
    sadm_write_log "Verifying command availability ..."

    # Check the availability of some commands that will be used in this script
    # If command is found the uppercase command variable is set to full command path
    # If command isn't found the uppercase command variable is set nothing
    #-----------------------------------------------------------------------------------------------

    case "$SADM_OS_TYPE"  in
        AIX)    command_available "lspv"        ; LSPV=$SADM_CPATH      
                command_available "lsvg"        ; LSVG=$SADM_CPATH      
                command_available "lsattr"      ; LSATTR=$SADM_CPATH    
                command_available "prtconf"     ; PRTCONF=$SADM_CPATH   
                ;;
        DARWIN) command_available "sw_vers"     ; SWVERS=$SADM_CPATH    # sw_ver Cmd Path
                command_available "system_profiler" ; SYSTEMPROFILER=$SADM_CPATH # Profiler Cmd Path
                command_available "diskutil"     ; DISKUTIL=$SADM_CPATH  # Cmd Path or Blank=!found
                command_available "networksetup" ; NETWORKSETUP=$SADM_CPATH  
                command_available "hostinfo"     ; HOSTINFO=$SADM_CPATH  # HostInfo Cmd Path
                command_available "ipconfig"     ; IPCONFIG=$SADM_CPATH  # ipconfig Cmd Path
                ;;
        LINUX)  command_available "lvs"          ; LVS=$SADM_CPATH       # Cmd Path or Blank=!found
                command_available "lvscan"       ; LVSCAN=$SADM_CPATH    # Cmd Path or Blank=!found
                command_available "lvdisplay"    ; LVDISPLAY=$SADM_CPATH # Cmd Path or Blank=!found
                command_available "vgs"          ; VGS=$SADM_CPATH       # Cmd Path or Blank=!found
                command_available "vgscan"       ; VGSCAN=$SADM_CPATH    # Cmd Path or Blank=!found
                command_available "vgdisplay"    ; VGDISPLAY=$SADM_CPATH # Cmd Path or Blank=!found
                command_available "pvs"          ; PVS=$SADM_CPATH       # Cmd Path or Blank=!found
                command_available "pvscan"       ; PVSCAN=$SADM_CPATH    # Cmd Path or Blank=!found
                command_available "pvdisplay"    ; PVDISPLAY=$SADM_CPATH # Cmd Path or Blank=!found
                command_available "ip"           ; IP=$SADM_CPATH        # Cmd Path or Blank=!found
                command_available "dmidecode"    ; DMIDECODE=$SADM_CPATH # Cmd Path or Blank=!found
                command_available "lsblk"        ; LSBLK=$SADM_CPATH     # Cmd Path or Blank=!found
                command_available "blkid"        ; BLKID=$SADM_CPATH     # Cmd Path or Blank=!found
                command_available "hwinfo"       ; HWINFO=$SADM_CPATH    # Cmd Path or Blank=!found
                command_available "inxi"         ; INXI=$SADM_CPATH      # Cmd Path or Blank=!found
                command_available "lshw"         ; LSHW=$SADM_CPATH      # lshw Cmd Path
                command_available "nmcli"        ; NMCLI=$SADM_CPATH     # nmcli Cmd Path
                command_available "hostnamectl"  ; HOSTNAMECTL=$SADM_CPATH   
                command_available "mii-tool"     ; MIITOOL=$SADM_CPATH   # mii-tool Cmd Path
                command_available "ethtool"      ; ETHTOOL=$SADM_CPATH   # ethtool Cmd Path
                command_available "sysctl"       ; SYSCTL=$SADM_CPATH    # CmdPath "" if not found
                command_available "scutil"       ; SCUTIL=$SADM_CPATH    # CmdPath="" if not found
                command_available "lsscsi"       ; LSSCSI=$SADM_CPATH    # CmdPath="" if not found
                command_available "rear"         ; REAR=$SADM_CPATH      # CmdPath="" if not found
                command_available "lspci"        ; LSPCI=$SADM_CPATH     # CmdPath="" if not found
                command_available "vboxmanage"   ; VBOXMANAGE=$SADM_CPATH
                ;;
        *)      sadm_write_err "$SADM_OSTYPE is not supported yet."
                sadm_write_err "Please reported to sadmlinux@gmail.com"
                ;;
    esac

    # Commands that are available on all Unix systems.
    command_available "ethtool"     ; ETHTOOL=$SADM_CPATH   # ethtool Cmd Path
    command_available "df"          ; DF=$SADM_CPATH                    # Cmd Path or Blank !found
    command_available "netstat"     ; NETSTAT=$SADM_CPATH               # Cmd Path or Blank !found
    command_available "ifconfig"    ; IFCONFIG=$SADM_CPATH              # Cmd Path or Blank !found
    command_available "uname"       ; UNAME=$SADM_CPATH                 # Cmd Path or Blank !found
    command_available "uptime"      ; UPTIME=$SADM_CPATH                # Cmd Path or Blank !found
    command_available "last"        ; LAST=$SADM_CPATH                  # Cmd Path or Blank !found
    sadm_write_log " " 
    sadm_write_log " " 
    return 0
}



# ==================================================================================================
#       First parameter is the command name to run (Example 'pvscan')
#       Second parameter is the fully qualified command name (Example '/sbin/pvscan')
#       Third paramter is the name of the ouput file
# ==================================================================================================
write_file_header()
{
    SOSNAME="$SADM_OS_NAME" ; SOSVER="$SADM_OS_VERSION"
    WTITLE=$1
    WFILE=$2
    echo "# ${SADM_DASH}"       >$WFILE 2>&1
    echo "# SADMIN Release $(sadm_get_release) - $SADM_PN Version $SADM_VER" >>$WFILE 2>&1
    echo "# $SADM_CIE_NAME - `date`"                 >>$WFILE 2>&1
    echo "# $WTITLE on $(sadm_get_fqdn) - $SOSNAME Version ${SOSVER}" >>$WFILE
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
        then sadm_write_log " " 
             sadm_write_log "Missing O/S Update RCH file ($RCHFILE)."
             sadm_write_log "Can't determine last O/S Update Date/Time & Status."
             sadm_write_log "Situation will resolve by itself, when you run your first O/S update for this system."
             sadm_write_log "You can run 'sadm_osupdate_starter.sh $(sadm_get_hostname)' on '$SADM_SERVER' to update this system."
             sadm_write_log "You will then get a valid 'rch' file."
             sadm_write_log " "
             OSUPDATE_DATE=""
             OSUPDATE_STATUS="U"
             return 1
    fi

    # Get Last Update Date from Return History File
    sadm_write_log "Getting last O/S Update date from $RCHFILE ..."
    OSUPDATE_DATE=$(tail -1 ${RCHFILE} |awk '{printf "%s %s", $4,$5}')
    if [ $? -ne 0 ]
        then sadm_write_log "Can't determine last O/S Update Date ..."
             sadm_write_log "You should run 'sadm_osupdate_starter.sh $(sadm_get_hostname)' on $SADM_SERVER to update this server."
             sadm_write_log "You will then get a valid 'rch' file ${RCHFILE}."
             return 1
    fi

    # Get the Status of the last O/S update
    RCH_CODE=$(tail -1 ${RCHFILE} |awk '{printf "%s", $NF}')
    if [ $? -ne 0 ]
        then sadm_write_log "Can't determine last O/S Update Status ..."
             return 1
    fi
    case "$RCH_CODE" in
        0)  OSUPDATE_STATUS="S"
            sadm_write_log "Last update done the $OSUPDATE_DATE & was successful ..."
            ;;
        1)  OSUPDATE_STATUS="F"
            sadm_write_log "Last update done the $OSUPDATE_DATE & failed ..."
            ;;
        2)  OSUPDATE_STATUS="R"
            sadm_write_log "Last update done the $OSUPDATE_DATE & is actually running ..."
            ;;
      "*")  OSUPDATE_STATUS="U"
            sadm_write_log "Last update done the $OSUPDATE_DATE - Undefined Status ..."
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
        then sadm_write_err "${SADM_ERROR} : Function ${FUNCNAME[0]} didn't receive 2 parameters."
             sadm_write_err "Function received $* and this isn't valid"
             return 1
    fi

    wfile=$1                                                            # What file to print
    wout=$2                                                             # Where to print the file

    # Check if file to print is readable
    if [ ! -r $wfile ]                                                  # If file not readable
        then sadm_write_err "File to print '$wfile' can be found."      # Inform User
             return 1
    fi

    echo " " >> $wout
    echo "#${SADM_80_DASH}"    >> $wout
    echo "# File: $wfile "  >> $wout                                    # Include name of the file
    echo "#${SADM_80_DASH}"    >> $wout
    grep -v "^#\|^$" $wfile >> $wout                                    # Output file to Desire file
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
        then sadm_write_err "[ ERROR ] Function ${FUNCNAME[0]} didn't receive 2 parameters.\n"
             sadm_write_err "Function received $* and this isn't valid.\n"
             return 1
    fi 

    ECMD=$1                                                             # Command to Execute
    EFILE=$2                                                            # Output Report File Name

    echo " "                        >> $EFILE
    echo "$ECMD"         >> $EFILE
    if [ $SADM_DEBUG -gt 4 ] ;then echo "Command executed is ${ECMD}." ; fi
    echo "#${SADM_80_DASH}"         >> $EFILE
    eval $ECMD                      >> $EFILE 2>&1
    echo " "                        >> $EFILE
    return 0
}

# ==================================================================================================
#               Create Misc. Linux config file for Disaster Recovery Purpose
# ==================================================================================================
create_linux_config_files()
{

    # Collect Disk Information ---------------------------------------------------------------------
    write_file_header "Disks Information" "$DISKS_FILE"
    sadm_write_log "Creating $DISKS_FILE ..."

    if [ "$INXI" != "" ]
        then CMD="$INXI -dc"
             execute_command "$CMD" "$DISKS_FILE" 
    fi

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
             CMD="$LSBLK -o name,size" 
             execute_command "$CMD" "$DISKS_FILE" 
             CMD="$LSBLK -f" 
             execute_command "$CMD" "$DISKS_FILE" 
             CMD="$LSBLK | grep -v part | awk '{print \$1 \"\t\" \$4}'"
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
    #write_file_header "Logical Volume" "$DISKS_FILE"
    #sadm_write "Creating $DISKS_FILE ...\n"
    if [ "$PVS"       != "" ] ; then CMD="$PVS"       ; execute_command "$CMD" "$DISKS_FILE" ; fi
    if [ "$PVSCAN"    != "" ] ; then CMD="$PVSCAN"    ; execute_command "$CMD" "$DISKS_FILE" ; fi
    if [ "$PVDISPLAY" != "" ] ; then CMD="$PVDISPLAY" ; execute_command "$CMD" "$DISKS_FILE" ; fi
    if [ "$VGS"       != "" ] ; then CMD="$VGS"       ; execute_command "$CMD" "$DISKS_FILE" ; fi
    if [ "$VGSCAN"    != "" ] ; then CMD="$VGSCAN 2>/dev/null"    ; execute_command "$CMD" "$DISKS_FILE" ; fi
    if [ "$VGDISPLAY" != "" ] ; then CMD="$VGDISPLAY" ; execute_command "$CMD" "$DISKS_FILE" ; fi
    if [ "$LVS"       != "" ] ; then CMD="$LVS"       ; execute_command "$CMD" "$DISKS_FILE" ; fi
    if [ "$LVSCAN"    != "" ] ; then CMD="$LVSCAN"    ; execute_command "$CMD" "$DISKS_FILE" ; fi
    if [ "$LVDISPLAY" != "" ] ; then CMD="$LVDISPLAY" ; execute_command "$CMD" "$DISKS_FILE" ; fi


    # Collect Network Information ------------------------------------------------------------------
    write_file_header "Network Information" "$NET_FILE"
    sadm_write_log "Creating $NET_FILE ..."

    if [ -r '/etc/hosts' ]              ; then print_file "/etc/hosts"              "$NET_FILE" ; fi
    if [ -r '/etc/resolv.conf' ]        ; then print_file "/etc/resolv.conf"        "$NET_FILE" ; fi

    if [ "$IP" != "" ]
        then CMD="$IP addr"
             execute_command "$CMD" "$NET_FILE" 
    fi

    if [ "$IP" != "" ]
        then CMD="$IP -brief a"
             execute_command "$CMD" "$NET_FILE" 
    fi

    if [ "$IP" != "" ]
        then CMD="$IP -brief link"
             execute_command "$CMD" "$NET_FILE" 
    fi

    if [ "$IP" != "" ]
        then CMD="$IP r"
             execute_command "$CMD" "$NET_FILE" 
    fi

    if [ "$NETSTAT" != "" ]
        then CMD="$NETSTAT -rn"
             execute_command "$CMD" "$NET_FILE" 
    fi

    #if [ -d "/sys/class/net" ] && [ "$MIITOOL" != "" ]
    #    then for w in `ls -1 /sys/class/net  --color=never | grep -v "^lo"`
    #            do
    #            CMD="$MIITOOL $w 2>/dev/null" 
    #            execute_command "$CMD" "$NET_FILE"
    #            done
    #fi

    if [ -d "/sys/class/net" ] && [ "$ETHTOOL" != "" ]
        then for w in $(ls -1 /sys/class/net  --color=never | grep -v "^lo")
                do
                CMD="$ETHTOOL $w" 
                execute_command "$CMD" "$NET_FILE"
                done
    fi

    if [ "$NMCLI" != "" ]
        then for w in $($NMCLI --terse --fields DEVICE device | awk -F: '{ print $1 }'| grep -v lo )
                do
                CMD="$NMCLI device show $w"
                execute_command "$CMD" "$NET_FILE" 
                CMD="$NMCLI -p -f general device show $w"
                execute_command "$CMD" "$NET_FILE"
                done
             CMD="$NMCLI dev status"
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

    if [ "$INXI" != "" ]
        then CMD="$INXI -ic"
             execute_command "$CMD" "$NET_FILE" 
             CMD="$INXI -nc"
             execute_command "$CMD" "$NET_FILE" 
    fi

    # Network Device information
    if [ "$IPCONFIG" != "" ]
        then index=0
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

    wd="/etc/sysconfig/network-scripts" 
    if [ -d "$wd" ]
        then if [ "$(ls -A $wd)" ]
                then ls -1 ${wd}/ifcfg* > /dev/null 2>&1 
                     if [ $? -eq 0 ] 
                        then for xfile in $(ls -1 ${wd}/ifcfg*)
                                do
                                if [ "$xfile" != "/etc/sysconfig/network-scripts/ifcfg-lo" ]
                                    then print_file "$xfile" "$NET_FILE"
                                fi 
                                done
                     fi 
             fi
    fi
    
    if [ -r '/etc/network/interfaces' ] ; then print_file "/etc/network/interfaces" "$NET_FILE" ; fi
    if [ -r '/etc/host.conf' ]          ; then print_file "/etc/host.conf"          "$NET_FILE" ; fi
    if [ -r '/etc/ssh.conf' ]           ; then print_file "/etc/ssh.conf"           "$NET_FILE" ; fi
    if [ -r '/etc/sshd.conf' ]          ; then print_file "/etc/sshd.conf"          "$NET_FILE" ; fi
    if [ -r '/etc/ntp.conf' ]           ; then print_file "/etc/ntp.conf"           "$NET_FILE" ; fi

    create_system_file                                                  # Collect System Information

    
    # Create List of Hardware in HTML
    if [ "$LSHW" != "" ]
        then sadm_write_log "Creating $LSHW_FILE .."
             $LSHW -html > $LSHW_FILE                                   # Create Hardware HTML File
    fi

}


# ==================================================================================================
# Create System Information file
# ==================================================================================================
create_system_file()
{
    write_file_header "System Information" "$SYSTEM_FILE"
    sadm_write_log "Creating $SYSTEM_FILE ..."

    if [ "$INXI" != "" ]
        then CMD="$INXI -Mc"
             execute_command "$CMD" "$SYSTEM_FILE" 
             CMD="$INXI -bc"
             execute_command "$CMD" "$SYSTEM_FILE" 
             CMD="$INXI -ac"
             execute_command "$CMD" "$SYSTEM_FILE" 
             CMD="$INXI -mc"
             execute_command "$CMD" "$SYSTEM_FILE" 
             CMD="$INXI -Gc"
             execute_command "$CMD" "$SYSTEM_FILE" 
             CMD="$INXI -Sc"
             execute_command "$CMD" "$SYSTEM_FILE" 
    fi

    if [ "$UNAME" != "" ]
        then CMD="$UNAME -a"
             execute_command "$CMD" "$SYSTEM_FILE" 
    fi

    if [ "$DMIDECODE" != "" ]
        then CMD="$DMIDECODE -t memory"
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

    if [ -f "$OSRELEASE"  ]
        then CMD="cat $OSRELEASE"
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
             CMD="$LSPCI "
             execute_command "$CMD" "$SYSTEM_FILE" 
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
    sadm_write_log "Creating $DISKS_FILE ..."

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
    write_file_header "Logical Volume" "$NET_FILE"
    sadm_write_log "Creating $NET_FILE ..."
    
    if [ "$LSVG" != "" ]
        then CMD="lsvg"
             execute_command "$CMD" "$NET_FILE" 
             CMD="lsvg -o | lsvg -i"
             execute_command "$CMD" "$NET_FILE" 
             CMD="$LSVG | xargs $LSVG -l "
             execute_command "$CMD" "$NET_FILE" 
    fi


    # Collect Network Information ------------------------------------------------------------------
    write_file_header "Network Information" "$NET_FILE"
    sadm_write_log "Creating $NET_FILE ..."

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

    sadm_write_log "Creating $HWD_FILE ..."
    echo "# $SADM_CIE_NAME - SysInfo Report File v${SADM_VER} - `date`"              >  $HWD_FILE
    echo "# This file is use by 'sadm_database_update.py' to update the SADMIN database." >> $HWD_FILE
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
    if [ "$REAR" != "" ] ;then REAR_VER=$($REAR -V | awk '{print $2}') ; else REAR_VER="N/A" ; fi
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
    
    pre_validation                                                      # Cmd neede are present ?
    SADM_EXIT_CODE=$?                                                   # Save Function Return code
    if [ $SADM_EXIT_CODE -ne 0 ]                                        # Which Command missing
        then sadm_stop 1                                                # Upd. RC & Trim Log & RCH
             exit 1
    fi
    
    if [ "$SADM_OS_TYPE"  = "AIX"   ]                                   # If running in AIX
        then create_aix_config_files                                    # Collect Aix Info
        else create_linux_config_files                                  # Collect Linux/OSX Info
    fi
    
    if [ -f "$LVM_FILE" ] ; then rm -f $LVM_FILE >/dev/null 2>&1 ; fi
    create_summary_file                                                 # Create Summary File for DB
    SADM_EXIT_CODE=$?                                                   # Save Function Return code
    sadm_stop $SADM_EXIT_CODE                                           # Upd RCH & Trim Log & RCH
    exit $SADM_EXIT_CODE                                                # Exit Glob. Err.Code (0/1)

##  lsmod | grep -io vboxguest | xargs modinfo | grep -iw version
#version:        6.1.12 r139181