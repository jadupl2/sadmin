#! /bin/bash
##############################################################################
# Title      :  sam_sched_incr.sh - sam schedule filesystem increase
# Version    :  1.0
# Author     :  Jacques Duplessis
# Date       :  2005-01-06
# Requires   :  bash shell
# SCCS-Id.   :  @(#) sam_sched_incr.sh 1.0 15-Fev-2006
#
##############################################################################
#
# Description
#   This script is used to enlarge filesystems used by application/Database
#
##############################################################################
# History    :
#   1.0      Initial Version - fev 2006 - Jacques Duplessis
#
##############################################################################
trap 'exec $SAM/sam' 2   		# INTERCEPTE LE ^C
#
SAM=/sysadmin/sam ; export SAM

# Load all Ext3 Functions
# ---------------------------------------------------------------------------
. $SAM/sam_fs_functions.sh


# Set Creation screen Default Value
# ---------------------------------------------------------------------------
BATCH_MODE=1 	                           ; export BATCH_MODE # Turn ON
SCHED_SBEFORE=""  			   ; export SCHED_SBEFORE
SCHED_SAFTER=""    			   ; export SCHED_SAFTER
SCHED_TMP="/tmp/SAMTMP.$$"                 ; export SCHED_TMP


# Must at least specify one parameter.
# ---------------------------------------------------------------------------
if [ "$#" != "1" ]
   then write_log "Usage: `basename $0` <Oracle Instance Name or Tag Name>"
        exit 1
   else WINST=$1 ; export WINST
fi


# SAM environment Variable must be defined
# ---------------------------------------------------------------------------
if [ "$SAM" = "" ]
   then                                  
   write_log "Please define the \"SAM\" environment variable"
   write_log "It got to point the \"sam\" directory" 
   write_log "---"  
   exit 1 
fi  
      
# Verify that the schedule data file exist and can be updated
# ---------------------------------------------------------------------------
if [ ! -w "$DBINCR_FILE" ]
   then                                  
   write_log "There is a problem with the file $DBINCR_FILE."
   write_log "It may not exist or is not writable"
   write_log "---"  
   exit 1 
fi  




# Verify that the schedule data file exist and can be updated
# -----------------------------------------------------------------------------
touch $SCHED_TMP
cat $DBINCR_FILE | while read wline
    do
    echo $wline | grep -i "^${WINST}:" > /dev/null 2>&1

# A Match was found 
    if [ $? -eq 0 ]
       then LVMOUNT=`echo $wline | awk -F: '{ print $2 }'`
            write_log " " ; write_log " " ; write_log " " 
	    write_log "--------------------------------------------------------"
            get_mntdata $LVMOUNT
            LVSIZE=`echo $wline | awk -F: '{ print $4 }'`
            write_log "Filesystem $LVMOUNT increase by $LVSIZE MB started at `date`"
            write_log "Instance name received in parameter is ${WINST}"
            mount $LVMOUNT > /dev/null 2>&1

            # Validate scripts that will execute before/after increase
            # ------------------------------------------------------------------
            SCHED_SBEFORE=`echo $wline | awk -F: '{ print $5 }'` 
            SCHED_SAFTER=` echo $wline | awk -F: '{ print $6 }'` 
            if [ ! -x ${SCHED_SAFTER} ] && [ ${#SCHED_SAFTER} -ne 0 ]
               then write_log "ABORTED - ${SCHED_SAFTER} is not executable"
                    exit 1
            fi
            if [ ! -x ${SCHED_SBEFORE} ] && [ ${#SCHED_SBEFORE} -ne 0 ]
               then write_log "ABORTED - ${SCHED_SBEFORE} is not executable"
                    exit 1
            fi

            # Execute script before Enlarging filesystem
            # ------------------------------------------------------------------
            if [ ${#SCHED_SBEFORE} -ne 0 ]
               then write_log " " 
                    write_log "Executing - su - oracle \"-c ${SCHED_SBEFORE} ${WINST}\""
                    #. ${SCHED_SBEFORE} ${WINST}
                    su - oracle "-c ${SCHED_SBEFORE} ${WINST}" 
                    RC1=$?
                    write_log "Return code returned by ${SCHED_SBEFORE} is $RC1"
                    if [ "$RC1" -ne 0 ] ; then exit 1 ; fi
            fi

            # Enlarging filesystem size
            # ------------------------------------------------------------------
            write_log " " 
            write_log "Executing File increase"
            extend_fs
            RC=$?
            if [ "$RC" -ne 0 ]
               then write_log "Return code returned by extend_fs function is $RC"
               else write_log "Filesystem was increased with success !"
            fi


	    # Execute Script after enlarging filesystem
            # ------------------------------------------------------------------
            if [ ${#SCHED_SAFTER} -ne 0 ]
               then write_log " " 
                    write_log "Executing - su - oracle \"-c ${SCHED_SAFTER} ${WINST}\""
                    write_log "Executing ${SCHED_SAFTER} ${WINST}"
                    #. ${SCHED_SAFTER} ${WINST}
                    su - oracle "-c ${SCHED_SAFTER} ${WINST}"
                    RC1=$?
                    write_log "Return code returned by ${SCHED_SAFTER} is $RC1"
                    if [ "$RC1" -ne 0 ] ; then exit 1 ; fi
            fi

       else echo "${wline}" >> $SCHED_TMP
            write_log "The Oracle Instance or TAG ($WINST) was not found in $DBINCR_FILE"
    fi 
    done

# Updating the File Increase Data File
    cp $SCHED_TMP $DBINCR_FILE
    chmod 644 $DBINCR_FILE
    rm -f $SCHED_TMP
