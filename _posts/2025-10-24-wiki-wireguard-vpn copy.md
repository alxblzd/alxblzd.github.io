---
title: "WireGuard VPN"
article_type: post
author: Alxblzd
date: 2025-10-24 09:12:00 +0200
categories: [Networking, VPN]
tags: [wireguard, vpn, network, security, encryption]
render_with_liquid: false
---

## What is WireGuard?

WireGuard is a modern, fast, and secure VPN protocol they say, designed to be simpler and more efficient than traditional VPN solutions like IPsec and OpenVPN. 

- Designed by Jason A. Donenfeld
- Merged into the Linux kernel 5.6 (March 2020)
- Available for Linux, Windows, macOS, BSD, iOS, and Android
- Significantly smaller codebase compared to OpenVPN and IPsec (~4,000 lines of code)

## Key Features

### Performance
- Extremely fast due to minimal overhead and efficient cryptography
- Runs in kernel space on Linux for optimal performance
- 3-5x throughput improvements over OpenVPN in identical hardware configurations
- Low latency and high throughput

### Security
- No cipher suite negotiation - prevents downgrade attacks
- Smaller attack surface due to minimal codebase
- Silent protocol - doesn't respond to unauthenticated packets (prevents enumeration attacks)

### Simplicity
- Easy to audit due to small codebase 
- Stateless by design - roams seamlessly between networks
- Negligible maintenance overhead

## Cryptography

WireGuard uses a fixed set of modern cryptographic protocols:

- **ChaCha20** for symmetric encryption
- **Poly1305** for authentication
- **Curve25519** for key exchange (ECDH)
- **BLAKE2s** for hashing
- **SipHash24** for hashtable keys
- **HKDF** for key derivation

> No algorithm negotiation means no complexity and no vulnerabilities from weak configurations. However, this also means you're stuck with ChaCha20-Poly1305 whether you like it or not.

## How WireGuard Works

### Key Concepts

#### Cryptokey Routing
WireGuard associates public keys with allowed IP addresses. Each peer has a public key, and traffic is routed based on cryptographic identity rather than traditional routing tables. The cryptokey routing table is implemented as a hash table - with thousands of peers, you may hit collision overhead.

**Critical insight**: AllowedIPs isn't just an ACL, it's your routing table. Each peer gets exactly one IP. No overlap. No ambiguity. This constraint forces clean network design.

#### Interface-Based
WireGuard creates a virtual network interface (like `wg0`) that behaves like a regular network interface. Traffic sent through this interface is encrypted and routed to peers. Unlike OpenVPN's dependency on tun/tap devices, WireGuard's interface model plays nicely with container networking.

#### Peer-to-Peer
Each WireGuard installation can be both client and server. The distinction is mainly in configuration - one peer typically has a static endpoint while others connect to it.

### Connection Process

1. **Key Exchange**: Uses Noise protocol framework for handshake
2. **Authentication**: Mutual authentication using public/private key pairs
3. **Encryption**: All traffic encrypted with session keys
4. **Roaming**: Automatically adapts to IP address changes (typically in under 3 seconds)
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

**Key Management Reality**: There's no built-in PKI. You're generating keys, distributing them, and tracking which key belongs to whom. For 10 users? A spreadsheet works. For 1000? You need automation (Ansible with Vault, or at minimum a bash script).

### Server Configuration

Create configuration file at `/etc/wireguard/wg0.conf`:

```ini
[Interface]
Address = 10.0.0.1/24
ListenPort = 51820
PrivateKey = 
PostUp = sysctl -w net.ipv4.ip_forward=1
PostUp = iptables -A FORWARD -i %i -j ACCEPT
PostUp = iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT
PostDown = iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

# Client 1
[Peer]
PublicKey = 
AllowedIPs = 10.0.0.2/32

# Client 2
[Peer]
PublicKey = 
AllowedIPs = 10.0.0.3/32
```

### Client Configuration

Create configuration file at `/etc/wireguard/wg0.conf`:

```ini
[Interface]
Address = 10.0.0.2/24
PrivateKey = 
DNS = 1.1.1.1, 8.8.8.8

[Peer]
PublicKey = 
Endpoint = server.example.com:51820
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
```

**Important Note**: For clients behind NAT (basically everyone), `PersistentKeepalive=25` isn't optional. Without it, stateful firewalls drop the mapping after 30-180 seconds of inactivity, causing "random disconnections."

### Configuration Parameters

#### Interface Section
- **Address**: IP address(es) assigned to the interface
- **ListenPort**: Port for incoming connections (default: 51820)
- **PrivateKey**: Interface's private key
- **DNS**: DNS servers to use (client-side, only works with wg-quick)
- **MTU**: Maximum transmission unit size (default 1420)
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

**Monitoring**: Forget ping checks. Monitor handshake age instead:

