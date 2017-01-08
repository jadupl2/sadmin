#!/usr/bin/env bash
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
e_header()      { printf "\n${bold}${purple}==========  %s  ==========${reset}\n" "$@" 
}
e_arrow()       { printf "➜ $@\n"
}
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





#---------------------------------------------------------------------------------------------------
#   DISPLAY MESSAGE ON THE LINE AND POSITION RECEIVE AS PARAMETER (SADM_WRITEXY "MESSAGE" 12 50)
#---------------------------------------------------------------------------------------------------
sadm_writexy()
{
    
    tput cup `expr $1 - 1`  `expr $2 - 1`                               # tput command pos. cursor
    if [ "$(sadm_get_ostype)" = "AIX" ]                                    # In AIX just Echo Message
       then echo "$3\c"                                                 # Don't need the -e in AIX
       else echo -e "$3\c"                                              # -e enable interpretation
    fi
}




#---------------------------------------------------------------------------------------------------
#  ASK A QUESTION AT LINE AND POSITION SPECIFIED - RETURN 0 FOR NO AND RETURN 1 IF ANSWERED "YES"
#---------------------------------------------------------------------------------------------------
sadm_messok()
{
    wline=$1 ; wpos=$2 ; wmess="$3 [y,n] ? "                            # Line, Position and Mess. Rcv
    wreturn=0                                                           # Function Return Value Default
    sadm_writexy $1 $2 "                                                "
    while :
        do
        sadm_writexy $1 $2 "$wmess  ${right}${right}"                   # Write mess rcv + [ Y/N ] ?
        read answer                                                     # Read User answer
        case "$answer" in                                               # Test Answer
           Y|y ) wreturn=1                                              # Yes = Return Value of 1
                 break                                                  # Break of the loop
                 ;; 
           n|N ) wreturn=0                                              # Yes = Return Value of 0
                 break                                                  # Break of the loop
                 ;;
             * ) ;;                                                     # Other stay in the loop
         esac
    done
   return $wreturn                                                      # Return 0=No 1=Yes
}



#---------------------------------------------------------------------------------------------------
# DISPLAY MESSAGE RECEIVE IN BOLD (AND SOUND BELL) AT LINE 22 & WAIT FOR RETURN
#---------------------------------------------------------------------------------------------------
sadm_mess()
{
   sadm_writexy 22 01 "${clreos}${bold}${1}${reset}${bell}${bell}"      # Clr from lines 22 to EOS
   sadm_writexy 23 01 "Press [ENTER] to continue."                      # Ask user 2 press [RETURN]
   read sadm_dummy                                                      # Wait for  [RETURN]
   sadm_writexy 22 01 "${clreos}"                                       # Clear from lines 22 to EOS
}




#---------------------------------------------------------------------------------------------------
# DISPLAY MESSAGE ON LINE 22 WITH BELL SOUND
#---------------------------------------------------------------------------------------------------
sadm_display_message()
{
   sadm_writexy 22 01 "${clreos}"                                       # Clear from lines 22 to EOS
   sadm_writexy 22 01 "${bold}${1}${reset}${bell}"                      # Display Mess. on Line 22
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
    sadm_writexy 01 01  "${clr}${bold}${reverse}\c"                     # ClrScr_ Activate. Rev. Video
    sadm_writexy 01 01 "$eighty_spaces"                                 # Line 1 in Reverse Video
    sadm_writexy 02 01 "$eighty_spaces"                                 # Line 2 in Reverse Video
    sadm_writexy 21 01 "$eighty_spaces"                                 # Line 21 in Reverse Video

    # Display Line 1 (Date + Cie Name + Script Version
    sadm_writexy 01 01 "`date +%d/%m/%Y`"                               # Display Date Line 1 Pos.1 
    let wpos="((80 - ${#SADM_CIE_NAME}) / 2)"                           # Calc. Center Pos for Name
    sadm_writexy 01 $wpos "$SADM_CIE_NAME"                              # Display Cie Name Centered 
    let wpos="81 - ${#HOSTNAME}"                                        # Calc. Pos. Line 2 on Right
    sadm_writexy 01 "$wpos" "$(sadm_get_hostname)"                          # Display HostName 

    # Display Line 2 - (Host Name + OS Name and OS Version)
    sadm_writexy 02 01 "$(sadm_get_osname) $(sadm_get_osversion)"       # Display OSNAME + OS Ver.
    let wpos="((80 - ${#titre}) / 2)"                                   # Calc. Center Pos for Name
    sadm_writexy 02 $wpos "$titre"                                      # Display Title Centered
    let wpos="81 - ${#VER}"                                             # Calc. Pos. Line 2 on Right
    sadm_writexy 02 $wpos "$VER"                                        # Display Script Version

    sadm_writexy 04 01 "${reset}\c"                                     # Reset to Normal & Pos. Cur
}



