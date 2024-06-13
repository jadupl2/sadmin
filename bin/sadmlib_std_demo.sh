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
# 2019_01_28 lib v3.8 Database info only show when running on SADMIN Server
# 2019_03_18 lib v3.9 Add demo call to function 'sadm_get_packagetype'
# 2019_04_07 lib v3.10 Don't show Database user name if run on client.
# 2019_04_11 lib v3.11 Add Database column "active","category" and "group" to server output.
# 2019_04_25 lib v3.12 Add Alert_Repeat, Textbelt API Key and URL Variables in Output.
# 2019_05_17 lib v3.13 Add option -p(Show DB password),-s(Show Storix Info),-t(Show TextBeltKey)
# 2019_10_14 lib v3.14 Add demo for calling sadm_server_arch function & show result.
# 2019_10_17 lib v3.15 Print Category and Group table content at the end of report.
# 2019_10_30 lib v3.16 Remove 'facter' utilization (depreciated).
# 2019_11_25 lib v3.17 Change printing format of Database table at the end of execution.
# 2020_04_01 lib v3.18 Replace function sadm_writelog() with N/L incl. by sadm_write() No N/L Incl.
# 2020_11_24 lib v3.19 Don't show DB password file on client.
# 2020_12_24 lib v3.20 Include output of capitalize function.
# 2022_04_10 lib v3.21 Remove 'lsb_release' command dependency.
# 2022_05_10 lib v3.22 Use 'mutt' instead of 'mail'.
# 2022_06_16 lib v3.23 Added fields 'sa.proot_only' & 'sa.psadm_server_only' to output.
# 2022_08_14 lib v3.24 Output updated with all the latest functions & global variables.
# 2023_04_13 lib v3.25 Add 'SADM_REAR_DIF', 'SADM_REAR_INTERVAL', 'SADM_BACKUP_INTERVAL' to output.
# 2023_11_29 lib v3.26 Change to not update 'rch' file.
#@2024_06_13 lib v3.27 Add VM export parameters and alert history/archive purge days limit.
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPT The Control-C
#set -x



# ------------------- S T A R T  O F   S A D M I N   C O D E    S E C T I O N  ---------------------
# v1.56 - Setup for Global Variables and load the SADMIN standard library.
#       - To use SADMIN tools, this section MUST be present near the top of your code.    

# Make Sure Environment Variable 'SADMIN' Is Defined.
if [ -z "$SADMIN" ] || [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]            # SADMIN defined? Libr.exist
    then if [ -r /etc/environment ] ; then source /etc/environment ; fi # LastChance defining SADMIN
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
export SADM_VER='3.27'                                      # Script version number
export SADM_PDESC="Demonstrate functions & variables available to developers using SADMIN Tools"
export SADM_ROOT_ONLY="N"                                  # Run only by root ? [Y] or [N]
export SADM_SERVER_ONLY="N"                                # Run only on SADMIN server? [Y] or [N]
export SADM_EXIT_CODE=0                                    # Script Default Exit Code
export SADM_LOG_TYPE="B"                                   # Log [S]creen [L]og [B]oth
export SADM_LOG_APPEND="N"                                 # Y=AppendLog, N=CreateNewLog
export SADM_LOG_HEADER="N"                                 # Y=ProduceLogHeader N=NoHeader
export SADM_LOG_FOOTER="N"                                 # Y=IncludeFooter N=NoFooter
export SADM_MULTIPLE_EXEC="Y"                              # Run Simultaneous copy of script
export SADM_USE_RCH="N"                                    # Update RCH History File (Y/N)
export SADM_DEBUG=0                                        # Debug Level(0-9) 0=NoDebug
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
# -------------------  E N D   O F   S A D M I N   C O D E    S E C T I O N  -----------------------








# --------------------------------------------------------------------------------------------------
#              V A R I A B L E S    L O C A L   T O     T H I S   S C R I P T
# --------------------------------------------------------------------------------------------------
#
lcount=0                                                                # Print Line Counter




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
    printf "\n   ${BOLD}${YELLOW}[-p]${NORMAL}\t\t\tShow password on output"
    printf "\n   ${BOLD}${YELLOW}[-t]${NORMAL}\t\t\tShow TextBelt Key on output"
    printf "\n\n" 
}


# Standardize Print Line Function 
#===================================================================================================
printline()
{
    lcount=$(expr $lcount + 1)                                          # Incr. Print Line Number
    p1=$1 ; p2=$2 ; p3=$3
    printf "\n[%03d] " $lcount                                          # Print Line Number
    if [ "$p1" != "" ] ; then printf "%-33s" "$p1"            ;fi
    if [ "$p2" != "" ] ; then printf "%-36s" "$p2"            ;fi  
    if [ "$p1" != "" ] && [ "$p2" != "" ] ; then printf "%-33s" ": ${p3}" ;fi
}


# Standardize Print Header Function 
#===================================================================================================
printheader()
{
    lcount=0                                                            # Clear Print Line Number
    h1=$1 ; h2=$2 ; h3=$3
    printf "\n\n$(printf %100s |tr ' ' '=')"
    #printf "\n$SADM_PN v$SADM_VER - Library v$SADM_LIB_VER"
    printf "\n%-39s%-36s%-33s" "$h1" "$h2" "$h3" 
    printf "\n$(printf %100s |tr " " "=")"
}





# Print SADMIN Function available to Users
#===================================================================================================
print_user_variables()
{
    printheader "User Var. that affect SADMIN behavior" "Description" "  This System Result"

    pexample="\$SADM_VER"                                               # Variable Name
    pdesc="Script Version Number"                                       # Description
    presult="$SADM_VER"                                                 # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_PN"                                                # Variable Name
    pdesc="Script Name"                                                 # Description
    presult="$SADM_PN"                                                  # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_INST"                                              # Variable Name
    pdesc="Script Name Without Extension"                               # Description
    presult="$SADM_INST"                                                # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_USERNAME"                                          # Variable Name
    pdesc="Current User Name"                                           # Description
    presult="$SADM_USERNAME"                                            # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_TPID"                                              # Variable Name
    pdesc="Current Process ID"                                          # Description
    presult="$SADM_TPID"                                                # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_MULTIPLE_EXEC"                                     # Variable Name
    pdesc="Allow running multiple copy [Y/N]"                           # Description
    presult="$SADM_MULTIPLE_EXEC"                                       # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_USE_RCH"                                           # Variable Name
    pdesc="Generate entry in '*.rch' file"                              # Description
    presult="$SADM_USE_RCH"                                             # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_LOG_TYPE"                                          # Variable Name
    pdesc="Set Output to [S]creen [L]og [B]oth"                         # Description
    presult="$SADM_LOG_TYPE"                                            # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_LOG_APPEND"                                        # Variable Name
    pdesc="Y=Append to Log, N=Create new log"                           # Description
    presult="$SADM_LOG_APPEND"                                          # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_LOG_HEADER"                                        # Variable Name
    pdesc="Generate Header in log [Y,N]"                                # Description
    presult="$SADM_LOG_HEADER"                                          # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_LOG_FOOTER"                                        # Name
    pdesc="Generate Footer in log [Y/N]"                                # Description
    presult="$SADM_LOG_FOOTER"                                          # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_EXIT_CODE"                                         # Variable Name
    pdesc="Current value of script exit code"                           # Description
    presult="$SADM_EXIT_CODE"                                           # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
  
    pexample="\$SADM_ROOT_ONLY"                                         # Variable Name
    pdesc="Only run by 'root' user [Y/N]"                               # Description
    presult="$SADM_ROOT_ONLY"                                           # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_SERVER_ONLY"                                       # Variable Name
    pdesc="Only run on SADMIN server [Y/N]"                             # Description
    presult="$SADM_SERVER_ONLY"                                         # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
}



