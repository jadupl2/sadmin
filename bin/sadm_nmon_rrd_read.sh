# --------------------------------------------------------------------------------------------------
# This script will allow you to display data from an rrd.
# January 2018 - Jacques Duplessis
# Version 1.0
# Enter name of the file + Start Data and time + End date and timek
# Example : 
# sadm_nmon_read.sh /sadmin/www/rrd/holmes/holmes.rrd "00:00 19.01.2018" "23:50 19.01.2018"
# 
# 2018_01_23 J.Duplessis
# V1.0 Initial Version Show RRD Content
#
# --------------------------------------------------------------------------------------------------
#set -x

# Make sure RRD Tools is present
# --------------------------------------------------------------------------------------------------
    RRDTOOL=`which rrdtool 2>/dev/null` ; export RRDTOOL                # Get Location of rrdtool
    if [ $? -ne 0 ]                                                     # Command rrdtool Not Avail.
        then echo "Script aborted : rrdtool command not found"          # Show User Error
             exit 1                                                     # Exit To O/S
    fi
    
    #echo "What is the name of the RRD File :\b" ; read RRD_FILE
    RRD_FILE=$1
	if [ ! -e $RRD_FILE ]
        then echo "The Round Robin Database ($RRD_FILE) does not exist"
             echo "Process aborted"
             exit 1
    fi

    #echo "Enter Start Date in this format (23:50 30.01.2002) :\b" ; read STARTDATE
    #echo "Enter End Date in this format   (23:50 30.01.2002) :\b" ; read ENDDATE
    STARTDATE=$2
    ENDDATE=$3
    
    echo "$RRDTOOL fetch $RRD_FILE MAX -r 60 -s $STARTDATE -e $ENDDATE"
    $RRDTOOL fetch $RRD_FILE MAX -r 60 -s "$STARTDATE" -e "$ENDDATE"

    echo "Date and time of last sample in $RRD_FILE"
    $RRDTOOL last $RRD_FILE
