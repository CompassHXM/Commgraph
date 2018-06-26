# auto-benchmark-script
auto benchmark script for h-store project

usage:
  Auto benchmark: "fab -f auto.py testAll" 
  Using fab.cfg to update fabfile.py: "fab -f auto.py updateFab"
  Using fab.cfg to update property files in H-store: "fab updateCfg"
  
  For command needs to run in all sites, using:
    "fab runAll:command='command_to_run'"
    "fab runClients:command='command_to_run'
    frequent command:
    build: "fab build"
    prepare: "fab prepare"
