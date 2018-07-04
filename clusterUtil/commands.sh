== Prepare

ant hstore-prepare -Dproject=twitter -Dhosts=cluster.cfg

== Gen plan.json && data.txt && data.txt.new
#dataManufacture/autogen.sh
mv plan.json to hstore_home
#make & cp ./dataManufacture/metis-5.1.0/.../gpmetis into ./

== Load

ant hstore-benchmark -Dproject=twitter -Dglobal.hasher_plan=plan.json -Dglobal.hasher_class=edu.brown.hashing.TwoTieredRangeHasher -Dnoshutdown=true -Dnoexecute=true -Dsite.txn_restart_limit_sysproc=100 -Dsite.jvm_asserts=false -Dsite.commandlog_enable=false -Dsite.exec_db2_redirects=false -Dsite.exec_early_prepare=false -Dsite.exec_force_singlepartitioned=true -Dsite.markov_fixed=false -Dsite.planner_caching=false -Dsite.specexec_enable=true -Dglobal.memory=1024 -Dclient.memory=8000 -Dsite.memory=8000

== Run Baseline 

ant hstore-benchmark -Dproject=twitter -Dglobal.hasher_plan=plan.json -Dglobal.hasher_class=edu.brown.hashing.TwoTieredRangeHasher -Dnostart=true -Dnoloader=true -Dnoshutdown=true -Dclient.duration=60000 -Dclient.interval=1000 -Dclient.txnrate=10000  -Dclient.threads_per_host=10 -Dclient.blocking_concurrent=30 -Dclient.output_results_csv=results.csv -Dclient.output_interval=true -Dsite.planner_caching=false -Dclient.txn_hints=false -Dsite.exec_early_prepare=false -Dclient.output_basepartitions=true -Dglobal.memory=1024 -Dclient.memory=8000 -Dsite.memory=8000 -Dclient.count=1 -Dclient.hosts="localhost"

== Run Monitor && Gen transactions-partition-*.log

ant hstore-benchmark -Dproject=twitter -Dglobal.hasher_plan=plan.json -Dglobal.hasher_class=edu.brown.hashing.TwoTieredRangeHasher -Dnostart=true -Dnoloader=true -Dnoshutdown=true -Dclient.interval=1000 -Dclient.txnrate=10000 -Dclient.threads_per_host=8 -Dclient.blocking_concurrent=30 -Dclient.output_results_csv=results.csv -Dclient.output_interval=true -Dsite.planner_caching=false -Dclient.txn_hints=false -Dsite.exec_early_prepare=false -Delastic.run_monitoring=true -Delastic.update_plan=false -Delastic.exec_reconf=false -Delastic.delay=20000 -Dclient.count=1 -Dclient.hosts="localhost"

## Monitor file, transactions-partition-*.log needed
== Gen E-store Greedy-ext: Plan_out.json

ant affinity -Dproject=twitter -Dglobal.hasher_plan=plan.json -Dglobal.hasher_class=edu.brown.hashing.TwoTieredRangeHasher -Delastic.run_monitoring=false -Delastic.update_plan=true -Delastic.exec_reconf=false -Delastic.max_load=26050 -Delastic.algo=greedy-ext -Delastic.max_partitions_added=6 -Delastic.topk=8000 -Dclient.memory=4096

== Run E-store Greedy-ext:
swap plan.json and plan_out.json
Load & Run baseline again

== Gen Metis with imbalance_load: Plan_out.json

ant affinity -Dproject=twitter -Dglobal.hasher_plan=plan.json -Dglobal.hasher_class=edu.brown.hashing.TwoTieredRangeHasher -Delastic.run_monitoring=false -Delastic.update_plan=true -Delastic.exec_reconf=false -Delastic.imbalance_load=1.5 -Delastic.algo=metis -Delastic.max_partitions_added=6 -Dclient.memory=4096

== Run Metis:
swap plan.json and plan_out.json
Load & Run baseline again


== Run commgraph
swap data.txt and data.txt.new or change properties file
Prepare
Load & run baseline again

### remember that $max_user_id in properties file need strictly less than max_id in json file!!!!