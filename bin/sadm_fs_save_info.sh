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
#    o run this script once a day via the cron
#
# -----
#    In Linux Script does : 
#    o this script collect all data necessary to recreate all filesystems using LVM
#       1- Check if lvm package is installed on server.
#           If not script display error and exit with error code 1
#           If it is installed check if V1 (Rhel3) or V2 is installed
#           Get the path to lvscan command
#
#       2- Run the LVSCAN command and process each line , one by one.
#           Gather all info needed to recreate the filesystem (or swap) needed in case of disaster
#           Create file sadm_fs_save_info.dat that will contain all info needed. to recreate FS.
#           File is in order of mount point lenght (So that /abc if created before /abc/123).
#
#           The output of the script is a text file named : 
#           SADM_BASE_DIR/dat/dr/HOSTNAME_sadm_fs_save_info.dat
#           This output file can then be use by "sadm_fs_recreate.sh" script to recreate all 
#           filesystems of the specified VG, with the proper Persmission.
#           Note the VG MUST be created with proper size prior to run the recreate fs script
#
#           EXAMPLE FOR FILE PRODUCED :
#                 root@holmes:/sadmin/dat/dr# cat holmes_fs_save_info.dat
#                       # SADMIN - Filesystem Info. for system holmes.maison.ca
#                        # File was created by sadm_fs_save_info.sh on Thu Dec  1 05:02:03 EST 2016
#                        # This file is use in a Disaster Recovery situation
#                        # The data below is use by sadm_fs_recreate.sh to recreate filesystems
#                        # ---------------------------------------------------------------------
#                        # 
#                        rootvg::swap00:swap:3072:::0000
#                        rootvg:/:root:xfs:1024:root:root:0555
#                        rootvg:/opt:opt:xfs:2048:root:root:0755
#                        rootvg:/tmp:tmp:xfs:3072:root:root:1777
#                        rootvg:/usr:usr:xfs:7997:root:root:0755
#                        rootvg:/var:var:xfs:3072:root:root:0755
#                        rootvg:/home:home:xfs:7997:root:root:0755
#                        rootvg:/sadmin:sadmin:xfs:4096:sadmin:sadmin:0775
#                        rootvg:/storix:storix:xfs:768:root:root:0775
#                        rootvg:/sysadmin:sysadm:xfs:128:sadmin:jacques:0775
#                    root@holmes:/sadmin/dat/dr#   
#
# -----     
#    In AIX Script does : 
#       1- It produce a file name ${SADM_BASE_DIR}/dat/dr/HOSTNAME_pvinfo.txt, that contain the
#          list of physical volume along with their size and the space use in each VG.
#          Example : root@aixb50(/sadmin/dat/dr)# cat aixb50_pvinfo.txt
#                       hdisk0          0002dd2f26946375                    rootvg          active
#                       hdisk1          0002dd2f24d98974                    datavg          active
#                       Used space for datavg: (256 megabytes)
#                       hdisk0:34715
#                       hdisk1:34715
#
#       2- Script make sure that an exclude file (/etc/exclude.VGNAME) for each VG exist and 
#          that it contain this line ".*", so that no file is taken in the backup of the VG 
#           (Only the structure).
#
#       3- A backup of the structure of each VG is taken and store in ${SADM_BASE_DIR}/dat/dr.
#          File is in backup/restore format.
#                       root@aixb50(/sadmin/dat/dr)# file aixb50_datavg.savevg
#                        aixb50_datavg.savevg: backup/restore format file
#                       root@aixb50(/sadmin/dat/dr)#
#           
#          Both of the files created are quite small, since no users files is included in the backup
#               -rw-rw-r--    1 sadmin   sadmin          215 Dec 01 12:10 aixb50_pvinfo.txt
#               -rw-rw-r--    1 sadmin   sadmin        51200 Dec 01 12:10 aixb50_datavg.savevg
#
#       4- When the backup of a VG is done the line line that was added in the exclude file 
#          is removed. 
#
#
#===================================================================================================
#
# 2015_10 - 1.5 - Modify to create a copy of previous data into $SADMIN/sadm_fs_save_info.prev 
# 2015_11 - 1.6 - Remove RHEL3 Support - Now Support RHEL 4, 5, 6 and 7.
# 2015_12 - 1.7 - Corrected bug with Swap Space
# 2016_11 - 2.0 - Aix is now supported by the script - All VG Structure are store in *.savevg 
#                 file under ${SADM_BASE_DIR}/dat/dr Directory 
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
SADM_VER='2.0'                             ; export SADM_VER            # This Script Version
SADM_INST=`echo "$SADM_PN" |cut -d'.' -f1` ; export SADM_INST           # Script name without ext.
SADM_TPID="$$"                             ; export SADM_TPID           # Script PID
SADM_EXIT_CODE=0                           ; export SADM_EXIT_CODE      # Script Error Return Code
SADM_BASE_DIR=${SADMIN:="/sadmin"}         ; export SADM_BASE_DIR       # SADMIN Root Base Directory
SADM_LOG_TYPE="B"                          ; export SADM_LOG_TYPE       # 4Logger S=Scr L=Log B=Both
SADM_MULTIPLE_EXEC="N"                     ; export SADM_MULTIPLE_EXEC  # Run many copy at same time

