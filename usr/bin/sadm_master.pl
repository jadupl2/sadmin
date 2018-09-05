#!/usr/bin/perl 
# ----------------------------------------------------------------------------------------------------
# Standard Life Application Monitor Master Program.
# This program used the *.rpt file in $SLAMDIR/tmp dir to produce the HTML file of SLAM.
# This program is to be run frequently to produce updated HTML File.
# Written in August 1998 by Jacques Duplessis.
# Version 2.2b in May 1999.
# Version 03.00a in August 1999 - Revise version to include Host and Switch respond and Backup Lookup
# Version 04.02  in July 2003   - Add ftp slam page
# ----------------------------------------------------------------------------------------------------
# SLAMDIR Environment Variable must be define and must indicate
# the location of the slav.pl  file (export SLAMDIR=/sysadmin/slamv2)
# ----------------------------------------------------------------------------------------------------
use English;
#use File;
use Date::Calc qw(:all);
#use Mail::Internet;
use Time::Local;
#use Net::SMTP;

# Global Variables definition
# ----------------------------------------------------------------------------------------------------
my $DEBUG = "$ENV{'SLAM_DEBUG'}" || 9;  	# Set for debugging purpose set to 5 
#
my $SLAMDIR = "/slam";   		        # Directory where slam file reside
my $SLAMNOV_DIR  = "$SLAMDIR/files/nov";        # Slam Novell Directory
my $SLAMFTP_DIR  = "$SLAMDIR/files/ftp";        # Slam ftp Directory
my $SLAMINT_DIR  = "$SLAMDIR/files/int";        # Slam Integration Directory
my $SLAMDBA_DIR  = "$SLAMDIR/files/dba";        # Slam DBA Directory
my $SLAMWIN_DIR  = "$SLAMDIR/files/win";        # Slam WIN Directory
my $SLAMAIX_DIR  = "$SLAMDIR/files/aix";        # Slam AIX Directory
my $SLAMTMP_DIR  = "$SLAMDIR/tmp";        	# Slam TMP Directory
my $SLAMWWW_DIR = "/www/html/slam"; #		# Dir where html reside
#
my $SLAMWRK_FILE= "$SLAMTMP_DIR/slamwrk.tmp";  # Slam first work File
my $SLAMTMP_FILE= "$SLAMTMP_DIR/slamtmp.tmp";  # Slam second work File
my $SLAMLCK_FILE= "$SLAMDIR/slam_master.lock"; # Slam SLam Master Lock file
my $SLAMEHI_FILE= "$SLAMDIR/log/slam_ehist.log";# Slam Email History FIle
my $SLAMPAG_FILE= "$SLAMDIR/log/slam_qpage.log";# Slam qpage log file
my $SLAMMAIL_FILE="$SLAMDIR/log/slam_email.log";# Slam email log file
my $SLAMQHI_FILE= "$SLAMDIR/log/slam_qhist.log";# Slam Qpage History FIle
my $SLAMQCF_FILE= "$SLAMDIR/cfg/slam_qpage.cfg";# Slam Default Qpage Config file
my $SLAMECF_FILE= "$SLAMDIR/cfg/slam_email.cfg";# Slam Default Email Config file
my $SLAMHOST= "$SLAMDIR/cfg/slam.hosts";	# Slam hosts file
my $SLAMBACK= "$SLAMDIR/log/slam_backup.log";	# Slam ASCII Backup report file
my $QPAGEID= " ";				# QPAGEID define in /etc/qpage.cf

#
my $CMD_TOUCH = "/bin/touch" ;              # Location of the unix touch command
my $CMD_MAIL = "/usr/bin/mail" ;                # Location of the unix mail command
my $CMD_TAIL = "/usr/bin/tail" ;                # Location of the unix tail command
my $CMD_QPAGE = "/sysadmin/bin/qpage" ;         # Location of the qpage command
my $VERSION_NUMBER = "04.03";	   	    	# SLAM Version Number
my $FTP_DESC = "";	   	    		# FTP Page Description
my @host_array = ();				# Contain the slam host file
my @qpage_array = ();				# Contain the alias to page
my @sub_array = ();				# Contain the sub module splitted name for ftp page
my $SLAM_EMAIL = "jacques.duplessis\@videotron.ca";# Address to send Error when it occurs
my $SLAM_FROMTO = "slam\@slamserver.maison.ca";   # Address to send Error when it occurs
my $EMAIL_DOMAIN = "videotron.ca" ;          # Email  destination domain
my $BDESC = "" ;			        # Backup Desc for NOvell
$OSNAME    =~ tr/A-Z/a-z/;                      # OS name is in lowercase
printf "OSNAME = $OSNAME\n" ;                   # Print OS name as Info




# ----------------------------------------------------------------------------------------------------
# This function is called at the very beginning of the script.
# It load the content of the slam.hosts file in an array in memory.
# ----------------------------------------------------------------------------------------------------
sub Load_slam_host {

my $widx = 0;

    if ($DEBUG >= 5) { print "\nLoading slam.hosts file\n" ; }; 

# LOad SLam.hosts in Memory
    open (SLAMHOST,"$SLAMHOST") or die "Can't open $SLAMHOST: $!\n";
    while ($line = <SLAMHOST>) 
        {
        next if $line =~ /^#/ ;  		# Don't load Comment
        next if $line =~ /^$/ ;  		# Don't load Blank LIne
        $line =~ tr/A-Z/a-z/;                   # Make line lowercase
        $host_array[$widx++] = $line ;  	# Load line in Array
        if ($DEBUG >= 5) { print "Loading $line" ; }; 
        }
    close SLAMHOST;
    if ($DEBUG >= 5) { print "\nSLAM Host File Loaded\n" ; }; 
}









