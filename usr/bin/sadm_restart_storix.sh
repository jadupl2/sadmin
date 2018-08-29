#! /usr/bin/env sh
#---------------------------------------------------------------------------------------------------
#   Author      :   Jacques Duplessis
#   Script Name :   sadm_restart_storix.sh
#   Date        :   2018/08/26
#   Requires    :   sh and SADMIN Shell Library
#   Description :   Stop/Start Storix Services
#
#   Note        :   All scripts (Shell,Python,php) and screen output are formatted to have and use 
#                   a 100 characters per line. Comments in script always begin at column 73. You 
#                   will have a better experience, if you set screen width to have at least 100 Chr.
# 
# --------------------------------------------------------------------------------------------------
#
# 2018_08_26    1.0 Initial Release
#
# --------------------------------------------------------------------------------------------------


#===================================================================================================
# Scripts Variables 
#===================================================================================================
SADM_DASH=`printf %80s |tr " " "="`         ; export SADM_DASH          # 80 equals sign line



#===================================================================================================
#                                       Script Start HERE
#===================================================================================================
    tput clear
    SERV="strexecd"
    echo "$SADM_DASH"
    echo "Before Stopping $SERV"
    ps -ef | grep -i $SERV | grep -v grep
    systemctl restart ${SERV}.service > /dev/null 2>&1
    echo "After Starting $SERV"
    ps -ef | grep -i $SERV | grep -v grep
    echo "$SADM_DASH"
    echo " " 
    systemctl status ${SERV}.service
    echo "$SADM_DASH"
    #
    SERV="stqdaemon"
    echo "Before Stopping $SERV"
    ps -ef | grep -i $SERV | grep -v grep
    systemctl restart ${SERV}.service  > /dev/null 2>&1
    echo "After Starting $SERV"
    ps -ef | grep -i $SERV | grep -v grep
    echo "$SADM_DASH"
    echo " " 
    systemctl status ${SERV}.service
    echo "$SADM_DASH"
    #