# --------------------------------------------------------------------------------------------------
# Define SADMIN Tool Library location and Load them in memory, so they are ready to be used
# --------------------------------------------------------------------------------------------------
[ -f ${SADM_BASE_DIR}/lib/sadmlib_std.sh ]    && . ${SADM_BASE_DIR}/lib/sadmlib_std.sh     
[ -f ${SADM_BASE_DIR}/lib/sadmlib_server.sh ] && . ${SADM_BASE_DIR}/lib/sadmlib_server.sh  

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
DRFILE=$SADM_DR_DIR/$(sadm_get_hostname)_fs_save_info.dat   ;export DRFILE  # Output file of program
PRVFILE=$SADM_DR_DIR/$(sadm_get_hostname)_fs_save_info.prev ;export PRVFILE # Yesterday Output file
Debug=true                                        ; export Debug        # Debug increase Verbose 
LVMVER=0                                          ; export LVMVER       # LVM Version on server (1/2)
LVSCAN=" "                                        ; export LVSCAN       # Full path to lvscan cmd
FSTAB="/etc/fstab"                                ; export FSTAB        # File containing mount point

# Variables used for AIX Support
VG_LIST=""                                        ; export VG_LIST      # Contain List of Active VG             SAVEVGFILE=""                                     ; export SAVEVGFILE   # FileName of savevg backup 
PVNAME="hdisk"                                    ; export PVNAME       # Hard Disk name in Aix
HPREFIX="${SADM_DR_DIR}/$(sadm_get_hostname)"     ; export HPREFIX      # Output File Loc & Name
PVINFO_FILE="${HPREFIX}_pvinfo.txt"               ; export PVINFO_FILE  # Output for Aix PV info   
SAVEVG="savevg -e -i -v -fVGDATAFILE_PLACE_HOLDER"




# --------------------------------------------------------------------------------------------------
#          Determine if LVM is installed and what version of lvm is installed (1 or 2)
# --------------------------------------------------------------------------------------------------
#
check_lvm_version()
{
    LVMVER=0                                                            # Assume lvm not install
    sadm_writelog "Currently verifying if 'lvm2' package is installed"
    
    # Check if LVM Version 2 is installed
    case "$(sadm_get_osname)" in                                            # Test OS Name
      "REDHAT"|"CENTOS"|"FEDORA")   sadm_writelog "rpm -qa lvm-2"
                                    rpm -qa '^lvm-2' > /dev/null 2>&1   # Query RPM DB
                                    if [ $? -eq 0 ] ; then LVMVER=2 ;fi # Found LVM V2     
                                    ;; 
      "UBUNTU"|"DEBIAN"         )   sadm_writelog "dpkg --status lvm2"
                                    dpkg --status lvm2 > /dev/null 2>&1 # Query pkg list
                                    if [ $? -eq 0 ] ; then LVMVER=2 ;fi # Found LVM V2     
                                    ;; 
      "*"                       )   sadm_writelog "OS Not Supported yet ($(sadm_get_osname))"
                                    ;; 
    esac
    LVSCAN=`which lvscan`                                               # LVM1 Path (RHEL 4 and Up)
    if [ $? -ne 0 ] ; then LVMVER=0 ; fi                                # If cannot locate lvscan 
    
    # If LVM Not Installed
    if [ $LVMVER -eq 0 ]                                                # lvm wasn't found on server
        then sadm_writelog "The lvm2 package is not installed"            # Advise user no lvm package
             sadm_writelog "No value running this script, Script Aborted" # No LVM - No Script
    fi
    return $LVMVER                                                      # Return LVM Version
}




