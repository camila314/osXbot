import level, struct

t = level.Level.downloadLevel('c','65143356')

xbot_poses = 'fps: 60\n'
count = -1
last = 'off'
for block in t.blocks:
	if str(block['blockid']) != '1817':
		continue
	else:
		count+=1
	if block['count']=='-1' and count==0:
		continue

	if block['count']=='-1': # release
		if last=='off':
			continue
		else:
			last = 'off'
			xbot_poses += str(int(struct.pack('!f',float(block['x_position'])).hex(),16))+'\n'

	if block['count']=='1':
		if last=='on':
			continue
		else:
			last = 'on'
			xbot_poses += str(int(struct.pack('!f',float(block['x_position'])).hex(),16))+' '
open('out.txt','w').write(xbot_poses)