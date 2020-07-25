from __future__ import with_statement
from fabric.api import *
from fabric.operations import *
from fabric.contrib.console import confirm
import json

"""             Settings are Here                     """
project_name='tpcc'
env.user='root'
env.key_filename='/root/.ssh/hstore.pem'
env.parallel=True
hstore_home='/root/h-store-main'
hostfile='cluster.cfg'
clients=[]
servers=["192.168.0.84","192.168.0.13"]


"""             Global Values                        """
project_propt = hstore_home + "/properties/benchmarks/%s.properties" % project_name
default_propt = hstore_home + "/properties/default.properties"
remote_hosts = clients + servers
all_hosts = remote_hosts + ['localhost']

"""           Here are Usage Part                        """

"""fab -H localhost,192.168.1.202,192.168.1.203 hostType"""
def hostType():
    run('uname -s')

"""fab hello:name=holbrook"""
"""Hello holbrook"""
def hello(name="world"):
    print("Hello %s!" % name)

def filePath():
    run('pwd')
    remote_dir = '~/code/h-store'
    with cd(remote_dir):
        run('ls')


"""          Below are working code                   """


""" File Updating """
def _upf(path_to_file=''):
    if len(path_to_file) == 0:
        print("Error: please spcify path to file name.")
        print("Usage: fab updateclient:path_to_file=your/path/to/file")
        abort()

    pf = path_to_file.rsplit('/',1)
    if len(pf) <= 1:
        print("Warn: No directory specified, using home directory instead.")
        pf.insert(0,'~')
    path_to_file = pf[0] + "/" + pf[1]

    print("[_upf]:  Updating file %s..." % path_to_file ) 
    with settings(warn_only=True):
        if run("test -d %s" % pf[0]).failed:
            print("Target host don't have the directory. Create it frist...")
            run("mkdir %s" % pf[0])
    put(path_to_file,path_to_file)

@hosts(remote_hosts)
def updateFile(path_to_file=''):
    _upf(path_to_file)

@hosts(clients)
def updateClients(path_to_file=''):
    _upf(path_to_file)


""" Commends run """
@hosts(all_hosts)
def runAll(commend='uname -a'):
    run(commend)

@hosts(remote_hosts)
def runRemote(commend='uname -a'):
    run(commend)

@hosts(all_hosts)
def prepare():
    with cd(hstore_home):
        precmd = "ant hstore-prepare -Dproject=%s -Dhosts=" % project_name + hostfile
        run(precmd)

@hosts(all_hosts)
def build():
    with cd(hstore_home):
        run("ant build")

@hosts(all_hosts)
def catalog():
    with cd(hstore_home):
        run("ant catalog-info -Dproject=%s" % project_name)


""" Run Script """

""" Every single configuration have format "key = value" in a WHOLE SINGLE line. """
def _updater(str,key,newvalue):
    lines = str.split("\n")
    n = len(lines)
    for i in range(n):
        piece = lines[i].split("=")
        if len(piece) == 2 and piece[0].split()[0] == key:
            lines[i] = piece[0] + " = " + newvalue
            break
    return "\n".join(lines)

def _tpcc_cfg(cfg_dict,filestr):
    if "neworder_only" in cfg_dict:
        filestr = _updater(filestr,"neworder_only",cfg_dict["neworder_only"])
    if "neworder_multip_mix" in cfg_dict:
        filestr = _updater(filestr,"neworder_multip_mix",cfg_dict["neworder_multip_mix"])
    if "neworder_multip_remote" in cfg_dict:
        filestr = _updater(filestr,"neworder_multip_remote",cfg_dict["neworder_multip_remote"])
    if "neworder_multip_remote_mix" in cfg_dict:
        filestr = _updater(filestr,"neworder_multip_remote_mix",cfg_dict["neworder_multip_remote_mix"])
    return filestr

def _twitter_cfg(cfg_dict,filestr):
    return filestr

def _default_cfg(cfg_dict,filestr):
    if "client.count" in cfg_dict:
        filestr = _updater(filestr,"client.count",cfg_dict["client.count"])
    if "client.threads_per_host" in cfg_dict:
        filestr = _updater(filestr,"client.threads_per_host",cfg_dict["client.threads_per_host"])
    if "client.txnrate" in cfg_dict:
        filestr = _updater(filestr,"client.txnrate",cfg_dict["client.txnrate"])
    return filestr


