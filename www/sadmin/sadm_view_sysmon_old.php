<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<?php
/*
* ==================================================================================================
*   Author      :  Jacques Duplessis
*   Title       :  sadm_view_sysmon.php
*   Version     :  1.5
*   Date        :  4 February 2017
*   Requires    :  secure.php.net, postgresql.org, getbootstrap.com, DataTables.net
*   Description :  This page allow to view the servers alerts information in various ways
*                  depending on parameters received.
*   
*   Copyright (C) 2016 Jacques Duplessis <duplessis.jacques@gmail.com>
*
*   The SADMIN Tool is free software; you can redistribute it and/or modify it under the terms
*   of the GNU General Public License as published by the Free Software Foundation; either
*   version 2 of the License, or (at your option) any later version.
*
*   SADMIN Tools are distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
*   without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
*   See the GNU General Public License for more details.
*
*   You should have received a copy of the GNU General Public License along with this program.
*   If not, see <http://www.gnu.org/licenses/>.
* ==================================================================================================
*/
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_init.php'); 
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_lib.php');
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_header.php');

#===================================================================================================
#                                       Local Variables
#===================================================================================================
#
$DEBUG = True;                                          # Activate (TRUE) or Deactivate (FALSE) Debug

$tmp_file1          = tempnam (SADM_TMP_DIR . "/", 'sysmon_tmp1_');
$tmp_file2          = tempnam (SADM_TMP_DIR . "/", 'sysmon_tmp2_');
$tmp_file3          = tempnam (SADM_TMP_DIR . "/", 'sysmon_tmp3_');

    

// ================================================================================================
//                                   Display Alert section Heading 
// ================================================================================================
function display_degug_info()
{
    if ($DEBUG)  { 
        echo "<br>Input temp1 file name is " . $tmp_file1 ; 
        echo "<br>Input temp2 file name is " . $tmp_file2 ; 
        echo "<br>Input temp3 file name is " . $tmp_file3 ;
    }

}