#---------------------------------------------------------------------------------------------------
#                               ASK THE MANAGER PASSWORD
#---------------------------------------------------------------------------------------------------
sadm_ask_password()
{
    MPASSE=`date +%d%m%y`       ; MPASSE=`expr $MPASSE + 444 `
    MPASSE=`expr $MPASSE \* 2 `	    ; export MPASSE
    echo "`date +%d`+`date +%m`+`date +%y`" | bc > /tmp/SAMPAS$$ 
    MPASSE2=`cat /tmp/SAMPAS$$`         ; export MPASSE2
    rm /tmp/SAMPAS$$

    MPASSE=`date +%d%m%y` ; MPASSE=`echo "($MPASSE + 666) * 2" | bc `   # Construct Passwd
    sadm_writexy 22 01 "${clreos}${bell}${bell}"                        # Clear Line 22 + Ring Bell
    sadm_writexy 22 01 "Please enter the SADMIN password ...  ? "       # Inform user for Password
    stty -echo                                                          # Turn OFF Char. echo
    read REPONSE                                                        # Accept Password
    stty echo                                                           # Turn Back echo ON
    if [ "$REPONSE" != "$MPASSE" ]                                      # Validate Password
        then sadm_mess "Invalid password"                               # Advise User Wrong Password
             return 0                                                   # 0 = Wrong Password
        else return 1                                                   # 1 = Good Password
    fi
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
    s_count=0
    s_item_list=$*
    for s_item in $s_item_list ; do  s_count=$(($s_count+1)) ; s_array[$s_count]=$s_item ; done
#    sadm_writelog "Count is $s_count"
#    for (( c=1; c<=$s_count; c++ ))
#        do
#        sadm_writelog "[$c] ${s_array[$c]}"
#        done
#    exit


    # Validate number of item in array - Can be from 1 to 30 Maximum
    if [ "$s_count" -gt 30 ] && [ "$s_count" -lt 1 ]          # Validate NB items in array
        then sadm_mess "Number of items in array ("$s_count") is invalid"
             return 98                                                  # Set Error return code
    fi
    
    
    # If from 1 to 8 items to display in the menu
    adm_choice=0                                                        # Initial menu item to zero
    if [ "$s_count" -lt 8 ]                                             # If less than 9 items
        then for i in "${s_array[@]}"                                    # Loop through the array
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
     if [ "$s_count" -gt 7 ] && [ "$s_count" -lt 16 ]         # If from 8 to 15 Items
        then for i in "${s_array[@]}"                                    # Loop through the array
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
     if [ "$s_count" -gt 15 ] && [ "$s_count" -lt 31 ]        # If from 16 to 30 items
        then for i in "${s_array[@]}"                                    # Loop through the array
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
        if [ "$adm_choix" -lt 1 ] || [ "$adm_choix" -gt "$s_count" ] # If Invalid Choice Number 
           then sadm_mess "Choice is invalid"                           # Invalid Choice  Message
                continue                                                # Go Back to ReAccept Choice
           else break                                                   # Valid Choice Selected
        fi
        done
    return $adm_choix                                                   # Return Selected choice
}




#---------------------------------------------------------------------------------------------------
# Param #1 = Position the cursor on that line number
# Param #2 = Cursor position on the line
# Param #3 = Number of Character to accept
# Param #4 = Type of accept A=AlphaNumeric N=NUmeric
# Param #5 = Value of field just entered ("NULL"  = No Default)
#---------------------------------------------------------------------------------------------------
sadm_accept_data()
{
  while :
        do
        WBLANK="                              "
        WLINE=$1                                                        # Save Line to accept Data
        WCOL=$2                                                         # Save Column to accept data
        WLEN=$3                                                         # Max Nb Char. to Accept
        WTYPE=$4                                                        # AlphaNum = A, Numeric = N
        if [ "$WTYPE" != "N" ] ; then WTYPE="A" ; fi                    # Make sure we have A or N
        WDEFAULT=$5	                                                    # Default if press Enter
        WDATA=$WDEFAULT                                                 # Move Default to WDATA
        
        # Build and Display a Mask Indicating number of Char Allowed and Display Default Value
        a=1 ; WMASK="" ;                                                # Set Init. Val before loop
        while [ $a -le "$WLEN" ]                                        # Len of data reached ?
              do                                                        # Beginning of loop
              WMASK="${WMASK} "                                         # Add Space to Mask
              a=$(($a+1))                                               # Incr Counter by 1
              done                                                      # Next iteration
        if [ "$WDEFAULT" = "NULL" ] ; then WDEFAULT="" ; fi             # Default is Clear if NULL 
        sadm_writexy $WLINE $WCOL "${reverse}${WMASK}"                      # Display Mask in Rvs Video
        sadm_writexy $WLINE $WCOL "${WDEFAULT}${reset}"                   # Display Default Value

        # Accept the Data
        sadm_writexy $WLINE $WCOL ""                                    # Pos. Cursor Ready to Input
        #read -n${WLEN} WDATA
        read WDATA                                                      # Read DAta From Keyboard
        if [ "$WDATA" = "" ]    ; then WDATA="$WDEFAULT"  ; fi          # [ENTER] = Default Value
        if [ "$WDATA" = " " ]   ; then WDATA=""           ; fi          # [SPACE] = Clear Value
        if [ "$WDATA" = "-" ]   ; then WDATA=""           ; fi          # [-] = Clear Value
        if [ "$WDATA" = "del" ] ; then WDATA=""           ; fi          # [DEL] = Clear Value
        if [ "$WLEN" != "0" ]                                           # If Length > 0 
           then sadm_writexy $WLINE $WCOL "${WMASK}"                    # Re-Display Mask
                sadm_writexy $WLINE $WCOL "$WDATA"                      # Re-Display Value Entered
        fi

        # Test if length of data exceed what was requested
        if [ ${#WDATA} -gt ${WLEN} ]                                    # Data Entered Exceed Max.
           then mess "Maximum of ${WLEN} characters are accepted for this field"
                continue                                                # Restart Loop
        fi

        # If numeric was wanted - Test all char for numbers
        if [ "$WTYPE" = "N" ]                                           # If Numeric was choosen
           then echo $WDATA | grep [^0-9] > /dev/null 2>&1              # Grep for Number
                if [ "$?" -eq "0" ]
                   then mess "Sorry, wanted a number"                   # Error Msg on Line 22
                   else break                                           # Ok we are finish
                fi
           else break                                                   # If Alpha - were finish
        fi
        done
}



