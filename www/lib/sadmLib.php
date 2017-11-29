<?php
# ==================================================================================================
#   Author   :  Jacques Duplessis
#   Title    :  sadmlib.php
#   Version  :  1.0
#   Date     :  22 March 2016
#   Requires :  php
#   Synopsis :  This file is the PHP Library that's used by the SADMIN Web Interface
#
#   Copyright (C) 2016 Jacques Duplessis <duplessis.jacques@gmail.com>
#
#   The SADMIN Tool is free software; you can redistribute it and/or modify it under the terms
#   of the GNU General Public License as published by the Free Software Foundation; either
#   version 2 of the License, or (at your option) any later version.
#
#   SADMIN Tools are distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
#   without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#   See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with this program.
#   If not, see <http://www.gnu.org/licenses/>.
# ==================================================================================================
# ChangeLog
#   2016_03_16 - Jacques Duplessis
#       V1.0 Initial Version
#   2017_11_15 - Jacques Duplessis
#       V2.0 Restructure and modify to used to new web interface and MySQL Database.
#
# ==================================================================================================
#


    

#===================================================================================================
# DISPLAY HEADING LINES OF THE CONTENT PORTION OF THE WEB PAGE 
#===================================================================================================
function display_std_heading($BACK_URL,$LTITLE,$CTITLE,$RTITLE,$WVER,
                            $CREATE_BUTTON=False,$CREATE_URL="",$CREATE_LABEL="Create") {

    $URL_HOME   = '/index.php';                                         # Site Main Page
    
    # FIRST LINE DISPLAY TITLE, VERSION NUMBER AND DATE/TIME
    echo "\n\n<div style='float: left;'>${LTITLE} " ."$WVER". "</div>"; # Display Title & Version No
    echo "\n<div style='float: right;'>" . date('l jS \of F Y, h:i:s A') . "</div>";  
    echo "\n<div style='clear: both;'> </div>";                         # Clear - Move Down Now
    
    # SECOND LINE - LEFT SIDE - DISPLAY LINK TO PREVIOUS PAGE OR TO HOME PAGE
    echo "\n<div style='float: left;'>";                                # Align Left Link Go Back
    if (strtoupper($BACK_URL) != "HOME") {                              # Parameter Recv. = home
        echo "<a href='javascript:history.go(-1)'>Previous Page</a>";   # URL Go Back Previous Page
    }else{
        echo "<a href='" . $URL_HOME . "'>Home Page</a>";               # URL to Go Back Home Page
    }
    echo "</div>"; 
        
    # SECOND LINE - RIGHT SIDE - DISPLAY CREATE BUTTON AT THE FAR RIGHT, IF $CREATE_BUTTON IS TRUE
    if ($CREATE_BUTTON) {
        echo "\n<div style='float: right;'>";                           # Div Position Create Button
        echo "\n<a href='" . $CREATE_URL . "'>";                        # URL when Button Press
        echo "\n<button type='button'>" . $CREATE_LABEL . "</button></a>";  # Create Create Button
        echo "\n</div>\n";                                              # End of Button Div
    }else{
        echo "\n<div style='float: right;'>" . $RTITLE . "</div>";  
    }
    echo "\n<div style='clear: both;'> </div>";                         # Clear Move Down Now
    echo "\n<hr/>\n\n";                                             # Print Horizontal Line
}


# ==================================================================================================
#        Function called at every end of SADM web page (Close Database and end all std Div)
# ==================================================================================================
function std_page_footer($wcon) {
    if (isset($wcon)) { mysqli_close($wcon); }                                   # Close Database Connection
    echo "\n</div> <!-- End of sadmRightColumn   -->" ;                 # End of Left Content Page       
    echo "\n</div> <!-- End of sadmPageContents  -->" ;                 # End of Content Page
    echo "\n\n<div id='sadmFooter'>";
    echo "\nCopyright &copy; 2015-2017 - www.sadmin.ca - Suggestions, Questions or Report a problem at";
    echo '<a href="mailto:webadmin@sadmin.ca">webadmin@sadmin.ca</a></small>';
    echo "\n</div> <!-- End of Div sadmFooter -->";

    echo "\n\n</div> <!-- End of sadmWrapper       -->" ;                 # End of Real Full Page
    echo "\n<br>";
    echo "\n</body>";
    echo "\n</html>";
}



# ==================================================================================================
#          Function to Calculate the OS Update Time Based on Parameters Received
# ==================================================================================================
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

# ==================================================================================================
#               Popup Message received as parameter and wait for OK to be pressed
# ==================================================================================================
function sadm_confirm($msg) {
    $message = preg_replace("/\r?\n/", "\\n", addslashes($msg));
    echo "<a href='http://stackoverflow.com'";
    echo "onclick=\"return confirm('Are you sure?');\">My Link</a>";
    // echo "\n<script type=\"text/javascript\">";
    // $reponse = "\nwindow.confirm(\"$message\");";
    // echo "\n</script>\n";
    // return $reponse;
    
    // echo $Confirmation;
    // if ($Confirmation == true) {
    //     your code goes here
    // }
    // $message = preg_replace("/\r?\n/", "\\n", addslashes($msg));
    // echo "\n<script type=\"text/javascript\">";
    // echo "\nvar stay=confirm(\"$message\")";
    // #document.getElementById("demo").innerHTML = x;
    // echo "\n</script>\n";
    // return $reponse;
}



