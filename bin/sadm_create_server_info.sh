#! /usr/bin/env sh
# --------------------------------------------------------------------------------------------------
#   Author   :  Jacques Duplessis
#   Title    :  sadm_create_server_info.sh
#   Synopsis : .Run once a day to collect hardware & some software info of system (Use for DR)
#   Version  :  1.5
#   Date     :  13 November 2015
#   Requires :  sh 
# --------------------------------------------------------------------------------------------------
# 2016_08_08    v1.8 Added lsblk output to script
# 2016_12_03    v1.9 Replace lsblk by parted to output disk name and size
# 2016_12_09    v2.0 Added lsdev to PVS_FILE in Aix 
# 2017_12_10    v2.1 Added field SADM_UPDATE_DATE to sysinfo.txt file
# 2017_12_12    v2.2 Corrected Problem related to vgs returned info (< sign return now) 
# 2018_01_02    v2.3 Now put information in less files (disks, lvm and network file) 
# 2018_01_03    v2.4 Added New system file output & add OSX Commands for Network,System & Disk Info.
# 2018_06_03    v2.5 Revisited and adapt to new Libr.
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPTE LE ^C
#set -x



#===================================================================================================
# Setup SADMIN Global Variables and Load SADMIN Shell Library
#
    # TEST IF SADMIN LIBRARY IS ACCESSIBLE
    if [ -z "$SADMIN" ]                                 # If SADMIN Environment Var. is not define
        then echo "Please set 'SADMIN' Environment Variable to install directory." 
             exit 1                                     # Exit to Shell with Error
    fi
    if [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]            # SADM Shell Library not readable
        then echo "SADMIN Library can't be located"     # Without it, it won't work 
             exit 1                                     # Exit to Shell with Error
    fi

    # CHANGE THESE VARIABLES TO YOUR NEEDS - They influence execution of SADMIN standard library.
    export SADM_VER='2.5'                               # Current Script Version
    export SADM_LOG_TYPE="B"                            # Output goes to [S]creen [L]ogFile [B]oth
    export SADM_LOG_APPEND="N"                          # Append Existing Log or Create New One
    export SADM_LOG_HEADER="Y"                          # Show/Generate Header in script log (.log)
    export SADM_LOG_FOOTER="Y"                          # Show/Generate Footer in script log (.log)
    export SADM_MULTIPLE_EXEC="N"                       # Allow running multiple copy at same time ?
    export SADM_USE_RCH="Y"                             # Generate entry in Return Code History .rch

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
Debug=true                                      ; export Debug          # Debug increase Verbose

