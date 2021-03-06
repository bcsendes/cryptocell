#!/bin/bash
### BEGIN INIT INFO
# Provides:          node-red
# Required-Start:    $local_fs $remote_fs $network
# Required-Stop:     $local_fs $remote_fs $network
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start or stop the node-red server
### END INIT INFO
# Can be downloaded and installed in one go by using this command
# sudo wget -O /tmp/download https://gist.github.com/Belphemur/cf91100f81f2b37b3e94/download && sudo tar -zxf /tmp/download --strip-components 1 -C /etc/init.d && sudo chmod +x /etc/init.d/node-red && sudo update-rc.d node-red defaults

# User that launches node-RED (it's advised to create a new user for Node-RED)
# You can do : sudo useradd node-red
# then change the USER=root by USER=node-red
# if you change the user, don't forget to also change the ownership of the log file (and create it if it doesn't exist):
# sudo chown NEWUSER /var/log/node-red.log
# else the log won't be writtable
USER=root

# The location of Node-RED configuration, not mandatory, leave empty/commented to let 
# Node-RED decides.

#USER_DIR='/home/pi/node-red/'


# DONT'T CHANGE unless you know what you're doing
NAME=node-red
DAEMON=/usr/local/bin/node-red-pi
OPTIONS="--max-old-space-size=512"

if [ -n "$USER_DIR" ];  then
	OPTIONS="$OPTIONS --userDir=$USER_DIR"
fi

LOG='/var/log/node-red.log'

PIDFILE=/var/run/node-red.pid

. /lib/lsb/init-functions

start_daemon () {
        start-stop-daemon --start --background \
        --chuid $USER --name $NAME \
                $START_STOP_OPTIONS --make-pidfile --pidfile $PIDFILE \
        --startas /bin/bash -- -c "exec $DAEMON $OPTIONS >> $LOG 2>&1"
                log_end_msg 0
}

case "$1" in
        start)
                        log_daemon_msg "Starting daemon" "$NAME"
                        start_daemon

        ;;
        stop)
             log_daemon_msg "Stopping daemon" "$NAME"
                         start-stop-daemon --stop --quiet \
            --chuid $USER \
            --exec $DAEMON --pidfile $PIDFILE --retry 30 \
            --oknodo || log_end_msg $?
                        log_end_msg 0
        ;;
        restart)
			$0 stop
			sleep 5
			$0 start
		;;
		status)
        status_of_proc "$DAEMON" "$NAME"
        exit $?
        ;;

        *)
                echo "Usage: $0 {start|stop|restart}"
                exit 1
esac
exit 0
