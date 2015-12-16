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
bold=`tput bold`                                ; export bold           # bold attribute
bel=`tput bel`                                  ; export bel            # Ring the bell
rvs=`tput rev`                                  ; export rvs            # rev. video attrib.
nrm=`tput sgr0`                                 ; export nrm            # normal attribute
unl=`tput smul`                                 ; export unl            # UnderLine
home=`tput home`                                ; export home           # home cursor
up=`tput cuu1`                                  ; export up             # cursor up
down=`tput cud1`                                ; export down           # cursor down
right=`tput cub1`                               ; export right          # cursor right
left=`tput cuf1`                                ; export left           # cursor left
clr=`tput clear`                                ; export clr            # clear the screen
blink=`tput blink`                              ; export blink          # turn blinking on
screen_color="\E[44;38m"                        ; export screen_color   # (BG Blue FG White)

#Set Colors
#

#bold=$(tput bold)
#underline=$(tput sgr 0 1)
#reset=$(tput sgr0)

#purple=$(tput setaf 171)
#red=$(tput setaf 1)
#green=$(tput setaf 76)
#tan=$(tput setaf 3)
#blue=$(tput setaf 38)

#
# Headers and  Logging
#

#e_header() { printf "\n${bold}${purple}==========  %s  ==========${reset}\n" "$@" 
#}
#e_arrow() { printf "➜ $@\n"
#}
#e_success() { printf "${green}✔ %s${reset}\n" "$@"
#}
#e_error() { printf "${red}✖ %s${reset}\n" "$@"
#}
#e_warning() { printf "${tan}➜ %s${reset}\n" "$@"
#}
#e_underline() { printf "${underline}${bold}%s${reset}\n" "$@"
#}
#e_bold() { printf "${bold}%s${reset}\n" "$@"
#}
#e_note() { printf "${underline}${bold}${blue}Note:${reset}  ${blue}%s${reset}\n" "$@"
#}





#---------------------------------------------------------------------------------------------------
#   DISPLAY MESSAGE ON THE LINE AND POSITION RECEIVE AS PARAMETER (SADM_WRITEXY "MESSAGE" 12 50)
#---------------------------------------------------------------------------------------------------
sadm_sadm_writexy()
{
    tput cup `expr $1 - 1`  `expr $2 - 1`                               # tput command pos. cursor
    if [ "$(sadm_os_type)" = "AIX" ]                                    # In AIX just Echo Message
       then echo "$3\c"                                                 # Don't need the -e in AIX
       else echo -e "$3\c"                                              # -e enable interpretation
    fi
}




#---------------------------------------------------------------------------------------------------
# ASK A QUESTION AT LINE AND POSITION SPECIFIED - RETURN 0 FOR NO AND RETURN 1 IF ANSWERED "YES"
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
             * ) ;;                                                     # Other options stay in the loop
      esac
    done
   return $wreturn                                                      # Return 0=No 1=Yes
}



#---------------------------------------------------------------------------------------------------
# DISPLAY MESSAGE RECEIVE IN BOLD (AND SOUND BELL) AT LINE 22 & WAIT FOR RETURN
#---------------------------------------------------------------------------------------------------
sadm_mess()
{
   sadm_writexy 22 01 "${clreos}${bold}${1}${nrm}${bel}${bel}"          # Clear from lines 22 to EOS
   sadm_writexy 23 01 "Press [ENTER] to continue."                      # Advise user to press [RETURN]
   read sadm_dummy                                                      # Wait for user 2 press [RETURN]
   sadm_writexy 22 01 "${clreos}"                                       # Clear from lines 22 to EOS
}




#---------------------------------------------------------------------------------------------------
# DISPLAY MESSAGE ON LINE 22 WITH BELL SOUND
#---------------------------------------------------------------------------------------------------
sadm_display_message()
{
   sadm_writexy 22 01 "${clreos}"                                       # Clear from lines 22 to EOS
   sadm_writexy 22 01 "${bold}${1}${nrm}${bel}"                         # Display Mess. on Line 22
}


