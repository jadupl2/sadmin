#! /usr/bin/env bash
# --------------------------------------------------------------------------------------------------
#   Author   :  Jacques Duplessis
#   Title    :  sadmlib_std_demo.sh
#   Synopsis :  Demonstrate functions & variables available to developers using SADMIN Tools
#   Version  :  1.0 
#   Date     :  14 August 2015
#   Requires :  sh
#   SCCS-Id. :  @(#) template.sh 1.0 2015/08/14
# --------------------------------------------------------------------------------------------------
# 2017_01_02    V2.3 Cosmetic changes
# 2017_01_03    V2.4 Allow to run multiple instance of the script - SADM_MULTIPLE_EXEC="Y"
# 2017_04_05    V2.5 Adapt with New Libr Ver & Remove Screen test (Move to sadmlib_screen_test.sh)
# 2018_01_02    V2.6 Display Path for command facter
# 2018_01_25    V2.7 Added Variable SADM_RRDTOOL to sadmin.cfg display
# 2018_02_22    V2.8 Added Variable SADM_HOST_TYPE to sadmin.cfg display
# 2018_05_22    V2.9 Change name to sadmlib_std_demo.sh and completly rewritten 
# 2018_05_26    V3.0 Final Test - Added Lot of Variable and code 
# 2018_05_27    v3.1 Replace setup_sadmin Function by putting code at the beginning of source.
# 2018_05_28    v3.2 Add Backup Parameters that come from sadmin.cfg from now on.
# 2018_06_04    v3.3 Added User Directory Environment Variables in SADMIN Client Section
# 2018_06_05    v3.4 Add dat/dbb,usr/bin,usr/doc,usr/lib,usr/mon,setup and www/tmp/perf Display
# 2018_09_04    v3.5 Show SMON Alert type, curl, mutt and Alert Group
# 2018_09_25    v3.6 Show SMON Alert Group, Channel and History Files
# 2019_01_19    v3.7 Added: Added Backup List & Backup Exclude File Name available to User.
# 2019_01_28 lib v03.8 .00Database info only show when running on SADMIN Server
# 2019_03_18 lib v03.9 .00Add demo call to function 'sadm_get_packagetype'
# 2019_04_07 lib v03.10.00 Don't show Database user name if run on client.
# 2019_04_11 lib v03.11.00 Add Database column "active","category" and "group" to server output.
# 2019_04_25 lib v03.12.00 Add Alert_Repeat, Textbelt API Key and URL Variables in Output.
# 2019_05_17 lib v03.13.00 Add option -p(Show DB password),-s(Show Storix Info),-t(Show TextBeltKey)
# 2019_10_14 lib v03.14.00 Add demo for calling sadm_server_arch function & show result.
# 2019_10_17 lib v03.15.00 Print Category and Group table content at the end of report.
# 2019_10_30 lib v03.16.00 Remove 'facter' utilization (depreciated).
# 2019_11_25 lib v03.17.00 Change printing format of Database table at the end of execution.
# 2020_04_01 lib v03.18.00 Replace function sadm_writelog() with N/L incl. by sadm_write() No N/L Incl.
# 2020_11_24 lib v03.19.00 Don't show DB password file on client.
# 2020_12_24 lib v03.20.00 Include output of capitalize function.
# 2022_04_10 lib v03.21.00 Remove 'lsb_release' command dependency.
# 2022_05_10 lib v03.22.00 Use 'mutt' instead of 'mail'.
# 2022_06_16 lib v03.23.00 Added fields 'sa.proot_only' & 'sa.psadm_server_only' to output.
# 2022_08_14 lib v03.24.00 Output updated with all the latest functions & global variables.
# 2023_04_13 lib v03.25.00 Add 'SADM_REAR_DIF', 'SADM_REAR_INTERVAL', 'SADM_BACKUP_INTERVAL' to output.
# 2023_11_29 lib v03.26.00 Change to not update 'rch' file.
#@2024_06_13 lib v03.27.00 Add VM export parameters and alert history/archive purge days limit.
#@2024_11_01 lib v03.28.00 Change name of Global variable "SADM_RCHLOG" to "RCH_FILE". 
#@2024_12_17 lib v03.29.00 Now require 'root' user to run.
#@2025_01_24 lib v03.30.00 Added lock functions examples.
#@2026_07_03 lib v03.30.01 Added NFY notification variables to output.
#@2026_07_08 lib v03.31.01 Complete Rewritten, update with new Variables and functions.
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPT The Control-C
#set -x


                                                                                          
# ---------   S T A R T   O F   S A D M I N   R E Q U I R E D   C O D E   S E C T I O N  -----------
# v1.60 - Setup Global Variables and load the SADMIN standard library $SADMIN/lib/sadmlib_std.sh.
#       - To use SADMIN scripting tools, this section MUST be present near the top of your code.    
#
# Make sure environment variable 'SADMIN' is defined, if it's not, exit with error message.
if [ -r /etc/environment ] && [ -z "$SADMIN" ] ; then source /etc/environment ; fi 
if [ -z "$SADMIN" ]                                        # Advise user, SADMIN Env. Var. is a MUST
   then printf "\n[ ERROR ] Set 'SADMIN' environment variable to the install directory." 
        printf "\n  - Add a line similar to 'SADMIN=/opt/sadmin' in /etc/environment." 
        exit 1 
fi 
if [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]                   # If SADMIN shell library doesn't exist 
   then printf "\n[ ERROR ] SADMIN library '$SADMIN/lib/sadmlib_std.sh' can't be found.\n" ; exit 1 
fi 


# SADMIN Section of your program that is shared with SADMIN Bash Library.
export SADM_TPID="$$"                                      # Script Process ID.
export SADM_HOSTNAME=$(hostname -s)                        # Host name without Domain Name
export SADM_OS_TYPE=$(uname -s|tr '[:lower:]' '[:upper:]') # Return LINUX,AIX,DARWIN,SUNOS 
export SADM_USERNAME=$(id -un)                             # Current user name.
export SADM_DEBUG=0                                        # Debug Level(0-9), 0 = NoDebug
export SADM_EXIT_CODE=0                                    # Pgm. Default Exit Code
export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} "   # SSH CMD to Access Systems

# You Can Use & Change Variables Below To Your Needs (They Influence Execution Of Sadmin Library).
export SADM_VER='03.31.01'                                 # Script version number
export SADM_DESC="Describe what your program is doing."
export SADM_ROOT_ONLY="N"                                  # Pgm. run only by root ? [Y] or [N]
export SADM_SERVER_ONLY="N"                                # Pgm. run only on SADMIN server? [Y]/[N]
export SADM_GROUP_ONLY='N'                                 # Pgm. run only if usr part of SADMIN Grp
export SADM_LOG_TYPE="B"                                   # Write log to [S]creen, [L]og, [B]oth
export SADM_LOG_APPEND="N"                                 # Append log ? Y=AppendLog,N=CreateNewLog
export SADM_LOG_HEADER="Y"                                 # Y = ProduceLogHeader, N = NoLogHeader
export SADM_LOG_FOOTER="Y"                                 # Y = ProduceLogFooter, N = NoLogFooter
export SADM_MULTIPLE_EXEC="N"                              # Can Run Simultaneous copy of script Y/N
export SADM_USE_RCH="Y"                                    # Update the RCH History File (Y/N)
export SADM_QUIET="N"                                      # Y=HideMsg & Error#  N=Show Msg & Error#
export SADM_ERRMSG=""                                      # Error Message returned by Library 
export SADM_ERRNO=0                                        # Error number (0=OK) returned by Library
export SADM_PID_TIMEOUT=7200                               # Sec. before PID file is remove,7200=2hr
export SADM_LOCK_TIMEOUT=3600                              # Sec. before System LockFile is Del, 1hr
export SADM_DB_USED="N"             
export SADM_DB_NAME="sadmin"    
export SADM_TMP_FILE1=$(mktemp -q "$SADMIN/tmp/sadm_tmp1_XXX") # Make tmpfile1, rm in sadm_stop()
export SADM_TMP_FILE2=$(mktemp -q "$SADMIN/tmp/sadm_tmp2_XXX") # Make tmpfile2, rm in sadm_stop()
export SADM_TMP_FILE3=$(mktemp -q "$SADMIN/tmp/sadm_tmp3_XXX") # Make tmpfile3, rm in sadm_stop()

