#!/usr/bin/env perl
# ---------------------------------------------------------------------------------------------
# SADM_Monitor Terminal Visualizer 
# Written in February 2017 by Jacques Duplessis.
# ---------------------------------------------------------------------------------------------
# 	- SADMIN Environment Variable must be define and must indicate
# 	  the location of this script
# ---------------------------------------------------------------------------------------------
use English;
#
# Global Variables definition
# ---------------------------------------------------------------------------------------------
my $SADM_BASE_DIR       = "$ENV{'SADMIN'}" || "/sadmin";                # SADMIN Root Dir.
my $SADM_BIN_DIR        = "$SADM_BASE_DIR/bin";                         # SADMIN bin Directory
my $SADM_RPT_DIR        = "${SADM_BASE_DIR}/www/dat";                   # Dir where rpt reside
$XDISPLAY= "$ENV{'DISPLAY'}";	   	                                    # Variable ENV DIsplay
$VERSION_NUMBER = "01.02";	   	                                        # SADM Version Number
$CLEAR=`tput clear`;
$RPT_FILE="$SADM_BASE_DIR/tmp/sadm_sysmon_tui.$$";
$CMD="find $SADM_RPT_DIR -type f -name *.rpt -exec cat {} > $RPT_FILE \\;" ;


# ---------------------------------------------------------------------------------------------
#                       Display slam report file from all host
# ---------------------------------------------------------------------------------------------
sub display_report {
    $RDATE=`date`;
	$dash_line = "-";
	$dash_line x= 100;
	print "${CLEAR}SADMIN SYSMON VIEWER - $VERSION_NUMBER \nReport as of ${RDATE}\n${dash_line}\n";
    #print "$CMD";
    system ("$CMD");
    open (SADMRPT,"<$RPT_FILE") or die "Can't open $RPT_FILE: $!\n";
   	while ($line = <SADMRPT>) {
        ($EType,$ENode,$EDate,$ETime,$EModule,$ESub,$EDesc,$Epage,$Email,$Escript) = split ';',$line;
	    printf "%-7s %-10s %-9s %-5s %-15s %-13s %-30s\n",$EType,$ENode,$EDate,$ETime,$EModule,$ESub,$EDesc;
   	}
   	close (SADMRPT);
}


# --------------------------------------------------------------------------------------------
#                       M A I N    P R O G R A M    S T A R T    H E R E 
# --------------------------------------------------------------------------------------------
	while (TRUE) {
	   display_report;
       print "\nReport will be refresh in 30 seconds\nPress CTRL-C to stop viewing";
       sleep 30;
	}
	
