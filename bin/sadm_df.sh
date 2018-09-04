#! /usr/bin/env sh
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
# 2016_05_05    v1.0 Initial Version
# 2018_06_04    v1.1 Include Filesystem Type, Sorted by Mount Point, Better, clearer Output.
# 2018_08_21    v1.2 Remove trailing space for data lines.
# 2018_08_21    v1.3 Adapted to work on MacOS and Aix
#@2018_09_03    v1.4 Option --total don't work on RHEL5, Total Line Removed for now
#
# --------------------------------------------------------------------------------------------------
#set -x



#===================================================================================================
# Scripts Variables 
#===================================================================================================
export SADM_VER='1.4'                                       # Current Script Version
SADM_DASH=`printf %100s |tr " " "="`                        # 100 equals sign line
DEBUG_LEVEL=0                                               # 0=NoDebug Higher=+Verbose
file="/tmp/sdf_tmp1.$$"                                     # File Contain Result of df
data="/tmp/sdf_tmp2.$$"                                     # Contain df data (No Heading, no Total)
export SADM_PN=${0##*/}                                     # Current Script name



#===================================================================================================
#                                       Script Start HERE
#===================================================================================================
    
ostype=`uname -s | tr '[:lower:]' '[:upper:]'`              # OS Name (AIX/LINUX/DARWIN/SUNOS)

# Run df command and output to file
    case "$ostype" in
        "DARWIN")   df -h > $file
                    ;;
        "LINUX")    df -ThP |awk '{printf "%-35s %-8s %-8s %-8s %-8s %-8s %-s\n",$1,$2,$3,$4,$5,$6,$7'}> $file
                    ;;
        "AIX")      df -g | awk '{ printf "%-30s %-8s %-8s %-8s %-8s %-8s %-28s\n", $1, $2, $3, $4, $5, $6, $7 }' > $file
                    ;;
    esac


# Work on df result file - getting ready to output
lines=`wc -l $file | awk '{print $1}'`                                  # Total Lines in file
ntail=`expr $lines - 1`                                                 # Calc. tail Number to use
nhead=`expr $ntail - 1`                                                 # Calc. head Number to use
title=`head -1 $file`                                                   # Save 'df' Title Line
if [ "$ostype" == "DARWIN" ] || [ "$ostype" == "AIX" ] || [ "$ostype" == "LINUX" ]   # For Mac and Aix No Total
   then total=""                                                        # On Mac/Aix no Total Line
        tail -${ntail} $file  > $data                                   # Put DF minus Heading  
   else total=`tail -1 $file`                                           # Save 'df' Total Line
        tail -${ntail} $file | head -${nhead}|sort -k7 > $data          # Sort by MntPoint 
fi

# Print DF Information
tput clear                                                              # Clear Screen
printf "${SADM_PN} - v${SADM_VER}\n"                                    # Print Script Name & Ver.
printf "${SADM_DASH}\n"                                                 # Print dash line
printf "%s\n" "$title"                                                  # Print title line
printf "${SADM_DASH}\n"                                                 # Print dash line
cat ${data}                                                             # Output df sort by MntPoint
printf "${SADM_DASH}\n"                                                 # Print dash line
printf "%s\n" "$total"                                                  # Print total line

# Remove work files
rm -f $file >/dev/null 2>&1                                             # Remove tmp full df file
rm -f $data >/dev/null 2>&1                                             # Remove tmp formated file

