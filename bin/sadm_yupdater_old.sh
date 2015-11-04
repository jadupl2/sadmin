#!/bin/bash
#
# yDNS Updater, updates your yDNS host.
# Copyright (C) 2013 Christian Jurk <cj@ydns.eu>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


##
# Define your yDNS account details and host you'd like to update.
##

YDNS_USER="duplessis.jacques@gmail.com"
YDNS_PASSWD="Icu@9am!"
YDNS_HOST="batcave.ydns.eu"
YDNS_LASTIP_FILE="/tmp/ydns_last_ip"

##
# Don't change anything below.
##
YDNS_UPD_VERSION="20141015.1"

if ! hash curl 2>/dev/null; then
	echo "ERROR: cURL is missing."
	exit 1
fi

usage () {
	echo "YDNS Updater"
	echo ""
	echo "Usage: $0 [options]"
	echo ""
	echo "Available options are:"
	echo "  -h             Display usage"
	echo "  -H HOST        YDNS host to update"
	echo "  -u USERNAME    YDNS username for authentication"
	echo "  -p PASSWORD    YDNS password for authentication"
	echo "  -v             Display version"
	echo "  -V             Enable verbose output"
	exit 0
}

## Shorthand function to update the IP address
update_ip_address () {
	# if this fails with error 60 your certificate store does not contain the certificate,
	# either add it or use -k (disable certificate check
	ret=`curl --basic \
		-u "$YDNS_USER:$YDNS_PASSWD" \
		--silent \
		--sslv3 \
		https://ydns.eu/api/v1/update/?host=$YDNS_HOST`

	echo $ret
}

## Shorthand function to display version
show_version () {
	echo "YDNS Updater version $YDNS_UPD_VERSION"
	exit 0
}

## Shorthand function to write a message
write_msg () {
	echo "[`date +%Y/%m/%dT%H:%M:%S`] $1" 
}

verbose=0

while getopts "hH:p:u:vV" opt; do
	case $opt in
		h)
			usage
			;;

		H)
			YDNS_HOST=$OPTARG
			;;

		p)
			YDNS_PASSWD=$OPTARG
			;;

		u)
			YDNS_USER=$OPTARG
			;;

		v)
			show_version
			;;

		V)
			verbose=1
			;;
	esac
done

# Retrieve current public IP address
current_ip=`curl --silent --sslv3 https://ydns.eu/api/v1/ip`
write_msg "Current IP: $current_ip"

# Get last known IP address that was stored locally
if [ -f "$YDNS_LASTIP_FILE" ]; then
	last_ip=`head -n 1 $YDNS_LASTIP_FILE`
else
	last_ip=""
fi

if [ "$current_ip" != "$last_ip" ]; then
	ret=$(update_ip_address)

	case "$ret" in
		badauth)
			write_msg "YDNS host updated failed: $YDNS_HOST (authentication failed)" 2
			exit 90
			;;

		ok)
			write_msg "YDNS host updated successfully: $YDNS_HOST ($current_ip)"
			echo "$current_ip" > $YDNS_LASTIP_FILE
			exit 0
			;;

		*)
			write_msg "YDNS host update failed: $YDNS_HOST ($ret)" 2
			exit 91
			;;
	esac
else
	write_msg "Not updating YDNS host $YDNS_HOST: IP address unchanged" 2
fi
