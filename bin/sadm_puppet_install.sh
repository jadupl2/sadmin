#! /bin/sh
####################################################################################################
# Shellscript:	install_puppet.sh
# Version    :	2.9
# Author    :	jacques duplessis
# Date      :	2014-05-22
# Requires  :	bash shell
# Category  :	installation
# SCCS-Id.  :	@(#) install_puppet.sh
####################################################################################################
#
#set -x

# --------------------------------------------------------------------------------------------------
#                          Script Variables Definitions
# --------------------------------------------------------------------------------------------------
PN=${0##*/}                                    ; export PN              # Current Script name
VER='2.9'                                      ; export VER             # Program version
DEBUG=1                                        ; export DEBUG           # Debug ON (1) or OFF (0)
DASH=`printf %100s |tr " " "="`                ; export DASH            # 100 dashes line
INST=`echo "$PN" | awk -F\. '{ print $1 }'`    ; export INST            # Get Current script name
RC=0                                           ; export RC              # Set default Return Code
HOSTNAME=`hostname -s`                         ; export HOSTNAME        # Current Host name
OSNAME=`uname -s|tr '[:lower:]' '[:upper:]'`   ; export OSNAME          # Get OS Name (AIX or LINUX)
CUR_DATE=`date +"%Y_%m_%d"`                    ; export CUR_DATE        # Current Date
CUR_TIME=`date +"%H_%M_%S"`                    ; export CUR_TIME        # Current Time
CPWD=`pwd`                                     ; export CPWD            # Save Current Working Dir.
#
#
BASE_DIR="/sadmin"                             ; export BASE_DIR        # Script Root Base Directory
BIN_DIR="$BASE_DIR/bin"                        ; export BIN_DIR         # Script Root binary directory
TMP_DIR="$BASE_DIR/tmp"                        ; export TMP_DIR         # Script Temp directory
LIB_DIR="$BASE_DIR/lib"                        ; export LIB_DIR         # Script Lib directory
LOG_DIR="$BASE_DIR/log"	                       ; export LOG_DIR         # Script log directory
TMP_FILE1="${TMP_DIR}/${INST}_1.$$"            ; export TMP_FILE1       # Script Tmp File1
TMP_FILE2="${TMP_DIR}/${INST}_2.$$"            ; export TMP_FILE2       # Script Tmp File2
TMP_FILE3="${TMP_DIR}/${INST}_3.$$"            ; export TMP_FILE3       # Script Tmp File3
LOG="${LOG_DIR}/${INST}.log"                   ; export LOG             # Script LOG filename
RCLOG="${LOG_DIR}/rc.${HOSTNAME}.${INST}.log"  ; export RCLOG           # Script Return code filename
GLOBAL_ERROR=0                                 ; export GLOBAL_ERROR    # Global Error Return Code
#
NFS_SERVER="nomad.maison.ca"                   ; export NFS_SERVER      # NFS Server
PUPPET_DIR="batcave/software/puppet/puppet_install" ; export PUPPET_DIR # Remote Puppet RPM Dir
SYSADMIN="duplessis.jacques@gmail.com"         ; export SYSADMIN        # sysadmin email
#
NFS_LOC_MOUNT="/mnt/nfs"                       ; export NFS_LOC_MOUNT   # NFS Local Mount Point
NFS_REM_MOUNT="/install"                       ; export NFS_REM_MOUNT   # NFS Remote Mount Point
PUPPET_CFGDIR="/etc/puppet"                    ; export PUPPET_CFGDIR   # Puppet Configuration Dir.
PUPPET_CFGFILE="${PUPPET_CFGDIR}/puppet.conf"  ; export PUPPET_CFGFILE  # Puppet Configuration File


OS_VER=`lsb_release -r | awk -F: '{ print $2 }'| tr -d '\t'| awk -F\. '{ print $1 }'` # Get OS Vers
uname -a | grep -iE "x86_64|ia64" >/dev/null 2>&1                       # Parse Kernel Description
if [ $? -eq 0 ] ; then OS_BITS=64 ; else OS_BITS=32 ; fi ;              # Kernel is 64 or 32 Bits
export OS_BITS OS_VER                                                   # Export OS Info

# Set Puppet Environment
if [ ! -f /opt/tivoli/tsm/client/ba/bin/include-exclude-list ] 			# If TSM Exclude file not exist
   then PUPPET_ENV="production"											# Set default to production
   else PUPPET_ENV=`head -1 /opt/tivoli/tsm/client/ba/bin/include-exclude-list | awk '{ print $3 }' | tr [:upper:] [:lower:]`
fi
if [ "$PUPPET_ENV" != "production" ] && [ "$PUPPET_ENV" != "development" ] # If Env is not valid
   then PUPPET_ENV="production"                           				# Default Env is Production
fi
export PUPPET_ENV


# --------------------------------------------------------------------------------------------------
#                      F U N C T I O N S    D E C L A R A T I O N
# --------------------------------------------------------------------------------------------------

# Write infornation into the log
write_log()
{
    echo -e "`date +"%Y-%b-%m %H:%M"` - $1" >> $LOG
}


# Convert String Received to Uppercase
toupper()
{
    echo $1 | tr  "[:lower:]" "[:upper:]"
}


# --------------------------------------------------------------------------------------------------
#         Check if this script is already running - If it is then do nothing else and exit
# --------------------------------------------------------------------------------------------------
check_if_already_running()
{
    echo -e "Checking if \"${PN}\" is already running ..."
    NB=`ps -A -o pid,cmd | grep  -i ${PN} | grep -v grep | wc -l | awk '{ print $1 }'`
    echo "I have count $NB instance(s) of the script running"
    if [ "$NB" -gt 1 ]
        then    echo -e "The script ${PN} is already running - Process aborted\n" > $WTMP2
                exit 1
        else    echo -e "Everything is OK - Proceeding ...\n"
    fi
}




# --------------------------------------------------------------------------------------------------
#                        Commands run at the beginning of the script
# --------------------------------------------------------------------------------------------------
init_process()
{

    # If log Directory doesn't exist, create it.
    if [ ! -d "$LOG_DIR" ]  ; then mkdir -p $LOG_DIR ; chmod 2775 $LOG_DIR ; export LOG_DIR ; fi

    # If TMP Directory doesn't exist, create it.
    if [ ! -d "$TMP_DIR" ]  ; then mkdir -p $TMP_DIR ; chmod 1777 $TMP_DIR ; export TMP_DIR ; fi

    # If LIB Directory doesn't exist, create it.
    if [ ! -d "$LIB_DIR" ]  ; then mkdir -p $LIB_DIR ; chmod 2775 $LIB_DIR ; export LIB_DIR ; fi

    # If log doesn't exist, Create it and Make sure it is writable
    if [ ! -e "$LOG" ]      ; then touch $LOG  ;chmod 664 $LOG  ; export LOG  ;fi
    > $LOG

    # If Return Log doesn't exist, Create it and Make sure it have right permission
    if [ ! -e "$RCLOG" ]    ; then touch $RCLOG ;chmod 664 $RCLOG ; export RCLOG ;fi

    # Write Starting Info in the Log
    write_log "${DASH}"
    write_log "Starting $PN $VER - `date`"
    write_log "${DASH}"

    # Update the Return Code File
    start=`date "+%C%y.%m.%d %H:%M:%S"`
    echo "${HOSTNAME} ${start} ........ ${INST} 2" >>$RCLOG

    # Abort Execution if OS Level is below RHEL 5
    if [ $OS_VER -lt 5 ]
        then write_log "Process Aborted - Only RHEL version greater than 4 are process"
             exit 1
    fi

}


# --------------------------------------------------------------------------------------------------
#                        Commands run at the end of the script
# --------------------------------------------------------------------------------------------------
end_process()
{

    # Maintain Backup RC File log at a reasonnable size.
    RC_MAX_LINES=100
    write_log "Trimming the rc log file $RCLOG to ${RC_MAX_LINES} lines."
    tail -100 $RCLOG > $RCLOG.$$
    rm -f $RCLOG > /dev/null
    mv $RCLOG.$$ $RCLOG
    chmod 666 $RCLOG

    # Making Sure the return code is 1 or 0 only.
    if [ $GLOBAL_ERROR -ne 0 ] ; then GLOBAL_ERROR=1 ; else GLOBAL_ERROR=0 ; fi

    # Update the Return Code File
    end=`date "+%H:%M:%S"`
    echo "${HOSTNAME} $start $end $INST $GLOBAL_ERROR" >>$RCLOG

    write_log "${PN} ended at ${end}"
    write_log "${DASH}\n\n\n\n"

    # Maintain Script log at a reasonnable size (5000 Records)
    cat $LOG >> $LOG.$$
    tail -5000 $LOG > $LOG.$$
    rm -f $LOG > /dev/null
    mv $LOG.$$ $LOG

    # Inform by Email if error
    if [ $RC -ne 0 ]
      then cat $LOG | mail -s "${PN} FAILED on ${HOSTNAME} at $end" $SYSADMIN
    fi

    # Delete Temproray files used
    if [ -e "$TMP_FILE1" ] ; then rm -f $TMP_FILE1 >/dev/null 2>&1 ; fi
    if [ -e "$TMP_FILE2" ] ; then rm -f $TMP_FILE2 >/dev/null 2>&1 ; fi
    if [ -e "$TMP_FILE3" ] ; then rm -f $TMP_FILE3 >/dev/null 2>&1 ; fi
}


# --------------------------------------------------------------------------------------------------
#                              Remove Puppet if necessary
# --------------------------------------------------------------------------------------------------
remove_puppet()
{

    # Check if puppet is installed
    write_log "Verify if puppet agent is already installed  ..."
    rpm -q puppet >/dev/null 2>&1
    if [ $? -ne 0 ]
        then write_log "Puppet is not install ..."
             return
        else write_log "Puppet is install and will be removed  ..."
    fi

    # If /etc/puppet directory exist make a backup
    write_log "Making a backup of configuration ..."
    PUPPET_BACKUP="${PUPPET_CFGDIR}/puppet_backup.`date +%Y_%m_%d_%H_%M_%S`"
    write_log "Backup file is name $PUPPET_BACKUP  ..."
    if [ -d "$PUPPET_CFGDIR" ]
       then cd $PUPPET_CFGDIR
            tar -cvzf $PUPPET_BACKUP . > /dev/null 2>&1
    fi

    # Now let' s uninstall puppet agent - rpm erase will stop puppet if it is running
    write_log "Uninstalling puppet agent ..."
    rpm -e puppet >> $LOG 2>&1

	# Certificate Conflict Warning
	#find /var/lib/puppet/ssl -name ${HOSTNAME}.${DOMAIN}.pem -delete > /dev/null 2>&1
	rm -fr /var/lib/puppet
    write_log "${DASH}"
    write_log "${DASH}"
    write_log " "
	write_log "If the server does not register automatically in Foreman."
	write_log "Or if the server were already register and you reinstall puppet agent"
    write_log " "
	write_log "You may need to run 'puppet cert clean ${HOSTNAME}.${DOMAIN}' on puppet server"
    write_log "And on agent 'find /var/lib/puppet/ssl -name ${HOSTNAME}.${DOMAIN}.pem -delete'"
    write_log "Then run 'puppet agent -t' on agent."
    write_log " "
    write_log "${DASH}"
    write_log "${DASH}"
}


# --------------------------------------------------------------------------------------------------
#                        Main Process of Script - Perform Installation
# --------------------------------------------------------------------------------------------------
install_process()
{
    write_log "The OS Major Version is $OS_VER"
    write_log "The OS is running a $OS_BITS bits kernel version."

    case "$OS_VER" in
        5)  write_log "Subscribing to puppetlabs repository for RHEL $OS_VER"
            rpm -ivh http://yum.puppetlabs.com/puppetlabs-release-el-5.noarch.rpm >> $LOG 2>&1
            ;;
        6)  write_log "Subscribing to puppetlabs repository for RHEL $OS_VER"
            rpm -ivh http://yum.puppetlabs.com/puppetlabs-release-el-6.noarch.rpm >> $LOG 2>&1
            ;;
        7)  write_log "Subscribing to puppetlabs repository for RHEL $OS_VER"
            rpm -ivh http://yum.puppetlabs.com/puppetlabs-release-el-7.noarch.rpm >> $LOG 2>&1
            ;;
        *)  echo "Version $OS_VER is not supported by this script"
            ;;
    esac
    write_log "yum -y install puppet"
    yum -y install puppet  >> $LOG

    # Keep a copy of original puppet.conf
    if [ -f $PUPPET_CFGFILE ]
       then write_log "/bin/cp ${PUPPET_CFGFILE} ${PUPPET_CFGFILE}.`date +%Y_%m_%d_%H_%M_%S`"
            /bin/cp ${PUPPET_CFGFILE} ${PUPPET_CFGFILE}.`date +%Y_%m_%d_%H_%M_%S` >> $LOG 2>&1
    fi

    # Apply our changes to Puppet Agent configuration file
    if [ -d $PUPPET_CFGDIR ]
        then write_log "Modifying /etc/puppet to Add Custom lines ... "
             grep 'server      = puppet.slac.ca' ${PUPPET_CFGFILE} >/dev/null 2>&1
             if [ $? -ne 0 ]
                then echo "                           "	     >> ${PUPPET_CFGFILE}
                     echo "    server      = puppet.maison.ca" >> ${PUPPET_CFGFILE}
                     echo "    report      = true"		     >> ${PUPPET_CFGFILE}
                     echo "    pluginsync  = true"	         >> ${PUPPET_CFGFILE}
                     echo "    moduledir   = /etc/puppet/modules:/var/lib/puppet/modules" >> ${PUPPET_CFGFILE}
                     echo "    environment = $PUPPET_ENV"    >> ${PUPPET_CFGFILE}
             fi
    fi

    # Register Server in Puppet Master - Assuming auto Register is active
    if [ -d $PUPPET_CFGDIR ]
        then write_log "puppet agent --test --noop"
             puppet agent --test --noop >> $LOG 2>&1
             # Setup Puppet Service
             write_log "chkconfig puppet on"
             chkconfig puppet on >> $LOG 2>&1
             write_log "service puppet restart"
             service puppet restart  >> $LOG 2>&1
             write_log "service puppet status"
             service puppet status  >> $LOG 2>&1
             service puppet status
    fi

	# Create Facter Directory
    write_log "Create Facter Directory /etc/facter/facts.d"
    mkdir -p /etc/facter/facts.d >> $LOG 2>&1

    # Create Facter SL File - IDate = Install Date
	echo "IDate = `date +%Y_%m_%d_%H_%M_%S`" > /etc/facter/facts.d/datacenter.txt
    write_log " ";
    write_log "Content of /etc/facter/facts.d/datacenter.txt"
    cat /etc/facter/facts.d/datacenter.txt >> $LOG 2>&1
    write_log " ";


}






# --------------------------------------------------------------------------------------------------
#                                Script Start HERE
# --------------------------------------------------------------------------------------------------
    write_log "Installation of puppet is started ..."
	echo "You may consult the installation log at $LOG"
	init_process
    remove_puppet
    install_process
    end_process
    exit $GLOBAL_ERROR


