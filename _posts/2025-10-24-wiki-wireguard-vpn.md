---
title: "[Wiki] WireGuard VPN"
author: "Alxblzd"
date: 2025-10-24 09:12:00 +0200
categories: [Networking, VPN]
tags: [wireguard, vpn, network, security, encryption]
render_with_liquid: false
---

# WireGuard VPN

## What is WireGuard?

WireGuard is a modern, fast, and secure VPN protocol designed to be simpler and more efficient than traditional VPN solutions like IPsec and OpenVPN. It uses state-of-the-art cryptography and aims to be easy to configure and deploy.

- Designed by Jason A. Donenfeld
- Merged into the Linux kernel 5.6 (March 2020)
- Available for Linux, Windows, macOS, BSD, iOS, and Android
- Significantly smaller codebase compared to OpenVPN and IPsec

## Key Features

### Performance
- Extremely fast due to minimal overhead and efficient cryptography
- Runs in kernel space on Linux for optimal performance
- Low latency and high throughput
- Minimal battery impact on mobile devices

### Security
- Uses modern cryptographic primitives by default
- No cipher suite negotiation - prevents downgrade attacks
- Perfect forward secrecy with regular key rotation
- Smaller attack surface due to minimal codebase (~4,000 lines of code)

### Simplicity
- Simple configuration with minimal parameters
- Easy to audit due to small codebase
- Silent protocol - doesn't respond to unauthenticated packets
- Stateless by design - roams seamlessly between networks

## Cryptography

WireGuard uses a fixed set of modern cryptographic protocols:

- **ChaCha20** for symmetric encryption
- **Poly1305** for authentication
- **Curve25519** for key exchange (ECDH)
- **BLAKE2s** for hashing
- **SipHash24** for hashtable keys
- **HKDF** for key derivation

> No algorithm negotiation means no complexity and no vulnerabilities from weak configurations

## How WireGuard Works

### Key Concepts

#### Cryptokey Routing
WireGuard associates public keys with allowed IP addresses. Each peer has a public key, and traffic is routed based on cryptographic identity rather than traditional routing tables.

#### Interface-Based
WireGuard creates a virtual network interface (like `wg0`) that behaves like a regular network interface. Traffic sent through this interface is encrypted and routed to peers.

#### Peer-to-Peer
Each WireGuard installation can be both client and server. The distinction is mainly in configuration - one peer typically has a static endpoint while others connect to it.

### Connection Process

1. **Key Exchange**: Uses Noise protocol framework for handshake
2. **Authentication**: Mutual authentication using public/private key pairs
3. **Encryption**: All traffic encrypted with session keys
4. **Roaming**: Automatically adapts to IP address changes
5. **Keep-alive**: Optional persistent keepalives for NAT traversal

## Installation

### Linux
```bash
# Debian/Ubuntu
sudo apt update
sudo apt install wireguard

# RHEL/CentOS/Fedora
sudo dnf install wireguard-tools

# Arch Linux
sudo pacman -S wireguard-tools
```

### FreeBSD/OPNsense/pfSense
```bash
# FreeBSD
pkg install wireguard-tools

# OPNsense/pfSense
# Install through web GUI package manager
```

