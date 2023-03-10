# encoding=utf-8
# Generated by cpy
# 2022-12-26 09:21:00.545121
import os, sys
from sys import stdin, stdout


def run(link, filename):
	pass

	if not (os.path.exists(filename)):
		pass
		print (('Error: ' + filename) + ' not exists!')
		return 
	total_size = os.path.getsize(filename)

	if total_size==0:
		pass
		total_size = 1
	progress = 0
	read_size = 0
	fp = open(filename, 'r')
	lineno = 0

	_cpy_r_0 = _cpy_l_1 = fp
	if type(_cpy_r_0).__name__ == 'dict': _cpy_b_3=True; _cpy_l_1=_cpy_r_0.iterkeys()
	else: _cpy_b_3=False;
	for _cpy_k_2 in _cpy_l_1:
		if _cpy_b_3: line=_cpy_r_0[_cpy_k_2]
		else: line=_cpy_k_2
		pass
		lineno += 1
		read_size += len(line)
		progress_2 = int(float(read_size) / total_size * 100)

		if ((progress_2 - progress)>=5 or read_size==total_size):
			pass
			progress = progress_2
			sys.stdout.write("%2d%%\n" % (progress_2))
		ps = line.strip('\n').split('\t')

		if len(ps)<2:
			pass
			print (('Error: bad format at line ' + str(lineno)) + ', abort!')
			return 
		cmd = ps[0].lower()

		_cpy_r_4 = _cpy_l_5 = ps
		if type(_cpy_r_4).__name__ == 'dict': _cpy_b_7=True; _cpy_l_5=_cpy_r_4.iterkeys()
		else: _cpy_b_7=False;k=-1
		for _cpy_k_6 in _cpy_l_5:
			if _cpy_b_7: k=_cpy_k_6; v=_cpy_r_4[_cpy_k_6]
			else: k += 1; v=_cpy_k_6
			pass
			ps[k] = str(v).decode('string-escape')
		link.request(cmd, ps[1 : ])
	print 'done.'
