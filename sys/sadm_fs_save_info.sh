#! /bin/sh
#===================================================================================================
# Shellscript   :  sadm_fs_save_info.sh - 
# Description   :  Collect Info in order to Recreate filesystem in case of Disaster
# Version       :  1.0
# Author        :  jacques duplessis
# Date          :  2010-10-09
# Requires      :  bash shell - lvm installed
# Category      :  disaster tools 
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
# 2015_10 - 1.5 - Modify to create a copy of previous data into $SADMIN/sadm_fs_save_info.prev 
# 2015_11 - 1.6 - Remove RHEL3 Support - Now Support RHEL 4, 5, 6 and 7.
#===================================================================================================
#set -x



# --------------------------------------------------------------------------------------------------
#  These variables got to be defined prior to calling the initialize (sadm_init.sh) script
#  These variables are use and needed by the sadm_init.sh script.
#  Source sadm variables and Load sadm functions
# --------------------------------------------------------------------------------------------------
PN=${0##*/}                                    ; export PN              # Current Script name
VER='1.5'                                      ; export VER             # Program version
OUTPUT2=1                                      ; export OUTPUT2         # Output log=0 1=Screen+Log
INST=`echo "$PN" | awk -F\. '{ print $1 }'`    ; export INST            # Get Current script name
TPID="$$"                                      ; export TPID            # Script PID
MAX_LOGLINE=5000                               ; export MAX_LOGLINE     # Max Nb. Lines in LOG (Trim)
MAX_RCLINE=100                                 ; export MAX_RCLINE      # Max Nb. Lines in RCLOG (Trim)
GLOBAL_ERROR=0                                 ; export GLOBAL_ERROR    # Global Error Return Code
#
BASE_DIR=${SADMIN:="/sadmin"}                  ; export BASE_DIR        # Script Root Base Directory
[ -f ${BASE_DIR}/lib/sadm_init.sh ] && . ${BASE_DIR}/lib/sadm_init.sh   # Init Var. & Load sadm functions
#
# --------------------------------------------------------------------------------------------------


# --------------------------------------------------------------------------------------------------
#              V A R I A B L E S    U S E D     I N    T H I S   S C R I P T 
# --------------------------------------------------------------------------------------------------
DRFILE=$SYS_DIR/sadm_fs_save_info.dat           ; export DRFILE         # Output file of program
DRSORT=$SYS_DIR/sadm_fs_save_info.srt           ; export DRSORT         # Output sorted by mnt len
PRVFILE=$SYS_DIR/sadm_fs_save_info.prev         ; export PRVFILE        # Output file of Yesterday
WLOG="/tmp/drrestore_$$.log"                    ; export WLOG           # Output file of program
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
    LVMVER=0                                                            # Assume lvm not install
    write_log "Currently verifying the LVM version installed on system"
    # Check if LVM Version 1 is installed
    rpm -qa '^lvm-' > /dev/null 2>&1                                    # Query RPM DB
    if [ $? -eq 0 ] ; then LVMVER=1 ; fi                                # Found LVM V1 
    
    # Check if LVM Version 2 is installed
    rpm -qa '^lvm-2' > /dev/null 2>&1                                   # Query RPM DB
    if [ $? -eq 0 ] ; then LVMVER=2 ; fi                                # Found LVM V2     

    # Set the Path to lvscan 
    if [ $LVMVER -eq 1 ] ; then LVSCAN="/sbin/lvscan" ; fi              # LVM1 Path (RHEL 3)
    if [ $LVMVER -eq 2 ] ; then LVSCAN=`which lvscan` ; fi              # LVM1 Path (RHEL 4 and Up)

    # If LVM Not Installed
    if [ $LVMVER -eq 0 ]                                                # lvm wasn't found on server
        then write_log "The rpm 'lvm' or 'lvm2' is not installed"       # Advise user no lvm package
             write_log "No use in running this script - Script Aborted" # No LVM - No Script
    fi
    
    return $LVMVER                                                      # Return LVM Version
}


