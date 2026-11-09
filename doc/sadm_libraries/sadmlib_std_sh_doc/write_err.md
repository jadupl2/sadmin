### (function)  write_err   

#### `def write_err (wline, lf=True ):`
   
   
        Write a string in error log file and/or the screen.
        Depend on log_type: [B]oth,[L]og,[S]creen.
        
        Args:
            wline (str) : Line to write to log (with time stamp)
                          When writing to error (and log) file, all "\n" are replace by " " in wline 
                          (Except for EOL).
                          Line to write to screen untouched (with no time stamp)
            lf (boolean): Include or not a line feed at EOL on the screen.
                          True or False (True Default).
        Returns:
            None
   
---
    


*Python library v1.1*   
*Wed Jun 17 13:47:01 2026*   
