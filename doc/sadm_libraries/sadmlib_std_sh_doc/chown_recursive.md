### (function)  chown_recursive   

#### `def chown_recursive(path, user, group):`
   
   
        Change the owner and group of a file or directory recursively.
        
        Args:
            path (str)  :   Full path of the file or directory to change.
            user (str)  :   New owner.
            group (str) :   New group.

        Returns:
            returncode (int):   0 When command executed with success (even if file doesn't exist)
                                1 When error occurred (Permission Error)
   
---
    


*Python library v1.1*   
*Wed Jun 17 13:47:01 2026*   
