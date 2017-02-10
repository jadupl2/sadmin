#! /usr/bin/env sh
#===================================================================================================
#   Author   :  Jacques Duplessis
#   Title    :  Restart Nagios, NPE  Service 
#   Version  :  1.0
#   Date     :  Februart 2017
#   Requires :  sh
#===================================================================================================
tput clear 
systemctl restart nagios.service
echo " " 
systemctl status nagios.service

