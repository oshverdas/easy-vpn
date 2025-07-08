# easy-vpn

## Server

```
sudo apt-get update
sudo apt-get install openvpn easy-rsa
```

Initialise PKI and config
```
./bootstrap.sh
```

## Client

Add new users by running
```
./new-client.sh <name>
```

Then transfer `<name>.zip` on a target machine and use .ovpn file to configure OpenVPN client.

### Linux

https://wiki.archlinux.org/title/OpenVPN

### Windows

https://openvpn.net/client/client-connect-vpn-for-windows/
