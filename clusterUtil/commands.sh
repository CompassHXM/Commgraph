write fab.cfg, server_information
fab all hello
fab all build
== Prepare
write properties/benchmark/twitter.properties
cp data/amazon/amazon0302_180000.plan.json ./plan.json
fab once updateBenchCfg && fab all prepare && fab once load

#make & cp ./dataManufacture/metis-5.1.0/.../gpmetis into ./

== Load
fab once load
#
ant hstore-benchmark -Dproject=twitter -Dglobal.hasher_plan=plan.json -Dglobal.hasher_class=edu.brown.hashing.TwoTieredRangeHasher -Dnoshutdown=true -Dnoexecute=true -Dsite.txn_restart_limit_sysproc=100 -Dsite.jvm_asserts=false -Dsite.commandlog_enable=false -Dsite.exec_db2_redirects=false -Dsite.exec_early_prepare=false -Dsite.exec_force_singlepartitioned=true -Dsite.markov_fixed=false -Dsite.planner_caching=false -Dsite.specexec_enable=true -Dglobal.memory=1024 -Dclient.memory=8000 -Dsite.memory=8000

== Run Baseline 
fab once benchmark
#
ant hstore-benchmark -Dproject=twitter -Dglobal.hasher_plan=plan.json -Dglobal.hasher_class=edu.brown.hashing.TwoTieredRangeHasher -Dnostart=true -Dnoloader=true -Dnoshutdown=true -Dclient.duration=60000 -Dclient.interval=1000 -Dclient.txnrate=6000  -Dclient.threads_per_host=5 -Dclient.blocking_concurrent=30 -Dclient.output_results_csv=results.csv -Dclient.output_interval=true -Dsite.planner_caching=false -Dclient.txn_hints=false -Dsite.exec_early_prepare=false -Dclient.output_basepartitions=true -Dglobal.memory=1024 -Dclient.memory=8000 -Dsite.memory=8000 -Dclient.count=1 -Dclient.hosts="localhost"

== Run Monitor && Gen transactions-partition-*.log
fab once monitor
ant hstore-benchmark -Dproject=twitter -Dglobal.hasher_plan=plan.json -Dglobal.hasher_class=edu.brown.hashing.TwoTieredRangeHasher -Dnostart=true -Dnoloader=true -Dnoshutdown=true -Dclient.interval=1000 -Dclient.txnrate=10000 -Dclient.threads_per_host=8 -Dclient.blocking_concurrent=30 -Dclient.output_results_csv=results.csv -Dclient.output_interval=true -Dsite.planner_caching=false -Dclient.txn_hints=false -Dsite.exec_early_prepare=false -Delastic.run_monitoring=true -Delastic.update_plan=false -Dglobal.memory=1024 -Dclient.memory=8000 -Dsite.memory=8000 -Delastic.exec_reconf=false -Delastic.delay=20000 -Dclient.count=1 -Dclient.hosts="localhost"

## Monitor file, transactions-partition-*.log needed
== Gen E-store Greedy-ext: Plan_out.json

ant affinity -Dproject=twitter -Dglobal.hasher_plan=plan.json -Dglobal.hasher_class=edu.brown.hashing.TwoTieredRangeHasher -Delastic.run_monitoring=false -Delastic.update_plan=true -Delastic.exec_reconf=false -Delastic.max_load=19000 -Delastic.algo=greedy-ext -Delastic.max_partitions_added=6 -Delastic.topk=1000 -Dclient.memory=4096

== Run E-store Greedy-ext:
swap plan.json and plan_out.json
fab once updateBenchCfg
fab once prepare
Load & Run baseline again

== Gen Metis with imbalance_load: Plan_out.json

ant affinity -Dproject=twitter -Dglobal.hasher_plan=plan.json -Dglobal.hasher_class=edu.brown.hashing.TwoTieredRangeHasher -Delastic.run_monitoring=false -Delastic.update_plan=true -Delastic.exec_reconf=false -Delastic.imbalance_load=1.5 -Delastic.algo=metis -Delastic.max_partitions_added=6 -Dclient.memory=4096

== Run Metis:
swap plan.json and plan_out.json
Load & Run baseline again


== Run commgraph
write properties/twitter.properties ./data/amazon.0302.txt.new 
Prepare
Load & run baseline again

== others:
fab all runCmd:command="ant clean"

### remember that $max_user_id in properties file need strictly less than max_id in json file!!!!