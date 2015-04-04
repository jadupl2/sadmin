#!/bin/sh
# --------------------------------------------------------------------------------------------------
#   Author:     Jacques Duplessis
#   Title:      clean_storix_images.sh - House cleaning of Storix Backup file
#   Date:       15 May 2014
#   Synopsis:   This script is run daily to keep only two copies on each 
#								storix image backup.
# --------------------------------------------------------------------------------------------------
#set -x 

# --------------------------------------------------------------------------------------------------
#                                   Program Variables Definitions
# --------------------------------------------------------------------------------------------------
PN=${0##*/}                                         ; export PN 	        # Program name
VER='1.8'                                           ; export VER          	# Program version
INST=`echo "$PN" | awk -F\. '{ print $1 }'`         ; export INST         	# Get Current script name
SYSADMIN="aixteam@standardlife.ca"             	    ; export SYSADMIN	    # Sysadmin email#!/bin/sh
SYSADMIN="duplessis.jacques@gmail.com"              ; export SYSADMIN	   	# Sysadmin email#!/bin/sh
BASE_DIR="/sadmin"				                    ; export BASE_DIR
LOG_FILE="${BASE_DIR}/log/${INST}.log"      	    ; export LOG_FILE
STORIX_IMAGES_DIR="/stbackups/images"       	    ; export STORIX_IMAGES_DIR  # Location if Storix Image
DASH=`printf %100s |tr " " "="`                     ; export DASH           	# 100 dashes line



# Build a list of hostname that have a backup in $STORIX_IMAGES_DIR
# --------------------------------------------------------------------------------------------------
cd $STORIX_IMAGES_DIR
ls -1 *:TOC:* | cut -d: -f4 | sort -u | while read stclient
  do
  echo -e "\n\n==========\nListing Backup of ${stclient} before cleanup ..."
  ls -1t *${stclient}*TOC* | nl
  echo -e "-----\nKeep only the two last copies of images for server $stclient ..."

  # List the Table Of Content File for the selected client.
  ls -1t *${stclient}*TOC* | sed '1,2d' | cut -d: -f5 | while read backupid
    do
      echo -e "-----\nDeleting backup ID #$backupid of server $stclient ..."
      ls -1 *:$stclient:$backupid:* | while read backup_file
            do
            echo "Deleting file $backup_file ..."
            ls -l $backup_file
            rm -f $backup_file
            done
    done
	echo -e "-----\nListing Backup after cleanup ..."
  ls -1t *${stclient}*TOC* | nl
  done
#
exit 0