// =================================================================================================
// This function create one file ______ that merge the *.rpt in /sadmin/www/dat with the *.rch in 
//  /sadmin/dat that are runnign or finish with errors (doesn't have a "0" (success) in last column)
// File in then loaded into an array (sysmon_array).
// =================================================================================================
function load_sysmon_array ($TXT_TYPE)
{
    global $DEBUG, $tmp_file1, $tmp_file2, $tmp_file3 ;

    # Create a file that will contains the content of all rpt files.
    # Output file will look like below
    # Error;nomad;2017.02.09;21:30;SERVICE;PROCESS;Service syslogd not running !;sadm;sadm
    # Error;nomad;2017.02.09;21:30;linux;FILESYSTEM;Filesystem /rhel at 97% > 90%;sadm;sadm
    # Error;gumby;2017.02.09;21:30;linux;FILESYSTEM;Filesystem /usr at 90% > 90%;sadm;sadm
    # Error;nano;2017.02.08;17:00;SERVICE;PROCESS;Service syslogd not running !;sadm;sadm
    #   1    2       3        4      5       6             7                     8     9
    # ----------------------------------------------------------------------------------------------
    $CMD="find " . SADM_WWW_DAT_DIR . " -type f -name '*.rpt' -exec cat {} \; > $tmp_file1";
    if ($DEBUG) { echo "<br>Command executed is : " . $CMD ; }
    $a = exec ( $CMD , $FILE_LIST, $RCODE);
    if ($DEBUG) { echo "<br>Return code of command is : " . $RCODE ; }


    #-rw-rw-r-- 1 sadmin sadmin  456 Feb  9 00:06 debian7_sadm_rear_backup.rch
    # /sadmin/www/dat/debian7/rch$ cat debian7_sadm_rear_backup.rch
    #debian7 2017.01.26 00:06:11 .......... ........ ........ sadm_rear_backup 2
    #debian7 2017.01.26 00:06:11 2017.01.26 00:06:26 00:00:15 sadm_rear_backup 0
    #debian7 2017.02.09 00:06:02 .......... ........ ........ sadm_rear_backup 2
    #debian7 2017.02.09 00:06:02 2017.02.09 00:06:02 00:00:00 sadm_rear_backup 1
    #   1        2         3         4        5        6          7            8

    $CMD="find " . SADM_WWW_DAT_DIR . " -type f -name '*.rch' -exec tail -1 {} \; > $tmp_file2";
    if ($DEBUG) { echo "<br>Command executed is : " . $CMD ; }
    $a = exec ( $CMD , $FILE_LIST, $RCODE);
    if ($DEBUG) { echo "<br>Return code of command is : " . $RCODE ; }

    $CMD="awk 'match($8,/[1-2]/) { print }' $tmp_file2 > $tmp_file3" ;
    if ($DEBUG) { echo "<br>Command executed is : " . $CMD ; }
    $a = exec ( $CMD , $FILE_LIST, $RCODE);
    if ($DEBUG) { echo "<br>Return code of command is : " . $RCODE ; }


    # Load RCH Line into Array
    $lines = file($wtmp_file3);

    # CONVERT THESE KIND OF LINES 
    #debian7 2017.02.09 00:06:02 2017.02.09 00:06:02 00:00:00 sadm_rear_backup 1
    #   1        2         3         4        5        6          7            8
    # TO THIS TYPE OF LINE
    # Error;nano;2017.02.08;17:00;SERVICE;PROCESS;Service syslogd not running !;sadm;sadm; 
    #   1    2       3        4      5       6             7                     8     9
    $output_file = fopen("$tmp_file1","a") or die("can't open in append mode file " . $tmp_file1 );
       
    foreach ($lines as $line_num => $line) {
        if ($DEBUG) { echo "Line #<b>{$line_num}</b> : " . htmlspecialchars($line) . "<br />\n"; }
        list($whost,$sdate,$stime,$edate,$etime,$eelapse,$escript,$ecode) = explode(" ",htmlspecialchars($line));
        $rtype    = "";  $rhost       = "";  $rdate = ""; $rtime  = ""; 
        $rprocess = "";  $rsubprocess = "";  $rdesc = ""; $rqpage = ""; 
        $remail   = "";
        switch (trim($ecode)) {
            case 0:
                $rtype = "Success" ;
                break;
            case 1:
                $rtype = "Error" ;
                break;
            case 2:
                $rrtype = "Running" ;
                break;
            default:
                $rtype = "Unknown" ;
                break;
        }
        $rhost = trim($whost);
        $rdate = trim($wdate);
        $rtime = trim($wtime);
        $rprocess = "Linux"; 
        $rsubprocess = "Script";
        $rqpage = "sadm";
        $rmail = "sadm";
        $rdesc = "Script " . $escript;
        $LINE = "${service_status},${service_name},${server_name},${short_desc},${full_desc}\n";
        fwrite($output_file,$LINE);
    }
    fclose($output_file);


    # Load RCH Line into Array
    $lines = file($wtmp_file1);




        $wname  = trim($wname);
        $wstatus= trim($wstatus);
        echo "\n<tr>";

    #debian7 2017.02.09 00:06:02 2017.02.09 00:06:02 00:00:00 sadm_rear_backup 1
    #   1        2         3         4        5        6          7            8        
        echo "\n<td class='dt-center'>" . $wip     . "</td>";
        echo "\n<td class='dt-center'>" . $wstatus . "</td>";
        echo "\n<td class='dt-center'>" . $wname   . "</td>";
        if (($wstatus == "No")  and ($wname == "")) { $wtype = "free" ; } 
        if (($wstatus == "Yes") and ($wname != "")) { $wtype = "used" ; }
        if (($wstatus == "Yes") and ($wname == "")) { $wtype = "Actine, No Hostname" ; }
        if (($wstatus == "No")  and ($wname != "")) { $wtype = "Inactive, With Hostname" ; }
        echo "\n<td>" . $wtype   . "</td>";
        echo "\n</tr>";
    }

    # Open input file containing lines of RCH files that end with 1 (Error) or 2 (Running)
    $rch_fh  = fopen("$tmp_file3","r") or die ("can't open RCH reference file - " . $tmp_file3);

    # Loop through RCH lines 
    while(! feof($rch_fh)) {
        $rchline = trim(fgets($rch_fh));                                # Read rch filename line
        if ($DEBUG) { echo "<br>Processing line :<br>" . $rchline; }    # Show rch line in Debug
        if ($wfile != "") {                                             # If filename not blank
            $line_array = file($wfile);                                 # Reads entire file in array
            $last_index = count($line_array) - 1;                       # Get Index of Last line
            if ($last_index > 0) {                                      # If last Element Exist
                if ($line_array[$last_index] != "") {                   # If None Blank Last Line
                    list($cserver,$cdate1,$ctime1,$cdate2,$ctime2,$celapsed,$cname,$ccode) = explode(" ",$line_array[$last_index], 8);
                    $outline = $cserver .",". $cdate1 .",". $ctime1 .",". $cdate2 .",". $ctime2 .",". $celapsed .",". $cname .",". trim($ccode) .",". basename($wfile) ."\n";
                    if ($DEBUG) {                                       # In Debug Show Output Line
                        echo "<br>Output line is " . $outline ;         # Print Output Line
                    }
                    $count+=1;
                    # Key is "StartDate + StartTime + FileName"
                    $akey = $cdate1 ."_". $ctime1 ."_". basename($wfile);
                    if ($DEBUG) {  echo "<br>AKey is " . $akey ;  }      # Print Array Key
                    if (array_key_exists("$akey",$script_array)) {
                        $script_array[$akey] = $outline . "_" . $count ;
                    }else{
                        $script_array[$akey] = $outline ;
                    }
                }
            }
        }
    }
    fclose($input_fh);                                                  # Close Input Filename List
    krsort($script_array);                                              # Reverse Sort Array on Keys

    # Under Debug - Display The Array Used to build the SideBar
    if ($DEBUG) {foreach($script_array as $key=>$value) { echo "<br>Key is $key and value is $value";}}
    return $script_array;
}

    # Open file containing the name of all txt files and create output file
    # ----------------------------------------------------------------------------------------------
    $input_file  = fopen("$tmp_in","r") or die("can't open input txt file - " . $tmp_in);
    $output_file = fopen("$tmp_out","a") or die("can't create output txt file" . $tmp_out );
    
    

    # Loop through filename list in the file
    # ----------------------------------------------------------------------------------------------
    while(! feof($input_file)) {
        $wfile = trim(fgets($input_file));
        if ( filesize($wfile) !=0 )  {
            if ($DEBUG) { echo "<br><br>File size of $wfile is ".  filesize($wfile) . " bytes."; }
            $txt_fh = fopen($wfile, "r") or exit ("Unable to open txt file: " . $wfile);
            while(!feof($txt_fh)) {
                $winput = trim(fgets($txt_fh));
                if (strlen($winput) > 1) {
                    if ($DEBUG) { echo "<br>Processing line : " . $winput  ; }
                    $wline = explode(' = ', "$winput ",9);
                    if ($DEBUG) { echo "<br>Number of element on line is " . sizeof($wline); }
                    $left_side      = explode ("_", @$wline[0],3);
                    $server_name    = @$left_side[0];
                    $service_name   = trim(@$left_side[1]);
                    $short_desc     = @$left_side[2];
                    $right_side     = explode ("[", @$wline[1]) ;
                    $service_status = trim(@$right_side[0]);
                    $full_desc      = trim(@$right_side[1]);
                    $full_desc      = trim($full_desc,"]");
                    if ($DEBUG) {
                        echo "<br>Server name    : $server_name"; 
                        echo "<br>Service name   : $service_name"; 
                        echo "<br>Short Desc.    : $short_desc"; 
                        echo "<br>Service Status : $service_status"; 
                        echo "<br>Full Desc.     : $full_desc";
                    }
                    $DATALINE = "${service_status},${service_name},${server_name},${short_desc},${full_desc}\n";
                    fwrite($output_file,$DATALINE);
                }
                
            }
            fclose   ($txt_fh);
        }
    }
    fclose($input_file);
    fclose($output_file);

}



