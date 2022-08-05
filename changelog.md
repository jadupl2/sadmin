# SADMIN Tools Changelog
 
## Release [1.3.6](https://github.com/jadupl2/sadmin/releases) (2021-09-07)

### Configuration files
  - [.sadmin.cfg](https://sadmin.ca/sadmin-cfg) (v2.6 2021/08/16) - Monitor page refresh rate can now be set via 'SADM_MONITOR_UPDATE_INTERVAL'

### Libraries, Scripts Templates, Demo
  - [sadmlib_std.sh](https://sadmin.ca/sadmlib-std-sh) (v3.73 2021/08/13) - New func. see Doc sadm_lock_system sadm_unlock_system sadm_check_system_lock
  - [sadmlib_std.sh](https://sadmin.ca/sadmlib-std-sh) (v3.74 2021/08/17) - Performance improvement.

### Operating System Update
  - [sadm_osupdate.sh](https://sadmin.ca/sadm-osupdate) (v3.27 2021/08/19) - Fix prompting issue on '.deb' distributions.

### SADMIN Server related
  - [sadm_fetch_clients.sh](https://sadmin.ca/sadm-fetch-clients) (v3.30 2021/08/17) - Performance improvement et code restructure
  - [sadm_fetch_clients.sh](https://sadmin.ca/sadm-fetch-clients) (v3.31 2021/08/27) - Increase ssh connection Timeout "-o ConnectTimeout=3".
  - [sadm_server_housekeeping.sh](https://sadmin.ca/sadm-server-housekeeping) (v2.9 2021/07/30) - Solve intermittent error on monitor page.

### Web interface
  - Result Code History viewer, show effective alert group instead of 'default.'
  - Result Code History viewer, show member(s) of alert group as tooltip.
  - Status of all Scripts - Add link to Script documentation.
  - Status of all Scripts - Show effective alert group name & members as tooltip
  - Status of all Scripts - Fix link to log & History file (*.rch).
  - Status of all Scripts - Show effective alert group name instead of 'default'.
  - Status of all Scripts - Show member(s) of alert group as tooltip.
  - System Monitor page - Each alert now show effective group name (not 'default').
  - System Monitor page - Alert type now show description and tooltip.
  - System Monitor page - Warning, Error, Info now have separate section.
  - System Monitor page - Use the refresh interval from SADMIN configuration file.
  - System Monitor page - Section heading are spread on two lines.
  - System Monitor page - Show alert group member(s) as tooltip.
   
   
  
  
## Release [1.3.4a](https://github.com/jadupl2/sadmin/releases) (2021-07-22)


### SADMIN Client related
  - sadm_cfg2html.sh (v3.8 2021/07/21) - Fix problem with cfg2html on Fedora 34.

### Configuration files
  - .alert_group.cfg (v2.5 2021/07/20) - Default alert group now assigned to 'mail_sysadmin' group.

### Install, Uninstall & Update project
  - sadm_setup.py (v3.57 2021/07/20) - Fix sadmin.service configuration problem.
  - sadm_setup.py (v3.58 2021/07/20) - Bug fix when installing SADMIN server 'mysql' packages.
  - sadm_setup.py (v3.59 2021/07/20) - Update alert group file, default now assigned to 'mail_sysadmin' group.
  - sadm_setup.py (v3.60 2021/07/20) - Client package to install changed from 'util-linux-ng' to 'util-linux'.
  - sadm_setup.py (v3.61 2021/07/21) - Fix server install problem on rpm system with package 'php-mysqlnd'.
  - sadm_setup.py (v3.62 2021/07/21) - Fix 'srv_rear_ver' field didn't have a default value in Database.



## Release [1.3.4](https://github.com/jadupl2/sadmin/releases) (2021-07-19)
   

### Backup related
  - sadm_backupdb.sh (v2.3 2021/05/26) - Added command line option option [-b backup_dir] [-n dbname].
  - sadm_backup.sh (v3.30 2021/05/24) - Optimize code & update command line options [-v] & [-h].
  - sadm_backup.sh (v3.31 2021/06/04) - Fix sporadic problem with exclude list.
  - sadm_backup.sh (v3.32 2021/06/05) - Include backup & system information in each backup log.
  - sadm_rear_backup.sh (v2.26 2021/05/11) - Fix 'rear' command missing false error message
  - sadm_rear_backup.sh (v2.27 2021/05/12) - Write more information about ReaR sadmin.cfg in the log.
  - sadm_rear_backup.sh (v2.28 2021/06/02) - Added more information in the script log.

### SADMIN Client related
  - sadm_client_housekeeping.sh (v1.48 2021/05/23) - Remove conversion of old history file format (not needed anymore).
  - sadm_client_housekeeping.sh (v2.00 2021/06/06) - Make sure that sadm_client crontab run 'sadm_nmon_watcher.sh' regularly.
  - sadm_client_housekeeping.sh (v2.02 2021/06/06) - Fix problem related to system monitor file update.
  - sadm_client_housekeeping.sh (v2.03 2021/06/10) - Fix problem removing 'nmon' watcher from monitor file.
  - sadm_create_sysinfo.sh (v3.24 2021/06/03) - Include script version in sysinfo text file generated

### Command line tools
  - sadm_service_ctrl.sh (v2.11 2021/06/13) - When using an invalid command line option, PID file wasn't removed.

### Libraries, Scripts Templates, Demo
  - sadmlib_screen.sh (v2.3 2021/05/10) - Version no. in 'sadm_display_heading' now align with first line.
  - sadmlib_std.sh (v3.71 2021/06/30) - To be more succinct global variables were removed from log footer.

### System Monitor
  - sadm_client_housekeeping.sh (v2.01 2021/06/06) - Remove script that run 'swatch_nmon.sh' from system monitor config file.
  - sadm_sysmon.pl (v2.43 2021/06/12) - Add Date & Time of last boot on last line of hostname.smon file.
  - sadm_sysmon.pl (v2.44 2021/07/03) - Fix problem when trying to run custom script.
  - sadm_sysmon.pl (v2.45 2021/07/05) - Added support to monitor 'http' and 'https' web site responsiveness.
  - sadm_sysmon.pl (v2.46 2021/07/06) - Change error messages syntax to be more descriptive.

### SADMIN Server related
  - sadm_daily_report.sh (v1.27 2021/06/10) - Show system backup in bold instead of having a yellow background.
  - sadm_fetch_clients.sh (v3.27 2021/06/06) - Change generation of /etc/cron.d/sadm_osupdate to use $SADMIN variable.
  - sadm_fetch_clients.sh (v3.28 2021/06/11) - Collect system uptime and store it in DB and update SADMIN section
  - sadm_fetch_clients.sh (v3.29 2021/07/19) - Sleep 5 seconds between rsync retries, if first failed.
  - sadm_push_sadmin.sh (v2.30 2021/05/22) - Remove sync depreciated $SADMIN/usr/mon/swatch_nmon* script and files.
  - sadm_server_housekeeping.sh (v2.8 2021/05/29) - Code optimization, update SADMIN section and Help screen.

### Web interface
  - sadmlib_graph.php (v1.1 2021/06/08) - Fix intermittent unlink error when showing all systems graph.
  - sadm_server_backup.php (v2.1 2021/05/25) - Replace php depreciated function 'eregi_replace' warning message.
  - sadm_server_delete_action.php (v1.3 2021/06/07) - Remove faulty error message when a client was delete just after creating it.
   




## Release v[1.3.2](https://github.com/jadupl2/sadmin/releases) (2021-04-30)

### Enhancements
- 2021_03_05 sadm_osupdate_starter.sh (v4.3) - Added sleep time after update to allow system to  become available.
- 2021_03_24 sadmlib_std.sh (v3.67) - Non root user MUST be part of 'sadmin' group to use SADMIN library.
- 2021_03_29 sadm_backup.sh (v3.28) - Exclude list is shown before each backup (tar) begin.
- 2021_03_29 sadm_backup.sh (v3.29) - Log of each backup (tar) recorded and place in backup directory.
- 2021_04_19 sadm_server_rear_backup.php (v1.4) - Change "Exclude" to "Include/Exclude" Label on file config
- 2021_04_19 sadm_setup.py (v3.54) - Fix Path to sadm_service_ctrl.sh

### Fixes
- 2021_04_01 sadm_daily_report.sh (v1.23) - Fix problem when the last line of *.rch was a blank line.
- 2021_04_02 sadmlib_std.sh (v3.68) - Replace test using '-v' with '! -z' on variable.
- 2021_04_09 sadmlib_std.sh (v3.69) - Fix problem with disabling log header, log footer and rch file.
- 2021_04_28 sadm_daily_report.sh (v1.24) - Fix problem with the report servers exclude list.


---
<br>

## Release v[1.3.1](https://github.com/jadupl2/sadmin/releases) (2021-02-06)

- Fixes
	- 2020_10_26 sadm_backup.sh (v3.26) - Suppress 'chmod' error message on backup directory.
	- 2020_10_29 sadm_daily_farm_fetch.sh (v4.3) - If comma was used in server description, it cause delimiter problem.
	- 2020_10_29 sadm_osupdate_farm.sh (v3.16) - If comma was used in server description, it cause delimiter problem.
	- 2020_10_29 sadm_osupdate_starter.sh (v3.16) - If comma was used in server description, it cause delimiter problem.
	- 2020_10_29 sadm_push_sadmin.sh (v2.24) - If comma was used in server description, it cause delimiter problem.
	- 2020_10_29 sadm_rear_initiator.sh (v1.10) - If comma was used in server description, it cause delimiter problem.
	- 2020_11_04 sadm_push_sadmin.sh (v2.25) - Change , to 
	- 2020_11_10 sadm_daily_report.sh (v1.10) - Minor bug fixes.
	- 2020_12_12 sadm_osupdate_farm.sh (v3.18) - LOCK_FILE bug fix.
	- 2020_12_19 sadm_fetch_clients.sh (v3.23) - Don't copy alert group and slack configuration files, when on SADMIN Server.
	- 2020_12_23 sadmlib_std.sh (v3.61) - Log Header (SADM_LOG_HEADER) & Footer (SADM_LOG_FOOTER) were always produce.
	- 2020_12_23 sadm_setup.py (v3.49) - Fix typo error.
	- 2020_12_24 sadmlib_std.sh (v3.62) - Fix problem with capitalize function.
	- 2020_12_26 sadm_client_housekeeping.sh (v1.47) - Doesn't delete Database Password File, cause problem during server setup.
	- 2020_12_27 sadm_setup.py (v3.51) - Fix problem with 'rear' & 'syslinux' when installing SADMIN server.
	- 2021_01_11 sadm_rear_backup.sh (v2.25) - NFS drive was not unmounted when the backup failed.
- Minor
	- 2020_11_04 sadm_osupdate_farm.sh (v3.17) - Minor code modification.
	- 2020_11_04 sadm_osupdate_starter.sh (v3.17) - Minor code modification.
- New
	- 2020_11_07 sadm_daily_report.sh (v1.8) - Exclude file can be use to exclude scripts or servers from daily report.
	- 2020_11_09 sadm_setup.py (v3.45) - Add Daily Email Report to crontab of sadm_server.
	- 2020_11_13 sadm_daily_report.sh (v1.11) - Email of each report now include a pdf of the report(if wkhtmltopdf install)
- Update
	- 2020_10_22 sadm_fs_incr.sh (v2.2) - Line Feed added in Email when filesystem is increase
	- 2020_11_04 sadm_daily_report.sh (v1.7) - Added 1st draft of scripts html report.
	- 2020_11_04 sadm_fetch_clients.sh (v3.18) - Reduce time allowed for O/S update to 1800sec. (30Min) & keep longer log.
	- 2020_11_05 sadm_daily_farm_fetch.sh (v4.4) - Change msg written to log & no alert while o/s update is running.
	- 2020_11_05 sadm_fetch_clients.sh (v3.19) - Change msg written to log & no alert while o/s update is running.
	- 2020_11_05 sadm_push_sadmin.sh (v2.26) - Change msg written to log & no alert while o/s update is running.
	- 2020_11_07 sadm_client_housekeeping.sh (v1.45) - Remove old rch conversion code execution.
	- 2020_11_08 sadm_daily_report.sh (v1.9) - Show Alert Group Name on Script Report
	- 2020_11_12 sadm_daily_report.sh (v1.12) - Warning in Yellow when backup outdated, bug fixes.
	- 2020_11_15 sadm_setup.py (v3.46) - 'wkhtmltopdf' package was added to server installation.
	- 2020_11_18 sadm_sysmon.pl (v2.41) - Fix: Fix problem with iostat on MacOS.
	- 2020_11_20 sadm_check_requirements.sh (v1.9) - Added package 'wkhtmltopdf' installation to server requirement.
	- 2020_11_20 sadm_osupdate_starter.sh (v4.0) - Restructure & rename from sadm_osupdate_farm to sadm_osupdate_starter.
	- 2020_11_21 sadm_daily_report.sh (v1.13) - Insert Script execution Title.
	- 2020_11_24 sadm_fetch_clients.sh (v3.20) - Optimize code & Now calling new 'sadm_osupdate_starter' for o/s update.
	- 2020_11_24 sadmlib_std_demo.sh (v3.19) - Don't show DB password file on client
	- 2020_11_24 sadmlib_std.sh (v3.57) - Revisit and Optimize 'send_alert' function.
	- 2020_11_27 sadm_push_sadmin.sh (v2.27) - For command line uniformity , option '-c' changed to '-n'
	- 2020_11_30 sadm_sysmon.pl (v2.42) - Fix: Fix problem reading SADMIN variable in /etc/environment.
	- 2020_12_02 sadm_fetch_clients.sh (v3.21) - New summary added to the log and Misc. fix.
	- 2020_12_02 sadmlib_std.sh (v3.58) - Optimize and fix some problem with Slack ans SMS alerting function.
	- 2020_12_02 sadm_osupdate_starter.sh (v4.1) - Log is now in appending mode and can grow up to 5000 lines.
	- 2020_12_12 sadm_create_sysinfo.sh (v3.21) - Add SADM_PID_TIMEOUT and SADM_LOCK_TIMEOUT Variables.
	- 2020_12_12 sadm_daily_farm_fetch.sh (v4.5) - Add and use SADM_PID_TIMEOUT and SADM_LOCK_TIMEOUT Variables.
	- 2020_12_12 sadm_daily_report.sh (v1.14) - Major revamp of HTML and PDF Report that are send via email to sysadmin.
	- 2020_12_12 sadm_fetch_clients.sh (v3.22) - Copy Site Common alert group and slack configuration files to client
	- 2020_12_12 sadmlib_std.sh (v3.59) - Add 'sadm_capitalize"function, add PID TimeOut, enhance script footer.
	- 2020_12_12 sadm_osupdate.sh (v3.25) - Minor adjustments.
	- 2020_12_12 sadm_osupdate_starter.sh (v4.2) - Use new LOCK_FILE & Add and use SADM_PID_TIMEOUT & SADM_LOCK_TIMEOUT Var.
	- 2020_12_12 sadm_push_sadmin.sh (v2.28) - Add pushing of alert_group.cfg alert_slack.cfg to client
	- 2020_12_13 sadm_view_backup.php (v1.5) - Added link in Heading to view the Daily Backup Report, if HTML file exist.
	- 2020_12_13 sadm_view_rch_summary.php (v2.6) - Add link in the heading to view the Daily Scripts Report, if HTML exist.
	- 2020_12_15 sadm_daily_report.sh (v1.15) - Cosmetic changes to Daily Report.
	- 2020_12_15 sadmPageWrapper.php (v1.5) - Add Storix Report Link in Header, only if Storix html file exist.
	- 2020_12_16 sadm_client_housekeeping.sh (v1.46) - Minor code change (Isolate the check for sadmin user and group)
	- 2020_12_16 sadm_server_housekeeping.sh (v2.7) - Include code to include in SADMIN server crontab the daily report email.
	- 2020_12_17 sadmlib_std.sh (v3.60) - sadm_get_osname() on 'CentOSStream' now return 'CENTOS'.
	- 2020_12_21 sadm_setup.py (v3.47) - Bypass installation of 'ReaR' on Arm platform (Not available).
	- 2020_12_21 sadm_setup.py (v3.48) - Bypass installation of 'syslinux' on Arm platform (Not available).
	- 2020_12_24 sadmlib_std_demo.sh (v3.20) - Include output of capitalize function.
	- 2020_12_24 sadmlib_std.py (v3.14) - CentOSStream is CENTOS
	- 2020_12_24 sadm_setup.py (v3.50) - CentOSStream return CENTOS.
	- 2020_12_26 sadm_daily_report.sh (v1.16) - Include link to web page in email.
	- 2020_12_26 sadm_daily_report.sh (v1.17) - Insert Header when reporting script error(s).
	- 2020_12_26 sadmInit.php (v3.7) - Added Global Var. SADM_WWW_ARC_DIR for Server archive when deleted.
	- 2020_12_26 sadmlib_std.sh (v3.63) - Add Global Variable SADM_WWW_ARC_DIR for Server Archive when deleted
	- 2020_12_27 sadm_daily_report.sh (v1.18) - Insert Header when reporting script running.
	- 2020_12_29 sadm_view_server_info.php (v2.15) - Date for starting & ending maintenance mode was not show properly.
	- 2020_12_29 sadm_view_servers.php (v2.10) - Show Architecture un-capitalize.
	- 2020_13_13 sadm_view_rear.php (v1.8) - Add link in heading to view ReaR Daily Report.
	- 2021_01_05 sadm_backup.sh (v3.27) - List backup directory content at the end of backup.
	- 2021_01_06 sadm_setup.py (v3.52) - Ensure that package util-linux is installed on client & server.
	- 2021_01_13 sadm_daily_report.sh (v1.19) - Change reports heading color and font style.
	- 2021_01_13 sadmlib_std.sh (v3.64) - Code Optimization (in Progress)
	- 2021_01_17 sadm_daily_report.sh (v1.20) - Center Heading of scripts report.
	- 2021_01_23 sadm_daily_report.sh (v1.21) - SCRIPTS & SERVERS variables no longer in "sadm_daily_report_exclude.sh"
	- 2021_01_27 sadmlib_std.sh (v3.65) - By default Temp files declaration done in caller
	- 2021_01_27 sadm_setup.py (v3.53) - Activate Startup and Shutdown Script (SADMIN Service)


---
<br>


## Release v[1.2.9](https://github.com/jadupl2/sadmin/releases) (2020-10-20)
- Fixes
	- 2020_07_29 sadmlib_std.sh (v3.46) - Fix date not showing in the log under some condition.
	- 2020_08_10 sadmlib_std.sh (v3.48) - Remove improper '::' characters to was inserted im messages.
	- 2020_08_19 sadmlib_std.sh (v3.51) - Remove some ctrl character from the log (sadm_write()).
	- 2020_08_20 sadmlib_std.sh (v3.52) - Adjust sadm_write method
	- 2020_09_05 sadmlib_std.sh (v3.53) - Added Start/End/Elapse Time to Script Alert Message.
	- 2020_09_05 sadm_rear_backup.sh (v2.24) - Minor Changes.
	- 2020_10_06 sadm_daily_report.sh (v1.4) - Bug that get Current backup size in yellow, when shouldn't.
- New
	- 2020_08_10 sadmlib_std.sh (v3.47) - Add module "sadm_sleep", sleep for X seconds with progressing info.
	- 2020_08_12 sadmlib_std.sh (v3.49) - Global Var. $SADM_UCFG_DIR was added to refer $SADMIN/usr/cfg directory.
	- 2020_08_18 sadmlib_std.sh (v3.50) - Change Screen Attribute Variable (Remove 'SADM_', $SADM_RED is NOW $RED).
- Update
	- 2020_07_29 sadm_fetch_clients.sh (v3.14) - Move location of o/s update is running indicator file to $SADMIN/tmp.
	- 2020_07_29 sadm_osupdate.sh (v3.24) - Minor adjustments to screen and log presentation.
	- 2020_07_29 sadmPageSideBar.php (v2.13) - Show server attribute counter even if it's zero.
	- 2020_07_29 sadm_view_rear.php (v1.7) - Remove system description to allow more space on each line.
	- 2020_09_05 sadm_fetch_clients.sh (v3.15) - Minor Bug fix, Alert Msg now include Start/End?Elapse Script time
	- 2020_09_05 sadm_osupdate.sh (v3.25) - Minor adjustments.
	- 2020_09_05 sadm_setup.py (v3.44) - Minor change to sadm_client crontab file.
	- 2020_09_09 sadm_fetch_clients.sh (v3.16) - Modify Alert message when client is down.
	- 2020_09_09 sadmlib_std.sh (v3.54) - Remove server name from Alert message (already in subject)
	- 2020_09_10 sadm_client_housekeeping.sh (v1.42) - Make sure permission are ok in user library directory ($SADMIN/usr/lib).
	- 2020_09_10 sadmlib_std.py (v3.13) - Minor update to date/time module.
	- 2020_09_10 sadm_push_sadmin.sh (v2.21) - Create local processing server data server directory (if don't exist)
	- 2020_09_10 sadm_service_ctrl.sh (v2.9) - Minor code improvement.
	- 2020_09_12 sadm_client_housekeeping.sh (v1.43) - Make sure that "${SADM_UCFG_DIR}/.gitkeep" exist to be part of git clone.
	- 2020_09_12 sadm_push_sadmin.sh (v2.22) - When -u is used, the usr/cfg directory is now also push to client.
	- 2020_09_20 sadm_client_housekeeping.sh (v1.44) - Minor adjustments to log entries.
	- 2020_09_22 sadmLib.php (v2.17) - Facilitate going back to previous & Home page by adding button in header.
	- 2020_09_23 sadm_backup.sh (v3.25) - Modification to log recording.
	- 2020_09_23 sadmPageWrapper.php (v1.4) - Add Tooltips to Shortcut in the page header.
	- 2020_09_23 sadm_view_sysmon.php (v2.17) - Add Home button in the page heading.
	- 2020_10_01 sadm_daily_report.sh (v1.2) - First Release
	- 2020_10_01 sadmlib_std.sh (v3.55) - Add Host name in email, when alert come from sysmon.
	- 2020_10_01 sadm_sysmon.pl (v2.40) - Write more elaborated email to user when restarting a service.
	- 2020_10_05 sadm_daily_report.sh (v1.3) - Daily Backup Report & ReaR Backup Report now available.
	- 2020_10_05 sadmlib_std.sh (v3.56) - Remove export for screen attribute variables.
	- 2020_10_06 sadm_daily_report.sh (v1.5) - Minor Typo Corrections
	- 2020_10_18 sadm_push_sadmin.sh (v2.23) - Correct error message when no system are active.


---
<br>

## Release v[1.2.8](https://github.com/jadupl2/sadmin/releases) (2020-07-29)
- Fixes
        - 2020_06_30 sadm_rear_backup.sh (v2.23) - Fix chmod 664 for files in server backup directory
        - 2020_07_11 sadmlib_std.sh (v3.42) - Date and time was not include in script log.
        - 2020_07_13 sadm_backup.sh (v3.24) - New System Main Backup Directory was not created with right permission.
        - 2020_07_29 sadmlib_std.sh (v3.46) - Fix date not showing in the log under some condition.
- New
        - 2020_07_23 sadmlib_std.sh (v3.45) - New function 'sadm_ask', show received msg & wait for y/Y (return 1) or n/N (return 0)
- Update
        - 2020_06_09 sadm_create_sysinfo.sh (v3.20) - New log at each execution & log not trimmed anymore ($SADM_MAX_LOGLINE=0)
        - 2020_07_10 sadm_client_housekeeping.sh (v1.40) - If no password have been assigned to 'sadmin' a temporary one is assigned.
        - 2020_07_10 sadm_setup.py (v3.41) - Assign temporary passwd to sadmin user.
        - 2020_07_11 sadm_setup.py (v3.42) - Minor script changes.
        - 2020_07_11 sadm_setup.py (v3.43) - Added rsync package to client installation.
        - 2020_07_12 sadmlib_std.sh (v3.43) - When virtual system 'sadm_server_model' return (VMWARE,VIRTUALBOX,VM)
        - 2020_07_12 sadm_server_menu.php (v1.6) - Add 'Delete System' as a menu item and change item labelling.
        - 2020_07_12 sadm_view_server_info.php (v2.14) - Replace 'CRUD' button with 'Modify' that direct you to CRUD server menu.
        - 2020_07_20 sadm_client_housekeeping.sh (v1.41) - Change permission of log and rch to allow normal user to run script.
        - 2020_07_20 sadm_fetch_clients.sh (v3.13) - Change email to have success or failure at beginning of subject.
        - 2020_07_20 sadmlib_std.sh (v3.44) - Change permission for log and rch to allow normal user to run script.
        - 2020_07_26 sadm_push_sadmin.sh (v2.20) - Add usr/lib to sync process when -u option is used.
        - 2020_07_27 sadm_sysmon.pl (v2.39) - Used space of CIFS Mounted filesystem are no longer monitored.
        - 2020_07_28 sadm_osupdate_farm.sh (v3.15) - Move location of o/s update is running indicator file to $SADMIN/tmp.
        - 2020_07_29 sadm_fetch_clients.sh (v3.14) - Move location of o/s update is running indicator file to $SADMIN/tmp.
        - 2020_07_29 sadm_osupdate.sh (v3.24) - Minor adjustments to screen and log presentation.
        - 2020_07_29 sadmPageSideBar.php (v2.13) - Show server attribute counter even if it's zero.
        - 2020_07_29 sadm_view_rear.php (v1.7) - Remove system description to allow more space on each line.


---
<br>

  

## Release v[1.2.7](https://github.com/jadupl2/sadmin/releases) (2020-06-03)
- Fixes
	- 2020_05_18 sadm_rear_backup.sh (v2.22) - Fix /etc/rear/site.conf auto update problem, prior to starting backup.
	- 2020_05_23 sadmlib_std.sh (v3.38) - Fix intermittent problem with 'sadm_write' & alert sent multiples times.
	- 2020_05_27 sadm_df.sh (v2.4) - fix problem when dealing with TB filesystem.
- Update
	- 2020_05_17 .sadmin.cfg (v2.4) - Update Rear Backup and backup default Location,
	- 2020_05_18 sadm_backup.sh (v3.22) - Backup Dir. Structure changed, now group by System instead of backup type
	- 2020_05_22 sadm_fetch_clients.sh (v3.12) - No longer report an error, if a system is rebooting because of O/S update.
	- 2020_05_23 sadm_daily_farm_fetch.sh (v4.2) - No longer report an error, if a system is rebooting because of O/S update.
	- 2020_05_23 sadm_fs_incr.sh (v2.1) - Changing the way to get SADMIN variable in /etc/environment
	- 2020_05_23 sadm_osupdate_farm.sh (v3.14) - Create 'LOCK_FILE' file before launching O/S update on remote.
	- 2020_05_23 sadm_osupdate.sh (v3.23) - Replace 'reboot' instruction with 'shutdown -r' (Problem on some OS).
	- 2020_05_23 sadm_push_sadmin.sh (v2.19) - Changing the way to get SADMIN variable in /etc/environment
	- 2020_05_23 sadm_rch_scr_summary.sh (v1.18) - Changing the way to get SADMIN variable in /etc/environment
	- 2020_05_23 sadm_server_housekeeping.sh (v2.6) - Minor change about reading /etc/environment and change logging messages.
	- 2020_05_24 sadm_backup.sh (v3.23) - Automatically move backup from old dir. structure to the new.
  
<br>

------


## Release v[1.2.6](https://github.com/jadupl2/sadmin/releases) (2020-05-14) 
- Fixes
	- 2020_05_01 man_sadm_dr_savefs.php (v1.1) - Correct link to IBM mksysb page.
	- 2020_05_12 sadmlib_std.sh - Fix problem sending attachment file when sending alert by email.
	- 2020_05_05 setup.sh (v3.10) - Fix problem with installation on Ubuntu 20.04.
- Update
	- 2020_05_13 sadm_rear_backup.sh (v2.21) - Remove mount directory before exiting script.
	- 2020_05_13 sadm_view_sysmon.php (v2.15) - Customize message when nothing to report.

<br>

------

## Release v[1.2.5](https://github.com/jadupl2/sadmin/releases) (2020-05-01)

### Web User Interface
* The main header look appearance was enhance.
* Part of page header, we now have a menu bar for faster and easier access.
* We fix link problem to show the script log, on the [R]esult [C]ode [H]istory file viewer page.
* Lot of functional change & enhancements. 

<br>

------

### Installation Setup
* Change made for RHEL/CentOS 8
    * Installation (if needed) of package 'hwinfo' is done using EPEL repository (Not in base repo. anymore).
    * Installation (if needed) of package 'dnf-utils' is now replace by 'yum-utils'.
    * Installation a SADMIN server, now include installation of Python3 'getmac' module (For subnet network scanning).
    * Package 'arp-scan' removed from server installation, using python3 'getmac' module instead.
    * Some bug fixes and minor adjustment were done for RHEL/CentOS 8.
* Setup now set the default alert group to 'email' and to sysadmin email address in .alert_group.cfg.
* Setup now install 'syslinux', 'genisomage' and 'rear' packages (Require to make a ReaR image Backup)
* Fix Apache config renaming error.


<br>

------

### Rear Backup
* Leave latest ReaR Backup to default name to ease the restore.
* Remove NFS mount point in /mnt after the backup.
* "BACKUP_URL" line (in site.conf) is align with sadmin.cfg before each backup.
* Create /etc/rear/site.conf if it doesn't exist, bug fixes and enhancements.
* Structure enhancement made to log.
* sadm_rear_backup.sh Documentation updated.
* Small CSS adjustments made to ReaR Backup Schedule.
* Mouse over system name on ReaR Backup Schedule status web page, show O/S name & version & IP.


<br>

------

### Server Scripts
* sadm_daily_farm_fetch.sh
  * Show Error Total only at the end of each system processed.
  * Replace function sadm_writelog() with NL incl. by sadm_write() No NL Incl.
  * Show rsync status & solve problem if duplicate entry in /etc/environment.
  * Minor error message alignment.
* sadm_fetch_clients.sh - SSH error to client were not reported in System Monitor.
* sadm_subnet_lookup.py - Major update, more portable, Faster and no longer use arp-scan.
* sadm_push_sadmin.sh - Script was rename from sadm_rsync_sadmin.sh to sadm_push_sadmin.sh
* sadm_rch_scr_summary.sh - Allow simultaneous execution of this script.


<br>

------

### Clients Scripts
* System Monitor
  * Fix problem getting 'SADMIN' variable content from /etc/environment (if export used).
  * Fix problem when 'dmidecode' is not available on system.
* sadm_backup.sh
  * If backup_list.txt include a '$' at beginning of a line, the environment variable is resolved.
  * Log output adjustment & enhancement changes.
  * Fix 'chown' error.
  * Don't show anymore directories that are skip because they don't exist.
* sadm_osupdate.sh
  * Use 'apt-get dist-upgrade' instead of 'apt-get -y upgrade' on deb system.
  * Restructure some code and change help message.
* sadm_client_housekeeping.sh
  * Code rewrite for better performance and maintenance.
  * Fix minor bugs & Restructure log presentation
  * Update readme file permission from 0644 to 0664
* sadm_create_sysinfo.sh
  * Collect more information about Disks, Partitions, Network and fix lsblk.
  * Replace function sadm_writelog() with NL incl. by sadm_write() No NL Incl


<br>

------

### Common Scripts
* Template Shell Script
  * Command line option code is now in a function.
  * Fix problem with server name resolving test.
  * Include some new Screen attribute in code ($BOLD,$YELLOW,...)
* sadm_df.sh
  * Fix problem under RHEL/CentOS older version (4,5,6).
  * To increase portability, Column total are now calculated by script.
  * Add -t to exclude tmpfs, -n nfs filesystem from the output and total line.
  * Modified to work on MacOS
  * Add hostname and date in heading line.
  * Updated documentation.


<br>

------

### SADMIN Library
* SADMIN Shell Library (sadmlib_std.sh)
  * Change the way script info (-v) is shown.
  * If not present, create Alert Group file (alert_group.cfg) from template.
  * Function sadm_writelog() with N/L depreciated, remplace by sadm_write().
  * Function sadm_writelog() replaced by sadm_write in Library.
  * New Variable SADM_OK, SADM_WARNING, SADM_ERROR to Show Status in Color.
  * New Variable SADM_SUCCESS, SADM_FAILED to Show Status in Color.
  * Add @@LNT (Log No Time) var. to prevent sadm_write to put Date/Time in Log


<br>

<br>

------

## Release v[1.2.4](https://github.com/jadupl2/sadmin/releases) (2020-02-27)
- Fixes
	- 2020_02_01 sadmlib_std.sh (v3.26) - If on SADM Server & script don't use 'rch', gave error trying to copy 'rch'.
	- 2020_02_23 setup.sh (v3.3) - Fix some problem installing lsb_release and typo with 'dnf' command..
- Update
	- 2020_01_26 sadm_rsync_sadmin.sh (v2.16) - Add Option -c [hostname] to sync of SADMIN server version to one client.
	- 2020_02_17 sadm_osupdate.sh (v3.19) - Add error message when problem getting the list of package to update.
	- 2020_02_18 sadm_rear_backup.sh (v2.13) - Correct typo error introduce in v2.12
	- 2020_02_19 sadm_fetch_clients.sh (v3.8) - Restructure & Create an Alert when can't SSH to client.
	- 2020_02_19 sadmlib_std.sh (v3.27) - Added History Archive File Definition
	- 2020_02_19 sadm_server_housekeeping.sh (v2.5) - Restructure & added archiving of old alert history to history archive.
	- 2020_02_23 sadm_client_sunset.sh (v2.6) - Produce an alert only if one of the executed scripts isn't executable.
	- 2020_02_23 sadm_server_sunrise.sh (v2.7) - Produce an alert only if one of the executed scripts isn't executable.
	- 2020_02_25 sadm_daily_farm_fetch.sh (v3.6) - Fix intermittent problem getting SADMIN value from /etc/environment.
	- 2020_02_25 sadmlib_std.py (v3.12) - Add 'export SADMIN=$INSTALLDIR' to /etc/environment, if not there.
	- 2020_02_25 sadmlib_std.sh (v3.28) - Add 'export SADMIN=$INSTALLDIR' to /etc/environment, if not there.
	- 2020_02_25 sadm_template.sh (v2.5) - Reduce SADMIN Section needed at beginning of script.
	- 2020_02_26 sadm_template.sh (v2.6) - Change code to show debug level at the beginning of script.




## Release v[1.2.3](https://github.com/jadupl2/sadmin/releases) (2020-01-23)
- Fixes
	- 2019_12_22 sadm_osupdate_farm.sh (v3.13) - Fix problem when using debug (-d) option without specifying level of debug.
	- 2020_01_13 sadm_view_sysmon.php (v2.13) - Bug fix, displaying empty error line.
	- 2020_01_18 setup.sh (v3.2) - Fix problem installing pip3, when running setup.sh script.
	- 2020_01_20 sadmlib_std.py (v3.11) - Fix 'get_osminorversion' function. Crash (raspbian) when no os minor version
- Update
	- 2019_12_18 sadm_setup.py (v3.32) - Fix problem when inserting server into database on Ubuntu/Raspbian.
	- 2019_12_20 sadm_setup.py (v3.33) - Remove installation of ruby (was used for facter) & of pymysql (Done)
	- 2019_12_20 setup.sh (v2.9) - Better verification and installation of python3 (If needed)
	- 2019_12_27 sadm_service_ctrl.sh (v2.8) - Was exiting with error when using options '-h' or '-v'.
	- 2019_12_27 setup.sh (v3.0) - Add recommended EPEL Repos on CentOS/RHEL 8.
	- 2019_12_27 setup.sh (v3.1) - On RHEL/CentOS 6/7, revert to Python 3.4 (3.6 Incomplete on EPEL)
	- 2020_01_03 sadm_server_backup.php (v1.8) - Web Page disposition and input was changed.
	- 2020_01_04 sadm_server_menu.php (v1.5) - Change Server C.R.U.D. Menu
	- 2020_01_07 sadm_group_common.php (v2.2) - Change web page for a lighter look.
	- 2020_01_08 sadm_rear_backup.sh (v2.12) - Minor logging changes.
	- 2020_01_09 sadm_category_common.php (v2.2) - Web page have now a new lighter look.
	- 2020_01_11 sadm_view_sysmon.php (v2.12) - Remove Arch,Category and OS Version to make space on Line.
	- 2020_01_12 sadm_fetch_clients.sh (v3.6) - Compact log produced by the script.
	- 2020_01_12 sadmlib_std.sh (v3.22) - When script run on SADMIN server, copy 'rch' & 'log' in Web Interface Dir.
	- 2020_01_12 sadm_server_osupdate.php (v2.9) - Enhance appearance and color of form.
	- 2020_01_13 sadm_create_sysinfo.sh (v3.17) - Collect 'rear' version to show on rear schedule web page.
	- 2020_01_13 sadmLib.php (v2.15) - Reduce Day of the week name returned by SCHEDULE_TO_TEXT to 3 Char.
	- 2020_01_13 sadm_server_backup.php (v1.9) - Enhance Web Appearance and color.
	- 2020_01_13 sadm_server_rear_backup.php (v1.2) - Enhance Web Page Appearance and color.
	- 2020_01_13 sadm_view_file.php (v1.5) - Enhance Web Page Appearance and color.
	- 2020_01_13 sadm_view_rear.php (v1.4) - Change column disposition and show ReaR version no. of systems.
	- 2020_01_13 sadm_view_servers.php (v2.9) - Minor Appearance page change (Nb.Cpu and page width).
	- 2020_01_14 sadm_fetch_clients.sh (v3.7) - Don't use SSH when running daily backup and ReaR Backup for SADMIN server.
	- 2020_01_14 sadm_view_rchfile.php (v2.5) - Add link to allow to view script log on the page.
	- 2020_01_14 sadm_view_rear.php (v1.5) - Don't show MacOS System on page (Not supported by ReaR).
	- 2020_01_18 sadm_osupdate.sh (v3.17) - Include evrything in script log while running 'apt-get upgrade'.
	- 2020_01_18 sadm_server_backup.php (v2.0) - Reduce width of text-area for include,exclude list to fit on Ipad.
	- 2020_01_19 sadm_rsync_sadmin.sh (v2.14) - Option -u to sync the $SADMIN/usr/bin of SADMIN server to all clients.
	- 2020_01_19 sadm_view_rchfile.php (v2.6) - Remove line counter and some other cosmetics changes.
	- 2020_01_20 sadmlib_std.py (v3.10) - Better handling & Error message when can't connect to database.
	- 2020_01_20 sadmlib_std.sh (v3.23) - Place Alert Message on top of Alert Message (SMS,SLACK,EMAIL)
	- 2020_01_20 sadm_rsync_sadmin.sh (v2.15) - Option -s to sync the $SADMIN/sys of SADMIN server to all clients.
	- 2020_01_21 sadm_client_housekeeping.sh (v1.35) - Remove alert_group.cfg and alert_slack.cfg, if present in $SADMIN/cfg
	- 2020_01_21 sadmlib_std.sh (v3.24) - For Texto alert put alet message on top of texto and don't show if 1 of 1
	- 2020_01_21 sadmlib_std.sh (v3.25) - Show the script starting date in the header.
	- 2020_01_21 sadm_osupdate.sh (v3.18) - Enhance the update checking process.
	- 2020_01_21 sadm_view_rchfile.php (v2.7) - Display rch date in date reverse order (Recent at the top)


## Release v[1.2.2](https://github.com/jadupl2/sadmin/releases) (2019-12-14)
- Fixes
	- Fix format problem (tgz) with previous version (1.2.1) (problem with sadm_updater.sh).
	- You should use 1.2.2 instead of 1.2.1,


## Release v[1.2.1](https://github.com/jadupl2/sadmin/releases) (2019-12-13)
- Fixes
	- 2019_11_25 sadm_client_housekeeping.sh (v1.34) - Remove deletion of $SADMIN/www on SADMIN client.
	- 2019_11_26 sadm_view_sysmon.php (v2.10) - Fix problem with temp files (Change from $SADMIN/tmp to $SADMIN/www/tmp)
	- 2019_11_27 sadm_view_sysmon.php (v2.11) - Fix 'open append failed', when no *.rpt exist or are all empty.
	- 2019_12_02 sadm_check_requirements.sh (v1.6) - Fix Mac OS crash.
- Update
	- 2019_11_25 sadmlib_std_demo.sh (v3.17) - Change printing format of Database table at the end of execution.
	- 2019_11_28 sadm_support_request.sh (V2.1) - When run on SADM server, will include crontab (osupdate,backup,rear).
	- 2019_12_01 sadm_fetch_clients.sh (v3.5) - Backup crontab will backup daily not to miss weekly,monthly and yearly.
	- 2019_12_01 sadmPageSideBar.php (v2.12) - Shorten label name of sidebar.
	- 2019_12_01 sadm_server_backup.php (v1.7) - Backup will run daily (Remove entry fields for specify day of backup)
	- 2019_12_01 sadm_view_backup.php (v1.4) - Change Layout to align with daily backup schedule.
	- 2019_12_02 sadmlib_std.sh (v3.21) - Add Server name in susbject of Email Alert,
	- 2019_12_02 sadm_support_request.sh (V2.2) - Add execution of sadm_check_requirenent.



## Release v[1.2.0](https://github.com/jadupl2/sadmin/releases) (2019-11-25)
- Fixes
	- 2019_11_06 sadm_subnet_lookup.py (v2.4) - Ping response was not recorded properly
	- 2019_11_22 sadm_create_sysinfo.sh (v3.16) - Problem with 'nmcli -t' on Ubuntu,Debian corrected.
- New
	- 2019_11_06 sadm_ui_rpm.sh (v1.0) - Initial version
	- 2019_11_12 sadm_ui_deb.sh (v1.0) - Initial version
	- 2019_11_14 sadm_ui_deb.sh (v1.1) - Test Phase
	- 2019_11_18 sadm_ui_deb.sh (v1.2) - First functional release
	- 2019_11_21 sadm_ui_deb.sh (v1.3) - Change Deb search method, now using 'apt-cache search'.
- Update
	- 2019_10_13 sadm_create_sysinfo.sh (v3.14) - Collect Server Architecture to be store later on in Database.
	- 2019_10_13 sadm_database_update.py (v3.6) - Take Architecture in Sysinfo.txt and store it in server database table.
	- 2019_10_13 sadmlib_std.sh (v3.17) - Added function 'sadm_server_arch' - Return system arch. (x86_64,armv7l,.)
	- 2019_10_13 sadm_view_servers.php (v2.8) - Add System Architecture to page.
	- 2019_10_14 sadm_database_update.py (v3.7) - Check if Architecture column is present in server Table, if not add it.
	- 2019_10_14 sadmlib_std_demo.py (v3.8) - Add demo for calling sadm_server_arch function & show result.
	- 2019_10_14 sadmlib_std_demo.sh (v3.14) - Add demo for calling sadm_server_arch function & show result.
	- 2019_10_14 sadmlib_std.py (v3.08) - Added function 'get_arch' - Return system arch. (x86_64,armv7l,i686,...)
	- 2019_10_15 sadmLib.php (v2.13) - Reduce Logo size image from 32 to 24 square pixels
	- 2019_10_15 sadmLib.php (v2.14) - Reduce font size on 2nd line of heading in "display_lib_heading".
	- 2019_10_15 sadmlib_std.sh (v3.18) - Enhance method to get host domain name in function $(sadm_get_domainname)
	- 2019_10_15 sadm_view_rear.php (v1.3) - Add Architecture, O/S Name, O/S Version to page
	- 2019_10_15 sadm_view_server_info.php (v2.13) - Color change of input fields.
	- 2019_10_15 sadm_view_sysmon.php (v2.9) - Add Architecture, O/S Name, O/S Version to page
	- 2019_10_16 sadm_database_update.py (v3.8) - Don't update anymore the domain column in the Database (Change with CRUD)
	- 2019_10_17 sadmlib_std_demo.sh (v3.15) - Print Category and Group table content at the end of report.
	- 2019_10_18 sadmlib_std_demo.py (v3.9) - Print SADMIN Database Tables and columns at the end of report.
	- 2019_10_25 .template.smon (v2.8) - - Turn off (Comment line) ping test lines.
	- 2019_10_30 sadm_create_sysinfo.sh (v3.15) - Remove utilization on 'facter' for collecting info (Not always available)
	- 2019_10_30 sadmlib_std_demo.py (v3.10) - Remove Utilization of 'facter' (Depreciated).
	- 2019_10_30 sadmlib_std_demo.sh (v3.16) - Remove 'facter' utilization (depreciated).
	- 2019_10_30 sadmlib_std.py (v3.09) - Remove 'facter' utilization (Depreciated).
	- 2019_10_30 sadmlib_std.sh (v3.19) - Remove utilization of 'facter' (Depreciated)
	- 2019_11_05 sadm_subnet_lookup.py (v2.3) - Restructure code for performance.
	- 2019_11_11 sadm_ui_rpm.sh (v1.1) - Revamp the RPM question & display of results.
	- 2019_11_11 sadm_ui_rpm.sh (v1.2) - Fix problem with List of repositories.
	- 2019_11_11 sadm_ui.sh (v2.8) - Add RPM Tools option in menu.
	- 2019_11_12 sadm_ui_rpm.sh (v1.3) - Production version
	- 2019_11_18 sadm_template_menus.sh (v1.4) - Put 'root' and SADM_SERVER test in comment.
	- 2019_11_21 sadm_osupdate.sh (v3.15) - Add 'export DEBIAN_FRONTEND=noninteractive' prior to 'apt-get upgrade'.
	- 2019_11_21 sadm_osupdate.sh (v3.16) - Email sent to SysAdmin if some package are kept back from update.
	- 2019_11_21 sadm_ui.sh (v2.10) - Minor correction to RPM Tools Menu
	- 2019_11_22 man_sadmlib_std_demo_py.php (v1.2) - Add sample of calling get architecture function (st.get_arch()).
	- 2019_11_22 sadmlib_std.sh (v3.20) - Change the way domain name is obtain on MacOS $(sadm_get_domainname).
	- 2019_11_22 sadm_ui.sh (v2.11) - Restrict RPM & DEV Menu when available only.
	- 2019_11_25 sadm_client_housekeeping.sh (v1.34) - Remove deletion of what is contained in $SADMIN/www on SADMIN client.
	- 2019_11_25 sadmlib_std_demo.sh (v3.17) - Database table printer at the is in a prettier format (server only)




## Release v[1.1.0](https://github.com/jadupl2/sadmin/releases) (2019-10-10)
- Update
	- 2019_09_01 sadm_rear_backup.sh (v2.8) - Remove separate creation of ISO (Already part of backup)
	- 2019_09_02 sadm_rear_backup.sh (v2.9) - Change syntax of error messages.
	- 2019_09_03 sadm_template.py (v2.1) - Change default value for max line in rch (35) and log (500) file.
	- 2019_09_03 sadm_template.sh (v2.4) - Change default value for max line in rch (35) and log (500) file.
	- 2019_09_14 sadm_rear_backup.sh (v2.10) - Backup list before housekeeping was not showing.
	- 2019_09_18 sadm_rear_backup.sh (v2.11) - Show Backup size in human redeable form.
	- 2019_09_20 sadmlib_std.sh (v3.16) - Foreground color definition, typo corrections.
	- 2019_09_20 sadm_view_backup.php (v1.3) - Show History (RCH) content using same uniform way.
	- 2019_09_20 sadm_view_rch_summary.php (v2.5) - Show History (RCH) content using same uniform way.
	- 2019_09_20 sadm_view_rear.php (v1.2) - Show History (RCH) content using same uniform way.
	- 2019_09_20 sadm_view_schedule.php (v2.10) - Show History (RCH) content using same uniform way.
	- 2019_09_23 sadm_view_schedule.php (v2.11) - When initiating Schedule change from here, return to this page when done.
	- 2019_09_25 sadm_view_sysmon.php (v2.7) - Page has become starting page and change page Title.
	- 2019_10_01 sadm_view_sysmon.php (v2.8) - Page Added links to log, rch and script documentation.
	- 2019_10_08 .template.smon (-) - Turn off (Comment line) syslog service check.





## Release v[1.0.0](https://github.com/jadupl2/sadmin/releases) (2019-08-31)
- Fixes
	- 2019_07_07 sadm_create_sysinfo.sh (v3.13) - O/S Update was indicating 'Failed' when it should have been 'Success'.
	- 2019_08_17 sadm_server_main.php (v2.3) - Return to caller URL wasn't set properly.
	- 2019_08_29 sadm_fetch_clients.sh (v3.3) - Correct problem with CR in site.conf
	- 2019_08_29 sadm_rear_backup.sh (v2.6) - Code restructure and was not reporting error properly.
	- 2019_08_30 sadm_rear_backup.sh (v2.7) - Fix renaming backup problem at the end of the backup.
- Improvement
	- 2019_07_18 sadm_backup.sh (v3.15) - Modified to backup MacOS system onto a NFS drive.
- New
	- 2019_08_14 sadm_view_backup.php (v1.1) - Allow to return to this page when backup schedule is updated (Send BACKURL)
	- 2019_08_18 sadm_server_rear_backup.php (v1.0) - Initial Beta version - Allow to define ReaR Backup schedule.
	- 2019_08-26 sadmPageSideBar.php (v2.9) - Add 'Rear Backup Status Page'
	- 2019_08_26 sadm_view_rear.php (v1.0) - Initial version of ReaR backup Status Page
	- 2019_08_26 sadm_view_rear.php (v1.1) - First Release of Rear Backup Status Page.
	- 2019_08-30 sadmPageSideBar.php (v2.10) - Side Bar re-arrange order.
- Update
	- 2019_06_30 sadm_df.sh (v1.8) - Remove tmpfs from output on Linux (useless)
	- 2019_07_04 sadm_setup.py (v3.29) - Crontab client and Server definition revised for Aix and Linux.
	- 2019_07_07 sadm_sysmon.pl (v2.34) - Update Filesystem Increase Message & verification.
	- 2019_07_11 sadm_fs_incr.sh (v1.7) - Change Email Body when filesystem in increase
	- 2019_07_12 sadm_fetch_clients.sh (v3.00) - Fix script path for backup and o/s update in respective crontab file.
	- 2019_07_12 sadm_osupdate.sh (v3.13) - O/S update script now update the date and status in sysinfo.txt.
	- 2019_07_12 sadm_view_schedule.php (v2.9) - Don't show MacOS and Aix status (Not applicable).
	- 2019_07_14 sadm_client_housekeeping.sh (v1.31) - Add creation of Directory /preserve/mnt if it doesn't exist (Mac Only)
	- 2019_07_14 sadmlib_std.sh (v3.09) - Change History file format , correct some alert issues.
	- 2019_07_14 sadm_osupdate_farm.sh (v3.12) - Adjustment for Library Changes.
	- 2019_07-15 sadmPageSideBar.php (v2.8) - Add 'Backup Status Page' & Fix RCH files with only one line not reported.
	- 2019_07_15 sadm_template.sh (v2.2) - If no SADMIN env. var. then use /etc/environment to get SADMIN location.
	- 2019_07_16 sadmInit.php (Remove) - repeating error message when not connecting to Database.
	- 2019_07_17 sadm_osupdate.sh (v3.14) - O/S update script now perform apt-get clean before update start on *.deb
	- 2019_07_18 sadmlib_std.sh (v3.10) - Repeat SysMon (not Script) Alert once a day if not solve the next day.
	- 2019_07_23 sadm_client_housekeeping.sh (v1.32) - Remove utilization of history sequence number file.
	- 2019_07_23 sadmlib_std.py (v3.05) - Remove utilization of history sequence number file.
	- 2019_07_24 sadm_fetch_clients.sh (v3.1) - Major revamp of code.
	- 2019_07_25 sadm_server_menu.php (v1.3) - Minor modification to page layout.
	- 2019_07_25 sadm_sysmon.pl (v2.35) - Now using a tmp rpt file and real rpt is replace at the end of execution.
	- 2019_07_25 sadm_template.sh (v2.3) - New variables available (SADM_OS_NAME, SADM_OS_VERSION, SADM_OS_MAJORVER).
	- 2019_07_25 sadm_view_file.php (v1.4) - File is displayed using monospace character.
	- 2019_07_25 sadm_view_server_info.php (v2.12) - Minor code changes
	- 2019_08_04 sadmLib.php (v2.10) - Added function 'sadm_show_logo' to show distribution logo in a table cell.
	- 2019_08_04 sadmlib_std.sh (v3.11) - Minor change to alert message format
	- 2019_08_04 sadm_view_sysmon.php (v2.6) - Add Distribution Logo and modify status icons.
	- 2019_08_13 sadmLib.php (v2.11) - Fix bug - When creating one line schedule summary
	- 2019_08_13 sadm_rch_scr_summary.sh (v1.15) - Fix bug when using -m option (Email report), Error not on top of report.
	- 2019_08_14 sadmLib.php (v2.12) - Add function for new page header look (display_lib_heading).
	- 2019_08_14 sadm_server_backup.php (v1.5) - Redesign page,show one line schedule,show backup policies, fit Ipad screen.
	- 2019_08_16 sadmInit.php (v3.5) - Correct Typo for number of rear backup to keep
	- 2019_08_17 sadm_category_update.php (v2.2) - Use new heading function, return to caller screen when exiting.
	- 2019_08_17 sadm_group_update.php (v2.2) - Use new heading function, return to caller screen when exiting.
	- 2019_08_17 sadm_server_delete_action.php (v1.1) - New Heading and return to Maintenance Server List
	- 2019_08_17 sadm_server_delete.php (v2.2) - New parameter, the URL where to go back after update.
	- 2019_08_17 sadm_server_main.php (v2.2) - New page heading and Logo of distribution inserted.
	- 2019_08_17 sadm_server_osupdate.php (v2.8) - Use new heading function, New parameter (URL) to get back to caller page.
	- 2019_08_17 sadm_server_update.php (v2.2) - Use new heading function, return to caller screen when exiting.
	- 2019_08_18 sadm_server_menu.php (v1.4) - Add ReaR Backup in menu.
	- 2019_08_19 sadm_client_housekeeping.sh (v1.33) - Check /etc/cron.d/sadm_rear_backup permission & remove /etc/cron.d/rear
	- 2019_08_19 sadmInit.php (v3.6) - Added Global Var. SADM_REAR_EXCLUDE_INIT for Rear Initial Options file.
	- 2019_08_19 sadmlib_std_demo.py (v3.7) - Remove printing of st.alert_seq (not used anymore)
	- 2019_08_19 sadmlib_std.py (v3.06) - Added rear_exclude_init Global Var. as default Rear Exclude List
	- 2019_08_19 sadmlib_std.py (v3.07) - Added Global Var. rear_newcron and rear_crontab file location
	- 2019_08_19 sadmlib_std.sh (v3.12) - Added SADM_REAR_EXCLUDE_INIT Global Var. as default Rear Exclude List
	- 2019_08_19 sadmlib_std.sh (v3.13) - Added Global Var. SADM_REAR_NEWCRON and SADM_REAR_CRONTAB file location
	- 2019_08_19 sadm_rear_backup.sh (v2.5) - Updated to align with new SADMIN definition section.
	- 2019_08_19 sadm_server_backup.php (v1.6) - Some typo error and show 'Backup isn't activated' when no schedule define.
	- 2019_08_19 sadm_server_rear_backup.php (v1.1) - Initial working version.
	- 2019_08_23 sadm_fetch_clients.sh (v3.2) - Remove Crontab work file (Cleanup)
	- 2019_08_23 sadmlib_std.sh (v3.14) - Create all necessary dir. in ${SADMIN}/www for the git pull to work
	- 2019_08_25 sadm_rch_scr_summary.sh (v1.16) - Put running scripts and scripts with error on top of email report.
	- 2019_08_25 sadm_setup.py (v3.30) - On Client setup Web USer and Group in sadmin.cfg to sadmin user & group.
	- 2019_08_29 sadm_category_create.php (v2.1) - New page heading, using the library heading function.
	- 2019_08_29 sadm_category_main.php (v2.1) - Use new page heading function.
	- 2019_08_29 sadm_group_create.php (v2.1) - New page heading, using the library heading function.
	- 2019_08_29 sadm_group_main.php (v2.1) - Use new page heading function.
	- 2019_08_29 sadm_server_create.php (v2.2) - New page heading, using the library heading function.
	- 2019_08_31 sadm_fetch_clients.sh (v3.4) - More consice of alert email subject.
	- 2019_08_31 sadmlib_std.sh (v3.15) - Change owner of web directories differently if on client or server.



## Release v[0.99.0](https://github.com/jadupl2/sadmin/releases) (2019-06-29)
- Fixes
	- 2019_06_06 sadm_fetch_clients.sh (v2.37) - Fix problem sending alert when SADM_ALERT_TYPE was set 2 or 3.
	- 2019_06_19 sadmlib_std.sh (v3.05) - Fix problem with repeating alert.
- Improvement
	- 2019_06_23 sadmlib_std.sh (v3.06) - Code reviewed and library optimization (300 lines were removed).
- New
	- 2019_06_07 sadm_fetch_clients.sh (v2.38) - An alert status summary of all systems is displayed at the end.
- Update
	- 2019_06_03 sadm_client_housekeeping.sh (v1.30) - Include logic to convert RCH file format to the new one, if not done.
	- 2019_06_07 sadmlib_std.py (v3.03) - Create/Update the rch file using the new format (with alarm type).
	- 2019_06_07 sadmlib_std.sh (v3.03) - Create/Update the RCH file using the new format (with alarm type).
	- 2019_06_07 sadmPageSideBar.php (v2.7) - Updated to deal with the new format of the RCH file.
	- 2019_06_07 sadm_rch_scr_summary.sh (v1.13) - Updated to adapt to the new field (alarm type) in RCH file.
	- 2019_06_07 sadm_sysmon_cli.sh (v2.3) - Updated to adapt to the new format of the '.rch' file.
	- 2019_06_07 sadm_view_rchfile.php (v2.4) - Add Alarm type to page (Deal with new format).
	- 2019_06_07 sadm_view_rch_summary.php (v2.4) - Add Alarm type to page (Deal with new format).
	- 2019_06_07 sadm_view_sysmon.php (v2.5) - Add Alarm type to page (Deal with new format).
	- 2019_06_10 sadm_support_request.sh (v1.9) - Add /etc/postfix/main.cf to support request output.
	- 2019_06_11 sadm_fs_incr.sh (v1.6) - Alert message change when filesystem increase failed.
	- 2019_06_11 sadmlib_std.sh (v3.04) - Function send_alert change to add script name as a parameter.
	- 2019_06_11 sadm_rch_scr_summary.sh (v1.14) - Change screen & email message when an invalid '.rch' format is encountered.
	- 2019_06_11 sadm_support_request.sh (V2.0) - Code Revision and performance improvement.
	- 2019_06_19 sadm_fetch_clients.sh (v2.39) - Cosmetic change to alerts summary and alert subject.
	- 2019_06_19 sadmlib_std.py (v3.04) - Trap and show error when can't connect to Database, instead of crashing.
	- 2019_06_19 sadm_setup.py (v3.26) - Ask for sadmin Database password until it's valid.
	- 2019_06_19 setup.sh (v2.8) - Update procedure to install CentOS/RHEL repository for version 5,6,7,8
	- 2019_06_21 sadm_setup.py (v3.27) - Ask user 'sadmin' & 'squery' database password until it's valid.
	- 2019_06_25 sadmlib_std.sh (v3.07) - Optimize 'send_alert' function.
	- 2019_06_25 sadm_setup.py (v3.28) - Modification of the text displayed at the end of installation.
	- 2019_06_25 sadm_uninstall.sh (v1.9) - Minor code update (use SADM_DEBUG instead of DEBUG_LEVEL).



## Release v[0.98.0](https://github.com/jadupl2/sadmin/releases) (2019-05-30)

- Features
	- 2019_05_12 sadmlib_std.sh (v2.77) - Alerting System with Mail Slack and SMS now fully working.
- Fixes
	- 2019_05_08 sadmlib_std.sh (v2.73) - Bug fix - Eliminate sending duplicate alert.
	- 2019_05_20 sadmlib_std.py (v3.02) - Was not loading Storix mount point directory info.
- Refactoring
	- 2019_05_19 sadm_template.py (v2.0) - Major revamp
- Update
	- 2019_04_25 sadmlib_std_demo.py (v3.5) - Add Alert_Repeat
	- 2019_04_25 sadmlib_std_demo.sh (v3.12) - Add Alert_Repeat
	- 2019_04_25 sadmlib_std.py (v2.28) - Read and Load 3 news sadmin.cfg variable Alert_Repeat
	- 2019_04_25 sadmlib_std.sh (v2.70) - Read and Load 2 news sadmin.cfg variable Alert_Repeat
	- 2019_04_25 sadm_sysmon_tui.pl (v1.8) - Was showing 'Nothing to report' although there was info displayed.
	- 2019_05_01 sadmlib_std.sh (v2.71) - Correct problem while writing to alert history log.
	- 2019_05_01 sadm_server_sunrise.sh (v2.5) - Log name now showed to help user diagnostic problem when an error occurs.
	- 2019_05_02 sadmLib.php (v2.9) - Function sadm_fatal_error - Insert back page link before showing alert.
	- 2019_05_04 sadm_server_osupdate.php (v2.7) - When specific date(s) specified for update
	- 2019_05_07 sadm_daily_farm_fetch.sh (v3.5) - Add 'W 5' ping option
	- 2019_05_07 sadm_fetch_clients.sh (v2.35) - Change Send Alert parameters for Library
	- 2019_05_07 sadmlib_std.sh (v2.72) - Function 'sadm_alert_sadmin' is removed
	- 2019_05_07 sadm_rch_scr_summary.sh (v1.12) - Change send_alert calling parameters
	- 2019_05_09 sadmlib_std.sh (v2.74) - Change Alert History file layout to facilitate search for duplicate alert
	- 2019_05_10 sadmlib_std.sh (v2.75) - Change to duplicate alert management
	- 2019_05_11 sadmlib_std.sh (v2.76) - Alert History epoch time (1st field) is always epoch the alert is sent.
	- 2019_05_13 sadmlib_std.sh (v2.78) - Minor adjustment of message format for history file and log.
	- 2019_05_13 sadm_sysmon.pl (v2.33) - Don't abort if can't create sysmon.lock file
	- 2019_05_14 sadmlib_std.sh (v2.79) - Alert via mail while now have the script log attach to the email.
	- 2019_05_16 sadm_check_requirements.sh (v1.4) - Don't generate the RCH file & allow running multiple instance of script.
	- 2019_05_16 sadmlib_std.py (v3.00) - Only one summary line is now added to RCH file when scripts are executed.
	- 2019_05_16 sadmlib_std.py (v3.01) - New 'st.show_version()' function
	- 2019_05_16 sadmlib_std.sh (v3.00) - Only one summary line is now added to RCH file when scripts are executed.
	- 2019_05_17 sadmlib_std_demo.py (v3.6) - Add option -p(Show DB password)
	- 2019_05_17 sadmlib_std_demo.sh (v3.13) - Add option -p(Show DB password)
	- 2019_05_19 sadm_client_housekeeping.sh (v1.29) - Change for lowercase readme.md
	- 2019_05_19 sadmlib_std.sh (v3.01) - SADM_DEBUG_LEVEL change to SADM_DEBUG for consistency with Python Library
	- 2019_05_19 sadm_server_housekeeping.sh (v2.4) - Add server crontab file to housekeeping
	- 2019_05_19 sadm_template.sh (v2.0) - New debug variable
	- 2019_05_20 sadmlib_std.sh (v3.02) - Eliminate `tput` warning when TERM variable was set to 'dumb'.
	- 2019_05_22 man_sadmlib_std_demo_py.php (v1.1) - Update to include new command line options (-s
	- 2019_05_22 man_sadmlib_std_demo_sh.php (v1.1) - Update to include new command line options (-s
	- 2019_05_22 sadm_template_menus.sh (v1.2) - Comment code for documentation
	- 2019_05_23 sadm_fetch_clients.sh (v2.36) - Updated to use SADM_DEBUG instead of Local Variable DEBUG_LEVEL
	- 2019_05_23 sadm_osupdate.sh (v3.12) - Updated to use SADM_DEBUG instead of Local Variable DEBUG_LEVEL
	- 2019_05_23 sadm_server_sunrise.sh (v2.6) - Updated to use SADM_DEBUG instead of Local Variable DEBUG_LEVEL
	- 2019_05_23 sadm_template_menus.sh (v1.3) - Correct Typo Error
	- 2019_05_23 sadm_template.sh (v2.1) - Minor Comment Update



## Release v[0.97.0](https://github.com/jadupl2/sadmin/releases) (2019-04-23)
- Fixes
	- 2019_03_17 sadm_sysmon_tui.pl (v1.7) - Wasn't reporting error coming from result code history (rch) file.
	- 2019_03_18 sadm_cfg2html.sh (v3.5) - Fix problem that prevent running on Fedora.
	- 2019_03_27 .sadmin.rc (v2.3) - Bug fixes Under SysV system & Optimization.
	- 2019_03_27 sadm_service_ctrl.sh (v2.3) - Making sure InitV sadmin service script is executable.
	- 2019_03_28 sadm_service_ctrl.sh (v2.4) - Was not executing shutdown script under RHEL/CentOS 4
	- 2019_03_30 sadm_subnet_lookup.py (v2.2) - Fix problem reading the fping result
	- 2019_04_02 sadm_rch_scr_summary.sh (v1.11) - Doesn't report an error anymore when last line is blank.
	- 2019_04_04 sadm_setup.py (v3.19) - Fix 'sadmin' user home directory and default password creation on Debian.
	- 2019_04_12 sadm_fetch_clients.sh (v2.33) - Create Web rch directory
	- 2019_04_14 sadm_uninstall.sh (v1.6) - Don't show password when entering it
	- 2019_04_14 sadm_uninstall.sh (v1.7) - Remove user before dropping database
	- 2019_04_15 sadm_setup.py (v3.22) - File /etc/environment was not properly updated under certain condition.
	- 2019_04_15 sadm_setup.py (v3.23) - Fix 'squery' database user password typo error.
	- 2019_04_18 sadm_setup.py (v3.25) - Release 0.97 Re-tested with CentOS/RedHat version.
	- 2019_04_19 setup.sh (v2.6) - Solve problem with installing 'pymysql' module.
	- 2019_04_19 setup.sh (v2.7) - Solve problem with pip3 on Ubuntu.
- New
	- 2019_03_18 sadmlib_std_demo.py (v3.3) - Add demo call to function get_packagetype()
	- 2019_03_18 sadmlib_std_demo.sh (v3.9) - Add demo call to function 'sadm_get_packagetype'
	- 2019_03_18 sadmlib_std.py (v2.27) - Function 'get_packagetype()' that return package type (rpm
	- 2019_03_18 sadmlib_std.sh (v2.66) - Function 'sadm_get_packagetype' that return package type (rpm
	- 2019_03_20 sadm_check_requirements.sh (v1.1) - Verify if SADMIN requirement are met and -i to install missing requirement.
	- 2019_03_21 man_sadm_check_requirements.php (v1.0) - Initial documentation of sadm_check_requirements.sh
	- 2019_04_06 man_sadm_uninstall.php (v1.1) - Uninstall SADMIN client and server documentation.
	- 2019_04_07 sadm_uninstall.sh (v1.3) - Uninstall script production release.
- Update
	- 2019_03_17 sadm_create_sysinfo.sh (v3.12) - PCI hardware list moved to end of system report file.
	- 2019_03_17 sadm_df.sh (v1.7) - No background color change
	- 2019_03_17 sadmlib_screen.sh (v1.7) - Add time in menu heading.
	- 2019_03_17 sadm_setup.py (v3.16) - Perl DateTime module no longer a requirement.
	- 2019_03_17 sadm_setup.py (v3.17) - Default installation server group is 'Regular' instead of 'Service'.
	- 2019_03_17 sadm_setup.py (v3.18) - If not already install 'curl' package will be intall by setup.
	- 2019_03_17 sadm_view_server_info.php (v2.10) - Volume Group Used & Free Size now show with GB unit.
	- 2019_03_18 sadmlib_std.sh (v2.65) - Improve: Optimize code to reduce load time (125 lines removed).
	- 2019_03_23 documentation.php (v1.1) - Insert man page for sadm_check_requirements.sh
	- 2019_03_29 sadm_check_requirements.sh (v1.2) - Add 'chkconfig' command requirement if running system using SYSV Init.
	- 2019_03_29 sadm_service_ctrl.sh (v2.5) - Major Revamp - Re-Tested - SysV and SystemD
	- 2019_03_30 sadm_service_ctrl.sh (v2.6) - Added message when enabling/disabling sadmin service.
	- 2019_03_31 sadmlib_std.sh (v2.67) - Set log file owner ($SADM_USER) and permission (664) if executed by root.
	- 2019_04_04 sadmLib.php (v2.8) - Function SCHEDULE_TO_TEXT now return 2 values (Occurence & Date of update)
	- 2019_04_04 sadm_server_osupdate.php (v2.6) - If a Date is used to schedule O/S Update then the day specify is not used.
	- 2019_04_04 sadm_view_schedule.php (v2.6) - Show Calculated Next O/S Update Date & update occurrence.
	- 2019_04_04 sadm_view_server_info.php (v2.11) - Adapt for Schedule_text function change in library
	- 2019_04_07 sadm_check_requirements.sh (v1.3) - Use color variables from SADMIN Library.
	- 2019_04_07 sadmlib_screen.sh (v1.8) - Use Color constant variable now available from standard SADMIN Shell Libr.
	- 2019_04_07 sadmlib_std_demo.py (v3.4) - Don't show Database user name if run on client.
	- 2019_04_07 sadmlib_std_demo.sh (v3.10) - Don't show Database user name if run on client.
	- 2019_04_07 sadmlib_std.sh (v2.68) - Optimize execution time & screen color variable now available.
	- 2019_04_07 sadm_service_ctrl.sh (v2.7) - Use color variables from SADMIN Library.
	- 2019_04_07 sadm_ui_fsmenu.sh (v2.5) - Use color variables from SADMIN Libr.
	- 2019_04_07 sadm_view_subnet.php (v1.5) - Show Card Manufacturer when available.
	- 2019_04_08 sadm_uninstall.sh (v1.4) - Remove 'sadmin' line in /etc/hosts
	- 2019_04_09 sadmlib_std.sh (v2.69) - Fix tput error when running in batch mode and TERM not set.
	- 2019_04_11 sadmlib_std_demo.sh (v3.11) - Add Database column "active"
	- 2019_04_11 sadm_uninstall.sh (v1.5) - Show if we are uninstalling a 'client' or a 'server' on confirmation msg.
	- 2019_04_12 sadm_setup.py (v3.20) - Check DD connection for user 'sadmin' & 'squery' & ask pwd if failed
	- 2019_04_14 sadm_setup.py (v3.21) - Password for User sadmin and squery wasn't updating properly .dbpass file.
	- 2019_04_17 sadm_client_housekeeping.sh (v1.28) - Make 'sadmin' account & password never expire (Solve Acc. & sudo Lock)
	- 2019_04_17 sadm_fetch_clients.sh (v2.34) - Show Processing message only when active servers are found.
	- 2019_04_17 sadm_sysmon.pl (v2.31) - Get SADMIN Root Directory from /etc/environment.
	- 2019_04_17 sadm_uninstall.sh (v1.8) - When quitting script
	- 2019_04_17 sadm_view_schedule.php (v2.7) - Minor code cleanup and show "Manual
	- 2019_04_18 sadm_setup.py (v3.24) - Release 0.97 Re-tested with Ubuntu version.
	- 2019_04_19 sadm_sysmon.pl (v2.32) - Produce customized Error Message
	- 2019_04_19 setup.sh (v2.5) - Will now install python 3.6 on CentOS/RedHat 7 instead of 3.4
	- 2019_04_22 man_template.php (v1.1.) - Small Adjustment


## Release v[0.96.0](https://github.com/jadupl2/sadmin/releases) (2019-03-15)
- Change
	- 2019_02_16 sadmLib.php (v2.7) - Convert schedule metadata to one text line (Easier to read in Sched. List)
	- 2019_02_25 sadm_ui.sh (v2.7) - Nicer color presentation and code cleanup.
	- 2019_02_27 sadm_daily_farm_fetch.sh (v3.4) - Change error message when ping to system don't work
	- 2019_02_28 sadmlib_std.sh (v2.64) - 'lsb_release -si' return new string in RHEL/CentOS 8 Chg sadm_get_osname
	- 2019_03_03 sadm_client_housekeeping.sh (v1.27) - Make sure .gitkeep files exist in important directories
	- 2019_03_03 sadmlib_screen.sh (v1.6) - Added color possibilities and cursor control to library.
	- 2019_03_08 sadmlib_std.py (v2.26) - 'lsb_release -si' return new string in RHEL/CentOS 8
	- 2019_03_08 sadm_setup.py (v3.15) - Change related to RHEL/CentOS 8 and change some text messages.
- Fixes
	- 2019_02_06 sadmlib_std.sh (v2.62) - break error when finding system domain name.
- Improvement
	- 2019_02_25 sadmlib_fs.sh (v2.5) - SADMIN Filesystem Library - Major code revamp and bug fixes.
	- 2019_02_25 sadm_ui_fsmenu.sh (v2.4) - SysAdmin Menu - (sadm command) Code revamp and add color to menu.
- New
	- 2019_02_11 sadmInit.php (v3.4) - Add $SADMIN/www to PHP Path
	- 2019_02_19 sadm_fetch_clients.sh (v2.32) - Copy script rch file in global dir after each run.
	- 2019_02_25 sadm_setup.py (v3.14) - Reduce output on initial execution of daily scripts.
- Removed
	- 2019_03_09 sadm_sysmon.pl (v2.29) - Remove DateTime Module (Not needed anymore)
- Updated
	- 2019_03_01 setup.sh (v2.0) - Bug Fix and updated for RHEL/CensOS 8
	- 2019_03_04 setup.sh (v2.1) - More changes for RHEL/CensOS 8
	- 2019_03_08 setup.sh (v2.2) - Add EPEL repository when installing RHEL or CENTOS
