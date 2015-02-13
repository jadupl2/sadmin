#! /bin/bash
##########################################################################
# Shellscript:	drrestvg.sh - Recovery VG filesystem in case of Disaster
# Version    :	1.5
# Author     :	jacques duplessis (jack.duplessis@standardlife.ca)
# Date       :	2010-04-14
# Requires   :	bash shell - lvm installed
# Category   :	disaster tools
# SCCS-Id.   :	@(#) drrestvg.sh 1.2 2010.04.14
##########################################################################
# Description
#
# Note
#    o this script restore the filesystem of the selected vg's . 
#    o run this script and specify the vg you want to restore
#    o This script read it input from the file $SYSADM/drsavevg.dat
#
##########################################################################
#set -x
PN=${0##*/}	            		; export PN         # Program name
VER='1.5'                       ; export VER        # program version
tput clear 
echo -e "Program $PN - Version $VER - `date`"


# Global Variables
# -------------------------------------------------------------------------------------
NOW=`date +"%Y_%m_%d_%H_%M_%S"`
SAM="/sysadmin/sam"             ; export SAM        # where reside pgm & data
DRFILE=$SAM/drsavevg.dat        ; export DRFILE     # Input file of program
DRSCRIPT="/tmp/drrestvg.$NOW.sh"; export DRSCRIPT   # Restore Script 
WTMP=/tmp/drrestvg_tmp.$$       ; export WTMP       # temporary work file
#DEBUG=true                     ; export DEBUG      # When true more verbose
WLOG="/tmp/drrestvg.$NOW.log"   ; export WLOG       # Program Log file
HOSTNAME=`hostname`             ; export HOSTNAME   # Server name
DSMC="/usr/bin/dsmc"            ; export DSMC       # dsmc pgm location
REST_CMD="$DSMC restore -replace=all -subdir=yes -ifnewer " # dsmc restore cmd
TEST_CMD="$DSMC q sched"        ; export TEST_CMD   # Test TSM connectivity cmd
VGLIST="/tmp/drrestvg.vg.$NOW.txt" ; export VGLIST  # List of VG to restore
DLINE="========================================"
HLINE="${DLINE}${DLINE}"


# Populate Basic Code in the final script
# -------------------------------------------------------------------------------------
echo -e "#! /bin/bash" > $DRSCRIPT                     
echo -e "WLOG=\"/tmp/drrestvg.$NOW.log\"" >> $DRSCRIPT
echo -e "DSMC=\"/usr/bin/dsmc\"  ; export DSMC"  >> $DRSCRIPT
echo -e "REST_CMD=\"\$DSMC restore -replace=all -subdir=yes -ifnewer\""  >> $DRSCRIPT
echo -e "#REST_CMD=\"\$DSMC restore -replace=all -subdir=yes -ifnewer -virtualnode=lxmq1033 -password=xxx /cadmin/\"\n"  >> $DRSCRIPT
#echo -e "DLINE=\"========================================\"" >> $DRSCRIPT
#echo -e "HLINE=\"\${DLINE}\${DLINE}\"" >> $DRSCRIPT
#echo -e \" \" >> $DRSCRIPT
#echo -e "# Restore filesystem function" >> $DRSCRIPT
#echo -e "restore_filesystem() " >> $DRSCRIPT
#echo -e "{" >> $DRSCRIPT
#echo -e "	if [ \$# -ne 3 ]" >> $DRSCRIPT  
#echo -e "	   then echo \"Error - Invalid number of Parameter - \$*\"" >> $DRSCRIPT
#echo -e "	        return 1" >> $DRSCRIPT
#echo -e "       fi" >> $DRSCRIPT
#echo -e "	FSNAME=\$1 ; FSNO=\$2 ; FSTOTAL=\$3" >> $DRSCRIPT
#echo -e "        echo -e "\"\n\${HLINE}" >>\$WLOG\"" >> $DRSCRIPT
#echo -e "	echo -e \"Restore \$FSNO of \$FSTOTAL - \$FSNAME started at `date`\" >>\$WLOG" >> $DRSCRIPT
#echo -e "	echo -e \"\${HLINE}\" >>\$WLOG" >> $DRSCRIPT
#echo -e "	echo -e \"\$REST_CMD \${FSNAME}/ >/dev/null 2>&1\" >>\$WLOG" >> $DRSCRIPT
#echo -e "	\$REST_CMD \${FSNAME}/ >>/dev/null 2>&1" >> $DRSCRIPT
#echo -e "	RC1=\$? ; RC2=\$RC1" >> $DRSCRIPT
#echo -e "	if [ \$RC1 -eq 4 ] || [ \$RC1 -eq 8 ] ; then RC2=0 ; fi" >> $DRSCRIPT
#echo -e "	if [ \$RC2 -ne 0 ]" >> $DRSCRIPT
#echo -e "	   then echo -e \"Restore of \$FSNAME - Error \$RC2\" >> \$WLOG" >> $DRSCRIPT
#echo -e "                RC=1" >> $DRSCRIPT
#echo -e "	   else echo -e \"Restore of \$FSNAME - Success ($RC1)\"  >> \$WLOG" >> $DRSCRIPT
#echo -e "                RC=0" >> $DRSCRIPT
#echo -e "	fi" >> $DRSCRIPT
#echo -e "	echo -e \"Restore of \$FSNAME ended at `date`\n\" >>\$WLOG" >> $DRSCRIPT
#echo -e "       return \$RC" >> $DRSCRIPT
#echo -e "}" >> $DRSCRIPT
#echo -e "\n\n" >> $DRSCRIPT


# Verify that input data file exist
# -------------------------------------------------------------------------------------
if [ ! -r "$DRFILE" ]
   then echo "The input file $DRFILE does not exist !"
        echo "Process aborted"
        exit 1
fi



# Verify that TSM Program is executable and exist
# -------------------------------------------------------------------------------------
if [ ! -x "$DSMC" ]
   then echo "The TSM restore program $DSMC does not exist !"
        echo "Process aborted"
        exit 1
fi



# -------------------------------------------------------------------------------------
# Function to check connectivity with TSM Server - Before starting the restore
# -------------------------------------------------------------------------------------
test_connectivity()
{
    echo -n "Testing TSM Server connection"
    $TEST_CMD >/dev/null 2>&1
    RC=$?
    if [ $RC -ne 0 ] && [ $RC -ne 8 ]
       then echo " FAILED " 
            echo "Error : $RC - \"$TEST_CMD\" command failed !" 
            echo -e "        Process aborted !\n"  
            return 1
       else echo -e " OK " 
            return 0
    fi
}

# -------------------------------------------------------------------------------------
#                 M A I N    P R O G R A M    S T A R T    H E R E  
# -------------------------------------------------------------------------------------

# Try to run dsmc q sched to test connectivity with TSM
test_connectivity
if [ $? -ne 0 ] ; then exit 1 ; fi


# Accept the volume group that we need to create to restore
touch $VGLIST
while : 
   do 
   awk -F: '{ print $1 }' $DRFILE | sort | uniq > $WTMP
   echo -e "\n==============================================================================="
   echo "These are the VG that are present in $DRFILE :" 
   cat $WTMP
   echo -e "==============================================================================="
   echo "These are the VG you selected to restore :" 
   cat $VGLIST
   echo -e "==============================================================================="
   echo -e "Enter the VG that you want to restore the filesystems [d=done] : \c" 
   read WVG
   if [ "$WVG" = "d" ] || [ "$WVG" = "D" ] ; then break ; fi
   grep -i $WVG $WTMP > /dev/null
   if [ $? -eq 0 ] 
      then grep $WVG $VGLIST >/dev/null 2>&1 
           if [ $? -eq 0 ] 
              then echo "*** Warning : The VG $WVG is already selected - selection ignore" 
                   sleep 1
              else echo "$WVG" >> $VGLIST
           fi
      else echo -e "\n\aVG $WVG not found in $DRFILE - Press [RETURN] and choose another." 
           read dummy
   fi
   done


# Confirmation before creating the script
while : 
   do 
   echo -e "==============================================================================="
   echo -e "Proceed with creating the restore script for selected VG(s) [Y/N]? \c" 
   read answer
   if [ "$answer" = "Y" ] || [ "$answer" = "y" ] 
      then answer="Y" ; break
      else echo "Please re-run the script" ; exit 1
   fi
   done


# Create the script that will be launched
echo -e "==============================================================================="
echo -e "Counting the number of filesystem to restore ... "
TOTAL=0 
export TOTAL
while read VG 
    do 
      grep "^${VG}:" $DRFILE > $WTMP 
      while read wline
          do 
	    TOTAL=$((${TOTAL}+1))	
          done < $WTMP
    done < $VGLIST

# Create the script that will be launched
echo -e "Building the restore script ... "
COUNT=0
while read VG 
    do 
      echo "Processing $VG"
      grep "^${VG}:" $DRFILE > $WTMP 
      while read wline
          do 
	  COUNT=$((${COUNT}+1))
          FS=`echo $wline | awk -F: '{ print $2 }'` 
          echo -e "echo -e \"\\\n${HLINE}\" >>\$WLOG" >>$DRSCRIPT
          echo -e "echo -e \"Restore $COUNT of $TOTAL - $FS started at \`date\`\" >>\$WLOG" >>$DRSCRIPT
          echo -e "echo -e \"${HLINE}\" >>\$WLOG" >>$DRSCRIPT
          echo -e "echo -e \"\$REST_CMD \"$FS/?*\" >/dev/null 2>&1\" >>\$WLOG" >>$DRSCRIPT
          #echo -e "\$REST_CMD '$FS/?*' >>/dev/null 2>&1" >> $DRSCRIPT
          echo -e "\$REST_CMD \"$FS/?*\"" >> $DRSCRIPT
          echo -e "RC1=\$? ; RC2=\$RC1" >> $DRSCRIPT
          echo -e "if [ \$RC1 -eq 4 ] || [ \$RC1 -eq 8 ] ; then RC2=0 ; fi" >> $DRSCRIPT
          echo -e "if [ \$RC2 -ne 0 ] " >> $DRSCRIPT
          echo -e "   then echo -e \"Restore of $FS - Error \$RC2\" >> \$WLOG" >> $DRSCRIPT
          echo -e "   else echo -e \"Restore of $FS - Success (\$RC1)  \"  >> \$WLOG" >> $DRSCRIPT
          echo -e "fi" >> $DRSCRIPT
          echo -e "echo -e \"Restore of $FS ended at \`date\`\\\n\" >>\$WLOG\n" >>$DRSCRIPT
          done < $WTMP
    done < $VGLIST
    echo -e "echo -e \"The script is now finished - \`date\`\\\n\" >>\$WLOG\n" >>$DRSCRIPT



# Accept final confirmation 
chmod +x $DRSCRIPT
while : 
   do 
   echo -e "==============================================================================="
   echo -e "I am now ready to start the restore script \"$DRSCRIPT\""
   echo -e "You can monitor the restore by looking at the log \"$WLOG\""
   echo -e "The script will be launch as a background process"
   echo -e "==============================================================================="
   echo -e "Do you still want me to start the restore script in the background [Y/N] ? \c" 
   read answer
   if [ "$answer" = "Y" ] || [ "$answer" = "y" ] 
      then echo "The script has been started in the background" 
           echo $DRSCRIPT | at now 
           exit 0
      else echo "The script has not being launch" ; exit 1
   fi
   done

# End of program.
echo -e "Program $PN - Version $VER - Ended `date`"
