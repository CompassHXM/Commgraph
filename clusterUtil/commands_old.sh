
vi src/benchmarks/com/oltpbenchmark/benchmarks/twitter/TwitterConstants.java


ssh 10.26.234.46 -i /root/.ssh/hstore.pem
yes
ssh 10.26.233.238 -i /root/.ssh/hstore.pem
yes
ssh 10.26.238.100 -i /root/.ssh/hstore.pem
yes
ssh 10.26.233.238 -i /root/.ssh/hstore.pem
yes





cp configs/twitter-logskew-6m/plan.json plan.json
cp configs/twitter-logskew-6m/twitter.properties properties/benchmarks/
mkdir results
cd results
mkdir twitter-40k
cd twitter-40k
mkdir monitor
mkdir PartitionPlacement
mkdir Metis
mkdir GraphGreedy
mkdir Metis-PartitionPlacement
mkdir Metis-GraphGreedy
cd ../..
cp plan.json results/twitter-40k/

cd ..
sh pretwi.sh
cd h-store-squall
==range
ant hstore-benchmark -Dproject=twitter -Dglobal.hasher_plan=plan.json -Dglobal.hasher_class=edu.brown.hashing.TwoTieredRangeHasher -Dnoshutdown=true -Dnoexecute=true -Dsite.txn_restart_limit_sysproc=100 -Dsite.jvm_asserts=false -Dsite.commandlog_enable=false -Dsite.exec_db2_redirects=false -Dsite.exec_early_prepare=false -Dsite.exec_force_singlepartitioned=true -Dsite.markov_fixed=false -Dsite.planner_caching=false -Dsite.specexec_enable=true -Dsite.memory=50240 | tee out-load.log

ant hstore-benchmark -Dproject=twitter -Dglobal.hasher_plan=plan.json -Dglobal.hasher_class=edu.brown.hashing.TwoTieredRangeHasher -Dnostart=true -Dnoloader=true -Dnoshutdown=true -Dclient.duration=60000 -Dclient.interval=1000 -Dclient.txnrate=2500 -Dclient.count=1 -Dclient.hosts="localhost" -Dclient.threads_per_host=23 -Dclient.blocking_concurrent=30 -Dclient.output_results_csv=results.csv -Dclient.output_interval=true -Dsite.planner_caching=false -Dclient.txn_hints=false -Dsite.exec_early_prepare=false -Dclient.output_basepartitions=true | tee out.log

cp out.log results/twitter-40k/
==monitor
ant hstore-benchmark -Dproject=twitter -Dglobal.hasher_plan=plan.json -Dglobal.hasher_class=edu.brown.hashing.TwoTieredRangeHasher -Dnostart=true -Dnoloader=true -Dnoshutdown=true -Dclient.interval=1000 -Dclient.txnrate=2500 -Dclient.count=1 -Dclient.hosts="localhost" -Dclient.threads_per_host=23 -Dclient.blocking_concurrent=30 -Dclient.output_results_csv=results.csv -Dclient.output_interval=true -Dsite.planner_caching=false -Dclient.txn_hints=false -Dsite.exec_early_prepare=false -Delastic.run_monitoring=true -Delastic.update_plan=false -Delastic.exec_reconf=false -Delastic.delay=20000 -Dclient.duration=60000 | tee -a out.log
cp out.log results/twitter-40k/monitor/
cp *partition*.log results/twitter-40k/monitor/

==PartitionPlacement
javac ProcessTransactionLogs.java -cp json.jar
java -cp .:./json.jar ProcessTransactionLogs 16 4 | tee partitioninfo.log
cp partitioninfo.log results/twitter-40k/PartitionPlacement/
cp plan_out.json results/twitter-40k/PartitionPlacement/
cd ..
fab updateFile:path_to_file=~/h-store-squall/plan_out.json
cd h-store-squall

