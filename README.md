# README V1.2 #
This project is in constant evolution and is almost ready for production
April 2018 - Version 0.85 

* SADMIN is Designed to Help Linux/Aix System Administration
* Version 0.85
* [Learn Markdown](https://bitbucket.org/tutorials/markdowndemo)


Quick Start
-----------
Choose a directory (or a filesystem) where you want to install SADMIN tools. Make sure you have around 2GB of free disk space on the server and 256MB for each client. All SADMIN software and data will reside in that directory (beside MariaDB Database).  For here on, we will assume that you have install SADM in '/opt/sadmin' directory.

### Running the Setup script
Run the setup program by typing the command below. This program will ask you some questions and will feed the configuration file ($SADMIN/cfg/sadmin.cfg). This file is used by
every scripts you will run, the web interface and it help standardize and add flexibility to your SADMIN environnment. The configuration can be modified afterward if you need to. The setup program can be run more than once, so don't worry if you made a mistake, just run it again. 


####    # sudo /opt/sadmin/setup/setup.sh



### The Template Script
To make sure everything is ok, run the template shell script ($SADMIN/bin/sadm_template.sh). The script have been prepared to give you an idea on how you can use the SADMIN tools to develop your own script. When you need to create a new script, you can use this script as a starting point. 

####    # $SADMIN/bin/sadm_template.sh 



### The Wrapper Script
If you want to run your script with SADMIN tools, you can use the sadm_wrapper.sh script to run them. Let's say you want to run a script name 'test.sh' located in $SADMIN/bin you would run it like this:

####    # $SADMIN/bin/sadm_wrapper.sh "$SADMIN/bin/test.sh"


### The SADMIN Shell Library
The SADMIN Shell Library have been develop our script faster, easier to debug, adopt the same standard and our easier to maintain. To have an idea of the what the library offer you, I would suggest that you run the script I use for testing the Library. Just the following script:

####    # $SADMIN/lib/sadmlib_test.sh

It display an example of each function with and global variables that can used and the way you can called them.

THIS IS A VERY SUCCINCT VERSION OF THE DOCUMENTATION , LOT MORE TO COME.



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
* mysql server
* Apache HTTP server



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
