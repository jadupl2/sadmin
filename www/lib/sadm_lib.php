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
// Function to strip unwanted characters (Extra space,tab,newline) from beginning and end of data
// Strips any quotes escaped with slashes and passes it through htmlspecialschar.
// ================================================================================================
function sadm_clean_data($wdata) {
    $wdata = trim($wdata);
    $wdata = stripslashes($wdata);
    $wdata = htmlspecialchars($wdata);
    return $wdata;
}


// ================================================================================================
//                      DISPLAY CATEGORY DATA USED IN THE DATA INPUT FORM
//
// wrow  = Array containing table row keys/values
// mode  = "Display" Will Only show row content - Can't modify any information
//       = "Create"  Will display default values and user can modify all fields, except the row key
//       = "Update"  Will display row content and user can modify all fields, except the row key
// ================================================================================================
function display_cat_record( $wrow , $mode) {

    echo "<div class='cat_form'>";                                      # Start Category Form Div

    echo "<div class='cat_code'>";                                      # >Start Div For Cat. Code
        echo "<div class='cat_label'>";                                 # >Start Div For Cade Label
        echo "Category Code";                                           # Label Text
        echo "</div>";                                                  # <End of Div For Code Label
        
        echo "<div class='cat_input'>"; 
        if ($mode == 'Create') {
            echo "<input type='text' name='scr_code' size=10 placeholder='Cat. Code'
                value='" . sadm_clean_data($wrow['cat_code']). "' >\n";
        }else{
            echo "<input type='text' name='scr_code' readonly size=10 placeholder='Cat. Code'
                 value='" . sadm_clean_data($wrow['cat_code']). "' >\n";   
        }
        echo "</div>";  # << End of cat_code_input
    echo "</div>";      # << End of cat_code
    
    
    // Category Description    
    echo "<div class='cat_desc'>";
        echo "<div class='cat_label'>";   
        echo "Category Description"; 
        echo "</div>"; 
        
        echo "<div class='cat_input'>"; 
        if ($mode == 'Display') {
            echo "<input type='text' name='scr_desc' readonly placeholder='Enter Category Desc.'
                size=25 value='" . sadm_clean_data($wrow['cat_desc']). "'/>\n";
        }else{
            echo "<input type='text' name='scr_desc' placeholder='Enter Category Desc.'
                size=25 value='" . sadm_clean_data($wrow['cat_desc']). "'/>\n";
        }
        echo "</div>";  # << End of cat_input
    echo "</div>";      # << End of cat_desc
    
    
    // Category Status
    echo "<div class='cat_status'>";
        echo "<div class='cat_label'>";   
        echo "Category Status"; 
        echo "</div>"; 
        
        echo "<div class='cat_input'>"; 
        if ($mode == 'Create') { $wrow['cat_status'] = True ; } 
        if ($mode == 'Display') {
            if ($wrow['cat_status'] == 't') {
                echo "<input type='radio' name='scr_status' value='1' onclick='javascript: return false;' checked> Active  \n";
                echo "<input type='radio' name='scr_status' value='0' onclick='javascript: return false;'> Inactive\n";
            }else{
                echo "<input type='radio' name='scr_status' value='1' onclick='javascript: return false;'> Active  \n";
                echo "<input type='radio' name='scr_status' value='0' onclick='javascript: return false;' checked > Inactive\n";
            }
        }else{
            if ($wrow['cat_status'] == 't') {
                echo "<input type='radio' name='scr_status' value='1' checked > Active  \n";
                echo "<input type='radio' name='scr_status' value='0'> Inactive\n";
            }else{
                echo "<input type='radio' name='scr_status' value='1'> Active\n";
                echo "<input type='radio' name='scr_status' value='0' checked > Inactive\n";
            }
        }
        echo "</div>";                                                  # < End of input Div
    echo "</div>";                                                      # < End of Field Div
    
    echo "</div>";                                                      # < End of Form Div
    echo "<br>";
}



