#!/usr/bin/env bash
# --------------------------------------------------------------------------------------------------
#  Author:    Jacques Duplessis
#  Title      sadmlib_screen.sh
#  Date:      November 2015
#  Synopsis:  Screen Oriented functions - Library of screen related functions.
# --------------------------------------------------------------------------------------------------
# CHANGE LOG
# 2016_07_07    v1.0 Initial Version
# 2017_09_01    v1.1 Added Display of SADM Release Number on second line of menu
# 2017_10_09    v1.2 Change Menu Heading & Menu item display
# 2018_05_14    v1.3 Fix Display Problem under MacOS
# 2018_09_20    v1.4 Show SADM Version instead of Release No.
# 2019_02_25 Change: v1.5 Code revamp and new menu design.
# 2019_03_03 Change: v1.6 Added color possibilities and cursor control to library.
#@2019_03_17 Update: v1.7 Add time in menu heading.
#@2019_04_07 Update: v1.8 Use Color constant variable now available from standard SADMIN Shell Libr.
# --------------------------------------------------------------------------------------------------
#set -x
# 



# --------------------------------------------------------------------------------------------------
# L O C A L    V A R I A B L E S    
# --------------------------------------------------------------------------------------------------
#
lib_screen_ver=1.8                              ; export lib_screen_ver





#---------------------------------------------------------------------------------------------------
#   DISPLAY MESSAGE ON THE LINE AND POSITION RECEIVE AS PARAMETER (SADM_WRITEXY "MESSAGE" 12 50)
#---------------------------------------------------------------------------------------------------
sadm_writexy()
{

    tput cup `expr $1 - 1`  `expr $2 - 1`                               # tput command pos. cursor
    case "$(sadm_get_ostype)" in
        "LINUX")    echo -e "$3\c"                                      # -e enable interpretation  
                    ;;
        "AIX")      echo "$3\c"                                         # Don't need the in AIX
                    ;;      
        "DARWIN")   echo -e "$3\c"                                      # Neeed the -e on MacOS
                    ;;
        *)          echo "$3\c"       
    esac
}



#---------------------------------------------------------------------------------------------------
#  ASK A QUESTION AT LINE AND POSITION SPECIFIED - RETURN 0 FOR NO AND RETURN 1 IF ANSWERED "YES"
#---------------------------------------------------------------------------------------------------
sadm_messok() {
    wline=$1 ; wpos=$2                                                  # Line & Position of Message
    wmess="${SADM_BOLD}${SADM_WHITE}${3} ${SADM_GREEN}[${SADM_MAGENTA}y,n${SADM_GREEN}]${SADM_WHITE} ? ${SADM_RESET}" 
    wreturn=0                                                           # Function Return Value Default
    sadm_writexy $1 $2 "                                                "
    while :
        do
        sadm_writexy $1 $2 "$wmess  ${SADM_RIGHT}${SADM_RIGHT}"         # Write mess rcv + [ Y/N ] ?
        read answer                                                     # Read User answer
        case "$answer" in                                               # Test Answer
           Y|y ) wreturn=1                                              # Yes = Return Value of 1
                 break                                                  # Break of the loop
                 ;; 
           n|N ) wreturn=0                                              # No = Return Value of 0
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
sadm_mess() {
   sadm_writexy 22 01 "${SADM_CLREOS}${SADM_BOLD}${SADM_MAGENTA}${1}${SADM_RESET}${SADM_BELL}" 
   sadm_writexy 23 01 "${SADM_BOLD}${SADM_WHITE}Press [ENTER] to continue${SADM_RESET}"
   read sadm_dummy                                                      # Wait for  [RETURN]
   sadm_writexy 22 01 "${SADM_CLREOS}"                                  # Clear from lines 22 to EOS
}




