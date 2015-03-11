#!/bin/sh
# --------------------------------------------------------------------------
#   Author:     Jacques Duplessis
#   Title:      Script that update the Performance RRD File
#
#   January 2005: Added support for Linux hosts
#   September 2010 - Updated to run on Linux - J.Duplessis
# --------------------------------------------------------------------------

# Define Global Variable
# --------------------------------------------------------------------------------------------------
SYSINFO="/sysinfo/www"                  ; export SYSINFO
SYSBIN="/sadmin/bin"                    ; export SYSBIN
SYSPERF="$SYSINFO/rrd/perf"             ; export SYSPERF
PERFARC="$SYSINFO/rrd/perf_archive"     ; export PERFARC
NMON_DIR="$SYSINFO/data/nmon"           ; export NMON_DIR
PN=${0##*/}                             ; export PN
VER='1.2'                               ; export VER
RRDTOOL="/usr/bin/rrdtool";             ; export RRDTOOL

echo "Program $PN Version $VER is starting - `date`"


# Process all file
find $SYSPERF -name "perfdata*" -exec ls -ltr {} \;
find $SYSPERF -name "perfdata*" | sort > /tmp/gph_work.$$

for wlinuxperfdata in `cat /tmp/gph_work.$$`
    do
    whost=`echo $wlinuxperfdata | awk -F/ '{ print $6 }'`
    rrdfile=`dirname $wlinuxperfdata`/${whost}.rrd


    # If RRD DataBase does not exist create it
    if [ ! -f  $rrdfile ]
       then echo "Creating Linux Round Robin Database for $whost ($rrdfile)"
            $RRDTOOL create $rrdfile            \
                 --start "00:00 01.01.2010"        \
                --step 600                        \
                 DS:cpu_busy:GAUGE:1200:0:100      \
                 DS:cpu_wait:GAUGE:1200:0:100      \
                 DS:mem_free:GAUGE:1200:0:U        \
                 DS:mem_used:GAUGE:1200:0:U        \
                 DS:mem_used_pct:GAUGE:1200:0:U    \
                 DS:mem_cache:GAUGE:1200:0:U       \
                 DS:mempg_alloc_sec:GAUGE:1200:U:U \
                 DS:swap_in_out_sec:GAUGE:1200:0:U \
                 DS:swap_free:GAUGE:1200:0:U       \
                 DS:swap_used:GAUGE:1200:0:U       \
                 DS:swap_used_pct:GAUGE:1200:0:100 \
                 DS:pg_in_out_sec:GAUGE:1200:0:U   \
                 DS:disk_tps:GAUGE:1200:0:U        \
                 DS:disk_kbread_sec:GAUGE:1200:0:U \
                 DS:disk_kbwrtn_sec:GAUGE:1200:0:U \
                 DS:proc_rque:GAUGE:1200:0:U       \
                 DS:eth0_kbytesin:GAUGE:1200:0:U   \
                 DS:eth0_kbytesout:GAUGE:1200:0:U  \
                 DS:eth1_kbytesin:GAUGE:1200:0:U   \
                 DS:eth1_kbytesout:GAUGE:1200:0:U  \
                 DS:eth2_kbytesin:GAUGE:1200:0:U   \
                 DS:eth2_kbytesout:GAUGE:1200:0:U  \
                 RRA:MAX:0.5:1:78912
            chmod 664 $rrdfile
    fi

    # Update the RRD DataBase
    echo -e "\nUpdating rrdfile $rrdfile from datafile $wlinuxperfdata for host $whost ..."
    ${SYSBIN}/sys_gph_update_rrd_linux.pl $wlinuxperfdata $rrdfile

    # Keep a copy in case in $PERFARC Directory.
    filename=`basename $wlinuxperfdata`
    echo "mv $wlinuxperfdata $PERFARC/${whost}_$filename"
    mv $wlinuxperfdata $PERFARC/${whost}_$filename
    done

# Remove work file
rm /tmp/gph_work.$$

# Keep performance Date file for 10 Days Linux Performance Data
echo -e "\n\nCleanup - Keep only 10 days on performance data files in $PERFARC"
echo -e "find $PERFARC -type f -name \"perfdata*\" -mtime +10 -exec rm -f {} \; >/dev/null 2>&1"
find $PERFARC -type f  -name perfdata* -mtime +10 -exec rm -f {} \; >/dev/null 2>&1
#
# Keep nmon file only for 35 Days
echo -e "\n\nCleanup - Keep only 35 days on nmon data files in $NMON_DIR"
echo -e "find $NMON_DIR -type f -name \"*.nmon\" -mtime +35 -exec rm -f {} \; >/dev/null 2>&1"
find $NMON_DIR       -type f -name *.nmon     -mtime +35 -exec rm -f {} \; >/dev/null 2>&1
#
#
echo -e "\nEnd of Program $PN - `date`"
