#! /usr/bin/env sh
# --------------------------------------------------------------------------------------------------
#   Author   :  Jacques Duplessis
#   Title    :  sadm_create_server_info.sh
#   Synopsis : .This command should be run once a day to collect hardware & some software
#               information on the server (Info that will collect by the SADMIN Server)
#   Version  :  1.5
#   Date     :  13 November 2015
#   Requires :  sh 
# --------------------------------------------------------------------------------------------------
# 1.8 - Aug 2016 - Added lsblk output to script
# 1.9 - Dec 2016 - Replace lsblk by parted to output disk name and size
# 2.0 - Dec 2016 - Added lsdev to PVS_FILE in Aix 
# 2.1 - Dec 2017 - Added filed SADM_UPDATE_DATE to sysinfo.txt file
# 2.2 - Dec 2017 - Corrected Problem related to vgs returned info (< sign return now) 
# 2018_01_02 jDuplessis
#   V2.3 Now put information in less files (disks, lvm and network file) 
#        Rewritten for performance & Efficiency
# 2018_01_03 jDuplessis
#   V2.4 Added New system file output & added OSX COmmande for Network,System and Disk Info.
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPTE LE ^C
#set -x


#===================================================================================================
# If You want to use the SADMIN Libraries, you need to add this section at the top of your script
# You can run $SADMIN/lib/sadmlib_test.sh for viewing functions and informations avail. to you.
# --------------------------------------------------------------------------------------------------
if [ -z "$SADMIN" ] ;then echo "Please assign SADMIN Env. Variable to install directory" ;exit 1 ;fi
if [ ! -r "$SADMIN/lib/sadmlib_std.sh" ] ;then echo "SADMIN Library can't be located"   ;exit 1 ;fi
#
# YOU CAN CHANGE THESE VARIABLES - They Influence the execution of functions in SADMIN Library
SADM_VER='1.0'                             ; export SADM_VER            # Your Script Version
SADM_LOG_TYPE="B"                          ; export SADM_LOG_TYPE       # S=Screen L=LogFile B=Both
SADM_LOG_APPEND="N"                        ; export SADM_LOG_APPEND     # Append to Existing Log ?
SADM_MULTIPLE_EXEC="N"                     ; export SADM_MULTIPLE_EXEC  # Run many copy at same time
#
# DON'T CHANGE THESE VARIABLES - Need to be defined prior to loading the SADMIN Library
SADM_PN=${0##*/}                           ; export SADM_PN             # Script name
SADM_HOSTNAME=`hostname -s`                ; export SADM_HOSTNAME       # Current Host name
SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1` ; export SADM_INST           # Script name without ext.
SADM_TPID="$$"                             ; export SADM_TPID           # Script PID
SADM_EXIT_CODE=0                           ; export SADM_EXIT_CODE      # Script Exit Return Code
SADM_BASE_DIR=${SADMIN:="/sadmin"}         ; export SADM_BASE_DIR       # SADMIN Root Base Dir.
#
[ -f ${SADMIN}/lib/sadmlib_std.sh ]  && . ${SADMIN}/lib/sadmlib_std.sh  # Load SADMIN Std Library
#
# The Default Value for these Variables are defined in $SADMIN/cfg/sadmin.cfg file
# But some can overriden here on a per script basis
# --------------------------------------------------------------------------------------------------
# An email can be sent at the end of the script depending on the ending status 
# 0=No Email, 1=Email when finish with error, 2=Email when script finish with Success, 3=Allways
SADM_MAIL_TYPE=1                           ; export SADM_MAIL_TYPE      # 0=No 1=OnErr 2=OnOK  3=All
#SADM_MAIL_ADDR="your_email@domain.com"    ; export SADM_MAIL_ADDR      # Email to send log
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
    chown ${SADM_USER}.${SADM_GROUP} ${SCMD_TXT}
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
    sadm_start                                                          # Init Env Dir & RC/Log File
    if ! $(sadm_is_root)                                                # Only ROOT can run Script
        then sadm_writelog "This script must be run by the ROOT user"   # Advise User Message
             sadm_writelog "Process aborted"                            # Abort advise message
             sleep 5 
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi
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


# Old file to remove (Section to be remove soon 3th January 2018)
PARTED_FILE="${HPREFIX}_parted.txt"             ; export PARTED_FILE    # Physical Disk Info
if [ -r "$PARTED_FILE" ] ; then rm -f $PARTED_FILE >/dev/null 2>&1 ;fi

LVS_FILE="${HPREFIX}_lvs.txt"                   ; export LVS_FILE       # lvs Output File
if [ -r "$LVS_FILE" ] ; then rm -f $LVS_FILE >/dev/null 2>&1 ;fi

LVSCAN_FILE="${HPREFIX}_lvscan.txt"             ; export LVSCAN_FILE    # lvscan Output File
if [ -r "$LVSCAN_FILE" ] ; then rm -f $LVSCAN_FILE >/dev/null 2>&1 ;fi

LVDISPLAY_FILE="${HPREFIX}_lvdisplay.txt"       ; export LVDISPLAY_FILE # lvdisplay Output File
if [ -r "$LVDISPLAY_FILE" ] ; then rm -f $LVDISPLAY_FILE >/dev/null 2>&1 ;fi

VGS_FILE="${HPREFIX}_vgs.txt"                   ; export VGS_FILE       # Volume Group Info File
if [ -r "$VGS_FILE" ] ; then rm -f $VGS_FILE >/dev/null 2>&1 ;fi

VGSCAN_FILE="${HPREFIX}_vgscan.txt"             ; export VGSCAN_FILE    # Volume Group Scan File
if [ -r "$VGSCAN_FILE" ] ; then rm -f $VGSCAN_FILE >/dev/null 2>&1 ;fi

VGDISPLAY_FILE="${HPREFIX}_vgdisplay.txt"       ; export VGDISPLAY_FILE # Volume Group Scan File
if [ -r "$VGDISPLAY_FILE" ] ; then rm -f $VGDISPLAY_FILE >/dev/null 2>&1 ;fi

PVS_FILE="${HPREFIX}_pvs.txt"                   ; export PVS_FILE       # Physical Volume Info
if [ -r "$PVS_FILE" ] ; then rm -f $PVS_FILE >/dev/null 2>&1 ;fi

PVSCAN_FILE="${HPREFIX}_pvscan.txt"             ; export PVSCAN_FILE    # pvscan output file
if [ -r "$PVSCAN_FILE" ] ; then rm -f $PVSCAN_FILE >/dev/null 2>&1 ;fi

PVDISPLAY_FILE="${HPREFIX}_pvdisplay.txt"       ; export PVDISPLAY_FILE # pvdisplay output file
if [ -r "$PVDISPLAY_FILE" ] ; then rm -f $PVDISPLAY_FILE >/dev/null 2>&1 ;fi

DF_FILE="${HPREFIX}_df.txt"                     ; export DF_FILE        # DF command Output
if [ -r "$DF_FILE" ] ; then rm -f $DF_FILE >/dev/null 2>&1 ;fi

NETSTAT_FILE="${HPREFIX}_netstat.txt"           ; export NETSTAT_FILE   # Netstat Output
if [ -r "$NETSTAT_FILE" ] ; then rm -f $NETSTAT_FILE >/dev/null 2>&1 ;fi

IP_FILE="${HPREFIX}_ip.txt"                     ; export IP_FILE        # IP Information
if [ -r "$IP_FILE" ] ; then rm -f $IP_FILE >/dev/null 2>&1 ;fi


    sadm_stop $SADM_EXIT_CODE                                           # Upd RCH & Trim Log & RCH
    exit $SADM_EXIT_CODE                                                # Exit Glob. Err.Code (0/1)
