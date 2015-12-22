#!/usr/bin/env sh
# --------------------------------------------------------------------------------------------------
#  Author:    Jacques Duplessis
#  Title      sadm_lib_screen.sh
#  Date:      November 2015
#  Synopsis:  Screen Oriented functions - Library of screen related functions.
# --------------------------------------------------------------------------------------------------
#set -x


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
purple=$(tput setaf 171)                        ; export purple         # Purple color
red=$(tput setaf 1)                             ; export red            # Red color
green=$(tput setaf 76)                          ; export green          # Green color
tan=$(tput setaf 3)                             ; export tan            # Tan color
blue=$(tput setaf 38)                           ; export blue           # Blue color

#
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
EXIT_CODE=0                                    ; export EXIT_CODE       # Script Error Return Code
BASE_DIR=${SADMIN:="/sadmin"}                  ; export BASE_DIR        # Script Root Base Directory
#
[ -f ${BASE_DIR}/lib/sadm_lib_std.sh ]    && . ${BASE_DIR}/lib/sadm_lib_std.sh     # sadm std Lib
[ -f ${BASE_DIR}/lib/sadm_lib_server.sh ] && . ${BASE_DIR}/lib/sadm_lib_server.sh  # sadm server lib
[ -f ${BASE_DIR}/lib/sadm_lib_screen.sh ] && . ${BASE_DIR}/lib/sadm_lib_screen.sh  # sadm screen lib
#
# VARIABLES THAT CAN BE CHANGED PER SCRIPT -(SOME ARE CONFIGURABLE IS $BASE_DIR/cfg/sadmin.cfg)
#ADM_MAIL_ADDR="root@localhost"                 ; export ADM_MAIL_ADDR  # Default is in sadmin.cfg
SADM_MAIL_TYPE=1                               ; export SADM_MAIL_TYPE  # 0=No 1=Err 2=Succes 3=All
MAX_LOGLINE=5000                               ; export MAX_LOGLINE     # Max Nb. Lines in LOG )
MAX_RCLINE=100                                 ; export MAX_RCLINE      # Max Nb. Lines in RCH LOG
#***************************************************************************************************
#
sadm_writexy()
{
    tput cup `expr $1 - 1`  `expr $2 - 1`                               # tput command pos. cursor
    if [ "$(sadm_os_type)" = "AIX" ]                                    # In AIX just Echo Message
       then echo "$3\c"                                                 # Don't need the -e in AIX
       else echo -e "$3\c"                                              # -e enable interpretation
    fi
}

#
#---------------------------------------------------------------------------------------------------
#            CLEAR SCREEN AND DISPLAY THE 2 HEADING LINES & Bottom line in Reverse Video
#---------------------------------------------------------------------------------------------------
#    ON THE FIRST LINE THERE IS  : DATE + CIE NAME (TAKEN FROM SADMIN CONFIG FILE) + HOST NAME
#   ON THE SECOND LINE THERE IS : O.S NAME & VERSION + MENU TITLE (RCV BY FUNCTION) + SCRIPT VER.
#---------------------------------------------------------------------------------------------------
sadm_display_heading() 
{
    titre=`echo $1`                                                     # Save Menu Title
    eighty_spaces=`printf %80s " "`                                     # 80 white space

    # Display 3 lines in reverse video - On line 1, 2 and 21.
    sadm_writexy 01 01  "${clr}${blue}${bold}${reverse}\c"                     # ClrScr_ Activate. Rev. Video
    sadm_writexy 01 01 "$eighty_spaces"                                 # Line 1 in Reverse Video
    sadm_writexy 02 01 "$eighty_spaces"                                 # Line 2 in Reverse Video
    sadm_writexy 21 01 "$eighty_spaces"                                 # Line 21 in Reverse Video

    # Display Line 1 (Date + Cie Name + Script Version
    sadm_writexy 01 01 "`date +%d/%m/%Y`"                               # Display Date Line 1 Pos.1 
    let wpos="((80 - ${#SADM_CIE_NAME}) / 2)"                           # Calc. Center Pos for Name
    sadm_writexy 01 $wpos "$SADM_CIE_NAME"                              # Display Cie Name Centered 
    let wpos="81 - ${#HOSTNAME}"                                        # Calc. Pos. Line 2 on Right
    sadm_writexy 01 "$wpos" "$(sadm_hostname)"                          # Display HostName 

    # Display Line 2 - (Host Name + OS Name and OS Version)
    sadm_writexy 02 01 "$(sadm_os_name) $(sadm_os_version)"             # Display OSNAME + OS Ver.
    let wpos="((80 - ${#titre}) / 2)"                                   # Calc. Center Pos for Name
    sadm_writexy 02 $wpos "$titre"                                      # Display Title Centered
    let wpos="81 - ${#VER}"                                             # Calc. Pos. Line 2 on Right
    sadm_writexy 02 $wpos "$VER"                                        # Display Script Version

    sadm_writexy 04 01 "${reset}\c"                                       # Reset to Normal & Pos. Cur
}