#===================================================================================================
# Print SADMIN Function available to Users
#===================================================================================================
print_functions()
{
    printheader "Calling Functions" "Description" "  This System Result"

    pexample="\$(sadm_get_release)"                                     # Example Calling Function
    pdesc="SADMIN Release Number (XX.XX)"                               # Function Description
    presult="$(sadm_get_release)"                                       # Return Value(s)
    printline "$pexample" "$pdesc" "$presult"                           # Print Example Line
    
    pexample="\$(sadm_get_ostype)"                                      # Example Calling Function
    pdesc="OS Type (Uppercase,LINUX,AIX,DARWIN)"                        # Function Description
    presult="$(sadm_get_ostype)"                                        # Return Value(s)
    printline "$pexample" "$pdesc" "$presult"                           # Print Example Line
        
    pexample="\$(sadm_get_osversion)"                                   # Example Calling Function
    pdesc="Return O/S Version (Ex: 7.2, 6.5)"                           # Function Description
    presult="$(sadm_get_osversion)"                                     # Return Value(s)
    printline "$pexample" "$pdesc" "$presult"                           # Print Example Line
            
    pexample="\$(sadm_get_osmajorversion)"                              # Example Calling Function
    pdesc="Return O/S Major Version (Ex 7, 6)"                          # Function Description
    presult="$(sadm_get_osmajorversion)"                                # Return Value(s)
    printline "$pexample" "$pdesc" "$presult"                           # Print Example Line
            
    pexample="\$(sadm_get_osminorversion)"                              # Example Calling Function
    pdesc="Return O/S Minor Version (Ex 2, 3)"                          # Function Description
    presult="$(sadm_get_osminorversion)"                                # Return Value(s)
    printline "$pexample" "$pdesc" "$presult"                           # Print Example Line
    
    pexample="\$(sadm_get_osname)"                                      # Example Calling Function
    pdesc="O/S Name (REDHAT,CENTOS,UBUNTU,...)"                         # Function Description
    presult="$(sadm_get_osname)"                                        # Return Value(s)
    printline "$pexample" "$pdesc" "$presult"                           # Print Example Line
    
    pexample="\$(sadm_get_oscodename)"                                  # Example Calling Function
    pdesc="O/S Project Code Name"                                       # Function Description
    presult="$(sadm_get_oscodename)"                                    # Return Value(s)
    printline "$pexample" "$pdesc" "$presult"                           # Print Example Line
    
    pexample="\$(sadm_get_kernel_version)"                              # Example Calling Function
    pdesc="O/S Running Kernel Version"                                  # Function Description
    presult="$(sadm_get_kernel_version)"                                # Return Value(s)
    printline "$pexample" "$pdesc" "$presult"                           # Print Example Line
    
    pexample="\$(sadm_get_kernel_bitmode)"                              # Example Calling Function
    pdesc="O/S Kernel Bit Mode (32 or 64)"                              # Function Description
    presult="$(sadm_get_kernel_bitmode)"                                # Return Value(s)
    printline "$pexample" "$pdesc" "$presult"                           # Print Example Line
     
    pexample="\$(sadm_get_hostname)"                                    # Example Calling Function
    pdesc="Current Host Name"                                           # Function Description
    presult="$(sadm_get_hostname)"                                      # Return Value(s)
    printline "$pexample" "$pdesc" "$presult"                           # Print Example Line
     
    pexample="\$(sadm_get_host_ip)"                                     # Example Calling Function
    pdesc="Current Host IP Address"                                     # Function Description
    presult="$(sadm_get_host_ip)"                                       # Return Value(s)
    printline "$pexample" "$pdesc" "$presult"                           # Print Example Line
    
    pexample="\$(sadm_get_domainname)"                                  # Example Calling Function
    pdesc="Current Host Domain Name"                                    # Function Description
    presult="$(sadm_get_domainname)"                                    # Return Value(s)
    printline "$pexample" "$pdesc" "$presult"                           # Print Example Line
    
    pexample="\$(sadm_get_fqdn)"                                        # Example Calling Function
    pdesc="Fully Qualified Domain Host Name"                            # Function Description
    presult="$(sadm_get_fqdn)"                                          # Return Value(s)
    printline "$pexample" "$pdesc" "$presult"                           # Print Example Line

    pexample="\$(sadm_server_serial)"                                   # Example Calling Function
    pdesc="Server serial number (Ex: 4S7GYF1)"                          # Function Description
    presult=$(sadm_server_serial)                                       # Return Value(s)
    printline "$pexample" "$pdesc" "$presult"                           # Print Example Line
            
    pexample="\$(sadm_get_epoch_time)"                                  # Example Calling Function
    pdesc="Get Current Epoch Time"                                      # Function Description
    presult="$(sadm_get_epoch_time)"                                    # Return Value(s)
    printline "$pexample" "$pdesc" "$presult"                           # Print Example Line
    
    EPOCH_TIME=$(sadm_get_epoch_time)                                   # Save Epoch Time
    pexample="\$(sadm_epoch_to_date $EPOCH_TIME)"                       # Example Calling Function
    pdesc="Convert epoch time to date"                                  # Function Description
    presult=$(sadm_epoch_to_date "$EPOCH_TIME")                         # Return Value(s)
    printline "$pexample" "$pdesc" "$presult"                           # Print Example Line
    
    pexample=""; pdesc=""; presult="";                                  # Clear Result Line
    WDATE=$(sadm_epoch_to_date $EPOCH_TIME)                             # Set Test Date
    printf "\n      WDATE='$WDATE'"                                     # Print Test Date
    pexample="\$(sadm_date_to_epoch \"\$WDATE\")"                       # Example Calling Function
    pdesc="Convert Date to epoch time"                                  # Function Description
    presult=$(sadm_date_to_epoch "$WDATE")                              # Return Value(s)
    printline "$pexample" "$pdesc" "$presult"                           # Print Example Line
        
    pexample=""; pdesc=""; presult="";                                  # Clear Result Line
    DATE1="2016.01.30 10:00:44" ; DATE2="2016.01.30 10:00:03"           # Set Date to Calc Elapse
    printf "\n      DATE1='$DATE1'"                                     # Print Date1 Used for Ex.
    printf "\n      DATE2='$DATE2'"                                     # Print Date2 Used for Ex.
    pexample="\$(sadm_elapse \"\$DATE1\" \"\$DATE2\")"                  # Example Calling Function
    pdesc="Elapse Time between two timestamps"                          # Function Description
    presult=$(sadm_elapse "$DATE1" "$DATE2")                            # Return Value(s)
    printline "$pexample" "$pdesc" "$presult"                           # Print Example Line
     
    pexample="\$(sadm_get_packagetype)"                                 # Example Calling Function
    pdesc="Get package type (rpm,deb,aix,dmg)"                          # Function Description
    presult="$(sadm_get_packagetype)"                                   # Return Value(s)
    printline "$pexample" "$pdesc" "$presult"                           # Print Example Line

    pexample="\$(sadm_server_arch)"                                     # Example Calling Function
    pdesc="System Architecture"                                         # Function Description
    presult=$(sadm_server_arch)                                         # Return Value(s)
    printline "$pexample" "$pdesc" "$presult"                           # Print Example Line

    pexample="sadm_lock_system \"hostname\""                            # Example Calling Function
    pdesc="Lock the specified hostname"                                 # Function Description
    presult="0=Lock 1=Error not lock"                                   # Return Value(s)
    printline "$pexample" "$pdesc" "$presult"                           # Print Example Line

    pexample="sadm_check_system_lock \"hostname\""                      # Example Calling Function
    pdesc="Check if specified hostname is lock"                         # Function Description
    presult="0=Not Lock - 1=System Locked"                              # Return Value(s)
    printline "$pexample" "$pdesc" "$presult"                           # Print Example Line

    pexample="sadm_unlock_system \"hostname\""                          # Example Calling Function
    pdesc="Unlock the specified hostname"                               # Function Description
    presult="0=Unlocked 1=Error could not unlock"                       # Return Value(s)
    printline "$pexample" "$pdesc" "$presult"                           # Print Example Line

    pexample="sadm_writelog \"message\""                                # Example Calling Function
    pdesc="Depreciated use 'sadm_write_log'"                            # Function Description
    presult="message"                                                   # Return Value(s)
    printline "$pexample" "$pdesc" "$presult"                           # Print Example Line

    pexample="sadm_write_log \"message\""                               # Example Calling Function
    pdesc="Write message to Screen, Log or Both"                        # Function Description
    presult="message"                                                   # Return Value(s)
    printline "$pexample" "$pdesc" "$presult"                           # Print Example Line

    pexample="sadm_write_err \"message\""                               # Example Calling Function
    pdesc="Write mess to error log & to std log"                        # Function Description
    presult="message"                                                   # Return Value(s)
    printline "$pexample" "$pdesc" "$presult"                           # Print Example Line

    pexample="sadm_sendmail(mail,sub,body,att)"
    pdesc="sadm_sendmail(email,'subject',body',file1,..)"     
    presult="0=Success  1=Error"                                        # Return Value(s)
    printline "$pexample" "$pdesc" "$presult"                           # Print Example Line

    pexample="sadm_show_version"
    pdesc="Cmdline -v option show script info."
    presult=""                                                          # Return Value(s)
    printline "$pexample" "$pdesc" "$presult"                           # Print Example Line

    pexample="sadm_sleep \"60\" \"15\""
    pdesc="Sleep 60sec. at interval of 15sec."
    presult="60...45...30...15...0"                                     # Return Value(s)
    printline "$pexample" "$pdesc" "$presult"                           # Print Example Line

    pexample="sadm_trimfile \"filename\" 35"
    pdesc="Keep the last 35 lines of filename."
    presult="0=Success  1=Error"                                        # Return Value(s)
    printline "$pexample" "$pdesc" "$presult"                           # Print Example Line


}



