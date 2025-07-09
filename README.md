# easy-vpn

## Server

```
sudo apt-get update
sudo apt-get install openvpn easy-rsa
```

For `openvpn` with xor patch

```
./openvpn-replace.sh $HOME/openvpn-xor/src/openvpn/openvpn
./init-pki-ca.sh
./create-server.sh --name server-xor --scramble --install
./systemd-enable.sh
```

For normal `openvpn`

```
./init-pki-ca.sh
./create-server.sh --install
./systemd-enable.sh
```

## Client

Add new clients by running

```
./create-client.sh client_name
```

Then transfer `client_name.zip` or `client_name.ovpn` to the target machine using a secure channel, and use the
.ovpn file to configure the OpenVPN client.

### Connect

`openvpn` with xor patch connection command

```
sudo ./openvpn-xor/src/openvpn/openvpn --config client_name.ovpn
```

For normal `openvpn`

```
sudo openvpn --config client_name.ovpn
```
