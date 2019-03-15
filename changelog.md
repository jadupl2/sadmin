# Changelog

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
