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
# 2018_07_19    v1.5 Added Scripts Error and Scripts Running in the Output (Same as Web Interface)
#@ 2018_07_20   v1.6 Wasn't Deleting work file at the end
#===================================================================================================
use English;


# --------------------------------------------------------------------------------------------------
# Global Variables definition
# --------------------------------------------------------------------------------------------------
my $SADM_BASE_DIR       = "$ENV{'SADMIN'}" || "/sadmin";                # SADMIN Root Dir.
my $SADM_BIN_DIR        = "$SADM_BASE_DIR/bin";                         # SADMIN bin Directory
my $SADM_WDATA_DIR      = "${SADM_BASE_DIR}/www/dat";                   # Dir where all *.rpt reside
$XDISPLAY= "$ENV{'DISPLAY'}";                                           # Variable ENV DIsplay
$VERSION_NUMBER = "1.6";                                                # SADM Version Number
$CLEAR=`tput clear`;
$RPT_FILE="$SADM_BASE_DIR/tmp/sadm_sysmon_tui_rpt.$$";
$RCH_FILE="$SADM_BASE_DIR/tmp/sadm_sysmon_tui_rch.$$";
$CMD_RPT="find $SADM_WDATA_DIR -type f -name *.rpt -exec cat {} > $RPT_FILE \\;" ;
$CMD_RCH="find $SADM_WDATA_DIR -type f -name *.rch -exec tail -1 {} \\;| awk 'match(\$8,/[1-2]/) { print }' >$RCH_FILE";
  
# --------------------------------------------------------------------------------------------------
#                               Display System Report file from all host
# --------------------------------------------------------------------------------------------------
sub display_report {
    $RDATE=`date`;
    $dash_line = "-";
    $dash_line x= 100;
    print "${CLEAR}SADMIN System Monitor Viewer - $VERSION_NUMBER";
    print "\nReport as of ${RDATE}${dash_line}\n\n";
    #print "$CMD_RPT";
    system ("$CMD_RPT");
    open (SADMRPT,"<$RPT_FILE") or die "Can't open $RPT_FILE: $!\n";
    while ($line = <SADMRPT>) {
        ($EType,$ENode,$EDate,$ETime,$EModule,$ESub,$EDesc,$Epage,$Email,$Escript) = split ';',$line;
        printf "%-7s %-10s %-9s %-5s %-15s %-13s %-30s\n",$EType,$ENode,$EDate,$ETime,$EModule,$ESub,$EDesc;
    }
    close (SADMRPT);

    # Display Scripts Error (Code 1) or Running (Code 2) by reading last line of every *.rch files 
    #print "$CMD_RCH";
    system ("$CMD_RCH");
    open (SADMRCH,"<$RCH_FILE") or die "Can't open $RCH_FILE: $!\n";
    while ($line = <SADMRCH>) {
        ($RNode,$RSDate,$RSTime,$REDate,$RETime,$RElapse,$RScript,$RCode) = split ' ',$line;
        if ($RCode == 1) { 
            $RType = "Error"; 
            $RDate = $REDate;
            $RTime = substr($RETime,0,5);
            $RDesc = "$RScript Ended with Error"
        }else{
            $RType = "Running";
            $RDate = $RSDate;
            $RTime = substr($RSTime,0,5);;
            $RDesc = "Script $RScript Running"
        }
        printf "%-7s %-10s %-9s %-5s %-15s %-13s %-30s\n",$RType,$RNode,$RDate,$RTime,"Linux","Script",$RDesc;
    }
    close (SADMRCH);
    unlink($RCH_FILE);
    unlink($RPT_FILE);
}


# --------------------------------------------------------------------------------------------------
#                       M A I N    P R O G R A M    S T A R T    H E R E 
# --------------------------------------------------------------------------------------------------
    while (TRUE) {
       display_report;
       print "\n${dash_line}\nReport will be refresh in 10 seconds\nPress CTRL-C to stop viewing\n";
       sleep 10;
    }

