<?php
/*
* ================================================================================================
*   Author   :  Jacques Duplessis
*   Title    :  sadm_view_rch_summary.php
*   Version  :  1.5
*   Date     :  22 March 2016
*   Requires :  php
*   Synopsis :  Present a summary of all rch files received from all servers.
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
* ================================================================================================
*/
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_constants.php'); 
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_connect.php');
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_lib.php');
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_header.php');

/*
* ==================================================================================================
*                                       Local Variables 
* ==================================================================================================
*/
$DEBUG = False ;							    						# TRUE or FALSE
$wcount = 0 ;															# Work Line Counter
$tmprchout     = tempnam ('tmp/', 'rch_out-');							# Create TMP Unique Filename
if ($DEBUG)  { echo "<br>Output temp file name is " . $tmprchout ; }	# Containing last line of RCH
$tmp_sorted  = tempnam ('tmp/', 'rch_sorted-');							# Create RCH Lines TMP Name 
if ($DEBUG)  { echo "<br>Sorted temp file name is " . $tmp_sorted ; }	# Show Tmp Filename 
	


// ================================================================================================
//                                  Error Handler Function 
// ================================================================================================
function customError($errno, $errstr)
{
	echo "<br><b>Error:</b> [$errno] $errstr<br>";
}



// ================================================================================================
//                            		Display RCH Status Heading 
// ================================================================================================
function display_rch_status_heading($HSORT)
{
	switch ($HSORT) {
		case 'server':    $HDESC="Server.";
						  break;
		case 'date'  :    $HDESC="Date and Time."; 
						  break;
		case 'elapse':    $HDESC="Elapsed Time."; 
						  break;
		case 'jobname':   $HDESC="Job Name."; 
						  break;
		case 'status':    $HDESC="Status."; 
						  break;
		default      :    echo "<br>Heading sort order (" . $SORT_ORDER . ") is invalid<br>";
						  echo "<a href='javascript:history.go(-1)'>Go back to adjust request</a>";
	}
    sadm_page_heading ("Result Code History File results ordered by $HDESC");
        
   	$HDR_BGCOLOR="#5EA2A5";
	$FNT_COLOR="#FFFFFF";
	$ATTR_BEFORE="bgcolor=$HDR_BGCOLOR>";
	$ATTR_AFTER="";
	#$ATTR_BEFORE="bgcolor=$HDR_BGCOLOR><font color=$FNT_COLOR><strong>";
	#$ATTR_AFTER="</font></strong>";

	echo "<center>\n";
	echo "<table border=1 cellspacing=0>\n";	
	echo "<tr>\n" ;
	echo "<td>No</td>\n";
	echo "<td>Server</td>\n";
	echo "<td>O/S Name</td>\n";
	echo "<td>Type</td>\n";
	echo "<td>Script Name</td>\n";
	echo "<td>Start Date</td>\n";
	echo "<td>Start Time</td>\n";
	echo "<td>End Time</td>\n";
	echo "<td>Elapse</td>\n";
	echo "<td>Status</td>\n";
	echo "</tr>\n";
}


	
	