#===================================================================================================
# Print SADMIN Functions Available Only in Bash Shell
#===================================================================================================
print_bash_functions()
{
    printheader "FUNCTIONS AVAIl. ONLY IN BASH LIBRARY" "Description" "  This System Result"

    pexample="\$(sadm_server_type)"                                     # Example Calling Function
    pdesc="Host is Physical or Virtual (P/V)"                           # Function Description
    presult=$(sadm_server_type)                                         # Return Value(s)
    printline "$pexample" "$pdesc" "$presult"                           # Print Example Line
    
    pexample="\$(sadm_server_model)"                                    # Example Calling Function
    pdesc="Server model (Ex: HP ProLiant DL580)"                        # Function Description
    presult=$(sadm_server_model)                                        # Return Value(s)
    printline "$pexample" "$pdesc" "$presult"                           # Print Example Line

    pexample="\$(sadm_server_memory)"                                   # Example Calling Function
    pdesc="Server total memory in MB (Ex: 3790)"                        # Function Description
    presult=$(sadm_server_memory)                                       # Return Value(s)
    printline "$pexample" "$pdesc" "$presult"                           # Print Example Line
            
    pexample="\$(sadm_server_hardware_bitmode)"                         # Example Calling Function
    pdesc="CPU Hardware capable of 32/64 bits"                          # Function Description
    presult=$(sadm_server_hardware_bitmode)                             # Return Value(s)
    printline "$pexample" "$pdesc" "$presult"                           # Print Example Line
            
    pexample="\$(sadm_server_nb_logical_cpu)"                           # Example Calling Function
    pdesc="Number of Logical CPU on system"                             # Function Description
    presult=$(sadm_server_nb_logical_cpu)                               # Return Value(s)
    printline "$pexample" "$pdesc" "$presult"                           # Print Example Line
                
    pexample="\$(sadm_server_nb_cpu)"                                   # Example Calling Function
    pdesc="Number of Physical CPU on system"                            # Function Description
    presult=$(sadm_server_nb_cpu)                                       # Return Value(s)
    printline "$pexample" "$pdesc" "$presult"                           # Print Example Line
       
    pexample="\$(sadm_server_nb_socket)"                                # Example Calling Function
    pdesc="Number of socket on system"                                  # Function Description
    presult=$(sadm_server_nb_socket)                                    # Return Value(s)
    printline "$pexample" "$pdesc" "$presult"                           # Print Example Line
                    
    pexample="\$(sadm_server_core_per_socket)"                          # Example Calling Function
    pdesc="Number of Core per Socket"                                   # Function Description
    presult=$(sadm_server_core_per_socket)                              # Return Value(s)
    printline "$pexample" "$pdesc" "$presult"                           # Print Example Line
    
    pexample="\$(sadm_server_thread_per_core)"                          # Example Calling Function
    pdesc="Number of Thread per Core"                                   # Function Description
    presult=$(sadm_server_thread_per_core)                              # Return Value(s)
    printline "$pexample" "$pdesc" "$presult"                           # Print Example Line
    
    pexample="\$(sadm_server_cpu_speed)"                                # Example Calling Function
    pdesc="Server CPU Speed in MHz"                                     # Function Description
    presult=$(sadm_server_cpu_speed)                                    # Return Value(s)
    printline "$pexample" "$pdesc" "$presult"                           # Print Example Line
    
    pexample="\$(sadm_server_disks)"                                    # Example Calling Function
    pdesc="Disks list(MB) (DISKNAME|SIZE,...)"                          # Function Description
    presult=$(sadm_server_disks)                                        # Return Value(s)
    printline "$pexample" "$pdesc" "$presult"                           # Print Example Line
    
    pexample="\$(sadm_server_vg)"                                       # Example Calling Function
    pdesc="VG list(MB) (VGNAME|SIZE|USED|FREE)"                         # Function Description
    presult=$(sadm_server_vg)                                           # Return Value(s)
    if [[ "$presult" = "" ]] ; then presult="No VG" ; fi
    printline "$pexample" "$pdesc" "$presult"                           # Print Example Line
        
    pexample="\$(sadm_server_ips)"                                      # Example Calling Function
    pdesc="Network IP(Name|IP|Netmask|MAC)"                             # Function Description
    presult=$(sadm_server_ips)                                          # Return Value(s)
    printline "$pexample" "$pdesc" "$presult"                           # Print Example Line
    
    pexample="sadm_toupper string"                                      # Example Calling Function
    pdesc="Return string uppercase"                                     # Function Description
    presult=`sadm_toupper STRING`                                       # Return Value(s)
    printline "$pexample" "$pdesc" "$presult"                           # Print Example Line

    pexample="sadm_tolower STRING"                                      # Example Calling Function
    pdesc="Return string lowercase"                                     # Function Description
    presult=`sadm_tolower STRING`                                       # Return Value(s)
    printline "$pexample" "$pdesc" "$presult"                           # Print Example Line
    
    pexample="sadm_capitalize STRING"                                   # Example Calling Function
    pdesc="Return string capitalize"                                    # Function Description
    presult=`sadm_capitalize String`                                    # Return Value(s)
    printline "$pexample" "$pdesc" "$presult"                           # Print Example Line

    pexample="sadm_ask \"Question\""                                    # Example Calling Function
    pdesc="Show message & wait for [Y/y/N/n]"                           # Function Description
    presult="Question [Y/N] ? - (0=N 1=Y)"                              # Return Value(s)
    printline "$pexample" "$pdesc" "$presult"                           # Print Example Line

}



