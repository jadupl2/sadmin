#! /usr/bin/env sh
# --------------------------------------------------------------------------------------------------
#   Author   :  Jacques Duplessis
#   Title    :  sadmlib_std_demo.sh
#   Synopsis : .
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
#
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPT The Control-C
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
    export SADM_VER='3.3'                               # Current Script Version
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
lcount=0                                                                # Print Line Counter




#===================================================================================================
# Standardize Print Line Function 
#===================================================================================================
printline()
{
    lcount=`expr $lcount + 1`                                           # Incr. Print Line Number
    p1=$1 ; p2=$2 ; p3=$3
    printf "\n[%03d] " $lcount                                          # Print Line Number
    if [ "$p1" != "" ] ; then printf "%-33s" "$p1"            ;fi
    if [ "$p2" != "" ] ; then printf "%-36s" "$p2"            ;fi  
    if [ "$p1" != "" ] && [ "$p2" != "" ] 
        then printf "%-33s" ": .${p3}."     
    fi
    #printf "%-33s" ": .${p3}."  
}

#===================================================================================================
# Standardize Print Header Function 
#===================================================================================================
printheader()
{
    lcount=0                                                            # Clear Print Line Number
    h1=$1
    h1=$1 ; h2=$2 ; h3=$3
    printf "\n\n\n`printf %100s |tr " " "="`"
    printf "\n$SADM_PN v$SADM_VER - Library v$SADM_LIB_VER"
    printf "\n%-39s%-36s%-33s" "$h1" "$h2" "$h3" 
    printf "\n`printf %100s |tr " " "="`"
}

#===================================================================================================
# Print SADMIN Function available to Users
#===================================================================================================
print_user_variables()
{
    printheader "User Var. that affect SADMIN behavior" "Description" "  This System Result"

    pexample="\$SADM_VER"                                               # Directory Variable Name
    pdesc="Script Version Number"                                       # Function Description
    presult="$SADM_VER"                                                 # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_PN"                                                # Directory Variable Name
    pdesc="Script Name"                                                 # Function Description
    presult="$SADM_PN"                                                  # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_INST"                                              # Directory Variable Name
    pdesc="Script Name Without Extension"                               # Function Description
    presult="$SADM_INST"                                                # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_USERNAME"                                          # Directory Variable Name
    pdesc="Current User Name"                                           # Function Description
    presult="$SADM_USERNAME"                                            # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_TPID"                                              # Directory Variable Name
    pdesc="Current Process ID"                                          # Function Description
    presult="$SADM_TPID"                                                # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_MULTIPLE_EXEC"                                     # Directory Variable Name
    pdesc="Allow running multiple copy"                                 # Function Description
    presult="$SADM_MULTIPLE_EXEC"                                       # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_USE_RCH"                                           # Directory Variable Name
    pdesc="Gen. entry in .rch file"                                     # Function Description
    presult="$SADM_USE_RCH"                                             # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_LOG_TYPE"                                          # Directory Variable Name
    pdesc="Set Output to [S]creen [L]og [B]oth"                         # Function Description
    presult="$SADM_LOG_TYPE"                                            # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_LOG_APPEND"                                        # Directory Variable Name
    pdesc="Append Log or Create New One"                                # Function Description
    presult="$SADM_LOG_APPEND"                                          # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_LOG_HEADER"                                        # Directory Variable Name
    pdesc="Generate Header in log"                                      # Function Description
    presult="$SADM_LOG_HEADER"                                          # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_LOG_FOOTER"                                        # Directory Variable Name
    pdesc="Generate Footer in  log"                                     # Function Description
    presult="$SADM_LOG_FOOTER"                                          # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_EXIT_CODE"                                         # Directory Variable Name
    pdesc="Script Exit Return Code"                                     # Function Description
    presult="$SADM_EXIT_CODE"                                           # Actual Content of Variable
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

}



