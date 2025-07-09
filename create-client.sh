#!/bin/bash
set -u

source $(dirname $0)/common-src.sh

client_ovpn_template=$script_dir/client-template.ovpn

if [ $# -lt 2 ]; then
    echo "Creates client certificate signed by CA"
    echo ""
    echo "Usage:"
    echo "  $script (create|update) <unique-client-name>"
    echo ""
    echo "  create: create new client certificate with easy-rsa"
    echo "  update: update .ovpn file and zip archive"
    exit
fi

case "$1" in
    create|update)
        mode=$1
        ;;
    *)
        err_exit "Unexpected arg 1: $1"
        ;;
esac

client_name="$2"

if echo "$client_name" | grep -q '[^a-zA-Z0-9_\-]'; then
    err_exit "'$client_name' contains symbols other than [a-zA-Z0-9_\-]"
fi

verify_path $easyrsa_dir
verify_path $config

client_cert_inline=$easyrsa_dir/pki/inline/$client_name.inline
if ! [ -e $client_cert_inline ]; then
    client_cert_inline=$easyrsa_dir/pki/inline/private/$client_name.inline
fi

if [ $mode = create ] && [ -e $client_cert_inline ]; then
    err_exit "'$client_name' already exists"
elif [ $mode = update ] && [ ! -e $client_cert_inline ]; then
    err_exit "'$client_name' doesn't exist"
fi

if [ $mode = create ]; then
    verify_path $easyrsa_dir
    verify_path $ca_crt
    verify_path $ta_key

    pushd $easyrsa_dir >/dev/null

    yes 'yes' | easyrsa build-client-full $client_name nopass ||
        err_exit 'build-client-full failed'

    popd >/dev/null
fi

verify_path $client_cert_inline

output_dir=output
client_ovpn_file=$output_dir/$client_name.ovpn

apply_config $client_ovpn_template >$client_ovpn_file &&
    print_cert $client_cert_inline >>$client_ovpn_file &&
    echo '<tls-auth>' >>$client_ovpn_file &&
    print_cert $ta_key >>$client_ovpn_file &&
    echo '</tls-auth>' >>$client_ovpn_file ||
    err_exit "$client_ovpn_file file generation failed"

echo "Successfully created client '$client_name'. OpenVPN file at:"
echo $(readlink -f $client_ovpn_file)

if which zip &>/dev/null; then
    pushd $output_dir >/dev/null
    archive=${client_name}.zip
    zip -r $archive $(basename $client_ovpn_file) >/dev/null
    popd >/dev/null
    echo $(readlink -f $output_dir/$archive)
fi
