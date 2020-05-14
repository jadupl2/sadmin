![SADMIN Tools][1] 
SADMIN Tools v1.2.6

- [Brief description](#brief-description)
- [Run on most popular Linux distributions](#run-on-most-popular-linux-distributions)
- [Download](#download)
- [Before you install](#before-you-install)
- [Installing SADMIN Tools](#installing-sadmin-tools)
  - [Method 1 : Cloning our git repository (Recommended)](#method-1--cloning-our-git-repository-recommended)
  - [Method 2 : Using the downloaded 'tgz' file](#method-2--using-the-downloaded-tgz-file)
  - [Running the setup script](#running-the-setup-script)
- [SADMIN Support](#sadmin-support)
- [Authors](#authors)
- [Copyright and license](#copyright-and-license)
  
---

## Brief description

**The SADMIN tools is a series of command line and web interface that allow you to :**

* **Scripts Framework and Monitoring Tools**
  * The SADMIN server is the central place for monitoring scripts running on your systems.
  * View the [status of all your scripts](https://www.sadmin.ca/img/sadm_web_scripts_status.png) that run in your server farm.
  * Access script log from SADMIN server [Web interface](https://www.sadmin.ca/img/sadm_view_logs.png) or from the [command line](https://www.sadmin.ca/img/file_log_format.png).
  * Choose to be alerted or not by ['SMS/Texto'](https://www.sadmin.ca/www/how-to_use_sms_alert.php), ['Slack'](https://www.sadmin.ca/img/slack_warning.png) or by [email](https://www.sadmin.ca/img/mail_notification.png)  when a script failed or succeed.
  * Use our [Shell](https://www.sadmin.ca/doc/man/man_sadm_template_sh.php) and/or [Python](https://www.sadmin.ca/doc/man/man_sadm_template_py.php) templates to create new scripts and benefit of SADMIN tools.
  * Use [SADMIN wrapper](https://www.sadmin.ca/doc/man/man_sadm_wrapper.php) and run your existing scripts using the SADMIN tools
    * $SADMIN/bin/sadm_wrapper.sh $SADMIN/usr/bin/yourscript.sh
  * Each script starting and ending time along with the ending status are recorded in a [history file](https://www.sadmin.ca/img/file_rch_format.png).
* **Create an inventory of your systems (Linux,Aix)**.
  * Add, [update](https://www.sadmin.ca/img/sadm_server_update.png) or delete system in your inventory.
  * It collect [system configuration](https://www.sadmin.ca/img/sadmin_web_interface.png)and [performance data](https://www.sadmin.ca/img/sadm_nmon_rrd_update_cpu_graph.png) of your systems.
  * Access all this information from a [Web interface](https://www.sadmin.ca/img/sadmin_main_screen.png) or from the command line.
  * View your servers farm [subnet utilization](https://www.sadmin.ca/img/sadm_view_subnet.png) and see what IP are free to use.
* **Help you keeping up to date with O/S update**.
  * Choose what system get updated automatically.
  * Choose [date and time to perform the update](https://www.sadmin.ca/img/sadm_osupdate_screen.png).
  * Choose to reboot or not your system after the update.
  * Choose to be [notify by 'Slack'](https://www.sadmin.ca/img/slack_warning.png) or by [email](https://www.sadmin.ca/img/mail_notification.png), if something goes wrong.
* **Backup your important directories and files to a NFS server**.
  * Create a daily, weekly, monthly and yearly backup.
  * Choose how many backups you wish to keep for each type.
  * [Decide at what time you wish to perform the backup](https://www.sadmin.ca/img/sadm_server_backup.png).
  * Backup are kept based upon the retention period you choose.
* **Easy installation**
  * Untar the download file into the directory of your choice (We recommend /opt/sadmin).
  * Run the [setup.sh](https://www.sadmin.ca/www/install_guide.php#installation) script, answer a few questions and that's it.
    * Once the installation is finish, just type 'http://sadmin' in your web browser.
    * Server installation install/configure the Apache Web server and MariaDB server.
    * See the SADMIN requirements on this [page](https://www.sadmin.ca/www/requirements.php).
    * Cron jobs (/etc/cron.d) will take care of keeping SADMIN healthy.

SADMIN surely can help you, improve and standardize the administration of your server farm.  
For more information visit the SADMIN web site at <https://www.sadmin.ca>.  
[See our latest release changelog](https://www.sadmin.ca/www/changelog.php).  
Impatient user may want to read the [Quick start guide](https://www.sadmin.ca/www/quickstart.php) first.

[Back To The Top](#brief-description)

---

## Run on most popular Linux distributions

* The **SADMIN client** have been tested to work on Redhat, Fedora, CentOS, Debian, Ubuntu, Raspbian and Aix.
  * It should work on most Linux distribution.
* The **SADMIN server**  is only supported Redhat, CentOS, Debian, Ubuntu and Raspbian. 
* Install time is about 15 minutes.
* We have been working for more than two years on these tools and it's near version 1.0. 
* We will continue to add and enhance the SADMIN tools over the years to come.  

[Back To The Top](#brief-description)

---

## Download

* Download the latest version of the SADMIN Project from our [Download page](https://www.sadmin.ca/www/download.php).
* Have a look at our [changelog](https://www.sadmin.ca/www/changelog.php) and see the latest features.
* You can also clone the project from [GitHub](https://github.com/jadupl2/sadmin)
    * `git clone https://github.com/jadupl2/sadmin.git`  

[Back To The Top](#brief-description)

---

## Before you install

* [SADMIN tools reside in one directory](https://www.sadmin.ca/doc/pdf/sadmin_directory_structure.pdf) (recommend '/opt/sadmin'), but you can install it in the directory of your choice.
* For **the server installation we recommended at least 2Gb** of free space and **1Gb for the client**.
* The 'SADMIN' environment variable is critical for the SADMIN tools and contain the installation directory name.
* The setup script will make sure that this environment variable is defined and persistent after a reboot.
  * It create a script ([/etc/profile.d/sadmin.sh](https://www.sadmin.ca/img/sadmin_sh.png)) that's executed every time you login.
    * To ease the use of the SADMIN tools, directories '$SADMIN/bin' & $SADMIN/usr/bin are added to the PATH.
  * It also modify the '[/etc/environment](http://wsadmin.maison.ca/img/etc_environment.png)' so it contain SADMIN install directory.
* The installation process MUST be executed by the 'root' user.
* **IMPORTANT : You need to have an internet access on the system you are installing.**  
  * The setup script, may need to download and install some [packages needed by SADMIN](https://www.sadmin.ca/www/requirements.php).
    * On Redhat and CentOS the "EPEL repository" is activated only for the installation time.
    * On other distributions the packages needed are available in the distribution repository.
* Instructions below assume you have chosen to install SADMIN tools in '/opt/sadmin' directory..

[Back To The Top](#brief-description)

---

## Installing SADMIN Tools


### Method 1 : Cloning our git repository (Recommended)

```bash
    Change directory to /opt
    # cd /opt

    Clone the SADMIN repository from GitHub
    # git clone https://github.com/jadupl2/sadmin.git  

    Run the setup program
    # /opt/sadmin/setup/setup.sh
```

[Back To The Top](#brief-description)


### Method 2 : Using the downloaded 'tgz' file

```bash
    Change directory to /opt
    # cd /opt

    Create a filesystem or directory where you want SADMIN to be install
    # mkdir /opt/sadmin

    Copy the latest version of SADMIN file you have downloaded in '/opt' directory.
    # cp sadmin_xx.xx.xx.tgz /opt

    Change directory to '/opt/sadmin' directory
    # cd /opt/sadmin

    Untar the file
    # tar -xvzf ../sadmin_xx.xx.xx.tgz

    Run the setup program
    # /opt/sadmin/setup/setup.sh
```
[Back To The Top](#brief-description)

### Running the setup script
* Setup ask several questions regarding your environment and store answers in the SADMIN configuration file ($SADMIN/cfg/sadmin.cfg).  
* Here's the [output running the setup script](https://www.sadmin.ca/doc/pdf/sadm_client_install_centos7.pdf) to install a SADMIN client on a CentOS 7 system.
* This file is used by the web interface, the SADMIN scripts, libraries and the new scripts you will create.  
* This configuration can be modified when ever you need to.  
* The setup script can be run more than once, so don't worry if you made a mistake, just run it again.
* If there are missing packages, the setup program will download and install them for you.
* You will be asked what type of installation you want, a 'SADM server' or a 'SADMIN client'.
* If you are installing a 'SADMIN server', the 'Mariadb' (Database) and the Apache Web Server will be installed and configure for you.  
* When installation is finished you will have a working Web SADMIN environment at 'http://sadmin'.

After the installation is terminated, you need to log out and log back in before using SADMIN Tools or type the command below.  
This will make sure "SADMIN" environment variable is define (The dot and the space are important).  
    `sudo . /etc/profile.d/sadmin.sh` 

[Back To The Top](#brief-description)

---

## SADMIN Support
Should you ran into problem while installing or running the SADMIN tools, please run the 'sadm_support_request.sh', attach the resulting file to an email with a description of your
problem or question and sent it to <support@sadmin.ca>.
We will get back to you as soon as possible.

[Back To The Top](#brief-description)

---

## Authors
[Jacques Duplessis](mailto:support@sadmin.ca) - *Initial work*.

[Back To The Top](#brief-description)

---

## Copyright and license
The SADMIN is a collection of free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. 

The SADMIN Tools is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  

See the [LICENSE](LICENSE) file for details.

[Back To The Top](#brief-description)

---

[1]: https://www.sadmin.ca/img/sadmin_small_logo.png
