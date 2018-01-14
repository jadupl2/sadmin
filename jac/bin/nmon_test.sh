#!/bin/sh
# --------------------------------------------------------------------------------------------------
#set -x
    RRDTOOL=`type rrdtool | awk '{ print $3 }'` ; export RRDTOOL   	        # Location of rrdtool
    RRD_OWNER="jadupl2"                         ; export RRD_OWNER          # RRD Dir. & File Owner Name
    RRD_GROUP="apache"                          ; export RRD_GROUP          # RRD Dir. & File Group Name
    RRD_FILE_PERM="664"                         ; export RRD_FILE_PROT      # RRD File Permission
    RRD_DIR_PERM="775"                          ; export RRD_DIR_PROT       # RRD Dir Permission
    DEBUG=0                                     ; export DEBUG              # Enable/Disable Debug Output

    RRD_FILE="/tmp/test.rrd"
    TMP_FILE="/sysinfo/bin/spet1008_130508_0000.nmon"
    NMON_FILE="/sysinfo/bin/spet1008.nmon"
    sort $TMP_FILE > $NMON_FILE                                         # Sort nmon file before use

    NMON_HOST=`grep "^AAA,host" $NMON_FILE | awk -F, '{ print $3 }'`    # Get HostNam
    EPOCH="/sysinfo/bin/epoch"                  ; export EPOCH     	        # Location of epoch pgm.    
    LOG="/tmp/nmon.log"                         ; export LOG                # Script LOG
    declare -a ARRAY_CPU
    
    
