import struct, level, msgport
a = level.Level("pickup")
data = open(input("xbot file:").strip(),'r').read().split('\n')
for d in data:
	hold, release = d.split(' ')

	hold = struct.unpack('!f',bytes.fromhex(hex(int(hold))[2:]))[0]
	release = struct.unpack('!f',bytes.fromhex(hex(int(release))[2:]))[0]

	a.addBlock(1817, hold, 100, is_active_trigger_type=1, item_id=0, count=1)
	a.addBlock(1817, release, 150, is_active_trigger_type=1, item_id=1, count=-1)
msgport.uploadToGD(a)