// ================================================================================================
//                                   Display Alert section Heading 
// ================================================================================================
function display_txt_heading($TXT_STATUS,$WENV)
{
    if (!$TXT_STATUS) {
        echo "<br><b><font color='red'>";
        echo "Function display_txt_heading : Did not receive any parameter ?";
        echo "</b></font>";
        exit;
    }

    # Double Space Between Section - BUt not for first section (Critical)
    if ($TXT_STATUS != 'critical') { echo "<br><br>"; }
    
    # Display Section Heading and Prefix Section with Environment
    switch ($TXT_STATUS) {
        case 'critical' :   echo "<H1>" . $WENV . " Critical Alert</H1><br>" ;
                            $HCOLOR = "Red";
                            break;
        case 'warning' :    echo "<H1>" . $WENV . " Warning Alert</H1><br>" ;
                            $HCOLOR = "Yellow";
                            break;
        case 'running' :    echo "<H1>" . $WENV . " Running Processes</H1><br>" ;
                            $HCOLOR = "Lime";
                            break;
        case 'mail'    :    echo "<H1>" . $WENV . " Mail Sent</H1><br>" ;
                            $HCOLOR = "SkyBlue";
                            break;
        case 'page'    :    echo "<H1>" . $WENV . " Qpage Sent</H1><br>" ;
                            $HCOLOR = "Lavender";
                            break;
    }

    # Display Section Heading in the proper color
    echo "<table  align=center border=0 cellspacing=0>\n";
    echo "<tr>\n" ;
    echo "<td width=20  align='center' bgcolor=$HCOLOR><b>No</b></td>";
    echo "<td width=60  align='center' bgcolor=$HCOLOR><b>Status</b></td>";
    echo "<td width=40  align='center' bgcolor=$HCOLOR><b>Dept.</b></td>";
    echo "<td width=80  align='center' bgcolor=$HCOLOR><b>Server</b></td>";
    echo "<td width=50  align='center' bgcolor=$HCOLOR><b>Type</b></td>";
    echo "<td width=250 align='center' bgcolor=$HCOLOR><b>Server Description</b></td>";
    echo "<td width=480 align='center' bgcolor=$HCOLOR><b>Alert Description</b></td>";
    echo "</tr>";
}


    
    