# --------------------------------------------------------------------------------------------------
#      Save information (size, owner, groups, protection, type, ...) about all lvm on server
# --------------------------------------------------------------------------------------------------
#
save_lvm_info()
{
    $LVSCAN  > $TMP_FILE1                                               # Run lvscan output to tmp
    
    write_log "There are `wc -l $TMP_FILE1 | awk '{ print $1 }'` Logical volume reported by lvscan"
    write_log " " ; write_log " "
    
    cat $TMP_FILE1 | while read LVLINE                                  # process all LV detected
        do
        if [ $Debug ] 
            then    write_log " "; 
                    write_log "Processing this line              = $LVLINE"   # Display lvm line processing
        fi 

        # Get logical volume name
        if [ $LVMVER -eq 2 ]                                            # if LVM version 2
            then LVNAME=$( echo $LVLINE |awk '{ print $2 }' | tr -d "\'" | awk -F"/" '{ print$4 }' )
            else LVNAME=$( echo $LVLINE |awk '{ print $4 }' | tr -d "\"" | awk -F"/" '{ print$4 }' )
        fi
        if [ $Debug ]                                                   # If Debug Activated
            then write_log "Logical Volume Name               = $LVNAME" 
        fi         

        
        # Get Volume Group Name
        if [ $LVMVER -eq 2 ]                                            # if LVM version 2
            then VGNAME=$( echo $LVLINE | awk '{ print $2 }' | tr -d "\'" | awk -F"/" '{ print$3 }' )
            else VGNAME=$( echo $LVLINE | awk '{ print $4 }' | tr -d "\"" | awk -F"/" '{ print$3 }' )
        fi
        if [ $Debug ]                                                   # If Debug Activated
            then write_log "Volume Group Name                 = $VGNAME" 
        fi         

        
        # Get logical Volume Size
        LVWS1=$( echo $LVLINE | awk -F'[' '{ print $2 }' )     # Del Everything before [
        LVWS2=$( echo $LVWS1   | awk -F']' '{ print $1 }' )    # Del everything after ]
        LVFLT=$( echo $LVWS2   | awk '{ print $1 }' )          # Get LVM Size
        LVUNIT=$(  echo $LVWS2 | awk '{ print $2 }' )          # Size Unit (MB/GB/MiB/GiB)
        if [ $LVUNIT = "GB" ] || [ $LVUNIT = "GiB" ]           # If GB/GiB Unit
            then LVINT=`echo "$LVFLT * 1024" | /usr/bin/bc  | awk -F'.' '{ print $1 }'`
                 LVSIZE=$LVINT                                  # Keep Size in MB
            else LVINT=$( echo $LVFLT | awk -F'\.' '{ print $1 }' )
                 LVSIZE=$LVINT                                  # Keep Size in MB
        fi
        if [ $Debug ]
            then write_log "Logical Volume Size               = $LVFLT"
                 write_log "Logical Volume Unit Used          = $LVUNIT"
                 write_log "Calculated LV size in MB          = $LVSIZE MB"
        fi


        # Construct from LVSCAN Device the device name used in FSTAB
        if [ $LVMVER -eq 2 ]
            then LVPATH1=$(echo $LVLINE | awk '{ printf "%s ",$2 }' | tr -d "\'")
            else LVPATH1=$(echo $LVLINE | awk '{ printf "%s ",$4 }' | tr -d "\"")
        fi
        LVPATH2="/dev/mapper/${VGNAME}-${LVNAME}"
        if [ $Debug ] 
            then write_log "LVM Device returned by lvscan     = $LVPATH1" 
                 write_log "LVM We need to find in $FSTAB = $LVPATH2" 
        fi
        
        
        # Get the Filesystem Type
        LVTYPE=`grep -iE "^${LVPATH1} |^${LVPATH2} " $FSTAB  | awk '{ print $3 }'`
        if [ $Debug ] ; then write_log "File system Type                  = $LVTYPE" ; fi

        
        # Get mount point from FSTAB
        if [ "$LVTYPE" = "swap" ]
           then LVMOUNT="" ; LVLEN=0
           else LVMOUNT=`grep -iE "^${LVPATH1} |^${LVPATH2} " $FSTAB  | awk '{ print $2 }'`
        fi
        if [ $Debug ] ; then write_log "Mount Point                       = $LVMOUNT" ; fi
        
        
        # Get the lenght of mount pointt
        LVLEN=${#LVMOUNT}
        if [ $Debug ] ; then write_log "Lenght of Mount Point Name        = $LVLEN" ; fi

    
        # Get Owner and Group of the Filesystem or Swap Space
        if [ "$LVTYPE" = "swap" ]
            then LVGROUP="" ; LVOWNER=""
            else LVGROUP=`ls -ld $LVMOUNT | awk '{ printf "%s", $4 }'`
                 LVOWNER=`ls -ld $LVMOUNT | awk '{ printf "%s", $3 }'`
        fi
        if [ $Debug ] 
            then write_log "Filesystem Group Owner            = $LVGROUP" 
                 write_log "Filesystem Owner                  = $LVOWNER"
        fi

    
        # Get the filesystem protection
        if [ "$LVTYPE" = "swap" ]
           then LVPROT="0000"
           else LVLS=`ls -ld $LVMOUNT`
                if [ $Debug ] ; then write_log "ls -ld returned                   = $LVLS" ; fi
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
        if [ $Debug ] ; then write_log "Filesystem Protection             = $LVPROT" ; fi


        # Write data collection in order that need to be recreated 
        echo "$LVLEN:$VGNAME:$LVMOUNT:$LVNAME:$LVTYPE:$LVSIZE:$LVGROUP:$LVOWNER:$LVPROT" >> $TMP_FILE3
        write_log "Line written to output file       = $LVLEN:$VGNAME:$LVMOUNT:$LVNAME:$LVTYPE:$LVSIZE:$LVGROUP:$LVOWNER:$LVPROT"
        done

    # Sort output - Get rid of LVLEN at the same time (needed only for the sort)
    sort -n $TMP_FILE3 | awk -F: '{ printf "%s:%s:%s:%s:%s:%s:%s:%s\n", $2,$3,$4,$5,$6,$7,$8,$9 }' > $DRFILE
    return
}



# --------------------------------------------------------------------------------------------------
#                                     Script Start HERE
# --------------------------------------------------------------------------------------------------
    sadm_start                                                          # Init Env. Dir & RC/Log File
    check_lvm_version                                                   # Get LVM Version in $LVMVER
    if [ $? -eq 0 ] ; then exit 1 ; fi                                  # LVM Not install - Exit
    if [ $Debug ]                                                       # If Debug Activated
        then write_log "We are using LVM version $LVMVER"               # Show LVM Version
             write_log "The Path to lvscan is $LVSCAN"                  # Show LVSCAN Path
    fi   
    if [ -s $DRFILE ] ; then cp $DRFILE $PRVFILE ; fi                   # Make a backup of data file 
    save_lvm_info                                                       # Save info about all lvm's
    sadm_stop $GLOBAL_ERROR                                             # Upd. RC & Trim Log & Set RC
    exit $GLOBAL_ERROR                                                  # Exit Glob. Err.Code (0/1)
