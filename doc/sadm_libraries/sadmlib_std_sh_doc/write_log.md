### (function)  write_log   

#### `def write_log (wline, lf=True ):`
   
   
        Write a string in log file and/or the screen.
        Depend on log_type: [B]oth,[L]og,[S]creen.
        
        Args:
            wline (str) : Line to write to log (with time stamp)
                          For log file, all "\n" are replace by " " in wline (Except for EOL)
                          Line write to screen are untouched (with no time stamp)
            lf (boolean): Include or not a line feed at the EOL on screen.
                          True or False (True Default).
        Returns:
            None
   
---
    


*Python library v1.1*   
*Wed Jun 17 13:47:01 2026*   
