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

ca_crt=$easyrsa_dir/pki/ca.crt
ta_key=$easyrsa_dir/ta.key
client_cert_req=$easyrsa_dir/pki/reqs/$client_name.req
client_cert_crt=$easyrsa_dir/pki/issued/$client_name.crt
client_cert_key=$easyrsa_dir/pki/private/$client_name.key
client_cert_inline=$easyrsa_dir/pki/inline/private/$client_name.inline

if [ $mode = create ] && [ -e $client_cert_req ]; then
    err_exit "'$client_name' already exists"
elif [ $mode = update ] && [ ! -e $client_cert_req ]; then
    err_exit "'$client_name' doesn't exist"
fi


if [ $mode = create ]; then
    pushd $easyrsa_dir
    yes 'yes' | easyrsa --nopass build-client-full $client_name
    if [ $? != 0 ]; then
        err_exit "A call to easyrsa has failed"
    fi
    popd
fi

verify_path $ca_crt
verify_path $ta_key
verify_path $client_cert_crt
verify_path $client_cert_key
verify_path $client_cert_inline

output_dir=output
client_ovpn_file=$output_dir/$client_name.ovpn

echo "Generating $client_ovpn_file"

apply_config $client_ovpn_template >$client_ovpn_file
print_cert $client_cert_inline >>$client_ovpn_file
echo '<tls-auth>' >>$client_ovpn_file
print_cert $ta_key >>$client_ovpn_file
echo '</tls-auth>' >>$client_ovpn_file

#client_output_dir=$output_dir/$client_name
#mkdir -p $client_output_dir
#client_output_certs_dir=$client_output_dir/certs
#mkdir -p $client_output_certs_dir
#cp -v $ca_crt $ta_key $client_cert_crt $client_cert_key \
#    $client_cert_inline $client_output_certs_dir/

if which zip &>/dev/null; then
    pushd $output_dir
    archive=${client_name}.zip
    zip -r $archive $(basename $client_ovpn_file)
    popd
    echo "$archive"
fi

echo "Done"
