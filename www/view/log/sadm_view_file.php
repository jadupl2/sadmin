<?php
#
# ==================================================================================================
#   Author   :  Jacques Duplessis
#   Title    :  sadm_view_file.php
#   Version  :  1.0
#   Date     :  4 January 2018
#   Requires :  php
#   Synopsis :  Present a summary of all rch files received from all servers.
#   
#   Copyright (C) 2016-2018 Jacques Duplessis <duplessis.jacques@gmail.com>
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
#   2018_01_04 JDuplessis
#       V1.0 Initial Version 
# ==================================================================================================
# REQUIREMENT COMMON TO ALL PAGE OF SADMIN SITE
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmInit.php');           # Load sadmin.cfg & Set Env.
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmLib.php');            # Load PHP sadmin Library
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageHeader.php');     # <head>CSS,JavaScript</Head>
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageWrapper.php');    # Heading & SideBar

echo "<style>";
echo "table { ";
echo "    display: table;";
echo "    border-collapse: separate;";
echo "    border-spacing: 2px;";
echo "    border-color: black;";
echo "}";
echo "</style>";

#===================================================================================================
#                                       Local Variables
#===================================================================================================
#
$DEBUG = False ;                                                        # Debug Activated True/False
$SVER  = "10" ;                                                         # Current version number
$CREATE_BUTTON = False ;                                                # Yes Display Create Button


# ==================================================================================================
#                       D I S P L A Y    S E L E C T E D   F I L E
# ==================================================================================================
function display_file ($WNAME)
{
    echo "\n<center>";                                                  # Center the Table
    echo "\n<table>";                                # Define Table
    echo "\n<tr>" ;                                                     # Begin Heading Row
    $TITRE="Content of file " . basename($WNAME);                        # Build the Table Heading
    echo "\n<th colspan=2 >" . $TITRE . "</th>";                         # Print 1st Row Heading
    echo "\n</tr>";                                                     # Enf of Row Heading
    
    $count=0; $ddate = 0 ; 
    $fh = fopen($WNAME,"r") or exit("Unable to open file : " . $WNAME); # Load Log In Memory
    while(!feof($fh)) {                                                 # Read till End Of File
        $wline = fgets($fh);                                            # Read Log Line By Line    
        if (strlen($wline) > 0) {                                       # Don't process empty Line
            $count+=1;                                                  # Increase Line Counter
            echo "\n<tr>";                                              # Begin Table Row
            if ($count % 2 == 0) { $BGCOLOR="#f8f1f8" ; }else{ $BGCOLOR="#f5d7f5" ;}
            echo "\n<td width=40>" . $count   . "</td>\n";              # Print Line Counter
            echo "\n<td>" . $wline  . "</td>";                          # Print Log Line
            echo "\n</tr>";                                             # End of Row
        }
    }
    fclose($fh);                                                        # Close Log
    echo "</table></center><br>\n";                                         # End of Table
    return ;
}



# ==================================================================================================
#*                                      PROGRAM START HERE
# ==================================================================================================
#
    # Get the paramater (Name of file to view) -----------------------------------------------------
    $FILENAME = $_GET['filename'];                                      # Get Content of filename
    if ($DEBUG)  { echo "<br>FILENAME Received is $FILENAME "; }        # In Debug Display FileName

    # Verify If the File exist, if not go back to previous page after adivising user.---------------
    if ($DEBUG)  { echo "<br>Name of the file is $FILE"; }              # In Debug display Full Name
    if (! file_exists($FILENAME))  {                                    # If Log does not exist
        $msg = "The file " . $FILENAME . " does not exist.\n";          # Mess. to User
        $msg = $msg . "Correct the situation and retry request";        # Add to Previous Message
        sadm_fatal_error($msg);                                         # Display Error & Go Back
    }
    
    # Display Standard Page Heading and Display Log ------------------------------------------------
    display_std_heading("NotHome","File Viewer ","","",$SVER);          # Display Content Heading
    display_file ($FILENAME);                                           # Go Display File Content
    std_page_footer()                                                   # HTML Footer
    ?>
