#!/bin/sh
# ================================================================================================
# Redhat / CentOS / Fedora / Ubuntu Kickstart Postinstall Script
# IMPORTANT: This script expect to run in a chrooted environment.
# Jacques Duplessis - October 2015
# Version 2.0
#
# ================================================================================================
# Version 2.0 - October 2015 - Jacques Duplessis
#               RHEL 7 Adaptation
# Version 2.5 - December 2015 - Jacques Duplessis
#               Adapted for Fedora 25
# Version 2.7 - January 2017 - Jacques Duplessis
#               Adapted for Ubuntu - Now Working for RedHat/CentOS/Fedora/Ubuntu
#               Tested on Ubuntu 16.04 - Jan 2017
# Version 2.8 - January 2017 - Jacques Duplessis
#               Tested on Ubuntu 14.04 - Jan 2017
# Version 2.9 - January 2017 - Jacques Duplessis
#               Standardize this script to run with all distribution supported
# Version 3.0 - January 2017 - Jacques Duplessis
#               Fix bugs and Tested on Debian V7 and V8 - Retested Fedora 24-25 - CentOS 7
# Version 3.1 - May 2017 - Jacques Duplessis
#               Test to work on RaspBian
#               XRDP Configuration Added fro Raspbian
#               User home directory was not created in Ubuntu/Debian/Raspbian
# Version 3.2 - May 2017 - Jacques Duplessis
#               Disable Multiple Logs - Back to one installation Log
# Version 3.3 - May 2017 - Jacques Duplessis
#               Raspberry Pi Post Installation Validated and Working
# Version 3.4 - May 2017 - Jacques Duplessis
#               Add -y command line switch to run without prompt
# Version 3.5   June 2017 - Jacques Duplessis
#               Added function for Fedora in order to load the loop module at boot time
#               Add Microsoft VsCode Repository and install VsCode at installation
# ================================================================================================
#set -x




# ================================================================================================
#                                 GLOBAL VARIABLES DEFINITION
# ================================================================================================
#
PIVER="3.5"                                             ; export PIVER          # PostInstall Ver.
DASH_LINE=`printf %70s |tr " " "="`                     ; export SADM_DASH      # 70 equals sign line
SRC_DIR=/mnt/nfs                                        ; export SRC_DIR        # NFS MOUNT POINT
GATEWAY=192.168.1.1                                     ; export GATEWAY        # Def. Net Gateway
NETMASK="255.255.255.0"                                 ; export NETMASK        # Def. Netmask
NAME_SERVERS="192.168.1.126 192.168.1.127 8.8.8.8 "     ; export NAME_SERVERS   # Def. DNS Servers
NETWORK="192.168.1.0"                                   ; export NETWORK        # Network
BROADCAST="192.168.1.255"                               ; export broadcast      # Network Broadcast
DOMAIN=maison.ca                                        ; export DOMAIN         # Def. Domain
ETHDEV=`netstat -rn |grep '^0.0.0.0' |awk '{ print $NF }'` ; export ETHDEV      # Eth Device Name
#/bin/ls -1 /sys/class/net | grep -v "^lo"              # Another way to get Interface Name 2B Test
STD_FILES=$SRC_DIR/files                                ; export STD_FILES      # Dir2Copy on server
SOFTWARE=$SRC_DIR/software                              ; export SOFTWARE       # Software Dir.
LOG_DIR=/root                                           ; export LOG_DIR        # Output Log Dir.
LOG_FILE=$LOG_DIR/postinstall.log                       ; export LOG_FILE       # Output Log File
touch $LOG_FILE                                                                 # Create Log File
STORIX_SERVER="storix.maison.ca"                        ; export STORIX_SERVER  # Storix server Name
MAIL_RELAYHOST="relais.videotron.ca"                    ; export MAIL_RELAYHOST # Mail Gateway relay
dmidecode | grep -i vmware > /dev/null 2>&1                                     # Check if a VM
if [ $? -eq 0 ] ; then VMWARE="Y" ; else VMWARE="N" ; fi                        # It is a VM Yes/No?
SAVE_EXTENSION="org"                                    ; export SAVE_EXTENSION # Org file save ext.
TMP_FILE1="/tmp/postinstall_1.$$"                       ; export TMP_FILE1      # Temp File 1
TMP_FILE2="/tmp/postinstall_2.$$"                       ; export TMP_FILE2      # Temp File 2

# Are we using Sysinit or systemd
command -v systemctl > /dev/null 2>&1               # Check if using sysinit or systemd
if [ $? -eq 0 ] ; then SYSTEMD=1 ; else SYSTEMD=0 ; fi
export SYSTEMD

# --------------------------------------------------------------------------------------------------
# We need lsb_release to get Distribution Name and Version Number (Next step below)
# On Fedora putting it in KickStart doesn't work - So we need to install it in this script
echo "Checking if lsb_release is available" >> $LOG_FILE
echo "The command lsb_release is used to determine the distribution name and version" >> $LOG_FILE
which lsb_release >/dev/null 2>&1
if [ $? -ne 0 ]
    then
    echo "lsb_release not available - Trying  to install it - Please wait ..." >>$LOG_FILE
         dnf -y install redhat-lsb >/dev/null 2>&1
         yum -y install redhat-lsb >/dev/null 2>&1
         apt-get -y install lsb-release > /dev/null 2>&1
fi
which lsb_release >/dev/null 2>&1
if [ $? -ne 0 ]
    then echo "Could not install lsb_release command - Installation aborted" >>$LOG_FILE
         exit 1
    else echo "Installation of lsb_release succeeded - Continue the post-installation" >>$LOG_FILE
fi
# --------------------------------------------------------------------------------------------------

# Establish and Validate the Name of OS in Uppercase (CENTOS/REDHAT/UBUNTU/FEDORA)
OS_NAME=`lsb_release -si | tr '[:lower:]' '[:upper:]'`  ; export OS_NAME        # Name of OS
if [ "$OS_NAME" = "REDHATENTERPRISESERVER" ] ; then OS_NAME="REDHAT" ; fi
if [ "$OS_NAME" = "REDHATENTERPRISEAS" ]     ; then OS_NAME="REDHAT" ; fi
if [ "$OS_NAME" != "REDHAT" ] && [ "$OS_NAME" != "CENTOS" ] && [ "$OS_NAME" != "FEDORA" ] &&
   [ "$OS_NAME" != "UBUNTU" ] && [ "$OS_NAME" != "DEBIAN" ] && [ "$OS_NAME" != "RASPBIAN" ]
   then echo  "This version of Linux ($OS_NAME) is currently not supported"
        exit 1
fi

# Determine if the running kernel is a 32 or 64 bits
OS_BITS=`getconf LONG_BIT`                              ; export OS_BITS        # 32 or 64 Bits
if [ $OS_BITS -ne 32 ] && [ $OS_BITS -ne 64 ]
   then write_log "The Kernel version can only be 32 or 64 bits not $OS_BITS"
        exit 1
fi

# Determine the OS Major version For Redhat/CentOS 5,6,7 - Fedora 24,25,26 - Ubuntu 14,15,16
OS_VERSION=`lsb_release -sr| awk -F. '{ print $1 }'| tr -d ' '` ; export OS_VERSION

# Get current IP Address of Server
IPADDR=`ip addr show | grep global | head -1 | awk '{ print $2 }' |awk -F/ '{ print $1 }'`
export IPADDR

# Set the Hostname as per name resolution of IP Address
HOSTNAME=`host $IPADDR | awk '{ print $NF }' | cut -d. -f1` ; export HOSTNAME   # Set Hostname
/bin/hostname ${HOSTNAME}.${DOMAIN}                                     # Set FQN Host Name
echo "${HOSTNAME}.${DOMAIN}" > /etc/hostname                            # Set HostName
hostnamectl set-hostname ${HOSTNAME}.${DOMAIN} > /dev/null 2>&1         # Set Hostname






# ================================================================================================
# Write log function
# ================================================================================================
write_log() {
    printf "%s - %s\n" "`date +"%Y-%m-%d %H:%M"`" "$1" >> $LOG_FILE     # write to log with date
    printf "%s - %s\n" "`date +"%Y-%m-%d %H:%M"`" "$1"                  # write to screen with date
}

#===================================================================================================
#                H E L P       U S A G E    D I S P L A Y    F U N C T I O N
#===================================================================================================
help()
{
    echo " "
    echo "sadm_postinstall.sh usage :"
    echo "             -y   (Run without prompting)"
    echo "             -h   (Display this help message)"
    echo " "
}


# ================================================================================================
# Display Message (Receive as $1) and wait for Y (return 1) or N (return 0)
# ================================================================================================
messok() {
    wmess="$1 [y,n] ? "                                                 # Add Y/N to Mess. Rcv
    wreturn=1                                                           # Return Code Default to No
    while :
        do
        printf "%s" "$wmess"
        read answer                                                     # Read User answer
        case "$answer" in                                               # Test Answer
           Y|y ) wreturn=1                                              # Yes = Return Value of 1
                 break                                                  # Break of the loop
                 ;;
           n|N ) wreturn=0                                              # No = Return Value of 0
                 break                                                  # Break of the loop
                 ;;
             * ) echo ""
                 ;;                                                     # Other stay in the loop
         esac
    done
    return $wreturn
}


# ================================================================================================
# String to Upper Function
# ================================================================================================
toupper() {
    echo $1 | tr  "[:lower:]" "[:upper:]"
}




