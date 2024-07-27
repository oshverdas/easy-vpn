# easy-vpn

## Server

```
sudo apt-get update
sudo apt-get install openvpn easy-rsa
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

## Versions

Known to work with next setups
```
Ubuntu 24.04 LTS
EasyRSA 3.1.7
OpenVPN 2.6.9
OpenSSL 3.0.13
```
