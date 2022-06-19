#!/bin/bash

# Start services
echo
echo Starting services
service ssh start
/etc/init.d/node-red start
docker-entrypoint.sh postgres &

# -$$: kill process group (parent and children)
#trap 'trap - TERM; kill 0' TERM
#trap 'trap - INT TERM; kill 0' INT TERM

trap 'trap - TERM; kill -s TERM -- -$$' TERM

tail -f /dev/null & wait

# Stop services
echo Stopping services
service ssh stop
/etc/init.d/node-red stop
gosu postgres pg_ctl -D $PGDATA stop

exit 0
