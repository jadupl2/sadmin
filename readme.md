![SADMIN Tools][1] 
**SADMIN Tools v1.3.1**


<a name="top_of_page"></a> 
![monitor](https://sadmin.ca/assets/img/index_monitor.png "SADMIN monitor page")

If you're a Unix system administrator who is taking care of multiple servers, you probably 
created some scripts to help you keeping your environment stable. 
With SADMIN you can be alerted when something goes wrong, when a script fail or just to let you 
know that your script ran with success. You can received these alerts via email, SMS or with the
Slack application. 
SADMIN can surely help you improve and standardize the administration of your server farm.

For more information visit the SADMIN web site at <https://www.sadmin.ca>.  
Impatient user may want to read the [Quick start guide](https://sadmin.ca/quickstart) first.

[Back To The Top](#top_of_page)

<br>

---

## Some of the features
<br>

**Monitoring your scripts is all done from one place**   

* View the [status of all your scripts](https://sadmin.ca/assets/img/webui/scripts_status.png) that run in your server farm.
* View your script log directly from the [web interface](https://sadmin.ca/assets/img/webui/view_logs.png) or from the [command line](https://sadmin.ca/assets/img/cmdline/cat_log.png).
* Your scripts can send alert by ['SMS/Texto'](https://sadmin.ca/assets/img/sms/textbelt_step10_sms_receive.png), ['Slack'](https://sadmin.ca/assets/img/slack/slack_warning.png) or by [email](https://sadmin.ca/assets/img/mail/sysmon_mail_notification.png)  when a script failed or succeed.

<br>

**Create/Modify your scripts using our templates**
* Use our [Shell](https://sadmin.ca/_pages/man/sadm-template-sh) and [Python](https://sadmin.ca/_pages/man/sadm-template-py) 
templates to create new scripts and benefit of SADMIN tools.  
* Use [SADMIN wrapper](https://sadmin.ca/_pages/man/sadm-wrapper) and run your existing scripts using the SADMIN tools.  
  `$SADMIN/bin/sadm_wrapper.sh $SADMIN/usr/bin/yourscript.sh`  
* Starting and ending time of each script along with the exit status is recorded in a 
[history file](https://sadmin.ca/assets/img/files/rch_file_format.png). 

<br>

**Create an inventory of your systems (Linux,Aix,MacOS)**.
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
  * [Decide at what time you wish to perform the backup](https://sadmin.ca/img/sadm_server_backup.png).
  * Backup are kept based upon the retention period you choose.
* **Easy installation**
  * Untar the download file into the directory of your choice (We recommend /opt/sadmin).
  * Run the [setup.sh](https://sadmin.ca/_pages/man/install_guide) script, answer a few questions and that's it.
    * Once the installation is finish, just type 'http://sadmin' in your web browser.
    * Server installation install/configure the Apache Web server and MariaDB server.
    * See the SADMIN requirements on this [page](https://sadmin.ca/_pages/requirements).
    * Cron jobs (/etc/cron.d) will take care of keeping SADMIN healthy.




<br>

---

## Run on most popular Linux distributions

* The **SADMIN client** have been tested to work on Redhat, Fedora, CentOS, Debian, Ubuntu, Raspbian and Aix.
  * It should work on most Linux distribution.
* The **SADMIN server**  is only supported Redhat, CentOS, Debian, Ubuntu and Raspbian. 
* Install time is about 15 minutes.
* We have been working for more than two years on these tools and it's near version 1.0. 
* We will continue to add and enhance the SADMIN tools over the years to come.  

[Back To The Top](#top_of_page)

<br>

---

## Download

* Download the latest version of the SADMIN Project from our [Download page](https://sadmin.ca/_pages/download/).
* Have a look at our [changelog](https://sadmin.ca/_pages/changelog/) and see the latest features.
* You can also clone the project from [GitHub](https://github.com/jadupl2/sadmin)
    * `git clone https://github.com/jadupl2/sadmin.git`  

[Back To The Top](#top_of_page)

<br>

---

## Before you install

* [SADMIN tools reside in one directory](https://sadmin.ca/assets/pdf/sadmin_directory_structure.pdf) (recommend '/opt/sadmin'), but you can install it in the directory of your choice.
* We recommend 5Gb of free space for the SADMIN server and 400Mb for each client.
* The 'SADMIN' environment variable is critical for the SADMIN tools and contain the installation directory name.
* The setup script will make sure that this environment variable is defined and persistent after a reboot.
  * It create a script "[/etc/profile.d/sadmin.sh](https://sadmin.ca/assets/img/files/etc_profile_d_sadmin_sh.png)" that's executed every time you login.
    * To ease the use of the SADMIN tools, directories '$SADMIN/bin' & $SADMIN/usr/bin are added to the PATH.
  * It also modify the "[/etc/environment](https://sadmin.ca/assets/img/files/etc_environment.png)" so it contain SADMIN install directory.
* The installation process MUST be executed by the 'root' user.
* **IMPORTANT : You need to have an internet access on the system you are installing.**  
  * The setup script, may need to download and install some [packages needed by SADMIN](https://sadmin.ca/_pages/requirements).
    * On Redhat and CentOS the "EPEL repository" is activated only for the installation time.
    * On other distributions the packages needed are available in the distribution repository.
* Instructions below assume you have chosen to install SADMIN tools in '/opt/sadmin' directory..

[Back To The Top](#top_of_page)


<br>

---

## Installing SADMIN Tools

<br>

### Method 1 : Cloning our git repository (Recommended)

```bash
    Change directory to /opt
    # cd /opt

    Clone the SADMIN repository from GitHub
    # git clone https://github.com/jadupl2/sadmin.git  

    Run the setup program
    # /opt/sadmin/setup/setup.sh
```

<br>

### Method 2 : Using the downloaded 'tgz' file

```bash
    Change directory to /opt
    # cd /opt

    Create a filesystem or directory where you want SADMIN to be install
    # mkdir /opt/sadmin

    Copy latest version of SADMIN file you have downloaded in '/opt'  
    # cp sadmin_xx.xx.xx.tgz /opt  

    Change directory to '/opt/sadmin' directory  
    # cd /opt/sadmin  

    Untar the file
    # tar -xvzf ../sadmin_xx.xx.xx.tgz

    Run the setup program
    # /opt/sadmin/setup/setup.sh
```

[Back To The Top](#top_of_page)   

<br>

---

### Running the setup script
* Setup ask several questions regarding your environment and store answers in the SADMIN configuration file ($SADMIN/cfg/sadmin.cfg).  
* Here's the [output running the setup script](https://sadmin.ca/assets//pdf/setup_centos7.pdf) to install a SADMIN client on a CentOS 7 system.
* This file is used by the web interface, the SADMIN scripts, libraries and the new scripts you will create.  
* This configuration can be modified when ever you need to.  
* The setup script can be run more than once, so don't worry if you made a mistake, just run it again.
* If there are missing packages, the setup program will download and install them for you.
* You will be asked what type of installation you want, a 'SADM server' or a 'SADMIN client'.
* If you are installing a 'SADMIN server', the 'Mariadb' (Database) and the Apache Web Server will be installed and configure for you.  
* When installation is finished you will have a working Web SADMIN environment at 'http://sadmin'.

After running the setup script, you need to log out and log back in before using SADMIN Tools or type the command below.  

    `sudo . /etc/profile.d/sadmin.sh`   
This will make sure "SADMIN" environment variable is define (The dot and the space are important).  

[Back To The Top](#top_of_page)

<br>

---

## SADMIN Support
Should you ran into problem while installing or running the SADMIN tools, please run the 'sadm_support_request.sh', attach the resulting file to an email with a description of your
problem or question and sent it to <sadmlinux@gmail.com>.
We will get back to you as soon as possible.

[Back To The Top](#top_of_page)

<br>

---

## Authors
[Jacques Duplessis](mailto:sadmlinux@gmail.com) 

[Back To The Top](#top_of_page)

<br>

---

## Copyright and license
The SADMIN is a collection of free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. 

The SADMIN Tools is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  

See the [LICENSE](LICENSE) file for details.

[Back To The Top](#top_of_page)

---

[1]: https://sadmin.ca/assets/img/logo/sadmin_small_logo.png