# Load SADMIN Bash Shell Library, ready to  be used.
. "${SADMIN}/lib/sadmlib_std.sh"                           # Init SADMIN tools, Load SADMIN Library

# Example of some functions and variable you can use.
export SADM_OS_NAME=$(sadm_get_osname)                     # REDHAT,ROCKY,ALMA,CENTOS,DEBIAN,UBUNTU.
export SADM_OS_VERSION=$(sadm_get_osversion)               # O/S Full Ver.No. (ex: 9.5)
export SADM_OS_MAJORVER=$(sadm_get_osmajorversion)         # O/S Major Ver. No. (ex: 9)
export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} "   # SSH CMD to Access Systems

# Variables Below Are Taken From SADMIN Configuration File (sadmin.cfg) when the Library is loaded.
# You Can Overridde them On A Per Program Basis (If Needed).
#export SADM_ALERT_GROUP="default"                          # Error Group Define in alert_group.cfg
#export SADM_WARNING_GROUP="default"                        # Warning Alert Group (alert_group.cfg)   
#export SADM_INFO_GROUP="default"                           # Info Alert Group (in alert_group.cfg)
#export SADM_ALERT_TYPE=1                                   # 0=NoAlert 1=OnError 2=OnOK 3=Always
#export SADM_MAIL_ADDR="your_email@domain.com"              # Send email to...default in sadmin.cfg
#export SADM_MAX_LOGLINE=400                                # Nb of Lines to trim (0=NoTrim)
#export SADM_MAX_RCHLINE=35                                 # Nb of Lines to trim (0=NoTrim)
#export SADM_ALERT_REPEAT=0                                 # 0=No Alert Repeat, Sec. between Repeat
# -------------------  E N D   O F   S A D M I N   C O D E    S E C T I O N  -----------------------










# --------------------------------------------------------------------------------------------------
#              V A R I A B L E S    L O C A L   T O     T H I S   S C R I P T
# --------------------------------------------------------------------------------------------------
#
lcount=0                                                                # Print Line Counter
first_page="Y"                                                          # No Form Feed on first page



# --------------------------------------------------------------------------------------------------
# Show script command line options
# --------------------------------------------------------------------------------------------------
show_usage()
{
    printf "\nUsage: %s%s%s [options]" "${BOLD}${CYAN}" $(basename "$0") "${NORMAL}"
    printf "\nDesc.: %s" "${BOLD}${CYAN}${SADM_DESC}${NORMAL}"
    printf "\n\n${BOLD}${GREEN}Options:${NORMAL}"
    printf "\n   ${BOLD}${YELLOW}[-d 0-9]${NORMAL}\t\tSet Debug (verbose) Level"
    printf "\n   ${BOLD}${YELLOW}[-h]${NORMAL}\t\t\tShow this help message"
    printf "\n   ${BOLD}${YELLOW}[-v]${NORMAL}\t\t\tShow script version information"
    printf "\n   ${BOLD}${YELLOW}[-p]${NORMAL}\t\t\tShow password on output"
    printf "\n   ${BOLD}${YELLOW}[-t]${NORMAL}\t\t\tShow TextBelt Key on output"
    printf "\n\n" 
}




# Print Standardize Line of each functions. 
#===================================================================================================
printline()
{
    p1=$1 ; p2=$2 ; p3=$3
    ((lcount++))                                                        # Incr. Print Line Number
    printf "\n[%03d] " $lcount                                          # Print Line Number
    if [ "$p1" != "" ] ; then printf "%-33s" "$p1"            ;fi
    if [ "$p2" != "" ] ; then printf "%-36s" "$p2"            ;fi  
    if [ "$p1" != "" ] && [ "$p2" != "" ] ; then printf "%-33s" ": ${p3}" ;fi
}



# Print Standardize Header Function 
#===================================================================================================
printheader()
{
    lcount=0 
    if [ "$first_page" = "Y" ] 
        then first_page="N" 
             printf "$1\n" 
        else printf "\f$1\n"     
    fi
    printf %100s |tr " " "="
}


# Print Standardize Section Header
#===================================================================================================
print_section_header()
{
    printf "\n\n## $1" 
}


