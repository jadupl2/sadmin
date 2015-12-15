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

#set -x
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
VER='1.7'                                      ; export VER             # Program version
OUTPUT2=1                                      ; export OUTPUT2         # Write log 0=log 1=Scr+Log
INST=`echo "$PN" | awk -F\. '{ print $1 }'`    ; export INST            # Get Current script name
TPID="$$"                                      ; export TPID            # Script PID
GLOBAL_ERROR=0                                 ; export GLOBAL_ERROR    # Global Error Return Code
BASE_DIR=${SADMIN:="/sadmin"}                  ; export BASE_DIR        # Script Root Base Directory
#
[ -f ${BASE_DIR}/lib/sadm_lib_std.sh ]    && . ${BASE_DIR}/lib/sadm_lib_std.sh     # sadm std Lib
[ -f ${BASE_DIR}/lib/sadm_lib_server.sh ] && . ${BASE_DIR}/lib/sadm_lib_server.sh  # sadm server lib
#
# VARIABLES THAT CAN BE CHANGED PER SCRIPT -(SOME ARE CONFIGURABLE IS $BASE_DIR/cfg/sadmin.cfg)
#ADM_MAIL_ADDR="root@localhost"                 ; export ADM_MAIL_ADDR  # Default is in sadmin.cfg
SADM_MAIL_TYPE=1                               ; export SADM_MAIL_TYPE  # 0=No 1=Err 2=Succes 3=All
MAX_LOGLINE=5000                               ; export MAX_LOGLINE     # Max Nb. Lines in LOG )
MAX_RCLINE=100                                 ; export MAX_RCLINE      # Max Nb. Lines in RCH LOG
#***************************************************************************************************
#
#
#



# --------------------------------------------------------------------------------------------------
#              V A R I A B L E S    U S E D     I N    T H I S   S C R I P T 
# --------------------------------------------------------------------------------------------------
DRFILE=$DR_DIR/`hostname`_fs_save_info.dat      ; export DRFILE         # Output file of program
DRSORT=$DR_DIR/`hostname`_fs_save_info.srt      ; export DRSORT         # Output sorted by mnt len
PRVFILE=$DR_DIR/`hostname`_fs_save_info.prev    ; export PRVFILE        # Output file of Yesterday
Debug=true                                      ; export Debug          # Debug increase Verbose 
LVMVER=0                                        ; export LVMVER         # LVM Version on server (1/2)
LVSCAN=" "                                      ; export LVSCAN         # Full path to lvscan cmd
FSTAB="/etc/fstab"                              ; export FSTAB          # File containing mount point





# --------------------------------------------------------------------------------------------------
#          Determine if LVM is installed and what version of lvm is installed (1 or 2)
# --------------------------------------------------------------------------------------------------
#
check_lvm_version()
{
    LVMVER=0                                                              # Assume lvm not install
    sadm_logger "Currently verifying the LVM version installed on system"
    
    # Check if LVM Version 2 is installed
    rpm -qa '^lvm-2' > /dev/null 2>&1                                     # Query RPM DB
    if [ $? -eq 0 ] ; then LVMVER=2 ; fi                                  # Found LVM V2     

    # Set the Path to lvscan 
    LVSCAN=`which lvscan`                                                 # LVM1 Path (RHEL 4 and Up)

    # If LVM Not Installed
    if [ $LVMVER -eq 0 ]                                                  # lvm wasn't found on server
        then sadm_logger "The rpm 'lvm' or 'lvm2' is not installed"       # Advise user no lvm package
             sadm_logger "No use in running this script - Script Aborted" # No LVM - No Script
    fi
    
    return $LVMVER                                                        # Return LVM Version
}




#===================================================================================================
#      SAVE INFORMATION (SIZE, OWNER, GROUPS, PROTECTION, TYPE, ...) ABOUT ALL LVM ON SERVER
#===================================================================================================
#
save_lvm_info()
{
    $LVSCAN  > $TMP_FILE1                                               # Run lvscan output to tmp
    
    sadm_logger "There are `wc -l $TMP_FILE1 | awk '{ print $1 }'` Logical volume reported by lvscan"
    sadm_logger "Output file is $DRFILE" 
    sadm_logger " " ; sadm_logger " "
    

    cat $TMP_FILE1 | while read LVLINE                                  # process all LV detected
        do
        if [ $Debug ] 
            then    sadm_logger " " ; sadm_logger "$DASH"; 
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
        echo "$LVLEN:$VGNAME:$LVMOUNT:$LVNAME:$LVTYPE:$LVSIZE:$LVGROUP:$LVOWNER:$LVPROT" >> $TMP_FILE3
        sadm_logger "Line written to output file       = $LVLEN:$VGNAME:$LVMOUNT:$LVNAME:$LVTYPE:$LVSIZE:$LVGROUP:$LVOWNER:$LVPROT"
        done
        
    sadm_logger " " ; sadm_logger "$DASH"; 
    sadm_logger "Backup of $DRFILE is done in $PRVFILE" 
    if [ -s $DRFILE ] ; then cp $DRFILE $PRVFILE ; fi                   # Make a backup of data file 

    # Sort output - Get rid of LVLEN at the same time (needed only for the sort)
    sadm_logger "Creating a new copy of $DRFILE"
    sort -n $TMP_FILE3 | awk -F: '{ printf "%s:%s:%s:%s:%s:%s:%s:%s\n", $2,$3,$4,$5,$6,$7,$8,$9 }' >$TMP_FILE2
    
    echo -e "# SADMIN - Filesystem Info. for system $(sadm_hostname).$(sadm_domainname)"   >$DRFILE
    echo -e "# File was created by sadm_fs_save_info.sh on `date`"                       >> $DRFILE
    echo -e "# This file is use in a Disaster Recovery situation"                        >> $DRFILE
    echo -e "# The data below is use by sadm_fs_recreate.sh to recreate filesystems"     >> $DRFILE
    echo -e "# ---------------------------------------------------------------------"    >> $DRFILE
    echo -e "# " >> $DRFILE
    cat  $TMP_FILE2 >> $DRFILE
    return
}



# --------------------------------------------------------------------------------------------------
#                                     Script Start HERE
# --------------------------------------------------------------------------------------------------
    if [ $(id -u) -ne 0 ]                                               # Only ROOT can run Script
        then echo "This script (${PN}) can only be run by ROOT"         # Advise User Message
             echo "Process aborted"                                     # Abort advise message
             exit 1                                                     # Exit To O/S
        else echo "UID =  $(id -u)"
    fi

    sadm_start                                                          # Init Env. Dir & RC/Log File
    check_lvm_version                                                   # Get LVM Version in $LVMVER
    if [ $? -eq 0 ] ; then sadm_stop 1 ; exit 1 ; fi                    # LVM Not install - Exit
#
    if [ $Debug ]                                                       # If Debug Activated
        then sadm_logger "System is using LVM version $LVMVER"          # Show LVM Version
             sadm_logger "The Path to lvscan is $LVSCAN"                # Show LVSCAN Path
    fi   
    save_lvm_info                                                       # Save info about all lvm's
    sadm_stop $GLOBAL_ERROR                                             # Upd. RC & Trim Log & Set RC
    exit $GLOBAL_ERROR                                                  # Exit Glob. Err.Code (0/1)