# ================================================================================================
# Save original file before modifying it - Save it under extension .org ($SAVE_EXTENSION)
# ================================================================================================
save_original()
{
    # Validate number of Parameter received - Should be the name of file to save
    if [ $# -ne 1 ]                                                     # Need 1 Parameter
        then write_log "ERROR : Wrong Number of parameters ($#) in function save_original"
             write_log "ERROR : Parameters received are $*"             # Display what recv
             write_log "ERROR : Post Process installation aborted"      # Advise Aborting
             exit 1                                                     # Abort Process.
    fi

    # Get filename to copy and construct backup filename and record them in the log
    FILE2SAVE="${1}"                        ; export FILE2SAVE          # FileName to save
    FILESAVED="${1}.${SAVE_EXTENSION}"      ; export FILESAVED          # Copy of Original
    #write_log "Saving a copy of the original $FILE2SAVE under $FILESAVED"

    # Test if file doesn't exist
    if [ ! -f "${FILE2SAVE}" ]
        then write_log " "
             write_log "WARNING : Couldn't save original file ${FILE2SAVE} - File doesn't exist"
             write_log " "
             return 1
    fi

    # If file with extension $SAVE_EXTENSION doesn't exist, make copy of original
    if [ ! -f "${FILESAVED}" ]
        then write_log "Making a copy of $FILE2SAVE"
             write_log "cp ${FILE2SAVE} ${FILESAVED}"
             cp ${FILE2SAVE} ${FILESAVED} >> $LOG_FILE 2>&1
        else write_log "Backup of $FILE2SAVE already exist - I will not touch it"
    fi
    write_log " "
}





# ================================================================================================
#                   Write Environnement Variables Used in the Script to log
# ================================================================================================
write_env()
{
    write_log "SCRIPT VERSION  = $PIVER"
    write_log "OS_VERSION      = $OS_VERSION"
    write_log "OS_BITS         = $OS_BITS"
    write_log "SRC_DIR         = $SRC_DIR"
    write_log "STD_FILES       = $STD_FILES"
    write_log "SOFTWARE        = $SOFTWARE"
    write_log "LOG_DIR         = $LOG_DIR"
    write_log "LOG_FILE        = $LOG_FILE"
    write_log "STORIX_SERVER   = $STORIX_SERVER"
    write_log "DOMAIN          = $DOMAIN"
    write_log "HOSTNAME        = $HOSTNAME"
    write_log "/bin/hostname   = `/bin/hostname`"
    write_log "IPADDR          = $IPADDR"
    write_log "NETMASK         = $NETMASK"
    write_log "GATEWAY         = $GATEWAY"
    write_log "ETHDEV          = $ETHDEV"
    write_log "BROADCAST       = $BROADCAST"
    write_log "NETWORK         = $NETWORK"
    write_log "NAME_SERVERS    = $NAME_SERVERS"
    write_log "VMWARE ?        = $VMWARE"
    write_log "OS_NAME         = $OS_NAME"
    write_log "MAIL_RELAYHOST  = $MAIL_RELAYHOST"
    write_log "SYSTEMD ENABLE  = $SYSTEMD (0=Sysinit 1=Systemd)"
}




# ================================================================================================
#                            Setup and Display the /etc/hosts file
# ================================================================================================
setup_host_file()
{
    write_log " " ; write_log " " ; write_log " " ; write_log " " ;
    write_log "========== Setup /etc/hosts"
    save_original "/etc/hosts"                                          # Backup Original
    echo "127.0.1.1     $HOSTNAME.$DOMAIN $HOSTNAME" >> /etc/hosts
    #echo "$IPADDR      $HOSTNAME.$DOMAIN $HOSTNAME" >> /etc/hosts
    write_log "New /etc/hosts content:"
    cat /etc/hosts | while read wline ; do write_log "$wline"; done
}




# ================================================================================================
#                                       Setup network
# ================================================================================================
setup_network()
{
    write_log " " ; write_log " " ; write_log " " ; write_log " " ;
    write_log "========== Setup Network"


    # Setup Network files for RedHat/CentOS/Fedora
    if [ "$OS_NAME" =  "REDHAT" ] || [ "$OS_NAME" =  "CENTOS" ] || [ "$OS_NAME" =  "FEDORA" ]
        then wfile="/etc/sysconfig/network"
             save_original "$wfile"                                     # Backup Original
             write_log "--- Original $wfile content:"
             cat $wfile | while read wline ; do write_log "$wline"; done
             write_log " "
             echo "NETWORKING=yes"                  >  $wfile
             echo "HOSTNAME=$HOSTNAME.$DOMAIN"      >> $wfile
             echo "NOZEROCONF=no"                   >> $wfile
             chown root.root $wfile
             chmod 644 $wfile
             write_log " "
             write_log "--- New $wfile content:"
             cat $wfile | while read wline ; do write_log "$wline"; done
             write_log " "

             wfile="/etc/sysconfig/network-scripts/ifcfg-${ETHDEV}"
             write_log "--- Original $wfile content:"
             sort $wfile | while read wline ; do write_log "$wline"; done
             write_log " "
             save_original "/etc/sysconfig/network-scripts/ifcfg-${ETHDEV}"              # Backup Original
             tmp_file="/tmp/ifcfg-${ETHDEV}"
             cp $wfile $TMP_FILE1
             grep -vEi "ONBOOT|NM_CONTROLLED|BOOTPROTO" $wfile > $TMP_FILE1
             echo "ONBOOT=yes"          >> $TMP_FILE1
             echo "BOOTPROTO=none"      >> $TMP_FILE1
             echo "NM_CONTROLLED=no"    >> $TMP_FILE1
             echo "IPADDR=$IPADDR"      >> $TMP_FILE1
             echo "GATEWAY=$GATEWAY"    >> $TMP_FILE1
             echo "NETMASK=$NETMASK"    >> $TMP_FILE1
             #echo "ETHTOOL_OPTS=\"speed 100 duplex full autoneg off\"" >> $TMP_FILE1
             cp $TMP_FILE1 $wfile
             write_log "--- New $wfile content:"
             sort $wfile | while read wline ; do write_log "$wline"; done
             chmod 0644 $wfile
             chown root.root $wfile
    fi

    # Setup network for Ubuntu/Debian/Raspbian
    if [ "$OS_NAME" =  "UBUNTU" ] || [ "$OS_NAME" =  "DEBIAN" ] || [ "$OS_NAME" =  "RASPBIAN" ]
        then netfile="/etc/network/interfaces"
             save_original "$netfile"                                   # Backup Original
             write_log " "
             write_log "--- Original $netfile content:"
             cat $netfile | while read wline ; do write_log "$wline"; done
             grep -v "$ETHDEV" $netfile > $TMP_FILE1                    # Del old ref to interface
             cp $TMP_FILE1 $netfile                                     # Add to resulting file
             echo " "                                       >> $netfile
             echo "# The primary network interface"         >> $netfile
             echo "auto             $ETHDEV"                >> $netfile
             echo "iface            $ETHDEV inet static"    >> $netfile
             echo "address          $IPADDR"                >> $netfile
             echo "gateway          $GATEWAY"               >> $netfile
             echo "netmask          $NETMASK"               >> $netfile
             echo "network          $NETWORK"               >> $netfile
             echo "broadcast        $BROADCAST"             >> $netfile
             echo "dns-nameservers  $NAME_SERVERS"          >> $netfile
             echo "dns-search       $DOMAIN"                >> $netfile
             echo " "                                       >> $netfile
             write_log " "
             write_log " "
             write_log "--- New $netfile content:"
             cat $netfile | while read wline ; do write_log "$wline"; done
             chmod 0644 $netfile
             chown root.root $netfile
    fi
}



# ================================================================================================
#                           Create the /etc/resolv.conf file
# ================================================================================================
setup_resolv_conf()
{
    wfile="/etc/resolv.conf"
    write_log " " ; write_log " " ; write_log "========== Setup $wfile"
    save_original "$wfile"                                              # Backup Original
    write_log "--- Original $wfile content:"
    cat $wfile | while read wline ; do write_log "$wline"; done

     case "$OS_NAME" in
        "REDHAT"|"CENTOS")
                                echo "domain $DOMAIN"       >> $wfile
                                echo "search $DOMAIN"       >> $wfile
                                for ns in $NAME_SERVERS
                                    do
                                    echo "nameserver $ns "   >> $wfile
                                    done
                                ;;
        "FEDORA")
                                write_log " "
                                write_log "Fedora - Let NetworkManager update /etc/resolv.conf"
                                ;;
        "UBUNTU"|"DEBIAN"|"RASPBIAN")
                                echo "domain $DOMAIN"       >> $wfile
                                echo "search $DOMAIN"       >> $wfile
                                for ns in $NAME_SERVERS
                                    do
                                    echo "nameserver $ns "   >> $wfile
                                    done
                                ;;
        "*" )                   sadm_writelog "OS $OS_NAME not supported yet for updating $wfile"
                                ;;
    esac

    write_log " " ; write_log "--- New $wfile content:"
    cat $wfile | while read wline ; do write_log "$wline"; done
}


# ================================================================================================
# Update the /etc/host.conf (Give priority to host file over DNS for name resolution)
# ================================================================================================
update_etc_host_conf()
{
    MFILE="/etc/host.conf"
    write_log " " ; write_log " " ; write_log " "
    write_log "========== Modify $MFILE file"                           # Log Section in Log
    save_original "$MFILE"                                              # Backup Original
    write_log "--- Original $MFILE content:"
    cat  $MFILE | while read wline ; do write_log "$wline"; done
    write_log " "
    echo "#multi on" > $MFILE                                           # Create file
    echo "order hosts,bind" >> $MFILE                                   # Append to file
    write_log "--- New $MFILE content:"
    cat  $MFILE | while read wline ; do write_log "$wline"; done
}