# 01) Print SADMIN Functions available to Developers
#===================================================================================================
print_dev_functions()
{
    printheader "01) SADMIN Bash Library Functions Available To Developers"
    printline "\$(sadm_get_release)" "SADMIN Release Number (XX.XX)" "$(sadm_get_release)"
    printline "\$(sadm_get_ostype)" "OS Type (Uppercase,LINUX,AIX,DARWIN)" "$(sadm_get_ostype)"
    printline "\$(sadm_get_osversion)" "Return O/S Version (Ex: 7.2, 6.5)"  "$(sadm_get_osversion)"
    printline "\$(sadm_get_osmajorversion)" "Return O/S Major Version (Ex 7, 6)"  "$(sadm_get_osmajorversion)"  
    printline "\$(sadm_get_osminorversion)" "Return O/S Minor Version (Ex 2, 3)"  "$(sadm_get_osminorversion)" 
    printline "\$(sadm_get_osname)" "O/S Name (REDHAT,CENTOS,UBUNTU,...)" "$(sadm_get_osname)"
    printline "\$(sadm_get_oscodename)" "O/S Project Code Name" "$(sadm_get_oscodename)"
    printline "\$(sadm_get_username)" "Current User Name" "$(sadm_get_username)"
    printline "\$(sadm_get_kernel_version)" "O/S Running Kernel Version" "$(sadm_get_kernel_version)"
    printline "\$(sadm_get_kernel_bitmode)" "O/S Kernel Bit Mode (32 or 64)" "$(sadm_get_kernel_bitmode)"
    printline "\$(sadm_get_hostname)" "Current Host Name" "$(sadm_get_hostname)"
    printline "\$(sadm_get_host_ip)" "Current Host IP Address" "$(sadm_get_host_ip)"
    printline "\$(sadm_get_domainname)" "Current Host Domain Name" "$(sadm_get_domainname)"
    printline "\$(sadm_get_fqdn)" "Fully Qualified Domain Host Name" "$(sadm_get_fqdn)"
    printline "\$(sadm_server_serial)" "Server serial number (Ex: 4S7GYF1)" "$(sadm_server_serial)"
    printline "\$(sadm_server_cpu_speed)" "Server CPU Speed in MHz" "$(sadm_server_cpu_speed) MHz"
    printline "\$(sadm_server_nb_cpu)" "Number of Physical CPU on system" $(sadm_server_nb_cpu)
    printline "\$(sadm_server_nb_logical_cpu)" "Number of Logical CPU" $(sadm_server_nb_logical_cpu)
    printline "\$(sadm_server_core_per_socket)" "Number of Core per Socket" $(sadm_server_core_per_socket) 
    printline "\$(sadm_server_thread_per_core)" "Number of Thread per Core" $(sadm_server_thread_per_core)
    printline "\$(sadm_server_nb_socket)" "Number of socket on system" $(sadm_server_nb_socket)
    printline "\$(sadm_get_packagetype)" "Get package type (rpm,deb,aix,dmg)" "$(sadm_get_packagetype)"
    printline "\$(sadm_server_arch)" "System Architecture" "$(sadm_server_arch)"
    printline "sadm_lock_system \"hostname\"" "Lock the specified hostname" "0=Lock 1=Could not lock"
    printline "sadm_lock_status \"hostname\"" "Check if specified hostname is lock" "0=Not Lock - 1=System Locked"
    printline "sadm_unlock_system \"hostname\"" "Unlock the specified hostname" "0=Unlocked 1=Error could not unlock"
    printline "sadm_write_log \"message\"" "Write message to Screen, Log or Both" "message"
    printline "sadm_write_err \"message\"" "Write message to error log + std log" "message"
    printline "sadm_sendmail(mail,sub,body,att)" "Send email (attachment optional)" "0=Sent 1=Could not send"
    printline "sadm_silentremove 'filename'" "Delete a file silently" "0"
    printline "sadm_trimfile \"filename\" 35" "Keep the last 35 lines of filename." "0=Success  1=Error"  
    printline "sadm_sleep \"60\" \"15\"" "Sleep 60sec. at interval of 15sec." "60...45...30...15...0"
    printline "\$(sadm_get_epoch_time)" "Get Current Epoch Time" "$(sadm_get_epoch_time)"

    EPOCH_TIME=$(sadm_get_epoch_time)                                   # Save Epoch Time
    printline "\$(sadm_epoch_to_date $EPOCH_TIME)" "Convert epoch time to date" "$(sadm_epoch_to_date "$EPOCH_TIME")"

    WDATE=$(sadm_epoch_to_date $EPOCH_TIME)                             # Set Test Date
    printf "\n      WDATE='$WDATE'"                                     # Print Test Date
    printline "\$(sadm_date_to_epoch \"\$WDATE\")" "Convert Date to epoch time" $(sadm_date_to_epoch "$WDATE")
        
    pexample=""; pdesc=""; presult="";                                  # Clear Result Line
    DATE1="2016.01.30 10:00:44" ; DATE2="2016.01.30 10:00:03"           # Set Date to Calc Elapse
    printf "\n      DATE1='$DATE1'  DATE2='$DATE2'"                                     # Print Date2 Used for Ex.
    printline "\$(sadm_elapse \"\$DATE1\" \"\$DATE2\")" "Elapse Time between two timestamps" $(sadm_elapse "$DATE1" "$DATE2") 

    printline "sadm_show_version" "Cmdline '-v' this func. is called" ""
}



# 02) Print Variables that affect SADMIN Tools Behavior
#===================================================================================================
print_user_variables()
{ 

    printheader "02) SADMIN Section of your program that is shared with SADMIN Bash Library."
    printline "\$SADM_TPID"  "Script Process ID." "$SADM_TPID" 
    printline "\$SADM_HOSTNAME" "Host name without Domain Name" "$SADM_HOSTNAME" 
    printline "\$SADM_OS_TYPE" "Return LINUX,AIX,DARWIN,SUNOS" "$SADM_OS_TYPE" 
    printline "\$SADM_USERNAME" "Current UserName" "$SADM_USERNAME" #
    printline "\$SADM_DEBUG" "Debug Level (0-9), 0 = NoDebug" "$SADM_DEBUG" 
    printline "\$SADM_EXIT_CODE" "Current value of script exit code" "$SADM_EXIT_CODE" 
    printline "\$SADM_SSH_CMD" "SSH command to access client" "$SADM_SSH_CMD" 
    printf    "\n" 
    printline "\$SADM_PN" "Script Name With Extension" "$SADM_PN"
    printline "\$SADM_INST" "Script name(without extension)" "$SADM_INST" 
    printline "\$SADM_VER" "Program Version Number" "$SADM_VER" 
    printline "\$SADM_DESC" "Program Description" "$SADM_DESC" 
    printline "\$SADM_ROOT_ONLY" "Can only be run by 'root' user [Y/N]" "$SADM_ROOT_ONLY" 
    printline "\$SADM_SERVER_ONLY" "Can only run on SADMIN server [Y/N]" "$SADM_SERVER_ONLY"   
    printline "\$SADM_GROUP_ONLY" "Run only by user part of '$SADM_GROUP'" "$SADM_GROUP_ONLY"
    printline "\$SADM_MULTIPLE_EXEC" "Run only one instance of Pgm. [Y/N]" "$SADM_MULTIPLE_EXEC"
    printline "\$SADM_QUIET" "Y=HideMsg & Err#  N=Show Msg & Err#" "$SADM_QUIET"
    printline "\$SADM_LOG_TYPE" "Set Output to [S]creen [L]og [B]oth" "$SADM_LOG_TYPE"
    printline "\$SADM_LOG_APPEND" "Y=Append to Log, N=Create new log" "$SADM_LOG_APPEND" 
    printline "\$SADM_LOG_HEADER" "Generate Header in log [Y,N]" "$SADM_LOG_HEADER" 
    printline "\$SADM_LOG_FOOTER" "Generate Footer in log [Y/N]" "$SADM_LOG_FOOTER" 
    printline "\$SADM_USE_RCH" "Generate entry in '*.rch' file" "$SADM_USE_RCH" 
    printline "\$SADM_ERRNO" "0=OK, Error# returned by function" "$SADM_ERRNO"
    printline "\$SADM_ERRMSG" "Error Msg returned by function" "$SADM_ERRMSG"  
    printline "\$SADM_PID_TIMEOUT"  "Stop Pgm. if running more than x sec" "$SADM_PID_TIMEOUT Sec."
    printline "\$SADM_LOCK_TIMEOUT" "Remove the system lock after X sec."  "$SADM_LOCK_TIMEOUT Sec."


    print_section_header "Override the default values defined in sadmin.cfg for this program of yours."  
    printline "\$SADM_ALERT_TYPE" "0=NoAlert 1=OnError 2=OnOK 3=Always" "$SADM_ALERT_TYPE" 
    printline "\$SADM_ALERT_GROUP" "Error Group Name (Default)" "$SADM_ALERT_GROUP"
    printline "\$SADM_WARNING_GROUP" "Warning Alert group Name" "$SADM_WARNING_GROUP" 
    printline "\$SADM_INFO_GROUP" "Infor Alert Group Name" "$SADM_INFO_GROUP" 
    printline "\$SADM_ALERT_REPEAT" "0=NoAlertRepeat, Repeat every sec." "$SADM_ALERT_REPEAT Sec."
    printline "\$SADM_MAIL_ADDR" "Email Address of SADMIN SysAdmin " "$SADM_MAIL_ADDR" 
    printline "\$SADM_MAX_LOGLINE" "Nb of Lines to trim (0=NoTrim)" "$SADM_MAX_LOGLINE lines." 
    printline "\$SADM_MAX_RCHLINE" "Nb of Lines to trim (0=NoTrim)" "$SADM_MAX_RCHLINE lines." 
} 



