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
#    2016-2018 Jacques Duplessis <sadmlinux@gmail.com>
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
#   If not, see <https://www.gnu.org/licenses/>.
# ==================================================================================================
# ChangeLog
# 2018_01_04 JDuplessis V1.0 Initial Version 
# 2018_05_06 JDuplessis V1.1 Change the look of the web page (Simplify code)
# 2019_01_20 Improvement v1.2 Web Page revamp - New Dark Look
# 2019_01_20 Update v1.3 Customize file not found message 
# 2019_07_25 Update: v1.4 File is displayed using monospace character.
# 2020_01_13 Update: v1.5 Enhance Web Page Appearance and color. 
# ==================================================================================================
# REQUIREMENT COMMON TO ALL PAGE OF SADMIN SITE
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmInit.php');           # Load sadmin.cfg & Set Env.
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmLib.php');            # Load PHP sadmin Library
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageHeader.php');     # <head>CSS,JavaScript</Head>


?>
<link href="https://fonts.googleapis.com/css?family=Space+Mono|Ubuntu+Mono" rel="stylesheet"> 
<style>

div.data_frame {
    font-family     :   Monaco, Menlo, "Liberation Mono",  monospace;
    background-color:   #006456;
    font-size       :   14px;
    font-weight     :   normal;
    color           :   white;
    margin-left     :   5px;
    width           :   96%;
    border          :   1px solid #000000;
    text-align      :   left;
    padding         :   1%;
    border-width    :   8px;
    border-style    :   solid;
    border-color    :   #6b6c6f;
    border-radius   :   10px;
}
</style>
<?php
require_once ($_SERVER['DOCUMENT_ROOT'].'/lib/sadmPageWrapper.php');    # Heading & SideBar


#===================================================================================================
#                                       Local Variables
#===================================================================================================
#
$DEBUG = False ;                                                        # Debug Activated True/False
$SVER  = "1.5" ;                                                        # Current version number
$CREATE_BUTTON = False ;                                                # Yes Display Create Button



# ==================================================================================================
#                       D I S P L A Y    S E L E C T E D   F I L E
# ==================================================================================================
function display_file ($WNAME)
{
    echo "\n\n<div class='data_frame'>                 <!-- Start of Server Data DIV -->";
    $count=0;                                                           # Set Line Counter to Zero
    try
    {
      if ( !file_exists($WNAME) ) { throw new Exception('File not found.'); }
      $fh = fopen($WNAME, "r");
      if ( !$fh ) { throw new Exception('File open failed.'); } 
    }
    catch ( Exception $e ) {
        sadm_fatal_error ("Unable to open file " . $WNAME);
        exit();
    } 

    echo "\n<code><pre>";
    while(!feof($fh)) {                                                 # Read till End Of File
        $wline = fgets($fh);                                            # Read Line By Line    
        if (strlen($wline) > 0) {                                       # Don't process empty Line
            $count+=1;                                                  # Increase Line Counter
            #$pline = sprintf("%06d - %s" , $count,trim($wline));        # Format Line
            $pline = sprintf("%s" , trim($wline));                      # Format Line
            echo "<br>" . $pline  ;                                     # Print Log Line
        }
    }
    echo "</br></code></pre></div>";                                    # End Data Frame
    fclose($fh);                                                        # Close Log
    return ;
}



# ==================================================================================================
#                                      PROGRAM START HERE
# ==================================================================================================

    # Get the parameter (Name of file to view) -----------------------------------------------------
    if (isset($_GET['filename']) ) {                                    # Get Parameter Expected
        $FILENAME = $_GET['filename'];                                  # Get Content of filename
        if ($DEBUG)  { echo "<br>FILENAME Received is $FILENAME "; }    # In Debug Display FileName
    }else{
        $err_msg = "No parameter received - Please advise administrator";
        sadm_fatal_error($err_msg);                                     # Display Error & Go Back
        exit() ;
    }

    # Verify if the file exist, if not go back to previous page after advising user. ---------------
    if ($DEBUG)  { echo "<br>Name of the file is $FILE"; }              # In Debug display Full Name
    if (! file_exists($FILENAME))  {                                    # If Log does not exist
        $msg = "The requested file doesn't exist !\n\n" .$FILENAME. "\n"; # Mess. to User
        sadm_fatal_error($msg);                                         # Display Error & Go Back
        exit();
    }
    
    # Display Standard Page Heading and Display Log ------------------------------------------------
    $title1="File Viewer";                                              # Heading Line 1 
    $title2="'" . $FILENAME . "'" ;                                     # Heading Line 2
    display_lib_heading("NotHome","$title1","$title2",$SVER);           # Display Page Heading
    display_file ($FILENAME);                                           # Go Display File Content
    std_page_footer()                                                   # HTML Footer
    ?>
