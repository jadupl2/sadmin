#! /bin/sh
####################################################################################################
# Shellscript   :   sadmin.sh
# Version       :   2.2
# Author        :   sadmin.ca
# Date          :   2019-04-08
# Requires      :   bash shell
# Synopsis      :   This script is executed when users login system wide.
#                   Do not modify this, it could be overwritten by new release.
####################################################################################################
#
# SADMIN root Directory
export SADMIN=/opt/sadmin
#
# Add SADMIN bin and usr/bin to PATH
export PATH=$PATH:${SADMIN}/bin:${SADMIN}/usr/bin
#
