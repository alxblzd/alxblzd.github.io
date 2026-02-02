---
title: "OPNsense on Proxmox (Double NAT Lab)"
article_type: post
date: 2025-08-24 14:09:00 +0200
categories: [Project, Networking]
tags: [opnsense, proxmox, homelab, network]
alt: "Proxmox logo"
render_with_liquid: false
---

OPNsense firewall inside my Proxmox, but my WAN is already behind a private IP. That means double NAT, and it changes a few defaults. This is the exact VM setup and the little tweaks I made to keep the GUI reachable and the install clean.

## Proxmox VM Settings (What I Use)

- **Memory**: 2 GB RAM (ballooning off)
- **CPU**: Host CPU passthrough
- **Kernel tunables**:
  - `hw.ibrs_disable=1`
  - `vm.pmap.pti=0`
- **Proxmox firewall**: Disabled for this VM
- **Guest agent**: Install `qemu-guest-agent`
- **Chipset**: `i440fx`
- **OS type**: Other
- **Disk**:
  - SCSI controller (block mode)
  - Discard enabled
  - Cache mode: Write Back
  - IOThreads enabled

Mount the OPNsense ISO to the VM as a DVD drive and boot it.

## Disable Default Firewall (Temporarily)

Because my WAN is private (double NAT), I want to reach the GUI from the WAN side while I’m setting things up.

1. Log in as `root` in the console
2. Choose **8) Shell**
3. Run:

```bash
pfctl -d
```

## Install OPNsense

From the console:

```bash
opnsense-installer
```

I pick **ZFS** even though Proxmox is already on ZFS. It’s a bit heavier than UFS, but I trust ZFS more. I use a **non‑mirrored ZFS stripe** here.

When the install finishes, set the root password and reboot.

## Initial Wizard (My Choices)

- **Domain**: `home.arpa`
- **WAN**: DHCP, **Block RFC1918** unchecked (because WAN is private)
- **LAN**: `10.0.66.1/24`

## After the Wizard

- Make sure you can reach the GUI
- Confirm hostname, time, DHCP reservations
- Change the root password if you didn’t already
- Update: **System → Firmware → Updates**

## Allow GUI Access from WAN (Double NAT Only)

I only do this in my lab because WAN is private. Don’t do this on a real public WAN.

1. **Disable default WAN protections**
   - Go to **Firewall → Settings → Advanced**
   - Enable **Disable reply to WAN Rule**
   - Enable **Disable administration anti‑lockout**

2. **Add a WAN rule**
   - Allow **WAN net** to access **WAN address** on port **443**

That’s it — after this I can reach the GUI directly from my WAN side inside the lab.
