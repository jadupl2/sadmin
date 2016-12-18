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
SADM_MULTIPLE_EXEC="N"                     ; export SADM_MULTIPLE_EXEC  # Run many copy at same time
SADM_DEBUG_LEVEL=9                         ; export SADM_DEBUG_LEVEL    # 0=NoDebug Higher=+Verbose


# --------------------------------------------------------------------------------------------------
# Define SADMIN Tool Library location and Load them in memory, so they are ready to be used
# --------------------------------------------------------------------------------------------------
[ -f ${SADM_BASE_DIR}/lib/sadm_lib_std.sh ]    && . ${SADM_BASE_DIR}/lib/sadm_lib_std.sh     
[ -f ${SADM_BASE_DIR}/lib/sadm_lib_server.sh ] && . ${SADM_BASE_DIR}/lib/sadm_lib_server.sh  
#[ -f ${SADM_BASE_DIR}/lib/sadm_lib_screen.sh ] && . ${SADM_BASE_DIR}/lib/sadm_lib_screen.sh  

# --------------------------------------------------------------------------------------------------
# These Global Variables, get their default from the sadmin.cfg file, but can be overridden here
# --------------------------------------------------------------------------------------------------
#SADM_MAIL_ADDR="your_email@domain.com"    ; export ADM_MAIL_ADDR        # Default is in sadmin.cfg
SADM_MAIL_TYPE=1                          ; export SADM_MAIL_TYPE       # 0=No 1=Err 2=Succes 3=All
#SADM_CIE_NAME="Your Company Name"         ; export SADM_CIE_NAME        # Company Name
#SADM_USER="sadmin"                        ; export SADM_USER            # sadmin user account
#SADM_GROUP="sadmin"                       ; export SADM_GROUP           # sadmin group account
#SADM_MAX_LOGLINE=5000                     ; export SADM_MAX_LOGLINE     # Max Nb. Lines in LOG )
#SADM_MAX_RCLINE=100                       ; export SADM_MAX_RCLINE      # Max Nb. Lines in RCH file
#SADM_NMON_KEEPDAYS=40                     ; export SADM_NMON_KEEPDAYS   # Days to keep old *.nmon
#SADM_SAR_KEEPDAYS=40                      ; export SADM_NMON_KEEPDAYS   # Days to keep old *.nmon
 
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPTE LE ^C
#===================================================================================================
#


##############################################################################
# Display Menu Principal
##############################################################################
sadm_display_main_menu()
{
    sadm_display_heading "System Administration Menu" 
    sadm_writexy 05 15 "1- Filesystem tools........................"
    sadm_writexy 07 15 "2- Create system group on Linux farm......."
    sadm_writexy 09 15 "3- Global Filesystem Tools................."
    sadm_writexy 11 15 "4- RPM DataBase Tools......................"
    sadm_writexy 14 15 "Q- Quit S.A.M.............................."
    sadm_writexy 21 29 "${reverse}Option ? ${reset}_${right}"
    sadm_writexy 21 38 " "
}

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
    printf "\$(sadm_get_epoch_time)                      Get Current Epoch Time                                           : ...$(sadm_get_epoch_time)...\n"
    EPOCH_TIME=$(sadm_get_epoch_time)
    printf "\$(sadm_epoch_to_date $EPOCH_TIME)            Convert epoch time to date (YYYY.MM.DD HH:MM:SS)                 : ...$(sadm_epoch_to_date $EPOCH_TIME)...\n"
    WDATE=$(sadm_epoch_to_date $EPOCH_TIME)
    printf "\$(sadm_date_to_epoch \'$WDATE\') Convert Date to epoch time (YYYY.MM.DD HH:MM:SS)                 : ..."$(sadm_date_to_epoch "$WDATE")"...\n"
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

    # For Debugging Purpose - Display Final Value of configuration file
    tput clear
    printf "=========================================================================================================================\n"
    printf ""
    printf  "SADM_DEBUG_LEVEL $SADM_DEBUG_LEVEL Information\n"
    printf "  - SADM_MAIL_ADDR=$SADM_MAIL_ADDR\n"         # Default email address
    printf "  - SADM_CIE_NAME=$SADM_CIE_NAME\n"           # Company Name
    printf "  - SADM_MAIL_TYPE=$SADM_MAIL_TYPE\n"         # Send Email after each run
    printf "  - SADM_SERVER=$SADM_SERVER\n"               # SADMIN server
    printf "  - SADM_DOMAIN=$SADM_DOMAIN\n"               # SADMIN Domain Default
    printf "  - SADM_USER=$SADM_USER\n"                   # sadmin user account
    printf "  - SADM_GROUP=$SADM_GROUP\n"                 # sadmin group account
    printf "  - SADM_WWW_USER=$SADM_WWW_USER\n"           # sadmin Web user account
    printf "  - SADM_WWW_GROUP=$SADM_WWW_GROUP\n"         # sadmin Web group account
    printf "  - SADM_MAX_LOGLINE=$SADM_MAX_LOGLINE\n"     # Max Line in each *.log
    printf "  - SADM_MAX_RCLINE=$SADM_MAX_RCLINE\n"       # Max Line in each *.rch
    printf "  - SADM_NMON_KEEPDAYS=$SADM_NMON_KEEPDAYS\n" # Days to keep old *.nmon
    printf "  - SADM_SAR_KEEPDAYS=$SADM_SAR_KEEPDAYS\n"   # Days ro keep old *.sar
    printf "  - SADM_RCH_KEEPDAYS=$SADM_NMON_KEEPDAYS\n"  # Days to keep old *.rch
    printf "  - SADM_LOG_KEEPDAYS=$SADM_SAR_KEEPDAYS\n"   # Days ro keep old *.log
    printf "  - SADM_PGUSER=$SADM_PGUSER\n"               # PostGres User Name
    printf "  - SADM_PGGROUP=$SADM_PGGROUP\n"             # PostGres Group Name
    printf "  - SADM_PGDB=$SADM_PGDB\n"                   # PostGres DataBase Name
    printf "  - SADM_PGSCHEMA=$SADM_PGSCHEMA\n"           # PostGres DataBase Schema
    printf "  - SADM_PGHOST=$SADM_PGHOST\n"               # PostGres DataBase Host
    printf "  - SADM_PGPORT=$SADM_PGPORT\n"               # PostGres Listening Port
    printf "  - SADM_RW_PGUSER=$SADM_RW_PGUSER\n"         # PostGres RW User
    printf "  - SADM_RW_PGPWD=$SADM_RW_PGPWD\n"           # PostGres RW User Pwd
    printf "  - SADM_RO_PGUSER=$SADM_RO_PGUSER\n"         # PostGres RO User
    printf "  - SADM_RO_PGPWD=$SADM_RO_PGPWD\n"           # PostGres RO User Pwd
    printf "=========================================================================================================================\n"
    echo "Press [ENTER] to Continue" ; read dummy
     

     
    tput clear
    echo " "
    echo "Testing Epoch and Elapse time calculation functions"
    wstart_time=`date "+%C%y.%m.%d %H:%M:%S"`
    wstart_time="2016.12.15 17:18:10"
    epoch_start=`sadm_date_to_epoch  "$wstart_time"`
    printf "Start Date is $wstart_time - Epoch is $epoch_start \n"
    echo "Please wait - Sleeping for 5 seconds"
    sleep 5 
    wend_time=`date "+%C%y.%m.%d %H:%M:%S"`
    wend_time="2016.12.15 18:31:56"
    epoch_end=`sadm_date_to_epoch "$wend_time"`
    welapse=$(sadm_elapse_time "$wend_time" "$wstart_time")
    printf "End   Date is $wend_time - Epoch is $epoch_end \n"
    printf "Elapsed time is $welapse \n"
    echo "Press [ENTER] to Continue" ; read dummy
    tput clear

    