ant hstore-benchmark -Dproject=twitter -Dglobal.hasher_plan=plan_out.json -Dglobal.hasher_class=edu.brown.hashing.TwoTieredRangeHasher -Dnoshutdown=true -Dnoexecute=true -Dsite.txn_restart_limit_sysproc=100 -Dsite.jvm_asserts=false -Dsite.commandlog_enable=false -Dsite.exec_db2_redirects=false -Dsite.exec_early_prepare=false -Dsite.exec_force_singlepartitioned=true -Dsite.markov_fixed=false -Dsite.planner_caching=false -Dsite.specexec_enable=true  -Dsite.memory=50000 | tee out-load.log
ant hstore-benchmark -Dproject=twitter -Dglobal.hasher_plan=plan_out.json -Dglobal.hasher_class=edu.brown.hashing.TwoTieredRangeHasher -Dnostart=true -Dnoloader=true -Dnoshutdown=true -Dclient.duration=60000 -Dclient.interval=1000 -Dclient.txnrate=2500 -Dclient.count=1 -Dclient.hosts="localhost" -Dclient.threads_per_host=23 -Dclient.blocking_concurrent=30 -Dclient.output_results_csv=results.csv -Dclient.output_interval=true -Dsite.planner_caching=false -Dclient.txn_hints=false -Dsite.exec_early_prepare=false -Dclient.memory=4096 -Dclient.output_basepartitions=true | tee out.log
cp out.log results/twitter-40k/PartitionPlacement/

==Metis
ant affinity -Dproject=twitter -Dglobal.hasher_plan=plan.json -Dglobal.hasher_class=edu.brown.hashing.TwoTieredRangeHasher -Delastic.run_monitoring=false -Delastic.update_plan=true -Delastic.exec_reconf=false -Delastic.imbalance_load=1.5 -Delastic.algo=metis -Delastic.max_partitions_added=6 -Dclient.memory=4096 | tee partitioninfo.log
cp partitioninfo.log results/twitter-40k/Metis/
cp plan_out.json results/twitter-40k/Metis/
cd ..
fab updateFile:path_to_file=~/h-store-squall/plan_out.json
cd h-store-squall
ant hstore-benchmark -Dproject=twitter -Dglobal.hasher_plan=plan_out.json -Dglobal.hasher_class=edu.brown.hashing.TwoTieredRangeHasher -Dnoshutdown=true -Dnoexecute=true -Dsite.txn_restart_limit_sysproc=100 -Dsite.jvm_asserts=false -Dsite.commandlog_enable=false -Dsite.exec_db2_redirects=false -Dsite.exec_early_prepare=false -Dsite.exec_force_singlepartitioned=true -Dsite.markov_fixed=false -Dsite.planner_caching=false -Dsite.specexec_enable=true  -Dsite.memory=50000 | tee out-load.log
ant hstore-benchmark -Dproject=twitter -Dglobal.hasher_plan=plan_out.json -Dglobal.hasher_class=edu.brown.hashing.TwoTieredRangeHasher -Dnostart=true -Dnoloader=true -Dnoshutdown=true -Dclient.duration=60000 -Dclient.interval=1000 -Dclient.txnrate=2500 -Dclient.count=1 -Dclient.hosts="localhost" -Dclient.threads_per_host=23 -Dclient.blocking_concurrent=30 -Dclient.output_results_csv=results.csv -Dclient.output_interval=true -Dsite.planner_caching=false -Dclient.txn_hints=false -Dsite.exec_early_prepare=false -Dclient.memory=4096 -Dclient.output_basepartitions=true | tee out.log
cp out.log results/twitter-40k/Metis/

==GraphGreedy
ant affinity -Dproject=twitter -Dglobal.hasher_plan=plan.json -Dglobal.hasher_class=edu.brown.hashing.TwoTieredRangeHasher -Delastic.run_monitoring=false -Delastic.update_plan=true -Delastic.exec_reconf=false -Delastic.max_load=15000 -Delastic.algo=graph -Dclient.memory=4096 -Delastic.max_partitions_added=6 | tee partitioninfo.log
cp partitioninfo.log results/twitter-40k/GraphGreedy/
cp plan_out.json results/twitter-40k/GraphGreedy/
cd ..
fab updateFile:path_to_file=~/h-store-squall/plan_out.json
cd h-store-squall
ant hstore-benchmark -Dproject=twitter -Dglobal.hasher_plan=plan_out.json -Dglobal.hasher_class=edu.brown.hashing.TwoTieredRangeHasher -Dnoshutdown=true -Dnoexecute=true -Dsite.txn_restart_limit_sysproc=100 -Dsite.jvm_asserts=false -Dsite.commandlog_enable=false -Dsite.exec_db2_redirects=false -Dsite.exec_early_prepare=false -Dsite.exec_force_singlepartitioned=true -Dsite.markov_fixed=false -Dsite.planner_caching=false -Dsite.specexec_enable=true  -Dsite.memory=50000 | tee out-load.log
ant hstore-benchmark -Dproject=twitter -Dglobal.hasher_plan=plan_out.json -Dglobal.hasher_class=edu.brown.hashing.TwoTieredRangeHasher -Dnostart=true -Dnoloader=true -Dnoshutdown=true -Dclient.duration=60000 -Dclient.interval=1000 -Dclient.txnrate=2500 -Dclient.count=1 -Dclient.hosts="localhost" -Dclient.threads_per_host=23 -Dclient.blocking_concurrent=30 -Dclient.output_results_csv=results.csv -Dclient.output_interval=true -Dsite.planner_caching=false -Dclient.txn_hints=false -Dsite.exec_early_prepare=false -Dclient.memory=4096 -Dclient.output_basepartitions=true | tee out.log
cp out.log results/twitter-40k/GraphGreedy/

