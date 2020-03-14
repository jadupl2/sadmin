#! /usr/bin/env bash
# --------------------------------------------------------------------------------------------------
#   Author      :   Jacques Duplessis
#   Title       :   sadm_df.sh
#   Version     :   1.0
#   Date        :   05/05/2016
#   Requires    :   sh 
#   Description :   Display Disk Usage (df) with filesystem type, sorted by mount point.
#
#   Note        :   All scripts (Shell,Python,php) and screen output are formatted to have and use 
#                   a 100 characters per line. Comments in script always begin at column 73. You 
#                   will have a better experience, if you set screen width to have at least 100 Chr.
# 
# --------------------------------------------------------------------------------------------------
#
#   This code was originally written by Jacques Duplessis <jacques.duplessis@sadmin.ca>.
#   Developer Web Site : http://www.sadmin.ca
#
#   The SADMIN Tool is free software; you can redistribute it and/or modify it under the terms
#   of the GNU General Public License as published by the Free Software Foundation; either
#   version 2 of the License, or (at your option) any later version.
#
#   SADMIN Tools are distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
#   without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#   See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with this program.
#   If not, see <http://www.gnu.org/licenses/>.
# 
# --------------------------------------------------------------------------------------------------
# CHANGELOG
#
# 2016_05_05 v1.0 Initial Version
# 2018_06_04 v1.1 Include Filesystem Type, Sorted by Mount Point, Better, clearer Output.
# 2018_08_21 v1.2 Remove trailing space for data lines.
# 2018_08_21 v1.3 Adapted to work on MacOS and Aix
# 2018_09_03 v1.5 Option --total don't work on RHEL 5, Total Line Removed for now
# 2018_09_24 v1.6 Corrected Total Display Problem under Linux
# 2019_03_17 Update: v1.7 No background color change, using brighter color.
# 2019_06_30 Update: v1.8 Remove tmpfs from output on Linux (useless)
#@2020_03_12 Fix: v1.9 Correct problem under RHEL/CentOS older version (4,5,6).
#@2020_03_14 Update: v2.0 To increase portability, Column total are now calculated by script.
#@2020_03_15 Update: v2.1 Add -t to exclude tmpfs, -n nfs filesystem from the output and total line. 
# --------------------------------------------------------------------------------------------------
#set -x



