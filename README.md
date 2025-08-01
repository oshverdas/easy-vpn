# easy-vpn

Installs and configures OpenVPN on a Linux server (tested on Ubuntu 24.04).
Clients can be added with the management script.

## Server

```
sudo apt-get update
sudo apt-get install openvpn easy-rsa iptables
```

### OpenVPN

For `openvpn` with xor patch (first build [oshverdas/openvpn-xor](https://github.com/oshverdas/openvpn-xor/))

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

Note: If systemd service hangs after start/restart, change type to simple (`Type=simple`) in `/usr/lib/systemd/system/openvpn-server@.service`.

### Network

Run once to configure server network

```
./network.sh
```

## Client

Add new clients by running

```
./create-client.sh client_name
```

Then transfer `client_name.zip` or `client_name.ovpn` to the target machine using a secure channel, and use the
.ovpn file to configure the OpenVPN client.

E.g. with rsync

```
rsync --progress -az user@SERVER_IP:/home/user/easy-vpn/output/client_name.ovpn ./
```

### Connecting

`openvpn` with xor patch connection command

```
sudo ./openvpn-xor/src/openvpn/openvpn --config client_name.ovpn
```

For normal `openvpn`

```
sudo openvpn --config client_name.ovpn
```
