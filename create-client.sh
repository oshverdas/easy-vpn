#!/bin/bash
set -u

usage()
{
    cat <<HELP
Creates new client .ovpn file with certificates signed by CA

Usage:
  $script <unique-client-name> [Options]

Options:
  --update  don't call easyrsa, just regenerate .ovpn file
HELP
}

source $(dirname $0)/common-src.sh

if [ $# -eq 0 ]; then
    usage
    exit 1
fi

mode='create'
while [ $# -gt 0 ]; do
    if [ "$1" = "--help" ]; then
        usage
        exit 0
    fi

    case "$1" in
        --update)
            mode='update'
            ;;
        --*)
            err_exit "Unexpected option: $1"
            ;;
        *)
            client_name="$1"
            ;;
    esac
    shift
done

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

output_dir=output
client_ovpn_file=$output_dir/$client_name.ovpn
client_ovpn_template=$script_dir/client-template.ovpn

verify_path $client_cert_inline
verify_path $client_ovpn_template

apply_config $client_ovpn_template >$client_ovpn_file &&
    print_cert $client_cert_inline >>$client_ovpn_file &&
    echo '<tls-auth>' >>$client_ovpn_file &&
    print_cert $ta_key >>$client_ovpn_file &&
    echo '</tls-auth>' >>$client_ovpn_file ||
    err_exit "$client_ovpn_file file generation failed"

echo "Successfully ${mode}d client '$client_name'. OpenVPN file is located at:"
echo $(readlink -f $client_ovpn_file)

if which zip &>/dev/null; then
    pushd $output_dir >/dev/null
    archive=${client_name}.zip
    zip -r $archive $(basename $client_ovpn_file) >/dev/null
    popd >/dev/null
    echo $(readlink -f $output_dir/$archive)
fi