#===================================================================================================
# Scripts Variables 
#===================================================================================================
export SADM_VER='2.1'                                                   # Current Script Version
export ostype=`uname -s | tr '[:lower:]' '[:upper:]'`                   # OS Name (AIX/LINUX/DARWIN)
export SADM_DASH=`printf %100s |tr " " "="`                             # 100 equals sign line
export SADM_DEBUG=0                                                     # 0=NoDebug Higher=+Verbose
export tmpfile="/tmp/sdf_tmp0.$$"                                       # Tmp File
export file="/tmp/sdf_tmp1.$$"                                          # File Contain Result of df
export data="/tmp/sdf_tmp2.$$"                                          # data (No Heading,no Total)
export SADM_PN=${0##*/}                                                 # Current Script name
export TMPFS=0                                                          # 1=Exclude tmpfs filesystem
export NFS=0                                                            # 1=Exclude nfs filesystem
export TOTAL_SIZE=0                                                     # df Size column total
export TOTAL_USED=0                                                     # df Used column total
export TOTAL_AVAIL=0                                                    # df Available column total

# Screen related variables
clreol=$(tput el)                               ; export clreol         # Clr to end of lne
clreos=$(tput ed)                               ; export clreos         # Clr to end of scr
bold=$(tput bold)                               ; export bold           # bold attribute
bell=$(tput bel)                                ; export bell           # Ring the bell
reverse=$(tput rev)                             ; export reverse        # rev. video attrib.
underline=$(tput sgr 0 1)                       ; export underline      # UnderLine
clr=$(tput clear)                               ; export clr            # clear the screen
blink=$(tput blink)                             ; export blink          # turn blinking on
reset=$(tput sgr0)                              ; export reset          # Screen Reset Attribute

# Foreground Color
black=$(tput setaf 0)                           ; export black          # Black color
red=$(tput setaf 1)                             ; export red            # Red color
green=$(tput setaf 2)                           ; export green          # Green color
yellow=$(tput setaf 3)                          ; export yellow         # Yellow color
blue=$(tput setaf 4)                            ; export blue           # Blue color
magenta=$(tput setaf 5)                         ; export magenta        # Magenta color
cyan=$(tput setaf 6)                            ; export cyan           # Cyan color
white=$(tput setaf 7)                           ; export white          # White color

# Background Color
bblack=$(tput setab 0)                          ; export bblack         # Black color
bred=$(tput setab 1)                            ; export bred           # Red color
bgreen=$(tput setab 2)                          ; export bgreen         # Green color
byellow=$(tput setab 3)                         ; export byellow        # Yellow color
bblue=$(tput setab 4)                           ; export bblue          # Blue color
bmagenta=$(tput setab 5)                        ; export bmagenta       # Magenta color
bcyan=$(tput setab 6)                           ; export bcyan          # Cyan color
bwhite=$(tput setab 7)                          ; export bwhite         # White color




# --------------------------------------------------------------------------------------------------
# Show Script command line option
# --------------------------------------------------------------------------------------------------
show_usage()
{
    printf "\n${SADM_PN} usage :"
    printf "\n\t-t   (Exclude tmpfs filesystem)"
    printf "\n\t-n   (Exclude nfs filesystem)"
    printf "\n\t-d   (Debug Level [0-9])"
    printf "\n\t-h   (Display this help message)"
    printf "\n\t-v   (Show Script Version Info)"
    printf "\n\n" 
}



# --------------------------------------------------------------------------------------------------
# Show Script Name, version, Library Version, O/S Name/Version and Kernel version.
# --------------------------------------------------------------------------------------------------
show_version()
{
    printf "\n${SADM_PN} - Version $SADM_VER"
    printf "\n$ostype - Kernel Version `uname -r`"
    printf "\n\n" 
}




# --------------------------------------------------------------------------------------------------
# Command line Options functions
# --------------------------------------------------------------------------------------------------
function cmd_options()
{
     local OPTIND # Must be local
    # Evaluate Command Line Switch Options Upfront
    # By Default (-h) Show Help Usage, (-v) Show Script Version,(-d0-9] Set Debug Level 
    while getopts "htnvd:" opt ; do                                      # Loop to process Switch
        case $opt in
            d) SADM_DEBUG=$OPTARG                                       # Get Debug Level Specified
               num=`echo "$SADM_DEBUG" | grep -E ^\-?[0-9]?\.?[0-9]+$`  # Valid is Level is Numeric
               if [ "$num" = "" ]                                       # No it's not numeric 
                  then printf "\nDebug Level specified is invalid.\n"   # Inform User Debug Invalid
                       show_usage                                       # Display Help Usage
                       exit 1                                           # Exit Script with Error
               fi
               printf "Debug Level set to ${SADM_DEBUG}."               # Display Debug Level
               ;;                                                       
            t) TMPFS=1                                                  # Exclude tmpfs filesystem
               ;;
            n) NFS=1                                                    # Exclude NFS filesystem
               ;;
            h) show_usage                                               # Show Help Usage
               exit 0                                                   # Back to shell
               ;;
            v) show_version                                             # Show Script Version Info
               exit 0                                                   # Back to shell
               ;;
           \?) printf "\nInvalid option: -$OPTARG"                      # Invalid Option Message
               show_usage                                               # Display Help Usage
               exit 1                                                   # Exit with Error
               ;;
        esac                                                            # End of case
    done                                                                # End of while
    return 
}