# ----------------------------------------------------------------------------------------------------
# This function is called everytime a error occured on a prod node (red color)
# It build a error record for the slam hisroty file.
# Then it check if the record is already in the slam history file.
# If it not then is it inserted and the sysadmin is page.
# ----------------------------------------------------------------------------------------------------
sub qpage {

# Build the history record line.
	my ($HType, $HNode, $HDate, $HTime, $HModule, $HSub, $HDesc, $HOStype, $HQPage) = @_;
	my $index = 0; 
	chomp $HQPage;

	
# Check if error were already logged
     	$pline =  sprintf ("%-7s %-10s %-9s %-10s %-18s %s",$HType, $HNode, $HDate, $HModule, $HSub, $HDesc);
    	open (SLAMHIST,"< $SLAMQHI_FILE") or die "Can't open $SLAMQHI_FILE: $!\n";
    	my $record_found=0;
    	while ($hline = <SLAMHIST>) { 
              chomp ($hline);
	      if ($hline eq $pline) { $record_found=1 ;last; }; 
    	}
        close SLAMHIST;
        if ($record_found != 0) { return ;} # If already log exit function

#       
# If it is a backup module on Novell then page Gary 
	if ( ($HModule eq "backup") && ($HOStype eq "nov") ) { $HQPage = "tsmman" ; }

	
# If first time error detecded today - Log it in history file
        open (SLAMHIST,">> $SLAMQHI_FILE") or die "Can't open $SLAMQHI_FILE: $!\n";
	printf SLAMHIST "%s\n", $pline;
        close SLAMHIST;


# if name to page is in qpage alias file - replace alias by actual email.
	if ($DEBUG >= 5)  { print "The Qpage name BEFORE extending name is $HQPage\n";}
	my @qpage_array = split '\,', $HQPage;
	my $extended_name = (); chomp $extended_name;
        for ($index = 0; $index < @qpage_array; $index++) {     
            if ( length $qpage_array[$index] == 0) { last; }   # A - may be used in cfg for a place holder
            if ( $qpage_array[$index] eq "-" ) { last; }   # A - may be used in cfg for a place holder
	    my $new_name = $qpage_array[$index];
	    open (SLAM_QPAGE_CONFIG,"< $SLAMQCF_FILE") or die "Can't open $SLAMQCF_FILE: $!\n";
            while ($qline = <SLAM_QPAGE_CONFIG>) {
                  chomp ($qline);
                  next if $qline =~ /^#/ ;  		# Comment
                  next if $qline =~ /^$/ ;  		# Blank LIne
                  ($qalias, $qname) = split ' ',$qline;
                  if ($qalias eq $qpage_array[$index]) { $new_name=$qname ; last; };
	    }
	    close SLAM_QPAGE_CONFIG;
	    $extended_name = "${extended_name}${new_name},";
	}
	chop $extended_name;
	if ($DEBUG >= 5)  { print "The Qpage name AFTER extending name is $extended_name\n";}

# If array is empty - Cause it contain a dash - Exit function
	if ( length $extended_name == 0 ) { return ;}


# Page Every one receive in parameter
	my @qpage_array = split '\,', $extended_name;
	for ($index = 0; $index < @qpage_array; $index++) {     
             if ( $qpage_array[$index] eq "-" ) { last; }   # A - may be used in cfg for a place holder
             if ( length $qpage_array[$index] == 0 ) { last; }

# If was supposed to page NT, Check if first letters of node are "ne", Then page Exchange Pager 
             $QPAGEID = $qpage_array[$index] ;
             if ((substr ($HNode,0,2) eq "ne") && ($QPAGEID eq "ts-nt")) { $QPAGEID = "ts-mail" };
             if (($HNode eq "nmmq1010")        && ($QPAGEID eq "ts-nt")) { $QPAGEID = "ts-mail" };
             if (($HNode eq "nmmq2000")        && ($QPAGEID eq "ts-nt")) { $QPAGEID = "ts-mail" };

             if ($DEBUG >= 5) { print "$CMD_QPAGE -f SLAM $QPAGEID $HNode_$HDate_$HTime_$HDesc\n";}
             if ($DEBUG >= 5) { print "Qpage Sent : $Node $HDesc - page $QPAGEID\n";}
             @cmd = ("$CMD_QPAGE -f SLAM $QPAGEID \"${HNode}_${HDesc}\"");
             $return_code = 0xffff & system @cmd ;

# Record Paging info in slam_qpage.log
	     open (SLAMPAGE,">> $SLAMPAG_FILE") or die "Can't open $SLAMPAG_FILE: $!\n";
	     $QPAGE_DATE = `date +%d/%m/%Y`; chop $QPAGE_DATE;
	     $QPAGE_TIME = `date +%H:%M`; chop $QPAGE_TIME;
             printf SLAMPAGE "Qpage %s %s \n%s\n", $QPAGE_DATE, $QPAGE_TIME, $pline;
             close SLAMPAGE;
	}

}




# --------------------------------------------------------------------------------------------------
# Send Email Function
# --------------------------------------------------------------------------------------------------
sub send_email {

        my ($email_to, $email_host, $email_message, $email_subject, $email_severity) = @_;
	if ($DEBUG >= 6) { print "\nEntering send_aix_email\n\n";};

# Check if error were already logged is history file
     	my $EMAIL_DATE = `date +%d/%m/%y`; chop $EMAIL_DATE;
        $pline =  sprintf ("%-10s %-2s %-10s %-30s",$EMAIL_DATE,$email_severity,$email_host,$email_subject);
        open (SLAM_EHIST,"< $SLAMEHI_FILE") or die "Can't open $SLAMEHI_FILE: $!\n";
        my $record_found=0;
        while ($hline = <SLAM_EHIST>) {
              chomp ($hline);
              if ($hline eq $pline) { $record_found=1 ;last; };
        }
        close SLAM_EHIST;
        if ($record_found != 0) { return ;} # If already log exit function


# If first time error detected today - Log it in history file
        open (SLAM_EHIST,">> $SLAMEHI_FILE") or die "Can't open $SLAMEHI_FILE: $!\n";
        printf SLAM_EHIST "%s\n", $pline;
        close SLAM_EHIST;

# If was supposed to mail NT, Check if first letters of node are "ne", Then mail mail group 
        if ((substr ($email_host,0,2) eq "ne") && ($email_to eq "win")) { $email_to = "mail" };
        if (($email_host eq "nmmq1010")        && ($email_to eq "win")) { $email_to = "mail" };
        if (($email_host eq "nmmq2000")        && ($email_to eq "win")) { $email_to = "mail" };

# if name to page is in qpage alias file - replace alias by actual email.
	if ($DEBUG >= 5)  { print "The Email name BEFORE extending name is $email_to\n";}
	chomp $email_to;
	my @email_array = split '\,', $email_to;
	my $extended_name = (); chomp $extended_name;
        for ($index = 0; $index < @email_array; $index++) {     
            if ( length $email_array[$index] == 0) { last; }   # Nothing in email_to ? 
            if ( $email_array[$index] eq "-" ) { last; }       # A - may be used in cfg for a place holder
	    my $new_name = $email_array[$index];
	    open (SLAM_EMAIL_CONFIG,"< $SLAMECF_FILE") or die "Can't open $SLAMECF_FILE: $!\n";
            while ($eline = <SLAM_EMAIL_CONFIG>) {
                  chomp ($eline);
                  next if $eline =~ /^#/ ;  		# Comment
                  next if $eline =~ /^$/ ;  		# Blank LIne
                  ($ealias, $ename) = split ' ',$eline;
                  if ($ealias eq $email_array[$index]) { $new_name=$ename ; last; };
	    }
	    close SLAM_EMAIL_CONFIG;
	    $extended_name = "${extended_name}${new_name},";
	}
	chop $extended_name;
	if ($DEBUG >= 5)  { print "The Email name AFTER extending name is $extended_name\n";}

# If array is empty - Cause it contain a dash - Exit function
	if ( length $extended_name == 0 ) { return ;}


# Subject
	$subject="SLAM ALERT: $email_host $email_subject"; 
	if ("$email_severity" eq "W") { $subject="SLAM WARNING: $host_in_problem $email_subject"; }
	if ("$email_severity" eq "w") { $subject="SLAM WARNING: $host_in_problem $email_subject"; }

# Message
        ($year,$month,$day,$hour,$min,$sec) = Today_and_Now();		  
	my $mytime = sprintf ("%02d/%02d/%04d %02d:%02d", $day,$month,$year,$hour,$min);
	$body="$mytime - Host $email_host - $email_subject";

# Email Every one receive in parameter
	my @email_array = split '\,', $extended_name;
	for ($index = 0; $index < @email_array; $index++) {     
             if ( $email_array[$index] eq "-" ) { last; }   # A - may be used in cfg for a place holder
             if ( length $email_array[$index] == 0 ) { last; }
	     $address = "$email_array[$index]\@${EMAIL_DOMAIN}";
	     if ($DEBUG >= 5) { print "$subject - Email Sent to $address\n";}
             if ($DEBUG >= 6) { print "echo $body | $CMD_MAIL -s \"$subject\" $address\n";}
             @cmd = ("echo $body | $CMD_MAIL -s \"$subject\" $address");
             $return_code = 0xffff & system @cmd ;
             # Record Paging info in email.log       
	     open (SLAMMAIL_LOG,">> $SLAMMAIL_FILE") or die "Can't open $SLAMMAIL_FILE: $!\n";
	     my $mail_date = `date +%d/%m/%Y`; chop $mail_date;
	     my $mail_time = `date +%H:%M`; chop $mail_time;
             printf SLAMMAIL_LOG "Email %s %s %s %s\n", $mail_date, $mail_time, $address, $subject;
             close SLAMMLAIL_LOG;
	}
}








