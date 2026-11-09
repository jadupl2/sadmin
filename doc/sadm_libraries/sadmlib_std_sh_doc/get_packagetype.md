def get_packagetype():
    
    """ Determine The Installation Package Type Of Current O/S.
        Value is returned in lowercase (rpm,deb,lpp,dmg).
        
        Args:            
            None
    
        Returns:
            package_type (str)  :   Return package type use on the system (in lowercase).
                                    rpm (Fedora,RedHat,CentOS,Alma,Rocky,...)  
                                    deb (Ubuntu,Debian,Raspbian,Mint,...)  
                                    dmg (MacOS)  
                                    lpp (Aix)  
                                    zypper (SUSE, OpenSUSE)
   
---
    


*Python library v1.1*   
*Wed Jun 17 13:47:01 2026*   
