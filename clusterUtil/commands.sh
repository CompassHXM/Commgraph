== PREPARE

ant hstore-prepare -Dproject=twitter -Dhosts=cluster.cfg

== LOAD

ant hstore-benchmark -Dproject=twitter -Dglobal.hasher_plan=plan.json -Dglobal.hasher_class=edu.brown.hashing.TwoTieredRangeHasher -Dnoshutdown=true -Dnoexecute=true -Dsite.txn_restart_limit_sysproc=100 -Dsite.jvm_asserts=false -Dsite.commandlog_enable=false -Dsite.exec_db2_redirects=false -Dsite.exec_early_prepare=false -Dsite.exec_force_singlepartitioned=true -Dsite.markov_fixed=false -Dsite.planner_caching=false -Dsite.specexec_enable=true -Dglobal.memory=1024 -Dclient.memory=8000 -Dsite.memory=8000 | tee out-load.log

== RUN

ant hstore-benchmark -Dproject=twitter -Dglobal.hasher_plan=plan.json -Dglobal.hasher_class=edu.brown.hashing.TwoTieredRangeHasher -Dnostart=true -Dnoloader=true -Dnoshutdown=true -Dclient.duration=60000 -Dclient.interval=1000 -Dclient.txnrate=10000 -Dclient.count=1 -Dclient.hosts="localhost" -Dclient.threads_per_host=10 -Dclient.blocking_concurrent=30 -Dclient.output_results_csv=results.csv -Dclient.output_interval=true -Dsite.planner_caching=false -Dclient.txn_hints=false -Dsite.exec_early_prepare=false -Dclient.output_basepartitions=true -Dglobal.memory=1024 -Dclient.memory=8000 -Dsite.memory=8000 | tee out.log

#== LOAD from plan_out.json

#ant hstore-benchmark -Dproject=twitter -Dglobal.hasher_plan=plan_out.json -Dglobal.hasher_class=edu.brown.hashing.TwoTieredRangeHasher -Dnoshutdown=true -Dnoexecute=true -Dsite.txn_restart_limit_sysproc=100 -Dsite.jvm_asserts=false -Dsite.commandlog_enable=false -Dsite.exec_db2_redirects=false -Dsite.exec_early_prepare=false -Dsite.exec_force_singlepartitioned=true -Dsite.markov_fixed=false -Dsite.planner_caching=false -Dsite.specexec_enable=true -Dglobal.memory=8048 -Dclient.memory=8048 -Dsite.memory=16000 | tee out-load.log

#== RUN from plan_out.json

#ant hstore-benchmark -Dproject=twitter -Dglobal.hasher_plan=plan_out.json -Dglobal.hasher_class=edu.brown.hashing.TwoTieredRangeHasher -Dnostart=true -Dnoloader=true -Dnoshutdown=true -Dclient.duration=60000 -Dclient.interval=1000 -Dclient.txnrate=1000 -Dclient.count=5 -Dclient.hosts="localhost" -Dclient.threads_per_host=16 -Dclient.blocking_concurrent=30 -Dclient.output_results_csv=results.csv -Dclient.output_interval=true -Dsite.planner_caching=false -Dclient.txn_hints=false -Dsite.exec_early_prepare=false -Dclient.output_basepartitions=true -Dglobal.memory=8048 -Dclient.memory=8048 -Dsite.memory=16000 | tee out.log


#== MONITOR

#ant hstore-benchmark -Dproject=twitter -Dglobal.hasher_plan=plan.json -Dglobal.hasher_class=edu.brown.hashing.TwoTieredRangeHasher -Dnostart=true -Dnoloader=true -Dnoshutdown=true -Dclient.interval=1000 -Dclient.txnrate=1000 -Dclient.count=5 -Dclient.hosts="localhost" -Dclient.threads_per_host=16 -Dclient.blocking_concurrent=30 -Dclient.output_results_csv=results.csv -Dclient.output_interval=true -Dsite.planner_caching=false -Dclient.txn_hints=false -Dsite.exec_early_prepare=false -Delastic.run_monitoring=true -Delastic.update_plan=false -Delastic.exec_reconf=false -Delastic.delay=20000 -Dclient.duration=60000 -Dglobal.memory=8048 -Dclient.memory=8048 -Dsite.memory=16000 | tee -a out.log

#== RECONFIGURE

#ant hstore-benchmark -Dproject=twitter -Dglobal.hasher_plan=plan.json -Dglobal.hasher_class=edu.brown.hashing.TwoTieredRangeHasher -Dnoshutdown=true -Dclient.duration=1200000 -Dclient.interval=1000 -Dclient.txnrate=1000 -Dclient.count=5 -Dclient.hosts="localhost" -Dclient.threads_per_host=16 -Dclient.blocking_concurrent=30 -Dclient.output_results_csv=results.csv -Dclient.output_interval=true -Dsite.planner_caching=false -Dclient.txn_hints=false -Dsite.exec_early_prepare=false -Dclient.output_basepartitions=true -Delastic.run_monitoring=false -Delastic.update_plan=false -Delastic.exec_reconf=true -Delastic.delay=20000 -Dglobal.memory=8048 -Dclient.memory=8048 -Dsite.memory=16000 | tee out.log