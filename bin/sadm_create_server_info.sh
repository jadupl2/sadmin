#! /usr/bin/env sh
# --------------------------------------------------------------------------------------------------
#   Author   :  Jacques Duplessis
#   Title    :  sadm_collect_hwd_info.sh
#   Synopsis : .This command should be run once a day to collect hardware & some software
#               information on the server (Info that will collect by the SADMIN Server)
#   Version  :  1.5
#   Date     :  13 November 2015
#   Requires :  sh
# --------------------------------------------------------------------------------------------------
#

#set -x
#***************************************************************************************************
#  USING SADMIN LIBRARY SETUP
#   THESE VARIABLES GOT TO BE DEFINED PRIOR TO LOADING THE SADM LIBRARY (sadm_lib_std.sh) SCRIPT
#   THESE VARIABLES ARE USE AND NEEDED BY ALL THE SADMIN SCRIPT LIBRARY.
#
#   CALLING THE sadm_lib_std.sh SCRIPT DEFINE SOME SHELL FUNCTION AND GLOBAL VARIABLES THAT CAN BE
#   USED BY ANY SCRIPTS TO STANDARDIZE, ADD FLEXIBILITY AND CONTROL TO SCRIPTS THAT USER CREATE.
#
#   PLEASE REFER TO THE FILE $BASE_DIR/lib/sadm_lib_std.txt FOR A DESCRIPTION OF EACH VARIABLES AND
#   FUNCTIONS AVAILABLE TO SCRIPT DEVELOPPER.
# --------------------------------------------------------------------------------------------------
PN=${0##*/}                                    ; export PN              # Current Script name
VER='1.5'                                      ; export VER             # Program version
OUTPUT2=1                                      ; export OUTPUT2         # Write log 0=log 1=Scr+Log
INST=`echo "$PN" | awk -F\. '{ print $1 }'`    ; export INST            # Get Current script name
TPID="$$"                                      ; export TPID            # Script PID
GLOBAL_ERROR=0                                 ; export GLOBAL_ERROR    # Global Error Return Code
BASE_DIR=${SADMIN:="/sadmin"}                  ; export BASE_DIR        # Script Root Base Directory
#
[ -f ${BASE_DIR}/lib/sadm_lib_std.sh ]    && . ${BASE_DIR}/lib/sadm_lib_std.sh     # sadm std Lib
[ -f ${BASE_DIR}/lib/sadm_lib_server.sh ] && . ${BASE_DIR}/lib/sadm_lib_server.sh  # sadm server lib
#
# VARIABLES THAT CAN BE CHANGED PER SCRIPT -(SOME ARE CONFIGURABLE IS $BASE_DIR/cfg/sadmin.cfg)
#ADM_MAIL_ADDR="root@localhost"                 ; export ADM_MAIL_ADDR  # Default is in sadmin.cfg
SADM_MAIL_TYPE=1                               ; export SADM_MAIL_TYPE  # 0=No 1=Err 2=Succes 3=All
MAX_LOGLINE=5000                               ; export MAX_LOGLINE     # Max Nb. Lines in LOG )
MAX_RCLINE=100                                 ; export MAX_RCLINE      # Max Nb. Lines in RCH LOG
#***************************************************************************************************
#
#
#

#
#


# --------------------------------------------------------------------------------------------------
#              V A R I A B L E S    L O C A L   T O     T H I S   S C R I P T
# --------------------------------------------------------------------------------------------------
#
Debug=true                                      ; export Debug          # Debug increase Verbose
PRTCONF="/usr/sbin/prtconf"                     ; export PRTCONF        # Aix Print Confing Cmd
#
HPREFIX="${DR_DIR}/`hostname`"                  ; export HPREFIX        # Output File Loc & Name
HWD_FILE="${HPREFIX}_sysinfo.txt"               ; export HWD_FILE       # Hardware File Info
FACTER_FILE="${HPREFIX}_facter.txt"             ; export LVSCAN_FILE    # Facter Output File
LVS_FILE="${HPREFIX}_lvs.txt"                   ; export LVS_FILE       # lvs Output File
LVSCAN_FILE="${HPREFIX}_lvscan.txt"             ; export LVSCAN_FILE    # lvscan Output File
LVDISPLAY_FILE="${HPREFIX}_lvdisplay.txt"       ; export LVDISPLAY_FILE # lvdisplay Output File
VGS_FILE="${HPREFIX}_vgs.txt"                   ; export VGS_FILE       # Volume Group Info File
VGSCAN_FILE="${HPREFIX}_vgscan.txt"             ; export VGSCAN_FILE    # Volume Group Scan File
VGDISPLAY_FILE="${HPREFIX}_vgdisplay.txt"       ; export VGDISPLAY_FILE # Volume Group Scan File
PVS_FILE="${HPREFIX}_pvs.txt"                   ; export PVS_FILE       # Physical Volume Info
PVSCAN_FILE="${HPREFIX}_pvscan.txt"             ; export PVSCAN_FILE    # pvscan output file
PVDISPLAY_FILE="${HPREFIX}_pvdisplay.txt"       ; export PVDISPLAY_FILE # pvdisplay output file
DF_FILE="${HPREFIX}_df.txt"                     ; export DF_FILE        # DF command Output
NETSTAT_FILE="${HPREFIX}_netstat.txt"           ; export NETSTAT_FILE   # Netstat Output
IP_FILE="${HPREFIX}_ip.txt"                     ; export IP_FILE        # IP Information
PRTCONF_FILE="${HPREFIX}_prtconf.txt"           ; export PRTCONF_FILE   # prtconf output file
#
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
FACTER=""                                       ; export FACTER         # facter Cmd with Path
DMIDECODE=""                                    ; export DMIDECODE      # dmidecode Cmd with Path
SADM_CPATH=""                                   ; export SADM_CPATH     # Tmp Var Store Cmd Path
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
        then sadm_logger "ERROR : Invalid parameter received by command_available function"
             sadm_logger "        Parameter received = $*"
             sadm_logger "Please correct the script error"
             return 1
    fi


    # Check if command is located and set SADM_CPATH accordingly
    #-----------------------------------------------------------------------------------------------
    SADM_CPATH=`which $SADM_PKG > /dev/null 2>&1`
    if [ $? -eq 0 ]
        then SADM_CPATH=`which $SADM_PKG`
        else SADM_CPATH=""
    fi
    export SADM_CPATH


    # If Debug is activated then display Package Name and Full path to it
    #-----------------------------------------------------------------------------------------------
    if [ $Debug ]
        then if [ ! -z $SADM_CPATH ]
                then SADM_MSG=`printf "%-10s %-15s : %-30s" "[OK]" "$SADM_PKG" "$SADM_CPATH"`
                else SADM_MSG=`printf "%-10s %-15s : %-30s" "[WARNING]" "$SADM_PKG" "Not Found"`
             fi
             sadm_logger "$SADM_MSG"
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
    sadm_logger "Validate Script Requirements before proceeding ..."
    sadm_logger " "

    # The which command is needed to determine presence of command - Return Error if not found
    #-----------------------------------------------------------------------------------------------
    if ! which which >/dev/null 2>&1
        then sadm_logger "The command 'which' isn't available - Install it and rerun this script"
             return 1
    fi


    # Check the availibility of some command that will be used later on
    # If command is found the command variable is set to full command path
    # If command is not found the command variable is set empty
    #-----------------------------------------------------------------------------------------------
    command_available "facter"      ; FACTER=$SADM_CPATH                # Cmd Path,Blank if not fnd
    command_available "lvs"         ; LVS=$SADM_CPATH                   # Cmd Path or Blank !found
    command_available "lvscan"      ; LVSCAN=$SADM_CPATH                # Cmd Path or Blank !found
    command_available "lvdisplay"   ; LVDISPLAY=$SADM_CPATH             # Cmd Path or Blank !found
    command_available "vgs"         ; VGS=$SADM_CPATH                   # Cmd Path or Blank !found
    command_available "vgscan"      ; VGSCAN=$SADM_CPATH                # Cmd Path or Blank !found
    command_available "vgdisplay"   ; VGDISPLAY=$SADM_CPATH             # Cmd Path or Blank !found
    command_available "pvs"         ; PVS=$SADM_CPATH                   # Cmd Path or Blank !found
    command_available "pvscan"      ; PVSCAN=$SADM_CPATH                # Cmd Path or Blank !found
    command_available "pvdisplay"   ; PVDISPLAY=$SADM_CPATH             # Cmd Path or Blank !found
    command_available "netstat"     ; NETSTAT=$SADM_CPATH               # Cmd Path or Blank !found
    command_available "ip"          ; IP=$SADM_CPATH                    # Cmd Path or Blank !found
    command_available "df"          ; DF=$SADM_CPATH                    # Cmd Path or Blank !found
    command_available "dmidecode"   ; DMIDECODE=$SADM_CPATH             # Cmd Path or Blank !found

    sadm_logger " "
    sadm_logger "----------"
    sadm_logger " "
    return 0
}




