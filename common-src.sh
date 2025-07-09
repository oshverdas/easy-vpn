# This script is intended to be sourced, not executed

err_exit()
{
    echo "$script: $@" >&2
    exit 1
}

verify_path()
{
    if [ ! -e "$1" ]; then
        err_exit "$1 does not exist"
    fi
}

grep_pem()
{
    awk '/^-+BEGIN/{p=1}
        /^-+END/{p=2}
        {
            if (p) print $0;
            if (p>1) exit
        }' "$1"
}

print_cert()
{
    cat "$1" | grep -vP '^(#|$)'
}

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

apply_config()
{
    source $config
    sed -e "s/@SERVER_IP@/$SERVER_IP/" \
        -e "s/@SERVER_PORT@/$SERVER_PORT/" \
        -e "s/@SCRAMBLE@/$SCRAMBLE/" \
        $1
}

script="$(basename $0)"
script_dir="$(dirname $0)"

output_dir=$script_dir/output
config=$script_dir/output/config.sh

easyrsa_dir=$output_dir/openvpn-ca
ca_crt=$easyrsa_dir/pki/ca.crt
ta_key=$easyrsa_dir/ta.key
