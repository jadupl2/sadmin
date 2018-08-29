#! /usr/bin/env sh
# --------------------------------------------------------------------------------------------------
#   Author      :   Jacques Duplessis
#   Title       :   sadm_fs_incr.sh [filesystem-to-increase]
#   Synopsis    :   Script designed to be called by SADM SYStem MONitor (sadm_sysmon.pl) to 
#                   automatically increase filesystem.
#                   When filesystem usage reach a level that is greater than the warning threshold 
#                   defined in SysMon configuration file (`hostname`.smon) a filesystem increase
#                   is trigger. 
#                   The filesystem increase, will occurs only if these conditions are met :
#                       1)  The name of this script 'sadm_fs_incr' must appears at the end of the 
#                           line of the chosen filesystem in `hostname`.smon file.
#                       2)  Filesystem will be increase by 10% each time they are increase.
#                       3)  No more than 2 filesystems increase will occurs in 24hours.
#                       4)  The script 'sadm_fs_incr.sh' must be present and executable in 
#                           directory "$SADMIN/bin".
#   Version     :   1.0
#   Date        :   15 May 2018
#   Requires    :   sh, lvm package and SADMIN Filesystem Library
#   This code was originally written by Jacques Duplessis,
#   Copyright (C) 2016-2018 Jacques Duplessis <jacques.duplessis@sadmin.ca> - http://www.sadmin.ca
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
# 
# --------------------------------------------------------------------------------------------------
# CHANGELOG
# 2018_05_15    V1.0 Initial Version
# 2018_05_18    V1.1 Working Initial Version
#@2018_08_19    V1.2 Change Filesystem Increase before and after Email information.
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPT The Control-C
#set -x