# ================================================================================================
#                 Install Favorites Custom Softwares from local (NFS) Directory
# ================================================================================================
install_favorites_software()
{
    write_log " " ; write_log " "
    write_log "========== Install Favorites Software for $OS_NAME ${OS_VERSION} ${OS_BITS}Bits"
    SDIR="${SOFTWARE}/std_rpm/${OS_NAME}/${OS_BITS}bits/${OS_VERSION}"
    write_log "Software Directory is ${SDIR}"
    ls -1 ${SDIR} | while read wline ; do write_log "$wline"; done
    write_log " "

    # Put in comment the CDROM from the apt-get sources list
    if [ -f /etc/apt/sources.list ]
        then sed -i -e 's/^deb cdrom:/#deb cdrom:/' /etc/apt/sources.list
    fi


    for soft in `ls ${SDIR}`
        do
        write_log "${DASH_LINE}"
        write_log "Install $soft"
        case "$OS_NAME" in
            "REDHAT"|"CENTOS")
                               if [ "$OS_VERSION" -lt 8 ]
                                  then write_log "yum -y install ${SDIR}/$soft"
                                       yum -y install ${SDIR}/$soft >> $LOG_FILE 2>&1
                                       EC=$?
                                  else write_log "dnf -y install ${SDIR}/$soft"
                                       dnf -y install ${SDIR}/$soft >> $LOG_FILE 2>&1
                                       EC=$?
                               fi
                               ;;
            "FEDORA")
                               write_log "dnf -y install ${SDIR}/$soft"
                               dnf -y install ${SDIR}/$soft  >> $LOG_FILE 2>&1
                               EC=$?
                               ;;
            "UBUNTU"|"DEBIAN"|"RASPBIAN")
                               write_log "dpkg -i ${SDIR}/$soft"
                               dpkg -i ${SDIR}/$soft >> $LOG_FILE 2>&1
                               EC1=$?
                               write_log "apt-get -y -f install"
                               apt-get -y -f install >> $LOG_FILE 2>&1
                               EC2=$?
                               EC=$(($EC1+$EC2))
                               ;;
            "*" )              sadm_writelog "OS $OS_NAME not supported for installing favorites"
                               ;;
        esac
        write_log "Installation Return Code is $EC"
        done
}




# ================================================================================================
#               Install Additionnal Standard Software From Distribution Repository
# ================================================================================================
install_additional_software()
{
    write_log " " ; write_log " " ; write_log " "
    write_log "========== Install Additionnal Software for $OS_NAME ${OS_VERSION} ${OS_BITS}Bits"

     case "$OS_NAME" in
        "REDHAT"|"CENTOS")
                                write_log "========== Install Selected EPEL Repository Packages"
                                EPEL_RPM="figlet xrdp filezilla p7zip p7zip-plugins terminator "
                                EPEL_RPM="$EPEL_RPM gparted rear iftop facter iperf keepassx2 "
                                EPEL_RPM="$EPEL_RPM bwm-ng git qgit tightvncserver Thunar xpdf "
                                EPEL_RPM="$EPEL_RPM qbittorrent gawk"
                                EPEL_RPM="$EPEL_RPM mailx ethtool redhat-lsb-core qbittorrent "
                                EPEL_RPM="$EPEL_RPM redhat-lsb-core dmidecode util-linux bc parted "
                                EPEL_RPM="$EPEL_RPM perl-DateTime "
                                for WRPM in $EPEL_RPM
                                    do
                                    write_log " "
                                    write_log "${DASH_LINE}"
                                    write_log "Install Package $WRPM "
                                    if [ "$OS_VERSION" -lt 8 ]
                                        then write_log "yum -y --enablerepo=epel install $WRPM"
                                             yum -y --enablerepo=epel install $WRPM >> $LOG_FILE 2>&1
                                             EC=$?
                                        else write_log "dnf -y --enablerepo=epel install $WRPM"
                                             dnf -y --enablerepo=epel install $WRPM >> $LOG_FILE 2>&1
                                             EC=$?
                                    fi
                                    write_log "Return code for adding package $WRPM is $EC"
                                    write_log "${DASH_LINE}"
                                    write_log " "
                                    done
                                ;;
        "FEDORA")
                                write_log " "
                                write_log "${DASH_LINE}"
                                write_log "Install Group 'LXDE Desktop''"
                                write_log "dnf group install LXDE Desktop"
                                dnf -y group install "LXDE Desktop" >> $LOG_FILE 2>&1
                                EC=$?
                                write_log "Return code for adding package LXD Desktop is $EC"
                                write_log "${DASH_LINE}"

                                URPM="figlet xrdp postfix rear telnet ftp dmidecode "
                                URPM=" $URPM filezilla facter git iperf bwm-ng qgit ntp nmon ntpdate"
                                URPM=" $URPM mailx ethtool redhat-lsb-core qbittorrent gawk"
                                URPM=" $URPM redhat-lsb-core dmidecode util-linux bc parted "
                                URPM=" $URPM perl-DateTime "
                                for WRPM in $URPM
                                    do
                                    write_log " "
                                    write_log "${DASH_LINE}"
                                    write_log "Installing Package $WRPM"
                                    write_log "dnf -y install $WRPM >> $LOG_FILE 2>&1"
                                    dnf -y install $WRPM  >> $LOG_FILE 2>&1
                                    EC=$?
                                    write_log "Return code for adding package $WRPM is $EC"
                                    write_log "${DASH_LINE}"
                                    write_log " "
                                    done
                                ;;
        "UBUNTU"|"DEBIAN"|"RASPBIAN")
                                UDEB="filezilla p7zip geany terminator "
                                UDEB=" $UDEB iftop figlet facter iperf keepass2 bwm-ng qgit telnet "
                                UDEB=" $UDEB synaptic ftp thunar nmon xpdf deluge dmidecode "
                                UDEB=" $UDEB xrdp ntp ntpdate postfix git mailutils ethtool lsb-release "
                                UDEB=" $UDEB openssh-server util-linux bc gawk apt-file dnsutils"
                                UDEB=" $UDEB libdatetime-perl libwww-perl "
                                if [ "$OS_VERSION" -lt 8 ] ; then UDEB=" $UDEB chkconfig " ; fi
                                write_log "Running apt-get update"
                                apt-get update  >>  $LOG_FILE 2>&1
                                EC=$?
                                write_log "Return code is $EC"
                                write_log " " ; write_log " "
                                for WDEB in $UDEB
                                    do
                                    write_log " "
                                    write_log "${DASH_LINE}"
                                    write_log "Installing Package $WDEB"
                                    #write_log "apt-get -y install $WDEB"
                                    write_log "DEBIAN_FRONTEND=noninteractive apt-get -y install $WDEB"
                                    #apt-get -y install $WDEB >> $LOG_FILE 2>&1
                                    DEBIAN_FRONTEND=noninteractive apt-get -y install $WDEB >> $LOG_FILE 2>&1
                                    EC=$?
                                    write_log "Return code for adding package $WDEB is $EC"
                                    write_log "${DASH_LINE}"
                                    done
                                write_log " "
                                write_log "${DASH_LINE}"
                                write_log "Running apt-get update"
                                apt-get update  >> $LOG_FILE 2>&1
                                EC=$?
                                write_log "Return code after running apt-get update is $EC"
                                write_log "${DASH_LINE}"
                                write_log " "
                                ;;
        "*" )                   sadm_writelog "OS $OS_NAME not supported yet for updating $wfile"
                                ;;
    esac
}




# ================================================================================================
#                   Copy the customized files to their appropriate location
# ================================================================================================
extract_std_files()
{
    write_log " " ; write_log " "
    write_log "========== Untar our standard files/directories to server"

    # Make a copy of original files before overwrite them (If they exist).
    write_log "--- Saving files that will be replace"
    F="/etc/ssh/ssh_config"     ; if [ -f "$F" ] ; then save_original "$F" ; fi
    F="/etc/ssh/sshd_config"    ; if [ -f "$F" ] ; then save_original "$F" ; fi
    F="/etc/ntp.conf"           ; if [ -f "$F" ] ; then save_original "$F" ; fi
    F="/etc/vsftpd/user_list"   ; if [ -f "$F" ] ; then save_original "$F" ; fi
    F="/etc/vsftpd/ftpusers"    ; if [ -f "$F" ] ; then save_original "$F" ; fi
    F="/etc/vsftpd/vsftpd.conf" ; if [ -f "$F" ] ; then save_original "$F" ; fi
    F="/etc/vsftpd.conf"        ; if [ -f "$F" ] ; then save_original "$F" ; fi
    F="/etc/mail/sendmail.cf"   ; if [ -f "$F" ] ; then save_original "$F" ; fi

    write_log "${DASH_LINE}"
    if [ ! -f "${STD_FILES}/files.tar.gz" ]
        then    write_log ""  ; write_log "" ; write_log ""
                write_log "Content of the directory ${STD_FILES}"
                ls -l ${STD_FILES} >> $LOG_FILE 2>&1
                write_log ""
                write_log "Missing Standard Fileset - ${STD_FILES}/files.tar.gz"
                write_log "CREATE OR RECREATE THE FILE AND RUN THE INSTALLATION AGAIN"
                write_log "1- cd /install"
                write_log "2- run this script : ./create_tgz.sh "
                write_log "3- Run installation again"
                return 1
        else    cd /
                write_log ""  ;
                write_log "Untar file ${STD_FILES}/files.tar.gz to server"
                tar -xvzf ${STD_FILES}/files.tar.gz >> $LOG_FILE 2>&1
                EC=$? ; write_log "Return Code of the untar is $EC"
                write_log ""  ;
    fi
    write_log "${DASH_LINE}"

    # Make sure O/S files restore & important files have the right permissions/owner/group
    write_log "--- Making sur file replace have the right owner and permission"
    F="/etc/rear/site.conf"     ; chmod 600 $F ; chown root.root $F
    write_log "chmod 600 $F     ; chown root.root $F"
    F="/etc/systemd/system/sadmin.service"; chmod 644 $F ; chown root.root $F
    write_log "chmod 644 $F     ; chown root.root $F"
    F="/etc/ssh/ssh_config"     ; chmod 644 $F ; chown root.root $F
    write_log "chmod 644 $F     ; chown root.root $F"
    F="/etc/ssh/sshd_config"    ; chmod 644 $F ; chown root.root $F
    write_log "chmod 644 $F     ; chown root.root $F"
    F="/etc/profile.d/sadmin.sh"; chmod 644 $F ; chown root.root $F
    write_log "chmod 644 $F     ; chown root.root $F"
    F="/etc/cfg2html/files"     ; chmod 644 $F ; chown root.root $F
    write_log "chmod 644 $F     ; chown root.root $F"
    F="/etc/ntp.conf"           ; chmod 644 $F ; chown root.root $F
    write_log "chmod 644 $F     ; chown root.root $F"
    F="/root/.forward"          ; chmod 600 $F ; chown root.root $F
    write_log "chmod 600 $F     ; chown root.root $F"
    F="/root/.bash_profile"     ; chmod 750 $F ; chown root.root $F
    write_log "chmod 750 $F     ; chown root.root $F"
    F="/root/.bashrc"           ; chmod 750 $F ; chown root.root $F
    write_log "chmod 750 $F     ; chown root.root $F"
    F="/root"                   ; chmod 750 $F ; chown -R root.root $F
    write_log "chmod 750 $F     ; chown -R root.root $F"
    F="/root/.ssh"              ; chmod 700 $F ; chown root.root $F
    write_log "chmod 700 $F     ; chown root.root $F"
    F="/home"                   ; chmod 755 $F ; chown root.root $F
    write_log "chmod 755 $F     ; chown root.root $F"
    F="/storix"                 ; chmod 755 $F ; chown root.root $F
    write_log "chmod 755 $F     ; chown root.root $F"
    F="/etc/vsftpd/user_list"   ; chmod 700 $F ; chown root.root $F
    write_log "chmod 700 $F     ; chown root.root $F"
    F="/etc/vsftpd/ftpusers"    ; chmod 700 $F ; chown root.root $F
    write_log "chmod 700 $F     ; chown root.root $F"
    F="/etc/vsftpd/vsftpd.conf" ; chmod 700 $F ; chown root.root $F
    write_log "chmod 700 $F     ; chown root.root $F"
    F="/etc/vsftpd.conf"        ; chmod 700 $F ; chown root.root $F
    write_log "chmod 700 $F     ; chown root.root $F"
    F="/etc/vsftpd"             ; chmod 755 $F ; chown root.root $F
    write_log "chmod 755 $F     ; chown root.root $F"
    F="/etc/mail"               ; chmod 755 $F ; chown root.root $F
    write_log "chmod 755 $F     ; chown root.root $F"
    F="/etc/mail/sendmail.cf"   ; chmod 644 $F ; chown root.root $F
    write_log "chmod 644 $F     ; chown root.root $F"
    save_original "/etc/fstab"                      # Backup Original fstab to fstab.org
    write_log "${DASH_LINE}"
    write_log " "
    write_log " "
}