// ================================================================================================
//                                  Display the sorted data file
// ================================================================================================
function display_data_file ($TXT_STATUS,$WENV){
    
    global $DEBUG, $tmp_in, $tmp_out, $tmp_sorted ;
        
    if (!$TXT_STATUS) {
        echo "<br><b><font color='red'>";
        echo "Function display_data_file : Did not receive any parameter ?";
        echo "</b></font>";
        exit;
    }
    
    $HEADING_DONE = 0 ;             
    $wcount = 0 ;

    # Sort tmp_output to tmp_sorted by Severity
    # ----------------------------------------------------------------------------------------------
    $CMD="sort $tmp_out > $tmp_sorted";
    if ($DEBUG) { echo "<br>Command executed is : " . $CMD ; }
    $a = exec ( $CMD , $FILE_LIST, $RCODE);
    if ($DEBUG) { echo "<br>Return code of command is : " . $RCODE ; }

    # Open file containing the name of all txt files and create output file
    # ----------------------------------------------------------------------------------------------
    $sorted_file  = fopen("$tmp_sorted","r") or die("can't open input sorted file - " . $tmp_sorted);

    # Loop through filename list in the file
    # ----------------------------------------------------------------------------------------------
    while(! feof($sorted_file)) {
        $wline = trim(fgets($sorted_file));
        if (strlen($wline) > 1) {
            if ($DEBUG) { echo "<br>Processing line : " . $wline  ; }
            $walarm = explode(',',$wline);
            if ($DEBUG) { echo "<br>Number of element on line is " . sizeof($wline) . "<br>" ; }
            $alarm_status     = @$walarm[0];
            $alarm_service    = @$walarm[1];
            $alarm_server     = @$walarm[2];
            $alarm_short_desc = @$walarm[3];
            $alarm_full_desc  = @$walarm[4];
            $row = mysql_fetch_array ( mysql_query("SELECT * FROM `servers` WHERE `server_name` = '$alarm_server' "));
            if (!$row) {
                $wdesc = "Unknown - Not in Sysinfo Database";
                $wtype = "Prod";
            }else{
                $wdesc   = $row['server_desc'];
                $wtype   = $row['server_type'];
            }
            if ($DEBUG) { echo "<br>TXT_STATUS = " . $TXT_STATUS . " Alarm_status = " . $alarm_status; }
            
            if (($TXT_STATUS == $alarm_status) && ( ($WENV == $wtype) || ($WENV == ""))) {
                if ($HEADING_DONE == 0) {
                    display_txt_heading($TXT_STATUS,$WENV);
                    $HEADING_DONE = 1 ;
                }
                echo "<tr>";
                $wcount += 1;
                if ($wcount % 2 == 0) $BGCOLOR="#FFFF99" ; else $BGCOLOR="#FFFFCC" ;
                echo "<td align='center' bgcolor=$BGCOLOR>" . $wcount     . "</td>\n";        
                echo "<td align='center' bgcolor=$BGCOLOR>" . $alarm_status     . "</td>\n";        
                echo "<td align='center' bgcolor=$BGCOLOR>" . $alarm_service    . "</td>\n";        
                echo "<td align='center' bgcolor=$BGCOLOR>" . $alarm_server     . "</td>\n";        
                echo "<td align='center' bgcolor=$BGCOLOR>" . $wtype     . "</td>\n";        
                echo "<td align='left'   bgcolor=$BGCOLOR>" . $wdesc     . "</td>\n";        
                #echo "<td align='center' bgcolor=$BGCOLOR>" . $alarm_short_desc . "</td>\n";        
                echo "<td align='left' bgcolor=$BGCOLOR>" . $alarm_full_desc  . "</td>\n";        
                echo "</tr>";
            }
        }
    }
    fclose($sorted_file);
    echo "</table></center>";
}


