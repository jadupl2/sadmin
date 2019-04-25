#! /usr/bin/env bash
# --------------------------------------------------------------------------------------------------
#   Author   :  Jacques Duplessis
#   Title    :  sadm_sysmon_cli.sh
#   Synopsis :  Run the SADM System Monitor (sadm_sysmon.pl) and display Result file (hostname.rpt)
#   Version  :  1.6
#   Date     :  14 Fevrier 2017
#   Requires :  sh
#
#   Copyright (C) 2016 Jacques Duplessis <duplessis.jacques@gmail.com>
#
#   The SADMIN Tool is free software; you can redistribute it and/or modify it under the terms
#   of the GNU General Public License as published by the Free Software Foundation; either
#   version 2 of the License, or (at your option) any later version.

#   SADMIN Tools are distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
#   without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#   See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with this program.
#   If not, see <http://www.gnu.org/licenses/>.
# --------------------------------------------------------------------------------------------------
# Enhancements/Corrections Version Log
# 1.7  Added Print Content of Error reported by RCH Files
#       Output now colorized
# 2017_12_18    V1.8 Exit with Error when sadm_sysmon.pl was already running - Now Show Message & Exit 0
# 2018_01_12    V1.9 Update SADM Library Section - Small Corrections
# 2018_07_11    v2.0 Now showing running process after scanning the server rch files
# 2018_07_18    v2.1 Fix problem reporting System Monitor Result (rpt filename)
#@2018_08_20    v2.2 Don't use rch file & don't send email if failing (It is an interactive script)
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPTE LE ^C
#set -x



#===================================================================================================
#               Setup SADMIN Global Variables and Load SADMIN Shell Library
#===================================================================================================
#
    # Test if 'SADMIN' environment variable is defined
    if [ -z "$SADMIN" ]                                 # If SADMIN Environment Var. is not define
        then echo "Please set 'SADMIN' Environment Variable to the install directory." 
             exit 1                                     # Exit to Shell with Error
    fi

    # Test if 'SADMIN' Shell Library is readable 
    if [ ! -r "$SADMIN/lib/sadmlib_std.sh" ]            # SADM Shell Library not readable
        then echo "SADMIN Library can't be located"     # Without it, it won't work 
             exit 1                                     # Exit to Shell with Error
    fi

    # CHANGE THESE VARIABLES TO YOUR NEEDS - They influence execution of SADMIN standard library.
    export SADM_VER='2.2'                               # Current Script Version
    export SADM_LOG_TYPE="B"                            # Writelog goes to [S]creen [L]ogFile [B]oth
    export SADM_LOG_APPEND="N"                          # Append Existing Log or Create New One
    export SADM_LOG_HEADER="N"                          # Show/Generate Script Header
    export SADM_LOG_FOOTER="N"                          # Show/Generate Script Footer 
    export SADM_MULTIPLE_EXEC="Y"                       # Allow running multiple copy at same time ?
    export SADM_USE_RCH="N"                             # Generate Entry in Result Code History file

    # DON'T CHANGE THESE VARIABLES - They are used to pass information to SADMIN Standard Library.
    export SADM_PN=${0##*/}                             # Current Script name
    export SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1`   # Current Script name, without the extension
    export SADM_TPID="$$"                               # Current Script PID
    export SADM_EXIT_CODE=0                             # Current Script Exit Return Code
    . ${SADMIN}/lib/sadmlib_std.sh                      # Load SADMIN Shell Standard Library
#
#---------------------------------------------------------------------------------------------------
#
    # Default Value for these Global variables are defined in $SADMIN/cfg/sadmin.cfg file.
    # But they can be overriden here on a per script basis.
    #export SADM_ALERT_TYPE=1                           # 0=None 1=AlertOnErr 2=AlertOnOK 3=Allways
    #export SADM_ALERT_GROUP="default"                  # AlertGroup Used to Alert (alert_group.cfg)
    #export SADM_MAIL_ADDR="your_email@domain.com"      # Email to send log (To Override sadmin.cfg)
    #export SADM_MAX_LOGLINE=1000                       # When Script End Trim log file to 1000 Lines
    #export SADM_MAX_RCLINE=125                         # When Script End Trim rch file to 125 Lines
    #export SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT} " # SSH Command to Access Server 
#
#===================================================================================================




# --------------------------------------------------------------------------------------------------
#                               This Script environment variables
# --------------------------------------------------------------------------------------------------
DEBUG_LEVEL=0                               ; export DEBUG_LEVEL        # 0=NoDebug Higher=+Verbose

# Screen related variables
clreol=`tput el`                                ; export clreol         # Clr to end of lne
clreos=`tput ed`                                ; export clreos         # Clr to end of scr
bold=$(tput bold)                               ; export bold           # bold attribute
bell=`tput bel`                                 ; export bell           # Ring the bell
reverse=`tput rev`                              ; export reverse        # rev. video attrib.
underline=$(tput sgr 0 1)                       ; export underline      # UnderLine
home=`tput home`                                ; export home           # home cursor
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

    if [ "$(whoami)" != "root" ]                                        # Is it root running script?
        then sadm_writelog "Script can only be run user 'root'"         # Advise User should be root
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close/Trim Log & Upd. RCH
             exit 1                                                     # Exit To O/S
    fi

    tput clear 

    # GET THE LAST LINE OF EVERY RCH FILE INTO THE TMP2 WORK FILE
    find $SADM_RCH_DIR -type f -name '*.rch' -exec tail -1 {} \; > $SADM_TMP_FILE2

    # RETAIN LINES THAT TERMINATE BY A 1(ERROR) OR A 2(RUNNING) FROM TMP2 WORK FILE INTO TMP3 FILE
    awk 'match($9,/[1-2]/) { print }' $SADM_TMP_FILE2 | grep -v ' smon 2' > $SADM_TMP_FILE3 

    # Run the System Monitor
    $SADM_BIN_DIR/sadm_sysmon.pl
    SADM_EXIT_CODE=$?                                                   # Save Process Exit Code
    if [ "$SADM_EXIT_CODE" -ne "0" ] 
        then echo "System Monitor (sadm_sysmon.pl) is running" 
             echo "Try running 'smon' in a couple of seconds"
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
