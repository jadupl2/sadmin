#! /bin/bash
##########################################################################
# Shellscript:  drsavevg.sh - Recreate filesystem in case of Disaster
# Version    :  1.5
# Author     :  jacques duplessis (jack.duplessis@standardlife.ca)
# Date       :  2005-10-09
# Requires   :  bash shell - lvm installed
# Category   :  disaster tools
# SCCS-Id.   :  @(#) drsavevg.sh 1.2 05.10.09
##########################################################################
# Description
#
# Note
#    o this script collect all data necessary to recreate all filesystems
#      present of the system.
#    o run this script once a day via the cron
#    o the output of this script is a text file named $SYSADM/drsavevg.dat
#
# Apr 2010 - 1.5 Modify to create a backup of drsavevg.dat to drsavevg.prev
#            before creating a new one.
##########################################################################
#set -x
PN=${0##*/}       		; export PN     	# Program name
VER='1.5'                       ; export VER    	# Program version
echo -e "Program $PN - Version $VER - Starting `date`"

SYSADM=/sysadmin/sam            ; export SYSADM 	# where reside pgm & data
WFILE=/tmp/drsavevg.$$          ; export WFILE  	# temporary work file
DRFILE=$SYSADM/drsavevg.dat     ; export DRFILE 	# Output file of program
PRVFILE=$SYSADM/drsavevg.prev   ; export PRVFILE 	# Output file of Yesterday
DRSORT=$SYSADM/drsavevg.srt     ; export DRSORT 	# Output sorted by mnt len
WFILE=/tmp/drsavevg.$$          ; export WFILE  	# temporary work file
WTMP=/tmp/drsavevg_tmp.$$       ; export WTMP   	# temporary work file
WTMP2=/tmp/drsavevg_tmp2.$$     ; export WTMP2  	# temporary work 2 file
DSMC="dsmc "                    ; export DSMC      	# dsmc (-virtual?)
DSMC_CMD="$DSMC restore -replace=all -subdir=yes -ifnewer " ; export DSMC_CMD
WLOG="/tmp/drrestore_$$.log"    ; export WLOG      	# Output file of program
#Debug=false
Debug=true

# Make a backup of data file before creating new one
# ------------------------------------------------------------------------------
if [ -s $DRFILE ] ; then cp $DRFILE $PRVFILE ; fi



# Determine if we are using lvm1 or lvm2
# ------------------------------------------------------------------------------
LVMVER=1                       ; export LVMVER  # Assume lvm1 by default
rpm -q lvm2 > /dev/null 2>&1                    # Is lvm2 installed ?
RC=$?                                           # RC = 0 = yes lvm2
if [ $RC -eq 0 ] ; then LVMVER=2 ; fi           # lvm2 install set lvm2 on
if [ $Debug ] ; then echo "We are using LVM version $LVMVER" ; fi

if [ $LVMVER -eq 2 ]
   then LVSCAN=`which lvscan`
   else LVSCAN="/sbin/lvscan"
fi


# Make sure the output and work file does not exist
# ------------------------------------------------------------------------------
rm -f $DRFILE >/dev/null 2>&1
rm -f $WFILE  >/dev/null 2>&1
rm -f $WTMP   >/dev/null 2>&1
rm -f $WTMP2  >/dev/null 2>&1

# collect logical volume data & save it to work file
# ------------------------------------------------------------------------------
$LVSCAN | /bin/grep "\["  > $WFILE


# process all logical volume detected
# ------------------------------------------------------------------------------
cat $WFILE | while read LVLINE
    do

    # in debug mode display lvscan line we are processing
    if [ $Debug ] ; then echo -e "\nLVLINE  = $LVLINE" ; fi


    # get logical volume name
    if [ $LVMVER -eq 2 ]
       then LVNAME=$( echo $LVLINE | awk '{ print $2 }' | tr -d "\'" | awk -F"/" '{ print$4 }' )
       else LVNAME=$( echo $LVLINE | awk '{ print $4 }' | tr -d "\"" | awk -F"/" '{ print$4 }' )
    fi
    if [ $Debug ] ; then echo "LVNAME  = $LVNAME" ; fi


    # get volume group name
    if [ $LVMVER -eq 2 ]
       then VGNAME=$( echo $LVLINE | awk '{ print $2 }' | tr -d "\'" | awk -F"/" '{ print$3 }' )
       else VGNAME=$( echo $LVLINE | awk '{ print $4 }' | tr -d "\"" | awk -F"/" '{ print$3 }' )
    fi
    if [ $Debug ] ; then echo "VGNAME  = $VGNAME" ; fi


    # get logical volume size
    if [ $LVMVER -eq 2 ]
       then LVWS1=$( echo $LVLINE | awk -F'[' '{ print $2 }' )
            LVWS2=$( echo $LVWS1  | awk -F']' '{ print $1 }' )
            LVFLT=$( echo $LVWS2 | awk '{ print $1 }' )
            LVUNIT=$(  echo $LVWS2 | awk '{ print $2 }' )
            if [ $LVUNIT = "GB" ] || [ $LVUNIT = "GiB" ] 
               then LVINT=`echo "$LVFLT * 1024" | /usr/bin/bc  | awk -F'.' '{ print $1 }'`
                    LVSIZE=$LVINT
               else LVINT=$( echo $LVFLT | awk -F'.' '{ print $1 }' )
                    LVSIZE=$LVINT
            fi
       else LVWS1=$( echo $LVLINE | awk -F'[' '{ print $2 }' )
            LVWS2=$( echo $LVWS1  | awk -F']' '{ print $1 }' )
            LVFLT=$( echo $LVWS2 | awk '{ print $1 }' )
            LVUNIT=$(  echo $LVWS2 | awk '{ print $2 }' )
            if [ $LVUNIT = "GB" ] || [ $LVUNIT = "GiB" ] 
               then LVINT=`echo "$LVFLT * 1024" | /usr/bin/bc  | awk -F'.' '{ print $1 }'`
                    LVSIZE=$LVINT
               else LVINT=$( echo $LVFLT | awk -F'.' '{ print $1 }' )
                    LVSIZE=$LVFLT
            fi
    fi
    if [ $Debug ] ; then echo "LVFLT   = $LVFLT" ; echo "LVUNIT  = $LVUNIT" ; echo "LVSIZE  = $LVSIZE MB" ; fi


    # get mount point
    if [ $LVMVER -eq 2 ]
       then LVPATH1=$(echo $LVLINE | awk '{ printf "%s ",$2 }' | tr -d "\'")
       else LVPATH1=$(echo $LVLINE | awk '{ printf "%s ",$4 }' | tr -d "\"")
    fi
    LVPATH2="/dev/mapper/${VGNAME}-${LVNAME}"
    if [ $Debug ] ; then echo "LVPATH1  = $LVPATH1" ; fi
    if [ $Debug ] ; then echo "LVPATH2  = $LVPATH2" ; fi
    LVTYPE=`grep -iE "^${LVPATH1} |^${LVPATH2} " /etc/fstab  | awk '{ print $3 }'`
    if [ $Debug ] ; then echo "LVTYPE  = $LVTYPE" ; fi

    if [ "$LVTYPE" = "swap" ]
       then LVMOUNT="" ; LVLEN=0
    else
       LVMOUNT=`grep -iE "^${LVPATH1} |^${LVPATH2} " /etc/fstab  | awk '{ print $2 }'`
       if [ $Debug ] ; then echo "LVMOUNT = $LVMOUNT" ; fi
       LVLEN=${#LVMOUNT}
       if [ $Debug ] ; then echo "LVLEN   = $LVLEN" ; fi
    fi

    # get owner and group of filesystem
    if [ "$LVTYPE" = "swap" ]
       then LVGROUP="" ; LVOWNER=""
    else
       LVOWNER=`ls -ld $LVMOUNT | awk '{ printf "%s", $3 }'`
       LVGROUP=`ls -ld $LVMOUNT | awk '{ printf "%s", $4 }'`
    fi
    if [ $Debug ] ; then echo "LVGROUP = $LVGROUP" ; echo "LVOWNER = $LVOWNER" ; fi

    # Get filesystem protection
    if [ "$LVTYPE" = "swap" ]
       then LVPROT="0000"
    else
       LVLS=`ls -ld $LVMOUNT`
       if [ $Debug ] ; then echo "LVLS    = $LVLS" ; fi
       user_bit=0 ; group_bit=0 ; other_bit=0 ; stick_bit=0
       if [ `echo $LVLS | awk '{ printf "%1s", substr($1,2,1) }'`   = "r" ] ; then user_bit=`expr $user_bit + 4`   ; fi
       if [ `echo $LVLS | awk '{ printf "%1s", substr($1,3,1) }'`   = "w" ] ; then user_bit=`expr $user_bit + 2`   ; fi
       if [ `echo $LVLS | awk '{ printf "%1s", substr($1,4,1) }'`   = "x" ] ; then user_bit=`expr $user_bit + 1`   ; fi
       if [ `echo $LVLS | awk '{ printf "%1s", substr($1,4,1) }'`   = "s" ] ; then user_bit=`expr $user_bit + 1`   ; fi
       if [ `echo $LVLS | awk '{ printf "%1s", substr($1,4,1) }'`   = "s" ] ; then stick_bit=`expr $stick_bit + 4` ; fi

       if [ `echo $LVLS | awk '{ printf "%1s", substr($1,5,1) }'`   = "r" ] ; then group_bit=`expr $group_bit + 4` ; fi
       if [ `echo $LVLS | awk '{ printf "%1s", substr($1,6,1) }'`   = "w" ] ; then group_bit=`expr $group_bit + 2` ; fi
       if [ `echo $LVLS | awk '{ printf "%1s", substr($1,7,1) }'`   = "x" ] ; then group_bit=`expr $group_bit + 1` ; fi
       if [ `echo $LVLS | awk '{ printf "%1s", substr($1,7,1) }'`   = "s" ] ; then group_bit=`expr $group_bit + 1` ; fi
       if [ `echo $LVLS | awk '{ printf "%1s", substr($1,7,1) }'`   = "s" ] ; then stick_bit=`expr $stick_bit + 2` ; fi

       if [ `echo $LVLS | awk '{ printf "%1s", substr($1,8,1) }'`   = "r" ] ; then other_bit=`expr $other_bit + 4` ; fi
       if [ `echo $LVLS | awk '{ printf "%1s", substr($1,9,1) }'`   = "w" ] ; then other_bit=`expr $other_bit + 2` ; fi
       if [ `echo $LVLS | awk '{ printf "%1s", substr($1,10,1) }'`  = "x" ] ; then other_bit=`expr $other_bit + 1` ; fi
       if [ `echo $LVLS | awk '{ printf "%1s", substr($1,10,1) }'`  = "t" ] ; then other_bit=`expr $other_bit + 1` ; fi
       if [ `echo $LVLS | awk '{ printf "%1s", substr($1,10,1) }'`  = "t" ] ; then stick_bit=`expr $stick_bit + 1` ; fi
       LVPROT="${stick_bit}${user_bit}${group_bit}${other_bit}"
    fi
    if [ $Debug ] ; then echo "LVPROT  = $LVPROT" ; fi


    # write data collection - make sure filesystem are in order that need to be recreated
    echo "$LVLEN:$VGNAME:$LVMOUNT:$LVNAME:$LVTYPE:$LVSIZE:$LVGROUP:$LVOWNER:$LVPROT" >> $WTMP
    echo "$LVLEN:$VGNAME:$LVMOUNT:$LVNAME:$LVTYPE:$LVSIZE:$LVGROUP:$LVOWNER:$LVPROT" >> $WTMP2
    done

# Sort output - Get rid of LVLEN at the same time (needed to sort)
sort -n $WTMP | awk -F: '{ printf "%s:%s:%s:%s:%s:%s:%s:%s\n", $2,$3,$4,$5,$6,$7,$8,$9 }' > $DRFILE

# Created file sorted by lenght character of mount point
sort -rn $WTMP2 | awk -F: '{ printf "%s:%s:%s:%s:%s:%s:%s:%s\n", $2,$3,$4,$5,$6,$7,$8,$9 }' > $DRSORT


# Remove Temporary files
rm -f $WTMP  >/dev/null 2>&1
rm -f $WTMP2 >/dev/null 2>&1

# End of program
echo -e "Program $PN - Version $VER - Ended `date`"
