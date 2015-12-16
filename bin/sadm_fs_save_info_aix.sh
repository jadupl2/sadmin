#!/bin/ksh
#set -x
# Script name: drnrvgs
# Platform: AIX 4.3.x
# Version: 0.1
# Author: Marco Ponton, Daniel Majeau
#
# History:
#        input list of hdisk for restvg function in progress
#
# Information:
#
#   Disaster Recovery for Non-Root Volumes Groups (drnrvgs)
#
#
#
# Prerequisites:
#
#  -  You must be root to execute this script.
#  -  A file /etc/exclude."vgname" exists and contains the line: ".*"
#  -  Have a file under $DATADIR with vgname.dr e.g. datavg.dr 
#     for restore functionality
#
# Usage:
#
#  drnrvgs [ -r ] [ -d vgdatadir ]  [ vg1 vg2 ... ] 
#
#  -r => restore
#
# Example:
#
#  # drnrvgs -r
#


############################################################
# Public variables
############################################################

DATE=`date '+%Y%m%d'`
DATETIME=`date '+%Y%m%d_%H%M'`
PLATFORM=`uname`
HOSTNAME=`hostname`
BASENAME=`basename $0`
DIRNAME=`dirname $0`
PWD=`pwd`

SAVEMODE=true
VG_LIST=

DEFAULTDATADIR="/sysadmin/bin/vgdata"
DATADIR=""
SAVEVGFILEEXT=".savevg"
SAVEVGFILE=""

PVNAME="hdisk"
EMC_PVNAME="hdiskpower"
PVINFOFILEEXT=".txt"
PVINFOFILE="pvinfo$PVINFOFILEEXT"

SAVEVG="savevg -e -i -v -fVGDATAFILE_PLACE_HOLDER"
RESTVG="restvg -q -fVGDATAFILE_PLACE_HOLDER"

YES_OR_NO_RESULT=""

TMPFILE1=/tmp/$BASENAME.$$.1.tmp
TMPFILE2=/tmp/$BASENAME.$$.2.tmp

TMPFILES="$TMPFILE1 $TMPFILE2"


############################################################
# Generic Functions
############################################################

check_platform()
{
  typeset ok="false"

  while [ "$1" != "" ]
  do
    if [ "$1" = "$PLATFORM" ]
    then
      ok="true"
      break
    fi
  done

  if [ "ok" = "false" ]
  then
    echo "\nFATAL ERROR: Unsupported platform: $PLATFORM\n"
    exit 1
  fi
}

check_root()
{
  # Verify if UID=0 (root)
  if [ `id | cut -d'=' -f2 | cut -d'(' -f1` != "0" ]
  then
    echo "\nFATAL ERROR: You MUST be root to run this script.\n"
    exit 1
  fi
}

yes_or_no()
{
  YES_OR_NO_RESULT=
  typeset question=$1
  typeset answer=""

  echo "$question (yes/no) \c"
  read answer
  while [ "$answer" != "y" -a "$answer" != "n" -a "$answer" != "yes" -a "$answer" != "no" ]
  do
    echo "Please answer the question by yes, no, y or n."
    echo "$question (yes/no) \c"
    read answer
  done
  if [ "$answer" = "y" -o "$answer" = "yes" ]
  then
    YES_OR_NO_RESULT=yes
  else
    YES_OR_NO_RESULT=no
  fi
}

dbprint()
{
  if [ "$DEBUG" = "true" ]
  then
    echo "$1"
  fi
}

fatal_error()
{
  echo "\nFATAL ERROR: $1\n"
  exit 1
}

exit_handler()
{
  # NOTE: This handler might be called twice! Watch out!

  for i in $TMPFILES
  do
    if [ -f $i ]
    then
      rm $i
    fi
  done

  exit 0
}


############################################################
# drnrvgs Functions
############################################################

usage()
{
  echo "\nUsage: $BASENAME [ -r ] [ -d vgdatadir ] [ vg1 vg2 ... ]\n"
  exit 1
}

validate_vgdatadir()
{
  if [[ ! -d $DATADIR ]]
  then
    fatal_error "Invalid VG data directory: $DATADIR"
  fi
}

validate_vgs()
{
  typeset pv


  #for pv in $VG_LIST
  #do
    ########## NOT FINISHED !!! ##########
  #done
}

build_exclude_file()
{
typeset vg

for vg in $VG_LIST
do
  echo ".*" > /etc/exclude.$vg
done
}


build_vg_list()
{
  typeset vg


  if [[ $SAVEMODE = "true" ]]
  then
    # Build VG list using lsvg
    lsvg | grep -v rootvg | while read vg
    do
      VG_LIST="$VG_LIST $vg"
    done
  else
    # Build VG list using files in DATADIR
    for vg in $DATADIR/*$SAVEVGFILEEXT
    do
      vg="${vg##*/}"
      vg="${vg%%$SAVEVGFILEEXT}"
      VG_LIST="$VG_LIST $vg"
    done
  fi

  # Remove any starting blanks
  VG_LIST="${VG_LIST##+( )}"
}

