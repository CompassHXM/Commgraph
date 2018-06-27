from __future__ import with_statement
from fabric.api import *
from fabric.operations import *
from fabric.contrib.console import confirm
import json
import sys

"""             Settings are Here                     """
required_settings = \
    {"hstore_home":str,"project_name":str,"hostfile":str,\
    "env.user":str,"env.key_filename":str,"env.parallel":bool,\
    "clients":list,"servers":list,"bench_tag":str,"result_dir":str\
    "command_hello":str,"command_prepare":str,"command_load":str,"command_run":str}


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
    
    cfg_dict["remote_hosts"] = list(set(cfg_dict["clients"] + cfg_dict["servers"]))
    cfg_dict["all_hosts"] = cfg_dict["remote_hosts"] + ["localhost"]
    cfg_dict["command_run"] += "-Dclient.count=%d -Dclient.hosts=\"%s\" | tee %s.log"\
                        % ( len(cfg_dict["clients"]), \
                            str(cfg_dict["clients"])[1:-1].replace("'",'').replace(', ',';'), \
                            cfg_dict["bench_tag"] )
    return cfg_dict

def build():
	cfg_dict = _load_configuration()
	with cd(cfg_dict["hstore_home"]):
		run("ant build")

def restart():
	cfg_dict = _load_configuration()
	run("killall java")
	with cd(cfg_dict["hstore_home"]):
		run(cfg_dict["command_prepare"])
	local(cfg_dict["command_load"])

def run():
	cfg_dict = _load_configuration()
	local(cfg_dict["command_run"])
	lcd(cfg_dict["hstore_home"])
	local("mkdir -p %s" % cfg_dict["result_dir"])
	local("mv %s.log %s" % (cfg_dict["bench_tag"],cfg_dict["result_dir"]) )

def updateFile(file=''):
	if file[-1] == "/":
    	file = file[:-1]

    if len(file) == 0:
        error("Error: please spcify path to file name(updateFile:file='file string').")
    
    if file[0] == '/' or file[0] == '~':
    	# absolute path
    	directory = file.rsplit('/', 1)[0]
    	file = file.rsplit('/', 1)[1]
    else:
    	# relative path
    	directory = sys.path[0] + file.rsplit('/', 1)[0]
    	file = file.rsplit('/', 1)[1]

    print("Updating file %s..." % file) 
    with settings(warn_only=True):
        if run("test -d %s" % directory).failed:
            print("Target host don't have the directory. Create it frist...")
            run("mkdir -p %s" % directory)

    path = directory + "/" + file
    put(path,path)
