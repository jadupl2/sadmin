#!/usr/bin/env sh 
# --------------------------------------------------------------------------------------------------
#   Author   :  Jacques Duplessis
#   Title    :  sysinfo.sh
#   Synopsis : .
#   Version  :  1.0
#   Date     :  30 August 2013
#   Requires :  sh
#   SCCS-Id. :  @(#) sysinfo.sh 2.0 2013/08/30
# --------------------------------------------------------------------------------------------------
#
#set -x


# --------------------------------------------------------------------------------------------------
#                           Script Variables Definitions
# --------------------------------------------------------------------------------------------------
PN=${0##*/}                                     ; export PN             # Current Script name
VER='2.1'                                       ; export VER            # Program version
SYSADMIN="duplessis.jacques@gmail.com"          ; export SYSADMIN       # sysadmin email
DASH=`printf %100s |tr " " "="`                 ; export DASH           # 100 dashes line
INST=`echo "$PN" | awk -F\. '{ print $1 }'`     ; export INST           # Get Current script name
RC=0                                            ; export RC             # Default Script Return Code
HOSTNAME=`hostname -s`                          ; export HOSTNAME       # Current Host name
OSNAME=`uname -s|tr '[:lower:]' '[:upper:]'`    ; export OSNAME         # Get OS Name (AIX or LINUX)
CUR_DATE=`date +"%Y_%m_%d"`                     ; export CUR_DATE       # Current Date
CUR_TIME=`date +"%H_%M_%S"`                     ; export CUR_TIME       # Current Time


# OUTPUT HEADING
# ==================================================================================================
tput clear
printf "%-22s %15s %15s %15s\n" "Parameter Name" "Maximum Value" "Current Usage" "% Used"
echo "------------------------------------------------------------------------------"

# OPEN FILES
# ==================================================================================================
file_max_set=`cat /proc/sys/fs/file-max`
file_max_used=`cat /proc/sys/fs/file-nr | awk '{print $1}'`
let pct_of_max=file_max_used*100/file_max_set
printf "%-22s %15d %15d %15d\n" fs.file-max $file_max_set $file_max_used $pct_of_max

# NUMBER OF MESSAGE QUEUES
# ==================================================================================================
queues_avail=`ipcs -q -l | tail -4 |head -1 | awk '{print $6}'`
queues_used=`ipcs -q -u | tail -4 |head -1 | awk '{print $4}'`
let pct_of_max=queues_used*100/queues_avail
printf "%-22s %15d %15d %15d\n" "Message Queues" $queues_avail $queues_used $pct_of_max

# MESSAGE SIZE
# ==================================================================================================
queue_size=`ipcs -q -l | tail -2 |head -1 | awk '{print $8}'`
let total_queue_size=queue_size*queues_avail
used_bytes=`ipcs -q -u | tail -2 |head -1 | awk '{print $4}'`
let pct_of_max=used_bytes*100/total_queue_size
printf "%-22s %15d %15d %15d\n" "Queue Size (bytes)" $total_queue_size $used_bytes $pct_of_max

# SEMAPHORE SETS
# ==================================================================================================
sem_sets_avail=`cat /proc/sys/kernel/sem | awk '{print $4}'`
sems_per_set=`cat /proc/sys/kernel/sem | awk '{print $1}'`
sem_sets_used=`ipcs -s -u | tail -3 |head -1 | awk '{print $4}'`
let pct_of_max=sem_sets_used*100/sem_sets_avail
printf "%-22s %15d %15d %15d\n" "Semaphore Sets" $sem_sets_avail $sem_sets_used $pct_of_max

# SEMAPHORE SETS
# ==================================================================================================
let sems_avail=sem_sets_avail*sems_per_set
sems_used=`ipcs -s -u | tail -2 |head -1 | awk '{print $4}'`
let pct_of_max=sems_used*100/sems_avail
printf "%-22s %15d %15d %15d\n" "Semaphores" $sems_avail $sems_used $pct_of_max

# MEMORY
# ==================================================================================================
segments_avail=`ipcs -m -l | tail -5 |head -1 | awk '{print $6}'`
segments_used=`ipcs -m -u | tail -6 |head -1 | awk '{print $3}'`
let pct_of_max=segments_used*100/segments_avail
printf "%-22s %15d %15d %15d\n" "Shared Memory Segments" $segments_avail $segments_used $pct_of_max


# PAGE AVAILABLES
# ==================================================================================================
#pages_avail=`cat /proc/sys/kernel/shmall`
#pages_used=`ipcs -m -u | tail -4 |head -1 | awk '{print $3}'`
#let pct_of_max=pages_used*100/pages_avail
#printf "%-22s %15d %15d %15d\n" "Shared Memory Pages" $pages_avail $pages_used $pct_of_max
#printf "%-22s %15s %15s %15s\n" "Shared Memory Pages" $pages_avail $pages_used $pct_of_max


# SHARE MEMORY
# ==================================================================================================
let shared_mem_avail=pages_avail*4
let shared_mem_used=pages_used*4
let pct_of_max=shared_mem_used*100/shared_mem_avail
printf "%-22s %15d %15d %15d\n" "Shared Memory (kB)" $shared_mem_avail $shared_mem_used $pct_of_max


# HUGE MEMORY PAGES
# ==================================================================================================
huge_pages_avail=`cat /proc/meminfo | grep ^HugePages_Total | awk '{print $2}'`
huge_pages_free=`cat /proc/meminfo | grep ^HugePages_Free | awk '{print $2}'`
let huge_pages_used=huge_pages_avail-huge_pages_free
if [ $huge_pages_avail -eq 0 ]
    then pct_huge_pages_used=0
    else let pct_huge_pages_used=huge_pages_used*100/huge_pages_avail
fi
printf "%-22s %15d %15d %15d\n" "Huge Memory Pages" $huge_pages_avail $huge_pages_used $pct_huge_pages_used
