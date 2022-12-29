# encoding=utf-8
# Generated by cpy
# 2022-12-26 09:21:00.829332
import os, sys
from sys import stdin, stdout

nagios_probe = ''
nagios_warn = 85
nagios_critical = 95

def run(link, cli_args):
	pass
	gs = globals()
	opt = ''

	_cpy_r_0 = _cpy_l_1 = cli_args
	if type(_cpy_r_0).__name__ == 'dict': _cpy_b_3=True; _cpy_l_1=_cpy_r_0.iterkeys()
	else: _cpy_b_3=False;
	for _cpy_k_2 in _cpy_l_1:
		if _cpy_b_3: arg=_cpy_r_0[_cpy_k_2]
		else: arg=_cpy_k_2
		pass

		if opt=='' and arg.startswith('-'):
			pass
			opt = arg
		else:
			pass

			# {{{ switch: opt
			_continue_1 = False
			while True:
				if False or ((opt) == '-n'):
					pass
					opt = ''
					gs['nagios_probe'] = arg
					break
				if False or ((opt) == '-w'):
					pass
					gs['nagios_warn'] = arg
					opt = ''
					break
				if False or ((opt) == '-c'):
					pass
					gs['nagios_critical'] = arg
					opt = ''
					break
				### default
				opt = ''
				break
				break
				if _continue_1:
					continue
			# }}} switch

	try:
		pass
		resp = link.request('info', [])

		if nagios_probe=='info':
			pass
			nagios_info(resp)

		if nagios_probe=='dbsize':
			pass
			nagios_dbsize(resp)

		if nagios_probe=='replication':
			pass
			nagios_replication(resp)

		if nagios_probe=='write_read':
			pass
			nagios_write_read(link)
	except Exception , e:
		pass
		sys.stderr.write((str(e) + '\n'))
		exit(2)
	exit(0)

def nagios_info(resp):
	pass
	is_val = False
	i = 1

	while i<len(resp.data):
		pass
		s = resp.data[i]

		if is_val:
			pass
			s = ('	' + s.replace('\n', '\n	'))
		print s
		is_val = not (is_val)
		pass
		i += 1

def nagios_probe_check(resp):
	pass
	next_val = False
	ret = ''
	i = 1

	while i<len(resp.data):
		pass
		s = resp.data[i]

		if next_val:
			pass
			s = s.replace('\n', '\n	')
			next_val = not (next_val)
			ret += s

		if s==nagios_probe:
			pass
			next_val = not (next_val)
		pass
		i += 1
	return ret

def nagios_dbsize(resp):
	pass
	dbsize = nagios_probe_check(resp)

	if long(dbsize)>long(nagios_critical):
		pass
		print ((('CRITICAL: dbsize ' + str(dbsize)) + ' larger than ') + str(nagios_critical))
		exit(2)
	elif long(dbsize)>long(nagios_warn):
		pass
		print ((('WARN: dbsize ' + str(dbsize)) + ' larger than ') + str(nagios_warn))
		exit(1)
	else:
		pass
		print ((('OK: dbsize ' + str(dbsize)) + ' less than ') + str(nagios_critical))
		exit(0)

def nagios_replication(resp):
	pass
	replication = nagios_probe_check(resp)
	replication = replication.replace('slaveof', '\nslaveof')

	if replication.find('DISCONNECTED')>0:
		pass
		print ('CRITICAL: ' + replication)
		exit(2)
	elif ((replication.find('COPY')>0 or replication.find('INIT')>0) or replication.find('OUT_OF_SYNC')>0):
		pass
		print ('WARN: ' + replication)
		exit(1)
	elif replication.find('SYNC')>0:
		pass
		print ('OK: ' + replication)
		exit(0)
	else:
		pass
		print ('WARN, is replication configured? Status: ' + replication)
		exit(1)

def nagios_write_read(link):
	pass
	import datetime
	test_date = datetime.datetime.now().strftime("%Y%m%d%H%M")
	test_key = ('write_read_test_key' + str(test_date))
	resp = link.request('set', [test_key, test_key])
	resp = link.request('get', [test_key])
	resp_del = link.request('del', [test_key])

	if resp.data==test_key:
		pass
		print ('OK: ' + str(resp.data))
		exit(0)
	else:
		pass
		print ('WRITE_READ failed: ' + str(resp.data))
		exit(2)