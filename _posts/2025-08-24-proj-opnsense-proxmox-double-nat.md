---
title: "[Project] Deploying OPNsense on Proxmox, double NAT setup"
author: Alxblzd
date: 2025-08-24 14:09:00 +0200
categories: ["project"]
tags: ["opnsense", "proxmox", "homelab", "network"]
image:
  path: /assets/img/projects/opnsense_proxmox_ha.webp
  alt: "OPNsense + Proxmox double nat architecture"
render_with_liquid: false
---
## Proxmox - OPNsense VM Setup

- **Memory**: 2 GB RAM (ballooning disabled)  
- **CPU**: Host CPU passthrough  
- **Kernel tunables**:  
  - `hw.ibrs_disable=1`  
  - `vm.pmap.pti=0`  
- **Proxmox Firewall**: Disabled  
- **Guest Agent**: Install `qemu-guest-agent`  
- **Chipset**: i440fx  
- **OS Type**: Other  
- **Disk**:  
  - SCSI controller (block mode)  
  - Discard enabled  
  - Cache mode: Write Back  
  - IOThreads enabled  


Download the OPNsense ISO and mount it to the VM as a DVD drive.

### Disable Default Firewall

Since this setup runs behind double NAT (with the WAN IP being private),  
I prefer to access the OPNsense GUI directly from the WAN interface.  
To do this, the default firewall must be disabled.

1. Log in as **root** in console
2. Select option **8) Shell**
3. Run the following command:

   ```bash
   pfctl -d
   ```

## OPNsense Installation

From the CLI console, run:

```bash
opnsense-installer
```

Choose ZFS as the filesystem, even if Proxmox itself already uses ZFS. While this adds some overhead, it's generally preferable to UFS in terms of stability and features. I went with a non-mirrored ZFS configuration (ZFS stripes).

After installation completes, change the root password and reboot.

## Initial Wizard

- **Domain**: home.arpa
- **WAN network**: DHCP, Block RFC 1918 → unchecked (because I'm in a double NAT setup, my WAN is a private IP)
- **LAN network**: 10.0.66.1/24

## Post-Wizard Setup

1. Ensure you can access the **GUI**.
2. Verify the following:
   - Hostname is correctly set
   - Date and time are accurate
   - DHCP reservations are configured
   - Root password has been changed

3. Run a **system update**:
   - Navigate to **System → Firmware → Updates**

### Make OPNsense GUI Available from the WAN Network

1. **Disable "Reply to WAN" Rule**  
   Navigate to:  
   **Firewall → Settings → Advanced**  
   - Enable **Disable reply to WAN Rule**  
   - Enable **Disable administration anti-lockout**

2. **Create a Firewall Rule**
   Add a rule to permit the **WAN network** to access the **WAN address** on port **443**.