# Name of all Output Files
HPREFIX="${SADM_DR_DIR}/$(sadm_get_hostname)"   ; export HPREFIX        # Output File Loc & Name
HWD_FILE="${HPREFIX}_sysinfo.txt"               ; export HWD_FILE       # Hardware File Info
FACTER_FILE="${HPREFIX}_facter.txt"             ; export LVSCAN_FILE    # Facter Output File
PRTCONF_FILE="${HPREFIX}_prtconf.txt"           ; export PRTCONF_FILE   # prtconf output file
DISKS_FILE="${HPREFIX}_diskinfo.txt"            ; export DISKS_FILE     # disk Inofrmation File 
LVM_FILE="${HPREFIX}_lvm.txt"                   ; export LVM_FILE       # lvm Information File 
NET_FILE="${HPREFIX}_network.txt"               ; export NET_FILE       # Network Information File 
SYSTEM_FILE="${HPREFIX}_system.txt"             ; export SYSTEM_FILE    # System Information File 

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
SFDISK=""                                       ; export SFDISK         # sfdisk Cmd with Path
IFCONFIG=""                                     ; export IFCONFIG       # ifconfig Cmd with Path
FACTER=""                                       ; export FACTER         # facter Cmd with Path
DMIDECODE=""                                    ; export DMIDECODE      # dmidecode Cmd with Path
SADM_CPATH=""                                   ; export SADM_CPATH     # Tmp Var Store Cmd Path
LSBLK=""                                        ; export LSBLK          # lsblk Cmd Path
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
#



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
        then sadm_writelog "ERROR : Invalid parameter received by command_available function"
             sadm_writelog "        Parameter received = $*"
             sadm_writelog "        Please correct error in the script"
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

    # If Debug is activated then display Package Name and Full path to it
    #-----------------------------------------------------------------------------------------------
    if [ $Debug ]
        then if [ ! -z $SADM_CPATH ]
                then SADM_MSG=`printf "%-10s %-15s : %-30s" "[OK]" "$SADM_PKG" "$SADM_CPATH"`
                else SADM_MSG=`printf "%-10s %-15s : %-30s" "[NA]" "$SADM_PKG" "Not Found"`
             fi
             sadm_writelog "$SADM_MSG"
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
    sadm_writelog "Verifying command availability ..."

    # The which command is needed to determine presence of command - Return Error if not found
    #-----------------------------------------------------------------------------------------------
    if ! which which >/dev/null 2>&1
        then sadm_writelog "The command 'which' isn't available - Install it and rerun this script"
             return 1
    fi

    # Check the availibility of some commands that will be used in this script
    # If command is found the uppercase command variable is set to full command path
    # If command isn't found the uppercase command variable is set nothing
    #-----------------------------------------------------------------------------------------------
    command_available "facter"      ; FACTER=$SADM_CPATH                # Cmd Path,Blank if not fnd

    if [ $(sadm_get_ostype) = "AIX" ]
        then    command_available "lspv"        ; LSPV=$SADM_CPATH      # Cmd Path or Blank !found
                command_available "lsvg"        ; LSVG=$SADM_CPATH      # Cmd Path or Blank !found
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
                command_available "sfdisk"      ; SFDISK=$SADM_CPATH    # Cmd Path or Blank !found
                command_available "diskutil"    ; DISKUTIL=$SADM_CPATH  # Cmd Path or Blank !found
                command_available "networksetup" ; NETWORKSETUP=$SADM_CPATH  # NetworkSetup Cmd Path 
                command_available "hostinfo"    ; HOSTINFO=$SADM_CPATH  # HostInfo Cmd Path 
                command_available "sw_vers"     ; SWVERS=$SADM_CPATH    # sw_ver Cmd Path 
                command_available "system_profiler" ; SYSTEMPROFILER=$SADM_CPATH  # Profiler Cmd Path 
                command_available "ipconfig"    ; IPCONFIG=$SADM_CPATH  # ipconfig Cmd Path 
                command_available "lshw"        ; LSHW=$SADM_CPATH      # lshw Cmd Path 
                command_available "nmcli"       ; NMCLI=$SADM_CPATH     # lshw Cmd Path 
                command_available "hostnamectl" ; HOSTNAMECTL=$SADM_CPATH # hostnamectl command Path 
    fi

    # Aix and Linux Common Commands
    command_available "df"          ; DF=$SADM_CPATH                    # Cmd Path or Blank !found
    command_available "netstat"     ; NETSTAT=$SADM_CPATH               # Cmd Path or Blank !found
    command_available "ifconfig"    ; IFCONFIG=$SADM_CPATH              # Cmd Path or Blank !found
       
    sadm_writelog " "
    sadm_writelog "----------"
    sadm_writelog " "
    return 0
}



# ==================================================================================================
#       First parameter is the command name to run (Example 'pvscan')
#       Second parameter is the fully qualified command name (Example '/sbin/pvscan')
#       Third paramter is the name of the ouput file
# ==================================================================================================
write_file_header()
{
    SOSNAME=$(sadm_get_osname) ; SOSVER=$(sadm_get_osmajorversion)
    WTITLE=$1
    WFILE=$2
    echo "# ${SADM_DASH}"       >$WFILE 2>&1
    echo "# SADMIN Release $(sadm_get_release) - sadm_create_server_info V$SADM_VER" >>$WFILE 2>&1
    echo "# $SADM_CIE_NAME - `date`"                 >>$WFILE 2>&1
    echo "# Output of $WTITLE command on $(sadm_get_fqdn) - $SOSNAME V${SOSVER}" >>$WFILE
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
        then sadm_writelog "Creating $SCMD_TXT ..."
             write_file_header "$SCMD_NAME" "$SCMD_TXT"
             $SCMD_PATH >> $SCMD_TXT 2>&1
        else sadm_writelog "The command $SCMD_NAME is not available"
             write_file_header "$SCMD_NAME" "$SCMD_TXT"
    fi
    chown ${SADM_USER}:${SADM_GROUP} ${SCMD_TXT}
}



