---
title: "[Network] WireGuard VPN Cheatsheet"
author: Alxblzd
date: 2025-06-14 15:57:00 +0200
categories: [Tutorial, Wireguard]
tags: [wireguard, vpn, homelab, network]
render_with_liquid: false
image: /assets/img/logo/wireguard_logo.webp
alt: "wireguard logo"
---
# Simplified Cheatsheet: WireGuard Setup & Usage

## What is WireGuard

WireGuard is a VPN protocol. It’s lightweight, fast, and uses modern cryptography primitives.

Built directly into the Linux kernel, it’s designed to be simple yet extremely efficient — making it perfect for homelabs, remote work, and low-power devices (hello Raspberry Pi).

### Why use WireGuard?

- Lightning fast connection (low overhead)
- Simple configuration (no XML jungle)
- Cross-platform (Linux, macOS, Windows, Android, iOS)
- Minimal attack surface
- Peer-to-peer — no client/server nonsense (but we’ll use it like that anyway)
- Built into the Linux kernel (kernel >= 5.6)
- Just ~4,000 lines of code

WireGuard doesn’t allow you to choose ciphers; it uses fixed ones.

There’s no master-slave or client-server enforced by the protocol. However, a common pattern is to assign a “hub” as a server-like peer.

---

## Setup

WireGuard is deployed on my VPS to route virtual machine traffic into my homelab network, functioning similarly to a Cloudflare Tunnel. 

I also run WireGuard within the homelab itself, enabling remote access to my internal network. I route all traffic from my phone through the VPN when connected to untrusted or public Wi-Fi networks such as hotels

- Host: Debian VPS (also works perfectly with Raspberry Pi / Proxmox LXC)
- Clients: Android phone, laptop, desktop

## Prerequisites

- A server with a public IP
- An OS that supports WireGuard
- Root/sudo privileges
- Firewall allowing NAT/PAT

---

## How it works

WireGuard establishes secure point-to-point encrypted tunnels using public key cryptography. Each peer generates a public/private key pair. Public keys are exchanged between peers, while private keys are kept secret and used to decrypt incoming traffic.

### Key Exchange (Asymmetric Encryption)

```
+--------------------+                         +--------------------+
|     Peer A         |                         |     Peer B         |
|--------------------|                         |--------------------|
| PrivateKey: A_priv |  <--- kept secret      | PrivateKey: B_priv |
| PublicKey:  A_pub  |  ---> shared with B    | PublicKey:  B_pub  |
+--------------------+                         +--------------------+
       |                                             |
       | Uses B_pub to encrypt packets   <----------
       |                                             |
       | Receives and decrypts with A_priv          |
```

### Packet Flow

1. A virtual network interface `wg0` is created.
2. It is assigned a static internal IP address (e.g., 10.0.0.1/24).
3. The interface routes packets bound for specific IP ranges.
4. Packets to this interface are encrypted with the peer’s public key, encapsulated in UDP, and sent over the internet.
5. The receiving peer uses its private key to decrypt and inject the packet into its local interface.

This direct model is highly efficient and avoids the complexity of traditional VPN protocols.

### PersistentKeepalive

WireGuard does not maintain an active connection unless traffic is flowing. On some NAT or mobile networks, this can lead to connection timeouts. The `PersistentKeepalive` setting helps by sending regular (empty) packets to keep NAT mappings open.

- Set on the *client* side (especially if behind NAT)
- Default interval: `25` seconds is recommended

Example:
```ini
PersistentKeepalive = 25
```

This is not required in every case but improves reliability in restrictive or idle-timeout-prone networks.

### Preshared Keys

In addition to public/private key pairs, WireGuard supports an optional **preshared key** to add a layer of symmetric encryption on top of the existing asymmetric encryption.

- Used in combination with the standard key exchange
- Helps mitigate the risk of key disclosure (post-quantum safety booster)
- Must be generated securely and shared between peers manually

Generate a preshared key:
```bash
wg genpsk > preshared.key
```

Add it to both peer configurations:
```ini
PresharedKey = <preshared-key>
```

Use preshared keys especially in sensitive deployments, high-security environments, or when extra assurance is desired.

## Installation

### On Debian / Ubuntu

```bash
sudo apt update && sudo apt install wireguard -y
```

WireGuard uses asymmetric keys (like SSH):

```bash
wg genkey | tee privatekey | wg pubkey > publickey
```

### Server Configuration

Edit `/etc/wireguard/wg0.conf`:

```ini
[Interface]
Address = 10.0.0.1/24
ListenPort = 51820
PrivateKey = <server-private-key>
# Optional: enable routing
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

[Peer]
PublicKey = <client-public-key>
PresharedKey = <preshared-key>
AllowedIPs = 10.0.0.2/32
```

Start the service:

```bash
sudo systemctl enable wg-quick@wg0
sudo systemctl start wg-quick@wg0
```

Check status:

```bash
sudo wg
```

### Client Configuration

Example: `/etc/wireguard/wg0.conf` (on client)

```ini
[Interface]
Address = 10.0.0.2/24
PrivateKey = <client-private-key>
DNS = 1.1.1.1

[Peer]
PublicKey = <server-public-key>
PresharedKey = <preshared-key>
Endpoint = <server-ip>:51820
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
```

Start client:

```bash
sudo wg-quick up wg0
```

Make it persistent:

```bash
sudo systemctl enable wg-quick@wg0
```

### Use `AllowedIPs` Wisely

- `0.0.0.0/0` -> Route all traffic through VPN (including internet)
- `10.0.0.0/24` -> Only access to specific internal routes

### QR Code for Mobile

On server or client:

```bash
sudo apt install qrencode
qrencode -t ansiutf8 < wg0.conf
```

### Known limitations

WireGuard has a clean, modern design, but that simplicity comes with trade-offs. In some setups, especially outside tightly controlled networks, these trade-offs can turn into real headaches. From handling changing IPs to being locked into one cryptographic algo, or from performance claims that don’t always hold up, there are a few technical limits worth keeping in mind before committing to it.

## Poor dynamic IP management

WireGuard expects each peer to have a fixed IP address, which is fine in stable networks but messy in real life. Many ISPs use DHCP or CGNAT, so IPs can change without warning, instantly breaking the tunnel. There’s a helper tool that can work around this, but it’s external, not fully IPv6-ready, and adds extra steps to your setup.

## Rigid crypto

WireGuard’s protocol hardcodes a fixed suite: Curve25519 for ECDH, ChaCha20-Poly1305 for AEAD, BLAKE2s for hashing, and SipHash for hashtable keys. 

There is no IKE-like negotiation or algorithm agility. If any primitive becomes insecure, every endpoint must be upgraded and redeployed in sync — an operationally expensive process for large fleets.

## Performance hype

Throughput claims >1 Gbps rely on jumbo packets (up to 64 KB) and Generic Segmentation Offload (GSO).

These conditions rarely apply over the public internet and can induce latency for small-packet flows (e.g., VoIP, gaming). On CPUs with AES-NI or ARMv8 Crypto Extensions, AES-GCM often delivers higher throughput and lower energy cost than ChaCha20-Poly1305.

## 4. Lacks enterprise features

WireGuard keeps things minimal, which is great for simplicity but limiting for corporate setups. It doesn’t support advanced authentication methods like EAP, smartcards, or PKI-based trust models. There’s also no backward compatibility for older crypto, making phased migrations tricky. For networks with a lot of legacy gear or strict interoperability needs, this can be a dealbreaker.