#===================================================================================================
# Print Directories Variables Available to Users
#===================================================================================================
print_directory()
{
    printheader "Directories Var. Avail." "Description" "  This System Result"

    pexample="\$SADM_BASE_DIR"                                          # Directory Variable Name
    pdesc="SADMIN Root Directory"                                       # Directory Description
    presult="$SADM_BASE_DIR"                                            # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_BIN_DIR"                                           # Directory Variable Name
    pdesc="SADMIN Scripts Directory"                                    # Directory Description
    presult="$SADM_BIN_DIR"                                             # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_TMP_DIR"                                           # Directory Variable Name
    pdesc="SADMIN Temporary file(s) Directory"                          # Directory Description
    presult="$SADM_TMP_DIR"                                             # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
        
    pexample="\$SADM_LIB_DIR"                                           # Directory Variable Name
    pdesc="SADMIN Shell & Python Library Dir."                          # Directory Description
    presult="$SADM_LIB_DIR"                                             # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
        
    pexample="\$SADM_LOG_DIR"                                           # Directory Variable Name
    pdesc="SADMIN Script Log Directory"                                 # Directory Description
    presult="$SADM_LOG_DIR"                                             # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
        
    pexample="\$SADM_CFG_DIR"                                           # Directory Variable Name
    pdesc="SADMIN Configuration Directory"                              # Directory Description
    presult="$SADM_CFG_DIR"                                             # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
        
    pexample="\$SADM_SYS_DIR"                                           # Directory Variable Name
    pdesc="Server Startup/Shutdown Script Dir."                         # Directory Description
    presult="$SADM_SYS_DIR"                                             # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
        
    pexample="\$SADM_DOC_DIR"                                           # Directory Variable Name
    pdesc="SADMIN Documentation Directory"                              # Directory Description
    presult="$SADM_DOC_DIR"                                             # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
            
    pexample="\$SADM_PKG_DIR"                                           # Directory Variable Name
    pdesc="SADMIN Packages Directory"                                   # Directory Description
    presult="$SADM_PKG_DIR"                                             # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
            
    pexample="\$SADM_DAT_DIR"                                           # Directory Variable Name
    pdesc="Server Data Directory"                                       # Directory Description
    presult="$SADM_DAT_DIR"                                             # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_NMON_DIR"                                          # Directory Variable Name
    pdesc="Server NMON - Data Collected Dir."                           # Directory Description
    presult="$SADM_NMON_DIR"                                            # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_DR_DIR"                                            # Directory Variable Name
    pdesc="Server Disaster Recovery Info Dir."                          # Directory Description
    presult="$SADM_DR_DIR"                                              # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_RCH_DIR"                                           # Directory Variable Name
    pdesc="Server Return Code History Dir."                             # Directory Description
    presult="$SADM_RCH_DIR"                                             # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
        
    pexample="\$SADM_NET_DIR"                                           # Directory Variable Name
    pdesc="Server Network Info Dir."                                    # Directory Description
    presult="$SADM_NET_DIR"                                             # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
        
    pexample="\$SADM_RPT_DIR"                                           # Directory Variable Name
    pdesc="SYStem MONitor Report Directory"                             # Directory Description
    presult="$SADM_RPT_DIR"                                             # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
        
    pexample="\$SADM_DBB_DIR"                                           # Directory Variable Name
    pdesc="Database Backup Directory"                                   # Directory Description
    presult="$SADM_DBB_DIR"                                             # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
        
    pexample="\$SADM_SETUP_DIR"                                         # Directory Variable Name
    pdesc="SADMIN Installation/Update Dir."                             # Directory Description
    presult="$SADM_SETUP_DIR"                                           # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
        
    pexample="\$SADM_USR_DIR"                                           # Directory Variable Name
    pdesc="User/System specific directory "                             # Directory Description
    presult="$SADM_USR_DIR"                                             # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
        
    pexample="\$SADM_UBIN_DIR"                                          # Directory Variable Name
    pdesc="User/System specific bin/script Dir."                        # Directory Description
    presult="$SADM_UBIN_DIR"                                            # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
        
    pexample="\$SADM_ULIB_DIR"                                          # Directory Variable Name
    pdesc="User/System specific library Dir."                           # Directory Description
    presult="$SADM_ULIB_DIR"                                            # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
        
    pexample="\$SADM_UDOC_DIR"                                          # Directory Variable Name
    pdesc="User/System specific documentation"                          # Directory Description
    presult="$SADM_UDOC_DIR"                                            # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
        
    pexample="\$SADM_UMON_DIR"                                          # Directory Variable Name
    pdesc="User/System specific SysMon Scripts"                         # Directory Description
    presult="$SADM_UMON_DIR"                                            # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
        
    pexample="\$SADM_WWW_DIR"                                           # Directory Variable Name
    pdesc="SADMIN Web Site Root Directory"                              # Directory Description
    presult="$SADM_WWW_DIR"                                             # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
        
    pexample="\$SADM_WWW_DOC_DIR"                                       # Directory Variable Name
    pdesc="SADMIN Web Documentation Dir."                               # Directory Description
    presult="$SADM_WWW_DOC_DIR"                                         # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
            
    pexample="\$SADM_WWW_DAT_DIR"                                       # Directory Variable Name
    pdesc="SADMIN Web Site Systems Data Dir."                           # Directory Description
    presult="$SADM_WWW_DAT_DIR"                                         # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
            
    pexample="\$SADM_WWW_LIB_DIR"                                       # Directory Variable Name
    pdesc="SADMIN Web Site PHP Library Dir."                            # Directory Description
    presult="$SADM_WWW_LIB_DIR"                                         # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
            
    pexample="\$SADM_WWW_TMP_DIR"                                       # Directory Variable Name
    pdesc="SADMIN Web Temp Working Directory"                           # Directory Description
    presult="$SADM_WWW_TMP_DIR"                                         # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
            
    pexample="\$SADM_WWW_PERF_DIR"                                      # Directory Variable Name
    pdesc="SADMIN Web Performance Graph Dir."                           # Directory Description
    presult="$SADM_WWW_PERF_DIR"                                        # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line

}



#===================================================================================================
# Print Client Directories Variables Available to Users
#===================================================================================================
print_server_directory()
{
    printheader "Server Directories Var. Avail." "Description" "  This System Result"
}