// ================================================================================================
//                              Display the Processed data file
// ================================================================================================
function display_data_file($WSORT){
	global $DEBUG, $tmprchout, $tmp_sorted ;

	# Sort tmp_output to tmp_sorted by Severity
	# ----------------------------------------------------------------------------------------------
	switch ($WSORT) {
		# Sort by Server
		case 'server':  $CMD="sort -t, -k1,1 			$tmprchout > $tmp_sorted";		
						break;
		# Sort by Start/End Date
		case 'date'  :  $CMD="sort -t, -k2,3 -k4,5 -r 	$tmprchout > $tmp_sorted"; 
						break;
		# Sort by Elapse Time
		case 'elapse':  $CMD="sort -t, -k6,6 -r  		$tmprchout > $tmp_sorted";	
						break;
		# Sort by JobName & End Date/Time
		case 'jobname': $CMD="sort -t, -k7,7 -k4,5   	$tmprchout > $tmp_sorted";
						break;
		# Sort by Job Status (Failed/Running/Success) & End Date/Time
		case 'status':  $CMD="sort -t, -k8,8 -k4,5 -r 	$tmprchout > $tmp_sorted";
						break;
		default      :  echo "<br>The sort order received (" . $SORT_ORDER . ") is invalid<br>";
						echo "<a href='javascript:history.go(-1)'>Go back to adjust request</a>";
						exit ;
	}
  
	# Execute The Sort of work file
	if ($DEBUG) { echo "<br>Command executed is : " . $CMD ; }
	$a = exec ( $CMD , $FILE_LIST, $RCODE);
	if ($DEBUG) { echo "<br>Return code of command is : " . $RCODE ; }


	# Open Sorted file containing the last line of all 'rch' file
	$sorted_file  = fopen("$tmp_sorted","r") or die("Can't open sorted file - " . $tmp_sorted);
	
	
	$HEADING_DONE = 0 ; $wcount = 0 ;									# Reset Flag & Counter 
	display_rch_status_heading($WSORT);									# Display RCH Status Heading
    while(! feof($sorted_file)) {
        $wline = trim(fgets($sorted_file));
		if  (strlen($wline) > 30) {
			list($cserver,$cdate1,$ctime1,$cdate2,$ctime2,$celapsed,$cname,$ccode,$cfile) = explode(",", $wline);
			if (strlen($cname) > 0) {
				$wcount += 1;
				if ($wcount % 2 == 0) $BGCOLOR="#E4F0EC" ; else $BGCOLOR="#F0DFD5" ;

				# Get Server Description / OSName and Type for Database
                $query = "SELECT * FROM sadm.server where srv_name = '$cserver' ;";
                $result = pg_query($query) or die('Query failed: ' . pg_last_error());
                $row = pg_fetch_array($result, null, PGSQL_ASSOC);
				if ($row) {
					$wdesc   = $row['srv_desc'];
					$wtype   =  nl2br( $row['srv_type']);
                    $wos     = $row['srv_osname'];
				}else{
					$wdesc   = "Unknown";
					$wtype   = "Unkn"; 
                    $wos     = "Unkn";
				}

			echo "<tr>\n";
			echo "<td bgcolor=$BGCOLOR>"  . $wcount . "</td>\n";        
        	echo "<td bgcolor=$BGCOLOR>" ;
			echo "<a href=/sadmin/sadm_view_server.php?host=" . $cserver . ">" . $cserver . "</a></td>\n";
			#echo "<td align='center' bgcolor=$BGCOLOR>"  . $wdesc  . "</td>\n";
			echo "<td align='center' bgcolor=$BGCOLOR>"  . $wos    . "</td>\n";
			echo "<td align='center' bgcolor=$BGCOLOR>"  . $wtype  . "</td>\n";
			echo "<td bgcolor=$BGCOLOR>"  . $cname . " - \n";
			list($fname,$fext) = explode ('.',$cfile);
			$LOGFILE = $fname . ".log";
			echo "<a href=/sadmin/sadm_view_rchfile.php?host=" . $cserver . "&filename=" .
				$cfile   . ">(rch)</a>\n";
			echo "<a href=/sadmin/sadm_view_logfile.php?host=" . $cserver . "&filename=" .
				$LOGFILE . ">(log)</a></td>\n";
			echo "<td align='center' bgcolor=$BGCOLOR>" . $cdate1  . "\n";
			echo "<td align='center' bgcolor=$BGCOLOR>" . $ctime1  . "</td>\n";
			if ($ccode == 2) {
				#echo "<td align='center' bgcolor=$BGCOLOR>  ........</td>\n";
				echo "<td align='center' bgcolor=$BGCOLOR>  ........</td>\n";
				echo "<td align='center' bgcolor=$BGCOLOR>  ........</td>\n";
			}else{
    			#echo "<td align='center' bgcolor=$BGCOLOR>" . $cdate2   . "</td>\n";
    			echo "<td align='center' bgcolor=$BGCOLOR>" . $ctime2   . "</td>\n";
    			echo "<td align='center' bgcolor=$BGCOLOR>" . $celapsed . "</td>\n";
			}
			switch ($ccode) {
				case 0:     echo "<td align='center' bgcolor=$BGCOLOR>Success</td>\n";
							break;
				case 1:     echo "<td align='center' bgcolor='orangered'>Failed</td>\n";
							break;
				case 2:     echo "<td align='center' bgcolor='greenyellow'>Running</td>\n";
							break;
				default:    echo "<td align='center' bgcolor=$BGCOLOR>Code " . $ccode . "</td>\n";
							break;;
			}                    
			echo "</tr>\n";
			}
		}
	}        
			
	fclose($sorted_file);
	echo "</table></center><br><br>\n";
}