#
# ----------------------------------------------------------------------------------------------------
#  Ping hosts and alias in slam.hosts - If dead add error in report file
# ----------------------------------------------------------------------------------------------------
sub PingHost{
	my $index = $hostname = $hosttype = $hostrtype = $nodenum = $alias = "0";
	my $host_down_flag = 0 ;


# Initialize Ping error log file
	@cmd = ("date > $SLAMDIR/log/ping.log 2>&1");
	system @cmd;


# PING THE PRIMARY INTERFACE 
# ==========================

# Ping each host in slam.hosts file
        for ($index = 0; $index < @host_array; $index++) {
            ($hostname, $hosttype, $hostrtype, $nodenum, $alias, $ostype, $copytype, $ping) = split ' ',$host_array[$index];
            next if $ping =~ /noping/ ;
	    $host_down_flag = $return_code = 0 ;

# First Interface - First Ping
            @cmd = ("ping -c1 $hostname >>$SLAMDIR/log/ping.log 2>&1");
            $return_code = 0xffff & system @cmd ;
    	    if ($DEBUG >= 5) { print "Return code of first ping to $hostname ($ostype) $is $return_code\n" ; }; 
# First Interface - Second Ping
            if ($return_code != 0) {
               @cmd = ("ping -c2 $hostname >>$SLAMDIR/log/ping.log 2>&1");
               $return_code = 0xffff & system @cmd ;
    	       if ($DEBUG >= 5) { print "Return code of second ping to $hostname ($ostype) is $return_code\n" ; }; 
            }
# First Interface - Third Ping
            if ($return_code != 0) {
               @cmd = ("ping -c2 $hostname >>$SLAMDIR/log/ping.log 2>&1");
               $return_code = 0xffff & system @cmd ;
    	       if ($DEBUG >= 5) { print "Return code of Third ping to $hostname ($ostype) is $return_code\n" ; }; 
	    }
# If ping did not work, erase current host report file (hostname.rpt) with host down error line
            if ($return_code != 0) {
     	       $ERR_DATE = `date +%d/%m/%Y`; chop $ERR_DATE;
               $ERR_TIME = `date +%H:%M`;    chop $ERR_TIME;
               if ( $ostype eq "aix" ) {
 	          open (SLAMWRK,">$SLAMAIX_DIR/rpt/aix.rpt") or die "Can't open $SLAMAIX_DIR/rpt/aix.rpt: $!\n";
                  printf SLAMWRK "%s;%s;%s;%s;%s;%s;%s;\n","Error",$hostname,$ERR_DATE,$ERR_TIME,"AIX" ,"NETWORK" ,"Cannot ping $hostname - Host may be down($return_code)!";
               }
               if ( $ostype eq "nt" ) {
 	          open (SLAMWRK,">$SLAMWIN_DIR/rpt/win.rpt") or die "Can't open $SLAMWIN_DIR/rpt/win.rpt: $!\n";
                  printf SLAMWRK "%s;%s;%s;%s;%s;%s;%s;\n","Error",$hostname,$ERR_DATE,$ERR_TIME,"NT" ,"NETWORK" ,"Cannot ping $hostname - NT Host may be down($return_code)!";
               }
               if ( $ostype eq "nov" ) {
 	          open (SLAMWRK,">$SLAMNOV_DIR/rpt/nov.rpt") or die "Can't open $SLAMNOV_DIR/rpt/nov.rpt: $!\n";
                  printf SLAMWRK "%s;%s;%s;%s;%s;%s;%s;\n","Error",$hostname,$ERR_DATE,$ERR_TIME,"Netware" ,"NETWORK" ,"Cannot ping $hostname - Novell Host may be down($return_code)!";
               }
	       close SLAMWRK;
	       $host_down_flag = 1 ;   # The rpt file was written once.
            }




# PING THE SECONDARY INTERFACE 
# ============================

# Ping Second Interface if not the same name or name is "none" 
	    $return_code = 0 ;
# Second Interface - First Ping
            if ($alias ne "none" and $alias ne $hostname) {
               @cmd = ("ping -c2 $alias >>$SLAMDIR/log/ping.log 2>&1");
               $return_code = 0xffff & system @cmd ;
    	       if ($DEBUG >= 5) { print "Return code of first ping to $alias ($ostype) is $return_code\n" ; }; 
# Second Interface - Second Ping
               if ($return_code != 0) {
                  @cmd = ("ping -c1 $alias >>$SLAMDIR/log/ping.log 2>&1");
                  $return_code = 0xffff & system @cmd ;
    	          if ($DEBUG >= 5) { print "Return code of second ping to $alias ($ostype) is $return_code\n" ; }; 
	       }
# Second Interface - Third Ping
               if ($return_code != 0) {
                  @cmd = ("ping -c2 $alias >>$SLAMDIR/log/ping.log 2>&1");
                  $return_code = 0xffff & system @cmd ;
    	          if ($DEBUG >= 5) { print "Return code of third ping to $alias ($ostype) is $return_code\n" ; }; 
	       }
            }
# If Second ping did not work, erase current host report file with host down 
            if ($return_code != 0) {
	       if ($host_down_flag == 0) {
                  if ( $ostype eq "aix" ) { open (SLAMWRK,">$SLAMAIX_DIR/rpt/aix.rpt") or die "Can't open $SLAMAIX_DIR/rpt/aix.rpt: $!\n";}
                  if ( $ostype eq "nt"  ) { open (SLAMWRK,">$SLAMWIN_DIR/rpt/aix.rpt") or die "Can't open $SLAMWIN_DIR/rpt/win.rpt: $!\n";}
                  if ( $ostype eq "nov" ) { open (SLAMWRK,">$SLAMNOV_DIR/rpt/nov.rpt") or die "Can't open $SLAMNOV_DIR/rpt/nov.rpt: $!\n";}
               }else{
                  if ( $ostype eq "aix" ) { open (SLAMWRK,">>$SLAMAIX_DIR/rpt/aix.rpt") or die "Can't open $SLAMAIX_DIR/rpt/aix.rpt: $!\n";}
                  if ( $ostype eq "nt"  ) { open (SLAMWRK,">>$SLAMWIN_DIR/rpt/aix.rpt") or die "Can't open $SLAMWIN_DIR/rpt/win.rpt: $!\n";}
                  if ( $ostype eq "nov" ) { open (SLAMWRK,">>$SLAMNOV_DIR/rpt/nov.rpt") or die "Can't open $SLAMNOV_DIR/rpt/nov.rpt: $!\n";}
               }	       		  
     	       $ERR_DATE = `date +%d/%m/%Y`; chop $ERR_DATE;
               $ERR_TIME = `date +%H:%M`;    chop $ERR_TIME;
               if  ($ostype eq "aix") { printf SLAMWRK "%s;%s;%s;%s;%s;%s;%s;\n","Error",$hostname,$ERR_DATE,$ERR_TIME,"NT" ,"NETWORK" ,"Cannot ping $alias - AIX Host may be down($return_code)!";}
               if  ($ostype eq "nt" ) { printf SLAMWRK "%s;%s;%s;%s;%s;%s;%s;\n","Error",$hostname,$ERR_DATE,$ERR_TIME,"NT" ,"NETWORK" ,"Cannot ping $alias - NT Host may be down($return_code)!";}
               if  ($ostype eq "nov") { printf SLAMWRK "%s;%s;%s;%s;%s;%s;%s;\n","Error",$hostname,$ERR_DATE,$ERR_TIME,"NT" ,"NETWORK" ,"Cannot ping $alias - Novell Host may be down($return_code)!";}
	       close SLAMWRK;
            }
        }
}







