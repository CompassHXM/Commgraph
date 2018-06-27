from __future__ import with_statement
from fabric.api import *
from fabric.operations import *
from fabric.contrib.console import confirm
import json

"""             Settings are Here                     """
required_settings = 
	["hstore_home","project_name","hostfile",
	"env.user","env.key_filename","env.parallel",
	"clients","servers",
	"command_hello","command_prepare","command_load","command_run"]


"""           Here are Usage Part                        """

"""fab -H localhost,192.168.1.202,192.168.1.203 hostType"""
def hostType():
    run('uname -s')

"""fab hello:name=holbrook"""
"""Hello holbrook"""
def hello(name="world"):
    print("Hello %s!" % name)

def _error(prompt_msg):
	print("Error: %s" % prompt_msg)
	abort()

def _configuration():
	with open("fab.cfg","r") as cfg_file:
		cfg_str = cfg_file.read()
    	cfg_dict = json.loads(cfg_str)
    	for required_ss in required_settings:
    		if required_ss not in cfg_dict:
    			_error(required_ss + " is required in configuration file 'fab.cfg'.")

	env.user = cfg_dict['env.user']
	env.key_filename = cfg_dict['env.key_filename']
	env.parallel = (cfg_dict['env.parallel'].upper() == "TRUE")
	cfg_dict["project_propt"] = cfg_dict["hstore_home"] 
						+ "/properties/benchmarks/%s.properties" % cfg_dict["project_name"]

	cfg_dict["clients"] = map(lambda x: x.encode('utf-8'), cfg_dict["clients"])
	cfg_dict["servers"] = map(lambda x: x.encode('utf-8'), cfg_dict["servers"])

	cfg_dict["remote_hosts"] = cfg_dict["clients"] + cfg_dict["servers"]
	cfg_dict["all_hosts"] = cfg_dict["remote_hosts"] + ["localhost"]

	print cfg_dict



