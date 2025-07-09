#!/bin/bash
set -u

source $(dirname $0)/common-src.sh

openvpn=/usr/sbin/openvpn
openvpn_orig=/usr/sbin/openvpn_orig

[ -e $openvpn_orig ] || err_exit "$openvpn_orig does not exist"

sudo rm -vf $openvpn &&
    sudo mv -v $openvpn_orig $openvpn ||
    err_exit "Failed to restore $openvpn"