# 3) Print Python sa.start() and sa.stop() function Used by SADMIN Tools
#===================================================================================================
function print_start_stop()
{
    printheader "3) Summary of the 'sadm_start()' and 'sadm_stop()' functions in SADMIN Bash Library"

    echo ""
    echo "'sadm_start()' - Bash Library Function   "
    echo ""
    echo "    The 'sadm_start()' function basically initialize the SADMIN environment."
    echo "    When you call 'sadm_start()', it will only come back to caller if everything went OK."
    echo "    Otherwise, it will advise the user of the error and exit(1)."
    echo ""
    echo "  Summary of the parts that 'sadm_start()' perform :"
    echo "    1) Step one, make sure all \$SADMIN directories & sub-dir. exist and have proper permissions."
    echo "    2) If \$SADM_LOG_APPEND='N', create new log & error log or append to existing log."
    echo "    3) If \$SADM_LOG_HEADER='Y', Include or not the script header in the log [Y/N]."
    echo "    4) if \$SADM_ROOT_ONLY='Y', The script can only be run by 'root' user [Y/N]."
    echo "       If user is not 'root', we advise the user and exit(1)."
    echo "    5) If \$SADM_SERVER_ONLY='Y', and not on the SADMIN server, show error message and exit(1)."
    echo "    6) If \$SADM_GROUP_ONLY='Y', and the user is not part of the SADM_GROUP (unless 'root'), "
    echo "       show error message and exit(1)."
    echo "    7) If \$SADM_USE_RCH='Y', write starting time to the RCH file (With a code 2=Running)."
    echo "    8) If system is lock and running on the SADMIN server, issue message and exit(1)"
    echo "    9) If PID file '\$SADM_PID_FILE' exist and '\$SADM_MULTIPLE_EXEC='Y'', continue normal execution"
    echo "       If PID file exist and execution time (sec) is less than the '\$SADM_PID_TIMEOUT', show error message and exit(1)."
    echo "       If PID file exist and execution time (sec) exceed the '\$SADM_PID_TIMEOUT' a new '\$SADM_PID_FILE' is created"
    echo "       and execution is resume."
    echo " "
    echo "   Notes:  If any unrecoverable error occurs while executing 'sadm_start()', it will advise" 
    echo "           the user of the error and exit(1). See example in '$SADMIN/bin/sadm_template.sh'."
    echo ""
    echo ""
    echo "'sadm_stop(exit_code)'"
    echo "    The sadm_stop(exitcode) basically collect and write information in log and in 'rch' file."
    echo ""
    echo "  Summary of the parts that 'sadm_stop()' does :"
    echo "    1) Calculate execution Time."
    echo "    2) If $SADM_USE_RCH='Y', update the rch file (End Time & Elapse Time ...)."
    echo "    3) Validate the alert group, "
    echo "    4) If $SADM_LOG_FOOTER='Y', write the log footer."
    echo "    5) If the error log file is empty, then delete it."
    echo "    6) Delete the PID file ($SADM_PID_FILE) of the program."
    echo "    7) Close log and error log files."
    echo "    8) If $SADM_MAX_LOGLINE is not zero, trim the log according to user choice in '$SADM_MAX_LOGLINE'."
    echo "    9) If $SADM_MAX_RCLINE is not zero, trim the 'rch' according to user choice in 'SADM_MAX_RCLINE'." 
    echo "   10) Set permission and owner/group to log and rch files."
    echo "   11) If on the SADMIN server, then rch and log are immediatly web central directory."
    echo " "
    echo "    Notes: This should be the one of the last function called at the end of your program."
    echo "           See example in '$SADMIN/bin/sadm_template.sh'."
    echo ""
}