#===================================================================================================
# Script Start HERE
#===================================================================================================

    cmd_options "$@"                                                         # Set command-line Options

    # Run df command and output to file
    case "$ostype" in
        "DARWIN")   
            df -ha  |awk '{printf "%-35s %-8s %-8s %-8s %-8s %-8s %-s\n",$1,$2,$3,$4,$5,$6,$9'}>$tmpfile
            ;;
        "LINUX")    
            df -ThP |awk '{printf "%-35s %-8s %-8s %-8s %-8s %-8s %-s\n",$1,$2,$3,$4,$5,$6,$7'}>$tmpfile
            ;;
        "AIX")      
            df -g   |awk '{printf "%-35s %-8s %-8s %-8s %-8s %-8s %-s\n",$1,$2,$3,$4,$5,$6,$7}'>$tmpfile
            ;;
    esac
    if [ $TMPFS -eq 1 ] 
        then grep -Ev "^tmpfs|^devtmpfs" $tmpfile > $file
        else cp $tmpfile  $file
    fi
    if [ $NFS -eq 1 ] 
        then grep -Ev " nfs" $file > $tmpfile
             cp $tmpfile  $file
    fi

# Work on df result file - getting ready to output
lines=`wc -l $file | awk '{print $1}'`                                  # Total Lines in file
ntail=`expr $lines - 1`                                                 # Calc. tail Number to use
title=`head -1 $file`                                                   # Save 'df' Title Line
tail -${ntail} $file | sort -k7 > $data                                 # Sort by MntPoint 

while read wline                                                        # Read df Output line by line
    do
    size=` echo "$wline" | awk '{ print $3 }'`                          # Size of Filesystem
    used=` echo "$wline" | awk '{ print $4 }'`                          # Size Used
    avail=`echo "$wline" | awk '{ print $5 }'`                          # Size Available
    if [ $SADM_DEBUG -gt 4 ] ; then printf "\nSize: $size - Used: $used - Avail: $avail\n" ; fi

    # Is the Filesystem size in Gb, then convert to MB and add it to column total.
    Gpos=`expr index "$size" "G"`                                       # Search for 'G' in value
    if [ $SADM_DEBUG -gt 4 ] ; then echo "Position of 'G' in size is $Gpos" ; fi
    if [ "$Gpos" -ne 0 ]                                                # If 'G' was found 
        then Dpos=`expr index "$size" "."`                              # Search for Dot in Value
             WSIZE=`echo $size | tr -cd [:digit:]`                      # Del. Char other than digit
             if [ "$Dpos" -ne 0 ]                                       # If Size with fraction(Dot) 
                then TSIZE=`echo "($WSIZE * 1024) /10" | bc `           # Convert GB Size in MB
                else TSIZE=`echo "($WSIZE * 1024)" | bc `               # Convert GB Size in MB
             fi                 
        else TSIZE=`echo $size | tr -cd [:digit:]`                      # Save Value already in MB
    fi 
    TOTAL_SIZE=$(( $TOTAL_SIZE + $TSIZE ))                              # Add MB value to Col. Total
    if [ $SADM_DEBUG -gt 4 ]                                   
        then echo "Initial value is $size & final value is $TSIZE"
             echo "Total Size: $TOTAL_SIZE - Used: $TOTAL_USED - Avail: $TOTAL_AVAIL"
    fi 

    # Is the Used size in Gb, then convert to MB and add it to column total.
    Gpos=`expr index "$used" "G"`                                       # Search for 'G' in value
    if [ $SADM_DEBUG -gt 4 ] ; then echo "Position of 'G' in used value is $Gpos" ; fi
    if [ "$Gpos" -ne 0 ]                                                # If 'G' was found 
        then Dpos=`expr index "$used" "."`                              # Search for Dot in Value
             WSIZE=`echo $used | tr -cd [:digit:]`                      # Del. Char other than digit
             if [ "$Dpos" -ne 0 ]                                       # If Size with fraction(Dot) 
                then TSIZE=`echo "($WSIZE * 1024) /10" | bc `           # Convert GB Size in MB
                else TSIZE=`echo "($WSIZE * 1024)" | bc `               # Convert GB Size in MB
             fi                 
        else TSIZE=`echo $used | tr -cd [:digit:]`                      # Save Value already in MB
    fi 
    TOTAL_USED=$(( $TOTAL_USED + $TSIZE ))                              # Add MB value to Col. Total
    if [ $SADM_DEBUG -gt 4 ]                                   
        then echo "Initial used value is $used & final value is $TSIZE"
             echo "Total Size: $TOTAL_SIZE - Used: $TOTAL_USED - Avail: $TOTAL_AVAIL"
    fi

    # Is the Available size in Gb, then convert to MB and add it to column total.
    Gpos=`expr index "$avail" "G"`                                      # Search for 'G' in size
    if [ $SADM_DEBUG -gt 4 ] ; then echo "Position of 'G' in avail. size is $Gpos" ; fi
    if [ "$Gpos" -ne 0 ]                                                # If 'G' was found 
        then Dpos=`expr index "$avail" "."`                             # Search for Dot in Value
             WSIZE=`echo $avail | tr -cd [:digit:]`                     # Del. Char other than digit
             if [ "$Dpos" -ne 0 ]                                       # If Size with fraction(Dot) 
                then TSIZE=`echo "($WSIZE * 1024) /10" | bc `           # Convert GB Size in MB
                else TSIZE=`echo "($WSIZE * 1024)" | bc `               # Convert GB Size in MB
             fi                 
        else TSIZE=`echo $avail | tr -cd [:digit:]`                     # Save Value already in MB
    fi 
    TOTAL_AVAIL=$(( $TOTAL_AVAIL + $TSIZE ))                            # Add MB value to Col. Total
    if [ $SADM_DEBUG -gt 4 ]                                   
        then echo "Initial value is $avail & final value is $TSIZE"
             echo "Total Size: $TOTAL_SIZE - Used: $TOTAL_USED - Avail: $TOTAL_AVAIL"
    fi    
    done <$data