def updateCfg():
    print "[updateCfg]:  Updating \"" + project_propt + "\" in All Sites (by fab.cfg)....\n"
    with open("fab.cfg", "r") as reader:
        cfg_str = reader.read()
        cfg_dict = json.loads(cfg_str)
        with open(project_propt, "r+") as modifier:
            filestr = modifier.read()
            if project_name == "tpcc":
                filestr = _tpcc_cfg(cfg_dict, filestr)
            elif project_name == "twitter":
                filestr = _twitter_cfg(cfg_dict, filestr)
            else:
                print "[updateCfg]:  Warning\nUnknown project name! Skipped Configuration updating..."
                    
            modifier.seek(0)
            modifier.truncate()
            modifier.write(filestr)

        print "1 :" + ",".join(remote_hosts)
        execute(_upf, hosts = remote_hosts, path_to_file = project_propt)
    print "[updateCfg]:  Updating Done.\n"

def _parse_throughput(throughput_str):
    if throughput_str.find(":") < 0 or throughput_str.find("txn/s") < 0:
        print "[Parse Throughput]:  Error in parse %s, skipped..." % throughput_str
        return "Parse Failed."
    return str(float(throughput_str.split(":")[1].split("txn/s")[0]))

def updateCluster():
    with open("fab.cfg", "r") as reader:
        cfg_str = reader.read()
        cfg_dict = json.loads(cfg_str)
        if "partition_num" in cfg_dict and len(servers) > 0:
            partition_num = cfg_dict["partition_num"]
            partition_per_site = partition_num / float(len(servers))
            with open(hstore_home+'/'+hostfile, "w") as writer:
                for i in range(len(servers)):
                    writer.write("%s:%d:%d-%d" % (servers[i], i, i*partition_per_site, (i+1)*partition_per_site)-1)
            print "[updateCluster]:  Succeed."
        else:
            print "[updateCluster]  Warning:  No partition num or server specified, Skipped..."

def autoBenchmark(log_title=''):
    if project_name != 'tpcc':
        print "[autoBenchmark]:  Project is not TPCC, Abort..."
        return 
    print "[autoBenchmark]: Prepare for next benchmark.\n"
    execute(_upf, hosts = remote_hosts, path_to_file = hstore_home +'/'+ hostfile)

    start_time_str = time.strftime("_%m-%d-%H%M",  time.localtime(time.time()))
    log_dir = "~/log" + log_title + start_time_str
    local("mkdir %s" % log_dir)

    with open("fab.cfg", "r") as reader:
        cfg_str = reader.read()
        cfg_dict = json.loads(cfg_str)
        if "neworder_multip_remote_mix_range" in cfg_dict and "neworder_multip_mix_range" in cfg_dict:
            for muti in cfg_dict["neworder_multip_mix_range"]:
                for muti_remote in cfg_dict["neworder_multip_remote_mix_range"]:
                    print "[autoBenchmark]:  Test on (%s %s) begin now...\n" %(str(muti), str(muti_remote))
                    with open(project_propt, "r+") as modifier:
                        filestr = modifier.read()
                        filestr = _updater(filestr,"neworder_multip_mix",muti)
                        filestr = _updater(filestr,"neworder_multip_remote_mix",muti_remote)
                        modifier.seek(0)
                        modifier.truncate()
                        modifier.write(filestr)
                    execute(_upf, hosts = remote_hosts, path_to_file = project_propt)
                    execute(prepare, hosts = all_hosts)
                    with lcd(hstore_home):
                        time_str = time.strftime("_%m-%d-%H%M",  time.localtime(time.time()))
                        log_file = log_dir + "/{0}-{1}{2}.log".format(muti,muti_remote,time_str)
                        command = "ant hstore-benchmark -Dproject=%s | tee " % project_name + log_file
                        with settings(warn_only=True):
                            report_str = "{0}\t{1}\t".format(muti,muti_remote)

                            failed = True
                            for i in range(3):
                                if not local(command).failed:
                                    if len( local('cat %s | grep "BUILD SUCCESSFUL"' % log_file, capture=True)) > 0:
                                        failed = False
                                        break
                                print "[autoBenchmark]:  Test on (%s) failed, try again in %d time....\n" % (report_str,i+1)
                            if failed:
                                print "[autoBenchmark]:  Test on (%s) failed more than 3 times, skiped....\n" % report_str
                                report_str += "Failed"
                            else:
                                print "[autoBenchmark]:  Test on (%s) succeed.\n" % report_str
                                report_str += _parse_throughput( local('cat %s | grep "Throughput"' % log_file, capture=True) )
                            local("echo %s >> ~/report%s.log" % (report_str,start_time_str) )