// ================================================================================================
//                   All SADM Web Page Heading (Page Title Receive as Parameter)
// ================================================================================================
function sadm_page_heading($msg) {
    $message = $msg;

    echo "\n\n\n<!-- ============================================================================= -->";
    echo "\n<div id='sadmMainBodyHeading'>";
    echo "\n<div id='sadmMainBodyHeadingLeft'>\n";
    echo "${msg}\n";
    echo "</div>                                <!-- End of Div sadmMainBodyHeadingLeft -->";
        
    echo "\n<div id='sadmMainBodyHeadingRight'>\n"; 
    echo date('l jS \of F Y, h:i:s A');
    echo "\n</div>                              <!-- End of Div sadmMainBodyHeadingRight -->";

    echo "\n</div>                              <!-- End of Div sadmMainBodyHeading -->\n";  
    echo "\n<!-- ============================================================================= -->";    
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

    # Under Debug - Display The Array Used to build the SideBar
    if ($DEBUG) {foreach($script_array as $key=>$value) { echo "<br>Key is $key and value is $value";}}
    return $script_array;
}



// ================================================================================================
//                   Build Side Bar Based on SideBar Type Desired (server/ip/script)
// ================================================================================================
function build_sidebar_servers_info() {

    $query = "SELECT * FROM sadm.server ;";
    $result = pg_query($query) or die('Query failed: ' . pg_last_error());

    # Reset All Counters
    $count=0;
    $sadm_array = array() ;

    # Read All Server Table
    while ($row = pg_fetch_array($result, null, PGSQL_ASSOC)) {
        $count+=1;

        # Process Server Type
        $akey = "srv_type," . $row['srv_type'];
        if (array_key_exists($akey,$sadm_array)) {
            $sadm_array[$akey] = $sadm_array[$akey] + 1 ;
        }else{
            $sadm_array[$akey] = 1 ;
        }

        # Process OS Type
        $akey = "srv_ostype," . $row['srv_ostype'];
        if (array_key_exists($akey,$sadm_array)) {
            $sadm_array[$akey] = $sadm_array[$akey] + 1 ;
        }else{
            $sadm_array[$akey] = 1 ;
        }

        # Process OS Name
        $akey = "srv_osname," . $row['srv_osname'];
        if (array_key_exists($akey,$sadm_array)) {
            $sadm_array[$akey] = $sadm_array[$akey] + 1 ;
        }else{
            $sadm_array[$akey] = 1 ;
        }

        # Process OS Version
        $akey = "srv_osversion," . $row['srv_osversion'];
        if (array_key_exists($akey,$sadm_array)) {
            $sadm_array[$akey] = $sadm_array[$akey] + 1 ;
        }else{
            $sadm_array[$akey] = 1 ;
        }

        # Count Number of Active Servers
        if ($row['srv_active']  == "t") {
            $akey = "srv_active," ;
            if (array_key_exists($akey,$sadm_array)) {
                $sadm_array[$akey] = $sadm_array[$akey] + 1 ;
            }else{
                $sadm_array[$akey] = 1 ;
            }
        }

        # Count Number of Inactive Servers
        if ($row['srv_active']  == "f") {
            $akey = "srv_inactive," ;
            if (array_key_exists($akey,$sadm_array)) {
                $sadm_array[$akey] = $sadm_array[$akey] + 1 ;
            }else{
                $sadm_array[$akey] = 1 ;
            }
        }

        # Count Number of Physical and Virtual Servers
        if ($row['srv_vm']  == "t") {
            $akey = "srv_vm," ;
            if (array_key_exists($akey,$sadm_array)) {
                $sadm_array[$akey] = $sadm_array[$akey] + 1 ;
            }else{
                $sadm_array[$akey] = 1 ;
            }
        }else{
            $akey = "srv_physical," ;
            if (array_key_exists($akey,$sadm_array)) {
                $sadm_array[$akey] = $sadm_array[$akey] + 1 ;
            }else{
                $sadm_array[$akey] = 1 ;
            }
        }

        # Count Number of Physical and Virtual Servers
        if ($row['srv_sporadic']  == "t") {
            $akey = "srv_sporadic," ;
            if (array_key_exists($akey,$sadm_array)) {
                $sadm_array[$akey] = $sadm_array[$akey] + 1 ;
            }else{
                $sadm_array[$akey] = 1 ;
            }
        }

    }
    ksort($sadm_array);                                                    # Sort Array Based on Keys
    #$DEBUG=True;
    # Under Debug - Display The Array Used to build the SideBar
    if ($DEBUG) {foreach($sadm_array as $key=>$value) { echo "<br>Key is $key and value is $value";}}
    return $sadm_array;
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
//                   Display Server Data used in General Server Information Page
// ================================================================================================
function display_server_info( $rarray ) {
    echo '<table frame="border" border="1" cellspacing="2" width="900">';

    // ======================= G E N E R A L    I N F O R M A T I O N ============================
    echo '<br>';
    echo '<table frame="border" bgcolor="lavender" border="0" width="800">';
    echo '<tr><td colspan=5 align=center bgcolor="blue"><font color=#FFFFFF><b>General Information</b></font></td></tr>';
    echo '<tr>';
    $myheader = stripslashes($rarray["server_name"]) . '.'  . stripslashes($rarray["server_domain"]) ;
    $myheader = $myheader . ' - ' . stripslashes($rarray["server_desc"]) ;
    echo '<td width=120 align=left><b>Server</b></td>';
    echo '<td colspan=3 width=300 align=left>' . $myheader . '</td>';
    echo '</tr>';

    // ============== Server Type and Server Notes
    echo '<td width=120 align=left><b>Server Type</b></td>';
    echo '<td width=300 align=left>' . stripslashes($rarray['server_type']) . '</td>';
       echo '<td align=left><b>General Note</b></td>';
    echo '<td align=left>' . stripslashes($rarray["server_note"]) . '</td>';
    echo '</tr>';

    // Server Active/Inactive & DR Notes
    echo '<tr>';
    echo '<td width=150 align=left><b>Server Status</b></td>';
    if (stripslashes($rarray['server_active']) == 1 ) {
       echo '<td>Active</td>';
    }else{
       echo '<td>Inactive</td>' ;
    }
       echo '<td align=left><b>D.R. Note</b></td>';
    echo '<td align=left>' . stripslashes($rarray["server_drnote"]) . '</td>';
    echo '</tr>';

    // Virtual Server & Server Recover at DR
    echo '<tr>';
    echo '<td width=150 align=left><b>Virtual Server</b></td>';
    if (stripslashes($rarray['server_vm']) == 1 ) {
       echo '<td>Yes</td>';
    }else{
       echo '<td>No</td>' ;
    }
       echo '<td align=left><b>Recover at DR</b></td>';
    if (stripslashes($rarray['server_dr']) == 1 ) {
       echo '<td>Yes</td>';
    }else{
       echo '<td>No</td>' ;
    }
    echo '</tr>';

    // Edit Server Information & Operating System
    echo '<tr>';
    echo '<td colspan=2 align=left><b><a href=/cfg/config_server_update.php?id=' . $rarray["server_name"] . '>Edit Server Information</a></b></td>';
    // Server O/S and Version number
    $myheader = stripslashes($rarray['server_os']) . ' ' . stripslashes($rarray['server_osver1']) . '.' ;
    $myheader = $myheader . stripslashes($rarray['server_osver2']) . '.' . stripslashes($rarray['server_osver3']);
    echo '<td width=200 align=left><b>Operating system</b></td>';
    echo '<td width=300 align=left>' . $myheader . '</td>';
    echo '</tr>';

    // Performance And Backup Links
    echo '<tr>';
    echo '<td colspan=2 align=left><b><a href=/unix/server_performance.php?host=' . $rarray["server_name"] . '>View Graphic Performance</a></b></td>';
    #echo '<td width=150 align=left></td>';
    echo '<td colspan=2 align=left><b><a href=/unix/server_rcfiles.php?host=' . $rarray["server_name"] . '>View Backup results</a></b></td>';
    echo '</tr>';

    echo '</table>';

    // ============================================ N E T W O R K   I N F O R M A T I O N =================================================
    echo '<br>';
    echo '<table frame="border" bgcolor="lavender" border="0" width="800">';
    echo '<tr><td colspan=3 align=center bgcolor="blue"><font color=#FFFFFF><b>Network Information</b></font></td></tr>';
    $myheader = stripslashes($rarray["server_ip1a"]) . '.' .stripslashes($rarray["server_ip1b"]) . '.' ;
    $myheader = $myheader . stripslashes($rarray["server_ip1c"]) . '.' . stripslashes($rarray["server_ip1d"]) ;
    echo '<tr><td width=170 align=left><b>Network Interface #1</b></td>';
    echo '<td width=300 align=left>' . $myheader . '</td>';
    echo '<td width=300 align=center><a href=server_view_text_file.php?file=data/hw/ifconfig&server=' . stripslashes($rarray["server_name"]) . '>' . 'View ifconfig command output'  . '</a></td>';
    echo '</tr>';
    $myheader = stripslashes($rarray["server_ip2a"]) . '.' .stripslashes($rarray["server_ip2b"]) . '.' ;
    $myheader = $myheader . stripslashes($rarray["server_ip2c"]) . '.' . stripslashes($rarray["server_ip2d"]) ;
    echo '<tr><td width=170 align=left><b>Network Interface #2</b></td>';
    echo '<td width=300 align=left>' . $myheader . '</td>';
    echo '<td width=300 align=center><a href=server_view_text_file.php?file=data/hw/netstat&server=' . stripslashes($rarray["server_name"]) . '>' . 'View netstat command output' . '</a></td>';
    echo '</tr>';
    $myheader = stripslashes($rarray["server_ip3a"]) . '.' .stripslashes($rarray["server_ip3b"]) . '.' ;
    $myheader = $myheader . stripslashes($rarray["server_ip3c"]) . '.' . stripslashes($rarray["server_ip3d"]) ;
    echo '<tr><td width=170 align=left><b>Network Interface #3</b></td>';
    echo '<td width=300 align=left>' . $myheader . '</td>';
    echo '<td width=300 align=center>' . ' '  . '</td>';
    echo '</tr>';
    echo '</table>';


    // ======================= H A R D W A R E    I N F O R M A T I O N ============================
    echo '<br>';
    echo '<table frame="border" bgcolor="lavender" border="0" width="800">';
    echo '<tr><td colspan=5 align=center bgcolor="blue"><font color=#FFFFFF><b>Hardware & Filesystem Information</b></font></td></tr>';
    echo '<tr><td><b>Internal Disk</b></td>';
    echo '<td> ' . stripslashes($rarray["server_disk_int"]) . ' GB';
    echo '<td>   </td>';
    echo '<td align=left><b>Server Model   </b></td>';
    echo '<td> ' . stripslashes($rarray["server_model"]) . '</td>';
    echo '</tr>';
    echo '<td><b>External Disk</b></td>';
    echo '<td width=210>' . stripslashes($rarray["server_disk_ext"]) . ' GB';
    echo '<td>   </td>';
    echo '<td><b>Serial Number</b></td>';
    echo '<td> ' . stripslashes($rarray["server_serial"]) . '</td>';
    echo '</tr>';

    echo '<tr>';
    echo '<td colspan=2 align=left><a href=server_view_text_file.php?file=data/hw/pvs&server=' . stripslashes($rarray["server_name"]) . '>' . 'Physical Volume - pvs command output' . '</a></td>';
    echo '<td>   </td>';
    echo '<td><b>Memory</b></td>';
    echo '<td>'  . stripslashes($rarray["server_memory"]) . ' MB';
    echo '</tr>';

    echo '<tr>';
    echo '<td colspan=2 align=left><a href=server_view_text_file.php?file=data/hw/vgs&server=' . stripslashes($rarray["server_name"]) . '>' . 'Volume Group - vgs command output' . '</a></td>';
    echo '<td>   </td>';
    echo '<td><b>CPU</b></td>';
    echo '<td>' . stripslashes($rarray["server_cpu_nb"]) . ' X ' . stripslashes($rarray["server_cpu_speed"]) . ' Mhz</td>';
    echo '</tr>';

    echo '<tr>';
    echo '<td colspan=2 align=left><a href=server_view_text_file.php?file=data/hw/lvs&server=' . stripslashes($rarray["server_name"]) . '>' . 'Logical Volume - lvs command output' . '</a></td>';
    echo '</tr>';

    echo '<tr>';
    echo '<td colspan=2 align=left><a href=server_view_text_file.php?file=data/hw/df&server=' . stripslashes($rarray["server_name"]) . '>' . 'Filesystem - df command output' . '</a></td>';
    echo '</tr>';
    echo '</table>';



    // ======================= D I S A S T E R    R E C O V E R Y   I N F O R M A T I O N ============================
    echo '<br>';
    echo '<table frame="border" bgcolor="lavender" border="0" width="800">';
    echo '<tr><td align=center colspan=5 bgcolor="blue"><font color=#FFFFFF><b>Disaster Recovery Information</b></font></td></tr>';


    # STORIX RECOVERY PROCEDURE
    if ( stripslashes($rarray['server_os']) == "Linux") {
        $DRDOC = 'data/dr/doc/dr_storix_restore.doc';
        $WFILE = SADM_WWW_DIR . $DRDOC;
        if (file_exists($WFILE)) {
            echo '<tr><td colspan=5><b><a href=/' . $DRDOC . '>Storix Recovery Procedure (' . $WFILE . ').</a></b></td>';
        } else {
            echo '<tr><td colspan=5><b>Storix Recovery Procedure is missing (' . $WFILE . ').</b></td>';
        }
    }


    # SPECIFIC PROCEDURE FOR SERVER - IF FILE EXIST WITH NAME "DR_{SERVERNAME}.doc" THEN DISPLAY LINK
    $DRDOC = 'data/dr/doc/dr_' . stripslashes($rarray["server_name"]) . '.doc';
    $WFILE = SADM_WWW_DIR . $DRDOC;
    if (file_exists($WFILE)) {
        echo '<tr><td colspan=5><b><a href=/' . $DRDOC . '>Specific Recovery procedure of ' . stripslashes($rarray["server_name"]) . ' (' . $WFILE . ').</a></b></td>';
    } else {
        echo '<tr><td colspan=5><b>Recovery procedure of ' . stripslashes($rarray["server_name"]) . ' is missing (' . $WFILE . ').</b></td>';
    }

    $DRDOC = 'data/dr/doc/dr_' . stripslashes($rarray["server_name"]) . '_a.doc';
    $WFILE = SADM_WWW_DIR . $DRDOC;
    if (file_exists($WFILE)) {
        echo '<tr><td colspan=5><b><a href=/' . $DRDOC . '>Special note for recovering ' . stripslashes($rarray["server_name"]) . ' (' . $WFILE . ').</a></b></td>';
    }


    # ON LINUX - DISPLAY PROCEDURE TO RESTORE FILE WITH TSM
    if ( stripslashes($rarray['server_os']) == "Linux") {
        $FSREST = 'data/dr/doc/linux_filesystem_restore_script.doc';
        $WFILE = SADM_WWW_DIR . $FSREST;
        if (file_exists($WFILE)) {
            echo '<tr><td colspan=5><b><a href=/' . $FSREST . '>TSM Filesystem Restore Procedure (' . $WFILE . ').</a></b></td>';
        } else {
            echo '<tr><td colspan=5><b>Filesystem restore procedure with TSM is ' . stripslashes($rarray["server_name"]) . ' is missing (' . $WFILE . ').</b></td>';
        }
    }


    # ON AIX DISPLAY PROCEDURE TO RECREATE VOLUME GROUP
    if ( stripslashes($rarray['server_os']) == "Aix") {
        $DRDOC = 'data/dr/doc/aix_recreate_volume_group.doc';
        $WFILE = SADM_WWW_DIR . $DRDOC;
        if (file_exists($WFILE)) {
            echo '<tr><td colspan=5><b><a href=/' . $DRDOC . '>Recreate volume group procedure (' . $WFILE . ').</a></b></td></tr>';
        } else {
            echo '<tr><td colspan=5><b>Recreate volume group procedure is missing (' . $WFILE . ').</b></td></tr>';
        }
    }

    # RESTORE KMA DOCUMENTATION FOR SERVER SPMQ1022
    if (( stripslashes($rarray['server_os']) == "Aix") and  ( stripslashes($rarray["server_name"]) == "spmq1022")) {
        $DRDOC = 'data/dr/doc/dr_restoring_kma_at_sungard.doc';
        $WFILE = SADM_WWW_DIR . $DRDOC;
        if (file_exists($WFILE)) {
            echo '<tr><td colspan=5><b><a href=/' . $DRDOC . '>Restoring KMA at DR site (' . $WFILE . ').</a></b></td></tr>';
        } else {
            echo '<tr><td colspan=5><b>Procedure for restoring KMA at DR site is missing (' . $WFILE . ').</b></td></tr>';
        }
    }

    // Configuration cfg2html
    echo '<tr>';
    echo '<td colspan=5 align=left><b><a href=/unix/server_detail_config.php?host=' . $rarray["server_name"] . '>Detailled server configuration</a></b></td>';
    echo '</tr>';
    echo '<tr>';
    echo '<td colspan=5 align=left><b><a href=/unix/server_system_config.php?host=' . $rarray["server_name"] . '>Summarized server configuration</a></b></td>';
    echo '</tr>';
    echo '</table>';

    echo '</table>';
}
?>
