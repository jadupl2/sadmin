#! /bin/sh
# Print SADM Database Information
# Jacques Duplessis - October 2017
# ==================================================================================================
tput clear 
echo "sadm_dbtool - version 1.0" 
export DBDIR="${SADMIN}/www/db" 
export DBNAME="sadm.db" 
export DATABASE="${DBDIR}/${DBNAME}"
export DBBACKUP="${DBDIR}/${DBNAME}.$(date "+%C%y.%m.%d_%H:%M:%S").gz"
export DBLOG="${SADMIN}/dat/db"
echo "Database Name is $DATABASE"

sqlite3 $DATABASE '.tables'
sqlite3 $DATABASE '.schema'
sqlite3 $DATABASE '.databases'

# Create a backup of all the Database
echo "Database Backup name is $DBBACKUP"
echo "Database Backup in progress"
echo '.dump' | sqlite3 $DATABASE | gzip > $DBBACKUP
echo "Database Backup ended with return code $?" 

exit

sqlite3 $DATABASE '.header on ; .mode csv ; .once /sadmin/tmp/sadm_cat.csv ; select * from sadm_cat;'
sqlite3 $DATABASE '.header on ; .mode csv ; .once /sadmin/tmp/sadm_cat.grp ; select * from sadm_grp;'
sqlite3 $DATABASE '.header on ; .mode csv ; .once /sadmin/tmp/sadm_cat.srv ; select * from sadm_srv;'


# Same has double clicking on the filename - Will open spreadsheet program with the csv
# .system /sadmin/tmp/sadm.csv

