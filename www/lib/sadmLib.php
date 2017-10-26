<?php
/*
* ================================================================================================
*   Author   :  Jacques Duplessis
*   Title    :  sadm_lib.php
*   Version  :  2.0
*   Date     :  22 March 2016
*   Requires :  php
*   Synopsis :  This file is the place to store all SADMIN functions
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



// ================================================================================================
//            Function to Calculate the OS Update Time Based on Parameter Received
// ================================================================================================
function calculate_osupdate_date($W1stMth,$WFreq,$Week1,$Week2,$Week3,$Week4,$WUpdDay) {
    
    $DEBUG = True ;                                   # Activate (TRUE) or Deactivate (FALSE) Debug

    if ($DEBUG) {
        echo "\nFirst Month is ";    
        echo "\nFrequency is ";    
        echo "\nWeek1 is ";    
        echo "\nWeek2 is ";    
        echo "\nWeek3 is ";    
        echo "\nWeek4 is ";    
        echo "\nUpdate Day is ";     
    }
    
    # !st Get Current Date Information
    $CurDay  = "";
    $CurMth  = "";
    $CurYear = ""; 
    if ($DEBUG) { echo "CurDay is ".$CurDay . " CurMth is ".$CurMth . " CurYear is ".$CurYear; }
    
    return $UPD_DATE;
}

// ================================================================================================
//            Popup Message received as parameter and wait for OK to be pressed
// ================================================================================================
function sadm_confirm($msg) {
    $message = $msg;
    $message = preg_replace("/\r?\n/", "\\n", addslashes($message));
    echo "\n<script type=\"text/javascript\">";
    echo "\nvar stay=confirm('Create this Category')";
    #document.getElementById("demo").innerHTML = x;
    echo "\n</script>\n";
    return $reponse;
}



// ================================================================================================
//      Popup with the Error Message wait for 5 seconds and return to previous page
// ================================================================================================
function sadm_fatal_error($msg) {
    $message = $msg;
    $message = preg_replace("/\r?\n/", "\\n", addslashes($message));
    echo "<script type=\"text/javascript\">\n";
    echo " alert(\"$message\");\n";
    echo " windows.history.back()\n";
    echo "</script>\n\n";
}



// ================================================================================================
//            Popup Message received as parameter and wait for OK to be pressed
// ================================================================================================
function sadm_alert($msg) {
    $message = $msg;
    $message = preg_replace("/\r?\n/", "\\n", addslashes($message));
    echo "<script type=\"text/javascript\">\n";
    echo " alert(\"$message\");\n";
    echo "</script>\n\n";
}


// ================================================================================================
//                       Transform date (DD/MM/YYY) into MYSQL format
// ================================================================================================
function DDMMYYYY_2_mysqldate( $input_date ) {
    $date_array = explode("/",$input_date);
    $mysql_date = $date_array[2] . '/' . $date_array[1] . '/' . $date_array[0] . " 00:00:00";
    return $mysql_date ;
}


// ================================================================================================
//           Transform MYSQL date (YYYY/MM/DD HH:MM:SS) format into user format (DD/MM/YYY)
// ================================================================================================
function mysql_date_2_DDMMYYYY( $mysql_date ) {
    $wyear  = substr($mysql_date, 0, 4);
    $wmonth = substr($mysql_date, 5, 2);
    $wday   = substr($mysql_date, 8, 2);
    $input_date = $wday . '/' . $wmonth . '/' . $wyear ;
    return $input_date ;
}



// ================================================================================================
//  Calculate elepsed time between two times value passed as arguments
//  Parameters are in this format HH:MM:SS in 24 hours format - Will return difference in HH:MM:
// ================================================================================================
function time_difference ( $wstart, $wend)
{
    #echo "<br>Start $wstart End $wend";
    list ($shour, $smin,   $ssec) = split(":", $wstart, 3);
    $wtime1 = ($shour*60*60)+ ($smin*60) + $ssec;

    list ($ehour, $emin,   $esec) = split(":", $wend, 3);
    $wtime2 = ($ehour*60*60)+ ($emin*60) + $esec;

    #echo "<br>Time 2 = $wtime2 Time 1 = $wtime1 Difference = " . ($wtime2 -$wtime1) . "<br>" ;
    $TOTAL_SEC = $wtime2 - $wtime1 ;

    #echo "<BR>Total Sec before is $TOTAL_SEC";
    if ($TOTAL_SEC < 0) { $TOTAL_SEC = ((24*60*60) - $wtime1) + $wtime2 ;}
    #echo "<BR>Total Sec after is $TOTAL_SEC";

    $fhrs = 0 ;
    if ($TOTAL_SEC > 3600) {
        $fhrs = intval($TOTAL_SEC/3600);
        $WORK = trim($TOTAL_SEC - ($fhrs*3600));
        $TOTAL_SEC = $WORK;
    }
    $HOURS = sprintf("%02d",number_format( $fhrs,0 ));
    $fmin = 0 ;
    if ($TOTAL_SEC > 60  ) {
        $fmin = intval($TOTAL_SEC/60) ;
        $WORK = trim($TOTAL_SEC - ($fmin*60)) ;
        $TOTAL_SEC = $WORK;
    }
    $MIN = sprintf("%02d",number_format($fmin,0));
    $fsec = $TOTAL_SEC ;
    $SEC = sprintf("%02d",number_format($fsec,0));
    $DUREE = $HOURS . ":" . $MIN . ":" . $SEC ;
    return ($DUREE);
}


// ================================================================================================
//                  Simple form to accept the server name and function to perform
// ================================================================================================
function accept_key($server_key) {
    echo "<form action='' method='POST'>";
    echo '<br><table frame="border" bgcolor="99FF66" border="0" cellspacing="2" width="600">';
    echo '<tr bgcolor="99FF66"><td valign="bottom" width=150 align=left><b>Server name</b></td>';
    echo '<td><input type="text" name="server_key" size="12" value="" /></td>';
    //echo "<td><input type='submit' value='Submit'/><a href='server_list.php'></td>";
    //echo '<td><input type="button" value="Google" onClick="window.location="http://www.google.com" /></td>';
    echo '<td><a href=server_create.php?id="$server_key"><button name="test" value=0 type="button">Create</button></td>';
    echo "<td><button name='create' value='0' type='button'>Create</button></td>";
    echo "<td><button name='query'  value='0' type='button'>Query </button></td>";
    echo "<td><button name='modify' value='0' type='button'>Modify</button></td>";
    echo "<td><button name='delete' value='0' type='button'>Delete</button></td>";
    echo "<td><button name='exit'   value='0' type='button'>Exit  </button></td>";
    echo '</tr><tr><td colspan="7" height="20" >Enter the server name you wish to to Create, Modify, Query or Delete & press corresponding button.</td></tr>';
    echo '<tr><td colspan=7><hr></td></tr></table>';
    echo '</form>';
}









// ================================================================================================
//                                        Standard Page footer
// ================================================================================================
function display_row_footer() {
    echo "</table></center><br>";
}





// ================================================================================================
//                   Display Content of file receive as parameter
// ================================================================================================
function display_file( $nom_du_fichier ) {
    $url = htmlspecialchars($_SERVER['HTTP_REFERER']);
    echo "<a href='$url'>Back</a>";

    echo '<table style="background-color: #EFCFFE"  frame="border" border="0" width="700">';
    echo '<tr><td><pre>';
    ///$myFile = "testFile.txt";
    //$fh = fopen($nom_du_fichier, 'r');
    //$theData = fgets($fh);
    //fclose($fh);
    //echo $theData;
    @readfile($nom_du_fichier);
    echo '</pre></td></tr>';
    echo '</table>';
}




// ================================================================================================
// Function to strip unwanted characters (Extra space,tab,newline) from beginning and end of data
// Strips any quotes escaped with slashes and passes it through htmlspecialschar.
// ================================================================================================
function sadm_clean_data($wdata) {
    if (! is_array($wdata)) {
        $wdata = trim($wdata);
        $wdata = stripslashes($wdata);
        $wdata = htmlspecialchars($wdata);
    }
    return $wdata;
}



// ================================================================================================
//                   All SADM Web Page Heading (Page Title Receive as Parameter)
// ================================================================================================
function sadm_page_heading2($msg) {
    $message = $msg;
    echo "\n\n\n<!-- ========================================================================= -->";
    echo "\n<div id='sadmMainBodyHeading'>";
    
    echo "\n<div id='sadmMainBodyHeadingLeft'>\n";
    if ($message != "List of all Servers") {
        echo "<a href='javascript:history.go(-1)'>" . 
            "<class='btn btn-info btn-sm'><span class='glyphicon glyphicon-arrow-left'></span>" ; 
        echo "</a>";
    }
    echo "\n</div>                              <!-- End of Div sadmMainBodyHeadingLeft -->";

    echo "\n<div id='sadmMainBodyHeadingCenter'>\n";
    echo "${msg}\n";
    echo "\n</div>                              <!-- End of Div sadmMainBodyHeadingCenter -->";
        
    echo "\n<div id='sadmMainBodyHeadingRight'>\n"; 
    echo date('l jS \of F Y, h:i:s A');
    echo "\n</div>                              <!-- End of Div sadmMainBodyHeadingRight -->";

    echo "\n</div>                              <!-- End of Div sadmMainBodyHeading -->\n";  
    echo "\n<!-- ============================================================================= -->";    
    #echo "\n<br>";
    echo "\n\n<div id='sadmMainBodyPage'>\n";   
}





// ================================================================================================
//                   Build Side Bar Based on SideBar Type Desired (server/ip/script)
// ================================================================================================
function build_sidebar_scripts_info() {

    #$DEBUG = TRUE;                                                     # Activate/Deactivate Debug

    # Reset All Counters
    $count=0;
    $script_array = array() ;

    # Form the base directory name where all the servers 'rch' files are located
    $RCH_ROOT = $_SERVER['DOCUMENT_ROOT'] . "/dat/";                    # /sadmin/www/dat
    if ($DEBUG) { echo "<br>Opening $RCH_ROOT directory "; }            # Debug Display RCH Root Dir

    # Make sure that the DATA Root directory is a directory
    if (! is_dir($RCH_ROOT)) {
        $msg="The $RCH_ROOT directory doesn't exist !\nCorrect the situation and retry operation";
        alert ("$msg");
        ?><script type="text/javascript">history.go(-1);</script><?php
        exit;
    }

    # Create unique filename that will contains all servers *.rch filename
    $tmprch = tempnam ('tmp/', 'ref_rch_file-');                        # Create unique file name
    if ($DEBUG) { echo "<br>Temp file of rch filename : " . $tmprch;}   # Show unique filename
    $CMD="find $RCH_ROOT -name '*.rch'  > $tmprch";                     # Construct find command
    if ($DEBUG) { echo "<br>Command executed is : " . $CMD ; }          # Show command constructed
    $a = exec ( $CMD , $FILE_LIST, $RCODE);                             # Execute find command
    if ($DEBUG) { echo "<br>Return code of command is : " . $RCODE ; }  # Display Return Code

    # Open input file containing the name of all rch filenames
    $input_fh  = fopen("$tmprch","r") or die ("can't open ref-rch file - " . $tmprch);

    # Loop through filename list in the file
    while(! feof($input_fh)) {
        $wfile = trim(fgets($input_fh));                                # Read rch filename line
        if ($DEBUG) { echo "<br>Processing file :<br>" . $wfile; }      # Show rch filename in Debug
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
    unlink($tmprch);                                                    # Delete Temp File
    # Under Debug - Display The Array Used to build the SideBar
    #if ($DEBUG) {foreach($script_array as $key=>$value) { echo "<br>Key is $key and value is $value";}}
    return $script_array;
}



// ================================================================================================
//                   Build Side Bar Based on SideBar Type Desired (server/ip/script)
// ================================================================================================
function build_sidebar_servers_info() {

    echo "p";
}
 

?>