# ================================================================================================
#                       Create My Standard Local System Groups
# ================================================================================================
create_groups()
{
    write_log " " ; write_log " " ; write_log " " ; write_log "========== Create Standard System Groups"
    write_log "groupadd -g 601 sadmin"
    groupadd -g 601 sadmin  >> $LOG_FILE 2>&1

    write_log "groupadd -g 602 storix"
    groupadd -g 603 storix  >> $LOG_FILE 2>&1

    write_log "groupadd -g 603 git"
    groupadd -g 604 git     >> $LOG_FILE 2>&1
}



# ================================================================================================
#                               Create My Standard Local users
# ================================================================================================
create_users()
{
    write_log " " ; write_log " " ;  write_log " "
    write_log "========== Create Standard users"
    write_log "Making sure the nologin shell is valid and functionnal"
    which nologin >/dev/null 2>&1
    if [ $? -ne 0 ]
        then write_log "ERROR : The nologin command is not present on this system"
             write_log "Please correct the situation and re-run this script"
        else NOLOGIN=`which nologin`
             write_log "The nologin shell is located at $NOLOGIN"
             write_log "Adding $NOLOGIN to /etc/shells"
             echo "$NOLOGIN" >> /etc/shells
    fi
    write_log " "
    write_log "New /etc/shells content:"
    cat /etc/shells | while read wline ; do write_log "$wline"; done
    write_log " "

    # SADMIN Tools User
    write_log " "
    write_log "useradd -c 'sadmin user' -s $NOLOGIN -g sadmin -u 601 sadmin"
    useradd -c "sadmin user" -s "$NOLOGIN" -g sadmin -u 601 sadmin  >> $LOG_FILE 2>&1
    usermod -p '$1$hruWioxm$NCp.fse7kVAqYaeA8JidL1' sadmin >> $LOG_FILE 2>&1
    # Under Debian/Ubuntu/Rasbian Home Directory not created
    WHOME="/home/sadmin" ; mkdir $WHOME ; chown sadmin.sadmin $WHOME ; chmod 700 $WHOME
    grep "$WHOME" /etc/passwd >> $LOG_FILE 2>&1
    ls -ld $WHOME  >> $LOG_FILE 2>&1

    # User storix
    write_log " "
    write_log "useradd -c 'Storix user' -s $NOLOGIN -g storix -u 602 storix"
    useradd -c "Storix User" -s $NOLOGIN -g storix -u 602 storix  >> $LOG_FILE 2>&1
    usermod -p '$1$pq3II6r.$DOZlJEwbVOMpJIfyK36js.' storix >> $LOG_FILE 2>&1
    # Under Debian/Ubuntu/Rasbian Home Directory not created
    WHOME="/home/storix" ; mkdir $WHOME ; chown storix.storix $WHOME ; chmod 700 $WHOME
    grep "$WHOME" /etc/passwd >> $LOG_FILE 2>&1
    ls -ld $WHOME  >> $LOG_FILE 2>&1

    # User git
    write_log " "
    write_log "useradd -c 'Git User'                         -g git    -u 603 git"
    useradd -c "Git User" -s $NOLOGIN -g git -u 603 git  >> $LOG_FILE 2>&1
    usermod -p '$1$XnjK1WE5$yUF2PcfN/1tSctn8OvNRk/' git >> $LOG_FILE 2>&1
    # Under Debian/Ubuntu/Rasbian Home Directory not created
    WHOME="/home/git" ; mkdir $WHOME ; chown git.git $WHOME ; chmod 700 $WHOME
    grep "$WHOME" /etc/passwd >> $LOG_FILE 2>&1
    ls -ld $WHOME  >> $LOG_FILE 2>&1

    # User jacques
    write_log " "
    write_log "useradd -c 'Jacques Duplessis'                -g sadmin -u 604 jacques"
    useradd -c "Jacques Duplessis" -g sadmin -u 604 jacques  > /dev/null 2>&1
    write_log "Setting jacques user password"
    usermod -p '$1$OMikOlq8$mUJPnNgyuzhLvg7e9Al07/' jacques >> $LOG_FILE 2>&1
    # Under Debian/Ubuntu/Rasbian Home Directory not created
    WHOME="/home/jacques" ; mkdir $WHOME ; chown jacques.sadmin $WHOME ; chmod 700 $WHOME
    write_log "Making jacques user part of sudo/admin group"
    if [ "$OS_NAME" =  "REDHAT" ] || [ "$OS_NAME" =  "CENTOS" ] || [ "$OS_NAME" =  "FEDORA" ]
        #then usermod -a -G wheel jacques >> $LOG_FILE 2>&1              # sudoers part admin group
        then gpasswd -a jacques wheel    >> $LOG_FILE 2>&1              # sudoers part admin group
        else usermod -a -G sudo  jacques >> $LOG_FILE 2>&1              # sudoers part admin group
    fi
    write_log "Setting jacques account to non-expirable"
    usermod -e '' jacques > /dev/null 2>&1                   # Password do not expire
    grep "$WHOME" /etc/passwd >> $LOG_FILE 2>&1
    ls -ld $WHOME  >> $LOG_FILE 2>&1

    # Set root password exipration to 90 days
    #/usr/bin/chage -M 90 root

    # Root password do not expire
    write_log " "
    write_log "Setting root account to non-expirable"
    usermod -e '' root  > /dev/null 2>&1
}



# ================================================================================================
#                           Create the OpenSSH Keys
# ================================================================================================
create_user_ssh_keys()
{
    SUSER=$1                                                            # Save the SSH user to setup

    write_log " " ; write_log " " ;  write_log " "
    write_log "========== Creating ${SUSER} user ssh keys"
    SSH_DIR="/home/${SUSER}/.ssh"

    # if ${SUSER} user .ssh directory doesn't exist - create it
    if [ ! -d "$SSH_DIR" ]
       then write_log "$SSH_DIR directory do not exist - Creating it"
            mkdir -p $SSH_DIR  >> $LOG_FILE 2>&1
            chmod 700 $SSH_DIR  >> $LOG_FILE 2>&1
            chown ${SUSER}.${SUSER} $SSH_DIR  >> $LOG_FILE 2>&1
    fi

    # if ${SUSER} user ssh private key doesn't exist - generate it
    if [ ! -f "$SSH_DIR/id_rsa" ]
       then write_log "Creating ${SUSER} user ssh keys ..."
            /usr/bin/ssh-keygen -t rsa -N '' -q -f $SSH_DIR/id_rsa >> $LOG_FILE 2>&1
            chown ${SUSER}.${SUSER} $SSH_DIR/id_rsa*  >> $LOG_FILE 2>&1
    fi

    # make a copy of the ${SUSER} public key under a hostname.pub
    write_log "cp $SSH_DIR/id_rsa.pub $SSH_DIR/${HOSTNAME}_ssh.pub"
    cp $SSH_DIR/id_rsa.pub $SSH_DIR/${HOSTNAME}_ssh.pub >> $LOG_FILE 2>&1
    chown ${SUSER}.${SUSER} $SSH_DIR/${HOSTNAME}_ssh.pub  >> $LOG_FILE 2>&1

    # List SSH directory
    write_log "So here is the list of SSH files for $SUSER user"
    ls -l ${SSH_DIR}/id_rsa* ${SSH_DIR}/${HOSTNAME}*.pub  >> $LOG_FILE 2>&1
}




# ================================================================================================
#                                  Configure Syslog
# ================================================================================================
configure_rsyslog()
{
    write_log " " ; write_log " " ; write_log "========== Configure rsyslog "
    write_log "Adding this line at the end of /etc/rsyslog.conf"
    write_log "Adding  *.*    @syslog.maison.ca:514  to /etc/rsyslog.conf"
    echo "*.* @syslog.maison.ca:514"    >> /etc/rsyslog.conf        # Use One @ for UDP Protocol
    #echo "*.* @@syslog.maison.ca:514"    >> /etc/rsyslog.conf      # Use One @ for TCP Protocol
}




