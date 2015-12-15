#!/usr/bin/env sh 
# --------------------------------------------------------------------------------------------------
#  Author:    Jacques Duplessis
#  Title      Jlib_misc.sh
#  Date:      August 2013 
#  Synopsis:  Misc Oriented functions 
# --------------------------------------------------------------------------------------------------
#set -x


fn_exists()
{
    type $1 | grep -q "$1 is a function"
}

#---------------------------------------------------------------------------------------------------
# Pour s'assure qu'un fichier ne depasse pas 2000 entree
#---------------------------------------------------------------------------------------------------
StripFile()
{
    wstrip=$1
    if [ -r "$wstrip" ]
	then
	tail -5000 $wstrip > /tmp/$$
	rm -f $wstrip
	cp /tmp/$$ $wstrip
	rm -f /tmp/$$
    fi
}