# --------------------------------------------------------------------------------------------------
#                         Write infornation into the log                        
# --------------------------------------------------------------------------------------------------
write_log()
{
  echo -e "`date` - $1"
  echo -e "`date` - $1" >> $LOG
}

    # If RRD DataBase does not exist create it
    rm -f $RRD_FILE
    
    if [ ! -e  $RRD_FILE ]
        then    echo "Creating Round Robin Database for $NMON_HOST Host ($RRDFILE)."
                    #--start N --step 300               
                $RRDTOOL create $RRD_FILE                  \
                        --start "00:00 01.01.2013" --step 300 \
                         DS:cpu_user:GAUGE:900:0:100      \
                         DS:cpu_sys:GAUGE:900:0:100      \
                         DS:cpu_wait:GAUGE:900:0:100      \
                         DS:cpu_idle:GAUGE:900:0:100      \
                         DS:cpu_total:GAUGE:900:0:100      \
                         RRA:MAX:0.5:1:210240
                chmod ${RRD_FILE_PERM} ${RRD_FILE}
                chown ${RRD_OWNER}.${RRD_GROUP} ${RRD_FILE}
    fi
    
    ls -l /tmp/*.rrd
    write_log "Using nmon file $NMON_FILE"


    # Get The Number of Snapshot
    NMON_SNAPSHOTS=`grep "^AAA,snapshots" $NMON_FILE | awk -F, '{ print $3 }'`
    grep "^CPU_ALL" $NMON_FILE | grep -iv "User%,Sys%,Wait%"  > /tmp/coco.txt    
    
    
#==================== PROCESS LOAD CPU INFORMATION =================================================
while read wline 
        do
        NTIME=`echo $wline | awk -F, '{ print $2 }'| cut -c2-5`
        #NTIME=`echo $wline | awk -F, '{ print $2 }'`
        NUSER=`echo $wline | awk -F, '{ print $3 }'`
        if [ "$NUSER" = "" ] ; then NUSER=0.0 ; fi
        NSYST=`echo $wline | awk -F, '{ print $4 }'`
        if [ "$NSYST" = "" ] ; then NSYST=0.0 ; fi
        NWAIT=`echo $wline | awk -F, '{ print $5 }'`
        if [ "$NWAIT" = "" ] ; then NWAIT=0.0 ; fi
        NIDLE=`echo $wline | awk -F, '{ print $6 }'`
        if [ "$NIDLE" = "" ] ; then NIDLE=0.0 ; fi
        NBUSY=`echo $wline | awk -F, '{ print $7 }'`
        NTOTAL=`echo $NUSER + $NSYST + $NWAIT | bc -l ` 

        INDX=`expr ${NTIME} + 0`
        ARRAY_CPU[$INDX]="${NUSER},${NSYST},${NWAIT},${NIDLE},${NTOTAL}"
        # If Debug is Activated - Display Important Variables before exiting function
        if [ $DEBUG -ne 0 ]
            then write_log "\n-----\nLINE   = $wline"
                 write_log "NTIME  = $NTIME"
                 write_log "NUSER  = $NUSER"
                 write_log "NSYST  = $NSYST"
                 write_log "NWAIT  = $NWAIT"
                 write_log "NIDLE  = $NIDLE"
                 write_log "NTOTAL = $NTOTAL"
                 echo "INDEX = $INDX - ${ARRAY_CPU[${INDX}]}"        
                 echo "NUmber of element in array is ${#ARRAY_CPU[*]}"
                 echo "NUmber of element in array is ${#ARRAY_CPU[@]} "
        fi    
        done <  /tmp/coco.txt 


#==================== LIST CPU ARRAY INFORMATION ===================================================
    echo "NUmber of element in array is ${#ARRAY_CPU[*]}"
    cnt=${#ARRAY_CPU[@]}
    echo "Number of elements: $cnt"
    for (( i = 1 ; i <= cnt ; i++ ))
        do
        if [ $DEBUG -ne 0 ] ; then echo "Element [$i]: ${ARRAY_CPU[$i]}" ; fi
        done        


#==================== PROCESS LOAD SNAPSHOT/EPOCH TIME ARRAY =======================================
    grep "^ZZZZ" $NMON_FILE | sort > /tmp/coco.txt
    while read wline 
        do
        ZCOUNT=`echo $wline | awk -F, '{ print $2 }'| cut -c2-5`
        ZTIME=`echo  $wline | awk -F, '{ print $3 }'`
        ZDATE=`echo  $wline | awk -F, '{ print $4 }'`

        ZHRS=`echo  $ZTIME  | awk -F: '{ print $1 }'`
        ZMIN=`echo  $ZTIME  | awk -F: '{ print $2 }'`
        ZSEC=`echo  $ZTIME  | awk -F: '{ print $3 }'`
        
        ZDD=`echo  $ZDATE  | awk -F- '{ print $1 }'`
        ZMONTH=`echo  $ZDATE  | awk -F- '{ print $2 }'`
        ZYY=`echo  $ZDATE  | awk -F- '{ print $3 }'`
        
        # Convert Month Name into Number
        case $ZMONTH in
            JAN) ZMM=1 ;;
            FEB) ZMM=2 ;;
            MAR) ZMM=3 ;;
            APR) ZMM=4 ;;
            MAY) ZMM=5 ;;
            JUN) ZMM=6 ;;
            JUL) ZMM=7 ;;
            AUG) ZMM=8 ;;
            SEP) ZMM=9 ;;
            OCT) ZMM=10 ;;
            NOV) ZMM=11 ;;
            DEC) ZMM=12 ;;
        esac
        
        NMON_EPOCH=`$EPOCH "$ZYY $ZMM $ZDD $ZHRS $ZMIN $ZSEC"`
        if [ $DEBUG -ne 0 ]
            then    echo "Line is $wline"
                    echo "DDMMYY is ${ZDD}/${ZMM}/${ZYY} HHMMSS is ${ZHRS}:${ZMIN}:${ZSEC}"
                    write_log "$EPOCH $ZYY $ZMM $ZDD $ZHRS $ZMIN $ZSEC"
                    echo "Epoch is $NMON_EPOCH"
        fi
        ZCOUNT=`expr ${ZCOUNT} + 0`
        ARRAY_TIME[$ZCOUNT]="${NMON_EPOCH},${ZDD}/${ZMM}/${ZYY} ${ZHRS}:${ZMIN}:${ZSEC}"
        done <  /tmp/coco.txt 

    
#============================ LIST SNAPSHOT/EPOCH TIME ARRAY =======================================
    echo "Number of element in SnapShot/Epoch array is ${#ARRAY_TIME[*]}"
    cnt=${#ARRAY_TIME[@]}
    echo "Number of elements: $cnt"
    for (( i = 1 ; i <= cnt ; i++ ))
        do
        if [ $DEBUG -ne 0 ] ; then echo "SnapShot/Epoch [$i]: ${ARRAY_TIME[$i]}" ; fi
        done        


    
#====================== LIST COMBINE SNAPSHOT/EPOCH AND CPU INFO ARRAY =============================
    echo "Number of SnapShots is $NMON_SNAPSHOTS"
    for (( i = 1 ; i <= NMON_SNAPSHOTS ; i++ ))
        do
        echo "CPU_ARRAY  [$i]: ${ARRAY_CPU[$i]}"
        echo "TIME_ARRAY [$i]: ${ARRAY_TIME[$i]}"

        A_USER=` echo ${ARRAY_CPU[$i]}   | awk -F, '{ print $1}'`
        A_SYST=` echo ${ARRAY_CPU[$i]}   | awk -F, '{ print $2}'`
        A_WAIT=` echo ${ARRAY_CPU[$i]}   | awk -F, '{ print $3}'`
        A_IDLE=` echo ${ARRAY_CPU[$i]}   | awk -F, '{ print $4}'`
        A_TOTAL=`echo ${ARRAY_CPU[$i]}   | awk -F, '{ print $5}'`
        A_EPOCH=`echo ${ARRAY_TIME[$i]} | awk -F, '{ print $1}'`
        echo "rrdupdate ${RRD_FILE} -t cpu_user:cpu_sys:cpu_wait:cpu_idle:cpu_total ${A_EPOCH}:${A_USER}:${A_SYST}:${A_WAIT}:${A_IDLE}:${A_TOTAL}"
        rrdupdate ${RRD_FILE} -t       cpu_user:cpu_sys:cpu_wait:cpu_idle:cpu_total ${A_EPOCH}:${A_USER}:${A_SYST}:${A_WAIT}:${A_IDLE}:${A_TOTAL}
        done        




#        rrdupdate "${RRD_FILE}" -t cpu_user:cpu_sys:cpu_wait:cpu_idle $NEPOCH:"${NUSER}":"${NSYS}":"${NWAIT}":"${NIDLE}"
    
#    rrdtool fetch test.rrd MAX