# ==================================================================================================
#               Create Misc. Linux config file for Disaster Recovery Purpose
# ==================================================================================================
create_linux_config_files()
{

    # Collect Disk Information ---------------------------------------------------------------------
    write_file_header "Disks Information" "$DISKS_FILE"
    sadm_writelog "Creating $DISKS_FILE ..."
    if [ "$LSBLK" != "" ]
        then echo "#"   >> $DISKS_FILE
             echo "# $LSBLK Command" >> $DISKS_FILE
             echo "#"   >> $DISKS_FILE
             $LSBLK -dn >> $DISKS_FILE
             echo "#"   >> $DISKS_FILE
    fi
    if [ "$SADM_PARTED" != "" ]
        then echo "#"   >> $DISKS_FILE
             echo "# $SADM_PARTED Command" >> $DISKS_FILE
             echo "#"   >> $DISKS_FILE
             $SADM_PARTED -l |grep "^Disk" |grep -vE "mapper|Disk Flags:" >> $DISKS_FILE 2>&1
             echo "#"   >> $DISKS_FILE
    fi
    if [ "$DF" != "" ]
        then echo "#"   >> $DISKS_FILE
             echo "# df -h Command" >> $DISKS_FILE
             echo "#"   >> $DISKS_FILE
             $DF -h >> $DISKS_FILE 2>&1
             echo "#"   >> $DISKS_FILE
    fi
    if [ "$SFDISK" != "" ]
        then echo "#"   >> $DISKS_FILE
             echo "#  sfdisk -uM -l | grep -iEv \"^$|mapper\" Command" >> $DISKS_FILE
             echo "#"   >> $DISKS_FILE
             $SFDISK -uM -l | grep -iEv "^$|mapper" >> $DISKS_FILE 2>&1
             echo "#"   >> $DISKS_FILE
    fi
    if [ $(sadm_get_ostype) = "DARWIN"   ]                              # If running in OSX
        then if [ "$DISKUTIL" != "" ]
                then echo "#"   >> $DISKS_FILE
                     echo "#  $DISKUTIL list " >> $DISKS_FILE
                     echo "#"   >> $DISKS_FILE
                     $DISKUTIL list >> $DISKS_FILE 2>&1
                     echo "#"   >> $DISKS_FILE
             fi
    fi


    # Collect LVM Information ----------------------------------------------------------------------
    write_file_header "Logical Volume" "$LVM_FILE"
    sadm_writelog "Creating $LVM_FILE ..."
    if [ "$PVS" != "" ]
        then echo "#"   >> $LVM_FILE
             echo "# $PVS Command" >> $LVM_FILE
             echo "#"   >> $LVM_FILE
             $PVS       >> $LVM_FILE
             echo "#"   >> $LVM_FILE
    fi
    if [ "$PVSCAN" != "" ]
        then echo "#"   >> $LVM_FILE
             echo "# $PVSCAN Command" >> $LVM_FILE
             echo "#"   >> $LVM_FILE
             $PVSCAN    >> $LVM_FILE
             echo "#"   >> $LVM_FILE
    fi
    if [ "$PVDISPLAY" != "" ]
        then echo "#"   >> $LVM_FILE
             echo "# $PVDISPLAY Command" >> $LVM_FILE
             echo "#"   >> $LVM_FILE
             $PVDISPLAY >> $LVM_FILE
             echo "#"   >> $LVM_FILE
    fi
    if [ "$VGS" != "" ]
        then echo "#"   >> $LVM_FILE
             echo "# $VGS Command" >> $LVM_FILE
             echo "#"   >> $LVM_FILE
             $VGS       >> $LVM_FILE
             echo "#"   >> $LVM_FILE
    fi
    if [ "$VGSCAN" != "" ]
        then echo "#"   >> $LVM_FILE
             echo "# $VGSCAN Command" >> $LVM_FILE
             echo "#"   >> $LVM_FILE
             $VGSCAN    >> $LVM_FILE
             echo "#"   >> $LVM_FILE
    fi
    if [ "$VGDISPLAY" != "" ]
        then echo "#"   >> $LVM_FILE
             echo "# $VGDISPLAY Command" >> $LVM_FILE
             echo "#"   >> $LVM_FILE
             $VGDISPLAY >> $LVM_FILE
             echo "#"   >> $LVM_FILE
    fi
    if [ "$LVS" != "" ]
        then echo "#"   >> $LVM_FILE
             echo "# $LVS Command" >> $LVM_FILE
             echo "#"   >> $LVM_FILE
             $LVS       >> $LVM_FILE
             echo "#"   >> $LVM_FILE
    fi
    if [ "$LVSCAN" != "" ]
        then echo "#"   >> $LVM_FILE
             echo "# $LVSCAN Command" >> $LVM_FILE
             echo "#"   >> $LVM_FILE
             $LVSCAN    >> $LVM_FILE
             echo "#"   >> $LVM_FILE
    fi
    if [ "$VGDISPLAY" != "" ]
        then echo "#"   >> $LVM_FILE
             echo "# $LVDISPLAY Command" >> $LVM_FILE
             echo "#"   >> $LVM_FILE
             $LVDISPLAY >> $LVM_FILE
             echo "#"   >> $LVM_FILE
    fi
    

    # Collect Network Information ------------------------------------------------------------------
    write_file_header "Network Information" "$NET_FILE"
    sadm_writelog "Creating $NET_FILE ..."
    if [ "$NMCLI" != "" ]
        then echo "#"   >> $NET_FILE
             echo "#  $NMCLI -p -f general device show" >> $NET_FILE
             echo "#"   >> $NET_FILE
             $NMCLI -p -f general device show >> $NET_FILE 2>&1
             echo "#"   >> $NET_FILE
             echo "#  $NMCLI dev status" >> $NET_FILE
             echo "#"   >> $NET_FILE
             $NMCLI dev status >> $NET_FILE 2>&1
             echo "#"   >> $NET_FILE
    fi   
    if [ "$IP" != "" ]
        then echo "#" >> $NET_FILE
             echo "# $IP Command" >> $NET_FILE
             echo "#" >> $NET_FILE
             $IP addr >> $NET_FILE
             echo "#" >> $NET_FILE
    fi
    if [ "$IFCONFIG" != "" ]
        then echo "#" >> $NET_FILE
             echo "# $IFCONFIG -a Command" >> $NET_FILE
             echo "#" >> $NET_FILE
             $IFCONFIG -a >> $NET_FILE
             echo "#" >> $NET_FILE
    fi
    if [ "$NETSTAT" != "" ]
        then echo "#"       >> $NET_FILE
             echo "# $NETSTAT -rn Command" >> $NET_FILE
             echo "#"       >> $NET_FILE
             $NETSTAT -rn   >> $NET_FILE
             echo "#"       >> $NET_FILE
    fi
    if [ "$NETWORKSETUP" != "" ]
        then echo "#"   >> $NET_FILE
             echo "#  $NETWORKSETUP -listallhardwareports " >> $NET_FILE
             echo "#"   >> $NET_FILE
             $NETWORKSETUP -listallhardwareports >> $NET_FILE 2>&1
             echo "#"   >> $NET_FILE
    fi   
    if [ "$IPCONFIG" != "" ]
        then FirstTime=0 ; index=0
             while [ $index -le 10 ]                                    # Process from en0 to en9
                do
                $IPCONFIG getpacket en${index} >/dev/null 2>&1          # Get Info about Interface 
                if [ $? -eq 0 ]                                         # If Device in use
                    then echo "#"   >> $NET_FILE
                         echo "#  $IPCONFIG getpacket en${index} " >> $NET_FILE
                         echo "#"   >> $NET_FILE
                         $IPCONFIG getpacket en${index} >> $NET_FILE 2>&1
                         echo "#"   >> $NET_FILE
                fi
                index=$((index + 1))
                done
    fi


    # Collect System Information -------------------------------------------------------------------
    write_file_header "System Information" "$SYSTEM_FILE"
    sadm_writelog "Creating $SYSTEM_FILE ..."
    if [ "$HOSTINFO" != "" ]
        then echo "#"       >> $SYSTEM_FILE
             echo "# $HOSTINFO Command" >> $SYSTEM_FILE
             echo "#"       >> $SYSTEM_FILE
             $HOSTINFO      >> $SYSTEM_FILE
             echo "#"       >> $SYSTEM_FILE
    fi
    if [ "$SWVERS" != "" ]
        then echo "#"       >> $SYSTEM_FILE
             echo "# $SWVERS Command" >> $SYSTEM_FILE
             echo "#"       >> $SYSTEM_FILE
             $SWVERS        >> $SYSTEM_FILE
             echo "#"       >> $SYSTEM_FILE
    fi
    if [ "$SYSTEMPROFILER" != "" ]
        then echo "#"       >> $SYSTEM_FILE
             echo "# $SYSTEMPROFILER SPSoftwareDataType Command" >> $SYSTEM_FILE
             echo "#"       >> $SYSTEM_FILE
             $SYSTEMPROFILER SPSoftwareDataType      >> $SYSTEM_FILE
             echo "#"       >> $SYSTEM_FILE
    fi
    if [ "$HOSTNAMECTL" != "" ]
        then echo "#"       >> $SYSTEM_FILE
             echo "# $HOSTNAMECTL Command" >> $SYSTEM_FILE
             echo "#"       >> $SYSTEM_FILE
             $HOSTNAMECTL   >> $SYSTEM_FILE
             echo "#"       >> $SYSTEM_FILE
    fi
    if [ "$LSHW" != "" ]
        then echo "#"       >> $SYSTEM_FILE
             echo "# $LSHW -short Command" >> $SYSTEM_FILE
             echo "#"       >> $SYSTEM_FILE
             $LSHW -short   >> $SYSTEM_FILE
             echo "#"       >> $SYSTEM_FILE
    fi
    if [ "$FACTER" != "" ]  ; then create_command_output "facter"  "$FACTER"  "$FACTER_FILE"   ; fi
}