# ==================================================================================================
# Popup with the Error Message wait for 5 seconds and return to previous page
# ==================================================================================================
function sadm_fatal_error($msg) {
    $message = preg_replace("/\r?\n/", "\\n", addslashes($msg));
    echo "\n<script type=\"text/javascript\">";
    echo "\n alert(\"$message\");";
    echo "\n windows.history.back()";
    echo "\n</script>\n";
}



# ==================================================================================================
# Display Popup Message received and wait for User to press OK Button
# ==================================================================================================
function sadm_alert($msg) {
    $message = preg_replace("/\r?\n/", "\\n", addslashes($msg));
    echo "\n<script type=\"text/javascript\">";
    echo "\nalert(\"$message\");";
    echo "\n</script>\n";
}


# ==================================================================================================
#                        Transform date (DD/MM/YYY) into MYSQL format
# ==================================================================================================
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




# ==================================================================================================
# Function to strip unwanted characters (Extra space,tab,newline) from beginning and end of data
# Strips any quotes escaped with slashes and passes it through htmlspecialschar.
# ==================================================================================================
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



        # Display Operating System Logo
        #switch (strtoupper($WOS)) {
        #    case 'REDHAT' :
        #        echo "<td class='dt-center'>";
        #        echo "<a href='http://www.redhat.com' ";
        #        echo "title='Server $whost is a RedHat server - Visit redhat.com'>";
        #        echo "<img src='/images/redhat.png' ";
        #        echo "style='width:24px;height:24px;'></a></td>\n";
        #        break;
        #    case 'FEDORA' :
        #        echo "<td class='dt-center'>";
        #        echo "<a href='https://getfedora.org' ";
        #        echo "title='Server $whost is a Fedora server - Visit getfedora.org'>";
        #        echo "<img src='/images/fedora.png' ";
        #        echo "style='width:24px;height:24px;'></a></td>\n";
        #        break;
        #    case 'CENTOS' :
        #        echo "<td class='dt-center'>";
        #        echo "<a href='https://www.centos.org' ";
        #        echo "title='Server $whost is a CentOS server - Visit centos.org'>";
        #        echo "<img src='/images/centos.png' ";
        #        echo "style='width:24px;height:24px;'></a></td>\n";
        #        break;
        #    case 'UBUNTU' :
        #        echo "<td class='dt-center'>";
        #        echo "<a href='https://www.ubuntu.com/' ";
        #        echo "title='Server $whost is a Ubuntu server - Visit ubuntu.com'>";
        #        echo "<img src='/images/ubuntu.png' ";
        #        echo "style='width:24px;height:24px;'></a></td>\n";
        #        break;
        #    case 'LINUXMINT' :
        #        echo "<td class='dt-center'>";
        #        echo "<a href='https://linuxmint.com/' ";
        #        echo "title='Server $whost is a LinuxMint server - Visit linuxmint.com'>";
        #        echo "<img src='/images/linuxmint.png' ";
        #        echo "style='width:24px;height:24px;'></a></td>\n";
        #        break;
        #    case 'DEBIAN' :
        #        echo "<td class='dt-center'>";
        #        echo "<a href='https://www.debian.org/' ";
        #        echo "title='Server $whost is a Debian server - Visit debian.org'>";
        #        echo "<img src='/images/debian.png' ";
        #        #echo "style='width:24px;height:24px;'></a<</td>\n";
        #        echo "style='width:24px;height:24px;'></a<</td>\n";
        #        break;
        #    case 'RASPBIAN' :
        #        echo "<td class='dt-center'>";
        #        echo "<a href='https://www.raspbian.org/' ";
        #        echo "title='Server $whost is a Raspbian server - Visit raspian.org'>";
        #        echo "<img src='/images/raspbian.png' ";
        #        echo "style='width:24px;height:24px;'></a></td>\n";
        #        break;
        #    case 'SUSE' :
        #        echo "<td class='dt-center'>";
        #        echo "<a href='https://www.opensuse.org/' ";
        #        echo "title='Server $whost is a OpenSUSE server - Visit opensuse.org'>";
        #        echo "<img src='/images/suse.png' ";
        #        echo "style='width:24px;height:24px;'></a></td>\n";
        #        break;
        #    case 'AIX' :
        #        echo "<td class='dt-center'>";
        #        echo "<a href='http://www-03.ibm.com/systems/power/software/aix/' ";
        #        echo "title='Server $whost is an AIX server - Visit Aix Home Page'>";
        #        echo "<img src='/images/aix.png' ";
        #        echo "style='width:24px;height:24px;'></a></td>\n";
        #        break;
        #    default:
        #        echo "<td class='dt-center'>";
        #        echo "<img src='/images/os_unknown.jpg' ";
        #        echo "style='width:24px;height:24px;'></td>\n";
        #        break;
        #}


?>
