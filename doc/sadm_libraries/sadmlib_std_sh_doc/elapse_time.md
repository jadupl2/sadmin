### (function)  elapse_time   

#### `def elapse_time(wdate1 : str ,wdate2 : str) -> str:`
   
   
        Calculate elapse time between date1 (YYYY.MM.DD HH:MM:SS) and date2 (YYYY.MM.DD HH:MM:SS)
        Date 1 MUST be greater than date 2  (wdate1 = End date/time,  wdate2 = Start date/time )
        
        Args:
            wdate1 (str) :  End date/time of the process.
                            Date got to be in format 'YYYY.MM.DD HH:MM:SS'
            wdate2 (str) :  Start date/time of the process.
                            Date got to be in format 'YYYY.MM.DD HH:MM:SS'

        Return:
            welapse (str):  Return the elapse time in hours, minutes and seconds 'HH:MM:SS'.
                            (Ex : '03:45:54') 
   
---
    


*Python library v1.1*   
*Wed Jun 17 13:47:01 2026*   