==Metis-PartitionPlacement
cp results/twitter-40k/Metis/plan_out.json plan.json
cd ..
fab updateFile:path_to_file=~/h-store-squall/plan.json
cd h-store-squall
javac ProcessTransactionLogs.java -cp json.jar
java -cp .:./json.jar ProcessTransactionLogs 16 4 | tee partitioninfo.log
cp partitioninfo.log results/twitter-40k/Metis-PartitionPlacement/
cp plan_out.json results/twitter-40k/Metis-PartitionPlacement/
cd ..
fab updateFile:path_to_file=~/h-store-squall/plan_out.json
cd h-store-squall
ant hstore-benchmark -Dproject=twitter -Dglobal.hasher_plan=plan_out.json -Dglobal.hasher_class=edu.brown.hashing.TwoTieredRangeHasher -Dnoshutdown=true -Dnoexecute=true -Dsite.txn_restart_limit_sysproc=100 -Dsite.jvm_asserts=false -Dsite.commandlog_enable=false -Dsite.exec_db2_redirects=false -Dsite.exec_early_prepare=false -Dsite.exec_force_singlepartitioned=true -Dsite.markov_fixed=false -Dsite.planner_caching=false -Dsite.specexec_enable=true  -Dsite.memory=50000 | tee out-load.log
ant hstore-benchmark -Dproject=twitter -Dglobal.hasher_plan=plan_out.json -Dglobal.hasher_class=edu.brown.hashing.TwoTieredRangeHasher -Dnostart=true -Dnoloader=true -Dnoshutdown=true -Dclient.duration=60000 -Dclient.interval=1000 -Dclient.txnrate=2500 -Dclient.count=1 -Dclient.hosts="localhost" -Dclient.threads_per_host=23 -Dclient.blocking_concurrent=30 -Dclient.output_results_csv=results.csv -Dclient.output_interval=true -Dsite.planner_caching=false -Dclient.txn_hints=false -Dsite.exec_early_prepare=false -Dclient.memory=4096 -Dclient.output_basepartitions=true | tee out.log
cp out.log results/twitter-40k/Metis-PartitionPlacement/

ant hstore-benchmark -Dproject=twitter -Dglobal.hasher_plan=plan.json -Dglobal.hasher_class=edu.brown.hashing.TwoTieredRangeHasher -Dnoshutdown=true -Dnoexecute=true -Dsite.txn_restart_limit_sysproc=100 -Dsite.jvm_asserts=false -Dsite.commandlog_enable=false -Dsite.exec_db2_redirects=false -Dsite.exec_early_prepare=false -Dsite.exec_force_singlepartitioned=true -Dsite.markov_fixed=false -Dsite.planner_caching=false -Dsite.specexec_enable=true  -Dsite.memory=50000 | tee out-load.log
ant hstore-benchmark -Dproject=twitter -Dglobal.hasher_plan=plan.json -Dglobal.hasher_class=edu.brown.hashing.TwoTieredRangeHasher -Dnoshutdown=true -Dclient.duration=1200000 -Dclient.interval=1000 -Dclient.txnrate=2500 -Dclient.count=1 -Dclient.hosts="localhost" -Dclient.threads_per_host=23 -Dclient.blocking_concurrent=30 -Dclient.output_results_csv=results.csv -Dclient.output_interval=true -Dsite.planner_caching=false -Dclient.txn_hints=false -Dsite.exec_early_prepare=false -Dclient.output_basepartitions=true -Delastic.run_monitoring=false -Delastic.update_plan=false -Delastic.exec_reconf=true -Delastic.delay=20000 | tee out.log
cp results.csv results/twitter-40k/Metis-PartitionPlacement