# ================================================================================================
#                                    Create /mnt mount point
# ================================================================================================
create_mnt_mount_point()
{
    write_log " " ; write_log " " ; write_log "========== Create /mnt mount Point"
    write_log "mkdir -p /mnt/iso      ; chmod 755 /mnt/iso    ; chown root.root /mnt/iso"
    mkdir -p /mnt/iso >/dev/null 2>&1 ; chmod 755 /mnt/iso    ; chown root.root /mnt/iso

    write_log "mkdir /mnt/usb         ; chmod 755 /mnt/usb    ; chown root.root /mnt/usb"
    mkdir /mnt/usb  >/dev/null 2>&1   ; chmod 755 /mnt/usb    ; chown root.root /mnt/usb

    write_log "mkdir /mnt/nfs"
    mkdir /mnt/nfs              >/dev/null 2>&1
    chmod 755 /mnt/nfs          >/dev/null 2>&1
    chown root.root /mnt/nfs    >/dev/null 2>&1

    write_log "mkdir /mnt/nfs1        ; chmod 755 /mnt/nfs1   ; chown root.root /mnt/nfs1"
    mkdir /mnt/nfs1 >/dev/null 2>&1   ; chmod 755 /mnt/nfs1   ; chown root.root /mnt/nfs1

    write_log "mkdir /mnt/nfs2        ; chmod 755 /mnt/nfs2   ; chown root.root /mnt/nfs2"
    mkdir /mnt/nfs2 >/dev/null 2>&1   ; chmod 755 /mnt/nfs2   ; chown root.root /mnt/nfs2

    write_log "mkdir /mnt/usbkey      ; chmod 755 /mnt/usbkey ; chown root.root /mnt/usbkey"
    mkdir /mnt/usbkey >/dev/null 2>&1 ; chmod 755 /mnt/usbkey ; chown root.root /mnt/usbkey

    write_log "mkdir /mnt/cdrom       ; chmod 755 /mnt/cdrom  ; chown root.root /mnt/cdrom"
    mkdir /mnt/cdrom >/dev/null 2>&1  ; chmod 755 /mnt/cdrom  ; chown root.root /mnt/cdrom
}



# ================================================================================================
# Create file for root user
# ================================================================================================
create_crontab()
{
    write_log " " ; write_log " " ; write_log "========== Creating crontab file for root"

    # Backup Ubuntu/Debian/RaspBian Crontab root file
    if [ -d /var/spool/cron/crontabs ] ; then touch root ; fi   # file not there after installation
    F="/var/spool/cron/crontabs/root" ; if [ -f "$F" ] ; then save_original $F ; fi

    # Backup RedHat/CentOS/Fedora Crontab root file
    F="/var/spool/cron/root" ;          if [ -f "$F" ] ; then save_original $F ; fi

    CFILE="/tmp/postintall.crontab"
    echo "#"                                                                                 >$CFILE
    echo "# Cron does not get a Path when it is run - So We put a standard PATH here"       >>$CFILE
    echo "PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:"               >>$CFILE
    echo "SADMIN=/sadmin"                                                                  >>$CFILE
    echo "#"                                                                                >>$CFILE
    echo "#"                                                                                >>$CFILE
    echo "# =========================================================================="     >>$CFILE
    echo "#        S A D M I N    C L I E N T    T O O L S    S E C T I O N"                >>$CFILE
    echo "# =========================================================================="     >>$CFILE
    echo "#"                                                                                >>$CFILE
    echo "# End Of Day Client Side Jobs"                                                    >>$CFILE
    echo "# MUST be run once a day, just before midnight - Produce Sysinfo/Rotate logs"     >>$CFILE
    echo "55 23 * * * \${SADMIN}/bin/sadm_eod_client.sh > /dev/null 2>&1"                     >>$CFILE
    echo "#"                                                                                >>$CFILE
    echo "# Run every 7 minutes - verify if the nmon daemon is running"                     >>$CFILE
    echo "#  - If not running start it with proper parameters so it finish at 23:55"        >>$CFILE
    echo "*/7 * * * * \${SADMIN}/bin/sadm_nmon_watcher.sh >/dev/null 2>&1"                    >>$CFILE
    echo "#"                                                                                >>$CFILE
    echo "# Run SADM System Monitoring every 6 minutes"                                     >>$CFILE
    echo "*/6 * * * * \${SADMIN}/bin/sadm_sysmon.pl > /dev/null 2>&1"                         >>$CFILE
    echo "#"                                                                                >>$CFILE
    echo "# Activate on Laptop - ReaR Backup every night laptop is left ON"                 >>$CFILE
    echo "#00 01 * * * \${SADMIN}/bin/sadm_rear_backup.sh > /dev/null 2>&1"                   >>$CFILE
    echo "#"                                                                                >>$CFILE
    echo "#"                                                                                >>$CFILE
    crontab $CFILE >> $LOG_FILE 2>&1

    write_log "Content of the root crontab file is now :"
    crontab -l | tee -a $LOG_FILE
    rm -f $CFILE > /dev/null 2>&1
}


# ================================================================================================
#                                   Install Storix Software
# ================================================================================================
install_storix()
{
    write_log " " ; write_log " " ; write_log "========== Install Storix Software"
    if [ "${HOSTNAME}.${DOMAIN}" = $STORIX_SERVER ]
       then write_log "IMPORTANT: This system is Storix Network Administrator."
            write_log "           Please install Storix manually."
            return 1
    fi

    # Setup Storix only for RedHat/CentOS/Fedora
    if [ "$OS_NAME" =  "REDHAT" ] || [ "$OS_NAME" =  "CENTOS" ] || [ "$OS_NAME" =  "FEDORA" ]
        then write_log "Installing Storix Client..."
             mkdir /tmp/storix_install
             cd /tmp/storix_install
             write_log "tar -xvf $SOFTWARE/storix/storix_current_version.tar"
             tar -xvf $SOFTWARE/storix/storix_current_version.tar >> $LOG_FILE 2>&1
             ./stinstall -c -d /storix -p 8181  -s 8182  >> $LOG_FILE 2>&1
             echo "$STORIX_SERVER" >/storix/config/admin_servers
             cd /
             rm -rf /tmp/storix_install
             echo "/tmp/*" >/storix/config/exclude_list
             /opt/storix/bin/stconfigure -t c -a $STORIX_SERVER  >> $LOG_FILE 2>&1
             write_log "Storix Client installed ..."
        else write_log "This version of Linux $OS_NAME is not supported by Storix"
    fi
}



# ================================================================================================
# Remove unwanted files
# ================================================================================================
remove_unwanted_files()
{
    write_log " " ; write_log " " ; write_log "========== Remove unwanted files"
    F="/etc/cron.daily/00-logwatch" ; if [ -f "$F" ] ; then write_log "rm -f $F" ; rm -f $F ; fi
}



# ================================================================================================
#                           Remove uneeded user and group accounts
# ================================================================================================
remove_unwanted_users_and_groups()
{
    write_log " " ; write_log " " ; write_log "========== Remove unwanted users and groups"

    #wuser="uucp"     ; grep "^$wuser" /etc/passwd >/dev/null 2>&1
    #if [ $? -eq 0 ]  ; then write_log "userdel $wuser" ; userdel $wuser >> $LOG_FILE 2>&1 ;fi

    wuser="news"     ; grep "^$wuser" /etc/passwd >/dev/null 2>&1
    if [ $? -eq 0 ]  ; then write_log "userdel $wuser" ; userdel $wuser >> $LOG_FILE 2>&1 ;fi

    wuser="games"    ; grep "^$wuser" /etc/passwd >/dev/null 2>&1
    if [ $? -eq 0 ]  ; then write_log "userdel $wuser" ; userdel $wuser >/dev/null   2>&1 ;fi

    wuser="sync"     ; grep "^$wuser" /etc/passwd >/dev/null 2>&1
    if [ $? -eq 0 ]  ; then write_log "userdel $wuser" ; userdel $wuser >> $LOG_FILE 2>&1 ;fi

    wuser="shutdown" ; grep "^$wuser" /etc/passwd >/dev/null 2>&1
    if [ $? -eq 0 ]  ; then write_log "userdel $wuser" ; userdel $wuser >> $LOG_FILE 2>&1 ;fi

    wuser="halt"     ; grep "^$wuser" /etc/passwd >/dev/null 2>&1
    if [ $? -eq 0 ]  ; then write_log "userdel $wuser" ; userdel $wuser >> $LOG_FILE 2>&1 ;fi

    wuser="operator" ; grep "^$wuser" /etc/passwd >/dev/null 2>&1
    if [ $? -eq 0 ]  ; then write_log "userdel $wuser" ; userdel $wuser >> $LOG_FILE 2>&1 ;fi


    wgroup="games"   ; grep "^$wgroup" /etc/group >/dev/null 2>&1
    if [ $? -eq 0 ]  ; then write_log "groupdel $wgroup" ; groupdel $wgroup >> $LOG_FILE 2>&1 ;fi

    wgroup="news"    ; grep "^$wgroup" /etc/group >/dev/null 2>&1
    if [ $? -eq 0 ]  ; then write_log "groupdel $wgroup" ; groupdel $wgroup >> $LOG_FILE 2>&1 ;fi

    #wgroup="uucp"    ; grep "^$wgroup" /etc/group >/dev/null 2>&1
    #if [ $? -eq 0 ]  ; then write_log "groupdel $wgroup" ; groupdel $wgroup >> $LOG_FILE 2>&1 ;fi
}




# ================================================================================================
# Set Server Date in sync with Master NTP
# ================================================================================================
set_time()
{
    write_log " " ; write_log " " ; write_log "========== Set Server date and Time"
    write_log "ntpdate -u 0.ca.pool.ntp.org"
    ntpdate -u 0.ca.pool.ntp.org >> $LOG_FILE 2>&1
}



