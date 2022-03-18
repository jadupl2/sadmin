#!/usr/bin/env bash 
# --------------------------------------------------------------------------------------------------
#   Title    : swatch_smon.sh 
#   Author   : Jacques Duplessis 
#   Synopsis : Restart nmon daemon, if it's not already running (with end time at 23:58:58)
#              Calculate the number of Snap Shot Till 23:55 today / Restart if necessary
#   Version  : 1.5
#   Date     : November 2015 
#   Requires : sh
# --------------------------------------------------------------------------------------------------
# Change log
#
# 2016_10_10 v1.7 Modification making sure that nmon is available on the server.
#            If not found a copy in /sadmin/pkg/nmon/aix in used to create the link /usr/bin/nmon
# 2016_11_11 v1.8 Enhance checking for nmon existence and add some message for user, ReTested AIX
# 2016_12_20 v1.9 Change to run on Aix 7.x and minor corrections
# 2017_12_29 v2.0 Add Warning message stating that nmon not available on MacOS
# 2017_01_27 V2.1 Now list two newest nmon files in $SADMIN/dat/nmon & Fix minor Bug & add comment
# 2017_02_02 V2.2 Show number of nmon running only once, if nmon is already running
# 2017_02_04 V2.3 Snapshot will be taken every 2 minutes instead of 5.
# 2017_02_08 V2.4 Fix Compatibility problem with 'sadh' shell (If statement) 
# 2018_06_04 V2.5 Adapt to new Libr.
# 2018_07_21 v2.6 Rewrote for performance since it now run within System Monitor.
#@2020_10_01 v2.7 If not able to start/Restart nmon, email include instruction about what to do.
#
# --------------------------------------------------------------------------------------------------
trap 'exit 0' 2                                                          # INTERCEPT The Control-C
#set -x


