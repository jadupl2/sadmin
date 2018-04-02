#! /bin/sh
####################################################################################################
# Shellscript	:	sadmin.sh
# Version    	:	2.0
# Author    	:	Jacques Duplessis
# Date      	:	2018-04-01
# Requires  	:	bash shell
# Category  	:	System Administration
# SCCS-Id.  	:	@(#) sadmin.sh V2
# Synopsis	:   	This script is executed when users login system wide & when system start 
#                   Do not modify this, it be overwritten with new release of SADMIN Tools
####################################################################################################
#
# SADMIN root Directory
SADMIN=/sadmin
export SADMIN
#
# Add SADMIN/bin to PATH
export PATH=$PATH:${SADMIN}/bin:
#
