#!/bin/bash
set -eux

echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward >/dev/null
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo iptables-save
