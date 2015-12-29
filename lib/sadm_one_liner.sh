#
#***************************************************************************************************
#  USING SADMIN LIBRARY SETUP
#   This Line include all that is needed to use the SADMIN shell library Tools.
#   If you wish to change some field for a particular scrpit then insert sadm_include.sh
#    at the beginning of your script.
#
SADM_BASE_DIR=${SADMIN:="/sadmin"}              ; export SADM_BASE_DIR      # Script Root Base Dir.
[ -f ${SADM_BASE_DIR}/lib/sadm_include.sh ] && .${SADM_BASE_DIR}/lib/sadm_include.sh     
#***************************************************************************************************
#