#===================================================================================================
# Print SADMIN Functions Available Only in Bash Shell
#===================================================================================================
print_bash_functions()
{
    printheader "SADMIN Bash Shell Specific Functions" "Description" "  This System Result"

    pexample="\$(sadm_server_type)"                                     # Example Calling Function
    pdesc="Host is Physical or Virtual (P/V)"                           # Function Description
    presult=$(sadm_server_type)                                         # Return Value(s)
    printline "$pexample" "$pdesc" "$presult"                           # Print Example Line
    
    pexample="\$(sadm_server_model)"                                    # Example Calling Function
    pdesc="Server model (Ex: HP ProLiant DL580)"                        # Function Description
    presult=$(sadm_server_model)                                        # Return Value(s)
    printline "$pexample" "$pdesc" "$presult"                           # Print Example Line
        
    pexample="\$(sadm_server_serial)"                                   # Example Calling Function
    pdesc="Server serial number (Ex: 4S7GYF1)"                          # Function Description
    presult=$(sadm_server_serial)                                       # Return Value(s)
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
    pdesc="Number of Logical CPU on server"                             # Function Description
    presult=$(sadm_server_nb_logical_cpu)                               # Return Value(s)
    printline "$pexample" "$pdesc" "$presult"                           # Print Example Line
                
    pexample="\$(sadm_server_nb_cpu)"                                   # Example Calling Function
    pdesc="Number of Physical CPU on server"                            # Function Description
    presult=$(sadm_server_nb_cpu)                                       # Return Value(s)
    printline "$pexample" "$pdesc" "$presult"                           # Print Example Line
                
    pexample="\$(sadm_server_nb_socket)"                                # Example Calling Function
    pdesc="Number of socket on server"                                  # Function Description
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
    
}



#===================================================================================================
# Print Client Directories Variables Available to Users
#===================================================================================================
print_client_directory()
{
    printheader "Client Directories Var. Avail." "Description" "  This System Result"

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
}



#===================================================================================================
# Print Client Directories Variables Available to Users
#===================================================================================================
print_server_directory()
{
    printheader "Server Directories Var. Avail." "Description" "  This System Result"
        
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
    
}




#===================================================================================================
# Print Files Variables Available to Users
#===================================================================================================
print_file()
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
    
    pexample="\$SADM_CFG_HIDDEN"                                        # Directory Variable Name
    pdesc="SADMIN Initial Configuration File"                           # Directory Description
    presult="$SADM_CFG_HIDDEN"                                          # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
                    
    #pexample="\$SADM_REL_FILE"                                          # Directory Variable Name
    #pdesc="SADMIN Release File"                                         # Directory Description
    #presult="$SADM_REL_FILE"                                            # Actual Content of Variable
    #printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_TMP_FILE1"                                         # Directory Variable Name
    pdesc="User usable Temp Work File 1"                                # Directory Description
    presult="$SADM_TMP_FILE1"                                           # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
        
    pexample="\$SADM_TMP_FILE2"                                         # Directory Variable Name
    pdesc="User usable Temp Work File 2"                                # Directory Description
    presult="$SADM_TMP_FILE2"                                           # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
        
    pexample="\$SADM_TMP_FILE3"                                         # Directory Variable Name
    pdesc="User usable Temp Work File 3"                                # Directory Description
    presult="$SADM_TMP_FILE3"                                           # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
            
    pexample="\$SADM_LOG"                                               # Directory Variable Name
    pdesc="Script Log File"                                             # Directory Description
    presult="$SADM_LOG"                                                 # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
            
    pexample="\$SADM_RCHLOG"                                            # Directory Variable Name
    pdesc="Script Return Code History File"                             # Directory Description
    presult="$SADM_RCHLOG"                                              # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
                
    pexample="\$DBPASSFILE"                                             # Directory Variable Name
    pdesc="SADMIN Database User Password File"                          # Directory Description
    presult="$DBPASSFILE"                                               # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
                
    pexample="\$SADM_RPT_FILE"                                          # Directory Variable Name
    pdesc="SYStem MONitor Report File"                                  # Directory Description
    presult="$SADM_RPT_FILE"                                            # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
                
}


