#! /usr/bin/env python3
import os, sys, socket



sadm = socket.gethostbyname('raspi3.maison.ca')
print ("sadm=%s\n" % (sadm))
digit1=sadm.split('.')[0]                                               # 1st Digit=127 = Invalid
print ("digit1=%s\n" % (digit1))
if (digit1 == "127"):
    print ("SADMIN server name can't resolve to localhost (%s)" %(sadm))
    print ("SADMIN clients would not be able to get to the SADMIN Server")
    print ("SADMIN Server name must resolve to an IP other than in 127.0.0.0/24 subnet")
    print ("You may need to press CTRL-C to abort installation and correct the situation")
    print ("Once resolve, just execute the setup program again")



sfqdn = socket.getfqdn()
hostip = socket.gethostbyname(sfqdn)
uhost = os.uname()[1]
hostname1 = socket.gethostname()

print ("\nsfqdn=%s \nhostip=%s \nuhost=%s \nhostname=%s"  % (sfqdn,hostip,uhost,hostname1))

hostinfo = socket.gethostbyaddr(hostname1)
print ("\nhostinfo1=%s "  % (hostinfo[0]))
print ("\nhostinfo2=%s "  % (hostinfo[1]))
print ("\nhostinfo3=%s "  % (hostinfo[2]))


if socket.gethostname().find('.')>=0:
	name=socket.gethostname()
else:
	name=socket.gethostbyaddr(socket.gethostname())[0]
print ("\nname = %s" % (name))
