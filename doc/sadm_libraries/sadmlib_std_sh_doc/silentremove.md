### (function)  silentremove   

#### `def silentremove(filename : str):`
   
   
        Silently remove the file received as parameter, without error if file doesn't exist. 
        
        Args:
            filename (str)  :   Full path of the file to delete.

        Returns:
            returncode (int):   0 When command executed with success (even if file doesn't exist)
                                1 When error occurred (Permission Error)
   
---
    


*Python library v1.1*   
*Wed Jun 17 13:47:01 2026*   
