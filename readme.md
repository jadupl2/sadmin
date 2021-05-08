![sadm_text](https://sadmin.ca/assets/img/logo/sadmin_logo_88x88.png "SADMIN Logo")
![sadm_logo](https://sadmin.ca/assets/img/logo/sadmin_text_343x93.png "SADMIN Text Logo")

# Tools for SysAdmin

If you're a Unix system administrator who is taking care of multiple servers, you probably 
created some scripts to help you keeping your environment stable and under control. SADMIN can 
help you by centralizing your scripts logs in one place, by viewing their results in one place and
you can even can be notified if something goes wrong. With SADMIN you can be notified, when a 
script fail or just to let you know that your script ran with success. You can received 
notification via email, SMS or the Slack application. 
SADMIN can surely help you improve and standardize the administration of your server farm.
 

![monitor](https://sadmin.ca/assets/img/index_monitor.png "SADMIN monitor page")

---

## Monitor your scripts from just one place
* View the [status of all your scripts](https://sadmin.ca/assets/img/webui/scripts_status.png) that run in your server farm.
* View your script log directly from the [web interface](https://sadmin.ca/assets/img/webui/view_logs.png) or from the [command line](https://sadmin.ca/assets/img/cmdline/cat_log.png).
* When a script fail or succeed, can receive a notification by ['SMS/Texto'](https://sadmin.ca/assets/img/sms/textbelt_step10_sms_receive.png), ['Slack'](https://sadmin.ca/assets/img/slack/slack_warning.png) or by [email](https://sadmin.ca/assets/img/mail/sysmon_mail_notification.png).

[Back To The Top](#Tools-for-SysAdmin)

---


## Using our templates 
* Use our [Shell](https://sadmin.ca/templates/sadm-template-sh) and [Python](https://sadmin.ca/templates/sadm-template-py) 
templates to create new scripts and benefit of SADMIN tools.  
* Use [SADMIN wrapper](https://sadmin.ca/utilities/sadm-wrapper) and *run your existing scripts using the SADMIN tools*.  
  `sadm_wrapper.sh $SADMIN/usr/bin/yourscript.sh`  
* Starting and ending time of each script along with the exit status is recorded in a 
[history file](https://sadmin.ca/assets/img/files/rch_file_format.png). 

[Back To The Top](#Tools-for-SysAdmin)

---

## Inventory of your systems
* Add, [update](https://sadmin.ca/assets/img/webui/server_static_info.png) or delete system in your inventory.
* It collect [system configuration](https://sadmin.ca/assets/img/webui/server_information.png) and [performance data](https://sadmin.ca/assets/img/perfo/rrd_update_cpu_graph.png) of your systems.
* Access all this information from a [web interface](https://sadmin.ca/assets/img/webui/main_screen.png) or from the command line.
* View your systems farm [subnet utilization](https://sadmin.ca/assets/img/webui/view_subnet.png) and see what IP are free to use.  

![SubnetInfo](https://sadmin.ca/assets/img/webui/view_subnet.png "SADMIN Subnet Information")

[Back To The Top](#Tools-for-SysAdmin)

---

## Web Interface to administrate your systems
* Use it to add, update and delete server in your server farm.
* View [performance graph of your servers up to two years in the past](https://sadmin.ca/assets/img/perfo/sadm_perf_adhoc.png).
* Have your systems configuration on hand, useful in case of a Disaster Recovery.
* View all your scripts logs and history files from the web interface.

[Back To The Top](#Tools-for-SysAdmin)

---

## Automate your system update
* Choose when and what system are updated.
* Choose [date and time to perform the update](https://sadmin.ca/assets/img/webui/osupdate_screen.png).
* Choose to reboot or not your system after the update.
* Choose to be notify by ['SMS/Texto'](https://sadmin.ca/assets/img/sms/textbelt_step10_sms_receive.png), 
['Slack'](https://sadmin.ca/assets/img/slack/slack_warning.png) or by 
[email](https://sadmin.ca/assets/img/mail/sysmon_mail_notification.png) if something goes wrong.

[Back To The Top](#Tools-for-SysAdmin)

---

## Backup to a NFS server
Choose what to backup, what to exclude and [how many copies to keep](https://sadmin.ca/assets/img/backup/backup_options.png).
Backup directory structure automatically [daily, weekly, monthly and yearly](https://sadmin.ca/assets/img/backup/backup_tree.png) created.
Decide when is [the right time to perform the daily backup](https://sadmin.ca/assets/img/backup/backup_screen.png).
   
[Back To The Top](#Tools-for-SysAdmin)

---

## Run on popular Linux distributions

The **SADMIN client** have been tested to work on Redhat, Fedora, CentOS, Debian, Ubuntu, Raspbian
and Aix, but it should work on most Linux distribution. The **SADMIN server**  is supported 
Redhat, CentOS, Debian, Ubuntu and Raspbian. The installation can normally done within 10 minutes.
We have been working for more than four years on these tools and it's getting pretty stable. We 
will continue to add and enhance the SADMIN tools over the years to come.  
 
[Back To The Top](#Tools-for-SysAdmin)

---

## Downloading SADMIN Tools
We recommend cloning the SADMIN repository and then run the setup script.  
    * `cd /opt/`    
    * `git clone https://github.com/jadupl2/sadmin.git`    
    * `sudo sadmin/setup/setup.sh`  
Another way is to download the latest version from our [download page](https://sadmin.ca/_pages/download) and have 
a look at our [changelog](https://github.com/jadupl2/sadmin/releases/) and see the latest features. For more information 
about the installation process, view our [install guide](https://sadmin.ca/_pages/install/)
 

[Back To The Top](#Tools-for-SysAdmin)

---

## SADMIN Support
Should you ran into problem while installing or running the SADMIN tools, please run the 
'sadm_support_request.sh', attach the resulting file to an email with a description of your 
problem or question and sent it to <sadmlinux@gmail.com>.
We will get back to you as soon as possible.
 
[Back To The Top](#Tools-for-SysAdmin)

---

## Copyright and license
The SADMIN is a collection of free software: you can redistribute it and/or modify it under the 
terms of the GNU General Public License as published by the Free Software Foundation, either 
version 3 of the License, or (at your option) any later version. 
The SADMIN Tools is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; 
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  
See the [LICENSE](https://sadmin.ca/_pages/license) file for details.  
 
[Back To The Top](#Tools-for-SysAdmin)

---

[1]: https://www.sadmin.ca/img/logo/sadmin_small_logo.png
