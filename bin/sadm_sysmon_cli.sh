#! /usr/bin/env bash
# --------------------------------------------------------------------------------------------------
#   Author   :  Jacques Duplessis
#   Title    :  sadm_sysmon_cli.sh
#   Synopsis :  Run the SADM System Monitor (sadm_sysmon.pl) and display Result file (hostname.rpt)
#   Version  :  1.6
#   Date     :  14 Fevrier 2017
#   Requires :  sh
#
#    2016 Jacques Duplessis <sadmlinux@gmail.com>
#
#   The SADMIN Tool is free software; you can redistribute it and/or modify it under the terms
#   of the GNU General Public License as published by the Free Software Foundation; either
#   version 2 of the License, or (at your option) any later version.

#   SADMIN Tools are distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
#   without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#   See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with this program.
#   If not, see <https://www.gnu.org/licenses/>.
# --------------------------------------------------------------------------------------------------
# Enhancements/Corrections Version Log
# 1.7  Added Print Content of Error reported by RCH Files
#       Output now colorized
# 2017_12_18 cmdline v1.8 Exit with Error when sadm_sysmon.pl was already running - Now Show Message & Exit 0
# 2018_01_12 cmdline v1.9 Update SADM Library Section - Small Corrections
# 2018_07_11 cmdline v2.0 Now showing running process after scanning the server rch files
# 2018_07_18 cmdline v2.1 Fix problem reporting System Monitor Result (rpt filename)
# 2018_08_20 cmdline v2.2 Don't use rch file & don't send email if failing (It is an interactive script)
# 2019_06_07 cmdline v2.3 Updated to adapt to the new format of the '.rch' file.
# 2022_08_17 cmdline v2.4 Updated with new SADMIN section v1.52
# 2022_08_21 cmdline v2.5 Fix problem when running on other system than SADMIN Server
# 2023_09_22 cmdline v2.6 Update SADMIN section (v1.56) and minor improvement.
# 2023_10_23 cmdline v2.7 Remove header and footer from the log.
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPT LE ^C
#set -x



# ------------------- S T A R T  O F   S A D M I N   C O D E    S E C T I O N  ---------------------
# v1.56 - Setup for Global Variables and load the SADMIN standard library.
#       - To use SADMIN tools, this section MUST be present near the top of your code.    

# Make Sure Environment Variable 'SADMIN' Is Defined.
if [ -z "$SADMIN" ] || [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]            # SADMIN defined? Libr.exist
    then if [ -r /etc/environment ] ; then source /etc/environment ;fi  # LastChance defining SADMIN
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
export SADM_VER='2.7'                                      # Script version number
export SADM_PDESC="Run SADMIN System Monitor and display result file (hostname.rpt)."
export SADM_ROOT_ONLY="Y"                                  # Run only by root ? [Y] or [N]
export SADM_SERVER_ONLY="N"                                # Run only on SADMIN server? [Y] or [N]
export SADM_EXIT_CODE=0                                    # Script Default Exit Code
export SADM_LOG_TYPE="B"                                   # Log [S]creen [L]og [B]oth
export SADM_LOG_APPEND="N"                                 # Y=AppendLog, N=CreateNewLog
export SADM_LOG_HEADER="N"                                 # Y=ProduceLogHeader N=NoHeader
export SADM_LOG_FOOTER="N"                                 # Y=IncludeFooter N=NoFooter
export SADM_MULTIPLE_EXEC="N"                              # Run Simultaneous copy of script
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
#export SADM_MAX_LOGLINE=500                                # Nb Lines to trim(0=NoTrim)
#export SADM_MAX_RCLINE=35                                  # Nb Lines to trim(0=NoTrim)
#export SADM_PID_TIMEOUT=7200                               # Sec. before PID Lock expire
#export SADM_LOCK_TIMEOUT=3600                              # Sec. before Del. System LockFile
# --------------- ---  E N D   O F   S A D M I N   C O D E    S E C T I O N  -----------------------






# --------------------------------------------------------------------------------------------------
#                               This Script environment variables
# --------------------------------------------------------------------------------------------------
# Screen related variables
clreol=`tput el`                                ; export clreol         # Clr to end of lne
clreos=`tput ed`                                ; export clreos         # Clr to end of scr
bold=$(tput bold)                               ; export bold           # bold attribute
bell=`tput bel`                                 ; export bell           # Ring the bell
reverse=`tput rev`                              ; export reverse        # rev. video attrib.
underline=$(tput sgr 0 1)                       ; export underline      # UnderLine
up=`tput cuu1`                                  ; export up             # cursor up
down=`tput cud1`                                ; export down           # cursor down
right=`tput cub1`                               ; export right          # cursor right
left=`tput cuf1`                                ; export left           # cursor left
clr=`tput clear`                                ; export clr            # clear the screen
blink=`tput blink`                              ; export blink          # turn blinking on
reset=$(tput sgr0)                              ; export reset          # Screen Reset Attribute

