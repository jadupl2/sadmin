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
# 2016_01_04 cmdline v1.1 Initial Version
# 2017_02_02 cmdline v1.2 Initial Working Version
# 2018_06_03 cmdline v1.3 Changes made to output format
# 2018_06_21 cmdline v1.4 Added comments
# 2018_07_19 cmdline v1.5 Added Scripts Error and Scripts Running in the Output (Same as Web Interface)
# 2018_07_20 cmdline v1.6 Wasn't Deleting work file at the end
# 2019_03_17 cmdline v1.7 Wasn't reporting error coming from result code history (rch) file.
# 2019_04_25 cmdline v1.8 Was showing 'Nothing to report' althought there was info displayed.
# 2019_06_07 cmdline v1.9 Include the alarm type in the screen output.
# 2020_04_08 cmdline v2.0 Correct alignment error.
#
#===================================================================================================
use English;


# --------------------------------------------------------------------------------------------------
# Global Variables definition
# --------------------------------------------------------------------------------------------------
my $SADM_BASE_DIR       = "$ENV{'SADMIN'}" || "/sadmin";                # SADMIN Root Dir.
my $SADM_BIN_DIR        = "$SADM_BASE_DIR/bin";                         # SADMIN bin Directory
my $SADM_WDATA_DIR      = "${SADM_BASE_DIR}/www/dat";                   # Dir where all *.rpt reside
my $XDISPLAY            = "$ENV{'DISPLAY'}";                            # Variable ENV Display
my $VERSION_NUMBER      = "2.0";                                        # SADM Version Number
my $CLEAR               = `tput clear`;                                 # Clear Screen escape code
my $RPT_FILE            = "$SADM_BASE_DIR/tmp/sadm_sysmon_tui_rpt.$$";  # Work for rpt files
my $RCH_FILE            = "$SADM_BASE_DIR/tmp/sadm_sysmon_tui_rch.$$";  # Work for rch files
my $CMD_RPT             = "find $SADM_WDATA_DIR -type f -name *.rpt -exec cat {} > $RPT_FILE \\;" ;
my $CMD_RCH="find $SADM_WDATA_DIR -type f -name \"*.rch\" -exec tail -1 {} \\;| awk 'match(\$10,/[1-2]/) { print }' >$RCH_FILE";




# --------------------------------------------------------------------------------------------------
#                               Display System Report file from all host
# --------------------------------------------------------------------------------------------------
sub display_report {
    $RDATE=`date`;
    $dash_line = "-";
    $dash_line x= 100;
    print "${CLEAR}SADMIN System Monitor Viewer - v${VERSION_NUMBER}";  # Heading Line
    print "\nReport as of ${RDATE}${dash_line}\n";                      # Report Date
    my $noreport = 0;                                                   # Nothing to report flag

    # Show The Sysmon Report File Collected from all SADMIN clients.
    system ("$CMD_RPT");                                                # Create List of *.rpt files
    open (SADMRPT,"<$RPT_FILE") or die "Can't open $RPT_FILE: $!\n";    # Open Resulting file
    while ($line = <SADMRPT>) {                                         # Read all alert line in file
      ($EType,$ENode,$EDate,$ETime,$EMod,$ESub,$EDesc,$Epage,$Email,$Escript) = split ';',$line;
      printf "%-8s %-10s %-10s %-5s %-15s %-13s %-30s\n",$EType,$ENode,$EDate,$ETime,$EMod,$ESub,$EDesc;
      $noreport =  1;                                                   # We have reported Error
    }
    close (SADMRPT);                                                    # Close RPT Work File.


    # Display Scripts Error (Code 1) or Running (Code 2) by reading last line of every *.rch files 
    system ("$CMD_RCH");                                                # Build Code 1,2 result file
    system ("cp $RCH_FILE /tmp/coco.txt");                             # For debugging copy file
    open (SADMRCH,"<$RCH_FILE") or die "Can't open $RCH_FILE: $!\n";    # Open Code 1,2 work file 
    while ($line = <SADMRCH>) {                                         # Read all Error/Running Line
        ($RNode,$RSDate,$RSTime,$REDate,$RETime,$RElapse,$RScript,$RGname,$RGtype,$RCode) = split ' ',$line;
        $RGrp   = "${RGname}/${RGtype}" ;                               # Alert Group Name & Type
        if ($RCode == 1) {                                              # Error Line Code (1)
            $RType  = "Error";                                          # Code 1 means Error
            $RDate  = $REDate;                                          # Error Date
            $RTime  = substr($RETime,0,5);                              # Error Time minus seconds
            $RDesc  = "$RScript Ended with Error";                      # Error Description
        }else{
            $RType  = "Running";                                        # Script Running code (2)
            $RDate  = $RSDate;                                          # Start Date of script
            $RTime  = substr($RSTime,0,5);                              # Start Time minus seconds
            $RDesc  = "Script $RScript Running";                        # Name of the running script
        }
        #printf "%-8s %-10s %-10s %-5s %-12s %-15s %-13s %-30s\n",$RType,$RNode,$RDate,$RTime,$RGrp,"Linux","Script",$RDesc;
        printf "%-8s %-10s %-10s %-5s %-15s %-13s %-30s\n",$RType,$RNode,$RDate,$RTime,$RGrp,"Script",$RDesc;
        $noreport =  1;                                                 # Flag at least line in report
    }
    close (SADMRCH);                                                    # Close RCH Work File

    if ($noreport == 0) { print "Nothing to report ..." ; }             # If nothing to report 
    unlink($RCH_FILE);                                                  # Delete Work RCH File
    unlink($RPT_FILE);                                                  # Delete Work RPT File
}


# --------------------------------------------------------------------------------------------------
#                       M A I N    P R O G R A M    S T A R T    H E R E 
# --------------------------------------------------------------------------------------------------
    while (TRUE) {
       display_report;                                                  # Refreah Report
       print "\n${dash_line}\nReport will be refresh in 10 seconds\nPress CTRL-C to stop viewing\n";
       sleep 10;                                                        # Sleep 10 seconds
    }