#===================================================================================================
#                               Script environment variables
#===================================================================================================
export HOSTNAME=`hostname -s`                                           # Hostname Without domain
export OSTYPE=`uname -s | tr '[:lower:]' '[:upper:]'`                   # OSName(AIX/LINUX/DARWIN) 
export PN=${0##*/}                                                      # Script name
export VER='2.7'                                                        # Script Version No.
export INST=`echo "$PN" | awk -F\. '{ print $1 }'`                      # Script name without ext.
export WDATE=`date "+%C%y.%m.%d;%H:%M:%S"`                              # Today Date and Time
export DASH=`printf %80s |tr ' ' '-'`                                   # 80 dashes
export NMON_DIR="${SADMIN}/dat/nmon"                                    # NMON Data Files Directory
export WDATE_EPOCH=""                                                   # Converted date to Epoch



# --------------------------------------------------------------------------------------------------
#    C O N V E R T   D A T E  (YYYY.MM.DD HH:MM:SS)  R E C E I V E    T O    E P O C H   T I M E  
# --------------------------------------------------------------------------------------------------
date2epoch() {
    if [ $# -ne 1 ]                                                     # Should have rcv 1 Param
        then echo -e "No Parameter received by $FUNCNAME function"      # Log Error Mess,
             echo -e "Please correct script please, script aborted"     # Advise that will abort
             exit 1                                                     # Terminate the script
    fi

    WDATE=$1                                                            # Save Received Date
    YYYY=`echo $WDATE | awk -F. '{ print $1 }'`                         # Extract Year from Rcv Date
    MTH=` echo $WDATE | awk -F. '{ print $2 }'`                         # Extract MTH  from Rcv Date
    DD=`echo   $WDATE | awk -F. '{ print $3 }' | awk '{ print $1 }'`    # Extract Day
    HH=`echo   $WDATE | awk '{ print $2 }' | awk -F: '{ print $1 }'`    # Extract Hours
    MM=`echo   $WDATE | awk '{ print $2 }' | awk -F: '{ print $2 }'`    # Extract Min   
    SS=`echo   $WDATE | awk '{ print $2 }' | awk -F: '{ print $3 }'`    # Extract Sec

    case "$OSTYPE" in                                            
      "LINUX")  if [ ${#DD} -lt 2 ]     ; then  DD=` printf "%02d" $DD`     ; fi 
                if [ ${#MTH} -lt 2 ]    ; then  MTH=`printf "%02d" $MTH`    ; fi
                if [ ${#HH} -lt 2 ]     ; then  HH=` printf "%02d" $HH`     ; fi
                if [ ${#MM} -lt 2 ]     ; then  MM=` printf "%02d" $MM`     ; fi
                if [ ${#SS} -lt 2 ]     ; then  SS=` printf "%02d" $SS`     ; fi               
                WDATE_EPOCH=`date +"%s" -d "$YYYY/$MTH/$DD $HH:$MM:$SS" `
                ;; 
      "AIX")    if [ "$MTH" -gt 0 ] ; then MTH=`echo $MTH | sed 's/^0//'` ; fi # Del Leading 0 
                MTH=`echo "$MTH -1" | bc`
                DD=`echo   $WDATE | awk -F. '{ print $3 }' | awk '{ print $1 }' | sed 's/^0//'`
                HH=`echo   $WDATE | awk '{ print $2 }' | awk -F: '{ print $1 }' | sed 's/^0//'`
                MM=`echo   $WDATE | awk '{ print $2 }' | awk -F: '{ print $2 }' | sed 's/^0//'`
                SS=`echo   $WDATE | awk '{ print $2 }' | awk -F: '{ print $3 }' | sed 's/^0//'`
                WDATE_EPOCH=`perl -e "use Time::Local; print timelocal($SS,$MM,$HH,$DD,$MTH,$YYYY)"`
                ;;
      "DARWIN") if [ ${#DD} -lt 2 ]     ; then  DD=` printf "%02d" $DD`     ; fi 
                if [ ${#MTH} -lt 2 ]    ; then  MTH=`printf "%02d" $MTH`    ; fi
                if [ ${#HH} -lt 2 ]     ; then  HH=` printf "%02d" $HH`     ; fi
                if [ ${#MM} -lt 2 ]     ; then  MM=` printf "%02d" $MM`     ; fi
                if [ ${#SS} -lt 2 ]     ; then  SS=` printf "%02d" $SS`     ; fi                     
                WDATE_EPOCH=`date -j -f "%Y/%m/%d %T" "$YYYY/$MTH/$DD $HH:$MM:$SS" +"%s"`
                ;;   
    esac
}

# --------------------------------------------------------------------------------------------------
# Check availibility of 'nmon' and permmission and Deactivate nmon cron file (if exist) 
# --------------------------------------------------------------------------------------------------
pre_validation()
{
    export NMON=`which nmon >/dev/null 2>&1`                            # Is nmon executable Avail.?
    if [ $? -eq 0 ]                                                     # If it is, Save Full Path 
        then NMON=`which nmon`                                          # Save 'nmon' location 
             echo -e "[OK] Yes, 'nmon' is available - $NMON"            # Show user result OK
        else echo -e "[ERROR] The 'nmon' command wasn't found"          # Show User Error
             return 1                                                   # Return error to caller
    fi
    if [ ! -x $NMON ]                                                   # Is nmon executable ?
       then echo -e "[ERROR] $NMON missing execution permission"        # Advise User of error
            return 1                                                    # Return Error to Caller
    fi

    # If nmon crontab file exist - Put crontab line in comment
    # What to make sure that only one nmon is running and is the one controlled by this script
    if [ "$OSTYPE" = "LINUX" ]                                          # On Linux O/S
        then nmon_cron='/etc/cron.d/nmon-script'                        # Name of the nmon cron file
             if [ -r "$nmon_cron" ]                                     # nmon cron file exist ?
                then commented=`grep 'nmon-script' ${nmon_cron} |cut -d' ' -f1` # 1st Char nmon line
                     if [ "$commented" = "0" ]                          # Cron Line not in commented
                        then sed -i -e 's/^/#/' $nmon_cron              # Then Put line in comment
                             echo "$nmon_cron file was put in comment"  # Advise user 
                        else echo "$nmon_cron file is in comment - OK"  # Advise user 
                     fi
             fi
    fi
    return 0
}


# --------------------------------------------------------------------------------------------------
#    - Check if nmon is running - If not start it and set parameter so it stop at 23:55
# --------------------------------------------------------------------------------------------------
#
check_nmon()
{
    # On Aix we might be running 'nmon' (older aix) or 'topas_nmon' (latest Aix)
    if [ "$OSTYPE" = "AIX" ]                                            # If Server is running Aix
        then which topas_nmon >/dev/null 2>&1                           # Lastest Aix use topas_nmon
             if [ $? -eq 0 ]                                            # topas_nmon on system ?
                then TOPAS_NMON=`which topas_nmon`                      # Save Path to topas_nmon
                     WSEARCH="${NMON}|${TOPAS_NMON}"                    # Will search for both nmon
                else WSEARCH=$NMON                                      # Will search for nmon only
                     TOPAS_NMON=""                                      # topas_nmon path not found
             fi
        else WSEARCH=$NMON                                              # Linux search for nmon only
    fi
    
    # Kill any nmon running without the option -s120 (Our switch) - Want only one nmon running
    # This will eliminate the nmon running from the crontab with rpm installation
    nmon_count=`ps -ef | grep -E "$WSEARCH" |grep -v grep |grep s120 |wc -l |tr -d ' '`
    if [ $nmon_count -gt 1 ] 
        then #NMON_PID=`ps -ef | grep nmon |grep -v grep |grep s120 |awk '{ print $2 }'`
             #echo -e "Found another nmon process running at $NMON_PID"
             echo -e "Found another nmon process running with s120 parameter"
             ps -ef | grep nmon |grep -v grep |grep s120 
             ps -ef | grep nmon |grep -v grep |grep s120 | awk '{ print $2 }' | xargs kill -9
             #kill -9 "$NMON_PID"
             echo -e "We just kill them - Only one nmon process should be running"
    fi
             
 
    # Search Process Status (ps) and display number of nmon process running currently
    echo -e " "                                                         # Blank line in log
    nmon_count=`ps -ef | grep -E "$WSEARCH" |grep -v grep |grep s120 |wc -l |tr -d ' '`
    echo -e "There is $nmon_count nmon process actually running"        # Show Nb. nmon Running
    ps -ef | grep -E "$WSEARCH" | grep 's120' | grep -v grep | nl 

    # nmon_count = 0 = Not running - Then we start it 
    # nmon_count = 1 = Running - Then OK
    # nmon_count = * = More than one running ? Kill them and then we start a fresh one
    # not running nmon, start it
    echo -e " "
    if [ "$nmon_count" -ne 1 ]
       then echo -e "----------------------"
            EPOCH_NOW=`perl -e 'print time'`
            echo -e "CURRENT DATE/TIME           = `date +"%Y.%m.%d %H:%M:%S"`"
            echo -e "CURRENT EPOCH               = $EPOCH_NOW"          # Show Current Epoch Time
            CUR_DATE=`date +"%Y.%m.%d"`                                 # Current Date
            NOW="$CUR_DATE 23:59:58"                                    # Build epoch cmd date format
            date2epoch "${NOW}"                                         # Epoch of Today at 23:58
            EPOCH_END=$WDATE_EPOCH
            echo -e "END DATE/TIME               = $NOW"
            echo -e "END EPOCH                   = $EPOCH_END" 
            TOT_SEC=`echo "${EPOCH_END}-${EPOCH_NOW}"|bc`               # Nb Sec. between now & 23:58
            echo -e "SECONDS TILL 23:59:58       = $TOT_SEC" 
            TOT_MIN=`echo "${TOT_SEC}/60"| bc`                          # Nb of Minutes till 23:58
            echo -e "MINUTES TILL 23:59:58       = $TOT_MIN"
            echo -e "SECONDS BETWEEN SNAPSHOT    = 120"
            TOT_SNAPSHOT=`echo "${TOT_MIN}/2"| bc`                      # Nb. of 2 Min till 23:58    
            echo -e "Nb. SnapShot till 23:59:58  = $TOT_SNAPSHOT" 
            echo -e "----------------------"
            case $nmon_count in
                0)  echo -e "The nmon process is not running - Starting nmon daemon ..."
                    echo -e "We will start a fresh one that will terminate at 23:55"
                    echo -e "We calculated that there will be ${TOT_SNAPSHOT} snapshots till 23:55"
                    echo -e "$NMON -f -s120 -c${TOT_SNAPSHOT} -t -m $NMON_DIR "
                    $NMON -f -s120 -c${TOT_SNAPSHOT} -t -m $NMON_DIR  
                    if [ $? -ne 0 ] 
                        then echo -e "Error while starting - Not Started !" 
                            EXIT_CODE=1 
                    fi
                    echo -e " "
                    nmon_count=`ps -ef | grep -E "$WSEARCH" |grep -v grep |grep s120 |wc -l |tr -d ' '`
                    echo -e "The number of nmon process running after restarting it is : $nmon_count"
                    ps -ef | grep -E "$WSEARCH" | grep -v grep | nl
                    ;;
                *)  echo -e "There seems to be more than one nmon process running ??"
                    ps -ef | grep -E "$WSEARCH" | grep 's120' | grep -v grep | nl 
                    echo -e "We will kill them both and start a fresh one that will terminate at 23:55"
                    ps -ef | grep -E "$WSEARCH" | grep -v grep |grep s120 |awk '{ print $2 }' |xargs kill -9 
                    echo -e "We will start a fresh one that will terminate at 23:55"
                    echo -e "We calculated that there will be ${TOT_SNAPSHOT} snapshots till 23:55"
                    echo -e "$NMON -f -s120 -c${TOT_SNAPSHOT} -t -m $NMON_DIR "
                    $NMON -f s120 -c${TOT_SNAPSHOT} -t -m $NMON_DIR 
                    if [ $? -ne 0 ] 
                        then echo -e "Error while starting - Not Started !" 
                            EXIT_CODE=1 
                        else EXIT_CODE=0
                    fi
                    # Search Process Status (ps) and display number of nmon process running currently
                    echo -e " "                                         # Blank line in log
                    nmon_count=`ps -ef | grep -E "$WSEARCH" |grep -v grep |grep s120 |wc -l |tr -d ' '`
                    echo -e "There is $nmon_count nmon process actually running" # Show Nb. Running
                    ps -ef | grep -E "$WSEARCH" | grep 's120' | grep -v grep | nl 
                    ;;
            esac
        else echo -e "Nmon already Running ... Nothing to Do."
             EXIT_CODE=0
    fi 

    # Display Last two nmon files created
    echo -e " "                                                         # Blank line in log
    echo -e "Last nmon files created"                                   # SHow what were doing
    ls -ltr $NMON_DIR | tail -2 |  while read wline ; do echo -e "$wline"; done
    return $EXIT_CODE
}



# --------------------------------------------------------------------------------------------------
#                                     Script Start HERE
# --------------------------------------------------------------------------------------------------
    echo -e "\n\n${DASH}\nStarting $PN on ${HOSTNAME} - `date`"         # Print Script Header
    if [ "$OSTYPE" = "DARWIN" ]                                         # nmon not available on OSX
        then echo -e "The command nmon is not available on MacOS"       # Advise user that won't run
             echo -e "Script can't continue"                            # Process can't continue
             exit 0                                                     # Exit back to bash
    fi
    pre_validation                                                      # Does 'nmon' cmd present ?
    if [ $? -eq 0 ]                                                     # If no validation Error
        then check_nmon                                                 # nmon not running start it
             EXIT_CODE=$?                                               # Save Return Code 
        else EXIT_CODE=1
             MSG0="Dear user,\n"
             MSG1="The Performance Collector 'nmon' is not running on '${HOSTNAME}'.\n"
             MSG2="The 'nmon' watcher (${INST}.sh) was not able to start it.\n\n"
             MSG3="I would suggest that you run the 'nmon' watcher manually and see the error message.\n"
             MSG4="To run the 'nmon' watcher, run the command below :\n"
             MSG5="# $SADMIN/usr/mon/swatch_nmon.sh\n\n" 
             MSG6="If it's not installed, please install it by running the command below :\n"
             MSG7="# $SADM_BIN_DIR/sadm_requirements.sh -i\n\n"
             MSG8="Have a good day"
             MSG="${MSG0}${MSG1}${MSG2}${MSG3}${MSG4}${MSG5}${MSG6}${MSG7}${MSG8}"
             echo -e "Not able to start the performance collector 'nmon' on '${HOSTNAME}'." >${SADM_UMON_DIR}/${INST}.txt         
    fi
    echo -e "\nReturn code : $EXIT_CODE"                                # Print Script return code
    echo -e "End of script $PN on ${HOSTNAME} `date`\n${DASH}\n"        # Print Script Footer
    exit $EXIT_CODE                                                     # Exit With Return Code           