```bash
#!/bin/bash
THRESHOLD=180  # seconds
LAST_HANDSHAKE=$(wg show wg0 latest-handshakes | grep $PEER_KEY | awk '{print $2}')
NOW=$(date +%s)
AGE=$((NOW - LAST_HANDSHAKE))

if [ $AGE -gt $THRESHOLD ]; then
    echo "CRITICAL: Handshake age $AGE seconds"
    exit 2
fi
```

For traffic analysis, `/proc/net/dev` gives you real-time stats without the overhead of tcpdump. Parse it, graph it, alert on anomalies.

**Silent Failures**: WireGuard doesn't log connection attempts by design, it prevents enumeration attacks. Great for security, terrible for debugging. Your monitoring needs to be proactive: check handshake timestamps, not connection states.

### Dynamic Configuration

```bash
# Add peer without restarting
sudo wg set wg0 peer  allowed-ips 10.0.0.4/32

# Remove peer
sudo wg set wg0 peer  remove

# Change listen port
sudo wg set wg0 listen-port 51821
```

## Common Use Cases

### Hub-and-Spoke

Forget the peer-to-peer mesh dreams for now. Start with a central node:

```ini
[Interface]
Address = 10.10.0.1/24
ListenPort = 51820
PrivateKey = 
PostUp = sysctl -w net.ipv4.ip_forward=1
PostUp = iptables -A FORWARD -i %i -j ACCEPT
PostUp = iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

[Peer]
PublicKey = 
AllowedIPs = 10.10.0.2/32
```

### Site-to-Site VPN

Connect two networks together by routing specific subnets through the tunnel:

```ini
# Site A
[Interface]
Address = 10.0.0.1/24

[Peer]
PublicKey = 
Endpoint = site-b.example.com:51820
AllowedIPs = 192.168.2.0/24, 10.0.0.5/32
PersistentKeepalive = 25
```

**Critical Detail**: That second AllowedIP (10.0.0.5/32) is the WireGuard interface address of the remote peer. Miss it, and you'll spend hours debugging.

Traditional site-to-site setups route entire subnets through the tunnel. With WireGuard, you're explicit about everything:

```ini
[Peer]
PublicKey = 
Endpoint = remote.example.com:51820
AllowedIPs = 192.168.100.0/24, 192.168.101.0/24, 10.10.0.5/32
PersistentKeepalive = 25
```

### Road Warrior VPN

Mobile clients connecting to a central server:

```ini
# Mobile Client
[Interface]
Address = 10.0.0.10/24
PrivateKey = 
DNS = 10.0.0.1

[Peer]
PublicKey = 
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
PublicKey = 
Endpoint = host-b.example.com:51820
AllowedIPs = 10.0.0.2/32
```


### MTU Issues

**Problem**: Default MTU of 1420 works until it doesn't. If you're tunneling over a connection with its own overhead (PPPoE, another VPN), you'll hit fragmentation.

**Symptoms**: SSH works fine, but large transfers hang mysteriously.

**Solution**: Drop MTU to 1280 and work your way up:

```ini
[Interface]
MTU = 1280
```

### DNS Leaks

Test with `dig @10.10.0.1 example.com` to verify your queries actually go through the tunnel. Configure DNS manually for non-wg-quick setups.


### Performance

On high-traffic nodes, CPU affinity matters:

```bash
# Bind WireGuard kernel threads to specific cores
echo 2 > /proc/irq/24/smp_affinity_list  # Adjust IRQ number as needed
```

Enable UDP offloading if your NIC supports it:

```bash
ethtool -K eth0 rx-udp_tunnel-port-offload on
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
- Check AllowedIPs configuration (most common issue)
- Verify routing table entries
- Ensure no IP conflicts
- Check PostUp/PostDown scripts for errors

#### Performance issues
- Adjust MTU size (typically 1420 for WireGuard, 1280 for problematic networks)
- Check for fragmentation
- Verify hardware acceleration support
- CPU usage during transfers

#### Random disconnections
- Add or verify `PersistentKeepalive = 25` for clients behind NAT
- Check firewall timeout settings
- Monitor handshake age


## When NOT to Use WireGuard

WireGuard isn't the right choice for every scenario:

- You need detailed connection logging for audit purposes (WireGuard is silent by design)
- Dynamic certificate-based authentication is non-negotiable (WireGuard uses static keys)
- Legacy integration requirements demand OpenVPN or IPsec compatibility

## Integration Examples

### Docker Container

WireGuard's in a docker container (not tested too much in my lab)

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

## Performance Tuning

1. **NIC Offloading**: Enable UDP offloading if your network card supports it

2. **Monitoring**: Use `/proc/net/dev` for low-overhead traffic statistics

## Useful Resources

- Official documentation: [wireguard.com](https://www.wireguard.com)
- Protocol specification: [WireGuard whitepaper](https://www.wireguard.com/papers/wireguard.pdf)
- Configuration examples: [WireGuard examples](https://github.com/pirate/wireguard-docs)
- Quick start guide: [WireGuard Quick Start](https://www.wireguard.com/quickstart/)