#
# ----------------------------------------------------------------------------------------------------
#  Function to is generating all Team Slam Page (win,aix,dba,int,nov)
# ----------------------------------------------------------------------------------------------------
sub generate_slam_html_page {

# Save variables received as parameter (dba,int,aix,win,nov)
        my ($page_type) = @_;
	if ($DEBUG >= 5) { print "\nGenerating SLAM $page_type main HTML page\n" ; }; 

# Open HTML Output File
	open (SLAMWRK,">$SLAMWRK_FILE") or die "Cannot open $SLAMWRK_FILE: $!\n";
	
   	if ($page_type eq "win") { open (SLAMRPT, "cat $SLAMWIN_DIR/rpt/*.rpt 2>/dev/null | sort |");}
   	if ($page_type eq "aix") { open (SLAMRPT, "cat $SLAMAIX_DIR/rpt/*.rpt 2>/dev/null | sort |");}
   	if ($page_type eq "int") { open (SLAMRPT, "cat $SLAMINT_DIR/rpt/*.rpt 2>/dev/null | sort |");}
   	if ($page_type eq "dba") { open (SLAMRPT, "cat $SLAMDBA_DIR/rpt/*.rpt 2>/dev/null | sort |");}
   	if ($page_type eq "nov") { open (SLAMRPT, "cat $SLAMNOV_DIR/rpt/*.rpt 2>/dev/null | sort |");}
	
	while ($line = <SLAMRPT>) {
              $line =~ tr/A-Z/a-z/;
	      chomp $line;
              ($EType, $ENode, $EDate, $ETime, $EModule, $ESub, $EDesc, $EQpage, $EEmail) = split ';',$line;
              chomp $EDesc;
	      if (($EQpage =~ dba) || ($EEmail =~ dba)) { system ("echo \"$line\" >> $SLAMDBA_DIR/rpt/dba.rpt");}
              $backos = "nt"  ; 	# Default to nt os
              for ($index = 0; $index < @host_array; $index++) {
                  ($hostname, $hosttype, $hostrtype, $nodenum, $alias, $ostype, $copytype, $ping) = split ' ',$host_array[$index];
                  if ( $hostname eq $ENode ) { $backos = $ostype ;  last ; } 
              }
              $FONTCOLOR = "000000" ;					# Fontcolor is black
              $BGCOLOR   = "#C0C0C0" ;					# Background color is green by default
              if ( $EType eq "warning" ) {
                 if ( $hosttype eq "prd" ) { $BGCOLOR = "#FFFF00" } ; 	# Background Color is Yellow
                 if ( $hosttype eq "dev" ) { $BGCOLOR = "#FFFFFF" } ; 	# Background Color is White
              }
              if ( $EType eq "error" ) {
                 if ( $hosttype eq "prd" ) {$BGCOLOR = "#FF0000"}; 	# Background Color is Red
                 if ( $hosttype eq "dev" ) {$BGCOLOR = "#FFFF00"}; 	# Background Color is Yellow
              }
              if ( $EType eq "running" ) { $BGCOLOR = "#00FF00"; };  	#Background Color is Green when job running



# If aix page and Oracle Module then
	     my $go_dba_only = 0; 
	     if (($page_type eq "aix") && ($EModule eq "DBA_BACKUP")) { $go_dba_only = 1 ; }
	     if (($page_type eq "aix") && ($EModule eq "dba_backup")) { $go_dba_only = 1 ; }
	     if (($page_type eq "aix") && ($EModule eq "db2"))        { $go_dba_only = 1 ; }
	     if (($page_type eq "aix") && ($EModule eq "oracle"))     { $go_dba_only = 1 ; }
	     if (($page_type eq "aix") && ($EModule eq "sql_backtrack")) { $go_dba_only = 1 ; }	
	     if (($page_type eq "aix") && ($ESub eq "filesystem") && ($EDesc =~ "db2")) { $go_dba_only = 1 ; }	
	     if (($page_type eq "aix") && ($ESub eq "filesystem") && ($EDesc =~ "ora")) { $go_dba_only = 1 ; }	
	     if (($page_type eq "aix") && ($ESub eq "filesystem") && ($EDesc =~ "dmp")) { $go_dba_only = 1 ; }
	     if (($page_type eq "aix") && ($ESub eq "filesystem") && ($EDesc =~ "exp")) { $go_dba_only = 1 ; }
	     if (($page_type eq "aix") && ($ESub eq "filesystem") && ($EDesc =~ "dbf"))       { $go_dba_only = 1 ; }
	     if (($page_type eq "aix") && ($ESub eq "filesystem") && ($EDesc =~ "arc"))       { $go_dba_only = 1 ; }
	     if (($page_type eq "aix") && ($ESub eq "filesystem") && ($EDesc =~ "datatools")) { $go_dba_only = 1 ; }

	     if ($go_dba_only == 1) { 
	        print "Skip Oracle Page Only : $line\n" ; 
	     }else{	     
		# Output HTML lines to the SLAM output file 
               	printf (SLAMWRK "<tr>\n"); 
	        printf (SLAMWRK "  <td align=\"center\" bgcolor=$BGCOLOR><font color=$FONTCOLOR>$EType</font></td>\n");
     	     	printf (SLAMWRK "  <td align=\"center\" bgcolor=$BGCOLOR><font color=$FONTCOLOR>$ENode</font></td>\n");
             	printf (SLAMWRK "  <td align=\"center\" bgcolor=$BGCOLOR><font color=$FONTCOLOR>$EDate</font></td>\n");
             	printf (SLAMWRK "  <td align=\"center\" bgcolor=$BGCOLOR><font color=$FONTCOLOR>$ETime</font></td>\n");
             	printf (SLAMWRK "  <td align=\"center\" bgcolor=$BGCOLOR><font color=$FONTCOLOR>$EModule</font></td>\n");
             	printf (SLAMWRK "  <td align=\"center\" bgcolor=$BGCOLOR><font color=$FONTCOLOR>$ESub</font></td>\n");
             	printf (SLAMWRK "  <td align=\"left\"   bgcolor=$BGCOLOR><font color=$FONTCOLOR>%s</font></td>\n",$EDesc);
             	printf (SLAMWRK "</tr>\n");
             }


# If red line was selected then Page and Email Appropriate Team
             if ($BGCOLOR eq "#FF0000") { 
	        chomp $EQpage;
	        if ( length $EQpage == 0 ) { $EQpage=$page_type; }  	# Default
		if ($go_dba_only == 1)     { $EQpage="dba" ;}		# if Only For DBA make sure not aix
		qpage ($EType,$ENode,$EDate,$ETime,$EModule,$ESub,$EDesc,$backos,$EQpage);
	        chomp $EEmail;
	        if ( length $EEmail == 0 ) { $EEmail=$page_type;}  	# Default
		if ($go_dba_only == 1)     { $EEmail="dba" ;}		# if Only For DBA make sure not aix
		send_email ($EEmail,$ENode,$EDesc,$EDesc,"e");
	        }
	     
# If yellow line was selected and Prod. System then Email Appropriate Team
             if (($BGCOLOR eq "#FFFF00")  && ( $hosttype eq "prd" )) { 
	        chomp $EEmail;
	        if ( length $EEmail == 0 ) { $EEmail=$page_type;}  	# Default
		if ($go_dba_only == 1) { $EEmail="dba" ;}		# if Only For DBA make sure not aix
		send_email ($EEmail,$ENode,$EDesc,$EDesc,"w");
	     }


        }  
        close (SLAMRPT); close (SLAMWRK);

# Concatenate html Header + Middle + Bottom files
   	if ($page_type eq "win") { 
	   system ("cat $SLAMDIR/html/win_slam1.html $SLAMWRK_FILE $SLAMDIR/html/win_slam2.html > $SLAMWWW_DIR/win_slam.html");}
   	if ($page_type eq "int") { 
	   system ("cat $SLAMDIR/html/int_slam1.html $SLAMWRK_FILE $SLAMDIR/html/int_slam2.html > $SLAMWWW_DIR/int_slam.html");}
   	if ($page_type eq "aix") { 
	   system ("cat $SLAMDIR/html/aix_slam1.html $SLAMWRK_FILE $SLAMDIR/html/aix_slam2.html > $SLAMWWW_DIR/aix_slam.html");}
   	if ($page_type eq "dba") { 
	   system ("cat $SLAMDIR/html/dba_slam1.html $SLAMWRK_FILE $SLAMDIR/html/dba_slam2.html > $SLAMWWW_DIR/dba_slam.html");}
   	if ($page_type eq "nov") { 
	   system ("cat $SLAMDIR/html/nov_slam1.html $SLAMWRK_FILE $SLAMDIR/html/nov_slam2.html > $SLAMWWW_DIR/nov_slam.html");}

        unlink ("$SLAMWRK_FILE") or die "Can't delete $SLAMWRK_FILE" ;
}