#===================================================================================================
# Print Files Variables Available to Users
#===================================================================================================
print_file_variable()
{
    printheader "SADMIN FILES VARIABLES AVAIL." "Description" "  This System Result"
            
    pexample="\$SADM_PID_FILE"                                          # Directory Variable Name
    pdesc="Current script PID file"                                     # Directory Description
    presult="$SADM_PID_FILE"                                            # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
                
    pexample="\$SADM_CFG_FILE"                                          # Directory Variable Name
    pdesc="SADMIN Configuration File"                                   # Directory Description
    presult="$SADM_CFG_FILE"                                            # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_CFG_HIDDEN"                                        # Variable Name
    pdesc="SADMIN Initial Configuration File"                           # Description
    presult="$SADM_CFG_HIDDEN"                                          # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line

    pexample="\$SADM_ALERT_FILE"                                        # Variable Name
    pdesc="SADMIN Alert Group File"                                     # Description
    presult="$SADM_ALERT_FILE"                                          # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line

    pexample="\$SADM_ALERT_INIT"                                        # Variable Name
    pdesc="SADMIN Initial Alert Group File"                             # Description
    presult="$SADM_ALERT_INIT"                                          # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line

    pexample="\$SADM_ALERT_HIST"                                        # Variable Name
    pdesc="SADMIN Alert History File"                                   # Description
    presult="$SADM_ALERT_HIST"                                          # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line

    pexample="\$SADM_ALERT_HINI"                                        # Variable Name
    pdesc="SADMIN Initial Alert History File"                           # Description
    presult="$SADM_ALERT_HINI"                                          # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line

    pexample="\$SADM_TMP_FILE1"                                         # Directory Variable Name
    pdesc="User usable Temp Work File 1"                                # Directory Description
    presult="$SADM_TMP_FILE1"                                           # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
        
    pexample="\$SADM_TMP_FILE2"                                         # Variable Name
    pdesc="User usable Temp Work File 2"                                # Description
    presult="$SADM_TMP_FILE2"                                           # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
        
    pexample="\$SADM_TMP_FILE3"                                         # Variable Name
    pdesc="User usable Temp Work File 3"                                # Description
    presult="$SADM_TMP_FILE3"                                           # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
            
    pexample="\$SADM_LOG"                                               # Variable Name
    pdesc="Script Log File"                                             # Description
    presult="$SADM_LOG"                                                 # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
            
    pexample="\$SADM_RCHLOG"                                            # Variable Name
    pdesc="Script Return Code History File"                             # Description
    presult="$SADM_RCHLOG"                                              # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
                
    pexample="\$DBPASSFILE"                                             # Variable Name
    pdesc="SADMIN Database User Password File"                          # Description
    presult="$DBPASSFILE"                                               # Actual Content of Variable
    if [ "$show_password" = "N" ] ; then presult="*Hidden*" ;fi         # Don't show DB Password
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line

    pexample="\$SADM_RPT_FILE"                                          # Variable Name
    pdesc="System Monitor Report File"                                  # Description
    presult="$SADM_RPT_FILE"                                            # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
                
    pexample="\$SADM_BACKUP_LIST"                                       # Variable Name
    pdesc="Backup List File Name"                                       # Variable Description
    presult="$SADM_BACKUP_LIST"                                         # Variable Content 
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
                
    pexample="\$SADM_BACKUP_LIST_INIT"                                  # Variable Name
    pdesc="Initial Backup List (Template)"                              # Variable Description
    presult="$SADM_BACKUP_LIST_INIT"                                    # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
                
    pexample="\$SADM_BACKUP_EXCLUDE"                                    # Variable Name
    pdesc="Backup Exclude List File Name"                               # Variable Description
    presult="$SADM_BACKUP_EXCLUDE"                                      # Variable Content
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
                
    pexample="\$SADM_BACKUP_EXCLUDE_INIT"                               # Variable Name
    pdesc="Initial Backup Exclude (Template)"                           # Variable Description
    presult="$SADM_BACKUP_EXCLUDE_INIT"                                 # Variable Actual Content
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line

}


