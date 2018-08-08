from __future__ import with_statement
from fabric.api import *
from fabric.operations import *
from fabric.contrib.console import confirm
import json
import os.path

"""			 Settings are Here					 """
required_settings = \
	{"hstore_home":str,"project_name":str,"hostfile":str,\
	"env.user":str,"env.key_filename":str,"env.parallel":bool,\
	"clients":list,"servers":list,"bench_tag":str,"result_dir":str,\
	"partitions_per_site":int,"partition_num":int,\
	"command_hello":str,"command_prepare":str,"command_load":str,"command_run":str,"command_monitor":str}

def clients():
	"""Prefix, Required: select clients to run commands"""
	cfg_dict = _load_configuration()
	env.user = cfg_dict['env.user']
	env.key_filename = cfg_dict['env.key_filename']
	env.parallel = cfg_dict['env.parallel']
	env.hosts = cfg_dict['clients']

def all():
	"""Prefix, Required: select all hosts to run commands"""
	cfg_dict = _load_configuration()
	env.user = cfg_dict['env.user']
	env.key_filename = cfg_dict['env.key_filename']
	env.parallel = cfg_dict['env.parallel']
	env.hosts = cfg_dict['all_hosts']

def remote():
	"""Prefix, Required: select remote hosts to run commands"""
	cfg_dict = _load_configuration()
	env.user = cfg_dict['env.user']
	env.key_filename = cfg_dict['env.key_filename']
	env.parallel = cfg_dict['env.parallel']
	env.hosts = cfg_dict['remote_hosts']

def once():
	"""Prefix, Required: select only localhost to run commands"""
	cfg_dict = _load_configuration()
	env.user = cfg_dict['env.user']
	env.key_filename = cfg_dict['env.key_filename']
	env.parallel = cfg_dict['env.parallel']
	env.hosts = cfg_dict['localhost']

def hello():
	"""Run command hello in selected cluster"""
	cfg_dict = _load_configuration()
	run(cfg_dict["command_hello"])

def _encodes(item):
	if type(item) == unicode:
		return item.encode('utf-8')
	elif type(item) == list:
		nitem = []
		for i in item:
			nitem.append(_encodes(i))
		return nitem
	elif type(item) == dict:
		nitem = {}
		for k,v in item.items():
			nitem[_encodes(k)] = _encodes(v)
		return nitem
	else:
		return item

def _load_configuration():
	if hasattr(env,"cfg_dict"):
		return env.cfg_dict

	with open("fab.cfg","r") as cfg_file:
		cfg_str = cfg_file.read()
		cfg_dict = _encodes(json.loads(cfg_str))
		for required_ss,the_type in required_settings.items():
			if required_ss not in cfg_dict:
				error(required_ss + " is required in configuration file 'fab.cfg'.")
			if type(cfg_dict[required_ss]) != the_type:
				error("%s should be %s instead of %s in configuration file 'fab.cfg'."\
					% (required_ss, the_type, type(cfg_dict[required_ss])))

	cfg_dict["project_propt"] = cfg_dict["hstore_home"]\
						+ "/properties/benchmarks/%s.properties" % cfg_dict["project_name"]

	lh = local("echo $(ifconfig | grep \"inet addr\" | head -n 1 | cut -d':' -f 2 | cut -d' ' -f1)", capture=True)

	cfg_dict["localhost"] = [lh]
	cfg_dict["remote_hosts"] = list(set(cfg_dict["clients"] + cfg_dict["servers"]))
	cfg_dict["all_hosts"] = cfg_dict["remote_hosts"] + [lh]
	
	# no local host as clients 
	client_suffix = " -Dclient.count=%d -Dclient.hosts=\"%s\" " \
					% ( len(cfg_dict["clients"]), \
					str(cfg_dict["clients"])[1:-1].replace("'",'').replace(', ',';') )

	cfg_dict["command_run"] += client_suffix + " | tee %s.log" % cfg_dict["bench_tag"]
	cfg_dict["command_monitor"] += client_suffix

	env.cfg_dict = cfg_dict
	return cfg_dict

