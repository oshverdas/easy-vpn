#!/bin/bash
set -u

source $(dirname $0)/common-src.sh

server_ip=''
server_port=''
scramble=''

while [ $# -gt 0 ]; do
    if [ "$1" = "--help" ]; then
cat <<HELP
Usage: ./$(basename $0) [Options]

Options:
  --ip IP     Specify OpenVPN server IP address. Default value: current public IP
              address.
  --port PORT Specify port that OpenVPN server will listen to. Default value: random
              port.
  --scramble  Enable scrambling (requires OpenVPN with tunnelblick xor patch).
HELP
        exit 0
    fi

    case "$1" in
        --ip)
            server_ip=${2?$1 expects an argument}
            shift
            ;;
        --port)
            server_port=${2?$1 expects an argument}
            shift
            ;;
        --scramble)
            scramble=y
            ;;
    esac
    shift
done


if ! [ -d $output_dir ]; then
    echo "Run init-pki-ca.sh first" >&2
    exit 1
fi

echo -n >$config

if [ -z "$server_ip" ]; then
    server_ip=$(my_ip)
fi
echo "SERVER_IP='$server_ip'" >>$config

if [ -z "$server_port" ]; then
    server_port=$(gen_port)
fi
echo "SERVER_PORT='$server_port'" >>$config

if [ "$scramble" = "y" ]; then
    echo "SCRAMBLE='scramble xorptrpos'" >>$config
else
    echo "SCRAMBLE=''" >>$config
fi

echo "Created config at:"
echo $config
cat $config