#===================================================================================================
# Print sadmin.cfg Variables available to users
#===================================================================================================
print_sadmin_cfg()
{
    printheader "SADMIN CONFIG FILE VARIABLES" "Description" "  This System Result"

    pexample="\$SADM_SERVER"                                            # Variable Name
    pdesc="SADMIN SERVER NAME (FQDN)"                                   # Description
    presult="$SADM_SERVER"                                              # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
                    
    pexample="\$SADM_HOST_TYPE"                                         # Variable Name
    pdesc="SADMIN [C]lient or [S]erver"                                 # Description
    presult="$SADM_HOST_TYPE"                                           # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
         
    pexample="\$SADM_MAIL_ADDR"                                         # Variable Name
    pdesc="SADMIN Administrator Default Email"                          # Description
    presult="$SADM_MAIL_ADDR"                                           # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
                    
    pexample="\$SADM_ALERT_TYPE"                                        # Variable Name
    pdesc="0=NoMail 1=OnError 2=OnSuccess 3=All"                        # Description
    presult="$SADM_ALERT_TYPE"                                          # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_ALERT_GROUP"                                       # Variable Name
    pdesc="Default Alert Group"                                         # Description
    presult="$SADM_ALERT_GROUP"                                         # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_ALERT_REPEAT"                                      # Variable Name
    pdesc="Seconds to wait before repeat alert"                         # Description
    presult="$SADM_ALERT_REPEAT"                                        # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
        
    pexample="\$SADM_DAYS_HISTORY"                                      # Variable Name
    pdesc="Days to keep alert in History file"                          # Function Description
    presult="$SADM_DAYS_HISTORY"                                        # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
        
    pexample="\$SADM_MAX_ARC_LINE"                                      # Variable Name
    pdesc="Max lines to keep in alert Archive"                          # Function Description
    presult="$SADM_MAX_ARC_LINE"                                        # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_TEXTBELT_KEY"                                      # Variable Name
    pdesc="TextBelt.com API Key"                                        # Description
    presult="*Hidden*"                                                  # TextBelt API Key
    if [ "$show_textbelt" = "Y" ]                                       # If command line switch
        then presult="$SADM_TEXTBELT_KEY"                               # TextBelt API Key
    fi
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line

    pexample="\$SADM_TEXTBELT_URL"                                      # Variable Name
    pdesc="TextBelt.com API URL"                                        # Description
    presult="$SADM_TEXTBELT_URL"                                        # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
          
    pexample="\$SADM_CIE_NAME"                                          # Directory Variable Name
    pdesc="Your Company Name"                                           # Directory Description
    presult="$SADM_CIE_NAME"                                            # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_DOMAIN"                                            # Directory Variable Name
    pdesc="Server Creation Default Domain"                              # Directory Description
    presult="$SADM_DOMAIN"                                              # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_USER"                                              # Directory Variable Name
    pdesc="SADMIN User Name"                                            # Directory Description
    presult="$SADM_USER"                                                # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_GROUP"                                             # Directory Variable Name
    pdesc="SADMIN Group Name"                                           # Directory Description
    presult="$SADM_GROUP"                                               # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line

    pexample="\$SADM_WWW_USER"                                          # Directory Variable Name
    pdesc="User that Run Apache Web Server"                             # Directory Description
    presult="$SADM_WWW_USER"                                            # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_WWW_GROUP"                                         # Directory Variable Name
    pdesc="Group that Run Apache Web Server"                            # Directory Description
    presult="$SADM_WWW_GROUP"                                           # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_DBNAME"                                            # Directory Variable Name
    pdesc="SADMIN Database Name"                                        # Directory Description
    presult="$SADM_DBNAME"                                              # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_DBHOST"                                            # Directory Variable Name
    pdesc="SADMIN Database Host"                                        # Directory Description
    presult="$SADM_DBHOST"                                              # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_DBPORT"                                            # Directory Variable Name
    pdesc="SADMIN Database Host TCP Port"                               # Directory Description
    presult="$SADM_DBPORT"                                              # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_RW_DBUSER"                                         # Directory Variable Name
    pdesc="SADMIN Database Read/Write User"                         
    presult="$SADM_RW_DBUSER"                                            # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_RW_DBPWD"                                          # Directory Variable Name
    pdesc="SADMIN Database Read/Write User Pwd"                         # Directory Description
    presult="$SADM_RW_DBPWD"                                            # Actual Content of Variable
    if [ "$show_password" = "N" ] ; then presult="*Hidden*" ;fi         # Don't show DB Password
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_RO_DBUSER"                                         # Directory Variable Name
    pdesc="SADMIN Database Read Only User"                              # Directory Description
    presult="$SADM_RO_DBUSER"                                           # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_RO_DBPWD"                                          # Directory Variable Name
    pdesc="SADMIN Database Read Only User Pwd"                          # Directory Description
    presult="$SADM_RO_DBPWD"                                            # Actual Content of Variable
    if [ "$show_password" = "N" ] ; then presult="*Hidden*" ;fi         # Don't show DB Password
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line

    pexample="\$SADM_SMTP_SERVER"                                       # Variable Name
    pdesc="Your Internet SMTP Server Name"                              # Description
    presult="$SADM_SMTP_SERVER"                                         # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line

    pexample="\$SADM_SMTP_PORT"                                         # Variable Name
    pdesc="Your Internet SMTP Server Port"                              # Description
    presult="$SADM_SMTP_PORT"                                           # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line

    pexample="\$SADM_SMTP_SENDER"                                       # Variable Name
    pdesc="Your Internet Sender Email"                                      
    presult="$SADM_SMTP_SENDER"                                         # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line

    pexample="\$SADM_GMPW"                                              # Variable Name
    pdesc="Your Internet Sender Password"                                      
    presult=$SADM_GMPW
    if [ "$show_password" = "N" ] ; then presult="*Hidden*" ;fi         # Don't show Password
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line

    pexample="\$SADM_SSH_PORT"                                          # Directory Variable Name
    pdesc="SSH Port to communicate with client"                         # Directory Description
    presult="$SADM_SSH_PORT"                                            # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line

    pexample="\$SADM_MONITOR_UPDATE_INTERVAL"                           # Directory Variable Name
    pdesc="Monitor page update interval in sec."                        # Directory Description
    presult="$SADM_MONITOR_UPDATE_INTERVAL"                             # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line

    pexample="\$SADM_MONITOR_RECENT_COUNT"                              # Directory Variable Name
    pdesc="Monitor page nb. recent scripts"                             # Directory Description
    presult="$SADM_MONITOR_RECENT_COUNT"                                # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line

    pexample="\$SADM_MONITOR_RECENT_EXCLUDE"                            # Directory Variable Name
    pdesc="Scripts excluded from SysMon Recent"                         # Directory Description
    presult="$SADM_MONITOR_RECENT_EXCLUDE"                              # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line

     pexample="\$SADM_NMON_KEEPDAYS"                                     # Directory Variable Name
    pdesc="Nb. of days to keep nmon perf. file"                         # Directory Description
    presult="$SADM_NMON_KEEPDAYS"                                       # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_RCH_KEEPDAYS"                                      # Directory Variable Name
    pdesc="Nb. days to keep unmodified rch file"                        # Directory Description
    presult="$SADM_RCH_KEEPDAYS"                                        # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_LOG_KEEPDAYS"                                      # Directory Variable Name
    pdesc="Nb. days to keep unmodified log file"                        # Directory Description
    presult="$SADM_LOG_KEEPDAYS"                                        # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
        
    pexample="\$SADM_MAX_RCLINE"                                        # Directory Variable Name
    pdesc="Trim rch file to this max. of lines"                         # Directory Description
    presult="$SADM_MAX_RCLINE"                                          # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_MAX_LOGLINE"                                       # Directory Variable Name
    pdesc="Trim log to this maximum of lines"                           # Directory Description
    presult="$SADM_MAX_LOGLINE"                                         # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_NETWORK1"                                          # Directory Variable Name
    pdesc="Network/Netmask 1 inv. IP/Name/Mac"                          # Directory Description
    presult="$SADM_NETWORK1"                                            # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_NETWORK2"                                          # Directory Variable Name
    pdesc="Network/Netmask 2 inv. IP/Name/Mac"                          # Directory Description
    presult="$SADM_NETWORK2"   
    if [[ "$SADM_NETWORK2" = "" ]] ; then presult="None" ; fi           # Blank replace by None
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_NETWORK3"                                          # Directory Variable Name
    pdesc="Network/Netmask 3 inv. IP/Name/Mac"                          # Directory Description
    presult="$SADM_NETWORK3"                                            # Actual Content of Variable
    if [[ "$SADM_NETWORK3" = "" ]] ; then presult="None" ; fi           # Blank replace by None
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_NETWORK4"                                          # Directory Variable Name
    pdesc="Network/Netmask 4 inv. IP/Name/Mac"                          # Directory Description
    presult="$SADM_NETWORK4"                                            # Actual Content of Variable
    if [[ "$SADM_NETWORK4" = "" ]] ; then presult="None" ; fi           # Blank replace by None
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_NETWORK5"                                          # Directory Variable Name
    pdesc="Network/Netmask 5 inv. IP/Name/Mac"                          # Directory Description
    presult="$SADM_NETWORK5"                                            # Actual Content of Variable
    if [[ "$SADM_NETWORK5" = "" ]] ; then presult="None" ; fi           # Blank replace by None
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line

    pexample="\$SADM_REAR_NFS_SERVER"                                   # Directory Variable Name
    pdesc="Rear NFS Server IP or Name"                                  # Directory Description
    presult="$SADM_REAR_NFS_SERVER"                                     # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_REAR_NFS_MOUNT_POINT"                              # Directory Variable Name
    pdesc="Rear NFS Mount Point"                                        # Directory Description
    presult="$SADM_REAR_NFS_MOUNT_POINT"                                # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_REAR_BACKUP_TO_KEEP"                               # Directory Variable Name
    pdesc="Rear NFS Backup - Nb. to keep"                               # Directory Description
    presult="$SADM_REAR_BACKUP_TO_KEEP"                                 # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_REAR_BACKUP_DIF"                                   # Directory Variable Name
    pdesc="Alert if size differ more than %"                            # Directory Description
    presult="$SADM_REAR_BACKUP_DIF"                                     # Actual Content of Variable
    printline "$pexample" "$pdesc" "${presult}%"                        # Print Variable Line
    
    pexample="\$SADM_REAR_BACKUP_INTERVAL"                              # Directory Variable Name
    pdesc="Rear alert if Backup older than"                             # Directory Description
    presult="$SADM_REAR_BACKUP_INTERVAL"                                # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult days"                      # Print Variable Line

    pexample="\$SADM_BACKUP_NFS_SERVER"                                 # Directory Variable Name
    pdesc="NFS Backup IP or Server Name"                                # Directory Description
    presult="$SADM_BACKUP_NFS_SERVER"                                   # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_BACKUP_NFS_MOUNT_POINT"                            # Directory Variable Name
    pdesc="NFS Backup Mount Point"                                      # Directory Description
    presult="$SADM_BACKUP_NFS_MOUNT_POINT"                              # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_BACKUP_DIF"                                        # Directory Variable Name
    pdesc="Alert if size differ more than %"                            # Directory Description
    presult="$SADM_BACKUP_DIF"                                          # Actual Content of Variable
    printline "$pexample" "$pdesc" "${presult}%"                        # Print Variable Line
    
    pexample="\$SADM_BACKUP_INTERVAL"                                   # Directory Variable Name
    pdesc="Alert if Backup older than X days"                           # Directory Description
    presult="$SADM_BACKUP_INTERVAL"                                     # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult days"                      # Print Variable Line

    pexample="\$SADM_DAILY_BACKUP_TO_KEEP"                              # Directory Variable Name
    pdesc="Nb. of Daily Backup to keep"                                 # Directory Description
    presult="$SADM_DAILY_BACKUP_TO_KEEP"                                # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_WEEKLY_BACKUP_TO_KEEP"                             # Variable Name
    pdesc="Nb. of Weekly Backup to keep"                                # Description
    presult="$SADM_WEEKLY_BACKUP_TO_KEEP"                               # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_MONTHLY_BACKUP_TO_KEEP"                            # Variable Name
    pdesc="Nb. of Monthly Backup to keep"                               # Description
    presult="$SADM_MONTHLY_BACKUP_TO_KEEP"                              # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_YEARLY_BACKUP_TO_KEEP"                             # Variable Name
    pdesc="Nb. of Yearly Backup to keep"                                # Description
    presult="$SADM_YEARLY_BACKUP_TO_KEEP"                               # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_WEEKLY_BACKUP_DAY"                                 # Variable Name
    pdesc="Weekly Backup Day (1=Mon,...,7=Sun)"                         # Description
    presult="$SADM_WEEKLY_BACKUP_DAY"                                   # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_MONTHLY_BACKUP_DATE"                               # Variable Name
    pdesc="Monthly Backup Date (1-28)"                                  # Description
    presult="$SADM_MONTHLY_BACKUP_DATE"                                 # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_YEARLY_BACKUP_MONTH"                               # Variable Name
    pdesc="Month to take Yearly Backup (1-12)"                          # Description
    presult="$SADM_YEARLY_BACKUP_MONTH"                                 # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_YEARLY_BACKUP_DATE"                                # Variable Name
    pdesc="Date to do Yearly Backup(1-DayInMth)"                        # Description
    presult="$SADM_YEARLY_BACKUP_DATE"                                  # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_PID_TIMEOUT"                                       # Variable Name
    pdesc="PID File Time To Live default in sec"                        # Description
    presult="$SADM_PID_TIMEOUT"                                         # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_LOCK_TIMEOUT"                                      # Variable Name
    pdesc="Maximum of sec. a system can be lock"                        # Description
    presult="$SADM_LOCK_TIMEOUT"                                        # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line


    pexample="\$SADM_VM_EXPORT_NFS_SERVER"                              # Variable Name
    pdesc="NFS Export Server"                                           # Function Description
    presult="$SADM_VM_EXPORT_NFS_SERVER"                                # Return Value(s)
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line

    pexample="\$SADM_VM_EXPORT_MOUNT_POINT"                             # Variable Name
    pdesc="NFS Export Mount Point"                                      # Function Description
    presult="$SADM_VM_EXPORT_MOUNT_POINT"                               # Return Value(s)
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line

    pexample="\$SADM_VM_EXPORT_TO_KEEP"                                 # Variable Name
    pdesc="Nb. of export to keep"                                       # Function Description
    presult="$SADM_VM_EXPORT_TO_KEEP"                                   # Return Value(s)
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line

    pexample="\$SADM_VM_EXPORT_INTERVAL"                                # Variable Name
    pdesc="Days without export before alert"                            # Function Description
    presult="$SADM_VM_EXPORT_INTERVAL"                                  # Return Value(s)
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line

    pexample="\$SADM_VM_EXPORT_ALERT"                                   # Variable Name (Y/N)
    pdesc="Issue an alert if interval reached"                          # Function Description
    presult="$SADM_VM_EXPORT_ALERT"                                     # Return Value(s)
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line

    pexample="\$SADM_VM_USER"                                           # Variable Name
    pdesc="User part of 'vboxusers' user group"                         # Function Description
    presult="$SADM_VM_USER"                                             # Return Value(s)
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line

    pexample="\$SADM_VM_STOP_TIMEOUT"                                   # Variable Name
    pdesc="Max. seconds given for acpi shutdown"                        # Function Description
    presult="$SADM_VM_STOP_TIMEOUT"                                     # Return Value(s)
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line

    pexample="\$SADM_VM_START_INTERVAL"                                 # Variable Name
    pdesc="Sec. to sleep between each VM start"                         # Function Description
    presult="$SADM_VM_START_INTERVAL"                                   # Return Value(s)
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line

}