#
#===========  S A D M I N    T O O L S    E N V I R O N M E N T   D E C L A R A T I O N  ===========
# If You want to use the SADMIN Libraries, you need to add this section at the top of your script
# You can run $SADMIN/lib/sadmlib_test.sh for viewing functions and informations avail. to you.
# --------------------------------------------------------------------------------------------------
if [ -z "$SADMIN" ] ;then echo "Please assign SADMIN Env. Variable to install directory" ;exit 1 ;fi
if [ ! -r "$SADMIN/lib/sadmlib_std.sh" ] ;then echo "SADMIN Library can't be located"   ;exit 1 ;fi
#
# YOU CAN CHANGE THESE VARIABLES - They Influence the execution of functions in SADMIN Library
SADM_VER='1.2'                             ; export SADM_VER            # Your Script Version
SADM_LOG_TYPE="B"                          ; export SADM_LOG_TYPE       # S=Screen L=LogFile B=Both
SADM_LOG_APPEND="N"                        ; export SADM_LOG_APPEND     # Append to Existing Log ?
SADM_LOG_HEADER="Y"                        ; export SADM_LOG_HEADER     # Show/Generate Log Header
SADM_LOG_FOOTER="Y"                        ; export SADM_LOG_FOOTER     # Show/Generate Log Footer
SADM_MULTIPLE_EXEC="N"                     ; export SADM_MULTIPLE_EXEC  # Run many copy at same time
SADM_USE_RCH="Y"                           ; export SADM_USE_RCH        # Update Return Code History
#
# DON'T CHANGE THESE VARIABLES - Need to be defined prior to loading the SADMIN Library
SADM_PN=${0##*/}                           ; export SADM_PN             # Script name
SADM_HOSTNAME=`hostname -s`                ; export SADM_HOSTNAME       # Current Host name
SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1` ; export SADM_INST           # Script name without ext.
SADM_TPID="$$"                             ; export SADM_TPID           # Script PID
SADM_EXIT_CODE=0                           ; export SADM_EXIT_CODE      # Script Exit Return Code
SADM_BASE_DIR=${SADMIN:="/sadmin"}         ; export SADM_BASE_DIR       # SADMIN Root Base Dir.
#
[ -f ${SADMIN}/lib/sadmlib_std.sh ]  && . ${SADMIN}/lib/sadmlib_std.sh  # Load SADMIN Std Library
#
# The Default Value for these Variables are defined in $SADMIN/cfg/sadmin.cfg file
# But some can overriden here on a per script basis
# --------------------------------------------------------------------------------------------------
# An email can be sent at the end of the script depending on the ending status 
# 0=No Email, 1=Email when finish with error, 2=Email when script finish with Success, 3=Allways
SADM_MAIL_TYPE=1                           ; export SADM_MAIL_TYPE      # 0=No 1=OnErr 2=OnOK  3=All
#SADM_MAIL_ADDR="your_email@domain.com"    ; export SADM_MAIL_ADDR      # Email to send log
#===================================================================================================
#

# Load Filesystem Tool SADM Library
[ -f ${SADMIN}/lib/sadmlib_fs.sh ]  && . ${SADMIN}/lib/sadmlib_fs.sh    # Load FS SADMIN Library


#===================================================================================================
#                               Script environment variables
#===================================================================================================
DEBUG_LEVEL=0                                   ; export DEBUG_LEVEL    # 0=NoDebug Higher=+Verbose
MAIL_BODY="${SADM_TMP_DIR}/MAILBODY_$$.txt"     ; export MAIL_BODY      # Email data file
DASH=`printf %50s |tr " " "="`                  ; export DASH           # 50 equals sign line
VGLIST="${SADM_TMP_DIR}/vglist.$$"              ; export VGLIST         # Contain list of VG 
INCR_PCT=1.10                                   ; export INCR_PCT       # Pct.  Filesystem Increase
VGMIN_PCT=10                                    ; export VGMIN_PCT      # Min PCT free in VG to Incr
VGMIN_MB=10240                                  ; export VGMIN_MB       # Min Free Space need in VG
FSTAB='/etc/fstab'                              ; export FSTAB          # Filesystem Table file

# Filesystem MetaData
LVNAME=""                                       ; export LVNAME         # LV Name
LVSIZE=""                                       ; export LVSIZE         # LV Size
SIZE2ADD=""                                     ; export SIZE2ADD       # MB 2 add to Filesystem
VGNAME=""                                       ; export VGNAME         # VG Name
VGSIZE=""                                       ; export VGSIZE         # VG Size in GB
VGFREE=""                                       ; export VGFREE         # VG Free Space in GB
LVTYPE=""                                       ; export LVTYPE         # LV type ext3,etx4,xfs,swap
LVMOUNT=""                                      ; export LVMOUNT        # LV Mount point
LVOWNER=""                                      ; export LVOWNER        # LV Mount point owner
LVGROUP=""                                      ; export LVGROUP        # LV Mount point group
LVPROT=""                                       ; export LVPROT         # LV Mount point protection





#===================================================================================================
# Function called to Expand a filesystem
#===================================================================================================
extend_fs()
{
    # Extend the logical volume
    if [ "$LVEXTEND" = "" ] 
       then sadm_writelog "Command 'lvextend' is not present of this host"  # Show User Error
            sadm_writelog "Filesystem can't be enlarge"                 # Show User we are aborting
            return 1
    fi
    sadm_writelog "$LVEXTEND -L+${SIZE2ADD} /dev/$VGNAME/$LVNAME"       # Show User Command to Exec.
    $LVEXTEND -L+${SIZE2ADD} /dev/$VGNAME/$LVNAME                       # Execute lvextend command
    ERRCODE="$?"                                                        # Save Return Code
    if [ "$ERRCODE" -ne 0 ]                                             # If Error on lvextend
        then sadm_writelog "Error on lvextend /dev/$VGNAME/$LVNAME"     # Signal Error to User
             return 1                                                   # Return Error to Caller
    fi
    sadm_writelog ""                                                    # Blank Line

    # Resize EXT3 and EXT4 Filesystem 
    if [ "$LVTYPE" = "ext3" ] || [ "$LVTYPE" = "ext4" ]                 # Ext3,Ext4 Resize FS 
        then if [ "$RESIZE2FS" = "" ]                                   # If resize2fs not present 
                then sadm_writelog "Command 'resize2fs' isn't present"  # Show User Error
                     sadm_writelog "Filesystem can't be enlarge"        # We are aborting
                     return 1                                           # Return Error to caller
                else sadm_writelog "$RESIZE2FS /dev/$VGNAME/$LVNAME"    # Show command executing
                     $RESIZE2FS  /dev/$VGNAME/$LVNAME                   # Resize the filesystem
                     if [ $? -ne 0 ]                                    # If Error occured
                        then sadm_writelog "Error on resize2fs /dev/$VGNAME/$LVNAME" # Advise User
                             return 1                                   # Return Error to Caller
                        else sadm_writelog "Filesystem increased ..."   # Show USer increase is OK
                             return 0                                   # Return Success to caller
                     fi 
             fi
    fi

    # Resize XFS Filesystem 
    if [ "$LVTYPE" = "xfs" ]                                            # XFS Resize Filesystem 
        then if [ "$XFS_GROWFS" = "" ]                                  # If xfs_growfs not present 
                then sadm_writelog "Command 'xfs_growfs' isn't present" # Show User Error
                     sadm_writelog "Filesystem can't be enlarge"        # We are aborting
                     return 1                                           # Return Error to caller
                else sadm_writelog "$XFS_GROWFS ${LVMOUNT}"             # Show Command about to Exec
                     $XFS_GROWFS ${LVMOUNT}                             # Increase FileSystem
                     if [ $? -ne 0 ]                                    # If Error Occured
                        then sadm_writelog "Error with $XFS_GROWFS ${LVMOUNT}"  # Advise User of Error
                             return 1                                   # Return Error to Caller
                        else return 0                                   # Return Success to caller
                     fi 
             fi
    fi
    return 0
}





#===================================================================================================
# Function to send email to sadmin administrator 
#===================================================================================================
send_email() 
{
    WSUBJECT=$1                                                         # Received Email Subject

    # Current Directory Size and Usage
    echo -e "\n${DASH}" >>$MAIL_BODY                                    # Print Dash Line
    #echo -e "Current ${FSNAME} Filesystem size and usage" >>$MAIL_BODY  # Title for Filesystem Usage
    echo -e "`date`\nFilesystem $FSNAME actual size.\n\n`df -hP $FSNAME` \n" >> $MAIL_BODY
    #df -hP ${FSNAME} >> $MAIL_BODY                                      # Print FileSystem Usage

    # Print 20 biggest directory of filesystem
    echo -e "\n${DASH}"  >>$MAIL_BODY                                   # Print Dash Line
    echo -e "Biggest directories of ${FSNAME}" >> $MAIL_BODY            # Title Biggest Dir. in FS
    du -kx $FSNAME | sort -rn | head -20 | nl >> $MAIL_BODY             # 20 Biggest Dir. in FS

    # Print 20 biggest file
    echo -e "\n${DASH}"  >>$MAIL_BODY                                   # Print Dash Line
    echo -e "Biggest files of ${FSNAME}" >> $MAIL_BODY                  # Title Biggest File in FS
    find $FSNAME -type f -printf '%s %p\n'|sort -nr|head -20 | nl >>$MAIL_BODY  # 20 Biggest files

    # Send email
    cat $MAIL_BODY | mail -s "$WSUBJECT" "${SADM_MAIL_ADDR}"            # Send Administrator Email
    rm -f $MAIL_BODY > /dev/null 2>&1                                   # Remove the Body Text File
}



#===================================================================================================
#                             S c r i p t    M a i n     P r o c e s s
#===================================================================================================
main_process()
{
    sadm_writelog "Filesystem Increase Process as started ... "

    # Check if filesystem (mount point) to increase exist in /etc/fstab
    if ! mntexist $FSNAME                                               # Mount Point don't exist ?
        then sadm_writelog "Filesystem $FSNAME doesn't exist"           # Show Error to user
             return 1                                                   # Return Error to caller
    fi

    # Get filesystem metadata
    get_mntdata $FSNAME                                                 # Get Filesystem Metadata

    # Display Metadata Received for debugging
    sadm_writelog "Logical Volume Name ..........: ...$LVNAME..."
    sadm_writelog "Volume Group .................: ...$VGNAME..."
    sadm_writelog "Filesystem Type ..............: ...$LVTYPE..."
    sadm_writelog "Filesystem Size in MB ........: ...$LVSIZE..."
    sadm_writelog "Filesystem Owner .............: ...$LVOWNER..."
    sadm_writelog "Filesystem Group .............: ...$LVGROUP..."
    sadm_writelog "Filesystem Protection ........: ...$LVPROT..."
    sadm_writelog "Filesystem Increase Pct.......: ...$INCR_PCT..."

    # Check if Filesystem Type is Supported
    if [ "$LVTYPE" != "ext3" ] && [ "$LVTYPE" != "ext4" ] && [ "$LVTYPE" != "xfs" ] 
        then WMESS="Filesystem Type (${LVTYPE}) isn't supported - Process aborted"
             sadm_writelog ""                                           # Blank Line
             sadm_writelog "$WMESS"                                     # Show User Error Mess.
             sadm_writelog "Sending Email and exit"                     # Inform User
             send_email "$WMESS"                                        # Send Email & Go Abort
             return 1                                                   # Return Error to Caller
    fi                         

    # Calculate new Filesystem Size
    OLDSIZE=$LVSIZE                                                     # Save Cur. LV Size
    NEW_LVSIZE=`echo "$LVSIZE * $INCR_PCT" |bc |awk -F \. '{print $1}'` # New Size= Cur.Size * 1.10
    sadm_writelog ""                                                    # Blank Line
    sadm_writelog "New Filesystem Size will be...: ${NEW_LVSIZE}MB"     # Show User New FS Size

    # Calculate number of MB that will be added
    SIZE2ADD=`echo "$NEW_LVSIZE - $OLDSIZE" | bc `                      # New Size - Old Size 
    sadm_writelog "FS will be increase by (MB)...: $SIZE2ADD"           # Show NB. MB will Add

    # Get VG Information (VGSIZE and VGFREE)
    VGSOPT="--noheadings --separator , --units m "                      # VGS Command Options
    VGSIZE=`vgs $VGSOPT $VGNAME |awk -F, '{ print $6 }'|tr -d 'G' |awk -F\. '{ print $1 }'`
    VGFREE=`vgs $VGSOPT $VGNAME |awk -F, '{ print $7 }'|tr -d 'G' |awk -F\. '{ print $1 }'` 
    sadm_writelog "VG size in MB ................: $VGSIZE"             # Show VG Size in MB
    sadm_writelog "VG MB free space before incr..: $VGFREE"             # Show VG Free Space in MB
    VGUSED=`echo "$VGSIZE - $VGFREE" | bc `                             # Calc. MB Used
    sadm_writelog "VG MB used ...................: $VGUSED"             # Show VG Use space in MB

    # If MB needed to increase is greater/equal MB free in VG - Refuse increase
    if [ $SIZE2ADD -ge $VGFREE ]                                        # if MB to Add > Free Space
       then WMESS="Increase Refused, need ${SIZE2ADD}MB & only ${VGFREE}MB left in VG $VGNAME"
            sadm_writelog "$WMESS"                                      # Show Error to User
            echo "$WMESS" >> $MAIL_BODY                                 # Msg to Email Body File
            send_email "SADMIN: Filesystem $FSNAME Increase rejected - Space Low"    
            return 1                                                    # Return Error to Caller
    fi

    MBLEFT=`echo "$VGFREE - $SIZE2ADD" | bc `                           # Free Space After Incr.
    sadm_writelog "VG MB free space after incr...: $MBLEFT"             # Show Free Space After Inc.
    sadm_writelog "Min. free MB in VG after incr.: $VGMIN_MB"           # Show Min. Free Space Req.

    # Calculate the % Left in the VG
    VGPCT_LEFT=`echo "(($VGFREE/$VGSIZE)*100)" | bc -l | xargs printf "%2.0f"`
    sadm_writelog "Percent free space left in VG.: $VGPCT_LEFT %"       # Percent Free Space in VG
    sadm_writelog "Minimum percent needed in VG..: $VGMIN_PCT %"        # Min. % Req. in VG

    # Free MB in VG after filesystem increase is less than Min. Require (10240MB)
    if [ $MBLEFT -le $VGMIN_MB ]                                        # Free MB < then Min Req.
       then WMESS="$FSNAME increase refused only ${MBLEFT}MB free in VG $VGNAME"
            sadm_writelog "$WMESS"                                      # Show User Error 
            echo "$WMESS" >> $MAIL_BODY                                 # Add Mess. to Mail Body
            send_email "Filesystem $FSNAME was rejected"                # Send Email to Sysadmin
            return 1                                                    # Return Error to Caller
       else sadm_writelog "Filesystem $FSNAME will increase by $SIZE2ADD MB"
    fi

    # Finally Increase filesystem
    sadm_writelog ""                                                    # Blank Line
    sadm_writelog "$FSNAME filesystem increase is starting"             # Start Filesystem increase 
    sadm_writelog ""                                                    # Blank Line
    sadm_writelog "df -hP $FSNAME - Before increase"                    # Show FileSystem Usage
    echo -e "\n${DASH}" >>$MAIL_BODY                                    # Print Dash Line
    echo -e "`date`\nFilesystem $FSNAME before increase.\n\n`df -hP $FSNAME` \n" >> $MAIL_BODY
    df -hP $FSNAME                                                      # Show FS Usage to User  
    sadm_writelog ""                                                    # Blank Line
    extend_fs                                                           # Go Extend Filesystem
    RC=$?                                                               # Save Extend Return Code
    if [ "$RC" -ne 0 ]                                                  # If error occured
        then WMESS="Error ($RC) occured while increasing filesystemn"   # Build Error Message
             sadm_writelog "$WMESS"                                     # Show Err.Msg to User
             echo -e "$WMESS \n" >> $MAIL_BODY                          # Add Err. Msg. to Mail Body
        else WMESS="Filesystem increased with success !"                # Build Status Message
             sadm_writelog "$WMESS"                                     # Show Success to User
             echo -e "$WMESS \n" >> $MAIL_BODY                          # Add Success to Mail Body
    fi
    sadm_writelog ""                                                    # Blank Line
    sadm_writelog "df -hP $FSNAME - After increase"                     # Show FS Usage after Incr.
    df -hP $FSNAME                                                      # Show FS Usage to User  
    #echo -e "`date`\nFilesystem $FSNAME after increase.\n\n`df -hP $FSNAME` \n" >> $MAIL_BODY
    sadm_writelog ""                                                    # Blank Line
    send_email "Filesystem $FSNAME on $MYHOST was increase"
    return $RC                                                          # Return Return Code Caller
}


#===================================================================================================
#                                       Script Start HERE
#===================================================================================================

    # If no filesystem parameter received, then abort process
    if [ $# -ne 1 ]                                                     # If Not 1 Param. Received
        then echo "Must receive filesystem name to increase, process aborted."
             exit 1                                                     # Exit with Error
        else FSNAME=$1                                                  # Save Filesystem to Incr.
    fi
    
    sadm_start                                                          # Init Env. Dir. & RC/Log
    if [ $? -ne 0 ] ; then sadm_stop 1 ; exit 1 ;fi                     # Exit if Problem 
    setlvm_path                                                         # Set Path of LVM Executable
    main_process                                                        # Main Process
    SADM_EXIT_CODE=$?                                                   # Save Nb. Errors in process
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RCH File & Trim Log
    exit $SADM_EXIT_CODE                                                # Exit With Global Err (0/1)                                             # Exit With Global Error code (0/1)
    end_process