#===================================================================================================
# Print sadmin.cfg Variables available to users
#===================================================================================================
print_sadmin_cfg()
{
    printheader "SADMIN CONFIG FILE VARIABLES" "Description" "  This System Result"

    pexample="\$SADM_SERVER"                                            # Directory Variable Name
    pdesc="SADMIN SERVER NAME (FQDN)"                                   # Directory Description
    presult="$SADM_SERVER"                                              # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
                    
    pexample="\$SADM_HOST_TYPE"                                         # Directory Variable Name
    pdesc="SADMIN [C]lient or [S]erver"                                 # Directory Description
    presult="$SADM_HOST_TYPE"                                           # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
         
    pexample="\$SADM_MAIL_ADDR"                                         # Directory Variable Name
    pdesc="SADMIN Administrator Default Email"                          # Directory Description
    presult="$SADM_MAIL_ADDR"                                           # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
                    
    pexample="\$SADM_MAIL_TYPE"                                         # Directory Variable Name
    pdesc="0=NoMail 1=OnError 3=OnSuccess 4=All"                        # Directory Description
    presult="$SADM_MAIL_TYPE"                                           # Actual Content of Variable
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
    pdesc="SADMIN Database Read/Write User"                             # Directory Description
    presult="$SADM_RW_DBUSER"                                           # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_RW_DBPWD"                                          # Directory Variable Name
    pdesc="SADMIN Database Read/Write User Pwd"                         # Directory Description
    presult="$SADM_RW_DBPWD"                                            # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_RO_DBUSER"                                         # Directory Variable Name
    pdesc="SADMIN Database Read Only User"                              # Directory Description
    presult="$SADM_RO_DBUSER"                                           # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_RO_DBPWD"                                          # Directory Variable Name
    pdesc="SADMIN Database Read Only User Pwd"                          # Directory Description
    presult="$SADM_RO_DBPWD"                                            # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_RRDTOOL"                                           # Directory Variable Name
    pdesc="RRDTOOL Binary Location"                                     # Directory Description
    presult="$SADM_RRDTOOL"                                             # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_SSH_PORT"                                          # Directory Variable Name
    pdesc="SSH Port to communicate with client"                         # Directory Description
    presult="$SADM_SSH_PORT"                                            # Actual Content of Variable
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
    presult="$SADM_NETWORK2"                                            # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_NETWORK3"                                          # Directory Variable Name
    pdesc="Network/Netmask 3 inv. IP/Name/Mac"                          # Directory Description
    presult="$SADM_NETWORK3"                                            # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_NETWORK4"                                          # Directory Variable Name
    pdesc="Network/Netmask 4 inv. IP/Name/Mac"                          # Directory Description
    presult="$SADM_NETWORK4"                                            # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_NETWORK5"                                          # Directory Variable Name
    pdesc="Network/Netmask 5 inv. IP/Name/Mac"                          # Directory Description
    presult="$SADM_NETWORK5"                                            # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
   
    pexample="\$SADM_MKSYSB_NFS_SERVER"                                 # Directory Variable Name
    pdesc="AIX MKSYSB NFS Server IP or Name"                            # Directory Description
    presult="$SADM_MKSYSB_NFS_SERVER"                                   # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_MKSYSB_NFS_MOUNT_POINT"                            # Directory Variable Name
    pdesc="AIX MKSYSB NFS Mount Point"                                  # Directory Description
    presult="$SADM_MKSYSB_NFS_MOUNT_POINT"                              # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_MKSYSB_BACKUP_TO_KEEP"                             # Directory Variable Name
    pdesc="AIX MKSYSB NFS Backup - Nb. to keep"                         # Directory Description
    presult="$SADM_MKSYSB_BACKUP_TO_KEEP"                               # Actual Content of Variable
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

    pexample="\$SADM_BACKUP_NFS_SERVER"                                 # Directory Variable Name
    pdesc="NFS Backup IP or Server Name"                                # Directory Description
    presult="$SADM_BACKUP_NFS_SERVER"                                   # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_BACKUP_NFS_MOUNT_POINT"                            # Directory Variable Name
    pdesc="NFS Backup Mount Point"                                      # Directory Description
    presult="$SADM_BACKUP_NFS_MOUNT_POINT"                              # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_DAILY_BACKUP_TO_KEEP"                              # Directory Variable Name
    pdesc="Nb. of Daily Backup to keep"                                 # Directory Description
    presult="$SADM_DAILY_BACKUP_TO_KEEP"                                # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_WEEKLY_BACKUP_TO_KEEP"                             # Directory Variable Name
    pdesc="Nb. of Weekly Backup to keep"                                # Directory Description
    presult="$SADM_WEEKLY_BACKUP_TO_KEEP"                               # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_MONTHLY_BACKUP_TO_KEEP"                            # Directory Variable Name
    pdesc="Nb. of Monthly Backup to keep"                               # Directory Description
    presult="$SADM_MONTHLY_BACKUP_TO_KEEP"                              # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_YEARLY_BACKUP_TO_KEEP"                             # Directory Variable Name
    pdesc="Nb. of Yearly Backup to keep"                                # Directory Description
    presult="$SADM_YEARLY_BACKUP_TO_KEEP"                               # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_WEEKLY_BACKUP_DAY"                                 # Directory Variable Name
    pdesc="Weekly Backup Day (1=Mon,...,7=Sun)"                         # Directory Description
    presult="$SADM_WEEKLY_BACKUP_DAY"                                   # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_MONTHLY_BACKUP_DATE"                               # Directory Variable Name
    pdesc="Monthly Backup Date (1-28)"                                  # Directory Description
    presult="$SADM_MONTHLY_BACKUP_DATE"                                 # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_YEARLY_BACKUP_MONTH"                               # Directory Variable Name
    pdesc="Month to take Yearly Backup (1-12)"                          # Directory Description
    presult="$SADM_YEARLY_BACKUP_MONTH"                                 # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_YEARLY_BACKUP_DATE"                                # Directory Variable Name
    pdesc="Date to do Yearly Backup(1-DayInMth)"                         # Directory Description
    presult="$SADM_YEARLY_BACKUP_DATE"                                  # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line

    pexample="\$SADM_STORIX_NFS_SERVER"                                 # Directory Variable Name
    pdesc="Storix NFS Server IP or Name"                                # Directory Description
    presult="$SADM_STORIX_NFS_SERVER"                                   # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_STORIX_NFS_MOUNT_POINT"                            # Directory Variable Name
    pdesc="Storix NFS Mount Point"                                      # Directory Description
    presult="$SADM_STORIX_NFS_MOUNT_POINT"                              # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line
    
    pexample="\$SADM_STORIX_BACKUP_TO_KEEP"                             # Directory Variable Name
    pdesc="Storix NFS Backup - Nb. to Keep"                             # Directory Description
    presult="$SADM_STORIX_BACKUP_TO_KEEP"                               # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line

}