# ==================================================================================================
#                 Create Misc. AIX config file for Disaster Recovery Purpose
# ==================================================================================================
create_aix_config_files()
{
    # Collect Disk Information ---------------------------------------------------------------------
    write_file_header "Disks Information" "$DISKS_FILE"
    sadm_writelog "Creating $DISKS_FILE ..."
    if [ "$DF" != "" ]
        then echo "#" >> $DISKS_FILE
             echo "# $DF -m Command" >> $DISKS_FILE
             echo "#" >> $LVM_FILE
             $DF -m >> "$DISKS_FILE"
             echo "#" >> $DISKS_FILE
    fi
 
    # Collect LVM Information ---------------------------------------------------------------------
    write_file_header "Logical Volume" "$LVM_FILE"
    sadm_writelog "Creating $LVM_FILE ..."
    if [ "$LSPV" != "" ]
        then    echo "# $LSPV Command" >> $LVM_FILE
                echo "#" >> $LVM_FILE
                $LSPV  >>$LVM_FILE 2>&1
                echo "#" >> $LVM_FILE
                $LSPV | awk '{ print $1 }' | while read PV
                    do
                    echo " " >>$LVM_FILE 2>&1
                    $LSPV  $PV          >>$LVM_FILE 2>&1
                    done
                echo "" >> $LVM_FILE
                lsdev -Cc disk >>$LVM_FILE 2>&1
                echo "#" >> $LVM_FILE
                $PVS >> "$LVM_FILE"
                echo "#" >> $LVM_FILE
    fi
    if [ "$LSVG" != "" ]
        then    echo "# $LSPV Command" >> $LVM_FILE
                echo "#" >> $LVM_FILE
                lsvg -o | lsvg -i >> $LVM_FILE
                echo "#" >> $LVM_FILE
                $LSVG | xargs $LSVG -l   >> $LVM_FILE 2>&1
                echo "#" >> $LVM_FILE
    fi
    

    # Collect Network Information ------------------------------------------------------------------
    write_file_header "Network Information" "$NET_FILE"
    sadm_writelog "Creating $NET_FILE ..."
    if [ "$NETSTAT" != "" ]
        then echo "#"       >> $NET_FILE
             echo "# $NETSTAT -rn Command" >> $NET_FILE
             echo "#"       >> $NET_FILE
             $NETSTAT -rn   >> $NET_FILE
             echo "#"       >> $NET_FILE
    fi
    if [ "$IFCONFIG" != "" ]
        then echo "#" >> $NET_FILE
             echo "# $IFCONFIG -a Command" >> $NET_FILE
             echo "#" >> $NET_FILE
             $IFCONFIG -a >> $NET_FILE
             echo "#" >> $NET_FILE
    fi
    
    if [ "$FACTER" != "" ]  ; then create_command_output "facter"  "$FACTER"  "$FACTER_FILE"   ; fi
    if [ "$PRTCONF" != "" ] ; then create_command_output "prtconf" "$PRTCONF" "$PRTCONF_FILE"  ; fi
}



