### (function)  lock_status   

#### `def lock_status(fname, errmsg=True):`
   
   

### Description :   

This function is used to check if a system 'lock_file' exist for the specified hostname.
When the lock file exist "${SADMIN}/tmp/$(hostname -s).lock" for a system, no 
monitoring error or warning is reported (No alert, No notification) to the user
until the lock file is deleted. The SADMIN server will not trigger any remote command to
that system until the lock is removed.
 
If the lock file exist, this function check the creation date & time of it.
When the lock file time stamp exceed the number of seconds set by 'lock_timeout' 
then 'lock_file' file is automatically remove by this function and exit with a return
code of 0, as if the lock file didn't exist.
       
### Argument(s) :       

Args: 
    fname : Name of the system you want to remove the lock file (hostname -s, not FQDN).
            The full path name of the lock file is "$SADMIN/tmp/$(hostname -s).lock"

Args Optionnal: 
    errmsg: Default value is True
            Use if don't want any message or error message written to log or screen.
            Base your logic only on the return value and built and display your own message.

### Return(s) :   
False) System is not lock.
True)  System is lock.

### Example :   

```bash
    # Check if System is Locked.
    if sa.lock_status(wname) :                                      # System is Lock
        sa.write_err("[ WARNING ] System '%s' is currently lock." % (wname))
        sa.stop(1)
        exit(1)
```
    
   
---
    


*Python library v1.1*   
*Wed Jun 17 13:47:01 2026*   
