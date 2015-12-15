#! /usr/bin/env sh
# --------------------------------------------------------------------------------------------------
#   Author   :  Jacques Duplessis
#   Title    :  template.sh
#   Synopsis : .
#   Version  :  1.0
#   Date     :  14 August 2013
#   Requires :  sh
#   SCCS-Id. :  @(#) template.sh 2.0 2013/08/14
# --------------------------------------------------------------------------------------------------
# 2.2 Correction in end_process function (April 2014)
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

# --------------------------------------------------------------------------------------------------
#              V A R I A B L E S    L O C A L   T O     T H I S   S C R I P T
# --------------------------------------------------------------------------------------------------
#
Debug=true                                      ; export Debug          # Debug increase Verbose
#



# --------------------------------------------------------------------------------------------------
#                                Script Start HERE
# --------------------------------------------------------------------------------------------------
    tput clear
    sadm_start                                                          # Init Env. Dir & RC/Log File

    sadm_logger "-------------------------------------------------------------------------------------------------------------------------"
    sadm_logger "                                      FUNCTIONS AVAILABLE IN SADM_LIB_STD.SH                                                     "
    sadm_logger "                                                                                                    RETURN VALUE         "
    sadm_logger "VARIABLE AVAILABLE TO USE    DESCRIPTION                                                        PREFIX & SUFFIX BY 3 DOTS"
    sadm_logger "-------------------------------------------------------------------------------------------------------------------------"
    sadm_logger "\$(sadm_os_type)             OS Type (Always in Uppercase) (LINUX,AIX,...)                    : ...$(sadm_os_type)..."
    sadm_logger "\$(sadm_os_version)          OS Version (Ex: 7.2, 6.5)                                        : ...$(sadm_os_version)..."
    sadm_logger "\$(sadm_os_major_version)    OS Major Version (Ex 7, 6)                                       : ...$(sadm_os_major_version)..."
    sadm_logger "\$(sadm_os_name)             OS Distribution (Always in Uppercase) (Ex:REDHAT,CENTOS,UBUNTU)  : ...$(sadm_os_name)..."   
    sadm_logger "\$(sadm_os_code_name)        OS Project Code Name                                             : ...$(sadm_os_code_name)..."   
    sadm_logger "\$(sadm_kernel_version)      OS Running Kernel Version (Ex: 3.10.0-229.20.1.el7.x86_64)       : ...$(sadm_kernel_version)..."
    sadm_logger "\$(sadm_kernel_bitmode)      OS Kernel Bit Mode is a 32 or 64 Bits                            : ...$(sadm_kernel_bitmode)..."
    sadm_logger "\$(sadm_hostname)            Host Name                                                        : ...$(sadm_hostname)..."
    sadm_logger "\$(sadm_host_ip)             Host IP Address                                                  : ...$(sadm_host_ip)..."
    sadm_logger "\$(sadm_domainname)          Host Domain Name                                                 : ...$(sadm_domainname)..."
    sadm_logger " "
    sadm_logger "sadm_toupper string         Return the string it receive in uppercase                        : ...`sadm_toupper STRING`..."
    sadm_logger "sadm_tolower STRING         Return the string it receive in lowercase                        : ...`sadm_tolower STRING`..."
    if $(sadm_is_root) ; then wmess="true" ; else wmess="false" ;fi
    sadm_logger "sadm_is_root                True if script is running as root, False if not.                 : ...${wmess}..."
    sadm_logger " "
    sadm_logger "sadm_start                   Start and initialize sadm environment"
    sadm_logger "                             Please call this function when your script is starting"
    sadm_logger "                              "
    sadm_logger "sadm_stop 9                  Accept one parameter - Either 0 (Successfull) or non-zero (Error Encountered)"
    sadm_logger "                             Please call this function just before your script end"
    sadm_logger " "
    sadm_logger "-------------------------------------------------------------------------------------------------------------------------"
    sadm_logger "                                 FUNCTIONS AVAILABLE IN SADM_LIB_SERVER.SH"
    sadm_logger "                                                                                                      RETURN VALUE     "
    sadm_logger "VARIABLE AVAILABLE TO USE         DESCRIPTION                                                   PREFIX & SUFFIX BY 3 DOTS"
    sadm_logger "-------------------------------------------------------------------------------------------------------------------------"
    sadm_logger "\$(sadm_server_ips)               All Network Interfaces IP Address and Netmask use on server   : ...$(sadm_server_ips)..."
    sadm_logger "\$(sadm_server_type)              Host is Physical or Virtual (P/V)                             : ...$(sadm_server_type)..."
    sadm_logger "\$(sadm_server_model)             Server model is (Ex: OptiPlex 755)                            : ...$(sadm_server_model)..."
    sadm_logger "\$(sadm_server_serial)            Server serial number is (Ex: 4S7GYF1)                         : ...$(sadm_server_serial)..."
    sadm_logger "\$(sadm_server_memory)            Server total memory in MB  (Ex: 3790)                         : ...$(sadm_server_memory)..."
    sadm_logger "\$(sadm_server_hardware_bitmode)  Server CPU Hardware is a 32 or 64 bits capable                : ...$(sadm_server_hardware_bitmode)..."
    sadm_logger "\$(sadm_server_nb_cpu)            Number of CPU on the server (Ex: 4)                           : ...$(sadm_server_nb_cpu)..."
    sadm_logger "\$(sadm_server_nb_socket)         Number of socket on the server (Ex: 2)                        : ...$(sadm_server_nb_socket)..."
    sadm_logger "\$(sadm_server_core_per_socket)   Number of Core per Socket (Ex: 4)                             : ...$(sadm_server_core_per_socket)..."
    sadm_logger "\$(sadm_server_thread_per_core)   Number of Thread per Core                                     : ...$(sadm_server_thread_per_core)..."
    sadm_logger "\$(sadm_server_cpu_speed)         Server CPU Speed in GHz                                       : ...$(sadm_server_cpu_speed)..."
    sadm_logger "\$(sadm_server_disks)             Server disks list (MB) (Ex: DISKNAME|SIZE,DISKNAME|SIZE,...)  : ...$(sadm_server_disks)..."
    sadm_logger "\$(sadm_server_vg)                Server vg(s) list (MB) (Ex: VGNAME|SIZE|USED|FREE,...)        : ...$(sadm_server_vg)..."
    
    sadm_stop $GLOBAL_ERROR                                             # Upd. RCH File & Trim Log
    exit $GLOBAL_ERROR                                                  # Exit With Global Err (0/1)
