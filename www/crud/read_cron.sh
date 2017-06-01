
# ==================================================================================================
#                      Update the crontab based on the $paction parameter
#
#   pscript  The name of the script to execute (With the path) 
#   pname    The hostname of the server to include/modify/delete in crontab
#   paction  [C] for create entry  [U] for Updating the crontab   [D] Delete crontab entry
#   pmonth   12 Characters (either a Y or a N) each representing a month (YYYYYYYYYYYY)
#            Default is that entry could run every month, no restriction based on month
#   pdom     31 Characters (either a Y or a N) each representing a day (1-31) Y=Update N=No Update
#            Default all at Y - Entry could run any day of the month 
#            So entry will run Once a week on the day specify in pdow 
#   pdow     7 Characters (either a Y or a N) each representing a week day () Starting with Sunday
#            Default at Saturday
#   phour    Hour when the update should begin (00-23) - Default 1am
#   pmin     Minute when the update will begin (00-50) - Default 5min
#
# Default will cause new entry to run every week on Saturday at 1:05 am.
# ==================================================================================================
function update_crontab ($pscript,$paction = "U",$pmonth = "*",$pdom = "*",$pdow=6,$phour=0,$pmin=0) 
{
    # Begin constructing our crontab line ($cline) based on parameters received
    $cline = sprintf ("%02d %02d ",$pmin,$phour);                       # Hour & Min. of Execution

    # Construct Date of the month (1-31) to run and add it to crontab line ($cline)
    if ($pdom == str_repeat("Y",31)) {                                  # If it's to run every Date
        $cline = $cline . "* ";                                         # Then use a Star
    }else{                                                              # If not to run every Date 
        $cdom = "";                                                     # Clear Work Variable
        for ($i = 0; $i < 31; $i = $i + 1) {                            # Check for Y or N in DOM
            if (substr($pdom,$i,1) == "Y") {                            # If Yes to run that Date
                if (strlen($cdom) == 0) {                               # And first date to add
                    $cdom = sprintf("%02d",$i+1);                       # Add Date number 
                }else{                                                  # If not 1st month in list
                    $cdom = $cdom . "," . sprintf("%02d",$i+1);         # More Date add , before
                }
            }    
        }
        $cline = $cline . $cdom . " " ;                                 # Add DOM in Crontab Line
    }
    
    # Construct the month(s) (1-12) to run and add it to crontab line ($cline)
    if ($pmonth == str_repeat("Y",12)) {                                # If it's to run every Month
        $cline = $cline . "* ";                                         # Then use a Star
    }else{                                                              # If not to run every Months
        $cmonth = "";                                                   # Clear Work Variable
        for ($i = 0; $i < 12; $i = $i + 1) {                            # Check for Y or N in Month
            if (substr($pmonth,$i,1) == "Y") {                          # If Yes to run that month
                if (strlen($cmonth) == 0) {                             # And first month to add
                    $cmonth = sprintf("%02d",$i+1);                     # Add month number 
                }else{                                                  # If not 1st month in list
                    $cmonth = $cmonth . "," . sprintf("%02d",$i+1);     # More Mth add , before Mth
                }
            }    
        }
        $cline = $cline . $cmonth . " " ;                               # Add Month in Crontab Line
    }
    
    # Construct the day of the week (0-6) to run and add it to crontab line ($cline)
    if ($pdow == str_repeat("Y",7)) {                                   # If it's to run every Day
        $cline = $cline . "* ";                                         # Then use a Star
    }else{                                                              # If not to run every Day
        $cdow = "";                                                     # Clear Work Variable
        for ($i = 0; $i < 7; $i = $i + 1) {                             # Check for Y or N in Week
            if (substr($pdow,$i,1) == "Y") {                            # If Yes to run that Day
                if (strlen($cdow) == 0) {                               # And first add day of week
                    $cdow = sprintf("%02d",$i);                         # Add Day number 
                }else{                                                  # If not 1st Day in list
                    $cdow = $cdow . "," . sprintf("%02d",$i);           # More Day add , before Day
                }
            }    
        }
        $cline = $cline . $cdow . " " ;                                 # Add Month in Crontab Line
    }
    
    # Add User, script name and script parameter to crontab line
    $cline = $cline . "root " . $pscript . " >/dev/null 2>&1\n";        # Add user & cmd on $cline
    if ($DEBUG) { echo "\n<br>Assemble crontab line : " . $cline ; }    # Debug Show crontab line
   
    # Opening what will become the new crontab file
    $newtab = fopen(SADM_WWW_TMP_FILE1,"w");                            # Create new Crontab File
    if (! $newtab) {                                                    # If Create didn't work
        sadm_fatal_error ("Can't create file " . SADM_WWW_TMP_FILE1) ;  # Show Err & Back Prev. Page
    } 
    # Write Crontab File Header
    $wline = "# Please don't edit manually, SADMIN generated file ". date("Y-m-d H:i:s") ."\n"; 
    fwrite($newtab,$wline);                                             # Write SADM Cron Header
    fwrite($newtab,"# \n");                                             # Write Comment Line

    # Open existing crontab File - If don't exist create empty one
    if (!file_exists(SADM_CRON_FILE)) {                                 # SADM crontab doesn't exist
        touch(SADM_CRON_FILE);                                          # Create empty crontab file
        chmod(SADM_CRON_FILE,0640);                                     # Set Permission on crontab
        #chown(SADM_CRON_FILE,'root');                                   # Set Crontab Owner
        #chgrp(SADM_CRON_FILE,'root');                                   # Set Crontab Group Owner
    }

    # Load actual crontab in array and process each line in array
    $alines = file(SADM_CRON_FILE);                                     # Load Crontab in Array
    $UPD_DONE = False;                                                  # AutoUpdate was Off now ON?
    foreach ($alines as $line_num => $line) {                           # Process each line in Array
        if ($DEBUG) { echo "\n<br>Before Processing Ligne #{$line_num} : " . $line ; }        
        if (strpos(trim($line), '#') === 0) continue;                   # Next line if comment
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
    if (! copy(SADM_WWW_TMP_FILE1,SADM_CRON_FILE)) {                    # Copy new over existing 
        sadm_fatal_error ("Error copying " . SADM_WWW_TMP_FILE1 . " to " . SADM_CRON_FILE . " ");
    }
    unlink(SADM_WWW_TMP_FILE1);                                         # Delete Crontab tmp file
}