#
#---------------------------------------------------------------------------------------------------
# CLEAR SCREEN AND DISPLAY THE 2 HEADING LINES OF SAM
#---------------------------------------------------------------------------------------------------
sadm_display_entete() 
{
    titre=`echo $1`                                                     # Menu Title
    eighty_spaces=`printf %80s " "`                                     # 80 white space

    # Calculate Version Position on the Heading line
    long=`echo $(sadm_os_type) | awk '{ printf "%d",length() }'`
    VERSION_POS=`expr 2 + $long `

    # Calculate HOSTNAME Position on the Heading line
    long=`echo $(sadm_hostname) | awk '{ printf "%d",length() }'`
    HOSTNAME_POS=`expr 81 - $long `

    # Display 3 lines in reverse video - On line 1, 2 and 21.
    echo -e "${clr}${bold}${rvs}\c"
    sadm_writexy 01 01 "$eighty_spaces"
    sadm_writexy 02 01 "$eighty_spaces"
    sadm_writexy 21 01 "$eighty_spaces"

    # Display Line 1 (Date + Cie Name +
    wpos=`expr 80 - ${#SADM_CIE_NAME}`                                      # 80 - lenght of title
    wpos=`expr $wpos / 2 `                                          # Divide result by 2 
    sadm_writexy 01 01 "`date +%d/%m/%Y`"                                 # Display Date Line 1 Pos.1 
    sadm_writexy 01 $wpos "$SADM_CIE_NAME"                                        # Display Title Calc Position 
    sadm_writexy 01 77 "$VER"

    # Display Line 2 - (Host Name + OS Name and OS Version)
    sadm_writexy 02 01 "$(sadm_os_type) Ver.$OSVERSION"
    sadm_writexy 02 "$HOSTNAME_POS" "$(sadm_hostname)"

# Display Titre du Menu
# Calculer la position pour centrer le titre sur la ligne de 80 colonnes
   long=`echo $1 | awk '{ printf "%d",length() }'`
   wpos=`expr 80 - $long `
   wpos=`expr $wpos / 2 `
   sadm_writexy 02 $wpos "$titre"

# Reset to normal mode
   echo -e "${nrm}\c"
   sadm_writexy 04 01 ""
}



#---------------------------------------------------------------------------------------------------
# ASK THE MANAGER PASSWORD
#---------------------------------------------------------------------------------------------------
sadm_ask_password()
{
    MPASSE=`date +%d%m%y` ; MPASSE=`echo "($MPASSE + 666) * 2" | bc `   # Construct Passwd
    sadm_writexy 22 01 "${clreos}${bel}${bel}"
    sadm_writexy 22 01 "Please enter the SADMIN password ...  ? "
    stty -echo
    read REPONSE
    stty echo
    if [ "$REPONSE" != "$MPASSE" ] && [ "$REPONSE" != "$MPASSE2" ]
        then sadm_mess "Invalid password"
             return 0
        else return 1
    fi
}



#---------------------------------------------------------------------------------------------------
# Param #1 = Position the cursor on that line number
# Param #2 = Cursor position on the line
# Param #3 = Number of Character to accept
# Param #4 = Type of accept A=AlphaNumeric N=NUmeric
# Param #5 = Value of field just entered
#---------------------------------------------------------------------------------------------------
sadm_accept_data()
{
  while :
        do
        WBLANK="                              "
        WLINE=$1			                # Line to accept Data
        WCOL=$2			                    # Column to accept data
        WLEN=$3			                    # Max Field Length
        WTYPE=$4                            # AlphaNum = A, Numeric = N
        if [ "$WTYPE" != "N" ] ; then WTYPE="A" ; fi
        WDEFAULT=$5			                # Default Value
        WDATA=$WDEFAULT
        a=1 ; WMASK="" ;
        while [ $a -le "$WLEN" ]
              do
              a=$(($a+1))
              WMASK="${WMASK} "
              done
        if [ "$WDEFAULT" = "NULL" ] ; then WDEFAULT="" ; fi
        if [ "$WCOL" != "" ]
           then sadm_writexy $WLINE $WCOL "${rvs}${WMASK}"
	        sadm_writexy $WLINE $WCOL "${WDEFAULT}${nrm}"
        fi

        # Accept the Data
        sadm_writexy $WLINE $WCOL ""
        #read -n${WLEN} WDATA
        read WDATA
        if [ "$WDATA" = "" ]    ; then WDATA="$WDEFAULT"  ; fi
        if [ "$WDATA" = " " ]   ; then WDATA=""           ; fi
        if [ "$WDATA" = "-" ]   ; then WDATA=""           ; fi
        if [ "$WDATA" = "del" ] ; then WDATA=""           ; fi
        if [ "$WLEN" != "0" ]
           then sadm_writexy $WLINE $WCOL "${WMASK}"
                sadm_writexy $WLINE $WCOL "$WDATA"
        fi

	    # Test if length of data excedd what was requested
        if [ ${#WDATA} -gt ${WLEN} ]
           then mess "Only ${WLEN} characters are accepted for this field"
                continue
        fi

        # If numeric was wanted - Test all char for numbers
        if [ "$WTYPE" = "N" ]
           then echo $WDATA | grep [^0-9] > /dev/null 2>&1
                if [ "$?" -eq "0" ]
                   then mess "Sorry, wanted a number"
                   else break
                fi
           else break
        fi

        done
}

