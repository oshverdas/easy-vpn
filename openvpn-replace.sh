#!/bin/bash
set -u

source $(dirname $0)/common-src.sh

openvpn=/usr/sbin/openvpn
openvpn_orig=/usr/sbin/openvpn_orig
openvpn_repl="${1?A path to patched openvpn expected}"

test -x $openvpn || err_exit "$openvpn is missing"
test -x $openvpn_repl || err_exit "$openvpn_repl is missing"

[ -e $openvpn_orig ] && err_exit "$openvpn_orig already exists"

sudo mv -v $openvpn $openvpn_orig &&
    sudo cp -v $openvpn_repl $openvpn &&
    sudo chmod 755 $openvpn ||
    err_exit "Failed to replace $openvpn"
