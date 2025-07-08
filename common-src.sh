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

make_ca_dir()
{
    [ -e "$1" ] && { echo "$1 exists. Aborting." ; return 1 ; }
    mkdir -p "$1"
    chmod 700 "$1"
    local easy_rsa_files
    if [ -d /usr/share/easy-rsa ]; then
        easy_rsa_files=/usr/share/easy-rsa
    else
        easy_rsa_files=/etc/easy-rsa
    fi
    ln -sv $easy_rsa_files/* "$1"
    rm -fv "$1"/vars "$1"/*.cnf
    cp -v $easy_rsa_files/vars $easy_rsa_files/*.cnf "$1"
}

script="$(basename $0)"
script_dir="$(dirname $0)"

output_dir=$script_dir/output
easyrsa_dir=$output_dir/openvpn-ca
config=$script_dir/output/config.sh