# ================================================================================================
#                          Customize Inittab file if still exist
# ================================================================================================
setup_inittab()
{
    # Nothing to setup if file doesn't exist - Not used anymore'
    if [ ! -f /etc/inittab ] ; then return 0 ; fi

    write_log " " ; write_log " " ; write_log "========== Customizing /etc/inittab file"

    # Remove CTRL-ALT-DEL Possibility (Read Hat/Centos Version 3,4,5,6)
    if [ "$OS_NAME" =  "REDHAT" ] || [ "$OS_NAME" =  "CENTOS" ]
        then write_log "Remove CTRL-ALT_DEL = Reboot from /etc/inittab"
             if [ $OS_VERSION -gt 5 ]
                then CTRL="/etc/init/control-alt-delete.conf"
                     CTRL_OVERRIDE="/etc/init/control-alt-delete.override"
                     write_log "Creating $CTRL_OVERRIDE File"
                     grep -vi "shutdown" $CTRL > $CTRL_OVERRIDE
                     echo 'exec /usr/bin/logger -p authpriv.notice -t init "Ctrl-Alt-Del pressed and ignored"' >> $CTRL_OVERRIDE
                     write_log "New $CTRL_OVERRIDE content:"
                     cat  $CTRL_OVERRIDE | while read wline ; do write_log "$wline"; done
                else save_original "/etc/inittab"
                     write_log "Removing CTRL_ALT_DEL from /etc/inittab"
                     cat /etc/inittab.original | sed -e 's/ca::ctrlaltdel/# ca::ctrlaltdel/g' >/etc/inittab
            fi
    fi
}



# ================================================================================================
#                           Perform the initial O/S system Update
# ================================================================================================
perform_os_update()
{
    write_log " " ; write_log " " ; write_log "========== Perform Initial $OS_NAME O/S Update"

    case "$OS_NAME" in
        "REDHAT"|"CENTOS")
                                if [ "$OS_VERSION" -gt 7 ]
                                    then write_log "yum -y update"
                                         yum -y update >>$LOG_FILE 2>&1
                                         EC=$? ; write_log "Return Code of Update is $EC"
                                    else write_log "dnf -y update"
                                         dnf -y update >>$LOG_FILE 2>&1
                                         EC=$? ; write_log "Return Code of Update is $EC"
                                fi
                                ;;

        "FEDORA")
                                write_log "dnf -y update"
                                dnf -y update >>$LOG_FILE 2>&1
                                EC=$? ; write_log "Return Code of Update is $EC"
                                ;;

        "UBUNTU"|"DEBIAN"|"RASPBIAN")
                                write_log "Running : apt-get -y update"
                                apt-get -y update >>$LOG_FILE 2>&1
                                EC=$? ; write_log "Return Code is $EC" ; write_log " "
                                write_log "Running : apt-get -fy install"
                                apt-get -fy install >>$LOG_FILE 2>&1
                                EC=$? ; write_log "Return Code is $EC" ; write_log " "
                                write_log "Running : apt-get -y upgrade"
                                apt-get -y upgrade >>$LOG_FILE 2>&1
                                EC=$? ; write_log "Return Code is $EC" ; write_log " "
                                write_log "Running : apt-get -y dist-upgrade "
                                apt-get -y dist-upgrade  >>$LOG_FILE 2>&1
                                EC=$? ; write_log "Return Code is $EC" ; write_log " "
                                ;;
        "*" )                   sadm_writelog "OS $OS_NAME not supported yet"
                                ;;
    esac
}




# ================================================================================================
# Update the /etc/issue
# ================================================================================================
update_etc_issue()
{
    MFILE="/etc/issue"
    write_log " " ; write_log " " ;  write_log " "
    write_log "========== Modify $MFILE file" # Log Section in Log
    save_original "$MFILE"                                                    # Backup Original
    echo "***AVERTISSEMENT*AVERTISSEMENT*AVERTISSEMENT*AVERTISSEMENT*AVERTISSEMENT**" > $MFILE
    echo "*                                                                        *" >> $MFILE
    echo "*      L'acces a ce systeme doit etre authorise!                         *" >> $MFILE
    echo "*      Toute activitee est sujete a une surveillance!                    *" >> $MFILE
    echo "*                                                                        *" >> $MFILE
    echo "*      Tout tentative d'acces ou acces non-autorise a ce systeme         *" >> $MFILE
    echo "*      est strictement defendu.                                          *" >> $MFILE
    echo "*________________________________________________________________________*" >> $MFILE
    echo "*                                                                        *" >> $MFILE
    echo "*      This system is for authorized use only!                           *" >> $MFILE
    echo "*      All activity may be subject to monitoring!                        *" >> $MFILE
    echo "*                                                                        *" >> $MFILE
    echo "*      Any unauthorized attempts and access to this system is            *" >> $MFILE
    echo "*      strictly prohibited.                                              *" >> $MFILE
    echo "*                                                                        *" >> $MFILE
    echo "**WARNING**WARNING**WARNING**WARNING**WARNING**WARNING**WARNING**WARNING**" >> $MFILE
    write_log "New $MFILE content:"
    cat  $MFILE | while read wline ; do write_log "$wline"; done
}





# ================================================================================================
# Update the /etc/issue
# ================================================================================================
update_etc_issue_net()
{
    MFILE="/etc/issue.net"
    write_log " " ; write_log " " ;  write_log " "
    write_log "========== Modify $MFILE file" # Log Section in Log
    save_original "$MFILE"                                                    # Backup Original
    echo "***AVERTISSEMENT*AVERTISSEMENT*AVERTISSEMENT*AVERTISSEMENT*AVERTISSEMENT**" > $MFILE
    echo "*                                                                        *" >> $MFILE
    echo "*      L'acces a ce systeme doit etre authorise!                         *" >> $MFILE
    echo "*      Toute activitee est sujete a une surveillance!                    *" >> $MFILE
    echo "*                                                                        *" >> $MFILE
    echo "*      Tout tentative d'acces ou acces non-autorise a ce systeme         *" >> $MFILE
    echo "*      est strictement defendu.                                          *" >> $MFILE
    echo "*________________________________________________________________________*" >> $MFILE
    echo "*                                                                        *" >> $MFILE
    echo "*      This system is for authorized use only!                           *" >> $MFILE
    echo "*      All activity may be subject to monitoring!                        *" >> $MFILE
    echo "*                                                                        *" >> $MFILE
    echo "*      Any unauthorized attempts and access to this system is            *" >> $MFILE
    echo "*      strictly prohibited.                                              *" >> $MFILE
    echo "*                                                                        *" >> $MFILE
    echo "**WARNING**WARNING**WARNING**WARNING**WARNING**WARNING**WARNING**WARNING**" >> $MFILE
    write_log "New $MFILE content:"
    cat  $MFILE | while read wline ; do write_log "$wline"; done
}



# ================================================================================================
# Create custom /etc/motd
# ================================================================================================
update_etc_motd()
{
    MFILE="/etc/motd"
    if [ ! -f "$MFILE" ] ; then return ; fi                             # if file not exist
    write_log " " ; write_log " " ;  write_log " " ;
    write_log "========== Modify $MFILE file"                           # Log Section in Log
    save_original "$MFILE"                                              # Backup Original
    figlet "$HOSTNAME" > $MFILE                                         # Create file
    write_log "New $MFILE content:"
    cat  $MFILE | while read wline ; do write_log "$wline"; done
}



# ================================================================================================
#                     Make sure login on console are not in GUI but in ASCII mode
# ================================================================================================
set_console_mode()
{
    write_log " " ; write_log " " ;  write_log " " ;
    write_log "========== Turn Off Graphical Console at login"
    if [ "$SYSTEMD" -eq 0 ]
       then save_original "/etc/inittab"                                        # Backup Original
            cp /etc/inittab /tmp/inittab.bak
            sed 's/id:5:initdefault/id:3:initdefault/' /tmp/inittab.bak > /etc/inittab
            rm -f /tmp/inittab.bak > /dev/null 2>&1
       else write_log "Login in text mode - systemctl set-default -f multi-user.target"
            systemctl set-default -f multi-user.target >>$LOG_FILE 2>&1
            systemctl get-default >>$LOG_FILE 2>&1
    fi

    write_log " "
    write_log "Remove Authentication popup when run vnc or xrdp"
    write_log "echo 'X-GNOME-Autostart-enabled=false' >> /etc/xdg/autostart/gnome-software-service.desktop"
    echo "X-GNOME-Autostart-enabled=false" >> /etc/xdg/autostart/gnome-software-service.desktop
}



# ================================================================================================
# Remove certains package for security reason
# ================================================================================================
remove_packages()
{
    write_log " " ; write_log " " ; write_log "========== Removing unnecessary packages"
    write_log "No Package to remove for now"
#    if [ "$OS_NAME" =  "REDHAT" ] || [ "$OS_NAME" =  "CENTOS" ] || [ "$OS_NAME" =  "FEDORA" ]
#       then write_log "rpm -e setserial"
#            rpm -e setserial >> $LOG_FILE 2>&1
#       else write_log "apt-get remove package"
#            apt-get remove package >> $LOG_FILE 2>&1
#    fi
}



# ================================================================================================
# Update the /etc/postfix/main.cf
# ================================================================================================
update_etc_postfix_main_cf()
{
    MFILE="/etc/postfix/main.cf"
    if [ ! -f "$MFILE" ] ; then return ; fi                             # if file not exist
    write_log " " ; write_log " " ;  write_log " "
    write_log "========== Update $MFILE file"                           # Log Section in Log
    save_original "$MFILE"                                              # Backup Original

    grep -vi "^myorigin ="  $MFILE     > $TMP_FILE1
    grep -vi "^relayhost =" $TMP_FILE1 > $MFILE
    echo "myorigin  = ${DOMAIN}" >> $MFILE                              # Append to file
    echo "relayhost = ${MAIL_RELAYHOST}" >> $MFILE                      # Append to file

    write_log "myorigin=${DOMAIN} - Was added at the end of $MFILE"     # Append to file
    write_log "relayhost=${MAIL_RELAYHOST} - Was added at the end of $MFILE" # Append to file
    write_log "tail -2 $MFILE"
    tail -2 $MFILE | while read wline ; do write_log "$wline"; done
}



