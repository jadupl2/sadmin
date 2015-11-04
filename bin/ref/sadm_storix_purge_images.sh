#!/bin/sh
# --------------------------------------------------------------------------------------------------
#   Author:     Jacques Duplessis
#   Title:      clean_storix_images.sh - House cleaning of Storix Backup file
#   Date:       15 May 2014
#   Synopsis:   This script is run daily to keep only two copies on each
#                                                               storix image backup.
# --------------------------------------------------------------------------------------------------
#set -x

# --------------------------------------------------------------------------------------------------
#                                   Program Variables Definitions
# --------------------------------------------------------------------------------------------------
PN=${0##*/}                                         ; export PN                 # Program name
VER='1.9'                                           ; export VER                # Program version
INST=`echo "$PN" | awk -F\. '{ print $1 }'`         ; export INST               # Get Current script name
SYSADMIN="duplessis.jacques@gmail.com"              ; export SYSADMIN           # Sysadmin email#!/bin/sh
BASE_DIR="/sadmin"                                  ; export BASE_DIR
LOG_FILE="${BASE_DIR}/log/${INST}.log"              ; export LOG_FILE
STORIX_IMAGES_DIR="/backup/storix"                  ; export STORIX_IMAGES_DIR  # Location if Storix Image
DASH=`printf %100s |tr " " "="`                     ; export DASH               # 100 dashes line
HOSTNAME=`hostname -s`                              ; export HOSTNAME           # Current Host name


echo "${DASH}"
start=`date "+%C%y.%m.%d %H:%M:%S"`
echo "Starting the script $PN on - ${HOSTNAME} - ${start}"
echo "Keep only the two last copies of each server images ..."
echo "${DASH}"



# Build a list of hostname that have a backup in $STORIX_IMAGES_DIR
# --------------------------------------------------------------------------------------------------
cd $STORIX_IMAGES_DIR
ls -1 *:TOC:* | cut -d: -f4 | sort -u | while read stclient
  do
  echo "\n\n==========\nListing Backup of ${stclient} before cleanup ..."
  ls -1t *${stclient}*TOC* | nl

  # List the Table Of Content File for the selected client.
  ls -1t *${stclient}*TOC* | sed '1,2d' | cut -d: -f5 | while read backupid
    do
      echo "-----\nDeleting backup ID #$backupid of server $stclient ..."
      ls -1 *:$stclient:$backupid:* | while read backup_file
            do
            echo "Deleting file $backup_file ..."
            ls -l $backup_file
            rm -f $backup_file
            done
    done

  echo "-----\nListing Backup after cleanup ..."
  ls -1t *${stclient}*TOC* | nl
  done