#===================================================================================================
# Print Command Path Variables available to users
#===================================================================================================
print_command_path()
{
    printheader "COMMAND PATH USE BY SADMIN STD. LIBR." "Description" "  This System Result"

    pexample="\$SADM_DMIDECODE"                                         # Variable Name
    pdesc="'dmidecode' use to get model & type"                         # Command Description
    presult="$SADM_DMIDECODE"                                           # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line

    pexample="\$SADM_BC"                                                # Variable Name
    pdesc="'bc' use to do some Math."                                   # Command Description
    presult="$SADM_BC"                                                  # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line

    pexample="\$SADM_FDISK"                                             # Variable Name
    pdesc="'fdisk' use to get partition info"                           # Command Description
    presult="$SADM_FDISK"                                               # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line

    pexample="\$SADM_WHICH"                                             # Variable Name
    pdesc="'which' use to get command path"                             # Command Description
    presult="$SADM_WHICH"                                               # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line

    pexample="\$SADM_PERL"                                              # Variable Name
    pdesc="'perl' epoch time Math on AIX"                               # Command Description
    presult="$SADM_PERL"                                                # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line

    pexample="\$SADM_MUTT"                                              # Variable Name
    pdesc="'mutt' use to send email"                                    # Command Description
    presult="$SADM_MUTT"                                                # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line

    pexample="\$SADM_CURL"                                              # Variable Name
    pdesc="'curl' Use to send alert to Slack"                           # Command Description
    presult="$SADM_CURL"                                                # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line

    pexample="\$SADM_LSCPU"                                             # Variable Name
    pdesc="'lscpu' To get Socket/Thread info"                           # Command Description
    presult="$SADM_LSCPU"                                               # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line

    pexample="\$SADM_NMON"                                              # Variable Name
    pdesc="'nmon' Collect Performance Stat."                            # Command Description
    presult="$SADM_NMON"                                                # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line

    pexample="\$SADM_PARTED"                                            # Variable Name
    pdesc="'parted' use to get disk real size"                          # Command Description
    presult="$SADM_PARTED"                                              # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line

    pexample="\$SADM_ETHTOOL"                                           # Variable Name
    pdesc="'ethtool' use to get system IP"                              # Command Description
    presult="$SADM_ETHTOOL"                                             # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line

    pexample="\$SADM_SSH"                                               # Variable Name
    pdesc="'ssh' use to SSH on SADMIN client"                           # Command Description
    presult="$SADM_SSH"                                                 # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line

    pexample="\$SADM_SSH_CMD"                                           # Variable Name
    pdesc="'ssh' SSH cmd to Connect to client"                          # Command Description
    presult="$SADM_SSH_CMD"                                             # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line

    pexample="\$SADM_RRDTOOL"                                           # Variable Name
    pdesc="'rrdtool' binary location"                                   # Description
    presult="$SADM_RRDTOOL"                                             # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line

    pexample="\$SADM_LSB_RELEASE"                                       # Variable Name
    pdesc="'lsb_release' cmd (get dist. info)"                          # Command Description
    presult="$SADM_LSB_RELEASE"                                         # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line

    pexample="\$SADM_INXI"                                              # Variable Name
    pdesc="'inxi' binary location"                                      # Description
    presult="$SADM_INXI"                                                # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line

    pexample="\$SADM_MYSQL"                                             # Variable Name
    pdesc="'mysql' binary location"                                     # Description
    presult="$SADM_MYSQL"                                               # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line

    pexample="\$SADM_SED"                                               # Variable Name
    pdesc="'sed' binary location"                                       # Description
    presult="$SADM_SED"                                                 # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
}


