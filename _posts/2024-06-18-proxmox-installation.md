---
title: "[PROJECT] Proxmox Hypervisor for Homelab"
author: Alxblzd
date: 2024-04-18 18:10:00 +0200
categories: [Proxmox, Project]
tags: [proxmox, hypervisor, homelab, project]
render_with_liquid: false
---
# Simplified Tutorial: Proxmox VE Installation


# What is Proxmox

Proxmox is an open-source virtualization management platform that combines two virtualization technologies: - KVM for full virtualization 
- LXC for container-based virtualization. 

It provides a web-based interface for managing virtual machines (VMs), containers, and storage resources.

You can have features like live migration, backups, and clustering out-of-the-box. 

It suitable for both enterprise and homelab environments. The platform is backed by a robust community.

# Use Cases


Proxmox is like a playground for tech fans, mixing KVM and LXC into a user-friendly web interface. You can test things, deploy VMs in a blink of an eye, improve your home network, and, of course, self-host almost everything!


# My Hardware 

In the quest for an efficient and versatile homelab setup, the Beelink EQ12 Pro emerged as a promising candidate. Powered by an Intel Core i3 N3050 CPU from the Alder Lake-N series, this mini PC packs eight E-cores.

I found this mini pc used in France for $170, a pretty good deal. I  enhanced its by adding 32GB of DDR5 RAM for $65.


![hardware](assets/img/eq_12_pro.jpg)

#### Pros
- 2 x  2.5GbE LAN ports (Intel i225-V B3)
- Moderate power usage: ranges from 9 to 36W

#### Cons
- PCIe : NVMe SSD operates on a PCIe Gen3 x1 link, limiting maximum data throughput ~ 750Mb/s for nvme :( .
- Memory  : Supports only 16 GB single-channel memory, though I have successfully used 32GB without encountering any issues for the moment.
- The casing feels cheap and really plasticish.


#### Other

I also have this type of HDD dock for adding more 3.5-inch storage. I can't really recommend it, but hey, it works.

![hdd_dock](assets/img/hdd_dock.png)


#### The setup in place

Look at this majestic cardboard-like setup.

![setup](assets/img/setup.png)




## Prerequisites

- Proxmox VE installer ISO image
- USB drive or CD-ROM for installation
- Compatible server (64-bit Debian Linux)

## Installation Steps

### 1. Preparation

- Insert the prepared installation media (USB or CD-ROM) into the server.
- Ensure booting from this media is enabled in the server's firmware settings.
- Disable Secure Boot.

### 2. Start the Installer

- Boot from the installation media.
- Choose the `Install Proxmox VE (Graphical)` option for a graphical installation or one of the other options if necessary.

### 3. Select Target Disk

- Read and accept the EULA (End User License Agreement).
- Select the target hard disk(s) for the installation. Note that all existing data will be erased.

### 4. Basic Configuration

- Select basic configuration options such as location, time zone, and keyboard layout.

### 5. Set Password

- Set the superuser (root) password and an email address to receive system notifications.

### 6. Network Configuration

- Configure the available network interfaces. You can specify an IPv4 or IPv6 address.

### 7. Summary and Installation

- Review the selected settings in the summary and make changes if necessary.
- Click `Install` to begin the installation. Wait for the package copying to complete.

### 8. Finalization

- Once the installation is complete, remove the installation media and reboot the system.

## Accessing the Management Interface

- After rebooting, access the Proxmox VE web interface via the IP address defined during installation, e.g., `https://youripaddress:8006`.
- Log in with the username root and the password set earlier.

- Download your subscription key to access the Enterprise repository, or configure a public repository for updates.

## Advanced Configuration

### LVM Advanced Options

- **hdsize**: Set the total hard disk size to use.
- **swapsize**: Set the swap partition size.
- **maxroot**: Set the maximum size of the root partition.
- **maxvz**: Set the maximum size of the data partition.
- **minfree**: Set the free space to leave in the LVM volume group.

> Note: For more details on advanced configuration, refer to the official Proxmox VE documentation.

---

This tutorial covers the basic steps to install and configure Proxmox VE. For more detailed installation and configuration, please consult the official documentation.