# ==================================================================================================
#                        Display the RCH files of the selected type 
# ==================================================================================================
function process_rch_files ()
{
	global $DEBUG, $tmprchout ;

	# Form the base directory name where all the servers 'rch' files are located
	$RCH_ROOT = $_SERVER['DOCUMENT_ROOT'] . "/dat/";
	if ($DEBUG) { echo "<br>Opening $RCH_ROOT directory "; }
	
	# Make sure that the rpt directory is a directory, if not close tmp and exit function
	if (! is_dir($RCH_ROOT)) {
		echo "<br>$RCH_ROOT is not a directory - But it should";
		echo "<br><a href='javascript:history.go(-1)'>Back to previous page</a>";
		exit;
	}
 
	# Create unique filename that will contains all servers *.rch filename
	$tmprch = tempnam ('tmp/', 'ref_rch_file-');						# Create unique file name
	if ($DEBUG) { echo "<br>Temp file of rch filename : " . $tmprch;}	# Show unique filename 
	$CMD="find $RCH_ROOT -name '*.rch'  > $tmprch";						# Construct find command
	if ($DEBUG) { echo "<br>Command executed is : " . $CMD ; }			# Show command constructed
	$a = exec ( $CMD , $FILE_LIST, $RCODE);								# Execute find command 
	if ($DEBUG) { echo "<br>Return code of command is : " . $RCODE ; }	# Display Return Code 

	# Open input file containing the name of all rch filename
	$input_fh  = fopen("$tmprch","r") or die ("can't open ref-rch file - " . $tmprch);

	# Create output file that will contain the last line of all rch files
	$output_fh = fopen("$tmprchout","w") or die ("can't create output txt file" . $tmprchout );
	if ($DEBUG) { echo "<br>Output Filename : " . $tmprchout;}			# Show unique filename
	
	# Loop through filename list in the file
	while(! feof($input_fh)) {
		$wfile = trim(fgets($input_fh));								# Read rch filename line
		if ($DEBUG) { echo "<br><br>Processing file " . $wfile; }		# Show rch filename in Debug
		if ($wfile != "") {												# If filename not blank
			$line_array = file($wfile);									# Reads entire file in array
			$last_index = count($line_array) - 1;						# Get Index of Last line
			if ($DEBUG) {												# In Debug Mode
				echo "<br>Number of line in rch file is " . count($line_array);		# Show Nb Line
				echo "<br>File size of $wfile is ".  filesize($wfile) . " bytes.";	# Show File Size
			}
			if ($last_index > 0) {										# If last Element Exist
				if ($line_array[$last_index] != "") {					# If None Blank Last Line
					list($cserver,$cdate1,$ctime1,$cdate2,$ctime2,$celapsed,$cname,$ccode) = explode(" ",$line_array[$last_index], 8);
					$outline = $cserver .",". $cdate1 .",". $ctime1 .",". $cdate2 .",". $ctime2 .",". $celapsed .",". $cname .",". trim($ccode) .",". basename($wfile) ."\n";
					if ($DEBUG) {										# In Debug Show Output Line
						echo "<br>Output line is " . $outline ;			# Print Output Line
					}
					fwrite($output_fh,$outline);  						# Write Line to Output File
			    }
		    }
	    }
	}
	fclose($input_fh);													# Close Input Filename List
	fclose($output_fh);													# Close Output RCH Summary
}




#===================================================================================================
#                                     PROGRAM START HERE
#===================================================================================================
#

	# If did not received any parameter, then default to sort by Start Date
	if (isset($_GET['sortorder']) ) { 									# If Param 'sortorder' recv.
		$SORT_ORDER = $_GET['sortorder'];								# Get Sort Order Received
	}else{																# If No Param received
		$SORT_ORDER = 'date';											# Default to Sort by Date
	}
	if ($DEBUG) { echo "<br>Sort order is " . $SORT_ORDER; }			# Under Debug Show SortOrder
	if ($DEBUG) { echo "<br>SADM_WWW_RCH_DIR = " . SADM_WWW_RCH_DIR; }	# Under Debug Show SortOrder


	# Validate the sort order received with the one supported - If not Stop - Back tp Prev page
	switch ($SORT_ORDER) {
		case 'server'  :  break;
		case 'date'    :  break;
		case 'elapse'  :  break;
		case 'status'  :  break;
		case 'jobname' :  break;
		default        :  echo "<br>The sort order received (" . $SORT_ORDER . ") is invalid";
						  echo "<br><a href='javascript:history.go(-1)'>Back to previous page</a>";
						  exit ;
	}

	# Produce one file with last line of all rch files
	process_rch_files();

	# Display the output in the sort order receive
	display_data_file($SORT_ORDER);             

include           ($_SERVER['DOCUMENT_ROOT'].'/lib/sadm_footer.php')  ;

?>
