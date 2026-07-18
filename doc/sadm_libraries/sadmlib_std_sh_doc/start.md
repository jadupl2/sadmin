### (function)  start   

#### `def start(db_name="sadmin") :`
   
   
    Function 'start()'
        - If 'sa.db_used' is True, then it will return connection (sa_conn) & the cursor (db_cur).
        - If 'sa.db_used' is False, then it will return None for both.

      The function 'start()' basically initialize the SADMIN environment.

      Here a summary of the different things it does :
        1) Make sure $SADMIN directories & sub-dirrectories exist and have proper permissions.
        2) Open program & error log in append ('log_append=True') or write mode ('log_append=False').
        3) If 'sa.log_header' is 'True', write the log header.
        4) Check if this program can only be run by 'root' (sa.root_only=True
           If 'True' and current user is not 'root', show error message and abort.
        5) Check if this program can only be run on the SADMIN server (sa.server_only=True).
           If current host is not the SADMIN server, show error message and abort.
        6) If 'sa.SADM_GROUP_ONLY' is 'True', then user MUST be part of the SADMIN group 
           ('sadm_group') for the program to run (Unless you run it as 'root').
        7) Check if user want to use Database (db_used=True) but not on SADMIN Server
           Show error message and abort.
        8) If system is lock (and running on the SADMIN), issue message and exit(1)
        9) Check if PID file exist, check if timeout is reached, if not show error message and abort.
           Unless program is allow to run more than one copy at the same time (sa.multiple_exec=True).
       10) Record starting time of your program & record it in the RCH file (if 'use_rch' is True).
       11) If 'db_used' is True, open connection to database and return connection and cursor.
           If not on SADMIN system, show error message and abort.
    
       *** If any error occurs while executing this function the program is aborted. ***
       *** When you call 'sa.start()', it will come back to your program only when everything is OK. **
    
   
---
    


*Python library v1.1*   
*Wed Jun 17 13:47:01 2026*   
