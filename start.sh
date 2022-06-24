#!/bin/bash

# Start services
echo
echo Starting services
service ssh start
/etc/init.d/node-red.sh start
docker-entrypoint.sh postgres &

# -$$: kill process group (parent and children)
#trap 'trap - TERM; kill 0' TERM
#trap 'trap - INT TERM; kill 0' INT TERM

trap 'trap - TERM; kill -s TERM -- -$$' TERM

tail -f /dev/null & wait

# Stop services
echo
echo Stopping services
service ssh stop
/etc/init.d/node-red.sh stop
echo Terminated successfully

exit 0