function print_subnet($wfile,$woption,$wsubnet) {

    # SUBNET DIV START
    echo "\n\n<div class='subnet_container'>                 <!-- Start Subnet Container DIV -->\n";
    
    # Print Heading and Start Body Section
    print_ip_heading ("$woption",$wsubnet);
    echo "\n<tbody>"; 
    
    # Load the IP File into $lines Array.
    $lines = file($wfile);

    // Loop through our array, show HTML source as HTML source; and line numbers too.
    foreach ($lines as $line_num => $line) {
        #echo "Line #<b>{$line_num}</b> : " . htmlspecialchars($line) . "<br />\n";
        list($wip, $wstatus, $wname) = explode(",", htmlspecialchars($line));
        $wname  = trim($wname);
        $wstatus= trim($wstatus);
        echo "\n<tr>";
        echo "\n<td class='dt-center'>" . $wip     . "</td>";
        echo "\n<td class='dt-center'>" . $wstatus . "</td>";
        echo "\n<td class='dt-center'>" . $wname   . "</td>";
        if (($wstatus == "No")  and ($wname == "")) { $wtype = "free" ; } 
        if (($wstatus == "Yes") and ($wname != "")) { $wtype = "used" ; }
        if (($wstatus == "Yes") and ($wname == "")) { $wtype = "Actine, No Hostname" ; }
        if (($wstatus == "No")  and ($wname != "")) { $wtype = "Inactive, With Hostname" ; }
        echo "\n<td>" . $wtype   . "</td>";
        echo "\n</tr>";
    }
    echo "\n</tbody>\n</table></center><br>";
   
    # SUBNET DIV END
    echo "\n\n</div'>                                        <!-- End Subnet Container DIV -->\n";
    echo "\n<BR>                                             <!-- Blank Line -->\n";
}




