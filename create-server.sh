#!/bin/bash
set -u

my_ip()
{
    curl ifconfig.me
}

gen_port()
{
    local port_min=${1:-49152}
    local port_max=${2:-65535}
    echo $((RANDOM % ($port_max - $port_min) + $port_min))
}

usage()
{
    cat <<HELP
Creates certificates and config files needed by OpenVPN server

Usage:
  $script [Options]

Options:
  --name NAME Specify server name. Default value: server.
  --ip IP     Specify OpenVPN server IP address. Default value: current public IP
              address.
  --port PORT Specify port that OpenVPN server will listen to. Default value: random
              port.
  --scramble  Enable scrambling (only available if OpenVPN with tunnelblick xor patch
              is used)
  --install   Install server files to /etc/openvpn
HELP
}

source $(dirname $0)/common-src.sh

server_name='server'
server_ip=''
server_port=''
scramble=''
install=''

while [ $# -gt 0 ]; do
    if [ "$1" = "--help" ]; then
        usage
        exit 0
    fi

    case "$1" in
        --name)
            server_name=${2?$1 expects an argument}
            shift
            ;;
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
        --install)
            install=y
            ;;
        --*)
            err_exit "Unexpected option: $1"
            ;;
    esac
    shift
done

check_name "$server_name"

if ! [ -d $output_dir ]; then
    echo "Run init-pki-ca.sh first" >&2
    exit 1
fi

if ! [ -e $config ]; then
    echo "SERVER_NAME='$server_name'" >$config

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

    echo $config
    cat $config
else
    echo "$config already exists"
fi

server_conf_template=$script_dir/server-template.conf
server_conf=$output_dir/$server_name.conf

if ! [ -e $server_conf ]; then
    apply_config $server_conf_template >$server_conf
else
    echo "$server_conf already exists"
fi

if ! [ -e $dh_param ]; then
    pushd $easyrsa_dir >/dev/null
    easyrsa gen-dh ||
        err_exit 'gen-dh failed'
    popd >/dev/null
    verify_path $dh_param
else
    echo "$dh_param already exists"
fi

server_key=$easyrsa_dir/pki/private/$server_name.key
server_crt=$easyrsa_dir/pki/issued/$server_name.crt

if ! [ -e $server_key ]; then
    pushd $easyrsa_dir >/dev/null
    yes 'yes' | easyrsa build-server-full $server_name nopass ||
        err_exit 'build-server-full failed'
    popd >/dev/null
    verify_path $server_key
    verify_path $server_crt
else
    echo "$server_key already exists"
fi

transfer_file()
{
    operation=${1?operation not specified}
    from=${2?from not specified}
    to=${3?to not specified}
    perm=${4:-}
    target=$to/$(basename $from)

    sudo $operation $(readlink -f $from) $to/ ||
        err_exit "Failed to transfer $from to $to"
    if [ -n "$perm" ]; then
        sudo chmod $perm $target ||
            err_exit "Failed to set permissions to $target"
    fi
}

if [ "$install" = "y" ]; then
    etc_openvpn=/etc/openvpn
    etc_server=$etc_openvpn/server

    transfer_file 'cp -v' $server_conf $etc_server 644

    for file in $ca_crt $ta_key $dh_param $server_key $server_crt $crl; do
        transfer_file 'cp -v' $file $etc_server 600
    done
fi
