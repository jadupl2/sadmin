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
# 2.3 Cosmetic changes - Jan 2017
# 2.4 Allow to run multiple instance of the script - SADM_MULTIPLE_EXEC="Y"
# 
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPTE LE ^C
#set -x


#===================================================================================================
# If You want to use the SADMIN Libraries, you need to add this section at the top of your script
#   Please refer to the file $sadm_base_dir/lib/sadm_lib_std.txt for a description of each
#   variables and functions available to you when using the SADMIN functions Library
# --------------------------------------------------------------------------------------------------
# Global variables used by the SADMIN Libraries - Some influence the behavior of function in Library
# These variables need to be defined prior to load the SADMIN function Libraries
# --------------------------------------------------------------------------------------------------
SADM_PN=${0##*/}                           ; export SADM_PN             # Script name
SADM_VER='2.4'                             ; export SADM_VER            # Script Version
SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1` ; export SADM_INST           # Script name without ext.
SADM_TPID="$$"                             ; export SADM_TPID           # Script PID
SADM_EXIT_CODE=0                           ; export SADM_EXIT_CODE      # Script Exit Return Code
SADM_BASE_DIR=${SADMIN:="/sadmin"}         ; export SADM_BASE_DIR       # SADMIN Root Base Dir.
SADM_LOG_TYPE="B"                          ; export SADM_LOG_TYPE       # 4Logger S=Scr L=Log B=Both
SADM_LOG_APPEND="N"                        ; export SADM_LOG_APPEND     # Append to Existing Log ?
SADM_MULTIPLE_EXEC="Y"                     ; export SADM_MULTIPLE_EXEC  # Run many copy at same time
[ -f ${SADM_BASE_DIR}/lib/sadm_lib_std.sh ]    && . ${SADM_BASE_DIR}/lib/sadm_lib_std.sh     
[ -f ${SADM_BASE_DIR}/lib/sadm_lib_server.sh ] && . ${SADM_BASE_DIR}/lib/sadm_lib_server.sh  
[ -f ${SADM_BASE_DIR}/lib/sadm_lib_screen.sh ] && . ${SADM_BASE_DIR}/lib/sadm_lib_screen.sh  

# These variables are defined in sadmin.cfg file - You can also change them on a per script basis 
SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT}" ; export SADM_SSH_CMD  # SSH Command to Access Farm
SADM_MAIL_TYPE=1                           ; export SADM_MAIL_TYPE      # 0=No 1=Err 2=Succes 3=All
#SADM_MAX_LOGLINE=5000                       ; export SADM_MAX_LOGLINE   # Max Nb. Lines in LOG )
#SADM_MAX_RCLINE=100                         ; export SADM_MAX_RCLINE    # Max Nb. Lines in RCH file
#SADM_MAIL_ADDR="your_email@domain.com"      ; export ADM_MAIL_ADDR      # Email Address of owner
#===================================================================================================
#


# --------------------------------------------------------------------------------------------------
#              V A R I A B L E S    L O C A L   T O     T H I S   S C R I P T
# --------------------------------------------------------------------------------------------------
#
Debug=true                                      ; export Debug          # Debug increase Verbose
#


# --------------------------------------------------------------------------------------------------
# Display All SADM Variables Available to USER
# --------------------------------------------------------------------------------------------------
sadm_display_variables()
{

# SADMIN DIRECTORIES STRUCTURES DEFINITIONS
    tput clear  ; printf "DIRECTORIES VARIABLES\n" ; printf "\n"
    printf "SADM_BASE_DIR        = $SADM_BASE_DIR\n" 
    printf "SADM_BIN_DIR         = $SADM_LIB_DIR\n" 
    printf "SADM_TMP_DIR         = $SADM_TMP_DIR\n" 
    printf "SADM_LIB_DIR         = $SADM_LIB_DIR\n" 
    printf "SADM_LOG_DIR         = $SADM_LOG_DIR\n" 
    printf "SADM_CFG_DIR         = $SADM_CFG_DIR\n" 
    printf "SADM_SYS_DIR         = $SADM_SYS_DIR\n" 
    printf "SADM_DAT_DIR         = $SADM_DAT_DIR\n"
    printf "SADM_PG_DIR          = $SADM_PG_DIR\n" 
    printf "SADM_PKG_DIR         = $SADM_PKG_DIR\n" 
    printf "SADM_NMON_DIR        = $SADM_NMON_DIR\n" 
    printf "SADM_DR_DIR          = $SADM_DR_DIR\n"
    printf "SADM_SAR_DIR         = $SADM_SAR_DIR\n" 
    printf "SADM_RCH_DIR         = $SADM_RCH_DIR\n" 
    printf "SADM_NET_DIR         = $SADM_NET_DIR\n" 
#
# SADMIN WEB SITE DIRECTORIES DEFINITION
    printf "SADM_WWW_DIR         = $SADM_WWW_DIR\n" 
    printf "SADM_WWW_HTML_DIR    = $SADM_WWW_HTML_DIR\n" 
    printf "SADM_WWW_DAT_DIR     = $SADM_WWW_DAT_DIR\n" 
    printf "SADM_WWW_LIB_DIR     = $SADM_WWW_LIB_DIR\n" 
    printf "SADM_WWW_RCH_DIR     = $SADM_WWW_RCH_DIR\n" 
    printf "SADM_WWW_SAR_DIR     = $SADM_WWW_SAR_DIR\n"
    printf "SADM_WWW_NET_DIR     = $SADM_WWW_NET_DIR\n" 
    printf "SADM_WWW_DR_DIR      = $SADM_WWW_DR_DIR\n" 
    printf "SADM_WWW_NMON_DIR    = $SADM_WWW_NMON_DIR\n" 
    printf "SADM_WWW_TMP_DIR     = $SADM_WWW_TMP_DIR\n" 
    printf "SADM_WWW_LOG_DIR     = $SADM_WWW_LOG_DIR\n" 
    echo "Press [ENTER] to Continue" ; read dummy

#
# SADM CONFIG FILE, LOGS, AND TEMP FILES USER CAN USE
    tput clear ; printf "FILES VARIABLES\n" ; printf "\n"
    printf "SADM_PID_FILE        = $SADM_PID_FILE\n" 
    printf "SADM_CFG_FILE        = $SADM_CFG_FILE\n" 
    printf "SADM_REL_FILE        = $SADM_REL_FILE\n" 
    printf "SADM_CFG_HIDDEN      = $SADM_CFG_HIDDEN\n" 
    printf "SADM_TMP_FILE1       = $SADM_TMP_FILE1\n" 
    printf "SADM_TMP_FILE2       = $SADM_TMP_FILE2\n" 
    printf "SADM_TMP_FILE3       = $SADM_TMP_FILE3\n" 
    printf "SADM_LOG             = $SADM_LOG\n" 
    printf "SADM_RCHLOG          = $SADM_RCHLOG\n" 
    printf "DBPASSFILE           = $DBPASSFILE\n" 
    printf "SADM_SERVER          = $SADM_SERVER\n" 
    printf "SADM_DOMAIN          = $SADM_DOMAIN\n"
#    
# COMMAND PATH REQUIRE TO RUN SADM
    printf "\n" ; printf "PROGRAM USED & MISC. VARIABLES\n" ; printf "\n"
    printf "SADM_LSB_RELEASE     = $SADM_LSB_RELEASE\n"
    printf "SADM_DMIDECODE       = $SADM_DMIDECODE\n" 
    printf "SADM_BC              = $SADM_BC\n" 
    printf "SADM_FDISK           = $SADM_FDISK\n" 
    printf "SADM_WHICH           = $SADM_WHICH\n" 
    printf "SADM_PERL            = $SADM_PERL\n"
    printf "SADM_MAIL            = $SADM_MAIL\n" 
    printf "SADM_LSCPU           = $SADM_LSCPU\n"
    printf "SADM_NMON            = $SADM_NMON\n"
    printf "SADM_PARTED          = $SADM_PARTED\n" 
    printf "SADM_ETHTOOL         = $SADM_ETHTOOL\n"
    printf "SADM_PSQL            = $SADM_PSQL\n"
    printf "SADM_SSH             = $SADM_SSH\n" 
    printf "SADM_DASH            = $SADM_DASH\n" 
    printf "SADM_TEN_DASH        = $SADM_TEN_DASH\n" 
    echo "Press [ENTER] to Continue" ; read dummy
    
# SADM CONFIG FILE VARIABLES (Values defined here Will be overrridden by SADM CONFIG FILE Content)
    tput clear ; printf "VARIABLES LOADED FROM SADM CONFIGURATION FILE\n" ; printf "\n"
    printf "SADM_MAIL_ADDR       = $SADM_MAIL_ADDR\n"
    printf "SADM_MAIL_TYPE       = $SADM_MAIL_TYPE\n" 
    printf "SADM_CIE_NAME        = $SADM_CIE_NAME\n" 
    printf "SADM_USER            = $SADM_USER\n"
    printf "SADM_GROUP           = $SADM_GROUP\n"
    printf "SADM_WWW_USER        = $SADM_WWW_USER\n" 
    printf "SADM_WWW_GROUP       = $SADM_GROUP\n" 
    printf "SADM_MAX_LOGLINE     = $SADM_MAX_LOGLINE\n" 
    printf "SADM_MAX_RCLINE      = $SADM_MAX_RCLINE\n" 
    printf "SADM_NMON_KEEPDAYS   = $SADM_NMON_KEEPDAYS\n" 
    printf "SADM_SAR_KEEPDAYS    = $SADM_SAR_KEEPDAYS\n" 
    printf "SADM_RCH_KEEPDAYS    = $SADM_RCH_KEEPDAYS\n" 
    printf "SADM_LOG_KEEPDAYS    = $SADM_LOG_KEEPDAYS\n" 
    #
    printf "SADM_DBNAME          = $SADM_DBNAME\n" 
    printf "SADM_DBHOST          = $SADM_DBHOST\n" 
    printf "SADM_DBPORT          = $SADM_DBPORT\n" 
    printf "SADM_RW_DBUSER       = $SADM_RW_DBUSER\n" 
    printf "SADM_RW_PGPWD        = $SADM_RW_DBPWD\n" 
    printf "SADM_RO_DBUSER       = $SADM_RO_DBUSER\n"
    printf "SADM_RO_DBPWD        = $SADM_RO_DBPWD\n" 
    #
    printf "SADM_SSH_PORT        = $SADM_SSH_PORT\n"
    #
    printf "SADM_NETWORK1        = $SADM_NETWORK1\n"
    printf "SADM_NETWORK2        = $SADM_NETWORK2\n"
    printf "SADM_NETWORK3        = $SADM_NETWORK3\n"
    printf "SADM_NETWORK4        = $SADM_NETWORK4\n"
    printf "SADM_NETWORK5        = $SADM_NETWORK5\n"
    #
    printf "SADM_REAR_NFS_SERVER        = $SADM_REAR_NFS_SERVER\n"
    printf "SADM_REAR_NFS_MOUNT_POINT   = $SADM_REAR_NFS_MOUNT_POINT\n"
    printf "SADM_REAR_BACKUP_TO_KEEP    = $SADM_REAR_BACKUP_TO_KEEP\n" 
    printf "SADM_BACKUP_NFS_SERVER      = $SADM_BACKUP_NFS_SERVER\n"
    printf "SADM_BACKUP_NFS_MOUNT_POINT = $SADM_BACKUP_NFS_MOUNT_POINT\n"
    printf "SADM_BACKUP_TO_KEEP         = $SADM_BACKUP_TO_KEEP\n"
    printf "SADM_STORIX_NFS_SERVER      = $SADM_STORIX_NFS_SERVER\n"
    printf "SADM_STORIX_NFS_MOUNT_POINT = $SADM_STORIX_NFS_MOUNT_POINT\n"
    printf "SADM_STORIX_BACKUP_TO_KEEP  = $SADM_STORIX_BACKUP_TO_KEEP\n"
    #
    echo "Press [ENTER] to Continue" ; read dummy
}


# --------------------------------------------------------------------------------------------------
#                                Script Start HERE
# --------------------------------------------------------------------------------------------------
    tput clear
    sadm_start                                                          # Init Env. Dir & RC/Log File

    
    
    printf "=========================================================================================================================================\n"
    printf "                                      FUNCTIONS AVAILABLE IN SADM_LIB_STD.SH (Part I)                                                    \n"
    printf "                                                                                                                    RETURN VALUE         \n"
    printf "VARIABLE AVAILABLE TO USE                   DESCRIPTION                                                        PREFIX & SUFFIX BY 3 DOTS \n"
    printf "=========================================================================================================================================\n"
    printf "\$(sadm_get_release)                         SADMIN Release Number (XX.XX)                                    : ...$(sadm_get_release)...\n"
    printf "\$(sadm_get_ostype)                          OS Type (Always in Uppercase) (LINUX,AIX,...)                    : ...$(sadm_get_ostype)...\n"
    printf "\$(sadm_get_osversion)                       OS Version (Ex: 7.2, 6.5)                                        : ...$(sadm_get_osversion)...\n"
    printf "\$(sadm_get_osmajorversion)                  OS Major Version (Ex 7, 6)                                       : ...$(sadm_get_osmajorversion)...\n"
    printf "\$(sadm_get_osminorversion)                  OS Minor Version (Ex 2, 3)                                       : ...$(sadm_get_osminorversion)...\n"
    printf "\$(sadm_get_osname)                          OS Distribution (Always in Uppercase) (Ex:REDHAT,CENTOS,UBUNTU)  : ...$(sadm_get_osname)...\n"   
    printf "\$(sadm_get_oscodename)                      OS Project Code Name                                             : ...$(sadm_get_oscodename)...\n"   
    printf "\$(sadm_get_kernel_version)                  OS Running Kernel Version (Ex: 3.10.0-229.20.1.el7.x86_64)       : ...$(sadm_get_kernel_version)...\n"
    printf "\$(sadm_get_kernel_bitmode)                  OS Kernel Bit Mode is a 32 or 64 Bits                            : ...$(sadm_get_kernel_bitmode)...\n"
    printf "\$(sadm_get_hostname)                        Host Name                                                        : ...$(sadm_get_hostname)...\n"
    printf "\$(sadm_get_host_ip)                         Host IP Address                                                  : ...$(sadm_get_host_ip)...\n"
    printf "\$(sadm_get_domainname)                      Host Domain Name                                                 : ...$(sadm_get_domainname)...\n"
    printf "\$(sadm_get_fqdn)                            Fully Qualified Host Name                                        : ...$(sadm_get_fqdn)...\n"
    printf "\$(sadm_get_epoch_time)                      Get Current Epoch Time                                           : ...$(sadm_get_epoch_time)...\n"
    EPOCH_TIME=$(sadm_get_epoch_time)
    printf "\$(sadm_epoch_to_date $EPOCH_TIME)            Convert epoch time to date (YYYY.MM.DD HH:MM:SS)                 : ...$(sadm_epoch_to_date $EPOCH_TIME)...\n"
    WDATE=$(sadm_epoch_to_date $EPOCH_TIME)
    printf "\$(sadm_date_to_epoch '$WDATE') Convert Date to epoch time (YYYY.MM.DD HH:MM:SS)                 : ..."$(sadm_date_to_epoch "$WDATE")"...\n"
    printf "\$(sadm_elapse_time '2016.01.30 10:00:44' '2016.01.30 10:00:03') Return Elapse Time between two timestamp     : ...$(sadm_elapse_time '2016.01.30 10:00:44' '2016.01.30 10:00:03')...\n"
    printf "sadm_toupper string                         Return the string it receive in uppercase                        : ...`sadm_toupper STRING`...\n"
    printf "sadm_tolower STRING                         Return the string it receive in lowercase                        : ...`sadm_tolower STRING`...\n"
    if $(sadm_is_root) ; then wmess="true" ; else wmess="false" ;fi
    printf "sadm_is_root                                True if script is running as root, False if not.                 : ...${wmess}...\n"
    printf " \n"
    printf "=========================================================================================================================================\n"
    echo "Press [ENTER] to Continue" ; read dummy
    tput clear
    printf "=========================================================================================================================================\n"
    printf "                                      FUNCTIONS AVAILABLE IN SADM_LIB_STD.SH (Part II)                                           \n"
    printf "                                                                                                    RETURN VALUE         \n"
    printf "VARIABLE AVAILABLE TO USE           DESCRIPTION                                                 PREFIX & SUFFIX BY 3 DOTS \n"
    printf "=========================================================================================================================================\n"
    printf "sadm_start                          Start and initialize sadm environment\n"
    printf "                                    If SADMIN root directory is not /sadmin, make sure the SADMIN Env. variable is set to proper directory.\n"
    printf "                                    Please call this function when your script is starting\n"
    printf "                                    What this function will do for us :\n" 
    printf "                                     1) Make sure All SADM directories and sub-directories exist and they have proper permissions.\n"
    printf "                                     2) Make sure the log file exist with proper permission ($SADM_LOG)\n"
    printf "                                     3) Make sure the Return Code History Log exist and have the right permission\n"
    printf "                                     4) Create script PID file - If it exist and user want to run only 1 copy of script, then abort\n"
    printf "                                     5) Add line in the [R]eturn [C]ode [H]istory file stating script is started (Code 2)\n"
    printf "                                     6) Write HostName - Script name and version - O/S Name and version to the Log file (SADM_LOG)\n"
    printf "                              \n"
    printf "sadm_stop 0                         Accept one parameter - Either 0 (Successfull) or non-zero (Error Encountered)\n"
    printf "                                    Please call this function just before your script end\n"
    printf "                                    What this function do.\n"
    printf "                                     1) If Exit Code is not zero, change it to 1.\n"
    printf "                                     2) Get Actual Time and Calculate the Execution Time.\n"
    printf "                                     3) Writing the Script Footer in the Log (Script Return code, Execution Time, ...)\n"
    printf "                                     4) Update the RCH File (Start/End/Elapse Time and the Result Code)\n"
    printf "                                     5) Trim The RCH File Based on User choice in sadmin.cfg\n"
    printf "                                     6) Write to Log the user mail alerting type choose by user (sadmin.cfg)\n"
    printf "                                     7) Trim the Log based on user selection in sadmin.cfg\n"
    printf "                                     8) Send Email to sysadmin (if user selected that option in sadmin.cfg)\n"
    printf "                                     9) Delete the PID File of the script (SADM_PID_FILE)\n"
    printf "                                    10) Delete the Uers 3 TMP Files (SADM_TMP_FILE1, SADM_TMP_FILE2, SADM_TMP_FILE3)\n"
    printf " \n"
    printf "=========================================================================================================================================\n"
    echo "Press [ENTER] to Continue" ; read dummy
    tput clear
    printf "=========================================================================================================================================\n"
    printf "                                      FUNCTIONS AVAILABLE IN SADM_LIB_STD.SH  (PART III)                                           \n"
    printf "                                                                                                    RETURN VALUE         \n"
    printf "VARIABLE AVAILABLE TO USE   DESCRIPTION                                                        PREFIX & SUFFIX BY 3 DOTS \n"
    printf "=========================================================================================================================================\n"
    printf "\$(sadm_server_ips)               All Network Interfaces IP Address and Netmask use on server   : ...$(sadm_server_ips)...\n"
    printf "\$(sadm_server_type)              Host is Physical or Virtual (P/V)                             : ...$(sadm_server_type)...\n"
    printf "\$(sadm_server_model)             Server model is (Ex: OptiPlex 755)                            : ...$(sadm_server_model)...\n"
    printf "\$(sadm_server_serial)            Server serial number is (Ex: 4S7GYF1)                         : ...$(sadm_server_serial)...\n"
    printf "\$(sadm_server_memory)            Server total memory in MB  (Ex: 3790)                         : ...$(sadm_server_memory)...\n"
    printf "\$(sadm_server_hardware_bitmode)  Server CPU Hardware is a 32 or 64 bits capable                : ...$(sadm_server_hardware_bitmode)...\n"
    printf "\$(sadm_server_nb_cpu)            Number of CPU on the server (Ex: 4)                           : ...$(sadm_server_nb_cpu)...\n"
    printf "\$(sadm_server_nb_socket)         Number of socket on the server (Ex: 2)                        : ...$(sadm_server_nb_socket)...\n"
    printf "\$(sadm_server_core_per_socket)   Number of Core per Socket (Ex: 4)                             : ...$(sadm_server_core_per_socket)...\n"
    printf "\$(sadm_server_thread_per_core)   Number of Thread per Core                                     : ...$(sadm_server_thread_per_core)...\n"
    printf "\$(sadm_server_cpu_speed)         Server CPU Speed in MHz                                       : ...$(sadm_server_cpu_speed)...\n"
    printf "\$(sadm_server_disks)             Server disks list (MB) (Ex: DISKNAME|SIZE,DISKNAME|SIZE,...)  : ...$(sadm_server_disks)...\n"
    printf "\$(sadm_server_vg)                Server vg(s) list (MB) (Ex: VGNAME|SIZE|USED|FREE,...)        : ...$(sadm_server_vg)...\n"
    printf " \n"
    printf "=========================================================================================================================\n"
    echo "Press [ENTER] to Continue" ; read dummy

   
     
    sadm_display_variables

     
    #tput clear
    #echo " "
    #echo "TEST EPOCH AND ELAPSE TIME CALCULTATION FUNCTIONS"
    #echo " "
    #wstart_time=`date "+%C%y.%m.%d %H:%M:%S"`
    #epoch_start=`sadm_date_to_epoch  "$wstart_time"`
    #printf "Start Date is $wstart_time - Epoch is $epoch_start \n"
    #echo "Please wait - Sleeping for 5 seconds"
    #sleep 5 
    #wend_time=`date "+%C%y.%m.%d %H:%M:%S"`
    #epoch_end=`sadm_date_to_epoch "$wend_time"`
    #welapse=$(sadm_elapse_time "$wend_time" "$wstart_time")
    #printf "End   Date is $wend_time - Epoch is $epoch_end \n"
    #printf "Elapsed time is $welapse \n"


    
    sadm_display_heading "Small Menu (7 Items or less)"
    menu_array=("Menu Item 1" "Menu Item 2" "Menu Item 3" "Menu Item 4" "Menu Item 5" \
                "Menu Item 6" "Menu Item 7" )
    sadm_display_menu "${menu_array[@]}"
    echo  "Value Returned to Function Caller is $? - Press [ENTER] to continue" ; read dummy


    sadm_display_heading "Medium Menu (Up to 15 Items)"
    menu_array=("Menu Item 1"  "Menu Item 2"  "Menu Item 3"  "Menu Item 4"  "Menu Item 5"   \
                "Menu Item 6"  "Menu Item 7"  "Menu Item 8"  "Menu Item 9"  "Menu Item 10"  \
                "Menu Item 11" "Menu Item 12" "Menu Item 13" "Menu Item 14" "Menu Item 15"  )
    sadm_display_menu "${menu_array[@]}"
    echo  "Value Returned to Function Caller is $? - Press [ENTER] to continue" ; read dummy


    sadm_display_heading "Large Menu (Up to 30 Items)"
    menu_array=("Menu Item 1"  "Menu Item 2"  "Menu Item 3"  "Menu Item 4"  "Menu Item 5"   \
                "Menu Item 6"  "Menu Item 7"  "Menu Item 8"  "Menu Item 9"  "Menu Item 10"  \
                "Menu Item 11" "Menu Item 12" "Menu Item 13" "Menu Item 14" "Menu Item 15"  \
                "Menu Item 16" "Menu Item 17" "Menu Item 18" "Menu Item 19" "Menu Item 20"  \
                "Menu Item 21" "Menu Item 22" "Menu Item 23" "Menu Item 24" "Menu Item 25"  \
                "Menu Item 26" "Menu Item 27" "Menu Item 28" "Menu Item 29" "Menu Item 30"  )
    sadm_display_menu "${menu_array[@]}"
    echo  "Value Returned to Function Caller is $? - Press [ENTER] to continue" ; read dummy

    #tput clear
    e_header    "e_eheader"
    e_arrow     "e_arrow"
    e_success   "e_success"
    e_error     "e_error"
    e_warning   "e_warning"
    e_underline "e_underline"
    e_bold      "e_bold"
    e_note      "e_note"


    SDAM_EXIT_CODE=0                                                    # For Test purpose
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
]