#===================================================================================================
#                              Display SADMIN Main Page Header
#===================================================================================================
function display_heading($line_title) {

    sadm_page_heading ("$line_title");                                  # Display Page Title

    echo "<center>\n";                                                  # Table Centered on Page
  
    # Set Font Size for Table Cell and Table Heading
    echo "<style>\n";
    echo "td { font-size: 12px; }\n";
    echo "th { font-size: 13px; }\n";
    echo "</style>\n";
    #echo '<table id="sadmTable" class="display compact nowrap" border="0" cellpadding="0" cellspacing="0" width="100%">';
    echo '<table id="sadmTable" class="display compact nowrap" width="100%">';

    # Server Table Heading
    echo "<thead>\n";
    echo "<tr>\n";
    #echo "<th>No.</th>\n";
    echo "<th>Server</th>\n";
    echo "<th>Description</th>\n";
    #echo "<th>Model</th>\n";
    echo "<th>Active</th>\n";
    #echo "<th>Sporadic</th>\n";
    echo "<th>O/S</th>\n";
    echo "<th>Version</th>\n";
    echo "<th>Memory</th>\n";
    echo "<th>Cpu Speed</th>\n";
    echo "<th>Disk Space</th>\n";
    echo "<th>Config.</th>\n";
    echo "</tr>\n"; 
    echo "</thead>\n";

    # Server Table Footer
    echo "<tfoot>\n";
    echo "<tr>\n";
    #echo "<th>No.</th>\n";
    echo "<th>Server</th>\n";
    echo "<th>Description</th>\n";
    #echo "<th>Model</th>\n";
    echo "<th>Active</th>\n";
    #echo "<th>Sporadic</th>\n";
    echo "<th>O/S</th>\n";
    echo "<th>Version</th>\n";
    echo "<th>Memory</th>\n";
    echo "<th>Cpu Speed</th>\n";
    echo "<th>Disk Space</th>\n";
    echo "<th>Config.</th>\n";
    echo "</tr>\n"; 
    echo "</tfoot>\n";

    # Start of Table Body
    echo "<tbody>\n";
}




#===================================================================================================
#                     Display Main Page Data from the row received in parameter
#===================================================================================================
function display_data($count, $row) {

    echo "<tr>\n";  
    #echo "<td>" . $count . "</td>\n";  
    echo "<td>" .
        "<a href=/sadmin/sadm_view_server_info.php?host=" . nl2br($row['srv_name']) .
        ">" . nl2br($row['srv_name']) . "</a></td>\n";
    echo "<td>" . nl2br( $row['srv_desc'])  . "</td>\n";
    #echo "<td>" . nl2br( $row['srv_model']) . "</td>\n";
    if ($row['srv_active']   == 't' ) { echo "<td>Yes</td>\n"; }else{ echo "<td>No</td>\n";}
    #if ($row['srv_sporadic'] == 't' ) { echo "<td>Yes</td>\n"; }else{ echo "<td>No</td>\n";}

    echo "<td>" . nl2br( ucwords($row['srv_osname']))      . "</td>\n";  
    echo "<td>" . nl2br( $row['srv_osversion'])   . "</td>\n";  
    echo "<td>" . nl2br( $row['srv_memory'])      . " MB</td>\n";  
    echo "<td>" . nl2br( $row['srv_nb_cpu']) . " X " . nl2br( $row['srv_cpu_speed']) . " MHz</td>\n";
    
    # Display Disk Space and Number of Disk(s)
    $DiskArray = explode(",", $row['srv_disks_info']);
    $DiskNumber = sizeof($DiskArray);
    $TotalSpace  = 0 ;
    for ($i = 0; $i < count($DiskArray); ++$i) {
        list($DiskName,$DiskSize) = explode("|", $DiskArray[$i] );
        $TotalSpace = $TotalSpace + $DiskSize ;
    }
    $TotalGBSpace = floor(($TotalSpace / 1024));
    echo "<td><a href='/dat/" . $row['srv_name'] . "/dr/" . $row['srv_name'] . "_pvs.txt' " ;
    echo " data-toggle='tooltip' title='View " . $row['srv_name'] ;
    echo " Disks Details'>" . $TotalGBSpace . " GB (" . $DiskNumber . " Disks)</a></td>\n";
    
    
    echo "<td class='dt-center'>" ;
    echo "<a href='/dat/" . $row['srv_name'] . "/dr/" . $row['srv_name'] . ".html' " ;
    echo " data-toggle='tooltip' title='View " . ucwords($row['srv_name']) . " Configuration'>Config</a>\n";
    echo "</td>\n";
    echo "</tr>\n"; 
}
    





