#!/bin/bash
set -u

cloak_dir=$HOME/Cloak
cloak_build=$cloak_dir/build
cloak_server=$cloak_build/ck-server

if [ ! -e $cloak_server ]; then
    echo 'Building Cloak'
    which go
    which make

    pushd $cloak_dir
    go get ./...
    make
    popd
fi

sudo setcap CAP_NET_BIND_SERVICE=+eip $cloak_server

echo 'Keys:'
$cloak_server -key

echo 'Bypass UID:'
$cloak_server -uid