# 4) Print sadmin.cfg Variables available to users
#===================================================================================================
print_sadmin_cfg()
{
    printheader "4) Variables Available reflecting values from SADMIN configuration file."

    print_section_header "----- General Section -----"
    printline "\$SADM_SERVER" "SADMIN SERVER NAME (FQDN)" "$SADM_SERVER" 
    printline "\$SADM_HOST_TYPE" "SADMIN HOST TYPE" "$SADM_HOST_TYPE"
    printline "\$SADM_CIE_NAME" "Your Company Name" "$SADM_CIE_NAME"
    printline "\$SADM_DOMAIN" "Server Creation Default Domain" "$SADM_DOMAIN" 
    printline "\$SADM_USER" "SADMIN User Name" "$SADM_USER"
    printline "\$SADM_GROUP" "SADMIN Group Name" "$SADM_GROUP"
    printline "\$SADM_PWD_RANDOM" "Auto generation of '$SADM_USER' password" "$SADM_PWD_RANDOM"
    printline "\$SADM_PID_TIMEOUT" "PID File Time To Live default in sec" "$SADM_PID_TIMEOUT Sec."
    printline "\$SADM_LOCK_TIMEOUT" "Maximum of sec. a system can be lock" "$SADM_LOCK_TIMEOUT Sec."


    print_section_header "----- Database Section -----"
    printline "\$SADM_DBNAME" "SADMIN Database Name" "$SADM_DBNAME"
    printline "\$SADM_DBHOST" "SADMIN Database Host" "$SADM_DBHOST"
    printline "\$SADM_DBPORT" "SADMIN Database Host TCP Port" "$SADM_DBPORT"
    # Read Only User (default is 'squery')
    printline "\$SADM_RO_DBUSER" "SADMIN Database Read Only User" "$SADM_RO_DBUSER"
    presult="$SADM_RO_DBPWD"                                            # Actual Content of Variable
    if [ "$show_password" = "N" ] ; then presult="*Hidden*" ;fi         # Don't show DB Password
    printline "\$SADM_RO_DBPWD" "SADMIN Database Read Only User Pwd" "$presult"
    # Read & Write User (default is 'sadmin')
    printline "\$SADM_RW_DBUSER" "SADMIN Database Read/Write User" "$SADM_RW_DBUSER"
    presult="$SADM_RW_DBPWD"                                            # Actual Content of Variable
    if [ "$show_password" = "N" ] ; then presult="*Hidden*" ;fi         # Don't show DB Password
    printline "\$SADM_RW_DBPWD" "SADMIN Database Read/Write User Pwd" "$presult"
    presult="$DBPASSFILE"
    if [ "$show_password" = "N" ] ; then presult="*Hidden*" ;fi 
    printline "\$DBPASSFILE" "SADMIN Database User Password File" "$presult"


    print_section_header "----- Web Interface Section -----"
    printline "\$SADM_WWW_USER" "User that Run Apache Web Server" "$SADM_WWW_USER"
    printline "\$SADM_WWW_GROUP" "Group that Run Apache Web Server" "$SADM_WWW_GROUP"
    printline "\$SADM_MONITOR_UPDATE_INTERVAL" "Monitor page update interval in sec." "$SADM_MONITOR_UPDATE_INTERVAL Sec." 
    printline "\$SADM_MONITOR_RECENT_COUNT" "Monitor page nb. recent scripts" "$SADM_MONITOR_RECENT_COUNT line(s)." 
    printline "\$SADM_MONITOR_RECENT_EXCLUDE" "Scripts excluded from SysMon Recent" "$SADM_MONITOR_RECENT_EXCLUDE"


    print_section_header "----- Email Section -----"
    printline "\$SADM_MAIL_ADDR" "SADMIN Administrator Default Email" "$SADM_MAIL_ADDR"
    printline "\$SADM_SMTP_SERVER" "Your Internet SMTP Server Name" "$SADM_SMTP_SERVER" 
    printline "\$SADM_SMTP_PORT" "Your Internet SMTP Server Port" "$SADM_SMTP_PORT"
    printline "\$SADM_SMTP_SENDER" "Your Internet Sender Email" "$SADM_SMTP_SENDER"
    presult="$SADM_GMPWD"         
    if [ "$show_password" = "N" ] ; then presult="*Hidden*" ;fi         # Don't show Mail Password
    printline "\$SADM_GMPW" "Your Internet Sender Password" "$SADM_GMPW"
    printline "\$SADM_EMAIL_STARTUP" "Email Administrator on Startup" "$SADM_EMAIL_STARTUP" 
    printline "\$SADM_EMAIL_SHUTDOWN" "Email Administrator on Shutdown" "$SADM_EMAIL_SHUTDOWN"


    print_section_header "----- Monitoring Section -----"
    printline "\$SADM_ALERT_TYPE" "0=NoMail 1=OnError 2=OnSuccess 3=All" "$SADM_ALERT_TYPE"
    printline "\$SADM_ALERT_REPEAT" "Seconds to wait before repeat alert" "$SADM_ALERT_REPEAT"
    printline "\$SADM_ALERT_GROUP" "Error Group Name (Default Group)" "$SADM_ALERT_GROUP" 
    printline "\$SADM_WARNING_GROUP" "Default Alert Group" "$SADM_WARNING_GROUP" 
    printline "\$SADM_INFO_GROUP" "Default Alert Group" "$SADM_INFO_GROUP" 
    printline "\$SADM_SSH_PORT" "SSH Port to communicate with client" "$SADM_SSH_PORT"
    # Alerting with Textbelt   
    presult="*Hidden*"                                                      # Default Hidden
    if [ "$show_textbelt" = "Y" ] ;then presult="$SADM_TEXTBELT_KEY" ;fi    # TextBelt API Key
    printline "\$SADM_TEXTBELT_URL" "TextBelt.com API URL" "$SADM_TEXTBELT_URL"
    printline "\$SADM_TEXTBELT_KEY" "TextBelt.com API Key" "$SADM_TEXTBELT_KEY"
    # Alerting with NTFY 
    printline "\$SADM_NTFY_EMAIL" "NTFY Email Address" "$SADM_NTFY_EMAIL"                
    printline "\$SADM_NTFY_PWD"   "NTFY Password"      "$SADM_NTFY_PWD"     
    printline "\$SADM_NTFY_TOKEN" "NTFY Token"         "$SADM_NTFY_TOKEN"      
    printline "\$SADM_NTFY_TOPIC" "NTFY Topic"         "$SADM_NTFY_TOPIC"        
    printline "\$SADM_NTFY_URL"   "NTFY URL"           "$SADM_NTFY_URL"
    printline "\$SADM_NTFY_USER"  "NTFY User"          "$SADM_NTFY_USER"                 


    print_section_header "----- Files and Logs pruning Section -----" 
    printline "\$SADM_RCH_KEEPDAYS" "Nb. days to keep unmodified rch file" "$SADM_RCH_KEEPDAYS days"
    printline "\$SADM_LOG_KEEPDAYS" "Nb. days to keep unmodified log file" "$SADM_LOG_KEEPDAYS days"
    printline "\$SADM_MAX_RCHLINE" "Trim rch file to this max. of lines" "$SADM_MAX_RCHLINE lines"
    printline "\$SADM_MAX_LOGLINE" "Trim log to this maximum of lines" "$SADM_MAX_LOGLINE lines"
    printline "\$SADM_DAYS_HISTORY" "Days to keep alert in History file" "$SADM_DAYS_HISTORY days"
    printline "\$SADM_MAX_ARC_LINE" "Max lines to keep in alert Archive" "$SADM_MAX_ARC_LINE lines"
    printline "\$SADM_NMON_KEEPDAYS" "Nb. of days to keep nmon perf. file" "$SADM_NMON_KEEPDAYS days"


    print_section_header "----- Subnet Network Scanner Section -----"
    printline "\$SADM_NETWORK1" "Network/Netmask 1 inv. IP/Name/Mac" "$SADM_NETWORK1"
    printline "\$SADM_NETWORK2" "Network/Netmask 2 inv. IP/Name/Mac" "$SADM_NETWORK2"
    printline "\$SADM_NETWORK3" "Network/Netmask 3 inv. IP/Name/Mac" "$SADM_NETWORK3"
    printline "\$SADM_NETWORK4" "Network/Netmask 4 inv. IP/Name/Mac" "$SADM_NETWORK4"
    printline "\$SADM_NETWORK5" "Network/Netmask 5 inv. IP/Name/Mac" "$SADM_NETWORK5"


    print_section_header "----- ReaR Backup Section -----"
    printline "\$SADM_REAR_BACKUP_SCRIPT" "Rear Backup Script Name" "$SADM_REAR_BACKUP_SCRIPT"
    printline "\$SADM_REAR_NFS_SERVER" "Rear NFS Server IP or Name" "$SADM_REAR_NFS_SERVER"
    printline "\$SADM_REAR_NFS_SERVER_VER" "Rear NFS Server Version" "$SADM_REAR_NFS_SERVER_VER"
    printline "\$SADM_REAR_NFS_MOUNT_POINT" "Rear NFS Mount Point" "$SADM_REAR_NFS_MOUNT_POINT" 
    printline "\$SADM_REAR_BACKUP_TO_KEEP" "Rear Number of backup to keep" "$SADM_REAR_BACKUP_TO_KEEP copies."
    printline "\$SADM_REAR_BACKUP_DIF" "Rear Backup - Size Difference Alert" "${SADM_REAR_BACKUP_DIF}%"
    printline "\$SADM_REAR_BACKUP_INTERVAL" "Rear alert if Backup older than" "$SADM_REAR_BACKUP_INTERVAL days"
    printline "\$SADM_REAR_DEL_FAILED_BACKUP" "Del backup if failed integrity check" "$SADM_REAR_DEL_FAILED_BACKUP"
    printline "\$SADM_REAR_CONCURRENT" "Concurrent backup processes" "$SADM_REAR_CONCURRENT"
    printline "\$SADM_REAR_BATCH_MODE" "Run script in batch mode (Y/N)" "$SADM_REAR_BATCH_MODE" 
    printline "\$SADM_REAR_BATCH_START_TIME" "Start time for launch batch backup" "$SADM_REAR_BATCH_START_TIME"  
    printline "\$SADM_REAR_BATCH_DAY2RUN" "0=AnyDay, 1=Su,2=Mo,3=Tu,...7=Sa" "$SADM_REAR_BATCH_DAY2RUN"
    printline "\$SADM_REAR_BATCH_MTH2RUN" "0=AnyMth, Months Numbers 1,2,12" "$SADM_REAR_BATCH_MTH2RUN"
    printline "\$SADM_REAR_BATCH_DATE2RUN" "0=AnyDate, Date to run [1,2...27,28]" "$SADM_REAR_BATCH_DATE2RUN"


    print_section_header "----- Backup Section -----"
    printline "\$SADM_BACKUP_NFS_SERVER" "NFS Backup IP or Server Name" "$SADM_BACKUP_NFS_SERVER"   
    printline "\$SADM_BACKUP_NFS_SERVER_VER" "NFS Backup server Version" "$SADM_BACKUP_NFS_SERVER_VER"
    printline "\$SADM_BACKUP_NFS_MOUNT_POINT" "NFS Backup Mount Point" "$SADM_BACKUP_NFS_MOUNT_POINT"
    printline "\$SADM_BACKUP_DIF" "Alert if cur. vs prev. size differ   " "${SADM_BACKUP_DIF}%"
    printline "\$SADM_BACKUP_INTERVAL" "Alert if Backup older than X days" "$SADM_BACKUP_INTERVAL days"
    printline "\$SADM_DAILY_BACKUP_TO_KEEP" "Nb. of Daily Backup to keep" "$SADM_DAILY_BACKUP_TO_KEEP copies"
    printline "\$SADM_WEEKLY_BACKUP_TO_KEEP" "Nb. of Weekly Backup to keep" "$SADM_WEEKLY_BACKUP_TO_KEEP copies"
    printline "\$SADM_MONTHLY_BACKUP_TO_KEEP" "Nb. of Monthly Backup to keep" "$SADM_MONTHLY_BACKUP_TO_KEEP copies"
    printline "\$SADM_YEARLY_BACKUP_TO_KEEP" "Nb. of Yearly Backup to keep" "$SADM_YEARLY_BACKUP_TO_KEEP copies"
    printline "\$SADM_WEEKLY_BACKUP_DAY" "Weekly Backup Day (1=Mon,...,7=Sun)" "$SADM_WEEKLY_BACKUP_DAY"
    printline "\$SADM_MONTHLY_BACKUP_DATE" "Monthly Backup Date (1-28)" "$SADM_MONTHLY_BACKUP_DATE"
    printline "\$SADM_YEARLY_BACKUP_MONTH" "Month to take Yearly Backup (1-12)" "$SADM_YEARLY_BACKUP_MONTH"
    printline "\$SADM_YEARLY_BACKUP_DATE" "Date to do Yearly Backup(1-DayInMth)" "$SADM_YEARLY_BACKUP_DATE"
    printline "\$SADM_BACKUP_BATCH_MODE" "Run backup script in batch mode (Y/N)" "$SADM_BACKUP_BATCH_MODE"
    printline "\$SADM_BACKUP_BATCH_START_TIME" "Start time for launch batch backup" "$SADM_BACKUP_BATCH_START_TIME"
    printline "\$SADM_BACKUP_CONCURRENT" "Concurrent backup processes" "$SADM_BACKUP_CONCURRENT"
    printline "\$SADM_BACKUP_BATCH_DAY2RUN" "0=AnyDay, 1=Su,2=Mo,3=Tu,...7=Sa" "$SADM_BACKUP_BATCH_DAY2RUN"
    printline "\$SADM_BACKUP_BATCH_MTH2RUN" "0=AnyMth, Months Numbers 1,2,12" "$SADM_BACKUP_BATCH_MTH2RUN"
    printline "\$SADM_BACKUP_BATCH_DATE2RUN" "0=AnyDate, Date to run [1,2...27,28]" "$SADM_BACKUP_BATCH_DATE2RUN"


    print_section_header "----- Virtual Machine Export Section -----"
    printline "\$SADM_VM_EXPORT_SCRIPT" "Virtual Machine Export Script Name" "$SADM_VM_EXPORT_SCRIPT"
    printline "\$SADM_VM_EXPORT_NFS_SERVER" "NFS Export Server" "$SADM_VM_EXPORT_NFS_SERVER"
    printline "\$SADM_VM_EXPORT_NFS_SERVER_VER" "Version du server NFS (3,4)" "$SADM_VM_EXPORT_NFS_SERVER_VER"
    printline "\$SADM_VM_EXPORT_MOUNT_POINT" "NFS Export Mount Point" "$SADM_VM_EXPORT_MOUNT_POINT"
    printline "\$SADM_VM_EXPORT_DIF" "Alert if cur. vs prev. size differ" "${SADM_VM_EXPORT_DIF}%"
    printline "\$SADM_VM_EXPORT_TO_KEEP" "Nb. of export to keep" "$SADM_VM_EXPORT_TO_KEEP copies."
    printline "\$SADM_VM_EXPORT_INTERVAL" "Alert if export older than X days" "$SADM_VM_EXPORT_INTERVAL days."
    printline "\$SADM_VM_EXPORT_ALERT" "Issue an alert if interval reached" "$SADM_VM_EXPORT_ALERT"
    printline "\$SADM_VM_USER" "User part of 'vboxusers' user group" "$SADM_VM_USER"
    printline "\$SADM_VM_STOP_TIMEOUT" "Max. seconds given for acpi shutdown" "$SADM_VM_STOP_TIMEOUT seconds." 
    printline "\$SADM_VM_START_INTERVAL" "Sec. to sleep between each VM start"  "$SADM_VM_START_INTERVAL seconds."
    printline "\$SADM_VM_EXPORT_CONCURRENT" "Concurrent backup processes" "$SADM_VM_EXPORT_CONCURRENT"
    printline "\$SADM_VM_EXPORT_BATCH_MODE" "Run export in batch mode (Y/N)" "$SADM_VM_EXPORT_BATCH_MODE"
    printline "\$SADM_VM_EXPORT_BATCH_START_TIME" "Start time for launch batch backup" "$SADM_VM_EXPORT_BATCH_START_TIME"
    printline "\$SADM_VM_EXPORT_BATCH_DAY2RUN" "0=AnyDay, 1=Su,2=Mo,3=Tu,...7=Sa" "$SADM_VM_EXPORT_BATCH_DAY2RUN"
    printline "\$SADM_VM_EXPORT_BATCH_MTH2RUN" "0=AnyMth, Months Numbers 1,2,12" "$SADM_VM_EXPORT_BATCH_MTH2RUN"
    printline "\$SADM_VM_EXPORT_BATCH_DATE2RUN" "0=AnyDate, Date to run [1,2...27,28]" "$SADM_VM_EXPORT_BATCH_DATE2RUN"


    print_section_header "----- SADMIN Operating System Update Section -----"
    printline "\$SADM_OSUPDATE_SCRIPT" "Name of O/S update script" "$SADM_OSUPDATE_SCRIPT"
    printline "\$SADM_OSUPDATE_INTERVAL" "Threshold between o/s update in days" "$SADM_OSUPDATE_INTERVAL days"
    printline "\$SADM_OSUPDATE_AUTOREMOVE" "Remove unused package after update" "$SADM_OSUPDATE_AUTOREMOVE"
    printline "\$SADM_OSUPDATE_FLATPAK" "Also Update the Flatpak package" "$SADM_OSUPDATE_FLATPAK"
    printline "\$SADM_OSUPDATE_SNAP" "Also Update the Snap package" "$SADM_OSUPDATE_SNAP"
    printline "\$SADM_OSUPDATE_REBOOT_NEEDED" "If reboot is needed after O/S update" "$SADM_OSUPDATE_REBOOT_NEEDED"
    printline "\$SADM_OSUPDATE_REBOOT_TIME" "Seconds to wait for starting Apps." "$SADM_OSUPDATE_REBOOT_TIME Seconds"
    printline "\$SADM_OSUPDATE_LOCK" "Lock system during O/S update Y/N" "$SADM_OSUPDATE_LOCK"
    printline "\$SADM_OSUPDATE_CONCURRENT" "Concurrent backup processes" "$SADM_OSUPDATE_CONCURRENT"
    printline "\$SADM_OSUPDATE_BATCH_MODE" "Run O/S Update in batch mode (Y/N)" "$SADM_OSUPDATE_BATCH_MODE"
    printline "\$SADM_OSUPDATE_BATCH_START_TIME" "Start time for launch batch update" "$SADM_OSUPDATE_BATCH_START_TIME"
    printline "\$SADM_OSUPDATE_BATCH_DAY2RUN" "0=AnyDay, 1=Su,2=Mo,3=Tu,...7=Sa" "$SADM_OSUPDATE_BATCH_DAY2RUN"
    printline "\$SADM_OSUPDATE_BATCH_MTH2RUN" "0=AnyMth, Months Numbers 1,2,12" "$SADM_OSUPDATE_BATCH_MTH2RUN"
    printline "\$SADM_OSUPDATE_BATCH_DATE2RUN" "0=AnyDate, Date to run [1,2...27,28]" "$SADM_OSUPDATE_BATCH_DATE2RUN"

}



