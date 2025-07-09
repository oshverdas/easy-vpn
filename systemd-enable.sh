#!/bin/bash
set -u

source $(dirname $0)/common-src.sh
source $config

sudo systemctl enable openvpn-server@$SERVER_NAME
sudo systemctl start openvpn-server@$SERVER_NAME