#    sadm_display_heading "Small Menu (7 Items or less)"
#    menu_array=("Menu Item 1" "Menu Item 2" "Menu Item 3" "Menu Item 4" "Menu Item 5" \
#                "Menu Item 6" "Menu Item 7" )
#    sadm_display_menu "${menu_array[@]}"
#    echo  "Value Returned to Function Caller is $? - Press [ENTER] to continue" ; read dummy
#
#
#    sadm_display_heading "Medium Menu (Up to 15 Items)"
#    menu_array=("Menu Item 1"  "Menu Item 2"  "Menu Item 3"  "Menu Item 4"  "Menu Item 5"   \
#                "Menu Item 6"  "Menu Item 7"  "Menu Item 8"  "Menu Item 9"  "Menu Item 10"  \
#                "Menu Item 11" "Menu Item 12" "Menu Item 13" "Menu Item 14" "Menu Item 15"  )
#    sadm_display_menu "${menu_array[@]}"
#    echo  "Value Returned to Function Caller is $? - Press [ENTER] to continue" ; read dummy


#    sadm_display_heading "Large Menu (Up to 30 Items)"
#    menu_array=("Menu Item 1"  "Menu Item 2"  "Menu Item 3"  "Menu Item 4"  "Menu Item 5"   \
#                "Menu Item 6"  "Menu Item 7"  "Menu Item 8"  "Menu Item 9"  "Menu Item 10"  \
#                "Menu Item 11" "Menu Item 12" "Menu Item 13" "Menu Item 14" "Menu Item 15"  \
#                "Menu Item 16" "Menu Item 17" "Menu Item 18" "Menu Item 19" "Menu Item 20"  \
#                "Menu Item 21" "Menu Item 22" "Menu Item 23" "Menu Item 24" "Menu Item 25"  \
#                "Menu Item 26" "Menu Item 27" "Menu Item 28" "Menu Item 29" "Menu Item 30"  )
#    sadm_display_menu "${menu_array[@]}"
#    echo  "Value Returned to Function Caller is $? - Press [ENTER] to continue" ; read dummy

    #tput clear
    #e_header    "e_eheader"
    #e_arrow     "e_arrow"
    #e_success   "e_success"
    #e_error     "e_error"
    #e_warning   "e_warning"
    #e_underline "e_underline"
    #e_bold      "e_bold"
    #e_note      "e_note"

    SDAM_EXIT_CODE=0                                                    # For Test purpose
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