#===================================================================================================
# 5) Print Directories Variables Available to Users
#===================================================================================================
print_directory()
{
    printheader " 5) Print Directories Variables Available to Users" 

    printline "\$SADM_BASE_DIR" "SADMIN Root Directory" "$SADM_BASE_DIR"
    printline "\$SADM_BIN_DIR" "Programs Directory" "$SADM_BIN_DIR"
    printline "\$SADM_TMP_DIR" "Temporary file(s) Directory" "$SADM_TMP_DIR"
    printline "\$SADM_LIB_DIR" "Libraries Directory" "$SADM_LIB_DIR"
    printline "\$SADM_LOG_DIR" "SADMIN Script Log Directory" "$SADM_LOG_DIR"
    printline "\$SADM_CFG_DIR" "SADMIN Configuration Directory" "$SADM_CFG_DIR"
    printline "\$SADM_SYS_DIR" "Server Startup/Shutdown Script Dir." "$SADM_SYS_DIR"
    printline "\$SADM_DOC_DIR" "Documentation Directory" "$SADM_DOC_DIR"
    printline "\$SADM_PKG_DIR" "Packages Directory" "$SADM_PKG_DIR"
    printline "\$SADM_DAT_DIR" "Data Directory" "$SADM_DAT_DIR"
    printline "\$SADM_NMON_DIR" "NMON Data Collected Directory." "$SADM_NMON_DIR"
    printline "\$SADM_DR_DIR" "Disaster Recovery Directory" "$SADM_DR_DIR"
    printline "\$SADM_RCH_DIR" "Server Return Code History Dir." "$SADM_RCH_DIR"
    printline "\$SADM_NET_DIR" "Server Network Info Dir." "$SADM_NET_DIR"
    printline "\$SADM_RPT_DIR" "SYStem MONitor Report Directory" "$SADM_RPT_DIR"
    printline "\$SADM_DBB_DIR" "Database Backup Directory" "$SADM_DBB_DIR"
    printline "\$SADM_SETUP_DIR" "SADMIN Installation/Update Dir." "$SADM_SETUP_DIR"

    printline "\$SADM_USR_DIR" "User/System specific directory " "$SADM_USR_DIR"
    printline "\$SADM_UBIN_DIR" "User/System specific bin/script Dir." "$SADM_UBIN_DIR"
    printline "\$SADM_ULIB_DIR" "User/System specific library Dir." "$SADM_ULIB_DIR"
    printline "\$SADM_UDOC_DIR" "User/System specific documentation" "$SADM_UDOC_DIR"
    printline "\$SADM_UMON_DIR" "User/System specific SysMon Scripts" "$SADM_UMON_DIR"
    
    printline "\$SADM_WWW_DIR" "SADMIN Web Site Root Directory" "$SADM_WWW_DIR"
    printline "\$SADM_WWW_DOC_DIR" "SADMIN Web Documentation Dir." "$SADM_WWW_DOC_DIR"
    printline "\$SADM_WWW_DAT_DIR" "SADMIN Web Site Systems Data Dir." "$SADM_WWW_DAT_DIR"
    printline "\$SADM_WWW_LIB_DIR" "SADMIN Web Site PHP Library Dir." "$SADM_WWW_LIB_DIR"
    printline "\$SADM_WWW_TMP_DIR" "SADMIN Web Temp Working Directory" "$SADM_WWW_TMP_DIR"
    printline "\$SADM_WWW_PERF_DIR" "SADMIN Web Performance Graph Dir." "$SADM_WWW_PERF_DIR"
}


