### (function)  stop   

#### `def stop(pexit_code : int) -> None:`
   
   
    Function 'stop(exit_code)'
        - exit_code (0=Success, 1=Error).

      This should be the one of the last function called at the end of your program.

      What this function does:
        1) Calculate execution Time.
        2) If 'sa.use_rch = True', update the rch file (End Time & Elapse Time ...).
        3) Validate the alert group, 
           If any alert is pending, send notification to group members.
           move the alert to the history file.
        4) If 'db_used' is True, and we are on the SADMIN server, close the database connection.
        5) If the error log file is empty, delete it.
        6) Delete the PID file of the program (sa.pid_file).
        7) Trim the log according to user choice in 'sa.sadm_max_logline'.
           No trim is done if 'sa.sadm_max_logline = 0'.
        8) Trim The RCH File according to user choice in 'sa.sadm_max_rchline'.
           No trim is done if 'sa.sadm_max_rchline = 0'.
        9) If 'sa.log_footer = True', write the log footer.
       10) Close log and error log files.
       11) Set permission and owner/group to log and rch files.
       12) If on the SADMIN server, then rch and log are immediatly web central directory.
 

        Args:            
            pexit_code (int)    : Can be either 0 (Successfully) if the script terminate 
                                  with success or with a non-zero (Error Encountered) if 
                                  it terminated with error. 
                                  Please call this function just before your script end.

        Return: 
            None
   
---
    


*Python library v1.1*   
*Wed Jun 17 13:47:01 2026*   