/*
* ==================================================================================================
*                                      PROGRAM START HERE
* ==================================================================================================
*/


# The "selection" (1st) parameter contains type of query that need to be done (all_servers,os,...)   
    if (isset($_GET['selection']) && !empty($_GET['selection'])) { 
        $SELECTION = $_GET['selection'];                                # If Rcv. Save in selection
    }else{
        $SELECTION = 'all_servers';                                     # No Param.= "all_servers"
    }
    if ($DEBUG) { echo "<br>1st Parameter Received is " . $SELECTION; } # Under Debug Display Param.

    
# The 2nd Paramaters is sometime used to specify the type of server received as 1st parameter.
# Example: http://sadmin/sadmin/sadm_view_servers.php?selection=os&value=centos
    if (isset($_GET['value']) && !empty($_GET['value'])) {              # If Second Value Specified
        $VALUE = $_GET['value'];                                        # Save 2nd Parameter Value
        if ($DEBUG) { echo "<br>2nd Parameter Received is " . $VALUE; } # Under Debug Show 2nd Parm.
    }

# Validate the view option received, Set Page Heading and Retreive Selected Data from Database
    switch ($SELECTION) {
        case 'all_servers'  : $query = 'SELECT * FROM sadm.server order by srv_name;';
                              $result = pg_query($query) or die('Query failed: ' . pg_last_error());
                              $TITLE = "Alerts for all servers";
                              break;
        case 'host'         : $query = "SELECT * FROM sadm.server where srv_name = '". $VALUE . "';";
                              $result = pg_query($query) or die('Query failed: ' . pg_last_error());
                              $TITLE = "Alerts for " . ucwords($VALUE) . " Server";
                              break;
        case 'os'           : $query = "SELECT * FROM sadm.server where srv_osname = '". $VALUE . "' order by srv_name;";
                              $result = pg_query($query) or die('Query failed: ' . pg_last_error());
                              $TITLE = "List of " . ucwords($VALUE) . " Servers";
                              break;
        default             : echo "<br>The sort order received (" . $SELECTION . ") is invalid<br>";
                              echo "<br><a href='javascript:history.go(-1)'>Go back to adjust request</a>";
                              exit ;
    }
    

# Display Page Heading
    display_heading("$TITLE");                                          # Display Page Heading
    
# Loop Through Retreived Data and Display each Row
    $count=0;                                                           # Reset Line Counter
    while ($row = pg_fetch_array($result, null, PGSQL_ASSOC)) {
        $count+=1;                                                      # Incr Line Counter
        display_data($count, $row);                                     # Display Next Server
    }
    echo "</tbody></table></center><br><br>\n";                         # End of tbody,table
    
    


// =================================================================================================
//                               M A I N    P R O G R A M 
// =================================================================================================
    display_degug_info;
    
    
    
    
    
    #set_error_handler("customError");               # Set error handler
    
    # Read each txt directory and collect errors in then same output file
    process_txt_files ("mvs");                          # Check all txt in mvs dir. for Errors.
    process_txt_files ("os");                           # Check all txt in os  dir. for Errors.
    process_txt_files ("pa");                           # Check all txt in pa  dir. for Errors.
    process_txt_files ("dba");                          # Check all txt in dba dir. for Errors.
    process_txt_files ("was");                          # Check all txt in was dir. for Errors.
    process_txt_files ("app");                          # Check all txt in app dir. for Errors.
    process_txt_files ("ftp");                          # Check all txt in ftp dir. for Errors.
    
    
    # Read the output file created earlier and display error that match parameter
    display_data_file("critical",$WENV);                    
    display_data_file("warning",$WENV);
    display_data_file("running",$WENV);
    display_data_file("mail",$WENV);
    display_data_file("page",$WENV);
    echo "<center><br><br>";
    echo "<b>This page will refresh automatically every minute - " . date('l jS \of F Y h:i:s A');
    echo "</br></center>";
    
    # Delete Work Files
    unlink($tmp_in);
    unlink($tmp_out);
    unlink($tmp_sorted);
       
    
    
    include ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_footer.php')  ;       # SADM Std EndOfPage Footer
?>