#===================================================================================================
#      SAVE INFORMATION (SIZE, OWNER, GROUPS, PROTECTION, TYPE, ...) ABOUT ALL LVM ON SERVER
#===================================================================================================
#
save_lvm_info()
{
    $LVSCAN  > $SADM_TMP_FILE1 2>/dev/null                              # Run lvscan output to tmp
    
    sadm_writelog "There are `wc -l $SADM_TMP_FILE1 | awk '{ print $1 }'` Logical volume reported by lvscan"
    sadm_writelog "Output file is $DRFILE" 
    #sadm_writelog " " ; sadm_writelog " "
    

    cat $SADM_TMP_FILE1 | while read LVLINE                             # process all LV detected
        do
        if [ $Debug ] 
            then    sadm_writelog " " ; sadm_writelog "$SADM_DASH"; 
                    sadm_writelog "Processing this line              = $LVLINE"   # Display lvm line processing
        fi 

        # Get logical volume name
        LVNAME=$( echo $LVLINE |awk '{ print $2 }' | tr -d "\'" | awk -F"/" '{ print$4 }' )
        if [ $Debug ] ; then sadm_writelog "Logical Volume Name               = $LVNAME"  ; fi         

        
        # Get Volume Group Name
        VGNAME=$( echo $LVLINE | awk '{ print $2 }' | tr -d "\'" | awk -F"/" '{ print$3 }' )
        if [ $Debug ] ; then sadm_writelog "Volume Group Name                 = $VGNAME"  ; fi         

        
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
            then sadm_writelog "Logical Volume Size               = $LVFLT"
                 sadm_writelog "Logical Volume Unit Used          = $LVUNIT"
                 sadm_writelog "Calculated LV size in MB          = $LVSIZE MB"
        fi


        # Construct from LVSCAN Device the device name used in FSTAB
        LVPATH1=$(echo $LVLINE | awk '{ printf "%s ",$2 }' | tr -d "\'")
        LVPATH2="/dev/mapper/${VGNAME}-${LVNAME}"
        if [ $Debug ] 
            then sadm_writelog "LVM Device returned by lvscan     = $LVPATH1" 
                 sadm_writelog "LVM We need to find in $FSTAB = $LVPATH2" 
        fi
        
        
        # Get the Filesystem Type
        LVTYPE=`grep -iE "^${LVPATH1} |^${LVPATH2} " $FSTAB  | awk '{ print $3 }' | tr -d ' '`
        WT=`blkid /dev/mapper/${VGNAME}-${LVNAME} |awk -F= '{ print $3 }' |tr -d "\"" |tr -d " "`
        if [ "$WT" = "swap" ] || [ "$WT" = "ext4" ] || [ "$WT" = "ext3" ] || [ "$WT" = "xfs" ] || [ "$WT" = "ext2" ] 
           then LVTYPE="$WT"
        fi
        if [ $Debug ] ; then sadm_writelog "File system Type                  = ${LVTYPE}" ; fi

        
        # Get mount point from FSTAB
        if [ "$LVTYPE" = "swap" ]
           then LVMOUNT="" ; LVLEN=0
           else LVMOUNT=`grep -iE "^${LVPATH1} |^${LVPATH2} " $FSTAB  | awk '{ print $2 }'`
        fi
        if [ $Debug ] ; then sadm_writelog "Mount Point                       = $LVMOUNT" ; fi
        
        
        # Get the lenght of mount pointt
        LVLEN=${#LVMOUNT}
        if [ $Debug ] ; then sadm_writelog "Lenght of Mount Point Name        = $LVLEN" ; fi

    
        # Get Owner and Group of the Filesystem or Swap Space
        if [ "$LVTYPE" = "swap" ]
            then LVGROUP="" ; LVOWNER=""
            else LVGROUP=`ls -ld $LVMOUNT | awk '{ printf "%s", $4 }'`
                 LVOWNER=`ls -ld $LVMOUNT | awk '{ printf "%s", $3 }'`
        fi
        if [ $Debug ] 
            then sadm_writelog "Filesystem Group Owner            = $LVGROUP" 
                 sadm_writelog "Filesystem Owner                  = $LVOWNER"
        fi

    
        # Get the filesystem protection
        if [ "$LVTYPE" = "swap" ]
           then LVPROT="0000"
           else LVLS=`ls -ld $LVMOUNT`
                if [ $Debug ] ; then sadm_writelog "ls -ld returned                   = $LVLS" ; fi
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
        if [ $Debug ] ; then sadm_writelog "Filesystem Protection             = $LVPROT" ; fi


        # Write data collection in order that need to be recreated 
        echo "$LVLEN:$VGNAME:$LVMOUNT:$LVNAME:$LVTYPE:$LVSIZE:$LVGROUP:$LVOWNER:$LVPROT" >> $SADM_TMP_FILE3
        sadm_writelog "Line written to output file       = $LVLEN:$VGNAME:$LVMOUNT:$LVNAME:$LVTYPE:$LVSIZE:$LVGROUP:$LVOWNER:$LVPROT"
        done
        
    sadm_writelog " " ; sadm_writelog "$SADM_DASH";
    sadm_writelog "Backup of $DRFILE" 
    if [ -s $DRFILE ] ; then cp $DRFILE $PRVFILE ; fi                   # Make a backup of data file 

    # Sort output - Get rid of LVLEN at the same time (needed only for the sort)
    sadm_writelog "Creating a new copy of $DRFILE"
    if [ -s $SADM_TMP_FILE3 ]
        then sort -n $SADM_TMP_FILE3 | awk -F: '{ printf "%s:%s:%s:%s:%s:%s:%s:%s\n", $2,$3,$4,$5,$6,$7,$8,$9 }' >$SADM_TMP_FILE2
        else touch $SADM_TMP_FILE2
    fi 
    
    echo "# SADMIN - Filesystem Info. for system $(sadm_get_hostname).$(sadm_get_domainname)"  > $DRFILE
    echo "# File was created by sadm_fs_save_info.sh on `date`"                       >> $DRFILE
    echo "# This file is use in a Disaster Recovery situation"                        >> $DRFILE
    echo "# The data below is use by sadm_fs_recreate.sh to recreate filesystems"     >> $DRFILE
    echo "# ---------------------------------------------------------------------"    >> $DRFILE
    echo "# " >> $DRFILE
    cat  $SADM_TMP_FILE2 >> $DRFILE
    return 0
}


# --------------------------------------------------------------------------------------------------
#                                Save All Vgs Information on AIX
# --------------------------------------------------------------------------------------------------
#
save_aix_info()
{
    sadm_writelog "Information about Volume group will be store in $SADM_DR_DIR"
    SADM_EXIT_CODE=0                                                    # Start with Exit Code at 0 

    # Build a list Volume Group Excluding rootvg.
    lsvg | grep -v rootvg | while read vg
        do
        VG_LIST="$VG_LIST $vg"
        done
    if [[ $VG_LIST = "" ]]
        then sadm_writelog "nCould not find any VG to process..."
             return 1
        else sadm_writelog "This is all VGs that are detected : $VG_LIST"
    fi

    sadm_writelog "Writing Physical volume name into ${PVINFO_FILE}"
    cp /dev/null ${PVINFO_FILE}
    lspv >> ${PVINFO_FILE}

    # Get the disk usage of the VG on Disk
    for VG in $VG_LIST
        do
        sadm_writelog "Extracting used space for that VG" 
        echo "Used space for $VG: `lsvg $VG | grep USED | awk '{ print $6,$7 }'`" >>${PVINFO_FILE}
        VGDISKS="$SADM_DR_DIR/$(sadm_get_hostname)_${VG}_restvg_disks.txt"
        sadm_writelog "Save list of disks in $VG to $VGDISKS"
        lspv | grep " $VG " | awk '{ print $1 }' > $VGDISKS
        done

    # Get the disk capacity 
    lspv | grep $PVNAME | awk '{ print $1 }' | while read pv
        do
        echo "$pv:`bootinfo -s $pv`" >> $PVINFO_FILE
        done

    # Backup the VG Structure
    for vg in $VG_LIST
        do
        sadm_writelog "Verifying /etc/exclude.$vg content before backup"
        grep "^\.\*" /etc/exclude.$vg >/dev/null 2>&1
        if [ $? -eq 1 ] 
            then sadm_writelog "Adding .* in the exclude file /etc/exclude.$vg ...."
                 echo ".*" >> /etc/exclude.$vg
            else sadm_writelog " No need to modify /etc/exclude.$vg" 
        fi

        sadm_writelog "Backup the structure of $vg volume group ..."
        SAVEVGFILE="$SADM_DR_DIR/$(sadm_get_hostname)_$vg.savevg"
        savevgcommand=`echo "$SAVEVG $vg" | sed -e "s|VGDATAFILE_PLACE_HOLDER|$SAVEVGFILE|g"`
        sadm_writelog "Running : $savevgcommand" 
        $savevgcommand
        if [ $? -ne 0 ]
            then sadm_writelog "Error occured while doing the backup of Volume Group name $vg"
                 sadm_writelog "You may want to correct the error and run this script again"
                 SADM_EXIT_CODE=1
        fi
        
        sadm_writelog "Removing the line '.*' in /etc/exclude.$vg after the backup"
        grep -v "^\.\*" /etc/exclude.$vg >$SADM_TMP_FILE3
        cp $SADM_TMP_FILE3  /etc/exclude.$vg
        if [ $? -ne 0 ]
            then sadm_writelog "Error while creating the new /etc/exclude.$vg file"
                 SADM_EXIT_CODE=1
        fi
    done
    return $SADM_EXIT_CODE
}




# --------------------------------------------------------------------------------------------------
#                                     Script Start HERE
# --------------------------------------------------------------------------------------------------
    sadm_start                                                          # Init Env Dir & RC/Log File
    if ! $(sadm_is_root)                                                # Only ROOT can run Script
        then sadm_writelog "This script must be run by the ROOT user"   # Advise User Message
             sadm_writelog "Process aborted"                            # Abort advise message
             sadm_stop 1                                                # Close and Trim Log
             exit 1                                                     # Exit To O/S
    fi

    if [ $(sadm_get_ostype) = "AIX" ]                                   # For AIX O/S Save all VGs
        then save_aix_info                                              # Save All VGs Information
             SADM_EXIT_CODE=$?                                          # Save Return Code
    fi

    if [ $(sadm_get_ostype) = "LINUX" ]                                 # Operations for Linux O/S
        then check_lvm_version                                          # Get LVM Version in $LVMVER
             if [ $? -eq 0 ] ; then sadm_stop 0 ; exit 0 ; fi           # LVM Not install - Exit
             save_lvm_info                                              # Save info about all lvm's
             SADM_EXIT_CODE=$?                                          # Save Return Code
    fi

    sadm_stop $SADM_EXIT_CODE                                           # Upd. RC & Trim Log & Set RC
    exit $SADM_EXIT_CODE                                                # Exit Glob. Err.Code (0/1)