# Color Foreground Text
black=$(tput setaf 0)                           ; export black          # Black color
red=$(tput setaf 1)                             ; export red            # Red color
green=$(tput setaf 2)                           ; export green          # Green color
yellow=$(tput setaf 3)                          ; export yellow         # Yellow color
blue=$(tput setaf 4)                            ; export blue           # Blue color
magenta=$(tput setaf 5)                        ; export magenta        # Magenta color
cyan=$(tput setaf 6)                            ; export cyan           # Cyan color
white=$(tput setaf 7)                           ; export white          # White color

# Color Background Text
bblack=$(tput setab 0)                           ; export bblack          # Black color
bred=$(tput setab 1)                             ; export bred            # Red color
bgreen=$(tput setab 2)                           ; export bgreen          # Green color
byellow=$(tput setab 3)                          ; export byellow         # Yellow color
bblue=$(tput setab 4)                            ; export bblue           # Blue color
bmagenta=$(tput setab 5)                         ; export bmagenta        # Magenta color
bcyan=$(tput setab 6)                            ; export bcyan           # Cyan color
bwhite=$(tput setab 7)                           ; export bwhite          # White color

# Headers and  Logging
e_success()     { printf "${green}✔ %s${reset}\n" "$@"
 }
e_error()       { printf "${red}✖ %s${reset}\n" "$@" 
}
e_warning()     { printf "${tan}➜ %s${reset}\n" "$@"
 }
e_underline()   { printf "${underline}${bold}%s${reset}\n" "$@" 
}
e_bold()        { printf "${bold}%s${reset}\n" "$@" 
}
e_note()        { printf "${underline}${bold}${blue}Note:${reset}  ${blue}%s${reset}\n" "$@" 
}


# --------------------------------------------------------------------------------------------------
#                                Script Start HERE
# --------------------------------------------------------------------------------------------------
    sadm_start                                                          # Init Env. Dir. & RC/Log
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if Problem 
    tput clear 

    # GET THE LAST LINE OF EVERY RCH FILE INTO THE TMP2 WORK FILE
    find $SADM_RCH_DIR -type f -name '*.rch' -exec tail -1 {} \; > $SADM_TMP_FILE2

    # RETAIN LINES THAT TERMINATE BY A 1(ERROR) OR A 2(RUNNING) FROM TMP2 WORK FILE INTO TMP3 FILE
    awk 'match($10,/[1-2]/) { print }' $SADM_TMP_FILE2 | grep -v ' smon 2' > $SADM_TMP_FILE3 

    # Run the System Monitor
    $SADM_BIN_DIR/sadm_sysmon.pl
    SADM_EXIT_CODE=$?                                                   # Save Process Exit Code
    if [ "$SADM_EXIT_CODE" -ne "0" ] 
        then echo "System Monitor (sadm_sysmon.pl) is already running." 
             echo "Try running it again in a couple of seconds."
             sadm_stop 0                                                # Upd. RCH File & Trim Log 
             exit 0    
    fi

    tput clear 
    WDATE=`date "+%Y/%m/%d %H:%M"`
    e_bold "System Monitor Command Line Report v${SADM_VER}                      $WDATE"
    echo "------------------------------------------------------------------------------"
    e_bold "Based on SysMon configuration file $SADM_CFG_DIR/${SADM_HOSTNAME}.smon"
    e_bold "Here is the output of SysMon Report File $SADM_RPT_DIR/${SADM_HOSTNAME}.rpt"
    echo "------------------------------------------------------------------------------"
    if [ -s $SADM_RPT_DIR/${SADM_HOSTNAME}.rpt ] 
        then cat $SADM_RPT_DIR/${SADM_HOSTNAME}.rpt | while read line 
                do
                e_error "$line"
                done 
        else e_success "No error reported by SysMon report file" 
    fi
    echo " "
    echo " "
    echo "------------------------------------------------------------------------------"
    e_bold "Running script(s) and Error(s) signaled by the Return Code History file"
    echo "------------------------------------------------------------------------------"
    if [ -s $SADM_TMP_FILE3 ] 
       then cat  $SADM_TMP_FILE3 | while read line 
              do
              e_error "$line"
              done 
       else e_success "No error reported by any RCH files" 
    fi
    echo " "
    echo "------------------------------------------------------------------------------"
    echo " "

    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)                                             # Exit With Global Error code (0/1)
