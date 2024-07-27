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


script="$(basename $0)"
script_dir="$(dirname $0)"

easyrsa_dir=$HOME/openvpn-ca
