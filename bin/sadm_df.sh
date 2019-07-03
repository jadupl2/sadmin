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
#@2019_06_30 Update: v1.8 Remove tmpfs from output on Linux (useless)
# --------------------------------------------------------------------------------------------------
#set -x



#===================================================================================================
# Scripts Variables 
#===================================================================================================
export SADM_VER='1.8'                                       # Current Script Version
SADM_DASH=`printf %100s |tr " " "="`                        # 100 equals sign line
DEBUG_LEVEL=0                                               # 0=NoDebug Higher=+Verbose
file="/tmp/sdf_tmp1.$$"                                     # File Contain Result of df
data="/tmp/sdf_tmp2.$$"                                     # Contain df data (No Heading, no Total)
export SADM_PN=${0##*/}                                     # Current Script name


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

#===================================================================================================
#                                       Script Start HERE
#===================================================================================================
    
ostype=`uname -s | tr '[:lower:]' '[:upper:]'`              # OS Name (AIX/LINUX/DARWIN/SUNOS)

# Run df command and output to file
    case "$ostype" in
        "DARWIN")   df -h > $file
                    ;;
        "LINUX")    df --total -hP | grep -v "^tmpfs"| awk '{printf "%-35s %-8s %-8s %-8s %-8s %-8s %-s\n",$1,$2,$3,$4,$5,$6,$7'}> $file
                    ;;
        "AIX")      df -g | awk '{ printf "%-30s %-8s %-8s %-8s %-8s %-8s %-28s\n", $1, $2, $3, $4, $5, $6, $7 }' > $file
                    ;;
    esac


# Work on df result file - getting ready to output
lines=`wc -l $file | awk '{print $1}'`                                  # Total Lines in file
ntail=`expr $lines - 1`                                                 # Calc. tail Number to use
nhead=`expr $ntail - 1`                                                 # Calc. head Number to use
title=`head -1 $file`                                                   # Save 'df' Title Line
#if [ "$ostype" = "DARWIN" ] || [ "$ostype" = "AIX" ] || [ "$ostype" = "LINUX" ]   # For Mac and Aix No Total
if [ "$ostype" = "DARWIN" ] || [ "$ostype" = "AIX" ]    # For Mac and Aix No Total

   then total=""                                                        # On Mac/Aix no Total Line
        tail -${ntail} $file  > $data                                   # Put DF minus Heading  
   else total=`tail -1 $file`                                           # Save 'df' Total Line
        tail -${ntail} $file | head -${nhead}|sort -k7 > $data          # Sort by MntPoint 
fi

# Print DF Information
tput clear                                                              # Clear Screen
printf "${green}${bold}${SADM_PN} - v${SADM_VER}${reset}\n"             # Print Script Name & Ver.
printf "${magenta}${bold}${SADM_DASH}${reset}\n"                        # Print dash line
printf "${yellow}${bold}%s${reset}\n" "${title}"                        # Print title line
printf "${magenta}${bold}${SADM_DASH}${reset}\n"                        # Print dash line
cat ${data}                                                             # Output df sort by MntPoint
printf "${magenta}${bold}${SADM_DASH}${reset}\n"                        # Print dash line
printf "${yellow}${bold}%s${reset}\n" "$total"                          # Print total line

# Remove work files
rm -f $file >/dev/null 2>&1                                             # Remove tmp full df file
rm -f $data >/dev/null 2>&1                                             # Remove tmp formated file

