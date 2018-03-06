#! /bin/sh
#---------------------------------------------------------------------------------------------------
# Title      :  tsm_sessions.sh - Script Gets Number of TSM sessions used and update rrd
# Version    :  1.2
# Author     :  Jacques Duplessis 
# Date       :  2012-04-20
# Requires   :  ksh
# SCCS-Id.   :  @(#) tsm_sessions.sh 1.1 
#---------------------------------------------------------------------------------------------------
#set -x 

# --------------------------------------------------------------------------------------------------
#                   Program  Variables Definitions
# --------------------------------------------------------------------------------------------------
PN=${0##*/}                                 	; export PN         # Program name
VER='2.0'                                   	; export VER        # Program version
BASE_DIR="/sysinfo"                             ; export BASE_DIR  	# Base Directories
RRDTOOL="/usr/bin/rrdtool"                      ; export RRDTOOL   	# Location of rrdtool
EPOCH="${BASE_DIR}/bin/epoch"                   ; export EPOCH     	# Location of epoch pgm.
RRD_DIR="$BASE_DIR/www/rrd/tsm"                 ; export RRD_DIR   	# Dir.  were rrd reside
RRD_FILE="${RRD_DIR}/tsm_sessions.rrd"  		; export RRD_FILE  	# RRD File
GIFDIR="${BASE_DIR}/www/images/tsm"             ; export GIFDIR    	# Where Gif Are generated
TSMDATA="${BASE_DIR}/tmp/sessions.txt"	        ; export TSMDATA   	# TSM Data collected
DASH="========================================"                     # 40 dashes
DASH="${DASH}========================================"              # 80 dashes

#---------------------------------------------------------------------------------------------------
# Function to Create the RRD Database
#---------------------------------------------------------------------------------------------------
create_rrd() {
	echo -e "Creating Round Robin Database for TSM Drive ($RRD_FILE)"
#               --start "00:00 01.01.2010"       \
#               --step 300                       \
	$RRDTOOL create $RRD_FILE                   \
                --start N --step 300            \
               DS:session:GAUGE:600:1:600         \
               RRA:MAX:0.5:1:210240
#               RRA:AVERAGE:0.5:1:210240
    
    chmod 664 $RRD_FILE
    chown apache.apache $RRD_FILE
}


# Calculate the Value to put in the RRD File
#---------------------------------------------------------------------------------------------------
echo -e "\n${DASH}\nScript : ${PN} Starting at `date`\nCalculate Number of TSM Session Active"
export RRD_VALUE=` dsmadmc -ID=query -PA=query  "q ses " | grep -i tcp | wc -l`
let "RRD_VALUE = (${RRD_VALUE} + 0)"

  
# If RRD Directory doesn't exist - then create it
#---------------------------------------------------------------------------------------------------
if [ ! -d $RRD_DIR ]
   then echo -e "\nDirectory $RRD_DIR was not found, it is now created"
        mkdir $RRD_DIR
        chmod 775 $RRD_DIR
        chown apache.apache $RRD_DIR
fi


# If RRD file doesn't exist, Create it 
#---------------------------------------------------------------------------------------------------
echo -e "RRD Value calculated ...$RRD_VALUE..." 				    # Display Value
if [ ! -w $RRD_FILE ] ; then create_rrd ; fi						# Create RRD File if not exist	


# Update the RRD File
#---------------------------------------------------------------------------------------------------
WYEAR=`date +%Y` ; WMONTH=`date +%m` ; WDAY=`date +%d`      		# Date of the RRD Update
WHRS=`date +%H`  ; WMIN=`date +%M`   ; WSEC=`date +%S`        		# Time of the RRD Update
TIME_STAMP=`$EPOCH "$WYEAR $WMONTH $WDAY $WHRS $WMIN $WSEC"`		# Current time Stamp in Epoch
echo "$RRDTOOL update $RRD_FILE  ${TIME_STAMP}:${RRD_VALUE}"		# Display Update Command
$RRDTOOL update $RRD_FILE  ${TIME_STAMP}:${RRD_VALUE}				# Update RRD File

echo -e "${PN} Ended at `date`\n${DASH}"							# EOF