config_pv_name()
{
  if [[ `lspv | grep $EMC_PVNAME` != "" ]]
  then
    PVNAME=$EMC_PVNAME
  fi
}

save_pv_info()
{
#  set -x
  typeset pv
  typeset VG


  cp /dev/null $DATADIR/$PVINFOFILE

  lspv >>$DATADIR/$PVINFOFILE

 for VG in $VG_LIST
 do
   echo "Used space for $VG: `lsvg $VG | grep USED | awk '{ print $6,$7 }' `" >>$DATADIR/$PVINFOFILE
 done

  lspv | grep $PVNAME | awk '{ print $1 }' | while read pv
  do
    echo "$pv:`bootinfo -s $pv`" >>$DATADIR/$PVINFOFILE
  done
}



save_vgs()
{
  typeset vg
  typeset savevgcommand


  for vg in $VG_LIST
  do
    echo "INFO: Saving VG information of $vg..."
    SAVEVGFILE="$DATADIR/$vg$SAVEVGFILEEXT"
    savevgcommand=`echo "$SAVEVG $vg" | sed -e "s|VGDATAFILE_PLACE_HOLDER|$SAVEVGFILE|g"`
    $savevgcommand
  done
}

restore_vgs()
{
  typeset vg
  typeset restvgcommand

#  creer un routine pour populler  $HDISKS_PLACE_HOLDER si on veut donner l'option 
#  a l'usager sur quel disque il veut restorer

for vg in $VG_LIST
  do

  echo "INFO: Restoring VG $vg..."

  SAVEVGFILE="$DATADIR/$vg$SAVEVGFILEEXT"

  if [ -a "$DATADIR/$vg.dr" ]; then
  PVINFOFILE=`awk '{printf "%s ", $0}'<  "$DATADIR/$vg.dr`
  echo $DATADIR
  echo $DATADIR/$vg.dr
  echo $PVINFOFILE
  restvgcommand=`echo "$RESTVG" | sed -e "s|VGDATAFILE_PLACE_HOLDER|$SAVEVGFILE|g"`
  restvgcommand=`echo "$restvgcommand" $PVINFOFILE"`
  $restvgcommand
  else
    echo " Cannot find file $DATADIR/$vg.dr.  You must provide a list of hdisk for VG $vg"

 fi

done

}


############################################################
# Debug Flags
############################################################

# Main Section
#set -x

# Functions
#typeset -ft check_platform
#typeset -ft check_root
#typeset -ft yes_or_no
#typeset -ft validate_vgdatadir
#typeset -ft validate_vgs
#typeset -ft build_vg_list
#typeset -ft config_pv_name
#typeset -ft save_pv_info
#typeset -ft save_vgs
#typeset -ft restore_vgs


############################################################
# Main Section
############################################################

# Trap SIGHUP (do nothing)
trap '' HUP

# Trap SIGEXIT SIGINT and SIGTERM and do clean exit
# NOTE: Normally, only EXIT should be required but on AIX the script
#       can die when calling certain programs (like kill) if stopped
#       using CTRL-C and only SIGEXIT is trapped...
trap 'exit_handler' EXIT INT TERM

echo "\nDisaster Recovery for Non-Root VGs\n"

# Check for any options
ARGS=$*
while getopts :rd: OPT $ARGS
do
  case $OPT in
    r) SAVEMODE=false
       shift
    ;;
    d) DATADIR=$OPTARG
       shift
       shift
    ;;
    *) usage
    ;;
  esac
done
VG_LIST="$*"

check_platform AIX
check_root

if [[ $SAVEMODE = "true" ]]
then
  echo "INFO: Using SAVE mode"
else
  echo "INFO: Using RESTORE mode"
fi

if [[ $DATADIR = "" ]]
then
  # Use default data directory
  DATADIR=$DEFAULTDATADIR
  echo "INFO: Using default VG data directory: $DATADIR"
else
  if [[ ${DATADIR%%/*} != "" ]]
  then
    # Path does not begin with a "/", assume current working directory + path
    DATADIR=$PWD/$DATADIR
    echo "INFO: Using VG data directory: $DATADIR"
  fi
fi

validate_vgdatadir

if [[ $VG_LIST != "" ]]
then
  validate_vgs
else
  build_vg_list
  if [[ $VG_LIST = "" ]]
  then
    fatal_error "Could not find any VG to process..."
  fi
fi

echo "INFO: VGs to be processed: $VG_LIST"
echo "INFO: Creating exclude files...."

build_exclude_file

config_pv_name

if [[ $PVNAME = $EMC_PVNAME ]]
then
  echo "INFO: Using hdiskpower physical volumes"
fi

if [[ $SAVEMODE = "true" ]];
then
  echo "INFO: Saving physical volumes information..."
  save_pv_info
  save_vgs
  df -k | awk '{print $7}' | sed "s/\///g" | sed "s/^/\//g"| sort > $DEFAULTDATADIR/df_sorted.txt
else
  restore_vgs
fi

exit 0