def build():
	"""build h-store project"""
	cfg_dict = _load_configuration()
	with cd(cfg_dict["hstore_home"]):
		run("ant build")

def _gen_cluster_cfg():
	"""generate "cluster.cfg" """
	cfg_dict = _load_configuration()
	# we say that localhost as a server
	cluster_cfg_file = cfg_dict["hstore_home"] + "/" + cfg_dict["hostfile"]
	pps = cfg_dict["partitions_per_site"]
	if pps == 1:
		with open(cluster_cfg_file,"w") as ccf:
			sitei = 0
			#print >> ccf, cfg_dict["localhost"][0] + ":0:0"
			for server in cfg_dict["servers"]:
				if sitei >= cfg["partition_num"]:
					break
				print >> ccf, "%s:%d:%d" % (server, sitei, sitei)
				sitei = sitei + 1
	elif pps > 0:
		with open(cluster_cfg_file,"w") as ccf:
			sitei = 0
			#endpid = pps-1
			#print >> ccf, cfg_dict["localhost"][0] + ":0:0-%d" % (pps-1)
			for server in cfg_dict["servers"]:
				stpid = sitei*pps
				if stpid >= cfg_dict["partition_num"]:
					print "\n[Warning]: some servers are not assgined to work\n"
					break

				endpid = (sitei+1)*pps-1
				if endpid >= cfg_dict["partition_num"]:
					endpid = cfg_dict["partition_num"] - 1
				print >> ccf, "%s:%d:%d-%d" % (server, sitei, sitei*pps, endpid)
				sitei = sitei + 1

def updateBenchCfg():
	"""update plan.json, cluster.cfg, twitter.properties """
	cfg_dict = _load_configuration()
	if len(env.hosts) > 1:
		error('could only run at prefix "once"')

	_gen_cluster_cfg()
	if "update_files" in cfg_dict:
		for f in cfg_dict["update_files"]:
			execute(updateFile, hosts=cfg_dict["remote_hosts"], newfile=f)

def prepare():
	"""reset env and run prepare on machines"""
	cfg_dict = _load_configuration()
	with settings(warn_only=True), cd(cfg_dict["hstore_home"]):
		run("killall java")
		run("rm transactions-partition-*.log")
		run("rm monitoring-*.tar.gz")
		run("rm interval-partition-*.log")

	with cd(cfg_dict["hstore_home"]):
		run(cfg_dict["command_prepare"])

def foo():
	"""list the ip"""
	local("echo $(ifconfig | grep \"inet addr\" | head -n 1 | cut -d':' -f 2 | cut -d' ' -f1)")

def load():
	"""run command load on local machine"""
	cfg_dict = _load_configuration()
	with lcd(cfg_dict["hstore_home"]):
		local(cfg_dict["command_load"])

def benchmark():
	"""run benchmark on local machine"""
	cfg_dict = _load_configuration()
	with lcd(cfg_dict["hstore_home"]):
		local(cfg_dict["command_run"])
		local("mkdir -p %s" % cfg_dict["result_dir"])
		local("mv %s.log %s" % (cfg_dict["bench_tag"],cfg_dict["result_dir"]) )

def monitor():
	"""run monitor on local machine"""
	cfg_dict = _load_configuration()
	with lcd(cfg_dict["hstore_home"]):
		local(cfg_dict["command_monitor"])

def updateFile(newfile=''):
	"""update a specific file"""
	if len(newfile) == 0:
		error("Error: please spcify path to file to update(updateFile:newfile='newfile string').")
	newfile = os.path.realpath(newfile)
	directory = os.path.dirname(newfile)

	local('echo Updating new file "%s"...' % newfile)
	run("mkdir -p %s/" % directory)

	put(newfile,newfile)