#===================================================================================================
# Print Database Information
#===================================================================================================
print_db_variables()
{
    printheader "Database Information" "Description" "  This System Result"

    CMDLINE="$SADM_MYSQL -t -u $SADM_RO_DBUSER  -p$SADM_RO_DBPWD "      # MySQL Auth/Read Only User

    printf "\n\nShow SADMIN Tables:\n"
    SQL="show tables; "                                                 # Show Table SQL
    $CMDLINE -h $SADM_DBHOST $SADM_DBNAME -Ne "$SQL" 

    printf "\n\nCategory Table:\n"
    SQL="describe server_category; "                                    # Show Table Format/colums
    $CMDLINE -h $SADM_DBHOST $SADM_DBNAME -Ne "$SQL" 
    SQL="select * from server_category; "                               # Show Table SQL
    $CMDLINE -h $SADM_DBHOST $SADM_DBNAME -Ne "$SQL" 
    SQL="SHOW keys FROM server_category FROM sadmin;"
    $CMDLINE -h $SADM_DBHOST $SADM_DBNAME -Ne "$SQL" 

    printf "\n\nGroup Table:\n"
    SQL="show columns from server_group; "                              # Show Table Format/columns
    $CMDLINE -h $SADM_DBHOST $SADM_DBNAME -Ne "$SQL" 
    SQL="select * from server_group; "                                  # Show Table SQL
    $CMDLINE -h $SADM_DBHOST $SADM_DBNAME -Ne "$SQL" 
    SQL="SHOW keys FROM server_group FROM sadmin;"
    $CMDLINE -h $SADM_DBHOST $SADM_DBNAME -Ne "$SQL" 

    printf "\n\nServer Table:\n"
    SQL="select srv_name, srv_desc, srv_osname, srv_osversion, srv_active, srv_cat, srv_group from server ; "
    SQL="describe server; "
    $CMDLINE -h $SADM_DBHOST $SADM_DBNAME -Ne "$SQL" 
    SQL="SHOW keys FROM server FROM sadmin;"
    $CMDLINE -h $SADM_DBHOST $SADM_DBNAME -Ne "$SQL" 

    printf "\n\nScript Table:\n"
    SQL="describe script; "
    $CMDLINE -h $SADM_DBHOST $SADM_DBNAME -Ne "$SQL" 
    SQL="SHOW keys FROM script FROM sadmin;"
    $CMDLINE -h $SADM_DBHOST $SADM_DBNAME -Ne "$SQL" 

    printf "\n\nScript Details:\n"
    SQL="describe script_rch; "
    $CMDLINE -h $SADM_DBHOST $SADM_DBNAME -Ne "$SQL" 
    SQL="SHOW keys FROM script_rch FROM sadmin;"
    $CMDLINE -h $SADM_DBHOST $SADM_DBNAME -Ne "$SQL" 

}


#===================================================================================================
# Print sadm_start() and sadm_stop() functions used by SADMIN tools.
#===================================================================================================
print_start_stop()
{
    printheader "Overview of sadm_start() and sadm_stop() functions."

    printf "\nExample of utilization:\n\n"
    printf " # sadm_start                                         # Init Env Dir & RCH/Log File\n"
    printf " # if [ \$? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi    # Exit if Problem\n" 
    printf " # main_process                                       # Main Process\n"
    printf " # SADM_EXIT_CODE=\$?                                  # Save Error Code\n"
    printf " # sadm_stop \$SADM_EXIT_CODE                          # Close SADM Tool & Upd RCH\n"
    printf " # exit \$SADM_EXIT_CODE                               # Exit With Global Err (0/1)\n"
    printf "\n"
    printf "Function 'sadm_start()':\n"
    printf "    Start and initialize SADMIN environment - accept no parameter\n"
    printf "    If SADMIN env. variable is not set /opt/sadmin, make sure it's set to proper dir.\n"
    printf "    Call this function when your script is starting.\n"
    printf "    What this function will do for us :\n" 
    printf "        1) Make sure all directories & sub-directories exist and have proper permissions.\n"
    printf "        2) Make sure log file exist with proper permission ($SADM_LOG)\n"
    printf "        3) Make sure Return Code History (.rch) exist and have the right permission\n"
    printf "        4) If PID file exist, show error message and abort.\n" 
    printf "           Unless user allow more than one copy to run simultaniously (SADM_MULTIPLE_EXEC='Y')\n"
    printf "        5) Add line in the [R]eturn [C]ode [H]istory file stating script is started (Code 2)\n"
    printf "        6) Write HostName - Script name and version - O/S Name and version to the Log file (SADM_LOG)\n"
    printf "\n"
    printf "Function 'sadm_stop($exit_code)':\n"
    printf "    Accept one parameter - Either 0 (Successfull) or non-zero (Error Encountered)\n"
    printf "    Please call this function just before your script end\n"
    printf "    What this function do.\n"
    printf "        1) If Exit Code is not zero, change it to 1.\n"
    printf "        2) Get Actual Time and Calculate the Execution Time.\n"
    printf "        3) Writing the Script Footer in the Log (Script Return code, Execution Time, ...)\n"
    printf "        4) Update the RCH File (Start/End/Elapse Time and the Result Code)\n"
    printf "        5) Trim The RCH File Based on User choice in sadmin.cfg\n"
    printf "        6) Write to Log the user mail alerting type choose by user (sadmin.cfg)\n"
    printf "        7) Trim the Log based on user selection in sadmin.cfg\n"
    printf "        8) Send Email to sysadmin (if user selected that option in sadmin.cfg)\n"
    printf "        9) Delete the PID File of the script (SADM_PID_FILE)\n"
    printf "       10) Delete the User 3 TMP Files (SADM_TMP_FILE1, SADM_TMP_FILE2, SADM_TMP_FILE3)\n"
    printf " \n"
}


# --------------------------------------------------------------------------------------------------
# Command line Options functions
# Evaluate Command Line Switch Options Upfront
# By Default (-h) Show Help Usage, (-v) Show Script Version,(-d0-9] Set Debug Level 
# --------------------------------------------------------------------------------------------------
function cmd_options()
{
    # Evaluate Command Line Switch Options Upfront
    # (-h) Show Help Usage, (-v) Show Script Version,(-d0-9] Set Debug Level, 
    # (-p) Show Database Password
    show_password="N"                                                   # Don't show DB Password
    #show_storix="N"                                                     # Don't show Storix Info
    show_textbelt="N"                                                   # Don't show TextBelt Key
    SADM_DEBUG=0                                                        # Lowest DEBUG Level

    while getopts "d:hvpt" opt ; do                                     # Loop to process Switch
        case $opt in
            d) SADM_DEBUG=$OPTARG                                       # Get Debug Level Specified
               num=`echo "$SADM_DEBUG" | grep -E ^\-?[0-9]?\.?[0-9]+$`  # Valid is Level is Numeric
               if [ "$num" = "" ]                            
                  then printf "\nDebug Level specified is invalid.\n"   # Inform User Debug Invalid
                       show_usage                                       # Display Help Usage
                       exit 1                                           # Exit Script with Error
               fi
               printf "Debug Level set to ${SADM_DEBUG}.\n"             # Display Debug Level
               ;; 
            p) show_password="Y"                                        # Flag to Show DB Password
               ;;                                                       
            t) show_textbelt="Y"                                        # Flag to Show TextBelt Key
               ;;                                                       
            #s) show_storix="Y"                                          # Show Storix Backup Info
            #   ;;                                                       
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

# --------------------------------------------------------------------------------------------------
#                                Script Start HERE
# --------------------------------------------------------------------------------------------------
    cmd_options "$@"                                                    # Check command-line Options
    sadm_start                                                          # Init Env. Dir. & RCH/Log
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # If Problem during init
    print_user_variables                                                # Print USer Variables
    print_functions                                                     # List Functions of SADMIN
    print_bash_functions                                                # List Bash Shell Only Func,
    print_start_stop                                                    # Help Start/Stop Function
    print_sadmin_cfg                                                    # List Sadmin Cfg File Var.
    print_directory                                                     # List Client Dir. Var. 
    print_file_variable                                                 # List Files Var. of SADMIN
    print_command_path                                                  # List Command Path
    if [ "$SADM_HOST_TYPE" = "S" ] ; then print_db_variables ;fi        # On SADM Server List DB Var.
    printf "\n\n"                                                       # End of report Line Feeds
    SDAM_EXIT_CODE=0                                                    # For Test purpose
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
