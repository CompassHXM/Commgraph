from __future__ import with_statement
from fabric.api import *
from fabric.operations import *
from fabric.contrib.console import confirm
import json
import time

def _updater(str,key,newvalue):
    lines = str.split("\n")
    n = len(lines)
    for i in range(n):
        piece = lines[i].split("=")
        if len(piece) == 2 and piece[0].split()[0] == key:
            lines[i] = piece[0] + " = " + newvalue
            break
    return "\n".join(lines)

def updateFab():
    print "Updating Local Fabfile (by fab.cfg)..."
    with open("fab.cfg","r") as reader:
        cfg_str = reader.read()
        cfg_dict = json.loads(cfg_str)
        with open("fabfile.py","r+") as modifier:
            filestr = modifier.read()
            if "project_name" in cfg_dict:
                filestr = _updater(filestr,"project_name",cfg_dict["project_name"])
            if "env.user" in cfg_dict:
                filestr = _updater(filestr,"env.user",cfg_dict["env.user"])
            if "env.key_filename" in cfg_dict:
                filestr = _updater(filestr,"env.key_filename",cfg_dict["env.key_filename"])
            if "env.parallel" in cfg_dict:
                filestr = _updater(filestr,"env.parallel",cfg_dict["env.parallel"])
            if "hstore_home" in cfg_dict:
                filestr = _updater(filestr,"hstore_home",cfg_dict["hstore_home"])
            if "hostfile" in cfg_dict:
                filestr = _updater(filestr,"hostfile",cfg_dict["hostfile"])
            if "clients" in cfg_dict:
                # default add localhost to clients
                if len(cfg_dict["clients"]) == 0:
                	newstr = '[]'
                else:
                	newstr = '["' + '","'.join(cfg_dict["clients"]) +  '"]'
                filestr = _updater(filestr,"clients",newstr)
            if "servers" in cfg_dict:
            	if len(cfg_dict["servers"]) == 0:
            		newstr = '[]'
            	else:
                	newstr = '["' + '","'.join(cfg_dict["servers"]) + '"]'
                filestr = _updater(filestr,"servers",newstr)
            modifier.seek(0)
            modifier.truncate()
            modifier.write(filestr)
    print "Updating Done."

def updateCfg():
	local("fab updateCfg")

def testall():
	updateFab()
	local("fab updateCfg")
        local("fab build")
	benchmark_s = "fab autoBenchmark:log_title='{0}'".format("test0")
	local(benchmark_s)


