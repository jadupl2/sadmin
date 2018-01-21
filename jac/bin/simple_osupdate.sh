#!/bin/bash

# Up -- Debian/Ubuntu Update Tool (Version 1.0)
# Advanced command to fully update system: "up" Adding the option "--clean" will
# remove orphaned packages and auto-clean the apt cache. (January, 2018)
# By Joe Collins www.ezeelinux.com (GNU/General Public License version 2.0)

# Set BASH to quit script and exit on errors:

set -e

# Functions:

update() {

echo "Starting full system update..."
sudo apt-get update
sudo apt-get dist-upgrade -yy

}

clean() {

echo "Cleaning up..."
sudo apt-get autoremove -yy
sudo apt-get autoclean

}

leave() {

echo "--------------------"
echo "- Update Complete! -"
echo "--------------------"
exit

}

up-help() {

cat << _EOF_

 Up is a tool that automates the update procedure for Debian and Ubuntu based
 Linux systems.

 Commands:
    up = full system update.

    Running "up" with no options will update the apt cache and then perform a
    full distribution update automatically.

    up --clean = full system update with cleanup.

    Adding the "--clean" option will invoke the apt commands to search for and
    remove locally cached packages that are no longer in the repositories and
    remove orphaned packages that are no longer needed by programs.

    up --help = shows this help page.

 By Joe Collins www.ezeelinux.com (GNU/General Public License version 2.0)

_EOF_

}

# Execution.

# Tell 'em who we are...

echo "Up -- Debian/Ubuntu Update Tool (Version 1.0)"

# Update and clean:

if [ "$1" == "--clean" ]; then
    update
    clean
    leave
fi

if [ "$1" == "--help" ]; then
    up-help
    exit
fi

# Check for invalid argument

if  [ -n "$1"  ]; then
    echo "Up Error: Invalid argument. Try 'up --help' for more info."
    exit 1
fi

update
leave