#
# ----------------------------------------------------------------------------------------------------
#  Generate the body of SLAM FULL backup Page and DBA Page based on rc*.log files
# ----------------------------------------------------------------------------------------------------
sub generate_job_html_page{


# Save variables received as parameter (dba,int,aix,win)
        my ($page_type) = @_;
        if ($DEBUG >= 5) { print "\nGenerating Job HTML Page for $page_type \n" ; }; 

# Delete Work file used
        unlink ("$SLAMWRK_FILE") ;

# Create a file with the last line of all rc* file
   	if ($page_type eq "aix") {opendir (RC ,"$SLAMAIX_DIR/log") or die "Cannot opendir $SLAMAIX_DIR/log: $!";}
   	if ($page_type eq "win") {opendir (RC ,"$SLAMWIN_DIR/log") or die "Cannot opendir $SLAMWIN_DIR/log: $!";}
   	if ($page_type eq "dba") {opendir (RC ,"$SLAMDBA_DIR/log") or die "Cannot opendir $SLAMDBA_DIR/log: $!";}
   	if ($page_type eq "int") {opendir (RC ,"$SLAMINT_DIR/log") or die "Cannot opendir $SLAMINT_DIR/log: $!";}
   	if ($page_type eq "nov") {opendir (RC ,"$SLAMNOV_DIR/log") or die "Cannot opendir $SLAMNOV_DIR/log: $!";}
   	if ($page_type eq "ftp") {opendir (RC ,"$SLAMFTP_DIR/log") or die "Cannot opendir $SLAMFTP_DIR/log: $!";}
	while ( defined ( $file = readdir (RC) ))  {
	      next if $file =~ /^\.\.?$/;	# Skip dir. entry . and ..
	      next if ! $file =~ "^rc" ; 
	      next if $file =~ "profile" ; 
	      next if $file =~ ".sh_history" ; 
	      if ($page_type eq "aix") {system ("tail -1 $SLAMAIX_DIR/log/$file >> $SLAMWRK_FILE");}
	      if ($page_type eq "win") {system ("tail -1 $SLAMWIN_DIR/log/$file >> $SLAMWRK_FILE");}
	      if ($page_type eq "dba") {system ("tail -1 $SLAMDBA_DIR/log/$file >> $SLAMWRK_FILE");}
	      if ($page_type eq "int") {system ("tail -1 $SLAMINT_DIR/log/$file >> $SLAMWRK_FILE");}
	      if ($page_type eq "nov") {system ("tail -1 $SLAMNOV_DIR/log/$file >> $SLAMWRK_FILE");}
	      if ($page_type eq "ftp") {system ("tail -1 $SLAMFTP_DIR/log/$file >> $SLAMWRK_FILE");}
	}
	closedir (RC);


# Ascii Slam report format - For remote support (on slamsrver when you type slam)
   	if ($page_type eq "aix") {open (SLAMMON, ">$SLAMBACK") or die "Can't open $SLAMBACK : $!\n";}

# If no entries were genereated, make sure at least an empty file exist
	if ( ! -e $SLAMWRK_FILE ) { system ("$CMD_TOUCH $SLAMWRK_FILE");} 

# Sort File in Reverse Order of RC Result code then date and time
	print "system sort -r +5 +1 +2 < $SLAMWRK_FILE > $SLAMTMP_FILE;";
#	system ("sort -r +5 +1 +2 < $SLAMWRK_FILE > $SLAMTMP_FILE");  
	system ("sort -r  < $SLAMWRK_FILE > $SLAMTMP_FILE");  
	print "..." ;

# Delete Work files used
	unlink ("$SLAMWRK_FILE") or die "Can't delete $SLAMWRK_FILE" ;

# Open HTML Output File 
	open (SLAMWRK, ">$SLAMWRK_FILE") or die "Cannot open $SLAMWRK_FILE: $!\n";

# Process Last line of all RC Code
	if ( ! -e $SLAMTMP_FILE ) { system ("$CMD_TOUCH $SLAMTMP_FILE");} 
        open (SLAMTMP, "<$SLAMTMP_FILE") or die "Cannot open $SLAMTMP_FILE: $!\n";

        while ($backline = <SLAMTMP>) {
             chomp $backline ;                	# Remove cr/lf
             next if $backline =~ /^#/ ;  		# Don't Process Comment
             next if $backline =~ /^$/ ;  	 	# Don't Process Blank LIne
             $backline =~ tr/A-Z/a-z/;        	# Make line lowercase
             if ($DEBUG >= 6) { print "Backup Line Processing - $backline\n" ; }; 
             $backline =~ s/_/-/g;
             ($backhost, $backdate, $backstart, $backend, $backname, $backcode) = split ' ',$backline;
             next if $backcode =~ /^4/ ;  	 	# Don't DBA Error line

# Determine if backup belong to nt or aix and if prod or dev 
             $backos = "nt"  ; 	# Default to nt os
             for ($index = 0; $index < @host_array; $index++) {
                 ($hostname, $hosttype, $hostrtype, $nodenum, $alias, $ostype, $copytype, $ping) = split ' ',$host_array[$index];
                 if ( $hostname eq $backhost ) { $backos = $ostype ; last ; } 
             }
             if ($DEBUG >= 6) { print "Host $backhost - $backname is a $backos box and considered a $hosttype machine.\n" ;}
	

# Prepare line info to be displayed on the SLAM Backup Page 
             $backstart = substr ($backstart,0,5);
             $backend   = substr ($backend,0,5);
             $newdate   = sprintf "%02d/%02d/%04d", substr ($backdate,8,2), substr ($backdate,5,2), substr ($backdate,0,4);
             $ENode = $backhost ;
             $EDate = $newdate ;
             $ETime = $backstart ;

# Set module Name
             $EModule = "Backup" ;
             if ( $page_type eq "nov" ) { $EModule = "T.S.M." ; }
             #if ( $page_type eq "dba" ) { $EModule = "dba_driver" ; }
	     if ( $page_type eq "int" ) { $EModule = "JobBatch" ; }
	     if ( $page_type eq "ftp" ) { $EModule = "FTP" ; }

# Set Default Sub Module Name
             $ESub = $backname ;
# for ftp page sub-module = 1st name before .
             if ( $page_type eq "ftp") { 
                ($ESub,@sub_array) = split '\.',$backname;
		$FTP_DESC = "@sub_array"; 
	     }
		
# If completed with Success
             if ( $backcode == 0 ) { 
                $EType = "Success" ; 
                $BGCOLOR = "#C0C0C0" ;  # Set Grey Color
                if ( $page_type eq "ftp") { $BGCOLOR = "#FFFFFF" };  # Success ftp is white
                $EDesc = "Backup of $backname completed at $backend" ;
                if (( $page_type eq "dba") || ($page_type eq "int" )) { $EDesc = "Job $backname completed at $backend" ; }
                if ( $page_type eq "ftp")  { $EDesc = "FTP $FTP_DESC completed at $backend" ; }
                if ( $page_type eq "nov")  { $EDesc = "Backup completed at $backend" ; }
             } 
	   
# If Completed with error
             if ( $backcode == 1 or $backcode == 3 ) { 
                $EType = "Failed" ; 
                $BGCOLOR = "#FF0000" ; # set red color
                $EDesc = "Backup of $backname failed at $backend - Check dsmerror.log";
                if ( $page_type eq "nov") { 
                    $EDesc = "Backup failed at $backend" ;
                    if ( "$backend" == "99:99" ) { $EDesc="schedule missed - Check dsmerror.log and dsmsched.log" ; }
                 }
                if ( $page_type eq "dba") { $EDesc = "Job $backname failed at $backend" ; }
                if ( $page_type eq "ftp") { $EDesc = "FTP $FTP_DESC failed at $backend" ; }
                if ( $hosttype eq "prd" ) { $BGCOLOR = "#FF0000" };  # Background Color is Red
                if ( $hosttype eq "dev" ) { $BGCOLOR = "#FFFF00" };  # Background Color is Yellow
                if ( $page_type eq "ftp") { $BGCOLOR = "#FFA500" };  # Failed ftp is Orange
                if ( ( $ESub =~ "mksysb" ) || ( $ESub =~ "savevg" ) ){ $BGCOLOR = "#FFFF00" }; # Background Color is Yellow
             } 

# If job is running
             if ( $backcode == 2 ) { 
                $EType = "running" ; 
                $BGCOLOR = "#00FF00" ;  # Set green color
                $EDesc = "Backup of $backname is running";
                if (( $page_type eq "dba") || ($page_type eq "int" )) {$EDesc = "Job $backname is running" ;}
             } 
 
# No red for DBA
#             if (($page_type eq "dba") &&  ($BGCOLOR eq "#FF0000")) { $BGCOLOR = "#FFFF00" ; }

# For HTML Viewing
             printf (SLAMWRK "<tr>\n");
             printf (SLAMWRK "  <td align=\"center\" bgcolor=$BGCOLOR><font color=$FONTCOLOR>$EType</font></td>\n");
             printf (SLAMWRK "  <td align=\"center\" bgcolor=$BGCOLOR><font color=$FONTCOLOR>$ENode</font></td>\n");
             printf (SLAMWRK "  <td align=\"center\" bgcolor=$BGCOLOR><font color=$FONTCOLOR>$EDate</font></td>\n");
             printf (SLAMWRK "  <td align=\"center\" bgcolor=$BGCOLOR><font color=$FONTCOLOR>$ETime</font></td>\n");
             printf (SLAMWRK "  <td align=\"center\" bgcolor=$BGCOLOR><font color=$FONTCOLOR>$EModule</font></td>\n");
             printf (SLAMWRK "  <td align=\"center\" bgcolor=$BGCOLOR><font color=$FONTCOLOR>$ESub</font></td>\n");
             printf (SLAMWRK "  <td align=\"left\"   bgcolor=$BGCOLOR><font color=$FONTCOLOR>%s</font></td>\n",$EDesc);
             printf (SLAMWRK "</tr>\n");

# For ASCII Viewing from Home 
	     if ( $page_type eq "aix" ) {
	        printf (SLAMMON  "%-7s %-10s %-9s %-5s %-10s %-18s %s\n",$EType, $ENode, $EDate, $ETime, $EModule, $ESub, $EDesc);
	     }
        }


# Close all Input and Output Files
	close (SLAMTMP);
        close (SLAMWRK);
	if ( $page_type eq "aix" ) { close SLAMMON };

# Concatenate html Header + Middle + Bottom files
   	if ($page_type eq "win") { 
	   system ("cat $SLAMDIR/html/win_jobs1.html $SLAMWRK_FILE $SLAMDIR/html/win_jobs2.html > $SLAMWWW_DIR/win_jobs.html");}
   	if ($page_type eq "int") { 
	   system ("cat $SLAMDIR/html/int_jobs1.html $SLAMWRK_FILE $SLAMDIR/html/int_jobs2.html > $SLAMWWW_DIR/int_jobs.html");}
   	if ($page_type eq "aix") { 
	   system ("cat $SLAMDIR/html/aix_jobs1.html $SLAMWRK_FILE $SLAMDIR/html/aix_jobs2.html > $SLAMWWW_DIR/aix_jobs.html");}
   	if ($page_type eq "dba") { 
	   system ("cat $SLAMDIR/html/dba_jobs1.html $SLAMWRK_FILE $SLAMDIR/html/dba_jobs2.html > $SLAMWWW_DIR/dba_jobs.html");}
   	if ($page_type eq "nov") { 
	   system ("cat $SLAMDIR/html/nov_jobs1.html $SLAMWRK_FILE $SLAMDIR/html/nov_jobs2.html > $SLAMWWW_DIR/nov_jobs.html");}
   	if ($page_type eq "ftp") { 
	   system ("cat $SLAMDIR/html/ftp_jobs1.html $SLAMWRK_FILE $SLAMDIR/html/ftp_jobs2.html > $SLAMWWW_DIR/ftp_jobs.html");}

# Delete Work file used
        unlink ("$SLAMWRK_FILE") or die "Can't delete $SLAMWRK_FILE" ;
        unlink ("$SLAMTMP_FILE") or die "Can't delete $SLAMTMP_FILE" ;
}






