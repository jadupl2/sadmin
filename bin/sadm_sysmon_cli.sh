#! /usr/bin/env sh
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
# 2017_12_18    JDuplessis
#   V1.8 Exit with Error when sadm_sysmon.pl was already running - Now Show Message & Exit 0
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
SADM_VER='1.8'                             ; export SADM_VER            # Script Version
SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1` ; export SADM_INST           # Script name without ext.
SADM_TPID="$$"                             ; export SADM_TPID           # Script PID
SADM_EXIT_CODE=0                           ; export SADM_EXIT_CODE      # Script Exit Return Code
SADM_BASE_DIR=${SADMIN:="/sadmin"}         ; export SADM_BASE_DIR       # SADMIN Root Base Dir.
SADM_LOG_TYPE="L"                          ; export SADM_LOG_TYPE       # 4Logger S=Scr L=Log B=Both
SADM_LOG_APPEND="N"                        ; export SADM_LOG_APPEND     # Append to Existing Log ?
SADM_MULTIPLE_EXEC="Y"                     ; export SADM_MULTIPLE_EXEC  # Run many copy at same time
#
[ -f ${SADM_BASE_DIR}/lib/sadmlib_std.sh ]    && . ${SADM_BASE_DIR}/lib/sadmlib_std.sh     
[ -f ${SADM_BASE_DIR}/lib/sadmlib_server.sh ] && . ${SADM_BASE_DIR}/lib/sadmlib_server.sh  

# These variables are defined in sadmin.cfg file - You can also change them on a per script basis 
SADM_SSH_CMD="${SADM_SSH} -qnp ${SADM_SSH_PORT}" ; export SADM_SSH_CMD  # SSH Command to Access Farm
SADM_MAIL_TYPE=1                           ; export SADM_MAIL_TYPE      # 0=No 1=Err 2=Succes 3=All
#SADM_MAX_LOGLINE=5000                       ; export SADM_MAX_LOGLINE   # Max Nb. Lines in LOG )
#SADM_MAX_RCLINE=100                         ; export SADM_MAX_RCLINE    # Max Nb. Lines in RCH file
#SADM_MAIL_ADDR="your_email@domain.com"      ; export ADM_MAIL_ADDR      # Email Address of owner
#===================================================================================================
#



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
screen_color="\E[44;38m"                        ; export screen_color   # (BG Blue FG White)
reset=$(tput sgr0)                              ; export reset          # Screen Reset Attribute

# Color Foreground Text
black=$(tput setaf 0)                           ; export black          # Black color
red=$(tput setaf 1)                             ; export red            # Red color
green=$(tput setaf 2)                           ; export green          # Green color
yellow=$(tput setaf 3)                          ; export yellow         # Yellow color
blue=$(tput setaf 4)                            ; export blue           # Blue color
magentae=$(tput setaf 5)                        ; export magenta        # Magenta color
cyan=$(tput setaf 6)                            ; export cyan           # Cyan color
white=$(tput setaf 7)                           ; export white          # White color

# Color Background Text
bblack=$(tput setab 0)                           ; export bblack          # Black color
bred=$(tput setab 1)                             ; export bred            # Red color
bgreen=$(tput setab 2)                           ; export bgreen          # Green color
byellow=$(tput setab 3)                          ; export byellow         # Yellow color
bblue=$(tput setab 4)                            ; export bblue           # Blue color
bmagentae=$(tput setab 5)                        ; export bmagenta        # Magenta color
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
    sadm_start                                                          # Init Env Dir & RC/Log File
    if ! $(sadm_is_root)                                                # Is it root running script?
        then sadm_writelog "Script can only be run by the 'root' user"  # Advise User Message
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi

    tput clear 

    # GET THE LAST LINE OF EVERY RCH FILE INTO THE TMP2 WORK FILE
    find $SADM_RCH_DIR -type f -name '*.rch' -exec tail -1 {} \; > $SADM_TMP_FILE2

    # RETAIN LINES THAT TERMINATE BY A 1(ERROR) OR A 2(RUNNING) FROM TMP2 WORK FILE INTO TMP3 FILE
    awk 'match($8,/1/) { print }' $SADM_TMP_FILE2 > $SADM_TMP_FILE3 

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
    echo "----------------------------------------------------------------------------------"
    e_bold "Based on the current configutation file $SADM_CFG_DIR/${HOSTNAME}.cfg"
    e_bold "Here is the output file $SADM_RPT_DIR/${HOSTNAME}.rpt of SADM System Monitor"
    echo "----------------------------------------------------------------------------------"
    if [ -s $SADM_RPT_DIR/${HOSTNAME}.rpt ] 
        then cat $SADM_RPT_DIR/${HOSTNAME}.rpt | while read line 
                do
                e_error "$line"
                done 
        else e_success "No error reported by SysMon file" 
    fi
    echo " "
    echo " "
    echo "----------------------------------------------------------------------------------"
    e_bold "Error(s) signaled by the Return Code History file"
    echo "----------------------------------------------------------------------------------"
    if [ -s $SADM_TMP_FILE3 ] 
       then cat  $SADM_TMP_FILE3 | while read line 
              do
              e_error "$line"
              done 
       else e_success "No error reported by the RCH files" 
    fi
    echo " "
    echo "----------------------------------------------------------------------------------"
    echo " "

    # Go Write Log Footer - Send email if needed - Trim the Log - Update the Recode History File
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log 
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)
