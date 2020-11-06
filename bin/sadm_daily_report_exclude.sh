# Daily Report Exclude List - v1.0
# This file is source by the script sadm_daily_report.sh,
# to exclude some servers or some script from reports.
# No Scripts or Server name should include spaces.
# -----------------------------------------------------------------------------


# SCRIPTS variable declare the script names you don't want to see in daily script report.
SCRIPTS="sadm_backup sadm_rear_backup sadm_nmon_watcher " 
#
# Exclude scripts that are executing as part of sadm_client_sunset.
# If any error encountered in the scripts below, error will be reported by sadm_client_sunset.
SCRIPTS="$SCRIPTS sadm_dr_savefs sadm_create_sysinfo sadm_cfg2html"
#
# Exclude System Startup and Shutdown Script for Daily scripts Report
SCRIPTS="$SCRIPTS sadm_startup sadm_shutdown"


# Server name to be exclude from every Daily Report (Backup, Rear and Scripts)
SERVERS="raspi2 "
