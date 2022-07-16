#!/bin/bash

# ##############
# Start services
echo
echo Starting services
# Setting up links for easier management
if [ -f /home/cryptogt/postgresql.conf ]; then 
    unlink /home/cryptogt/postgresql.conf 
fi
ln -s "$PGDATA/postgresql.conf" /home/cryptogt/postgresql.conf
if [ -f /home/cryptogt/settings.js ]; then 
    unlink /home/cryptogt/settings.js
fi
ln -s /home/cryptogt/.node-red/settings.js /home/cryptogt/settings.js
if [ -f /home/cryptogt/data ]; then 
    unlink /home/cryptogt/data
fi
ln -s "$PGVOLUME" /home/cryptogt/data
# Starting services
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