# 6) Print Files Variables Available to Users
#===================================================================================================
print_file_variable()
{
    printheader " 6) Print Files Variables Available to Users" 

    printline "\$SADM_LOG_FILE" "Program Log File" "$SADM_LOG"
    printline "\$SADM_ERR_FILE" "Program Error Log file." "$SADM_ELOG"
    printline "\$SADM_RCH_FILE" "Pgm. [R]eturn [C]ode [H]istory File" "$SADM_RCH_FILE"
    printline "\$SADM_PID_FILE" "Program PID Lock File" "$SADM_PID_FILE"
    printline "\$SADM_TMP_FILE1" "Temporary File 1 (avail. to you)" "$SADM_TMP_FILE1"
    printline "\$SADM_TMP_FILE2" "Temporary File 2 (avail. to you)" "$SADM_TMP_FILE2"
    printline "\$SADM_TMP_FILE3" "Temporary File 3 (avail. to you)" "$SADM_TMP_FILE3"
    printline "\$SADM_CFG_FILE" "Main Configuration File" "$SADM_CFG_FILE" 
    printline "\$SADM_CFG_HIDDEN" "Template of Main Configuration File" "$SADM_CFG_HIDDEN"
    printline "\$SADM_ALERT_FILE" "Alert Group File" "$SADM_ALERT_FILE"
    printline "\$SADM_ALERT_INIT" "Template of Alert Group File" "$SADM_ALERT_INIT"  
    printline "\$SADM_ALERT_HIST" "Alert History File" "$SADM_ALERT_HIST"
    printline "\$SADM_ALERT_HINI" "Template of Alert History File" "$SADM_ALERT_HINI"
    printline "\$SADM_RPT_FILE" "System Monitor Report File" "$SADM_RPT_FILE"
    printline "\$SADM_BACKUP_LIST" "Backup List File Name" "$SADM_BACKUP_LIST"
    printline "\$SADM_BACKUP_LIST_INIT" "Template of Backup List" "$SADM_BACKUP_LIST_INIT"
    printline "\$SADM_BACKUP_EXCLUDE" "Backup Exclude List File Name" "$SADM_BACKUP_EXCLUDE"
    printline "\$SADM_BACKUP_EXCLUDE_INIT" "Template Backup Exclude" "$SADM_BACKUP_EXCLUDE_INIT"
    return 0
}