# ==================================================================================================
#        C R E A T E     S E R V E R    C O N F I G U R A T I O N    S U M M A R Y   F I L E 
# ==================================================================================================
create_summary_file()
{
    sadm_writelog "Creating $HWD_FILE ..."
    sadm_writelog " "
    echo "# $SADM_CIE_NAME - SysInfo Report File - `date`"                           >  $HWD_FILE
    echo "# This file will be use to update the SADMIN Database"                     >> $HWD_FILE
    echo "#                                                    "                     >> $HWD_FILE
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
    echo "SADM_SERVER_NB_SOCKET                 = $(sadm_server_nb_socket)"          >> $HWD_FILE
    echo "SADM_SERVER_CORE_PER_SOCKET           = $(sadm_server_core_per_socket)"    >> $HWD_FILE
    echo "SADM_SERVER_THREAD_PER_CORE           = $(sadm_server_thread_per_core)"    >> $HWD_FILE
    echo "SADM_SERVER_IPS                       = $(sadm_server_ips)"                >> $HWD_FILE
    echo "SADM_SERVER_DISKS (Size in MB)        = $(sadm_server_disks)"              >> $HWD_FILE
    echo "SADM_SERVER_VG(s) (Size in MB)        = $(sadm_server_vg)"                 >> $HWD_FILE
}