# ----------------------------------------------------------------------------------------------------
# Check for Windows backup Error & include them in the node report file (.rpt) for the concerned host
# ----------------------------------------------------------------------------------------------------
sub add_jobs_error_in_rpt_file {


# Save variables received as parameter
        my ($page_type) = @_;
	if ($DEBUG >= 5) { print "\nChecking $page_type Backup For Errors\n" ; };

	if ($page_type eq "win") {while (glob("$SLAMWIN_DIR/log/rc.*.log")) {system ("tail -1 $_ >> $SLAMWRK_FILE");}}
	if ($page_type eq "int") {while (glob("$SLAMINT_DIR/log/rc.*.log")) {system ("tail -1 $_ >> $SLAMWRK_FILE");}}
	if ($page_type eq "aix") {while (glob("$SLAMAIX_DIR/log/rc.*.log")) {system ("tail -1 $_ >> $SLAMWRK_FILE");}}
#	if ($page_type eq "dba") {while (glob("$SLAMDBA_DIR/log/rc.*.log")) {system ("tail -1 $_ >> $SLAMWRK_FILE");}}
	#if ($page_type eq "dba") {while (glob("$SLAMDBA_DIR/log/rc.*db2*cold*.log")) {system ("tail -1 $_ >> $SLAMWRK_FILE");}}
	#if ($page_type eq "dba") {while (glob("$SLAMDBA_DIR/log/rc.*db2*hot*.log"))  {system ("tail -1 $_ >> $SLAMWRK_FILE");}}
	if ($page_type eq "dba") {while (glob("$SLAMDBA_DIR/log/rc.*db2*.log"))  {system ("tail -1 $_ >> $SLAMWRK_FILE");}}
	if ($page_type eq "nov") {while (glob("$SLAMNOV_DIR/log/rc.*.log")) {system ("tail -1 $_ >> $SLAMWRK_FILE");}}

# If file is empty nothing to report Exit SubRoutine
	if ( ! -e $SLAMWRK_FILE ) { return; }	# If nothing to report exit function

# Accept only Error code 1 2 or 3 in rc log file
        system ("grep -E \"1\$\|2\$\|3\$|1 \$\|2 \$\|3 \$|1  \$\|2  \$\|3  \$\" $SLAMWRK_FILE | sort > $SLAMTMP_FILE");
	unlink ("$SLAMWRK_FILE") ;

# If file is empty nothing to report Exit SubRoutine
	if ( ! -e $SLAMTMP_FILE ) { return; }	# If nothing to report exit function

    	open (SLAMBACK,"<$SLAMTMP_FILE") or die "Can't open $SLAMTMP_FILE: $!\n";
        while ($backline = <SLAMBACK>) {
              next if $backline =~ /^#/ ;  		# Don't Process Comment
              next if $backline =~ /^$/ ;  	 	# Don't Process Blank LIne
     	      chomp $backline ;                # Remove cr/lf
       	      $backline =~ s/_/-/g;            # Replace _ by -
              $backline =~ tr/A-Z/a-z/;        	# Make line lowercase
              ($backhost, $backdate, $backstart, $backend, $backname, $backcode) = split ' ',$backline;
              next if $backcode =~ /^4/ ;  	 	# Don't DBA Error line
              $backstart = substr ($backstart,0,5); 
              $backend   = substr ($backend,0,5); 
              $newdate   = sprintf "%02d/%02d/%04d", substr ($backdate,8,2), substr ($backdate,5,2), substr ($backdate,0,4);
              if ($DEBUG >= 7) { print "Processing line  - $backline \n" ; }; 

# Append Backup Failed or Running in proper host RPT File
              if ($page_type eq "win") {
	         open (SLAMRPT,">>$SLAMWIN_DIR/rpt/win.rpt") or die "Can't open $SLAMWIN_DIR/rpt/win.rpt: $!\n";}
              if ($page_type eq "int") {
	         open (SLAMRPT,">>$SLAMINT_DIR/rpt/int.rpt") or die "Can't open $SLAMINT_DIR/rpt/int.rpt: $!\n";}
              if ($page_type eq "dba") {
	         open (SLAMRPT,">>$SLAMDBA_DIR/rpt/dba.rpt") or die "Can't open $SLAMDBA_DIR/rpt/dba.rpt: $!\n";}
              if ($page_type eq "aix") {
	         open (SLAMRPT,">>$SLAMAIX_DIR/rpt/aix.rpt") or die "Can't open $SLAMAIX_DIR/rpt/aix.rpt: $!\n";}
              if ($page_type eq "nov") {
	         open (SLAMRPT,">>$SLAMNOV_DIR/rpt/nov.rpt") or die "Can't open $SLAMAIX_DIR/rpt/nov.rpt: $!\n";}


# Determine if backup belong to Prod or Dev
             $HOSTTYPE = "dev" ; 
	      for ($index = 0; $index < @host_array; $index++) {
                  ($hostname, $hosttype, $hostrtype, $nodenum, $alias, $ostype, $copytype, $ping) = split ' ',$host_array[$index];
                  if ( $hostname eq $backhost ) { $HOSTTYPE = $hosttype ;  last ; } 
              }
              if ($DEBUG >= 7) { print "Node $backhost was assigned a $HOSTTYPE machine\n" ; }; 


# If error were detected in backup or dba_driver		 
              if ( $backcode == 1 or $backcode == 3 ) {

                  if ($page_type eq "dba")  {
                     if ( $HOSTTYPE eq "prd" ) { 
                     	printf SLAMRPT "%s;%s;%s;%s;%s;%s;%s;\n","Error",$backhost,$newdate,$backstart,"BACKUP",$backname,"Backup of $backname failed at $backend";
                     }
                     if ( $HOSTTYPE eq "dev" ) { 
                     	printf SLAMRPT "%s;%s;%s;%s;%s;%s;%s;\n","Warning",$backhost,$newdate,$backstart,"BACKUP",$backname,"Backup of $backname failed at $backend";
                     }
#                      printf SLAMRPT "%s;%s;%s;%s;%s;%s;%s;\n","Warning",$backhost,$newdate,$backstart,"BACKUP",$backname,"Backup of $backname failed at $backend";
                  }

                  if ($page_type eq "win") {
                     if ( $HOSTTYPE eq "prd" ) { 
                     	printf SLAMRPT "%s;%s;%s;%s;%s;%s;%s;\n","Error",$backhost,$newdate,$backstart,"BACKUP",$backname,"Backup of $backname failed at $backend";
                     }
                     if ( $HOSTTYPE eq "dev" ) { 
                     	printf SLAMRPT "%s;%s;%s;%s;%s;%s;%s;\n","Warning",$backhost,$newdate,$backstart,"BACKUP",$backname,"Backup of $backname failed at $backend";
                     }
                  }

                  if ($page_type eq "nov") {
                     $BDESC="Backup of $backname failed at $backend";
                     if ( $backend eq "99:99" ) { $BDESC="Schedule missed - Check dsmsched.log & dsmerror.log" ; }
                     if ( $HOSTTYPE eq "prd" ) { 
                     	printf SLAMRPT "%s;%s;%s;%s;%s;%s;%s;\n","Error",$backhost,$newdate,$backstart,"BACKUP",$backname,$BDESC;
                     }
                     if ( $HOSTTYPE eq "dev" ) { 
                     	printf SLAMRPT "%s;%s;%s;%s;%s;%s;%s;\n","Warning",$backhost,$newdate,$backstart,"BACKUP",$backname,$BDESC;
                     }
                  }

                  if (($page_type eq "aix") && ($backname !~ "archive")) {
                     if ( $HOSTTYPE eq "prd" ) { 
                        if ( ( $backname =~ "mksysb" ) || ( $backname =~ "savevg" ) ){
                     	    printf SLAMRPT "%s;%s;%s;%s;%s;%s;%s;\n","Warning",$backhost,$newdate,$backstart,"BACKUP",$backname,"Backup of $backname failed at $backend";
                        }else{
                            printf SLAMRPT "%s;%s;%s;%s;%s;%s;%s;\n","Error",$backhost,$newdate,$backstart,"BACKUP",$backname,"Backup of $backname failed at $backend";
                        }
                     }
                     if ( $HOSTTYPE eq "dev" ) { 
                     	printf SLAMRPT "%s;%s;%s;%s;%s;%s;%s;\n","Warning",$backhost,$newdate,$backstart,"BACKUP",$backname,"Backup of $backname failed at $backend";
                     }
                  }

                  if ($page_type eq "int") {
                      printf SLAMRPT "%s;%s;%s;%s;%s;%s;%s;\n","Warning",$backhost,$newdate,$backstart,"BACKUP",$backname,"Backup of $backname failed at $backend";
                  }


                  if ($DEBUG >= 5) { print "Backup $backhost Failed $backname at $backend\n" ; }; 
              }else{
                  printf SLAMRPT "%s;%s;%s;%s;%s;%s;%s;\n","Running",$backhost,$newdate,$backstart,"BACKUP",$backname,"Backup of $backname is running";
                  if ($DEBUG >= 5) { print "Backup $backhost Running $backname\n" ; }; 
              }   
              close SLAMRPT;
	      

# If Archive Backup name put it in DBA Page also
              if (($page_type eq "aix") && ( $backcode == 1 or $backcode == 3 ) && ( ($backname =~ "archive") || ($backname =~ "hot") || ($backname =~ "cold")) ) {
                 open (SLAMRPT,">>$SLAMDBA_DIR/rpt/dba.rpt") or die "Can't open $SLAMDBA_DIR/rpt/dba.rpt: $!\n";
                 printf SLAMRPT "%s;%s;%s;%s;%s;%s;%s;\n","Error",$backhost,$newdate,$backstart,"BACKUP",$backname,"Backup of $backname failed at $backend";
                 if ($DEBUG >= 5) { print "Backup $backhost Failed $backname at $backend\n" ; }; 
                 close SLAMRPT;
	      }
	}
	close SLAMBACK;
        unlink ("$SLAMWRK_FILE") ;
    	unlink ("$SLAMTMP_FILE") ;
}






