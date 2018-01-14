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



#col_suite_runtime_line='#CE0071';
#col_suite_runtime_area='#E73A98';

# Case colors
#col_case_line = array('','#225ea8','#0c2c84','#1d91c0','#41b6c4','#7fcdbb','#c7e9b4','#edf8b1','#E9F698');
#col_case_area = array('','#5692dc','#154be0','#5692DC','#1d91c0','#8ED4DC','#b6e2d8','#d7f0c7','#f3fac7');
#col_case_area_opacity = "BB";

# Step colors
#col_step_line = array('#01c510a','#bf812d','#dfc27d','#c7eae5','#80cdc1','#35978f','#01665e');
#col_step_area = array('#01c510a','#bf812d','#dfc27d','#c7eae5','#80cdc1','#35978f','#01665e');
#col_step_area_opacity = "CC";

# State colors
#col_OK = "#008500";
#col_WARN = "#ffcc00";
#col_CRIT = "#d30000";
#col_UNKN = "#d6d6d6";
#col_NOK = "#ff8000";



    # If RRD DataBase does not exist create it
    #rm -f $RRD_FILE
 
/usr/bin/rrdtool graph /sysinfo/bin/spet1008.png -s "00:00 08.05.2013" -e "23:59 08.05.2013" --title "Titre" --vertical-label "vertical" --height 250 --width 950 --upper-limit 100 --lower-limit 0 DEF:total=/tmp/test.rrd:cpu_total:MAX AREA:total#83AFE5:"% CPU total" DEF:user=/tmp/test.rrd:cpu_user:MAX AREA:user#D2EEEA:"% CPU User" DEF:sys=/tmp/test.rrd:cpu_sys:MAX AREA:sys#E6CE97:"% CPU Sys" DEF:wait=/tmp/test.rrd:cpu_wait:MAX AREA:wait#CC9A57:"% CPU wait" 
 

   
    GFILE="/sysinfo/bin/spet1008.png"
#    #$GTITLE     = "${WHOST_NAME} - " . strtoupper($WTYPE) ." Last 2 days" ;
#    #$CMD1       = "$RRDTOOL graph $GFILE -s \"$START\" -e \"$END\" --title \"$GTITLE\"";
#    #$CMD2       = "--vertical-label \"percentage(%)\" --height 250 --width 950 --upper-limit 100 --lower-limit 0 ";
##    #$CMD3       = "DEF:user=$RRD_FILE:cpu_busy:MAX LINE2:user#0000FF:\"% CPU time busy\"";
#    #$CMD        = "$CMD1" . " $CMD2 " .  " $CMD3";
#    #$outline    = exec ("$CMD", $array_out, $retval);    
#    write_log "$RRDTOOL graph $GFILE -s \"00:00 08.05.2013\" -e \"23:59 08.05.2013\" --title \"Titre\" --vertical-label \"vertical\" --height 250 --width 950 --upper-limit 100 --lower-limit 0 DEF:user=$RRD_FILE:cpu_user:MAX LINE2:user#0000FF:\"% CPU User\""
#    $RRDTOOL graph $GFILE -s "00:00 08.05.2013" -e "23:59 08.05.2013" --title "Titre" --vertical-label "vertical" --height 250 --width 950 --upper-limit 100 --lower-limit 0 DEF:user=$RRD_FILE:cpu_user:MAX LINE2:user#0000FF:"% CPU User"
#    echo "Return Code is $?"
    ls -l $GFILE
    
    
    