# --------------------------------------------------------------------------------------------------
#                                     Script Start HERE
# --------------------------------------------------------------------------------------------------
#
    
    # If you want this script to be run only by 'root'.
    if ! [ $(id -u) -eq 0 ]                                             # If Cur. user is not root 
        then printf "\nThis script must be run by the 'root' user"      # Advise User Message
             printf "\nTry sudo %s" "${0##*/}"                          # Suggest using sudo
             printf "\nProcess aborted\n\n"                             # Abort advise message
             exit 1                                                     # Exit To O/S with error
    fi

    sadm_start                                                          # Start Using SADM Tools
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # If Problem during init
    pre_validation                                                      # Input File > Cmd present ?
    SADM_EXIT_CODE=$?                                                   # Save Function Return code
    if [ $SADM_EXIT_CODE -ne 0 ]                                        # Cmd|File missing = exit
        then sadm_stop $SADM_EXIT_CODE                                  # Upd. RC & Trim Log & Set RC
             exit 1
    fi
    if [ $(sadm_get_ostype) = "AIX"   ]                                 # If running in AIX
        then create_aix_config_files                                    # Collect Aix Info
        else create_linux_config_files                                  # Collect Linux/OSX Info
    fi
    create_summary_file                                                 # Create Summary File for DB
    sadm_stop $SADM_EXIT_CODE                                           # Upd RCH & Trim Log & RCH
    exit $SADM_EXIT_CODE                                                # Exit Glob. Err.Code (0/1)
