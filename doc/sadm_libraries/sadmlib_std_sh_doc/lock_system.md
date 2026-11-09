### (function)  lock_system   

#### `def lock_system(fname, errmsg=True ) :`
   
   
        Create a system 'lock_file' for the specified hostname.
        When the lock file exist "${SADMIN}/tmp/$(hostname -s).lock" for a system, 
        no error or warning is reported (No alert, No notification) to the user 
        Lock system will appears on the monitor web page until the 'lock_file' is removed, 
        either by calling then 'unlock_system' function or when the lock file time stamp exceed 
        the number of seconds set by 'sa.lock_timeout' variable. The 'unlock system()' function
        will automatically remove 'lock_file' when this time is expired or when you manually 
        remove it.
        
    Args: 
        fname : Name of the system you want to remove the lock file (hostname -s, not FQDN).
                The full path name of the lock file is "$SADMIN/tmp/$(hostname -s).lock"

    Args Optionnal: 
        errmsg: Default value is True (Show message/error)
                False, when you want no message, error or content of lock file to be displayed.
                Use if don't want any message or error message written to log or screen.
                Base your logic only on the return value and built and display your own message.

    Return Value : 
            True is system is lock and False if it's not.
   
---
    


*Python library v1.1*   
*Wed Jun 17 13:47:01 2026*   
