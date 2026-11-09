### (function)  unlock_system   

#### `def unlock_system(fname ,errmsg=True):`
   
   
        Remove the lock file for the received system host name.
        When the lock file exist "${SADMIN}/tmp/$(hostname -s).lock" for a system, no error or 
        warning is reported (No alert, No notification) to the user (on monitor screen) until the 
        lock file is remove.
        When the lock file time stamp exceed the number of seconds set by 'lock_timeout' variable
        then 'lock_file' will be automatically by "lock_status()" function.
       
        Args: 
            fname : Name of the system you want to remove the lock file (hostname -s, not FQDN).
                    The full path name of the lock file is "$SADMIN/tmp/$(hostname -s).lock"

        Args Optionnal: 
            errmsg: Default value is True
                    Use if don't want any message or error message written to log or screen.
                    Base your logic only on the return value and built and display your own message.

        Return Value : 
            Always return True, even the lock file doesn't exist
   
---
    


*Python library v1.1*   
*Wed Jun 17 13:47:01 2026*   
