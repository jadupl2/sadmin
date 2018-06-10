#!/bin/sh
# --------------------------------------------------------------------------------------------------
#   Author:     Jacques Duplessis
#   Title:      Generate Password hash to be used to set password in script file without 
#               showing the password in clear text.
#   Date:       January 2017
#   Synopsis:   Type in the password and the encrypted form of the password is displayed.
#               You can then use it in the form below in your script
#               # usermod -p "HASH" user
# --------------------------------------------------------------------------------------------------
#   Copyright (C) 2016 Jacques Duplessis <duplessis.jacques@gmail.com>
#
#   The SADMIN Tool is free software; you can redistribute it and/or modify it under the terms
#   of the GNU General Public License as published by the Free Software Foundation; either
#   version 2 of the License, or (at your option) any later version.

#   SADMIN Tools are distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
#   without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#   See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with this program.
#   If not, see <http://www.gnu.org/licenses/>.
# --------------------------------------------------------------------------------------------------
trap 'sadm_stop 0; exit 0' 2                                            # INTERCEPTE LE ^C
#set -x



# --------------------------------------------------------------------------------------------------
echo -n "Enter username : "
read user
echo -n "Enter password : "
read passwd

hash=`echo $passwd | openssl passwd -1 -stdin`
echo    "Password Hash  : $hash" 
echo " " 
echo "usermod -p '$hash' $user" 
echo " " 

