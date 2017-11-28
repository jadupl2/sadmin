<?php
#
# ==================================================================================================
#   Author   :  Jacques Duplessis
#   Title    :  sadm_view_logfile.php
#   Version  :  1.5
#   Date     :  2 April 2016
#   Requires :  php
#   Synopsis :  Present a summary of all rch files received from all servers.
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
#   Version 2.0 - November 2017 
#       - Replace PostGres Database with MySQL 
#       - Web Interface changed for ease of maintenance and can concentrate on other things
#
# ==================================================================================================
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmInit.php');      # Load sadmin.cfg & Set Env.
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmLib.php');       # Load PHP sadmin Library
require_once      ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageHead.php');  # <head>CSS,JavaScript</Head>
require_once      ($_SERVER['DOCUMENT_ROOT'].'/crud/srv/sadm_server_common.php');
echo "\n\n<body>";                                                      # Start of Web Page Body
echo "\n\n<div id='sadmWrapper'>";                                      # Whole Page Wrapper Div
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageHeading.php');    # Top Universal Page Heading
echo "<div id='sadmPageContents'>";                                     # Lower Part of Page
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageSideBar.php');    # Display SideBar on Left 



#===================================================================================================
#                                       Local Variables
#===================================================================================================
#
$DEBUG = False ;                                                        # Debug Activated True/False
$SVER  = "2.0" ;                                                        # Current version number
$CREATE_BUTTON = False ;                                                # Yes Display Create Button


# ==================================================================================================
#           D I S P L A Y    L O G   (WFILE)   F O R    T H E   S E L E C T E D   H O S T
#  For the received host ($WHOST) 
#  Host Description is also received (WDESC)
#  The LOG Full Path Name (WNAME) to display 
# ==================================================================================================
function display_log_file ($WHOST,$WDESC,$WNAME)
{
    echo "\n<center>";                                                  # Center the Table
    echo "\n<table border=0>";                                          # Define Table
    echo "\n<tr>" ;                                                     # Begin Heading Row
    $TITRE="Content of log " . basename($WNAME);                        # Build the Table Heading
    echo "\n<th colspan=2>" . $TITRE . "</th>";                         # Print 1st Row Heading
    echo "\n</tr>";                                                     # Enf of Row Heading
    
    $count=0; $ddate = 0 ; 
    $fh = fopen($WNAME,"r") or exit("Unable to open file : " . $WNAME); # Load Log In Memory
    while(!feof($fh)) {                                                 # Read till End Of File
        $wline = fgets($fh);                                            # Read Log Line By Line    
        if (strlen($wline) > 0) {                                       # Don't process empty Line
            $count+=1;                                                  # Increase Line Counter
            echo "\n<tr>";                                              # Begin Table Row
            if ($count % 2 == 0) { $BGCOLOR="#FFF8C6" ; }else{ $BGCOLOR="#FAAFBE" ;}
            echo "\n<td width=40>" . $count   . "</td>\n";              # Print Line Counter
            echo "\n<td>" . $wline  . "</td>";                          # Print Log Line
            echo "\n</tr>";                                             # End of Row
        }
    }
    fclose($fh);                                                        # Close Log
    echo "</table></center>\n";                                         # End of Table
    return ;
}



# ==================================================================================================
#*                                      PROGRAM START HERE
# ==================================================================================================
#
    echo "\n\n<div id='sadmRightColumn'>";                              # Beginning Content Page

    # Get the first Parameter (HostName) and validate it -------------------------------------------
    if (isset($_GET['host']) ) {                                        # Get Content of 'host' Var.
        $HOSTNAME = $_GET['host'];                                      # Save content to HOSTNAME
        if ($DEBUG)  { echo "<br>HOSTNAME Received is $HOSTNAME"; }     # In Debug print HOSTNAME
        $sql = "SELECT * FROM server where srv_name = '$HOSTNAME' ;";   # Build Sql to validate host
        if ($DEBUG) { echo "<br>SQL = $sql"; }                          # In Debug Display SQL Stat.
        if ( ! $result=mysqli_query($con,$sql)) {                       # Execute SQL Select
            $err_line = (__LINE__ -1) ;                                 # Error on preceeding line
            $err_msg1 = "Category (" . $wkey . ") not found.\n";        # Row was not found Msg.
            $err_msg2 = strval(mysqli_errno($con)) . ") " ;             # Insert Err No. in Message
            $err_msg3 = mysqli_error($con) . "\nAt line "  ;            # Insert Err Msg and Line No 
            $err_msg4 = $err_line . " in " . basename(__FILE__);        # Insert Filename in Mess.
            sadm_fatal_error($err_msg1.$err_msg2.$err_msg3.$err_msg4);  # Display Msg. Box for User
        }else{                                                          # If row was found
            $row = mysqli_fetch_assoc($result);                         # Read the Associated row
        }
        if ($row = FALSE) {                                             # If Now row Array
            $msg = "Host $HOSTNAME is not valid.";                      # Error Message to user
            sadm_fatal_error($msg);                                     # Display Error & Go Back
        }
    }

    # Get the second paramater (Name of LOG file to view) ------------------------------------------
    $LOG_FILENAME = $_GET['filename'];                                  # Get Content of filename
    if ($DEBUG)  { echo "<br>FILENAME Received is $LOG_FILENAME "; }    # In Debug Display FileName


    # Verify that the LOG directory for the host exist, if not advise user and abort. --------------
    $WDIR = SADM_WWW_DAT_DIR . "/" . $HOSTNAME . "/log";                # Build Log DIR Name
    if ($DEBUG)  { echo "<br>Directory of the log file is $WDIR"; }     # In Debug print Log Dir.
    if (! is_dir($WDIR))  {                                             # If Log Dir. not found
        $msg = "The LOG Directory " . $WDIR . " does not exist.\n";     # Mess. to User
        $msg = $msg . "Correct the situation and retry request";        # Add to Previous Message
        sadm_fatal_error($msg);                                         # Display Error & Go Back
    }

    # Verify If the LOG File exist, if not go back to previous page after adivising user.-----------
    $LOGFILE = $WDIR . "/" . $LOG_FILENAME ;                            # Full Path to Log File
    if ($DEBUG)  { echo "<br>Name of the LOG file is $LOGFILE"; }       # In Debug display Full Name
    if (! file_exists($LOGFILE))  {                                     # If Log does not exist
        $msg = "The LOG file " . $LOGFILE . " does not exist.\n";       # Mess. to User
        $msg = $msg . "Correct the situation and retry request";        # Add to Previous Message
        sadm_fatal_error($msg);                                         # Display Error & Go Back
    }
    
    # Display Standard Page Heading and Display Log ------------------------------------------------
    display_std_heading("NotHome","Log Viewer ",$SVER);                 # Display Content Heading
    display_log_file ($HOSTNAME, $HOSTDESC, $LOGFILE);                  # Go Display File Content

    # COMMON FOOTING -------------------------------------------------------------------------------
    echo "</div> <!-- End of sadmRightColumn   -->" ;                   # End of Left Content Page
    echo "</div> <!-- End of sadmPageContents  -->" ;                   # End of Content Page
    include ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageFooter.php')  ;    # SADM Std EndOfPage Footer
    echo "</div> <!-- End of sadmWrapper       -->" ;                   # End of Real Full Page
?>
