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
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPTE LE ^C

#
#===================================================================================================
# If You want to use the SADMIN Libraries, you need to add this section at the top of your script
#   Please refer to the file $sadm_base_dir/lib/sadm_lib_std.txt for a description of each
#   variables and functions available to you when using the SADMIN functions Library
#===================================================================================================

# --------------------------------------------------------------------------------------------------
# Global variables used by the SADMIN Libraries - Some influence the behavior of function in Library
# These variables need to be defined prior to load the SADMIN function Libraries
# --------------------------------------------------------------------------------------------------
SADM_PN=${0##*/}                           ; export SADM_PN             # Current Script name
SADM_VER='1.8'                             ; export SADM_VER            # This Script Version
SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1` ; export SADM_INST           # Script name without ext.
SADM_TPID="$$"                             ; export SADM_TPID           # Script PID
SADM_EXIT_CODE=0                           ; export SADM_EXIT_CODE      # Script Error Return Code
SADM_BASE_DIR=${SADMIN:="/sadmin"}         ; export SADM_BASE_DIR       # SADMIN Root Base Directory
SADM_LOG_TYPE="B"                          ; export SADM_LOG_TYPE       # 4Logger S=Scr L=Log B=Both
SADM_LOG_APPEND="N"                        ; export SADM_LOG_APPEND     # Append to Existing Log ?
SADM_MULTIPLE_EXEC="N"                     ; export SADM_MULTIPLE_EXEC  # Run many copy at same time
SADM_DEBUG_LEVEL=0                         ; export SADM_DEBUG_LEVEL    # 0=NoDebug Higher=+Verbose

# --------------------------------------------------------------------------------------------------
# Define SADMIN Tool Library location and Load them in memory, so they are ready to be used
# --------------------------------------------------------------------------------------------------
[ -f ${SADM_BASE_DIR}/lib/sadm_lib_std.sh ]    && . ${SADM_BASE_DIR}/lib/sadm_lib_std.sh     
[ -f ${SADM_BASE_DIR}/lib/sadm_lib_server.sh ] && . ${SADM_BASE_DIR}/lib/sadm_lib_server.sh  
#[ -f ${SADM_BASE_DIR}/lib/sadm_lib_screen.sh ] && . ${SADM_BASE_DIR}/lib/sadm_lib_screen.sh  

#
# SADM CONFIG FILE VARIABLES (Values defined here Will be overrridden by SADM CONFIG FILE Content)
#SADM_MAIL_ADDR="your_email@domain.com"      ; export ADM_MAIL_ADDR      # Default is in sadmin.cfg
SADM_MAIL_TYPE=1                            ; export SADM_MAIL_TYPE     # 0=No 1=Err 2=Succes 3=All
#SADM_CIE_NAME="Your Company Name"           ; export SADM_CIE_NAME      # Company Name
#SADM_USER="sadmin"                          ; export SADM_USER          # sadmin user account
#SADM_GROUP="sadmin"                         ; export SADM_GROUP         # sadmin group account
#SADM_WWW_USER="apache"                      ; export SADM_WWW_USER      # /sadmin/www owner 
#SADM_WWW_GROUP="apache"                     ; export SADM_WWW_GROUP     # /sadmin/www group
#SADM_MAX_LOGLINE=5000                       ; export SADM_MAX_LOGLINE   # Max Nb. Lines in LOG )
#SADM_MAX_RCLINE=100                         ; export SADM_MAX_RCLINE    # Max Nb. Lines in RCH file
#SADM_NMON_KEEPDAYS=60                       ; export SADM_NMON_KEEPDAYS # Days to keep old *.nmon
#SADM_SAR_KEEPDAYS=60                        ; export SADM_SAR_KEEPDAYS  # Days to keep old *.sar
#SADM_RCH_KEEPDAYS=60                        ; export SADM_RCH_KEEPDAYS  # Days to keep old *.rch
#SADM_LOG_KEEPDAYS=60                        ; export SADM_LOG_KEEPDAYS  # Days to keep old *.log
#SADM_PGUSER="postgres"                      ; export SADM_PGUSER        # PostGres User Name
#SADM_PGGROUP="postgres"                     ; export SADM_PGGROUP       # PostGres Group Name
#SADM_PGDB="sadmin"                          ; export SADM_PGDB          # PostGres DataBase Name
#SADM_PGSCHEMA="sadm_schema"                 ; export SADM_PGSCHEMA      # PostGres DataBase Schema
#SADM_PGHOST="sadmin.maison.ca"              ; export SADM_PGHOST        # PostGres DataBase Host
#SADM_PGPORT=5432                            ; export SADM_PGPORT        # PostGres Listening Port
#SADM_RW_PGUSER=""                           ; export SADM_RW_PGUSER     # Postgres Read/Write User 
#SADM_RW_PGPWD=""                            ; export SADM_RW_PGPWD      # PostGres Read/Write Passwd
#SADM_RO_PGUSER=""                           ; export SADM_RO_PGUSER     # Postgres Read Only User 
#SADM_RO_PGPWD=""                            ; export SADM_RO_PGPWD      # PostGres Read Only Passwd
#SADM_SERVER=""                              ; export SADM_SERVER        # Server FQN Name
#SADM_DOMAIN=""                              ; export SADM_DOMAIN        # Default Domain Name

#===================================================================================================
#




# --------------------------------------------------------------------------------------------------
#              V A R I A B L E S    L O C A L   T O     T H I S   S C R I P T
# --------------------------------------------------------------------------------------------------
#
Debug=true                                      ; export Debug          # Debug increase Verbose
#
HPREFIX="${SADM_DR_DIR}/$(sadm_get_hostname)"   ; export HPREFIX        # Output File Loc & Name
HWD_FILE="${HPREFIX}_sysinfo.txt"               ; export HWD_FILE       # Hardware File Info
FACTER_FILE="${HPREFIX}_facter.txt"             ; export LVSCAN_FILE    # Facter Output File
LVS_FILE="${HPREFIX}_lvs.txt"                   ; export LVS_FILE       # lvs Output File
LVSCAN_FILE="${HPREFIX}_lvscan.txt"             ; export LVSCAN_FILE    # lvscan Output File
LVDISPLAY_FILE="${HPREFIX}_lvdisplay.txt"       ; export LVDISPLAY_FILE # lvdisplay Output File
VGS_FILE="${HPREFIX}_vgs.txt"                   ; export VGS_FILE       # Volume Group Info File
VGSCAN_FILE="${HPREFIX}_vgscan.txt"             ; export VGSCAN_FILE    # Volume Group Scan File
VGDISPLAY_FILE="${HPREFIX}_vgdisplay.txt"       ; export VGDISPLAY_FILE # Volume Group Scan File
PVS_FILE="${HPREFIX}_pvs.txt"                   ; export PVS_FILE       # Physical Volume Info
LSBLK_FILE="${HPREFIX}_lsblk.txt"               ; export LSBLK_FILE     # Physical Disk Info
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
IFCONFIG=""                                     ; export IFCONFIG       # ifconfig Cmd with Path
FACTER=""                                       ; export FACTER         # facter Cmd with Path
DMIDECODE=""                                    ; export DMIDECODE      # dmidecode Cmd with Path
SADM_CPATH=""                                   ; export SADM_CPATH     # Tmp Var Store Cmd Path
LSVG=""                                         ; export LSVG           # Tmp Var Store Cmd Path
LSPV=""                                         ; export LSPV           # Tmp Var Store Cmd Path
PRTCONF=""                                      ; export PRTCONF        # Aix Print Confing Cmd
LSBLK=""                                        ; export LSBLK          # Path to lsblk command
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
             sadm_writelog "Please correct the script error"
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
                else SADM_MSG=`printf "%-10s %-15s : %-30s" "[WARNING]" "$SADM_PKG" "Not Found"`
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
    sadm_writelog "Validate Script Requirements before proceeding ..."

    # The which command is needed to determine presence of command - Return Error if not found
    #-----------------------------------------------------------------------------------------------
    if ! which which >/dev/null 2>&1
        then sadm_writelog "The command 'which' isn't available - Install it and rerun this script"
             return 1
    fi


    # Check the availibility of some command that will be used later on
    # If command is found the command variable is set to full command path
    # If command is not found the command variable is set empty
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
    fi
    
    if [ "$FACTER" != "" ]
       then create_command_output "facter"     "$FACTER"      "$FACTER_FILE"
    fi
       
    # Command Commands
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
    WTITLE=$1
    WFILE=$2
    echo "# ${SADM_DASH}"       >$WFILE 2>&1
    echo "# SADMIN Release $(sadm_get_release)"      >>$WFILE 2>&1
    echo "# $SADM_CIE_NAME - `date`"                 >>$WFILE 2>&1
    echo "# Output of $WTITLE command on $(sadm_get_hostname)" >>$WFILE 2>&1
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

    SCMD_NAME=$1
    SCMD_PATH=$2
    SCMD_TXT=$3

    if [ ! -z "$SCMD_PATH" ]
        then sadm_writelog "Creating $SCMD_TXT with command $SCMD_PATH"
             write_file_header "$SCMD_NAME" "$SCMD_TXT"
             $SCMD_PATH >> $SCMD_TXT 2>&1
        else sadm_writelog "The command $SCMD_NAME is not available"
             write_file_header "$SCMD_NAME Not Available" "$SCMD_TXT"
    fi
}



# ==================================================================================================
#               Create Misc. Linux config file for Disaster Recovery Purpose
# ==================================================================================================
create_linux_config_files()
{
    create_command_output "pvs"         "$PVS"          "$PVS_FILE"
    create_command_output "lsblk"       "$LSBLK"        "$LSBLK_FILE"
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
    create_command_output "df -m"       "$DF -m"        "$DF_FILE"
    create_command_output "netstat -rn" "$NETSTAT -rn"  "$NETSTAT_FILE"
    create_command_output "ifconfig -a" "$IFCONFIG -a"  "$IP_FILE"

    rm -f $PVS_FILE >/dev/null 2>&1
    $LSPV | awk '{ print $1 }' | while read PV
        do
        echo " " >>$PVS_FILE 2>&1
        $LSPV  $PV          >>$PVS_FILE 2>&1
        done

    #   #then create_command_output "$LSVG | xargs $LSVG" "lsvg | xargs lsvg" "$VGS_FILE"
    #   then $LSVG -o | $LSVG -i > $SADM_TMP_FILE3
    #        create_command_output "cat $SADM_TMP_FILE3" "lsvg -o | lsvg -i" "$VGS_FILE"
    #fi
    
    if [ "$LSVG" != "" ]
        then write_file_header "lsvg -o | lsvg -i" "$VGS_FILE"
             lsvg -o | lsvg -i >> $VGS_FILE
             write_file_header "$LSVG | xargs $LSVG -l" "$LVS_FILE"
             $LSVG | xargs $LSVG -l   >> $LVS_FILE 2>&1
    fi
    
    
    if [ "$FACTER" != "" ]
       then create_command_output "facter"     "$FACTER"      "$FACTER_FILE"
    fi
    
    if [ "$PRTCONF" != "" ]
       then create_command_output "prtconf"     "$PRTCONF"      "$PRTCONF_FILE"
    fi
}



# ==================================================================================================
#        C R E A T E     S E R V E R    C O N F I G U R A T I O N    S U M M A R Y   F I L E 
# ==================================================================================================
create_summary_file()
{
    sadm_writelog "Creating Configuration Summary File"
    sadm_writelog "$HWD_FILE"
    sadm_writelog " "
    echo "# $SADM_CIE_NAME - SysInfo Report File - `date`"                           >  $HWD_FILE
    echo "# This file will be use to update the SADMIN Database"                     >> $HWD_FILE
    echo "#                                                    "                     >> $HWD_FILE
    echo "SADM_OS_TYPE                          : $(sadm_get_ostype)"                >> $HWD_FILE
    echo "SADM_HOSTNAME                         : $(sadm_get_hostname)"              >> $HWD_FILE
    echo "SADM_DOMAINNAME                       : $(sadm_get_domainname)"            >> $HWD_FILE
    echo "SADM_HOST_IP                          : $(sadm_get_host_ip)"               >> $HWD_FILE
    echo "SADM_SERVER_TYPE [V]irtual [P]hysical : $(sadm_server_type)"               >> $HWD_FILE
    echo "SADM_OS_VERSION                       : $(sadm_get_osversion)"             >> $HWD_FILE
    echo "SADM_OS_MAJOR_VERSION                 : $(sadm_get_osmajorversion)"        >> $HWD_FILE
    echo "SADM_OS_NAME                          : $(sadm_get_osname)"                >> $HWD_FILE
    echo "SADM_OS_CODE_NAME                     : $(sadm_get_oscodename)"            >> $HWD_FILE
    echo "SADM_KERNEL_VERSION                   : $(sadm_get_kernel_version)"        >> $HWD_FILE
    echo "SADM_KERNEL_BITMODE (32 or 64)        : $(sadm_get_kernel_bitmode)"        >> $HWD_FILE
    echo "SADM_SERVER_MODEL                     : $(sadm_server_model)"              >> $HWD_FILE
    echo "SADM_SERVER_SERIAL                    : $(sadm_server_serial)"             >> $HWD_FILE
    echo "SADM_SERVER_MEMORY (in MB)            : $(sadm_server_memory)"             >> $HWD_FILE
    echo "SADM_SERVER_HARDWARE_BITMODE          : $(sadm_server_hardware_bitmode)"   >> $HWD_FILE
    echo "SADM_SERVER_NB_CPU                    : $(sadm_server_nb_cpu)"             >> $HWD_FILE
    echo "SADM_SERVER_CPU_SPEED (in MHz)        : $(sadm_server_cpu_speed)"          >> $HWD_FILE
    echo "SADM_SERVER_NB_SOCKET                 : $(sadm_server_nb_socket)"          >> $HWD_FILE
    echo "SADM_SERVER_CORE_PER_SOCKET           : $(sadm_server_core_per_socket)"    >> $HWD_FILE
    echo "SADM_SERVER_THREAD_PER_CORE           : $(sadm_server_thread_per_core)"    >> $HWD_FILE
    echo "SADM_SERVER_IPS                       : $(sadm_server_ips)"                >> $HWD_FILE
    echo "SADM_SERVER_DISKS (Size in MB)        : $(sadm_server_disks)"              >> $HWD_FILE
    echo "SADM_SERVER_VG(s) (Size in MB)        : $(sadm_server_vg)"                 >> $HWD_FILE
}



# --------------------------------------------------------------------------------------------------
#                                     Script Start HERE
# --------------------------------------------------------------------------------------------------
    sadm_start                                                          # Init Env Dir & RC/Log File

    if ! $(sadm_is_root)                                                # Only ROOT can run Script
        then sadm_writelog "This script must be run by the ROOT user"   # Advise User Message
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi
    
    pre_validation                                                      # Input File > Cmd present ?
    SADM_EXIT_CODE=$?                                                   # Save Function Return code
    if [ $SADM_EXIT_CODE -ne 0 ]                                        # Cmd|File missing = exit
        then sadm_stop $SADM_EXIT_CODE                                  # Upd. RC & Trim Log & Set RC
             exit 1
    fi
    echo ""
    if [ $(sadm_get_ostype) = "LINUX" ] ;then create_linux_config_files ;fi
    if [ $(sadm_get_ostype) = "AIX"   ] ;then create_aix_config_files   ;fi
    
    create_summary_file
    
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RC & Trim Log & Set RC
    exit $SADM_EXIT_CODE                                                # Exit Glob. Err.Code (0/1)