#
#---------------------------------------------------------------------------------------------------
#   this function display the array of menu item in one or two columns depending on the size
#   of array received and accept the choice number selected (or Q|q to Quit).
#---------------------------------------------------------------------------------------------------
#  - function return the item number selected (between 1 and the number of item in array) Max 30
#  - function return 98 if the number of item in the menu array is less than one or greater than 30
#  - function return 99 if the choice selected was [Q|q]uit.
#---------------------------------------------------------------------------------------------------
#   Example
#        sadm_display_heading "Filesystem Menu"             # Display the menu Heading
#        menu_array=("Create a filesystem" \                # Put Items 1 in menu array
#                    "Increase a filesystem" \              # Put Items 1 in menu array
#                    "Delete a filesystem" \                # Put Items 1 in menu array
#                    "Check a filesystem" )                 # Put Items 1 in menu array
#        sadm_display_menu "${menu_array[@]}"               # Display menu items & Accept Choice
#---------------------------------------------------------------------------------------------------
sadm_display_menu() 
{
    marray=( "$@" )                                                     # Save Array of menu recv.

    # Validate number of item in array - Can be from 1 to 30 Maximum
    if [ "${#marray[@]}" -gt 30 ] && [ "${#marray[@]}" -lt 1 ]          # Validate NB items in array
        then sadm_mess "Number of items in array ("${#marray[@]}") is invalid"
             return 98                                                  # Set Error return code
    fi
    adm_choice=0                                                        # Initial menu item to zero
    
    
    # If from 1 to 8 items to display in the menu
    if [ "${#marray[@]}" -lt 8 ]                                        # If less than 9 items
        then for i in "${marray[@]}"                                    # Loop through the array
                do                                                      # Start of loop
                let adm_choice="$adm_choice + 1"                        # Increment menu option no. 
                menu_item=$i
                for (( c=${#menu_item} ; c<32; c++ ))
                    do
                    menu_item="${menu_item}."
                    done
                witem=`printf "[%s%02d%s] %-s" $bold $adm_choice $reset "$menu_item"` 
                let wline="2 + ($adm_choice * 2)"                       # Cacl. display Line Number
                sadm_writexy $wline 22 "$witem"                         # Display Item on screen
                done                                                    # End of loop
            let adm_choice="$adm_choice + 1"                            # Increment menu option no. 
            let wline="2 + ($adm_choice * 2)"                           # Cacl. display Line Number
            sadm_writexy $wline 22 "[${bold}Q${reset}]  Quit"           # Last Item always Quit item
    fi
    
    # If from 8 to 15 items to display in the menu
     if [ "${#marray[@]}" -gt 7 ] && [ "${#marray[@]}" -lt 16 ]         # If from 8 to 15 Items
        then for i in "${marray[@]}"                                    # Loop through the array
                do                                                      # Start of loop
                let adm_choice="$adm_choice + 1"                        # Increment menu option no.
                menu_item=$i
                for (( c=${#menu_item} ; c<32; c++ ))
                    do
                    menu_item="${menu_item}."
                    done    
                witem=`printf "[%s%02d%s] %-s" $bold $adm_choice $reset "$menu_item"` # Menu No. & Desc
                let wline="3 + $adm_choice"                             # Cacl. display Line Number
                sadm_writexy $wline 22 "$witem"                         # Display Item on screen
                done                                                    # End of loop
            sadm_writexy 19 22 "[${bold}Q${reset}]  Quit"               # Last Item always Quit item
    fi

    # If from 16 to 30 items to display in the menu
     if [ "${#marray[@]}" -gt 15 ] && [ "${#marray[@]}" -lt 31 ]        # If from 16 to 30 items
        then for i in "${marray[@]}"                                    # Loop through the array
                do                                                      # Start of loop
                let adm_choice="$adm_choice + 1"                        # Increment menu option no. 
                menu_item=$i
                for (( c=${#menu_item} ; c<32; c++ ))
                    do
                    menu_item="${menu_item}."
                    done
                witem=`printf "[%s%02d%s] %-s" $bold $adm_choice $reset "$menu_item"` 
                let wline="3 + $adm_choice"                             # Cacl. display Line Number
                if [ "$adm_choice" -lt 16 ]                             # Item 1to15 on left column
                    then sadm_writexy $wline 02 "$witem"                # Display item on screen
                    else let wline="$wline - 15"                        # Item from 16to30 right col
                         sadm_writexy $wline 43 "$witem"                # Display item on screen
                fi                          
                done                                                    # End of loop
            sadm_writexy 19 43 "[${bold}Q${reset}]  Quit"               # Last Item always Quit item
    fi
    
    
    # Accept choice on line 21 - Validate it and set return code accordingly
    while :                                                             # Repeat Until good choice
        do                                                              # Begin of loop
        sadm_space_line=`printf %80s`                                   # 80 Spaces Line
        sadm_writexy 21 01 "${bold}${reverse}${sadm_space_line}\c"      # Display Rev. Video Line
        sadm_writexy 21 29 "Option ? ${reset}  ${right}"                # Display Option 
        sadm_writexy 21 38 " "                                          # Position to accept Choice
        read adm_choix                                                  # Accept User Choice
        if [ "$adm_choix" = "" ] ; then continue ; fi                   # [ENTER] Only = Re-Accept
        if [ "$adm_choix" = "q" ] || [ "$adm_choix" = "Q" ]             # If Quit is selected
            then adm_choix=99 ; break  ; fi                             # Quit = Return code of 99
        echo "$adm_choix" | grep [^0-9] >/dev/null 2>&1                 # Grep for Number
        if [ $? -eq 0 ]                                                 # If not only number
           then sadm_mess "Sorry, wanted a number"                      # Error Msg on Line 22
                continue                                                # Go Re-Accept choice
        fi
        if [ "$adm_choix" -lt 1 ] || [ "$adm_choix" -gt "${#marray[@]}" ] # If Invalid Choice Number 
           then sadm_mess "Choice is invalid"                           # Invalid Choice  Message
                continue                                                # Go Back to ReAccept Choice
           else break                                                   # Valid Choice Selected
        fi
        done
    return $adm_choix                                                   # Return Selected choice
}

sadm_display_heading "Filesystem Menu"
menu_array=("Menu Item 1" \
            "Menu Item 2" \
            "Delete a filesystem3" \
            "Delete a filesystem3" \
            "Delete a filesystem4" \
            "Delete a filesystem5" \
            "Delete a filesystem6" \
            "Check a filesystem7" )
sadm_display_menu "${menu_array[@]}"
sadm_logger "CHOICE SELECTED IS $?" ; read dummy

sadm_display_heading "Menu 2"
menu_array=("Filesystem Jacques1"  \
            "Filesystem Jacques2"  \
            "Filesystem Jacques3"  \
            "Filesystem Jacques4"  \
            "Filesystem Jacques5"  \
            "Filesystem Jacques6"  \
            "Filesystem Jacques7"  \
            "Filesystem Jacques8"  \
            "Filesystem Jacques9"  \
            "Filesystem Jacques10" \
            "Filesystem Jacques11" \
            "Filesystem Jacques12" \
            "Filesystem Jacques13" \
            "Filesystem Jacques14" \
            "Filesystem Jacques15" )
sadm_display_menu "${menu_array[@]}"
sadm_logger "CHOICE SELECTED IS $?" ; read dummy

sadm_display_heading "Menu 3"
menu_array=("Filesystem Jacques1"  \
            "Filesystem Jacques2"  \
            "Filesystem Jacques3"  \
            "Filesystem Jacques4"  \
            "Filesystem Jacques5"  \
            "Filesystem Jacques6"  \
            "Filesystem Jacques7"  \
            "Filesystem Jacques8"  \
            "Filesystem Jacques9"  \
            "Filesystem Jacques10" \
            "Filesystem Jacques11" \
            "Filesystem Jacques12" \
            "Filesystem Jacques13" \
            "Filesystem Jacques14" \
            "Filesystem Jacques15" \
            "Filesystem Jacques16" \
            "Filesystem Jacques17" \
            "Filesystem Jacques18" \
            "Filesystem Jacques19" \
            "Filesystem Jacques20" \
            "Filesystem Jacques21" \
            "Filesystem Jacques22" \
            "Filesystem Jacques23" \
            "Filesystem Jacques24" \
            "Filesystem Jacques25" \
            "Filesystem Jacques26" \
            "Filesystem Jacques27" \
            "Filesystem Jacques28" \
            "Filesystem Jacques29" \
            "Filesystem Jacques30" )
sadm_display_menu "${menu_array[@]}"
sadm_logger "CHOICE SELECTED IS $?" ; read dummy