# ----------------------------------------------------------------------------------------------------
#         M A I N    P R O G R A M    S T A R T    H E R E 
# ----------------------------------------------------------------------------------------------------

# If lock file exist, then slam is already running, then exit !
        if ( -e "$SLAMLCK_FILE"  ) {
           die "Slam Already running - File $SLAMLCK_FILE exist\n";
        }else{
           @args = ("$CMD_TOUCH", "$SLAMLCK_FILE");
           system(@args) == 0   or die "system @args failed: $?";
        }
# Display Date and Time
        ($year,$month,$day,$hour,$min,$sec) = Today_and_Now();		  
	printf ("SLAM MASTER IS STARTING %02d/%02d/%04d %02d:%02d\n", $day,$month,$year,$hour,$min);

# Load Slam Host file
	Load_slam_host;

# Make Sure work files are delete before we begin
        unlink ("$SLAMWRK_FILE") ;
        unlink ("$SLAMTMP_FILE") ;

# Make sure dba and integration are empty before beginning
	if ( -e "$SLAMAIX_DIR/rpt/aix.rpt") {unlink "$SLAMAIX_DIR/rpt/aix.rpt";}	
	if ( -e "$SLAMWIN_DIR/rpt/win.rpt") {unlink "$SLAMWIN_DIR/rpt/win.rpt";}	
