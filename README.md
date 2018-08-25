# SADMIN Tools

If you are a Unix system administrator who is taking care of multiple servers, you probably 
created some scripts to help you keeping your environment stable. SADMIN surely can help you, 
improve and standardize the administration of your server farm.  
For more information visit the [SADMIN web site at <https://www.sadmin.ca>.

## Some features of SADMIN Tools
****
### **Templates Scripts (Shell and Python)**

* Make a copy of the template script, modify it to your need and enjoy :
  * All your script log (*.log) will :
    * Have the same format.
    * Be recorded in the same location ($SADMIN/log).
    * View-able from a Web Interface.
    * Look at them from the command line.
    * You control if you want to append or create a new log at each execution.
    * You decide the maximum of lines you want to keep in the log.
  * Execution history will be recorded (*.rch file) :
    * Script execution date and time (Start and Ending) will be recorded.
    * Execution elapse time is calculated and included in the history file (*.rch).
    * Script ending status is also recorded (Success, Failed).
    * You can receive an email if the script end with Success or Failure (Or no Mail).
    * If the script is currently running they will have a status of "Running".
    * You will able to view the History file from the Web Interface.
    * And you can also look at them from the command line.
    * You control the maximum of lines you want to keep in the RCH file.
    * If you don't want to use the RCH file, you have to option to disable it.
* With the "srch" command, you can even have a status of all your scripts that ran in your server farm.
* Use SADMIN wrapper and run your existing using the SADMIN tools
  * $SADMIN/bin/sadm_wrapper.sh $SADMIN/usr/bin/yourscript.sh
* What happen when one your script fail, are you alerted/advised ?
* In the morning do you have to look in multiple place to check if everything went right last night ?
* Can you look at performance graph of your servers to see or to justify the cpu utilization increase ?
* In case of a disaster recovery situation, do you have all the information on hand to rebuild your servers ?
* When a filesystem/disk is getting full on one of your servers are you alerted ?
* If a service start working, can you restart automatically ?
* Include a frontend tool (sadm) to create/increase/delete filesystem (ext3,ext4,xfs)

If you like one these features, then will certainly find a couple of more interesting things in SADMIN.


## SADMIN is working on most popular Linux distributions
****
* The SADMIN client have been tested to work on Redhat, Fedora, CentOS, Debian, Ubuntu, Raspbian and Aix.
* The SADMIN server should work on any Linux distribution but it's only supported on Redhat, CentOS, Fedora and Debian, Ubuntu and Raspbian distribution.
* In less than 15 minutes, you can install and start using the tools. 
* We have been working for more than two years on these tools and we are happy to release the SADMIN project. We will continue to add and enhance the SADMIN tools over the years to come. We are starting with the basic infrastructure, but there is much more to come, stay tuned.
* Impatient user may want to read the [Quick start guide](https://www.sadmin.ca/www/quickstart.php) first.
  

## Download

* You download the latest version of the SADMIN Project from our [Download page](https://www.sadmin.ca/www/download.php) .
* You can clone the project from [GitHub](https://github.com/jadupl2/sadmin)

```bash
# git clone https://github.com/jadupl2/sadmin.git
```

* You can track the changes by viewing the [Release Archive page](https://www.sadmin.ca/www/archive.php).
<br/>
<br/>
<br/>
<br/>

# Getting Started

## Brief overview

* All the components of the SADMIN tools reside in one directory, we recommend using '/opt/sadmin', but you can install it in the directory of your choice.
* At least 2Gb of free space is recommended for the server installation and 1Gb for the client.
* The instructions below are assuming you have chosen to install it in '/opt/sadmin' directory. The directory you choose can either be a directory or a filesystem.
* An environment variable named 'SADMIN' containing the installation directory you have chosen, is critical for all the tools to work.
* To make sure that this environment variable is defined after a reboot, the installation process will create a script name (/etc/profile.d/sadmin.sh) and will modify the file (/etc/environment).
* The directory '$SADMIN/bin' and $SADMIN/usr/bin will be added to your PATH to ease the use of the SADMIN tools.
* The installation process MUST be executed by the 'root' user.
* IMPORTANT : You need to have an internet access on the system you are installing.
  Some of the packages needed by SADMIN, may not be present on your system and will need to be downloaded.
  On Redhat and CentOS the "EPEL repository" is activated only for the installation time.
  On other distributions the packages needed are available in the distribution repository.

## Installing SADMIN Tools
****
```bash
    Change directory to /opt
    # cd /opt 

    Create a filesystem or directory where you want SADMIN to be install
    # mkdir /opt/sadmin

    Copy the latest version of SADMIN file you have downloaded in '/opt' directory.
    # cp sadmin_x.xx_yyyymmdd.tgz /opt

    Change directory to '/opt/sadmin' directory
    # cd /opt/sadmin

    Untar the file
    # tar -xvzf ../sadmin_x.xx_yyyymmdd.tgz

    Run the setup program (CentOS installation example)
    # /opt/sadmin/setup/setup.sh

```

* Setup program will ask questions regarding your environment and store your answers in the SADMIN configuration file ($SADMIN/cfg/sadmin.cfg). This file is used by the web interface, the SADMIN libraries, the scripts you will create and add flexibility to your SADMIN environment. The configuration can be modified afterward if you need to.
* The setup program can be run more than once, so don't worry if you made a mistake, just run it again.
* If there are missing packages, the setup program will install them for you.
* You will be asked what type of installation you want, a 'SADM server' or a 'SADMIN client'.
* If you are installing a 'SADMIN server', the setup program will install and configure for you the 'Mariadb' (Database) and the Apache Web Server. When installation is finished you will have a working Web SADMIN environment.

After the installation is terminated, you need to log out and log back in before using SADMIN Tools or type the command below (The dot and the space are important), This will 
make sure "SADMIN" environment variable is define.\
```bash
# . /etc/profile.d/sadmin.sh
``` 



## SADMIN Support
****
Should you ran into problem while installing or running the SADMIN tools, please run the 'sadm_support_request.sh', attach the resulting log to an email with a description of your 
problem or question and sent to <support@sadmin.ca>.\
We will get back to you as soon as possible. 

## Authors
****
[Jacques Duplessis](mailto:support@sadmin.com) - *Initial work*.


## License
****
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
