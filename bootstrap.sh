#!/bin/bash
set -u

source common-src.sh

mkdir -p $output_dir

if [ ! -e $vpn_ip_file ]; then
    my_ip >$vpn_ip_file
fi
echo "VPN ip is set to $(cat $vpn_ip_file)"

if [ ! -e $vpn_port_file ]; then
    gen_port >$vpn_port_file
fi
echo "VPN port is set to $(cat $vpn_port_file)"