# Print DF Information
tput clear                                                              # Clear Screen
printf "${green}${bold}${SADM_PN} - v${SADM_VER}${reset}\n"             # Print Script Name & Ver.
printf "${magenta}${bold}${SADM_DASH}${reset}\n"                        # Print dash line
printf "${yellow}${bold}%s${reset}\n" "${title}"                        # Print title line
printf "${magenta}${bold}${SADM_DASH}${reset}\n"                        # Print dash line
cat ${data}                                                             # Output df sort by MntPoint
printf "${magenta}${bold}${SADM_DASH}${reset}\n"                        # Print dash line
TS=`echo "$TOTAL_SIZE  / 1024" | bc -l` ; TS=`printf "%6.2f" $TS`
TU=`echo "$TOTAL_USED  / 1024" | bc -l` ; TU=`printf "%5.2f" $TU`
TA=`echo "$TOTAL_AVAIL / 1024" | bc -l` ; TA=`printf "%5.2f" $TA`
PC=`echo "($TOTAL_USED / $TOTAL_SIZE) * 100" | bc -l` ; PC=`printf "%3.2f" $PC`
total_line=`printf "%-40s %8s %8s %8s %9s\n" "Total (-t exclude tmpfs, -n exclude nfs)" ${TS}G ${TU}G ${TA}G ${PC}%` 
printf "${yellow}${bold}%s${reset}\n" "$total_line"                     # Print total line
printf "${magenta}${bold}${SADM_DASH}${reset}\n"                        # Print dash line

# Remove work files
rm -f $file >/dev/null 2>&1                                             # Remove tmp full df file
rm -f $data >/dev/null 2>&1                                             # Remove tmp formated file
rm -f $tmpfile >/dev/null 2>&1                                          # Remove tmp file
