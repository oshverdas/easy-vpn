#!/bin/bash
set -u

source $(dirname $0)/common-src.sh

if ! which easyrsa; then
    echo "'easy-rsa' package is not installed" >&2
    exit 1
fi

if ! which openvpn; then
    echo "'openvpn' package is not installed" >&2
    exit 1
fi

mkdir -p $output_dir

if [ -d $easyrsa_dir ]; then
    err_exit "$easyrsa_dir already exists, aborting"
fi

echo "make-cadir $easyrsa_dir"

if [ -d /usr/share/easy-rsa ]; then
    # Ubuntu
    easy_rsa_files=/usr/share/easy-rsa
    if [ -x $easy_rsa_files/easyrsa ] && ! which easyrsa >/dev/null; then
        sudo ln -sv $easy_rsa_files/easyrsa /usr/local/bin/ ||
            err_exit "Failed to symlink easyrsa executable"
    fi
else
    # Arch
    easy_rsa_files=/etc/easy-rsa
fi
mkdir -p $easyrsa_dir &&
    chmod 700 $easyrsa_dir &&
    ln -s $easy_rsa_files/x509-types $easyrsa_dir &&
    cp $easy_rsa_files/openssl-easyrsa.cnf $easyrsa_dir &&
    cp $easy_rsa_files/vars* "$easyrsa_dir/vars" ||
    err_exit "Failed to copy easy-rsa files into $easyrsa_dir"

pushd $easyrsa_dir >/dev/null

easyrsa init-pki ||
    err_exit 'init-pki failed'

echo 'Easy-RSA CA' | easyrsa build-ca nopass ||
    err_exit 'build-ca failed'

easyrsa gen-crl ||
    err_exit 'gen-crl failed'

openvpn --genkey secret ta.key ||
    err_exit 'TA key generation failed'

popd >/dev/null

echo "Successfully set up the PKI and CA at:"
echo $(readlink -f $easyrsa_dir)