### Windows/macOS
Download the official WireGuard application from [wireguard.com](https://www.wireguard.com/install/)

## Configuration

### Generating Keys

```bash
# Generate private key
wg genkey | tee privatekey | wg pubkey > publickey

# Or generate both at once
umask 077
wg genkey | tee privatekey | wg pubkey > publickey

# View keys
cat privatekey
cat publickey
```

### Server Configuration

Create configuration file at `/etc/wireguard/wg0.conf`:

```ini
[Interface]
Address = 10.0.0.1/24
ListenPort = 51820
PrivateKey = <server-private-key>
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

# Client 1
[Peer]
PublicKey = <client1-public-key>
AllowedIPs = 10.0.0.2/32

# Client 2
[Peer]
PublicKey = <client2-public-key>
AllowedIPs = 10.0.0.3/32
```

### Client Configuration

Create configuration file at `/etc/wireguard/wg0.conf`:

```ini
[Interface]
Address = 10.0.0.2/24
PrivateKey = <client-private-key>
DNS = 1.1.1.1, 8.8.8.8

[Peer]
PublicKey = <server-public-key>
Endpoint = server.example.com:51820
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
```

### Configuration Parameters

#### Interface Section
- **Address**: IP address(es) assigned to the interface
- **ListenPort**: Port for incoming connections (default: 51820)
- **PrivateKey**: Interface's private key
- **DNS**: DNS servers to use (client-side)
- **MTU**: Maximum transmission unit size
- **Table**: Routing table to use (auto, off, or table number)
- **PostUp/PostDown**: Commands to run when interface goes up/down
- **PreUp/PreDown**: Commands to run before interface goes up/down

#### Peer Section
- **PublicKey**: Peer's public key (required)
- **Endpoint**: IP address and port of the peer
- **AllowedIPs**: IP ranges this peer can send/receive
- **PersistentKeepalive**: Interval in seconds for keepalive packets
- **PresharedKey**: Optional additional symmetric key for post-quantum resistance

## Managing WireGuard

### Start/Stop Interface

```bash
# Start interface
sudo wg-quick up wg0

# Stop interface
sudo wg-quick down wg0

# Enable at boot
sudo systemctl enable wg-quick@wg0

# Start service
sudo systemctl start wg-quick@wg0

# Check status
sudo systemctl status wg-quick@wg0
```

### Monitoring

```bash
# Show interface status
sudo wg show

# Show specific interface
sudo wg show wg0

# Show detailed information
sudo wg show wg0 dump

# Monitor in real-time
watch -n 1 sudo wg show
```

### Dynamic Configuration

```bash
# Add peer without restarting
sudo wg set wg0 peer <public-key> allowed-ips 10.0.0.4/32

# Remove peer
sudo wg set wg0 peer <public-key> remove

# Change listen port
sudo wg set wg0 listen-port 51821
```

## Common Use Cases

### Site-to-Site VPN
Connect two networks together by routing specific subnets through the tunnel:

```ini
# Site A
[Interface]
Address = 10.0.0.1/24

[Peer]
PublicKey = <site-b-public-key>
Endpoint = site-b.example.com:51820
AllowedIPs = 192.168.2.0/24
```

### Road Warrior VPN
Mobile clients connecting to a central server:

```ini
# Mobile Client
[Interface]
Address = 10.0.0.10/24
PrivateKey = <client-private-key>
DNS = 10.0.0.1

[Peer]
PublicKey = <server-public-key>
Endpoint = vpn.example.com:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
```

### Peer-to-Peer
Direct connection between two hosts:

```ini
# Host A
[Interface]
Address = 10.0.0.1/24
ListenPort = 51820

[Peer]
PublicKey = <host-b-public-key>
Endpoint = host-b.example.com:51820
AllowedIPs = 10.0.0.2/32
```

## Security Best Practices

### Key Management
- Generate unique keys for each peer
- Store private keys securely with proper file permissions (600)
- Never share or transmit private keys
- Rotate keys periodically for long-term deployments

### Network Configuration
- Use firewall rules to restrict access to WireGuard port
- Implement rate limiting to prevent DoS attacks
- Use PresharedKey for post-quantum security
- Regularly update WireGuard to latest version

### Access Control
- Limit AllowedIPs to minimum required ranges
- Use separate tunnels for different security zones
- Implement monitoring and logging
- Regular security audits of peer configurations

## Troubleshooting

### Connection Issues

```bash
# Check if interface is up
ip link show wg0

# Verify routing
ip route show

# Check for handshake
sudo wg show wg0 latest-handshakes

# Monitor traffic
sudo tcpdump -i wg0

# Test connectivity
ping -I wg0 10.0.0.1
```

### Common Problems

#### No handshake occurring
- Verify firewall allows UDP traffic on WireGuard port
- Check endpoint address and port are correct
- Ensure public keys are correctly configured
- Verify NAT traversal with PersistentKeepalive

#### Handshake completes but no traffic
- Check AllowedIPs configuration
- Verify routing table entries
- Ensure no IP conflicts
- Check PostUp/PostDown scripts for errors

#### Performance issues
- Adjust MTU size (typically 1420 for WireGuard)
- Check for fragmentation
- Verify hardware acceleration support
- Monitor CPU usage during transfers

## Comparison with Other VPNs

### WireGuard vs OpenVPN
- **Speed**: WireGuard is significantly faster
- **Complexity**: WireGuard much simpler to configure
- **Codebase**: WireGuard ~4K lines vs OpenVPN ~100K lines
- **Compatibility**: OpenVPN more widely supported (for now)
- **Flexibility**: OpenVPN more configuration options

### WireGuard vs IPsec
- **Performance**: WireGuard generally faster
- **Configuration**: WireGuard much easier to set up
- **Roaming**: WireGuard handles network changes better
- **Maturity**: IPsec more established in enterprise
- **Standards**: IPsec is an IETF standard

## Integration Examples

### OPNsense/pfSense
1. Install WireGuard plugin through Package Manager
2. Navigate to VPN > WireGuard
3. Create Local instance (server)
4. Add Endpoints (peers)
5. Configure firewall rules for WireGuard interface

### Docker Container
```bash
# Run WireGuard in Docker
docker run -d \
  --name=wireguard \
  --cap-add=NET_ADMIN \
  --cap-add=SYS_MODULE \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=Europe/Paris \
  -e SERVERPORT=51820 \
  -e PEERS=3 \
  -p 51820:51820/udp \
  -v /path/to/config:/config \
  -v /lib/modules:/lib/modules \
  --sysctl="net.ipv4.conf.all.src_valid_mark=1" \
  --restart unless-stopped \
  linuxserver/wireguard
```

### Systemd Network Manager
```bash
# Enable NetworkManager integration
nmcli connection import type wireguard file /etc/wireguard/wg0.conf

# Activate connection
nmcli connection up wg0
```

## Useful Resources

- Official documentation: [wireguard.com](https://www.wireguard.com)
- Protocol specification: [WireGuard whitepaper](https://www.wireguard.com/papers/wireguard.pdf)
- Configuration examples: [WireGuard examples](https://github.com/pirate/wireguard-docs)

## Conclusion

WireGuard represents the modern approach to VPN technology - simple, fast, and secure by default. Its minimal configuration and excellent performance make it ideal for both personal and enterprise use cases. Whether setting up a home VPN, connecting remote sites, or securing mobile devices, WireGuard provides a streamlined solution without sacrificing security.
