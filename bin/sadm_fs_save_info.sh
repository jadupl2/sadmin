#! /bin/sh
#===================================================================================================
# Shellscript   :  sadm_fs_save_info.sh - 
# Description   :  Collect Info in order to Recreate filesystem in case of Disaster
# Version       :  1.0
# Author        :  jacques duplessis
# Date          :  2015-10-09
# Requires      :  bash shell - lvm installed
# Category      :  disaster recovery tools 
#===================================================================================================
# Description
#
# Note
#    o this script collect all data necessary to recreate all filesystems using LVM
#    o run this script once a day via the cron
#    o the output of this script is a text file named $SADMIN/sadm_fs_save_info.dat
#
#    Script does : 
#       1- Check if lvm package is installed on server.
#           If not script display error and exit with error code 1
#           If it is installed check if V1 (Rhel3) or V2 is installed
#           Get the path to lvscan command
#       2- Run the LVSCAN command and process each line , one by one.
#           Gather all info needed to recreate the filesystem (or swap) needed in case of disaster
#           Create file sadm_fs_save_info.dat that will contain all info needed. to recreate FS.
#           File is in order of mount point lenght (So that /abc if created before /abc/123).
#           
#
#===================================================================================================
#
# 2015_10 - 1.5 - Modify to create a copy of previous data into $SADMIN/sadm_fs_save_info.prev 
# 2015_11 - 1.6 - Remove RHEL3 Support - Now Support RHEL 4, 5, 6 and 7.
# 2015_12 - 1.7 - Corrected bug with Swap Space
#
#===================================================================================================
#set -x


#
#===================================================================================================
# If You want to use the SADMIN Libraries, you need to add this section at the top of your script
#   Please refer to the file $sadm_base_dir/lib/sadm_lib_std.txt for a description of each
#   variables and functions available to you when using the SADMIN functions Library
#===================================================================================================