# ==================================================================================================
#       First parameter is the command name to run (Example 'pvscan')
#       Second parameter is the fully qualified command name (Example '/sbin/pvscan')
#       Third paramter is the name of the ouput file
# ==================================================================================================
create_command_output()
{

    SCMD_NAME=$1
    SCMD_PATH=$2
    SCMD_TXT=$3

    if [ ! -z "$SCMD_PATH" ]
        then sadm_logger "Creating $SCMD_TXT with command $SCMD_PATH"
             echo -e "# $ADM_CIE_NAME - `date`" >$SCMD_TXT 2>&1
             echo -e "# Output of $SCMD_PATH command on `hostname`\n#" >>$SCMD_TXT 2>&1
             $SCMD_PATH >> $SCMD_TXT 2>&1
        else sadm_logger "The command $SCMD_NAME is not available"
             echo -e "# $ADM_CIE_NAME - `date`\n# The $SCMD_NAME command is not available on `hostname`\n#" > $PVS_FILE 2>&1
    fi
}




# ==================================================================================================
#               Create Misc. Linux config file for Disaster Recovery Purpose
# ==================================================================================================
create_linux_config_files()
{

    create_command_output "pvs"         "$PVS"          "$PVS_FILE"
    create_command_output "pvscan"      "$PVSCAN"       "$PVSCAN_FILE"
    create_command_output "pvdisplay"   "$PVDISPLAY"    "$PVDISPLAY_FILE"

    create_command_output "vgs"         "$VGS"          "$VGS_FILE"
    create_command_output "vgscan"      "$VGSCAN"       "$VGSCAN_FILE"
    create_command_output "vgdisplay"   "$VGDISPLAY"    "$VGDISPLAY_FILE"

    create_command_output "lvs"         "$LVS"          "$LVS_FILE"
    create_command_output "lvscan"      "$LVSCAN"       "$LVSCAN_FILE"
    create_command_output "lvdisplay"   "$LVDISPLAY"    "$LVDISPLAY_FILE"

    create_command_output "df -h"       "$DF -h"        "$DF_FILE"
    create_command_output "netstat -rn" "$NETSTAT -rn"  "$NETSTAT_FILE"
    create_command_output "ip addr"     "$IP addr"      "$IP_FILE"
    
    if [ "$FACTER" != "" ]
        then create_command_output "facter"     "$FACTER"      "$FACTER_FILE"
    fi

}


