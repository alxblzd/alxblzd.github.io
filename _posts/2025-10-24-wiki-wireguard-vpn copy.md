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

WireGuard is the VPN I reach for when I want something boring and reliable. It’s a small, modern protocol that keeps the config simple and stays out of the way.

- Designed by Jason A. Donenfeld
- In the Linux kernel since 5.6 (March 2020)
- Available on Linux, Windows, macOS, BSD, iOS, and Android

### Why it’s nice
#### Performance
Low overhead, Kernel‑space on Linux, Usually faster than OpenVPN on the same box
#### Security
Fixed crypto set, Small attack surface, Silent to unauthenticated packets
#### Simplicity
Small config files yay!, Roams between networks, Easy to operate

## Cryptography

WireGuard ships with a fixed crypto suite:

- **ChaCha20** for symmetric encryption
- **Poly1305** for authentication
- **Curve25519** for key exchange (ECDH)

## How it works 

### Key Concepts

#### Cryptokey Routing
Keys map to AllowedIPs. That list is both your ACL and your routing table. Keep it clean and non‑overlapping.

#### Interface-Based
You get a normal interface (`wg0`). Send traffic to it, WireGuard handles the rest. Works well with containers.

#### Peer-to-Peer
Everything is a peer. “Server” just means the peer with a stable endpoint.

### Connection Process

1. Handshake (Noise framework)
2. Mutual auth with key pairs
3. Encrypted tunnel
4. Roaming just works
5. Optional keepalive for NAT

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

**Key management reality**: No built‑in PKI. You generate keys, distribute them, and keep track. For a small lab, a spreadsheet is fine. For anything bigger, automate it.

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

**Note**: For clients behind NAT, `PersistentKeepalive=25` usually prevents idle timeouts.

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

**Monitoring**: Don’t rely on ping alone. Track handshake age:

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

For traffic stats, `/proc/net/dev` is lightweight and easy to graph.

**Silent failures**: WireGuard doesn’t log connection attempts by design. Good for security, bad for debugging. Use handshake timestamps as your signal.

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

Simple lab pattern: one box with a public endpoint, everyone else dials in.

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

Connect two LANs by routing specific subnets through the tunnel:

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

**Critical detail**: That second AllowedIP (10.0.0.5/32) is the WireGuard interface address of the remote peer. Miss it and you waste time.

Traditional site-to-site setups route whole subnets. With WireGuard, you are explicit about everything:

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

Two hosts, direct tunnel:

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

## Gotchas

### MTU

If SSH works but big transfers hang, drop MTU and work back up:

```ini
[Interface]
MTU = 1280
```

### DNS

Quick check:
`dig @10.10.0.1 example.com`

For non `wg-quick` setups, set DNS manually.

### Performance

On busy nodes, CPU affinity can help:

```bash
# Bind WireGuard kernel threads to specific cores
echo 2 > /proc/irq/24/smp_affinity_list  # Adjust IRQ number as needed
```

Enable UDP offloading if your NIC supports it:

```bash
ethtool -K eth0 rx-udp_tunnel-port-offload on
```

## Security Notes

- One keypair per peer
- `chmod 600` on private keys
- Do not share private keys
- Keep AllowedIPs minimal
- Add `PresharedKey` if you want extra insurance
- Keep WireGuard up to date

## Troubleshooting

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

#### No handshake
- UDP port open?
- Endpoint correct?
- Keys match?
- NAT? Add keepalive.

#### Handshake but no traffic
- AllowedIPs wrong (most common)
- Routing table
- IP conflicts
- PostUp/PostDown errors

#### Slow or flaky
- Try MTU 1280
- Check fragmentation
- Watch CPU

#### Random disconnects
- Add/verify `PersistentKeepalive = 25`
- Check firewall timeouts
- Watch handshake age

## When NOT to Use WireGuard

- You need detailed connection logs (WireGuard is quiet by design)
- You need cert-based auth (WireGuard uses static keys)
- You must integrate with legacy OpenVPN/IPsec setups

## Integration Examples

### Docker

WireGuard in Docker (not heavily tested on my side):

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

### NetworkManager

```bash
# Enable NetworkManager integration
nmcli connection import type wireguard file /etc/wireguard/wg0.conf

# Activate connection
nmcli connection up wg0
```

## Useful Resources

- Official docs: [wireguard.com](https://www.wireguard.com)
- Whitepaper: [wireguard.com/papers/wireguard.pdf](https://www.wireguard.com/papers/wireguard.pdf)
- Examples: [github.com/pirate/wireguard-docs](https://github.com/pirate/wireguard-docs)
- Quick start: [wireguard.com/quickstart](https://www.wireguard.com/quickstart/)
