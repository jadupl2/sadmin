#! /bin/python3
import ipaddress
SUBNET='192.168.1.0/24'

NET4 = ipaddress.ip_network(SUBNET)

nbaddr = NET4.num_addresses
print("Number of adresses in %s : %d" % (SUBNET,nbaddr))

netmask = NET4.netmask
print("Netmask is %s" % (netmask))

# Usable IP
print("\nUsable IP")
for x in NET4.hosts(): print(x)  

# Adresses in Network
print("\nAdresses in Network")
for addr in NET4: print(addr)

addr4 = ipaddress.ip_address('192.168.1.20')
addr4 in ipaddress.ip_network('192.168.1.0/24')
#True
addr4 in ipaddress.ip_network('192.0.3.0/24')
#False