#	if ( -e "$SLAMWIN_DIR/rpt/ndmq1061_syst.rpt") {unlink "$SLAMWIN_DIR/rpt/ndmq1061_syst.rpt";}	
#	if ( -e "$SLAMWIN_DIR/rpt/ndmq1061_dev.rpt")  {unlink "$SLAMWIN_DIR/rpt/ndmq1061_dev.rpt";}	
	if ( -e "$SLAMDBA_DIR/rpt/dba.rpt") {unlink "$SLAMDBA_DIR/rpt/dba.rpt";}	
	if ( -e "$SLAMINT_DIR/rpt/int.rpt") {unlink "$SLAMINT_DIR/rpt/int.rpt";}	
	if ( -e "$SLAMNOV_DIR/rpt/nov.rpt") {unlink "$SLAMNOV_DIR/rpt/nov.rpt";}	
	if ( -e "$SLAMFTP_DIR/rpt/ftp.rpt") {unlink "$SLAMFTP_DIR/rpt/ftp.rpt";}	

# Ping Server defined in Slam hosts file
	PingHost;

# Append Backup Error in AIX and NT .rpt files
	add_jobs_error_in_rpt_file "aix";
	add_jobs_error_in_rpt_file "int";
	add_jobs_error_in_rpt_file "dba";
	add_jobs_error_in_rpt_file "win";
	add_jobs_error_in_rpt_file "nov";
	
	
# Generate SLAM html pages
	generate_slam_html_page "aix";
	generate_slam_html_page "win";
	generate_slam_html_page "int";
	generate_slam_html_page "dba";
	generate_slam_html_page "nov";

# Generate Jobs (Backup) Html File
	generate_job_html_page "aix";
	generate_job_html_page "win";
	generate_job_html_page "int";
	generate_job_html_page "dba";
	generate_job_html_page "nov";
	generate_job_html_page "ftp";

# Remove slam_master.lock file
        unlink "$SLAMLCK_FILE" ;
