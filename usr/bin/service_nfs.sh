#!/bin/bash
# A simple shell script wrapper start / stop / restart nfsv4 services on CentOS / RHEL
# based systems.
# Tested on: RHEL / CentOS but can be ported to Debian or other distros.
# ----------------------------------------------------------------------------
# Author: nixCraft
# Copyright: 2009 nixCraft under GNU GPL v2.0+
# ----------------------------------------------------------------------------
# Last updated: 20/Mar/2013 - Added support for RHEL 6.x
# ----------------------------------------------------------------------------
# Who am I?
_me=${0##*/}
## RHEL/CentOS init.d script names
_server="/etc/init.d/rpcbind /etc/init.d/rpcidmapd /etc/init.d/nfslock /etc/init.d/nfs"
_client="/etc/init.d/rpcbind /etc/init.d/rpcidmapd /etc/init.d/nfslock"
_action="$1"
## Run either server or client script with the following action:
# stop|start|restart|status
##
runme(){
	local i="$1"
	local a="$2"
	for t in $i
	do
		$t $a
	done
}
usage(){
	echo "$_me start|stop|restart|reload|status";
	exit 0
}
[ $# -eq 0 ] && usage
## Main logic
case $_me in
	nfs.server) runme "$_server" "$_action" ;;
	nfs.client) runme "$_client" "$_action" ;;
	*) usage
esac
