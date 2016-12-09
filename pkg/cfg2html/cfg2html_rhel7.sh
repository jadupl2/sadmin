#
# @(#) $Id: cfg2html,v 6.30 2016/05/03 07:13:17 ralph Exp $
# -------------------------------------------------------------------------
# This is the wrapper for cfg2html for LINUX and HP-UX
# CFG2HTML - license: see GPL v3
# -------------------------------------------------------------------------
# The cfg2html is developed on https://github.com/cfg2html/cfg2html
# The main download area/web site is http://www.cfg2html.com
# SUSE open build service (OBS): https://build.opensuse.org/package/show/home:gdha/cfg2html


PRGNAME=$0
MY_OS=$(uname -s)
args=$@

### this is not optimal and should be simplified. case ...
if [ "$MY_OS" = "Linux" -a ! -f /tmp/cfg2html.respawn ]; then
    touch /tmp/cfg2html.respawn
    exec /bin/bash -O extglob $PRGNAME $args
fi
if [ "$MY_OS" = "HP-UX" -a ! -f /tmp/cfg2html.respawn ]; then
    touch /tmp/cfg2html.respawn
    exec /usr/bin/ksh $PRGNAME $args
fi
if [ "$MY_OS" = "SunOS" -a ! -f /tmp/cfg2html.respawn ]; then
    touch /tmp/cfg2html.respawn
    exec /usr/bin/ksh $PRGNAME $args
fi
if [ "`echo $MY_OS | grep BSD`" -a ! -f /tmp/cfg2html.respawn ]; then
    touch /tmp/cfg2html.respawn
    exec /usr/local/bin/bash $PRGNAME $args
fi
if [ "$MY_OS" = "AIX" -a ! -f /tmp/cfg2html.respawn ]; then
    touch /tmp/cfg2html.respawn
    exec /usr/bin/ksh $PRGNAME $args
fi

rm -f /tmp/cfg2html.respawn # get rid of the temporary lock as soon as possible

####

PRODUCT="Config to HTML - cfg2html"
# this CVS id is also used by the Makefiles to get the version number!
CVS="$Id: cfg2html,v 6.30 2016/05/03 07:13:17 ralph Exp $"
PROGRAM=$(echo $CVS|cut -f2 -d" "|cut -f1 -d,)
#VERSION=6.20
VERSION=6.30-git201609261152
RELEASE_DATE="2016-09-26"
#echo $PROGRAM,$VERSION,$RELEASE_DATE

OS=$(uname)
OS=$(echo $OS | tr 'A-Z' 'a-z' | sed -e 's/-//')
CFG_CMDLINE=$*

COPYRIGHT="Copyright (C) 1999-2016
    ROSE SWE, Dipl.-Ing. Ralph Roth"
STARTTIME=$SECONDS

LANG="C"
LANG_ALL="C"
LC_MESSAGE="C"

## maybe we should skip the root check if the command line option -h or -? is passed?
if  [ "$(whoami)" != "root" -a "$1" != "-h" ]
then
    echo "$(whoami) - You must be root to run the script $PROGRAM"
    exit 1
fi

# introduce trap to make sure the temporary directories get cleaned up
trap "DoExitTasks" 0 1 2 3 6 11 15

# initialize defaults
case $MY_OS in
    HP-UX) TMP_DIR="$(mktemp -d /tmp -p cfg2html_)" ;;
    Linux|SunOS) TMP_DIR="$(mktemp -d /tmp/cfg2html.XXXXXXXXXXXXXXX)" ;;
    *) TMP_DIR="/tmp/${PROGRAM}_${RANDOM}" ;;				## hopefully AIX and SUN have $RANDOM too - why not using mktemp too, its safer! RR
esac

# SHARE_DIR will be redefined (to /opt/$PROGRAM) by 'make depot' not by 'make rpm/deb'
SHARE_DIR="/usr/share/cfg2html"
# /etc/$PROGRAM may contain local.conf (hpux), default.conf always under SHARE_DIR/etc/
CONFIG_DIR="/etc/cfg2html"
# VAR_DIR can be overruled in default.conf or local.conf file (or by -o option)
VAR_DIR="/var/log/cfg2html"

VERBOSE=
DEBUG=

# If cfg2html is installed in a directory not in the PATH ## menguyj@yahoo.fr add 06.03.2012
MYPATH=$(dirname $(type $0 | awk '{print $NF}')) # see issue #18

# define our BASE_DIR according the location of our SHARE_DIR
[[ -d $SHARE_DIR ]] && BASE_DIR="$SHARE_DIR" || BASE_DIR="${MYPATH}/$OS"

# check the CONFIG_DIR and redefine when running from current dir (conf dir renamed to etc)
[[ ! -d $CONFIG_DIR ]] && CONFIG_DIR="$BASE_DIR/etc"

# source of configuration file(s) - important: treat these as scripts
[[ -f $BASE_DIR/etc/default.conf ]] && . $BASE_DIR/etc/default.conf
# source your own configuration file which overrides settings in the default.conf
# in the local.conf you could define OUTPUT_URL settings
[[ -f $BASE_DIR/etc/local.conf ]] && . $BASE_DIR/etc/local.conf
# your personal config file if present will be read as last one (overrule previous settings!)
[[ -f $CONFIG_DIR/local.conf ]] && . $CONFIG_DIR/local.conf

### new date check ###

YEAR=$(date +%Y)    ## current year, e.g. 2016
# YEAR=2018 # for debugging set it into the future
OLD=""
i=2030
# date sanity check. complains if cfg2html is too old, must be adjusted every year to fit
# 

while [ $i -gt 2016 ]   ## where we want to stop, complains if older than two years
do
    [ $YEAR -gt $i ] && OLD=$OLD" very"
    # echo $i - $OLD
    ((i=(i-1)))
    [ "${OLD}" != "" ] && echo "WARNING! This version of cfg2html is$OLD old! Update asap!"
done


# source the include functions
for script in $BASE_DIR/lib/*.sh ; do
    [[ -f $script ]] && . $script
done

# source the main program, e.g. cfg2html-hpux.sh
if [ "`echo $MY_OS | grep BSD`" ]; then
    . $BASE_DIR/${PROGRAM}-bsd.sh
else
    if [[ -f $BASE_DIR/${PROGRAM}-${OS}.sh ]]; then
        . $BASE_DIR/${PROGRAM}-${OS}.sh
    elif [[ -f $BASE_DIR/bin/${PROGRAM}-${OS}.sh ]]; then
        . $BASE_DIR/bin/${PROGRAM}-${OS}.sh
    else
        echo "ERROR: Could not find $BASE_DIR/[bin/]${PROGRAM}-${OS}.sh"
        exit 1
    fi
fi
RETCODE=$?

# define OUTPUT_URL in your local.conf file
CopyFilesAccordingOutputUrl

if [ $RETCODE -eq 0 ]
then
	echo "No errors reported."
else
	echo "Returncode=$RETCODE (see file $ERROR_LOG)"
fi

# cleanup
rm -f /tmp/cfg2html.respawn $LOCK
rm -rf $TMP_DIR

exit $RETCODE
