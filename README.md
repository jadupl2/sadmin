# README #
This project is in constant evolution and is not yet ready for production, althought it is running well.
Jan 2018 - Version 0.74

* SADMIN is Designed to Help Linux/Aix System Administration
* Version 0.74
* [Learn Markdown](https://bitbucket.org/tutorials/markdowndemo)


Quick Start
-----------
Choose a directory (or a filesystem) where you want to install SADMIN. Make sure you have  around 2GB of disk space on the server and 256MB for each client. All SADMIN software and data will reside in that directory (beside MySQL Database).


Define an environment variable name "SADMIN" that contains the directory path, you just chosen. If you chosen to install SADMIN in the directory /opt/sadmin and add the line below to the /etc/environment file.

##### # echo "SADMIN=/opt/sadmin" >> /etc/environment

To make this change to be effective you need to logout and log back in.

Next, run the setup program by typing the command below. This program will ask you some questions and will feed the configuration file ($SADMIN/cfg/sadmin.cfg). This file is used by
every script you you will run and help standardize your SADMIN environnment.

##### # $SADMIN/bin/sadm_setup.py


The Template Script
Once done, run the template shell script ($SADMIN/bin/sadm_template.sh), to make sure everything is ok. The script have been prepared to give you an idea of how you can use the SADMIN tools to develop your own script. When you need to create a new script, you can use this script as a template. 

#### # $SADMIN/bin/sadm_template.sh 


The Wrapper Script
If you want to run your script with SADMIN tools, you can use the sadm_wrapper.sh script to run them. Let's say you want to run a script name 'test.sh' located in $SADMIN/bin you would run it like this:

#### # $SADMIN/bin/sadm_wrapper.sh "$SADMIN/bin/test.sh"


Contribution guidelines
-----------------------
* Writing tests
* Code review
* Other guidelines


Requirements
------------
* python >= 3.x
* bash shell
* sadmin library


Copyright and license
---------------------
The SADMIN is a collection of free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

The SADMIN Tools is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  

See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with nmaptocsv. 
If not, see http://www.gnu.org/licenses/.

Contact
-------
* Jacques Duplessis < jacques.duplessis@sadmin.ca >