#===================================================================================================
# Print Command Path Variables available to users
#===================================================================================================
print_command_path()
{
    printheader "COMMAND PATH USE BY SADMIN STD. LIBR." "Description" "  This System Result"

    pexample="\$SADM_LSB_RELEASE"                                       # Variable Name
    pdesc="Cmd. 'lsb_release', Get O/S Version"                         # Command Location
    presult="$SADM_LSB_RELEASE"                                         # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line

    pexample="\$SADM_DMIDECODE"                                         # Variable Name
    pdesc="Cmd. 'dmidecode', Get model & type"                          # Command Location
    presult="$SADM_DMIDECODE"                                           # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line

    pexample="\$SADM_FACTER"                                            # Variable Name
    pdesc="Cmd. 'facter', Get System Info"                              # Command Location
    presult="$SADM_FACTER"                                              # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line

    pexample="\$SADM_BC"                                                # Variable Name
    pdesc="Cmd. 'bc', Do some Math."                                    # Command Location
    presult="$SADM_BC"                                                  # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line

    pexample="\$SADM_FDISK"                                             # Variable Name
    pdesc="Cmd. 'fdisk', Get Partition Info"                            # Command Location
    presult="$SADM_FDISK"                                               # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line

    pexample="\$SADM_WHICH"                                             # Variable Name
    pdesc="Cmd. 'which', Get Command location"                          # Command Location
    presult="$SADM_WHICH"                                               # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line

    pexample="\$SADM_PERL"                                              # Variable Name
    pdesc="Cmd. 'perl', epoch time Calc."                               # Command Location
    presult="$SADM_PERL"                                                # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line

    pexample="\$SADM_MAIL"                                              # Variable Name
    pdesc="Cmd. 'mail', Send SysAdmin Email"                            # Command Location
    presult="$SADM_MAIL"                                                # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line

    pexample="\$SADM_LSCPU"                                             # Variable Name
    pdesc="Cmd. 'lscpu', Socket & thread info"                          # Command Location
    presult="$SADM_LSCPU"                                               # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line

    pexample="\$SADM_NMON"                                              # Variable Name
    pdesc="Cmd. 'nmon', Collect Perf Statistic"                         # Command Location
    presult="$SADM_NMON"                                                # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line

    pexample="\$SADM_PARTED"                                            # Variable Name
    pdesc="Cmd. 'parted', Get Disk Real Size"                           # Command Location
    presult="$SADM_PARTED"                                              # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line

    pexample="\$SADM_ETHTOOL"                                           # Variable Name
    pdesc="Cmd. 'ethtool', Get System IP Info"                          # Command Location
    presult="$SADM_ETHTOOL"                                             # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line

    pexample="\$SADM_SSH"                                               # Variable Name
    pdesc="Cmd. 'ssh', SSH to SADMIN client"                            # Command Location
    presult="$SADM_SSH"                                                 # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line

    pexample="\$SADM_SSH_CMD"                                           # Variable Name
    pdesc="Cmd. 'ssh', SSH to Connect to client"                        # Command Location
    presult="$SADM_SSH_CMD"                                             # Actual Content of Variable
    printline "$pexample" "$pdesc" "$presult"                           # Print Variable Line

}



