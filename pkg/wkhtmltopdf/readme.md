# wkhtmltopdf

------

## How to install wkhtmltopdf

### Ubuntu, Debian, Raspbian, Linux Mint, ...

```  
# apt-get install wkhtmltopdf 
```


### RedHat, CentOS, Fedora 

The package **wkhtmltopdf** is not include in the base distribution.  
- On V7, we need to install it from the (EPEL repository) [https://fedoraproject.org/wiki/EPEL].  
- If not done already, you need to add the EPEL repository subsviption to your system.
  - yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
``` 
Version 7s
# yum install --enablerepo=epel wkhtmltopdf 
OR
Install with version include in this directory.
# cd $SADMIN/pkg/wkhtmltopdf
# dnf install ./wkhtmltox-0.12.6-1.centos7.x86_64.rpm
```  

- On V8, the package is not yet included in EPEL. 
  - You need to download it from the (wkhtmltopdf Home page) [https://wkhtmltopdf.org/]  
  - Or install with version include in this directory.
``` 
# cd $SADMIN/pkg/wkhtmltopdf
# yum install ./wkhtmltox-0.12.6-1.centos8.x86_64.rpm 
```  