#---------------------------------------------------------------------------------------------------
# DISPLAY MESSAGE ON LINE 22 WITH BELL SOUND
#---------------------------------------------------------------------------------------------------
sadm_display_message() {
   sadm_writexy 22 01 "${SADM_CLREOS}"                                       # Clear from lines 22 to EOS
   sadm_writexy 22 01 "${SADM_BOLD}${1}${SADM_RESET}${SADM_BELL}"                      # Display Mess. on Line 22
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

    # Clear screen and display line 21 in reverse video
    sadm_writexy 01 01  "${SADM_CLR}\c"                                 # ClrScr_ Activate. Rev. Video
    #sadm_writexy 21 01 "${bgreen}${SADM_RVS}${eighty_spaces}${SADM_RESET}" # Line 21 in Reverse Video
    #sadm_writexy 21 01 "${bgreen}${eighty_spaces}${SADM_RESET}"        # Line 21 in Reverse Video

    # Display Line 1 (Hostname + Menu Name + Date)
    sadm_writexy 01 01 "${SADM_BOLD}${SADM_GREEN}$(sadm_get_fqdn)"      # Top Left Show HostName 
    let wpos="((80 - ${#titre}) / 2)"                                   # Calc. Center Pos for Name
    sadm_writexy 01 $wpos "${SADM_MAGENTA}$titre"                       # Display Title Centered
    sadm_writexy 01 65 "${SADM_GREEN}`date '+%Y/%m/%d %H:%M'`"          # Top Right Show Current Date 

    # Display Line 2 - (OS Name and version + Cie Name and SADM Release No.
    sadm_writexy 02 01 "$(sadm_get_osname) $(sadm_get_osversion)"       # Display OSNAME + OS Ver.
    let wpos="((80 - ${#SADM_CIE_NAME}) / 2)"                           # Calc. Center Pos for Name
    sadm_writexy 02 $wpos "${SADM_CYAN}$SADM_CIE_NAME"                  # Display Cie Name Centered 
    let wpos="74 - ${#SADM_VERSION}"                                    # Calc. Pos. Line 2 on Right
    sadm_writexy 02 $wpos "${SADM_GREEN}Ver $SADM_VER"                  # Display Script Version
    sadm_writexy 04 01 "${SADM_RESET}\c"                                # Reset to Normal & Pos. Cur
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
    sadm_writexy 22 01 "${SADM_CLREOS}${SADM_BELL}${SADM_BELL}"         # Clear Line 22 + Ring Bell
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



#---------------------------------------------------------------------------------------------------
# Display Menu item 
# Parameter 1=LineNumber (1,24) 2=Column(1,80) 3=MenuItemNo 4=MenuItemDesc
#---------------------------------------------------------------------------------------------------
sadm_show_menuitem()
{
    mrow=$1                                                             # Line no. where to display
    mcol=$2                                                             # Column no. to display
    mno=$3                                                              # Item Menu Choice 
    mdesc=$4                                                            # Item Menu Description

    if [ -n "$mno" ] && [ "$mno" -eq "$mno" ] 2>/dev/null
        then menuno=`printf "${SADM_BOLD}${SADM_GREEN}[${SADM_CYAN}%02d${SADM_GREEN}]" "$mno"` # Numeric Menu No. [xx] 
        else menuno=`printf "${SADM_BOLD}${SADM_GREEN}[${SADM_CYAN}%s${SADM_GREEN}] " "$mno"`  # Alpha Menu No. [x]
    fi 
    witem=`printf "${SADM_BOLD}${SADM_MAGENTA}%-s${SADM_RESET}" "$mdesc"`             # Combine [xx] & Menu Desc
    sadm_writexy $mrow $mcol "${menuno} ${witem}"                       # Display Menu Item
}

#---------------------------------------------------------------------------------------------------
# Display Status Received in specific color depending of parameter received
# First Parameter received in placed between green bold bracket.
#   OK is show in green, ERROR is show in red, Warning is show in yellow, Other in magenta
# Second parameter received is placed right after showing the first, with a space between them.
#---------------------------------------------------------------------------------------------------
sadm_print_status()
{
    if [ $# -ne 2 ] 
        then if [ $# -eq 1 ] 
                then wmsg="" ; wst=$1
                else printf "sadm_print_status: Number of parameter received must be 1 or 2." 
             fi
        else wst=$1 wmsg=$2
    fi 

    case "$wst" in
        "ok"|"OK"|"Ok")    
            printf "${SADM_BOLD}${SADM_GREEN}[${SADM_CYAN}OK${SADM_GREEN}]${SADM_RESET} %s\n" "$wmsg"
            ;;
        "ERROR"|"Error"|"error")      
            printf "${SADM_BOLD}${SADM_GREEN}[${SADM_RED}ERROR${SADM_GREEN}]${SADM_RESET} %s\n" "$wmsg"
            ;;      
        "Warning"|"WARNING"|"warning")   
            printf "${SADM_BOLD}${SADM_GREEN}[${SADM_YELLOW}WARNING${SADM_GREEN}]${SADM_RESET} %s\n" "$mwsg"
            ;;
        *)  printf "${SADM_BOLD}${SADM_GREEN}[${SADM_MAGENTA}%s${SADM_GREEN}]${SADM_RESET} %s\n" "$wst" "$wmsg" 
            ;;
    esac    
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
    s_array=("$@")                                                      # Save Menu Array Received
    s_count=${#s_array[@]}                                              # Get Nb, of  items in Menu

    # Validate number of item in array - Can be from 1 to 30 Maximum
    if [ "$s_count" -gt 30 ] && [ "$s_count" -lt 1 ]                    # Validate NB items in array
        then sadm_mess "Number of items in array ("$s_count") is to high or too low."
             return 98                                                  # Set Error return code
    fi
    
    
    # If from 1 to 8 items to display in the menu
    adm_choice=0                                                        # Initial menu item to zero
    if [ "$s_count" -lt 8 ]                                             # If less than 9 items
        then for i in "${s_array[@]}"                                   # Loop through the array
                do                                                      # Start of loop
                let adm_choice="$adm_choice + 1"                        # Increment menu option no. 
                menu_item=$i
                for (( c=${#menu_item} ; c<32; c++ ))
                    do
                    menu_item="${menu_item}."
                    done
                let wline="2 + ($adm_choice * 2)"                       # Cacl. display Line Number
                sadm_show_menuitem $wline 22 "$adm_choice" "$menu_item"
                done                                                    # End of loop
            let adm_choice="$adm_choice + 1"                            # Increment menu option no. 
            let wline="2 + ($adm_choice * 2)"                           # Cacl. display Line Number
            menuno=`printf "${SADM_BOLD}${SADM_GREEN}[${SADM_CYAN}Q${SADM_GREEN}]"`
            menuitem=`printf "${SADM_BOLD}${SADM_MAGENTA}Quit............................${SADM_RESET}"`
            sadm_writexy $wline 22 "${menuno}  ${menuitem}" 
    fi
    
    # If from 8 to 15 items to display in the menu
     if [ "$s_count" -gt 7 ] && [ "$s_count" -lt 16 ]         # If from 8 to 15 Items
        then for i in "${s_array[@]}"                                   # Loop through the array
                do                                                      # Start of loop
                let adm_choice="$adm_choice + 1"                        # Increment menu option no.
                menu_item=$i
                for (( c=${#menu_item} ; c<32; c++ ))
                    do
                    menu_item="${menu_item}."
                    done    
                menuno=`printf "${SADM_BOLD}${SADM_GREEN}[${SADM_CYAN}%02d${SADM_GREEN}] " "$adm_choice"`
                witem=`printf "${SADM_BOLD}${SADM_MAGENTA}%-s${SADM_RESET}" "$menuno" "$menu_item"` 
                #witem=`printf "[%s%02d%s] %-s" $bold $adm_choice $reset "$menu_item"` # Menu No. & Desc
                let wline="3 + $adm_choice"                             # Cacl. display Line Number
                sadm_writexy $wline 22 "$witem"                         # Display Item on screen
                done                                                    # End of loop
            menuno=`printf "${SADM_BOLD}${SADM_GREEN}[${SADM_CYAN}Q${SADM_GREEN}]"`
            menuitem=`printf "${SADM_BOLD}${SADM_MAGENTA}Quit............................${SADM_RESET}"`
            sadm_writexy 19 22 "${menuno}  ${menuitem}" 
            #sadm_writexy 19 22 "[${SADM_BOLD}Q${SADM_RESET}]  Quit............................"
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
                menuno=`printf "${SADM_BOLD}${SADM_GREEN}[${SADM_CYAN}%02d${SADM_GREEN}] " "$adm_choice"`
                witem=`printf "${SADM_BOLD}${SADM_MAGENTA}%-s${SADM_RESET}" "$menuno" "$menu_item"` 
                #witem=`printf "[%s%02d%s] %-s" $bold $adm_choice $reset "$menu_item"` 
                let wline="3 + $adm_choice"                             # Cacl. display Line Number
                if [ "$adm_choice" -lt 16 ]                             # Item 1to15 on left column
                    then sadm_writexy $wline 02 "$witem"                # Display item on screen
                    else let wline="$wline - 15"                        # Item from 16to30 right col
                         sadm_writexy $wline 43 "$witem"                # Display item on screen
                fi                          
                done                                                    # End of loop
            menuno=`printf "${SADM_BOLD}${SADM_GREEN}[${SADM_CYAN}Q${SADM_GREEN}]"`
            menuitem=`printf "${SADM_BOLD}${SADM_MAGENTA}Quit............................${SADM_RESET}"`
            sadm_writexy 19 43 "${menuno}  ${menuitem}" 
            #sadm_writexy 19 43 "[${SADM_BOLD}Q${SADM_RESET}]  Quit............................"
    fi
    
    
    # Accept choice on line 21 - Validate it and set return code accordingly
    while :                                                             # Repeat Until good choice
        do                                                              # Begin of loop
        sadm_space_line=`printf %80s`                                   # 80 Spaces Line
        sadm_writexy 21 01 "${SADM_GREEN}${SADM_RVS}${sadm_space_line}\c" # Display Rev. Video Line
        sadm_writexy 21 29 "Option ? ${SADM_RESET}  ${SADM_RIGHT}"      # Display Option 
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
        sadm_writexy $WLINE $WCOL "${SADM_RVS}${WMASK}"                  # Display Mask in Rvs Video
        sadm_writexy $WLINE $WCOL "${WDEFAULT}${SADM_RESET}"                 # Display Default Value

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
           then mess "A maximum of ${WLEN} characters is accepted for this field"
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
