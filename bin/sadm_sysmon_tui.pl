#!/usr/bin/env perl
#===================================================================================================
#   Author   :  Jacques Duplessis
#   Title    :  sadm_sysmon_tui.pl
#   Synopsis :  Terminal SADMIN System Monitor viewer
#   Version  :  1.0
#   Date     :  15 Janvier 2016
#   Requires :  sh
#===================================================================================================
# Change Log
# 2016_01_04    v1.1 Initial Version
# 2017_02_02    v1.2 Initial Working Version
# 2018_06_03    v1.3 Changes made to output format
# 2018_06_21    v1.4 Added comments
#===================================================================================================
use English;


# --------------------------------------------------------------------------------------------------
# Global Variables definition
# --------------------------------------------------------------------------------------------------
my $SADM_BASE_DIR       = "$ENV{'SADMIN'}" || "/sadmin";                # SADMIN Root Dir.
my $SADM_BIN_DIR        = "$SADM_BASE_DIR/bin";                         # SADMIN bin Directory
my $SADM_RPT_DIR        = "${SADM_BASE_DIR}/www/dat";                   # Dir where all *.rpt reside
$XDISPLAY= "$ENV{'DISPLAY'}";                                           # Variable ENV DIsplay
$VERSION_NUMBER = "1.4";                                                # SADM Version Number
$CLEAR=`tput clear`;
$RPT_FILE="$SADM_BASE_DIR/tmp/sadm_sysmon_tui.$$";
$CMD="find $SADM_RPT_DIR -type f -name *.rpt -exec cat {} > $RPT_FILE \\;" ;


  
# --------------------------------------------------------------------------------------------------
#                               Display System Report file from all host
# --------------------------------------------------------------------------------------------------
sub display_report {
    $RDATE=`date`;
    $dash_line = "-";
    $dash_line x= 100;
    print "${CLEAR}SADMIN System Monitor Viewer - $VERSION_NUMBER";
    print "\nReport as of ${RDATE}${dash_line}\n\n";
    #print "$CMD";
    system ("$CMD");
    open (SADMRPT,"<$RPT_FILE") or die "Can't open $RPT_FILE: $!\n";
    while ($line = <SADMRPT>) {
        ($EType,$ENode,$EDate,$ETime,$EModule,$ESub,$EDesc,$Epage,$Email,$Escript) = split ';',$line;
        printf "%-7s %-10s %-9s %-5s %-15s %-13s %-30s\n",$EType,$ENode,$EDate,$ETime,$EModule,$ESub,$EDesc;
    }
    close (SADMRPT);
}


# --------------------------------------------------------------------------------------------------
#                       M A I N    P R O G R A M    S T A R T    H E R E 
# --------------------------------------------------------------------------------------------------
    while (TRUE) {
       display_report;
       print "\n${dash_line}\nReport will be refresh in 30 seconds\nPress CTRL-C to stop viewing\n";
       sleep 30;
    }

