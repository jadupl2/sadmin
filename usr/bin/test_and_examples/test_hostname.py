#! /usr/bin/env python3
import os, sys, socket

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
