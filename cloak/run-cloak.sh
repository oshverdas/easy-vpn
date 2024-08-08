#!/bin/bash
set -u

cloak_dir=$HOME/Cloak
cloak_build=$cloak_dir/build
cloak_server=$cloak_build/ck-server

pid_file=cloak.pid

if [ $# -lt 1 ]; then
    echo "Cloak server runner"
    echo "Usage:"
    echo "  $(basename $0) (start|stop|restart)"
    exit
fi

action=''

case "$1" in
    start|stop|restart)
        action=$1
        ;;
    *)
        echo "Unexpected action: $1"
        exit 1
        ;;
esac

if  [ -f $pid_file ]; then
    if [ $action = start ]; then
        echo "Cloak already running, pid: $(cat $pid_file)"
        exit 1
    fi
else
    if [ $action = stop ]; then
        echo "Cloak is not running, pid file doesn't exist"
        exit 1
    fi
fi

export PATH=$PATH:$cloak_build

start()
{
    ck-server -c ckserver.json >cloak.log 2>&1 &
    local pid=$!
    echo "pid: $pid"
    echo -n $pid >cloak.pid
}

stop()
{
    local pid=$(cat $pid_file)
    while kill -0 $pid >/dev/null 2>&1; do
        kill $pid
        sleep 0.5
    done
    rm $pid_file
}

case $action in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        stop
        start
        ;;
esac
