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
# 2018_01_04 JDuplessis V1.0 Initial Version 
# 2018_05_06 JDuplessis V1.1 Change the look of the web page (Simplify code)
#@2019_01_20 Improvement v1.2 Web Page revamp - New Dark Look
# ==================================================================================================
# REQUIREMENT COMMON TO ALL PAGE OF SADMIN SITE
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmInit.php');           # Load sadmin.cfg & Set Env.
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmLib.php');            # Load PHP sadmin Library
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageHeader.php');     # <head>CSS,JavaScript</Head>


?>
<link href="https://fonts.googleapis.com/css?family=Space+Mono|Ubuntu+Mono" rel="stylesheet"> 
<style>

div.data_frame {
    /* font-family     :   Geneva, sans-serif; */
    font-family: 'Ubuntu Mono', 'Space Mono', Geneva, sans-serif, monospace;

    /* font-family: 'Space Mono', monospace; */


    background-color:   #2d3139;
    color           :    white;
    margin-left     :   5px;
    width           :   85%;
    border          :   1px solid #000000;
    text-align      :   left;
    padding         :   1%;
    border-width    :   5px;
    border-style    :   solid;
    border-color    :   #6b6c6f;
    border-radius   :   10px;
}
code {
    /* font-size:0.9em; */
    margin: 10px;
    background: #2f3743;
    text-align: left;
    color           : white;
    font-family: Consolas, "Liberation Mono", Menlo, Courier, monospace;
    font-size: 12px;
}
</style>
<?php
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageWrapper.php');    # Heading & SideBar


#===================================================================================================
#                                       Local Variables
#===================================================================================================
#
$DEBUG = False ;                                                        # Debug Activated True/False
$SVER  = "1.2" ;                                                         # Current version number
$CREATE_BUTTON = False ;                                                # Yes Display Create Button


# ==================================================================================================
#                       D I S P L A Y    S E L E C T E D   F I L E
# ==================================================================================================
function display_file ($WNAME)
{

    # Display Table Heading
    $TITRE = basename($WNAME);                                          # Build the Table Heading
    echo "\n\n<div class='data_frame'>                 <!-- Start of Server Data DIV -->";
    echo "\n<center><h2><strong><i>" .$TITRE. "</i></strong></h2></center>";   # Print 1st Row Heading

    $count=0;                                                           # Set Line Counter to Zero
    #echo file_get_contents($WNAME);
    $fh = fopen($WNAME,"r") or exit("Unable to open file : " . $WNAME); # Load File In Memory
    echo "<code>";
    while(!feof($fh)) {                                                 # Read till End Of File
        $wline = fgets($fh);                                            # Read Line By Line    
        if (strlen($wline) > 0) {                                       # Don't process empty Line
            $count+=1;                                                  # Increase Line Counter
            $pline = sprintf("%06d - %s\n" , $count,trim($wline));      # Format Line
            echo "<br>" . $pline  ;                                     # Print Log Line
        }
    }
    echo "</br></code></div>";                                          # End Data Frame
    fclose($fh);                                                        # Close Log
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
