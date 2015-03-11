#set -x
PROJECT=$1                              ; export PROJECT
export BASE_DIR="/svn/sadmin"           ; export BASE_DIR
WDATE=`date`				; export WDATE
svn delete -m "Delete Project" file:///${BASE_DIR}/${PROJECT}


# However, if you need to delete all record of it in the repo, use another method. 
