import ipcalc
ip='192.168.1.1'
subnet='25'
for x in ipcalc.Network(ip+'/'+subnet):
    print str(x)