# 7) Print Command Path Variables available to users
#===================================================================================================
print_command_path()
{
    printheader "7) Alias use to override malicious path changes"
    printline "\$SADM_DMIDECODE" "'dmidecode' use to get model & type" "$SADM_DMIDECODE"
    printline "\$SADM_BC" "'bc' use to do some Math." "$SADM_BC"  
    printline "\$SADM_FDISK" "'fdisk' use to get partition info" "$SADM_FDISK"
    printline "\$SADM_WHICH" "'which' use to get command path" "$SADM_WHICH"
    printline "\$SADM_PERL" "'perl' epoch time Math on AIX" "$SADM_PERL"
    printline "\$SADM_MUTT" "'mutt' use to send email" "$SADM_MUTT"
    printline "\$SADM_CURL" "'curl' Use to send alert to Slack" "$SADM_CURL"
    printline "\$SADM_LSCPU" "'lscpu' To get Socket/Thread info" "$SADM_LSCPU"
    printline "\$SADM_NMON" "'nmon' Collect Performance Stat." "$SADM_NMON"
    printline "\$SADM_PARTED" "'parted' use to get disk real size" "$SADM_PARTED"
    printline "\$SADM_ETHTOOL" "'ethtool' use to get system IP" "$SADM_ETHTOOL"
    printline "\$SADM_RRDTOOL" "'rrdtool' binary location" "$SADM_RRDTOOL"
    printline "\$SADM_LSB_RELEASE" "'lsb_release' cmd (get dist. info)" "$SADM_LSB_RELEASE"
    printline "\$SADM_INXI" "'inxi' binary location" "$SADM_INXI"
    if [ "$SADM_HOST_TYPE" = "S" ]                                      # Only on SADMIN Server
        then printline "\$SADM_MYSQL" "'mysql' binary location" "$SADM_MYSQL"
    fi 
    printline "\$SADM_SSH" "'ssh' use to SSH on SADMIN client" "$SADM_SSH"
    printline "\$SADM_SED" "'sed' binary location" "$SADM_SED"
    sadm_write_log " "
}




#===================================================================================================
# 8) Print Database Information
#===================================================================================================
print_db_variables()
{
    printheader "8) Database Information" 

    CMDLINE="$SADM_MYSQL -t -u $SADM_RO_DBUSER  -p$SADM_RO_DBPWD "      # MySQL Auth/Read Only User

    #printf "\n\nShow SADMIN Tables:\n"
    #SQL="show tables; "                                                 # Show Table SQL
    #$CMDLINE -h $SADM_DBHOST $SADM_DBNAME -Ne "$SQL" | grep -v 'pma__'

    print_section_header "----- Server Table Section -----"
    printf "\n"
    #SQL="select srv_name, srv_desc, srv_osname, srv_osversion, srv_active, srv_cat, srv_group from server ; "
    SQL="describe server; "
    $CMDLINE -h $SADM_DBHOST $SADM_DBNAME -Ne "$SQL" 
    SQL="SHOW keys FROM server FROM sadmin;"
    $CMDLINE -h $SADM_DBHOST $SADM_DBNAME -Ne "$SQL" 

    print_section_header "----- Category & Group Table Section -----"
    printf "\n"
    SQL="describe server_category; "                                    # Show Table Format/colums
    $CMDLINE -h $SADM_DBHOST $SADM_DBNAME -Ne "$SQL" 
    #SQL="select * from server_category; "                               # Show Table SQL
    #$CMDLINE -h $SADM_DBHOST $SADM_DBNAME -Ne "$SQL" 
    SQL="SHOW keys FROM server_category FROM sadmin;"
    $CMDLINE -h $SADM_DBHOST $SADM_DBNAME -Ne "$SQL" 

    #print_section_header "----- Group Table Section -----"
    SQL="show columns from server_group; "                              # Show Table Format/columns
    $CMDLINE -h $SADM_DBHOST $SADM_DBNAME -Ne "$SQL" 
    #SQL="select * from server_group; "                                  # Show Table SQL
    #$CMDLINE -h $SADM_DBHOST $SADM_DBNAME -Ne "$SQL" 
    SQL="SHOW keys FROM server_group FROM sadmin;"
    $CMDLINE -h $SADM_DBHOST $SADM_DBNAME -Ne "$SQL" 

    print_section_header "----- Script Table Section -----"
    SQL="describe script; "
    $CMDLINE -h $SADM_DBHOST $SADM_DBNAME -Ne "$SQL" 
    SQL="SHOW keys FROM script FROM sadmin;"
    $CMDLINE -h $SADM_DBHOST $SADM_DBNAME -Ne "$SQL" 

    printf "\n\n"
    #Script Details:\n"
    SQL="describe script_rch; "
    $CMDLINE -h $SADM_DBHOST $SADM_DBNAME -Ne "$SQL" 
    SQL="SHOW keys FROM script_rch FROM sadmin;"
    $CMDLINE -h $SADM_DBHOST $SADM_DBNAME -Ne "$SQL" 

}






# --------------------------------------------------------------------------------------------------
# Command line Options functions
# Evaluate Command Line Switch Options Upfront
#   -d[0-9] Set Debug Level  
#   -h) Show Help Usage, 
#   -v) Show Script Version,  
#   -t) Show TextBelt Keys
#   -p) Show password on output
#   -X) Delete the script PID file before running the script.
# --------------------------------------------------------------------------------------------------
function cmd_options()
{
    show_password="N"                                                   # Don't show DB Password
    show_textbelt="N"                                                   # Don't show TextBelt Key

    while getopts "d:hvXpt" opt ; do                                    # Loop to process Switch
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
            p) show_password="Y"                                        # Flag to Show DB Password
               ;;                                                       
            t) show_textbelt="Y"                                        # Flag to Show TextBelt Key
               ;;                  
            v) sadm_show_version                                        # Show Script Version Info
               exit 0                                                   # Back to shell
               ;;
            X) /usr/bin/rm -f "${SADMIN}/tmp/${SADM_INST}.pid" >/dev/null 2>&1
               printf "\nThe PID File '${SADMIN}/tmp/${SADM_INST}.pid' is now removed.\n" 
               ;;
           \?) printf "\nInvalid option: ${OPTARG}.\n"                  # Invalid Option Message
               show_usage                                               # Display Help Usage
               exit 1                                                   # Exit with Error
               ;;
        esac                                                            # End of case
    done                                                                # End of while
    return 
}


# --------------------------------------------------------------------------------------------------
#                                Script Start HERE
# --------------------------------------------------------------------------------------------------
    cmd_options "$@"                                                    # Check command-line Options
    sadm_start                                                          # Init Env. Dir. & RCH/Log

    print_dev_functions                                                 # 1) Functions of SADMIN
    print_user_variables                                                # 2) Print USer Variables
    print_start_stop                                                    # 3) Start/Stop Function
    print_sadmin_cfg                                                    # 4) List Sadmin Cfg File Var.
    print_directory                                                     # 5) List Client Dir. Var. 
    print_file_variable                                                 # 6) List Files Var. of SADMIN
    print_command_path                                                  # 7) List Command Path
    if [ "$SADM_HOST_TYPE" = "S" ] ; then print_db_variables ;fi        # 8) SADMIN Server DB Layout 

    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