# ================================================================================================
#                               Add Microsoft VSCode Repository
# ================================================================================================
add_vscode_repository()
{

    # VsCode Setup for specific O/S
    case "$OS_NAME" in
        "REDHAT"|"CENTOS"|"FEDORA")
                write_log "VsCode Setup for ${OS_NAME}" ; write_log " "
                write_log "rpm --import https://packages.microsoft.com/keys/microsoft.asc"
                rpm --import https://packages.microsoft.com/keys/microsoft.asc
                W="/etc/yum.repos.d/vscode.repo"
                write_log "Creating the repository file $W
                echo "[code]"                                                   >  $W
                echo "name=Visual StudioCode"                                   >> $W
                echo "baseurl=https://packages.microsoft.com/yumrepos/vscode"   >> $W
                echo "enabled=1 "                                               >> $W
                echo "gpgcheck=1"                                               >> $W
                echo "gpgkey=https://packages.microsoft.com/keys/microsoft.asc" >> $W
                if [ "$OS_NAME" == "FEDORA" ]
                    then write_log "dnf -y install code"
                         dnf -y install code
                    else write_log "yum -y install code"
                         yum -y install code
                fi
                ;;
        "UBUNTU"|"DEBIAN"|"LINUXMINT")
                write_log "VsCode Setup for ${OS_NAME}" ; write_log " "
                curl https://packages.microsoft.com/keys/microsoft.asc |gpg --dearmor >microsoft.gpg
                mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
                W="/etc/apt/sources.list.d/vscode.list"
                write_log "Creating the repository file $W
                echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" >$W
                write_log " " ; write_log "apt-get -y update"
                apt-get -y update >> $LOG_FILE 2>&1
                RC=$? ; write_log "Return code of previous command is $RC" ; write_log " "
                write_log " " ; write_log "apt-get -y install code"
                apt-get -y install code >> $LOG_FILE 2>&1
                RC=$? ; write_log "Return code of previous command is $RC" ; write_log " "
                ;;
        "*" )
                sadm_writelog "VsCode not available on $OS_NAME"
                ;;
    esac

}






# ================================================================================================
#                    Add EPEL Repository Only for RedHat and CentOS Installation
# ================================================================================================
add_epel_repository()
{
    if [ "$OS_NAME" !=  "REDHAT" ] && [ "$OS_NAME" !=  "CENTOS" ] ; then return ; fi
    write_log " " ; write_log " " ; write_log "========== Add EPEL Repository "

    write_log "yum -y install -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm"
    yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm >>$LOG_DIR/add_epel.log 2>&1
    EC=$? ; write_log "Return code after adding repository is $EC"

    # Disable EPEL Repository from the YUM update
    write_log "Disable the EPEL Repository from normal yum update"
    write_log "perl -p -i -e 's/enabled=1/enabled=0/g'  /etc/yum.repos.d/epel.repo"
    perl -p -i -e 's/enabled=1/enabled=0/g'  /etc/yum.repos.d/epel.repo
    EC=$? ; write_log "Return code after changing epel.repo is $EC"

    write_log " " ; write_log "Content of  cat /etc/yum.repos.d/epel.repo"
    cat /etc/yum.repos.d/epel.repo >> $LOG_FILE 2>&1
}




# ==================================================================================================
#               Making sure sadm_startup/sadm_shutdown script are executed
#                   Now that sadmin has been copied, enable service
# ==================================================================================================
enable_sadmin_service()
{
    write_log " " ; write_log " " ; write_log "========== Enabling SADM Startup/Shutdown Script"
    write_log "Setup sadmin service"

    write_log "Query sadmin.service status"
    if [ $SYSTEMD -eq 0 ]
       then chkconfig --list | grep sadmin >> $LOG_FILE 2>&1
       else systemctl --no-pager list-unit-files |grep sadmin.service >> $LOG_FILE 2>&1
    fi
    #write_log " " ; service_disable sadmin.service >> $LOG_FILE 2>&1
    write_log " " ; service_enable  sadmin.service >> $LOG_FILE 2>&1

    write_log "Query sadmin.service status"
    if [ $SYSTEMD -eq 0 ]
        then chkconfig --list | grep sadmin >> $LOG_FILE 2>&1
             find /etc/rc.d -name "*sadmin*" >> $LOG_FILE 2>&1
        else systemctl --no-pager list-unit-files |grep sadmin.service >> $LOG_FILE 2>&1
             find /etc/systemd/system -name "*sadmin*" >> $LOG_FILE 2>&1
             systemctl status sadmin.service  >> $LOG_FILE 2>&1
    fi
}




# ==================================================================================================
#                               Disable Linux Service
# ==================================================================================================
service_disable()
{
    write_log "--- Disabling service '$1' ..."                              # Advise action 2 log
    if [ $SYSTEMD -eq 1 ]                                               # Using systemd not Sysinit
        then write_log "systemctl disable $1"                           # write cmd to log
             systemctl disable $1 >> $LOG_FILE 2>&1                     # use systemctl to disable
             systemctl list-unit-files | grep $1 >> $LOG_FILE 2>&1       # Display Service Status
        else write_log "chkconfig $1 off"                               # write cmd to log
             chkconfig $1 off    >> $LOG_FILE 2>&1                      # disable service
    fi
    write_log ""                                                        # Blank LIne
}



# ==================================================================================================
#                               Enable Linux Service
# ==================================================================================================
service_enable()
{
    write_log "--- Enabling service '$1' ..."                               # action to log
    if [ $SYSTEMD -eq 1 ]                                               # Using systemd not Sysinit
        then write_log "systemctl enable $1"                            # write cmd to log
             systemctl enable $1    >> $LOG_FILE 2>&1                   # use systemctl
             systemctl list-unit-files | grep $1 >> $LOG_FILE 2>&1       # Display Service Status
        else write_log "chkconfig $1 on"                                # write cmd to log
             chkconfig $1 on    >> $LOG_FILE 2>&1                       # enable service
    fi
    write_log ""                                                        # Blank LIne
}



# ==================================================================================================
#                               Status of Linux Service
# ==================================================================================================
service_status()
{
    write_log "--- Status of service '$1' ..."                              # write action to log
    if [ $SYSTEMD -eq 1 ]                                               # Using systemd not Sysinit
        then write_log "systemctl status $1"                            # write cmd to log
             systemctl status $1 >> $LOG_FILE 2>&1                      # use systemctl
             systemctl list-unit-files | grep $1 >> $LOG_FILE 2>&1       # Display Service Status
        else write_log "service $1 status"                              # write cmd to log
             service $1 status >> $LOG_FILE 2>&1                        # Show service status
    fi
}



# ==================================================================================================
#                               Stop Linux Service
# ==================================================================================================
service_stop()
{
    write_log "--- Stopping service '$1' ..."                               # write action to log
    if [ $SYSTEMD -eq 1 ]                                               # Using systemd not Sysinit
        then write_log "systemctl stop $1"                              # write cmd to log
             systemctl stop $1    >> $LOG_FILE 2>&1                     # use systemctl
             systemctl status $1 >> $LOG_FILE 2>&1
        else write_log "service $1 stop"                                # write cmd to log
             service $1 stop >> $LOG_FILE 2>&1                          # stop the service
             service $1 status >> $LOG_FILE 2>&1                        # status the service
    fi
}



# ==================================================================================================
#                               Start Linux Service
# ==================================================================================================
service_start()
{
  write_log "--- Starting service '$1' ..."
    if [ $SYSTEMD -eq 1 ]                                               # Using systemd not Sysinit
        then write_log "systemctl start $1"
             systemctl start  $1 >> $LOG_FILE 2>&1
             systemctl status $1 >> $LOG_FILE 2>&1
        else write_log "service $1 start"
             service $1 start >> $LOG_FILE 2>&1
             service $1 status >> $LOG_FILE 2>&1                        # status the service
    fi
}

# ==================================================================================================
#    Once our Standard SSH configuration is in place, make sure sftp server is the right one
#     sftp server line is different on RedHat/Centos/Fedora than on Ubuntu/Debian/Raspbian
# ==================================================================================================
update_sshd_config()
{
    write_log " " ; write_log " " ; write_log " "
    write_log "========== Setup sshd_config"

    MFILE="/etc/ssh/sshd_config"                                        # Actual Std SSHD Conf. File
    MFILE_ORG="/etc/ssh/sshd_config.org"                                # Get sftp server from Orig.
    grep -vi "sftp"  $MFILE      > $TMP_FILE1                           # Remove sftp line
    grep -i "sftp"   $MFILE_ORG >> $TMP_FILE1                           # Add sftp line from org
    cp $TMP_FILE1 $MFILE                                                # Put modified cfg in place

    write_log " "
    write_log "New $MFILE content:"
    cat $MFILE | while read wline ; do write_log "$wline"; done         # Print sshd cfg content
}


