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

subst_config()
{
    verify_path $vpn_ip_file
    verify_path $vpn_port_file
    sed -e "s/@VPN_IP@/$(cat $vpn_ip_file)/" \
        -e "s/@VPN_PORT@/$(cat $vpn_port_file)/" \
        $1
}


script="$(basename $0)"
script_dir="$(dirname $0)"

easyrsa_dir=$HOME/openvpn-ca

output_dir=$script_dir/output
vpn_ip_file=$output_dir/vpn_ip
vpn_port_file=$output_dir/vpn_port