# --------------------------------------------------------------------------------------------------
# Global variables used by the SADMIN Libraries - Some influence the behavior of function in Library
# These variables need to be defined prior to load the SADMIN function Libraries
# --------------------------------------------------------------------------------------------------
SADM_PN=${0##*/}                           ; export SADM_PN             # Current Script name
SADM_VER='1.5'                             ; export SADM_VER            # This Script Version
SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1` ; export SADM_INST           # Script name without ext.
SADM_TPID="$$"                             ; export SADM_TPID           # Script PID
SADM_EXIT_CODE=0                           ; export SADM_EXIT_CODE      # Script Error Return Code
SADM_BASE_DIR=${SADMIN:="/sadmin"}         ; export SADM_BASE_DIR       # SADMIN Root Base Directory
SADM_LOG_TYPE="B"                          ; export SADM_LOG_TYPE       # 4Logger S=Scr L=Log B=Both
SADM_MULTIPLE_EXEC="N"                     ; export SADM_MULTIPLE_EXEC  # Run many copy at same time
SADM_DEBUG_LEVEL=0                         ; export SADM_DEBUG_LEVEL    # 0=NoDebug Higher=+Verbose

# --------------------------------------------------------------------------------------------------
# Define SADMIN Tool Library location and Load them in memory, so they are ready to be used
# --------------------------------------------------------------------------------------------------
[ -f ${SADM_BASE_DIR}/lib/sadm_lib_std.sh ]    && . ${SADM_BASE_DIR}/lib/sadm_lib_std.sh     # sadm std Lib
[ -f ${SADM_BASE_DIR}/lib/sadm_lib_server.sh ] && . ${SADM_BASE_DIR}/lib/sadm_lib_server.sh  # sadm server lib
#[ -f ${SADM_BASE_DIR}/lib/sadm_lib_screen.sh ] && . ${SADM_BASE_DIR}/lib/sadm_lib_screen.sh  # sadm screen lib

# --------------------------------------------------------------------------------------------------
# These Global Variables, get their default from the sadmin.cfg file, but can be overridden here
# --------------------------------------------------------------------------------------------------
#SADM_MAIL_ADDR="your_email@domain.com"    ; export ADM_MAIL_ADDR        # Default is in sadmin.cfg
SADM_MAIL_TYPE=1                          ; export SADM_MAIL_TYPE       # 0=No 1=Err 2=Succes 3=All
#SADM_CIE_NAME="Your Company Name"         ; export SADM_CIE_NAME        # Company Name
#SADM_USER="sadmin"                        ; export SADM_USER            # sadmin user account
#SADM_GROUP="sadmin"                       ; export SADM_GROUP           # sadmin group account
#SADM_MAX_LOGLINE=5000                     ; export SADM_MAX_LOGLINE     # Max Nb. Lines in LOG )
#SADM_MAX_RCLINE=100                       ; export SADM_MAX_RCLINE      # Max Nb. Lines in RCH file
#SADM_NMON_KEEPDAYS=40                     ; export SADM_NMON_KEEPDAYS   # Days to keep old *.nmon
#SADM_SAR_KEEPDAYS=40                      ; export SADM_NMON_KEEPDAYS   # Days to keep old *.nmon
 
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPTE LE ^C
#===================================================================================================
#


#



# --------------------------------------------------------------------------------------------------
#              V A R I A B L E S    U S E D     I N    T H I S   S C R I P T 
# --------------------------------------------------------------------------------------------------
DRFILE=$SADM_DR_DIR/`hostname`_fs_save_info.dat   ; export DRFILE       # Output file of program
DRSORT=$SADM_DR_DIR/`hostname`_fs_save_info.srt   ; export DRSORT       # Output sorted by mnt len
PRVFILE=$SADM_DR_DIR/`hostname`_fs_save_info.prev ; export PRVFILE      # Output file of Yesterday
Debug=true                                        ; export Debug        # Debug increase Verbose 
LVMVER=0                                          ; export LVMVER       # LVM Version on server (1/2)
LVSCAN=" "                                        ; export LVSCAN       # Full path to lvscan cmd
FSTAB="/etc/fstab"                                ; export FSTAB        # File containing mount point





# --------------------------------------------------------------------------------------------------
#          Determine if LVM is installed and what version of lvm is installed (1 or 2)
# --------------------------------------------------------------------------------------------------
#
check_lvm_version()
{
    LVMVER=0                                                            # Assume lvm not install
    sadm_logger "Currently verifying if 'lvm2' package is installed"
    
    # Check if LVM Version 2 is installed
    case "$(sadm_os_name)" in                                           # Test OS Name
      "REDHAT"|"CENTOS"|"FEDORA")   sadm_logger "rpm -qa lvm-2"
                                    rpm -qa '^lvm-2' > /dev/null 2>&1   # Query RPM DB
                                    if [ $? -eq 0 ] ; then LVMVER=2 ;fi # Found LVM V2     
                                    ;; 
      "UBUNTU"|"DEBIAN"         )   sadm_logger "dpkg --status lvm2"
                                    dpkg --status lvm2 > /dev/null 2>&1 # Query pkg list
                                    if [ $? -eq 0 ] ; then LVMVER=2 ;fi # Found LVM V2     
                                    ;; 
      "*"                       )   sadm_logger "OS Not Supported yet ($(sadm_os_name))"
                                    ;; 
    esac
    LVSCAN=`which lvscan`                                               # LVM1 Path (RHEL 4 and Up)
    if [ $? -ne 0 ] ; then LVMVER=0 ; fi                                # If cannot locate lvscan 
    
    # If LVM Not Installed
    if [ $LVMVER -eq 0 ]                                                # lvm wasn't found on server
        then sadm_logger "The lvm2 package is not installed"            # Advise user no lvm package
             sadm_logger "No value running this script, Script Aborted" # No LVM - No Script
    fi
    return $LVMVER                                                      # Return LVM Version
}




#===================================================================================================
#      SAVE INFORMATION (SIZE, OWNER, GROUPS, PROTECTION, TYPE, ...) ABOUT ALL LVM ON SERVER
#===================================================================================================
#
save_lvm_info()
{
    $LVSCAN  > $SADM_TMP_FILE1 2>/dev/null                                              # Run lvscan output to tmp
    
    sadm_logger "There are `wc -l $SADM_TMP_FILE1 | awk '{ print $1 }'` Logical volume reported by lvscan"
    sadm_logger "Output file is $DRFILE" 
    #sadm_logger " " ; sadm_logger " "
    

    cat $SADM_TMP_FILE1 | while read LVLINE                                  # process all LV detected
        do
        if [ $Debug ] 
            then    sadm_logger " " ; sadm_logger "$SADM_DASH"; 
                    sadm_logger "Processing this line              = $LVLINE"   # Display lvm line processing
        fi 

        # Get logical volume name
        LVNAME=$( echo $LVLINE |awk '{ print $2 }' | tr -d "\'" | awk -F"/" '{ print$4 }' )
        if [ $Debug ] ; then sadm_logger "Logical Volume Name               = $LVNAME"  ; fi         

        
        # Get Volume Group Name
        VGNAME=$( echo $LVLINE | awk '{ print $2 }' | tr -d "\'" | awk -F"/" '{ print$3 }' )
        if [ $Debug ] ; then sadm_logger "Volume Group Name                 = $VGNAME"  ; fi         

        
        # Get logical Volume Size
        LVWS1=$( echo $LVLINE | awk -F'[' '{ print $2 }' )     # Del Everything before [
        LVWS2=$( echo $LVWS1   | awk -F']' '{ print $1 }' )    # Del everything after ]
        LVFLT=$( echo $LVWS2   | awk '{ print $1 }' )          # Get LVM Size
        LVUNIT=$(  echo $LVWS2 | awk '{ print $2 }' )          # Size Unit (MB/GB/MiB/GiB)
        if [ $LVUNIT = "GB" ] || [ $LVUNIT = "GiB" ]           # If GB/GiB Unit
            then LVINT=`echo "$LVFLT * 1024" | /usr/bin/bc  | awk -F'.' '{ print $1 }'`
                 LVSIZE=$LVINT                                  # Keep Size in MB
            else LVINT=$( echo $LVFLT | awk -F'.' '{ print $1 }' )
                 LVSIZE=$LVINT                                  # Keep Size in MB
        fi
        if [ $Debug ]
            then sadm_logger "Logical Volume Size               = $LVFLT"
                 sadm_logger "Logical Volume Unit Used          = $LVUNIT"
                 sadm_logger "Calculated LV size in MB          = $LVSIZE MB"
        fi


        # Construct from LVSCAN Device the device name used in FSTAB
        LVPATH1=$(echo $LVLINE | awk '{ printf "%s ",$2 }' | tr -d "\'")
        LVPATH2="/dev/mapper/${VGNAME}-${LVNAME}"
        if [ $Debug ] 
            then sadm_logger "LVM Device returned by lvscan     = $LVPATH1" 
                 sadm_logger "LVM We need to find in $FSTAB = $LVPATH2" 
        fi
        
        
        # Get the Filesystem Type
        LVTYPE=`grep -iE "^${LVPATH1} |^${LVPATH2} " $FSTAB  | awk '{ print $3 }' | tr -d ' '`
        WT=`blkid /dev/mapper/${VGNAME}-${LVNAME} |awk -F= '{ print $3 }' |tr -d "\"" |tr -d " "`
        if [ "$WT" = "swap" ] || [ "$WT" = "ext4" ] || [ "$WT" = "ext3" ] || [ "$WT" = "xfs" ] || [ "$WT" = "ext2" ] 
           then LVTYPE="$WT"
        fi
        if [ $Debug ] ; then sadm_logger "File system Type                  = ${LVTYPE}" ; fi

        
        # Get mount point from FSTAB
        if [ "$LVTYPE" = "swap" ]
           then LVMOUNT="" ; LVLEN=0
           else LVMOUNT=`grep -iE "^${LVPATH1} |^${LVPATH2} " $FSTAB  | awk '{ print $2 }'`
        fi
        if [ $Debug ] ; then sadm_logger "Mount Point                       = $LVMOUNT" ; fi
        
        
        # Get the lenght of mount pointt
        LVLEN=${#LVMOUNT}
        if [ $Debug ] ; then sadm_logger "Lenght of Mount Point Name        = $LVLEN" ; fi

    
        # Get Owner and Group of the Filesystem or Swap Space
        if [ "$LVTYPE" = "swap" ]
            then LVGROUP="" ; LVOWNER=""
            else LVGROUP=`ls -ld $LVMOUNT | awk '{ printf "%s", $4 }'`
                 LVOWNER=`ls -ld $LVMOUNT | awk '{ printf "%s", $3 }'`
        fi
        if [ $Debug ] 
            then sadm_logger "Filesystem Group Owner            = $LVGROUP" 
                 sadm_logger "Filesystem Owner                  = $LVOWNER"
        fi

    
        # Get the filesystem protection
        if [ "$LVTYPE" = "swap" ]
           then LVPROT="0000"
           else LVLS=`ls -ld $LVMOUNT`
                if [ $Debug ] ; then sadm_logger "ls -ld returned                   = $LVLS" ; fi
                user_bit=0 ; group_bit=0 ; other_bit=0 ; stick_bit=0
                if [ `echo $LVLS | awk '{ printf "%1s", substr($1,2,1) }'`  = "r" ] ; then user_bit=`expr $user_bit + 4`   ; fi
                if [ `echo $LVLS | awk '{ printf "%1s", substr($1,3,1) }'`  = "w" ] ; then user_bit=`expr $user_bit + 2`   ; fi
                if [ `echo $LVLS | awk '{ printf "%1s", substr($1,4,1) }'`  = "x" ] ; then user_bit=`expr $user_bit + 1`   ; fi
                if [ `echo $LVLS | awk '{ printf "%1s", substr($1,4,1) }'`  = "s" ] ; then user_bit=`expr $user_bit + 1`   ; fi
                if [ `echo $LVLS | awk '{ printf "%1s", substr($1,4,1) }'`  = "s" ] ; then stick_bit=`expr $stick_bit + 4` ; fi
                if [ `echo $LVLS | awk '{ printf "%1s", substr($1,5,1) }'`  = "r" ] ; then group_bit=`expr $group_bit + 4` ; fi
                if [ `echo $LVLS | awk '{ printf "%1s", substr($1,6,1) }'`  = "w" ] ; then group_bit=`expr $group_bit + 2` ; fi
                if [ `echo $LVLS | awk '{ printf "%1s", substr($1,7,1) }'`  = "x" ] ; then group_bit=`expr $group_bit + 1` ; fi
                if [ `echo $LVLS | awk '{ printf "%1s", substr($1,7,1) }'`  = "s" ] ; then group_bit=`expr $group_bit + 1` ; fi
                if [ `echo $LVLS | awk '{ printf "%1s", substr($1,7,1) }'`  = "s" ] ; then stick_bit=`expr $stick_bit + 2` ; fi
                if [ `echo $LVLS | awk '{ printf "%1s", substr($1,8,1) }'`  = "r" ] ; then other_bit=`expr $other_bit + 4` ; fi
                if [ `echo $LVLS | awk '{ printf "%1s", substr($1,9,1) }'`  = "w" ] ; then other_bit=`expr $other_bit + 2` ; fi
                if [ `echo $LVLS | awk '{ printf "%1s", substr($1,10,1) }'` = "x" ] ; then other_bit=`expr $other_bit + 1` ; fi
                if [ `echo $LVLS | awk '{ printf "%1s", substr($1,10,1) }'` = "t" ] ; then other_bit=`expr $other_bit + 1` ; fi
                if [ `echo $LVLS | awk '{ printf "%1s", substr($1,10,1) }'` = "t" ] ; then stick_bit=`expr $stick_bit + 1` ; fi
                LVPROT="${stick_bit}${user_bit}${group_bit}${other_bit}"
        fi
        if [ $Debug ] ; then sadm_logger "Filesystem Protection             = $LVPROT" ; fi


        # Write data collection in order that need to be recreated 
        echo "$LVLEN:$VGNAME:$LVMOUNT:$LVNAME:$LVTYPE:$LVSIZE:$LVGROUP:$LVOWNER:$LVPROT" >> $SADM_TMP_FILE3
        sadm_logger "Line written to output file       = $LVLEN:$VGNAME:$LVMOUNT:$LVNAME:$LVTYPE:$LVSIZE:$LVGROUP:$LVOWNER:$LVPROT"
        done
        
    sadm_logger "Backup of $DRFILE" 
    if [ -s $DRFILE ] ; then cp $DRFILE $PRVFILE ; fi                   # Make a backup of data file 

    # Sort output - Get rid of LVLEN at the same time (needed only for the sort)
    sadm_logger "Creating a new copy of $DRFILE"
    if [ -s $SADM_TMP_FILE3 ]
        then sort -n $SADM_TMP_FILE3 | awk -F: '{ printf "%s:%s:%s:%s:%s:%s:%s:%s\n", $2,$3,$4,$5,$6,$7,$8,$9 }' >$SADM_TMP_FILE2
        else touch $SADM_TMP_FILE2
    fi 
    
    echo "# SADMIN - Filesystem Info. for system $(sadm_hostname).$(sadm_domainname)"  > $DRFILE
    echo "# File was created by sadm_fs_save_info.sh on `date`"                       >> $DRFILE
    echo "# This file is use in a Disaster Recovery situation"                        >> $DRFILE
    echo "# The data below is use by sadm_fs_recreate.sh to recreate filesystems"     >> $DRFILE
    echo "# ---------------------------------------------------------------------"    >> $DRFILE
    echo "# " >> $DRFILE
    cat  $SADM_TMP_FILE2 >> $DRFILE
    return
}



# --------------------------------------------------------------------------------------------------
#                                     Script Start HERE
# --------------------------------------------------------------------------------------------------
    sadm_start                                                          # Init Env. Dir & RC/Log File
    if ! $(sadm_is_root)                                                # Only ROOT can run Script
        then sadm_logger "This script must be run by the ROOT user"     # Advise User Message
             sadm_logger "Process aborted"                              # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi
    check_lvm_version                                                   # Get LVM Version in $LVMVER
    if [ $? -eq 0 ] ; then sadm_stop 0 ; exit 0 ; fi                    # LVM Not install - Exit
    save_lvm_info                                                       # Save info about all lvm's
    sadm_stop $SADM_EXIT_CODE                                           # Upd. RC & Trim Log & Set RC
    exit $SADM_EXIT_CODE                                                # Exit Glob. Err.Code (0/1)