# ==================================================================================================
#                 Create Misc. AIX config file for Disaster Recovery Purpose
# ==================================================================================================
create_aix_config_files()
{

    df -m                   > $DF_FILE 2>&1
    netstat -rn             > $NETSTAT_FILE 2>&1
    ifconfig -a             > $IP_FILE 2>&1

    lspv | awk '{ print $1 }' | while read PV
        do
        echo "\n" >>$PVS_FILE 2>&1
        lspv  $PV          >>$PVS_FILE 2>&1
        done
    lsvg | xargs lsvg      > $VGS_FILE 2>&1
    lsvg | xargs lsvg -l   > $LVS_FILE 2>&1
    
    if [ "$FACTER" != "" ]
       then create_command_output "facter"     "$FACTER"      "$FACTER_FILE"
    fi
    
    sadm_logger "Running $SADM_PRTCONF ..."
    $SADM_PRTCONF > $PRTCONF_FILE
}



# ==================================================================================================
#        C R E A T E     S E R V E R    C O N F I G U R A T I O N    S U M M A R Y   F I L E 
# ==================================================================================================
create_summary_file()
{
    sadm_logger "Creating Configuration Summary File"
    sadm_logger "$HWD_FILE"
    sadm_logger " "
    echo -e "# $SADM_CIE_NAME - SysInfo Report File - `date`"                       >  $HWD_FILE
    echo -e "# This file will be use to update the SADMIN Database"                >> $HWD_FILE
    echo -e "#                                                    "                >> $HWD_FILE
    echo "SADM_OS_TYPE                        : $(sadm_os_type)"                   >> $HWD_FILE
    echo "SADM_HOSTNAME                       : $(sadm_hostname)"                  >> $HWD_FILE
    echo "SADM_DOMAINNAME                     : $(sadm_domainname)"                >> $HWD_FILE
    echo "SADM_HOST_IP                        : $(sadm_host_ip)"                   >> $HWD_FILE
    echo "SADM_SERVER_TYPE                    : $(sadm_server_type)"               >> $HWD_FILE
    echo "SADM_OS_VERSION                     : $(sadm_os_version)"                >> $HWD_FILE
    echo "SADM_OS_MAJOR_VERSION               : $(sadm_os_major_version)"          >> $HWD_FILE
    echo "SADM_OS_NAME                        : $(sadm_os_name)"                   >> $HWD_FILE
    echo "SADM_OS_CODE_NAME                   : $(sadm_os_code_name)"              >> $HWD_FILE
    echo "SADM_KERNEL_VERSION                 : $(sadm_kernel_version)"            >> $HWD_FILE
    echo "SADM_KERNEL_BITMODE (32 or 64)      : $(sadm_kernel_bitmode)"            >> $HWD_FILE
    echo "SADM_SERVER_MODEL                   : $(sadm_server_model)"              >> $HWD_FILE
    echo "SADM_SERVER_SERIAL                  : $(sadm_server_serial)"             >> $HWD_FILE
    echo "SADM_SERVER_MEMORY (in MB)          : $(sadm_server_memory)"             >> $HWD_FILE
    echo "SADM_SERVER_HARDWARE_BITMODE        : $(sadm_server_hardware_bitmode)"   >> $HWD_FILE
    echo "SADM_SERVER_NB_CPU                  : $(sadm_server_nb_cpu)"             >> $HWD_FILE
    echo "SADM_SERVER_CPU_SPEED (in GHz)      : $(sadm_server_cpu_speed)"          >> $HWD_FILE
    echo "SADM_SERVER_NB_SOCKET               : $(sadm_server_nb_socket)"          >> $HWD_FILE
    echo "SADM_SERVER_CORE_PER_SOCKET         : $(sadm_server_core_per_socket)"    >> $HWD_FILE
    echo "SADM_SERVER_THREAD_PER_CORE         : $(sadm_server_thread_per_core)"    >> $HWD_FILE
    echo "SADM_SERVER_IPS                     : $(sadm_server_ips)"                >> $HWD_FILE
    echo "SADM_SERVER_DISKS (Size in MB)      : $(sadm_server_disks)"              >> $HWD_FILE
    echo "SADM_SERVER_VG(s) (Size in MB)      : $(sadm_server_vg)"                 >> $HWD_FILE
}



# --------------------------------------------------------------------------------------------------
#                                     Script Start HERE
# --------------------------------------------------------------------------------------------------
    sadm_start                                                          # Init Env Dir & RC/Log File
    pre_validation                                                      # Input File > Cmd present ?
    GLOBAL_ERROR=$?                                                     # Save Function Return code
    if [ $GLOBAL_ERROR -ne 0 ]                                          # Cmd|File missing = exit
        then sadm_stop $GLOBAL_ERROR                                    # Upd. RC & Trim Log & Set RC
             exit 1
    fi
    echo ""
    if [ $(sadm_os_type) = "LINUX" ] ;then create_linux_config_files ;fi
    if [ $(sadm_os_type) = "AIX"   ] ;then create_aix_config_files   ;fi
    
    create_summary_file
    
    sadm_stop $GLOBAL_ERROR                                             # Upd. RC & Trim Log & Set RC
    exit $GLOBAL_ERROR                                                  # Exit Glob. Err.Code (0/1)

