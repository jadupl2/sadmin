#! /bin/sh
BASE_DIR="/var/slac"
LOG="$BASE_DIR/slac.log"
HNAME=`hostname -s`
SYSADMIN="dan.florescu@standardlife.ca,jack.duplessis@standardlife.ca,germain.bernier@stand
ardlife.ca"
echo "============================================" >> $LOG
date >> $LOG
echo "============================================" >> $LOG
echo "VMAC LIST" >> $LOG
ifconfig -a | grep -i vrrp >> $LOG
if [ $? -ne 0 ] ; then echo "No VRRP on $HNAME 1616 - Firewall External Flip at 1245" | mai
l -s "OH OH From 1616" $SYSADMIN ; fi
echo "--------------------------------------------" >> $LOG
echo "NETSTAT " >> $LOG
netstat -i >> $LOG
echo "--------------------------------------------" >> $LOG
/sbin/ping -c3 199.202.211.34 >> $LOG
echo "--------------------------------------------" >> $LOG
echo "VRRP INTERFACE" >> $LOG
clish -c "show vrrp interfaces" >> $LOG
echo "--------------------------------------------" >> $LOG
tail -50000 $LOG > $LOG.$$
rm -f $LOG > /dev/null
mv $LOG.$$ $LOG
chmod 644 $LOG
