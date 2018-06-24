#! /bin/sh
####################################################################################################
# Shellscript	:	sadmin.sh
# Version    	:	2.0
# Author    	:	J.Duplessis
# Date      	:	2018-04-01
# Requires  	:	bash shell
# Synopsis	:   	This script is executed when users login system wide & when system start 
#                   Do not modify this, it could be overwritten by new release.
####################################################################################################
#
# SADMIN root Directory
SADMIN=/opt/sadmin
export SADMIN
#
# Add SADMIN bin and usr/bin to PATH
export PATH=$PATH:${SADMIN}/bin:${SADMIN}/usr/bin
#
