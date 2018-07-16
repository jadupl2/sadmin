#! /bin/sh
# J.Duplessis - July 2018
# List Active Services on system
# ------------------------------------------------------------
# Change Log
# 2018_07_16 v1.0 Initial Version
# ------------------------------------------------------------
tput clear
systemctl list-units -t service --state active

