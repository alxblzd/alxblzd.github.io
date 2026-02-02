---
title: "OSI Layer Basics"
article_type: post
date: 2024-04-28 23:10:00 +0200
categories: [Networking, Concepts]
tags: [network, mac, osi, layer]
render_with_liquid: false
alt: "OSI logo"
---

## OSI Model (Quick, Practical View)

The OSI model is just a way to slice networking into layers. Mental map when troubleshooting: start low, move up.

## Layer 1: Physical

The raw signal level. Cables, fiber, radio, voltages, light pulses.

- Media: copper, fiber, wireless
- Signal encoding, timing, modulation
- Hubs, repeaters, PHY chips

## Layer 2: Data Link

Local network delivery. Frames, MAC addresses, and how devices share the medium.

- Ethernet, Wi‑Fi (802.11)
- MAC addresses (48‑bit)
- Switches live here

802.11 splits L2 into:

- LLC (Logical Link Control)
- MAC (Media Access Control)

Access methods:

- Wired: CSMA/CD
- Wireless: CSMA/CA (can’t listen while transmitting)

MAC address structure:

- First 3 bytes: OUI (vendor)
- Last 3 bytes: device ID

## Layer 3: Network

Routing between networks. Packets, IP addresses, and path selection.

Common protocols:

- IP (v4/v6)
- ARP
- ICMP
- IGMP
- IPsec
- Routing protocols (OSPF, BGP, RIP)

Quick notes:

- IPv4 = 32 bits, IPv6 = 128 bits
- ARP maps IP → MAC on local networks
- ICMP is for errors and diagnostics (ping, traceroute)
- IGMP handles multicast group membership
- IPsec provides encryption and authentication at L3

## Layer 4: Transport

End‑to‑end delivery. Ports, reliability, and flow control.

- TCP: reliable, ordered, 3‑way handshake
- UDP: lightweight, no guarantee, low overhead
- QoS can be implemented here

## Layer 5: Session

Manages conversations between hosts.

- Establish, maintain, and close sessions
- Checkpointing and recovery
- Less visible today, but still a useful concept

## Layer 6: Presentation

Makes data readable by the application.

- Encoding/decoding
- Encryption/decryption
- Compression

## Layer 7: Application

Where applications live and speak.

- HTTP, FTP, SMTP, DNS, SSH, etc.
- Auth and user‑level interaction
- The part humans usually see