#===================================================================================================
# Print sadm_start and sadm_stop Function Used by SADMIN Tools
#===================================================================================================
print_start_stop()
{
    printheader "Overview of sadm_start and sadm_stop function"

    printf "\nExample of utilisation:\n\n"
    printf " # sadm_start                                         # Init Env Dir & RC/Log File\n"
    printf " # if [ \$? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi    # Exit if Problem\n" 
    printf " # main_process                                       # Main Process\n"
    printf " # SADM_EXIT_CODE=\$?                                  # Save Error Code\n"
    printf " # sadm_stop \$SADM_EXIT_CODE                          # Close SADM Tool & Upd RCH\n"
    printf " # exit \$SADM_EXIT_CODE                               # Exit With Global Err (0/1)\n"
    printf "\n"
    printf "sadm_start\n"
    printf "    Start and initialize sadm environment - Accept no Parameter\n"
    printf "    If SADMIN root directory is not /sadmin, make sure the SADMIN Env. variable is set to proper dir.\n"
    printf "    Please call this function when your script is starting\n"
    printf "    What this function will do for us :\n" 
    printf "        1) Make sure all directories & sub-directories exist and have proper permissions.\n"
    printf "        2) Make sure log file exist with proper permission ($SADM_LOG)\n"
    printf "        3) Make sure Return Code History (.rch) exist and have the right permission\n"
    printf "        4) If PID file exist, show error message and abort.\n" 
    printf "           Unless user allow more than one copy to run simultaniously (SADM_MULTIPLE_EXEC='Y')\n"
    printf "        5) Add line in the [R]eturn [C]ode [H]istory file stating script is started (Code 2)\n"
    printf "        6) Write HostName - Script name and version - O/S Name and version to the Log file (SADM_LOG)\n"
    printf "\n"
    printf "sadm_stop\n"
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
#                                Script Start HERE
# --------------------------------------------------------------------------------------------------
    # If you want this script to be run only by 'root'.
    if ! [ $(id -u) -eq 0 ]                                             # If Cur. user is not root 
        then printf "\nThis script must be run by the 'root' user"      # Advise User Message
             printf "\nTry sudo %s" "${0##*/}"                          # Suggest using sudo
             printf "\nProcess aborted\n\n"                             # Abort advise message
             exit 1                                                     # Exit To O/S with error
    fi
    sadm_start                                                          # Init Env. Dir. & RCH/Log
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # If Problem during init
    
    print_user_variables                                                # Print USer Variables
    print_functions                                                     # List Functions of SADMIN
    print_bash_functions                                                # List Bash Shell Only Func,
    print_start_stop                                                    # Help Start/Stop Function
    print_sadmin_cfg                                                    # List Sadmin Cfg File Var.
    print_client_directory                                              # List Client Dir. Var. 
    print_server_directory                                              # List Server Dir. Var. 
    print_file                                                          # List Files Var. of SADMIN
    print_command_path                                                  # List Command PAth
    printf "\n\n"                                                       # End of report Line Feeds
    SDAM_EXIT_CODE=0                                                    # For Test purpose
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