# ==================================================================================================
#                           Install Configuration for XRDP under Raspbian
# ==================================================================================================
setup_raspbian_xrdp()
{
    if [ "$OS_NAME" != "RASPBIAN" ] ; then return ; fi
    write_log " " ; write_log " " ; write_log " "
    write_log "========== Setup Raspbian XRDP"

    write_log " " ; write_log "apt-get -y update"
    apt-get -y update >> $LOG_FILE 2>&1
    RC=$? ; write_log "Return code of previous command is $RC" ; write_log " "


    # Proper Packages must be installed in order
    write_log " " ; write_log "apt-get -y remove xrdp vnc4server tightvncserver"
    apt-get -y remove xrdp vnc4server tightvncserver >> $LOG_FILE 2>&1
    RC=$? ; write_log "Return code of previous command is $RC" ; write_log " "

    write_log " " ; write_log "apt-get -y install tightvncserver"
    apt-get -y install tightvncserver >> $LOG_FILE 2>&1
    RC=$? ; write_log "Return code of previous command is $RC" ; write_log " "

    write_log " " ; write_log "apt-get -fy install "
    apt-get -fy install  >> $LOG_FILE 2>&1
    RC=$? ; write_log "Return code of previous command is $RC" ; write_log " "

    write_log " " ; write_log "apt-get -y install xrdp"
    apt-get -y install xrdp >> $LOG_FILE 2>&1
    RC=$? ; write_log "Return code of previous command is $RC" ; write_log " "

    # Make sure Xrdp/VNC Password Dir exist
    if [ ! -d "/home/jacques/.vnc" ]
        then write_log " "
             write_log "mkdir -p /home/jacques/.vnc"
             mkdir -p /home/jacques/.vnc  >> $LOG_FILE 2>&1
             chmod 750 /home/jacques/.vnc  >> $LOG_FILE 2>&1
    fi

    # Change Cross Cursor to Normal Arrow Cursor on Desktop (Bug)
    write_log "echo 'xsetroot -cursor_name left_ptr &' > /home/jacques/.xsessionrc"
    echo "xsetroot -cursor_name left_ptr &" > /home/jacques/.xsessionrc
    chmod 750 /home/jacques/.xsessionrc

    # Make sure everything in /home/jacques is owned by jacques.sadmin
    write_log "chown -R jacques.sadmin /home/jacques"
    chown -R jacques.sadmin /home/jacques     >> $LOG_FILE 2>&1
    write_log " "
    service_enable xrdp
    write_log " "
}

# ==================================================================================================
#                                       Special Setup for Fedora
# ==================================================================================================
fedora_setup()
{
    # Storix need the loop module loaded in order to produce the bootable media
    if [ "$OS_VERSION" -gt 22 ]                                     # Version 23 and Above
       then WFILE="/etc/modules-load.d/loop.conf"
            echo "# Load loop at boot" > $WFILE
            echo "loop" >> $WFILE
            chown root.root $WFILE ; chmod 644 $WFILE
    fi

}




# ==================================================================================================
#                                           Setup Services
# ==================================================================================================
setup_services()
{
    write_log " " ; write_log " " ; write_log " "
    write_log "========== Setup Services"

    # disable service we don't want
    write_log " "
    service_disable mdmonitor                           # Disable Disk Array Monitor
    write_log " "
    #service_disable nfs                                 # Disable nfs server
    write_log " "
    #service_disable bluetooth                           # Disable Bluetooth for server
    write_log " "
    service_disable avahi-daemon                        # Disable Apple ZeroConf  Bonjour Network
    write_log " "
    service_disable iscsid                              # Disable SCSI over IP (client)
    write_log " "
    service_disable iscsid                              # Disable Iscsi Daemon (server)
    write_log " "
    service_disable abrtd                               # Disable Auto Bug Reporting Tool Daemon
    write_log " "
    service_disable abrt-ccpp                           # Disable Auto Bug Reporting Tool Daemon
    write_log " "
    service_disable abrt-oops                           # Disable Auto Bug Reporting Tool Daemon
    write_log " "
    service_disable abrt-vmcore                         # Disable Auto Bug Reporting Tool Daemon
    write_log " "
    service_disable abrt-xorg                           # Disable Auto Bug Reporting Tool Daemon
    write_log " "
    service_disable qemu-guest-agent                    # Qemulator used for KVM
    write_log " "
    service_disable spice-vdagentd                      # USed with RHEV Env. for Virtual Server
    write_log " "
    service_disable ModemManager                        # Modem Manager (2G/3G/4G Devices)
    write_log " "
    service_disable libvirtd                            # Virtual device for VM
    write_log " "


    # Setup Network and Firewall Service per Distribution
    case "$OS_NAME" in
        "REDHAT"|"CENTOS")      service_disable firewalld               # Disable Firewall
                                if [ "$OS_VERSION" -gt 6 ]              # Version 7 and Above
                                    then service_enable  NetworkManager # Redhat Recommend ON in V7
                                    else service_disable NetworkManager # V6 and Below Leave OFF
                                fi
                                write_log " " ; write_log " "
                                ;;
        "FEDORA")               write_log " " ; write_log " "
                                service_disable firewalld               # Disable Firewall
                                systemctl mask firewalld                # Without this start on boot
                                write_log " " ; write_log " "
                                service_enable  NetworkManager
                                ;;
        "UBUNTU"|"DEBIAN"|"RASPBIAN")
                                write_log " " ; write_log " "
                                service_disable firewalld               # Disable Firewall
                                write_log " " ; write_log " "
                                service_disable NetworkManager
                                ;;
        "*" )                   sadm_writelog "OS $OS_NAME not supported yet"
                                ;;
    esac

    write_log " "
    if [ "$OS_NAME" != "RASPBIAN" ]
       then service_enable network
            service_enable sshd
       else service_enable networking
            service_enable ssh
    fi

    write_log " "
    service_enable postfix

    write_log " "
    service_enable rsyslog

    write_log " "
    service_enable ntpdate                             # Seems to have been raplace by chronyd ?

    write_log " "
    service_enable xrdp

    write_log " " ; write_log " " ; write_log " " ;
    write_log "========== Listing of all Enable Services"
    if [ "$SYSTEMD" -eq 1 ]
       then write_log "systemctl --no-pager list-unit-files | grep '.service' |grep -i enable | sort | nl"
            systemctl --no-pager list-unit-files | grep '.service' |grep -i enable | sort | nl >> $LOG_FILE 2>&1
       else write_log "chkconfig --list | grep -iE '3:on|5:on'"
            chkconfig --list | grep -iE "3:on|5:on"  >> $LOG_FILE 2>&1

    fi
}



# ==================================================================================================
#                   S T A R T   O F   T H E   M A I N   S C R I P T
# ==================================================================================================
    tput clear
    write_log " " ; write_log "========== Start of postinstall script "
    write_env                                       # Write ENv. Variable to log

    # Optional Command line switches
    PROMPT="ON"                                                         # Set Switch Default Value
    while getopts "yh" opt ; do                                         # Loop to process Switch
        case $opt in
            y) PROMPT="OFF"                                             # Run Without Prompt
               ;;                                                       # No stop after each page
            h) help                                                     # Display Help Usage
               sadm_stop 0                                              # Close the shop
               exit 0                                                   # Back to shell
               ;;
           \?) echo "Invalid option: -$OPTARG" >&2                      # Invalid Option Message
               help                                                     # Display Help Usage
               exit 1                                                   # Exit with Error
               ;;
        esac                                                            # End of case
    done

    # If -y command line switch was not specified - Display Warning & Wait for confirmation
    if [ "$PROMPT" != "OFF" ]
        then    echo "This is the Post-Intallation script."
                echo "Server will reboot after running this script."
                echo "You may want to review this log after the reboot ($LOG_FILE)."
                echo " "
                messok "Still want to proceed "                         # Wait for user Answer (y/n)
                if [ "$?" -eq 0 ] ; then exit 1 ; fi                    # Do not proceed
    fi


    # Setup Network
    setup_host_file                                 # Setup /etc/hosts file
    setup_network                                   # Setup network configuration file
    setup_resolv_conf                               # Setup /etc/resolv.conf
    update_etc_host_conf                            # Prioritize host file file over DNS

    # Install and Update Software we want
    perform_os_update                               # Install latest O/S update
    add_epel_repository                             # Add EPEL Repository For CentOS and RedHat
    add_vscode_repository                           # Add Microsoft VsCode Repo & Install VsCode
    install_additional_software                     # Install Additional Software From Dist. Repos
    install_favorites_software                      # Install Favorites Custom Software


    # Setup Users and Groups
    create_groups                                   # Create std needed group
    create_users                                    # Create standard users
    create_user_ssh_keys "sadmin"                   # Create the sadmin user OpenSSH keys

    # Setup Customs Configuration files and directories
    extract_std_files                               # Copy standard custom files onto system
    set_time                                        # Set Server time and Date
    create_mnt_mount_point                          # Create /mnt mount point
    update_etc_issue                                # Update /etc/issue
    update_etc_issue_net                            # Update /etc/issue.net
    update_etc_motd                                 # Create /etc/motd file from HOSTNAME
    set_console_mode                                # Turn off login in Graphical Mode
    update_etc_postfix_main_cf                      # Update /etc/postfix/main.cf
    update_sshd_config                              # Make change to sftp server if needed

    # Setup Services
    configure_rsyslog                               # Configure rsyslog.conf
    create_crontab                                  # Create crontab file for root user
    install_storix                                  # Install Storix Software
    enable_sadmin_service                           # Make sure rc.startup get executed
    setup_raspbian_xrdp                             # Special Install/Config for Raspberry Pi XRDP
    setup_services                                  # Disable/Enable Services for Security & Usage

    # Final Setup - Securing the Environment
    remove_packages                                 # Remove certains Packages for security reason
    remove_unwanted_files                           # remove unwanted files
    remove_unwanted_users_and_groups                # Remove unneeded users and groups
    setup_inittab                                   # Disable CTRL-ALT-DEL (Old Version)

    # Special Setup for specific O/S
    case "$OS_NAME" in
        "REDHAT"|"CENTOS")      write_log "Special Setup for ${OS_NAME}" ; write_log " "
                                ;;
        "FEDORA")               write_log "Special Setup for ${OS_NAME}" ; write_log " "
                                fedora_setup
                                ;;
        "UBUNTU"|"DEBIAN"|"RASPBIAN"|"LINUXMINT")
                                write_log "Special Setup for ${OS_NAME}" ; write_log " "
                                ;;
        "*" )                   sadm_writelog "No Special Setup Exist for $OS_NAME"
                                ;;
    esac

    # End of Post-installation
    write_log " " ; write_log " "                   # White lines in Log
    write_log "End of SADM_Postscript file"         # Signal end of script
    write_log " " ; write_log " "                   # White lines in Log
    write_log "Rebooting ... "                      # Signal end of script
    write_log " " ; write_log " "                   # White lines in Log
    reboot
