#!/bin/bash
set -u

easyrsa_dir=$HOME/openvpn-ca

client_ovpn_template=client-template.ovpn

if [ $# -eq 0 ]; then
    echo "Creates client certificate signed by CA"
    echo "Usage:"
    echo "  $(basename $0) [Options] <unique-client-name>"
    exit
fi

verify_path()
{
    if [ ! -e ${1?Internal error: path expected} ]; then
        echo "$1 does not exist" >&2
        echo "Possible reasons:" >&2
        echo "  easyrsa is not configured" >&2
        echo "  some paths have changed in newer version of easyrsa" >&2
        exit 1
    fi
}

verify_path $easyrsa_dir

client_name="$1"
if echo "$client_name" | grep -q '[^a-zA-Z0-9_\-]'; then
    echo "Error: '$client_name' contains symbols other than [a-zA-Z0-9_\-]" >&2
    exit 1
fi

if [ -e $client_name ]; then
    echo "Error: '$client_name' already exists" >&2
    exit 1
fi

pushd $easyrsa_dir

./easyrsa --nopass build-client-full $client_name
if [ $? != 0 ]; then
    "A call to easyrsa has failed" >&2
    exit $?
fi

popd

ca_crt=$easyrsa_dir/pki/ca.crt
ta_key=$easyrsa_dir/ta.key
client_cert_crt=$easyrsa_dir/pki/issued/$client_name.crt
client_cert_key=$easyrsa_dir/pki/private/$client_name.key
client_cert_inline=$easyrsa_dir/pki/inline/$client_name.inline

verify_path $ca_crt
verify_path $ta_key
verify_path $client_cert_crt
verify_path $client_cert_key
verify_path $client_cert_inline

output_dir=$client_name
output_ovpn_file=$output_dir/$client_name.ovpn
output_cert_dir=$output_dir/certs

# Leave only PEM part
pem()
{
    awk '/^-+BEGIN/{p=1} /^-+END/{p=2} {if (p) print $0; if (p>1) exit}' ${1?Internal error: path expected}
}

print_cert()
{
    cat ${1?Internal error: path expected} | grep -vP '^(#|$)'
}

mkdir $output_dir
mkdir $output_cert_dir

echo "Generating $output_ovpn_file"
cat $client_ovpn_template >$output_ovpn_file
print_cert $client_cert_inline >>$output_ovpn_file
echo '<tls-auth>' >>$output_ovpn_file
print_cert $ta_key >>$output_ovpn_file
echo '</tls-auth>' >>$output_ovpn_file

cp -v $ca_crt $ta_key $client_cert_crt $client_cert_key $client_cert_inline $output_cert_dir/

if which zip; then
    zip -r ${output_dir}.zip $output_dir
fi