==Metis-GraphGreedy
cp results/twitter-40k/Metis/plan_out.json plan.json
cd ..
fab updateFile:path_to_file=~/h-store-squall/plan.json
cd h-store-squall
ant affinity -Dproject=twitter -Dglobal.hasher_plan=plan.json -Dglobal.hasher_class=edu.brown.hashing.TwoTieredRangeHasher -Delastic.run_monitoring=false -Delastic.update_plan=true -Delastic.exec_reconf=false -Delastic.max_load=15000 -Delastic.algo=graph -Dclient.memory=4096 -Delastic.max_partitions_added=6 | tee partitioninfo.log
cp partitioninfo.log results/twitter-40k/Metis-GraphGreedy/
cp plan_out.json results/twitter-40k/Metis-GraphGreedy/
cd ..
fab updateFile:path_to_file=~/h-store-squall/plan_out.json
cd h-store-squall
ant hstore-benchmark -Dproject=twitter -Dglobal.hasher_plan=plan_out.json -Dglobal.hasher_class=edu.brown.hashing.TwoTieredRangeHasher -Dnoshutdown=true -Dnoexecute=true -Dsite.txn_restart_limit_sysproc=100 -Dsite.jvm_asserts=false -Dsite.commandlog_enable=false -Dsite.exec_db2_redirects=false -Dsite.exec_early_prepare=false -Dsite.exec_force_singlepartitioned=true -Dsite.markov_fixed=false -Dsite.planner_caching=false -Dsite.specexec_enable=true  -Dsite.memory=50000 | tee out-load.log
ant hstore-benchmark -Dproject=twitter -Dglobal.hasher_plan=plan_out.json -Dglobal.hasher_class=edu.brown.hashing.TwoTieredRangeHasher -Dnostart=true -Dnoloader=true -Dnoshutdown=true -Dclient.duration=60000 -Dclient.interval=1000 -Dclient.txnrate=2500 -Dclient.count=1 -Dclient.hosts="localhost" -Dclient.threads_per_host=23 -Dclient.blocking_concurrent=30 -Dclient.output_results_csv=results.csv -Dclient.output_interval=true -Dsite.planner_caching=false -Dclient.txn_hints=false -Dsite.exec_early_prepare=false -Dclient.memory=4096 -Dclient.output_basepartitions=true | tee out.log
cp out.log results/twitter-40k/Metis-GraphGreedy/

ant hstore-benchmark -Dproject=twitter -Dglobal.hasher_plan=plan.json -Dglobal.hasher_class=edu.brown.hashing.TwoTieredRangeHasher -Dnoshutdown=true -Dnoexecute=true -Dsite.txn_restart_limit_sysproc=100 -Dsite.jvm_asserts=false -Dsite.commandlog_enable=false -Dsite.exec_db2_redirects=false -Dsite.exec_early_prepare=false -Dsite.exec_force_singlepartitioned=true -Dsite.markov_fixed=false -Dsite.planner_caching=false -Dsite.specexec_enable=true  -Dsite.memory=50000 | tee out-load.log
ant hstore-benchmark -Dproject=twitter -Dglobal.hasher_plan=plan.json -Dglobal.hasher_class=edu.brown.hashing.TwoTieredRangeHasher -Dnoshutdown=true -Dclient.duration=1200000 -Dclient.interval=1000 -Dclient.txnrate=2500 -Dclient.count=1 -Dclient.hosts="localhost" -Dclient.threads_per_host=23 -Dclient.blocking_concurrent=30 -Dclient.output_results_csv=results.csv -Dclient.output_interval=true -Dsite.planner_caching=false -Dclient.txn_hints=false -Dsite.exec_early_prepare=false -Dclient.output_basepartitions=true -Delastic.run_monitoring=false -Delastic.update_plan=false -Delastic.exec_reconf=true -Delastic.delay=20000 | tee out.log
cp results.csv results/twitter-40k/Metis-GraphGreedy




