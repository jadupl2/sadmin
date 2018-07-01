
# ==================================================================================================
#                      Update the crontab based on the $paction parameter
#
#   pscript  The name of the script to execute (With NO path - Need to be in $SADMIN/bin)
#   pname    The hostname of the server to include/modify/delete in crontab
#   paction  [C] for create entry  [U] for Updating the crontab   [D] Delete crontab entry
#   pmonth   13 Characters (either a Y or a N) each representing a month (YNNNNNNNNNNNN)
#            Position 0 = Y Then ALL Months are Selected
#            Position 1-12 represent the month that are selected (Y or N)             
#            Default is YNNNNNNNNNNNN meaning will run every month 
#   pdom     32 Characters (either a Y or a N) each representing a day (1-31) Y=Update N=No Update
#            Position 0 = Y Then ALL Date in the month are Selected
#            Position 1-31 Indicate (Y) date of the month that script will run or not (N)
#   pdow     8 Characters (either a Y or a N) 
#            If Position 0 = Y then will run every day of the week
#            Position 1-7 Indicate a week day () Starting with Sunday
#            Default is all Week (YNNNNNNN)
#   phour    Hour when the update should begin (00-23) - Default 1am
#   pmin     Minute when the update will begin (00-50) - Default 5min
#
# Example of line generated
#  +---------------- minute (0 - 59)
#  |  +------------- hour (0 - 23)
#  |  | +----------- date of month (1 - 31)
#  |  | | +--------- month (1 - 12)
#  |  | | |  +------ day of week (0 - 6) (Sunday=0 or 7)
#  |  | | |  | User |Command to execute  
# 15 04 * * 06 root /sadmin/bin/sadm_osupdate_farm.sh -s nano >/dev/null 2>&1
# ==================================================================================================
#
function update_crontab ($pscript,$paction = "U",$pmonth = "YNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN",
                        $pdom = "YNNNNNNNNNNNN",$pdow="NNNNNNNY",$phour=01,$pmin=00) 
{
    # To Display Parameters received - Used for Debugging Purpose ----------------------------------
    $DEBUG = False;
    if ($DEBUG) { 
        echo "<BR>I'm in update crontab" ; 
        $wmsg1 = "\npscript = " . $pscript ;                            # Script to execute
        $wmsg2 = "\npaction = " . $paction ;                            # U=Update C=Create D=Delete
        $wmsg3 = "\npmonth  = " . $pmonth ;                             # Month String YNYNYNYNYNY..
        $wmsg4 = "\npdom    = " . $pdom;                                # Day of MOnth String YNYN..
        $wmsg5 = "\npdow    = " . $pdow;                                # Day of Week String YNYN...
        $wmsg6 = "\nphour   = " . $phour;                               # Hour to run script
        $wmsg7 = "\npmin    = " . $pmin;                                # Min. to run Script
        $wmsg  = $wmsg1.$wmsg2.$wmsg3.$wmsg4.$wmsg5.$wmsg6.$wmsg7 ;     # Combine information
        sadm_alert ($wmsg) ;                                            # Display Alert with Info
        #return ;
    } 
    
    # Begin constructing our crontab line ($cline) - Based on Hour and Min. Received ---------------
    $cline = sprintf ("%02d %02d ",$pmin,$phour);                       # Hour & Min. of Execution

    # Construct Date of the month (1-31) to run and add it to crontab line ($cline) ----------------
    if ($pdom == "YNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN") {                  # If it's to run every Date
        $cline = $cline . "* ";                                         # Then use a Star
    }else{                                                              # If not to run every Date 
        $cdom = "";                                                     # Clear Work Variable
        for ($i = 1; $i < 32; $i = $i + 1) {                            # Check for Y or N in DOM
            if (substr($pdom,$i,1) == "Y") {                            # If Yes to run that Date
                if (strlen($cdom) == 0) {                               # And first date to add
                    $cdom = sprintf("%02d",$i);                         # Add Date number 
                }else{                                                  # If not 1st month in list
                    $cdom = $cdom . "," . sprintf("%02d",$i);           # More Date add , before
                }
            }    
        }
        $cline = $cline . $cdom . " " ;                                 # Add DOM in Crontab Line
    }
    
    # Construct the month(s) (1-12) to run and add it to crontab line ($cline) ---------------------
    if ($pmonth == "YNNNNNNNNNNNN") {                                   # If it's to run every Month
        $cline = $cline . "* ";                                         # Then use a Star
    }else{                                                              # If not to run every Months
        $cmonth = "";                                                   # Clear Work Variable
        for ($i = 1; $i < 13; $i = $i + 1) {                            # Check for Y or N in Month
            if (substr($pmonth,$i,1) == "Y") {                          # If Yes to run that month
                if (strlen($cmonth) == 0) {                             # And first month to add
                    $cmonth = sprintf("%02d",$i);                       # Add month number 
                }else{                                                  # If not 1st month in list
                    $cmonth = $cmonth . "," . sprintf("%02d",$i);       # More Mth add , before Mth
                }
            }    
        }
        $cline = $cline . $cmonth . " " ;                               # Add Month in Crontab Line
    }
    
    # Construct the day of the week (0-6) to run and add it to crontab line ($cline) ---------------
    if ($pdow == "YNNNNNNN") {                                          # If it's to run every Day
        $cline = $cline . "* ";                                         # Then use a Star
    }else{                                                              # If not to run every Day
        $cdow = "";                                                     # Clear Work Variable
        for ($i = 1; $i < 8; $i = $i + 1) {                             # Check for Y or N in Week
            if (substr($pdow,$i,1) == "Y") {                            # If Yes to run that Day
                if (strlen($cdow) == 0) {                               # And first add day of week
                    $cdow = sprintf("%02d",$i-1);                       # Add Day number 
                }else{                                                  # If not 1st Day in list
                    $cdow = $cdow . "," . sprintf("%02d",$i-1);         # More Day add , before Day
                }
            }    
        }
        $cline = $cline . $cdow . " " ;                                 # Add Month in Crontab Line
    }
    
    # Add User, script name and script parameter to crontab line -----------------------------------
    # SCRIPT WILL RUN ONLY IF LOCATED IN $SADMIN/BIN
    #$cline = $cline.SADM_USER." sudo ".SADM_BIN_DIR."/".$pscript." >/dev/null 2>&1\n";   
    $cline = $cline . " root " . SADM_BIN_DIR . "/" . $pscript . " >/dev/null 2>&1\n";   
    if ($DEBUG) { echo "\n<br>Final crontab line : " . $cline ; }       # Debug Show crontab line
   
    # Opening what will become the new crontab file ------------------------------------------------
    $newtab = fopen(SADM_WWW_TMP_FILE3,"w");                            # Create new Crontab File
    if (! $newtab) {                                                    # If Create didn't work
        sadm_fatal_error ("Can't create file " . SADM_WWW_TMP_FILE3) ;  # Show Err & Back Prev. Page
    } 

    # Write Crontab File Header --------------------------------------------------------------------
    $wline = "# Please don't edit manually, SADMIN generated file ". date("Y-m-d H:i:s") ."\n"; 
    fwrite($newtab,$wline);                                             # Write SADM Cron Header
    fwrite($newtab,"# \n");                                             # Write Comment Line
    fwrite($newtab,"SADMIN=".SADM_BASE_DIR."\n");                       # Write SADMIN Dir. Location
    fwrite($newtab,"# \n");                                             # Write Comment Line

    # Open existing crontab File - If don't exist create empty one ---------------------------------
    if (!file_exists(SADM_CRON_FILE)) {                                 # SADM crontab doesn't exist
        touch(SADM_CRON_FILE);                                          # Create empty crontab file
        chmod(SADM_CRON_FILE,0640);                                     # Set Permission on crontab
    }

    # Load actual crontab in array and process each line in array ----------------------------------
    $alines = file(SADM_CRON_FILE);                                     # Load Crontab in Array
    $UPD_DONE = False;                                                  # AutoUpdate was Off now ON?
    foreach ($alines as $line_num => $line) {                           # Process each line in Array
        if ($DEBUG) { echo "\n<br>Before Processing Ligne #{$line_num} : " . $line ; }        
        if (strpos(trim($line), '#') === 0) continue;                   # Next line if comment
        if (strpos(trim($line), 'SADMIN=') === 0) continue;             # Next line if SADMIN Env.
        $line = trim($line);                                            # Trim Crontab Line
        $wpos = strpos($line,$pscript);                                 # Get Pos. of script on line
        if ($wpos == false) {                                           # If Script is not on line
            fwrite($newtab,${line}."\n");                               # Write line to new crontab
        }else{                                                          # If script to Upd or Del
            continue;                                                   # Line Match then skip it
        }    
    }
    if ($paction == 'C') { fwrite($newtab,$cline); }                    # Add new line to crontab 
    if ($paction == "U") { fwrite($newtab,$cline); }                    # Add Update line to crontab 
    fclose($newtab);                                                    # Close sadm new crontab
    if (! copy(SADM_WWW_TMP_FILE3,SADM_CRON_FILE)) {                    # Copy new over existing 
        sadm_fatal_error ("Error copying " . SADM_WWW_TMP_FILE3 . " to " . SADM_CRON_FILE . " ");
    }
    unlink(SADM_WWW_TMP_FILE3);                                         # Delete Crontab tmp file
}


