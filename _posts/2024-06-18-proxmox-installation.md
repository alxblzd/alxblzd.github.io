---
title: "[PROJECT] Proxmox Hypervisor for Homelab"
author: Alxblzd
date: 2024-04-18 18:10:00 +0200
categories: [Proxmox, Project]
tags: [proxmox, hypervisor, homelab, project]
render_with_liquid: false
image: /assets/img/proxmox_logo.webp
alt: "proxmox logo"
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


![hardware](assets/img/eq_12_pro.webp)

#### Pros
- 2 x  2.5GbE LAN ports (Intel i225-V B3)
- Moderate power usage: ranges from 9 to 36W

#### Cons
- PCIe : NVMe SSD operates on a PCIe Gen3 x1 link, limiting maximum data throughput ~ 750Mb/s for nvme :( .
- Memory  : Supports only 16 GB single-channel memory, though I have successfully used 32GB without encountering any issues for the moment.
- The casing feels cheap and really plastic-ish.


#### Other

I also have this type of HDD dock for adding more 3.5-inch storage. I can't really recommend it, but hey, it works.

![hdd_dock](assets/img/hdd_dock.webp)


#### The setup in place

Look at this majestic cardboard-like setup.

![setup](assets/img/setup.webp)




## Prerequisites

- Proxmox VE installer ISO image
- USB drive or CD-ROM for installation
- Compatible server (64-bit Debian Linux)

To make a USB bootable drive, you can use rufus or balena etcher for example, the iso can be downloaded here : 
https://www.proxmox.com/en/downloads/proxmox-virtual-environment/iso


## Installation Steps

### Setting up the bios

Before or after installing proxmox, you have to modifify some bios options, to make virtualization better and activating all functionnality provided by the bios

### 1. Preparation

- Insert the prepared installation media (USB or CD-ROM) into the server.
- Ensure booting from this media is enabled in the server's firmware settings.

### 2. Start the Installer

- Boot from the installation media.


![Boot](assets/img/proxmox/proxmox1.webp)

- Choose the `Install Proxmox VE (Graphical)` option for a graphical installation or one of the other options if necessary.

- Read and accept the EULA (End User License Agreement).
![EULA](assets/img/proxmox/proxmox2.webp)


### 3. Select Target Disk
- Select the target hard disk(s) for the installation, keeping in mind that all existing data will be erased

- **hdsize**: Set the total hard disk size to use.
- **swapsize**: Set the swap partition size.
- **maxroot**: Set the maximum size of the root partition.
- **maxvz**: Set the maximum size of the data partition.
- **minfree**: Set the free space to leave in the LVM volume group.

- You have the option to customize the default partition sizes
- If you have the necessary hardware and knowledge, configuring ZFS for Proxmox can be recommended

Personally, I prefer running Proxmox on a single SSD and configuring ZFS separately for my VMs on this mini PC. Given that the hardware isn't as robust as a server and there's no redundancy in my ZFS pool, I use ZFS primarily for RAID 0 to enhance storage speed. I keep backups of my VMs on separate storage outside of my ZFS pool in case of corruption or instability.

![Disks](assets/img/proxmox/proxmox3.webp)

- Select basic configuration options such as location, time zone, and keyboard layout.
- Set the superuser (root) password and an email address to receive system notifications.

![Pass](assets/img/proxmox/proxmox5.webp)


### 4. Network Configuration

- Configure the available network interfaces. You can specify either an IPv4 or IPv6 address.

- Choose a static IP address that is not already in use. You can assign this IP by configuring your DHCP server and also by setting it in the network/interface file on the Linux host.

- The management interface will be used to connect to the Web GUI, so choose it carefully. 
Here, you can also set up a more advanced configuration to manage your proxmox node only from a specific VLAN.

- The hostname of your Proxmox node cannot be easily changed after installation, so select it carefully. Technically, it can be changed, but it requires removing all your existing VMs.

In this example, I am using Google DNS, but you can use the DNS of your router, ISP, or Google. You can also follow another tutorial to set up your own DNS resolver or forwarder, such as Pi-hole or a pfSense router.

![Interfaces](assets/img/proxmox/proxmox6.webp)


### 5. Summary and Installation


- Review the selected settings in the summary and make changes if necessary.
- Click `Install` to begin the installation. Wait for the package copying to complete.

![Summary](assets/img/proxmox/proxmox7.webp)

- Once the installation is complete, remove the installation media and reboot the system.

![Summary](assets/img/proxmox/proxmox8.webp)

- After rebooting, access the Proxmox VE web interface via the IP address defined during installation, e.g., `https://youripaddress:8006`.
- Log in with the username root and the password set earlier.


### 6. Congratulations

You can now connect to your newly created proxmox node ! :)

![Summary](assets/img/proxmox/proxmox9.webp)
![Summary](assets/img/proxmox/proxmox10.webp)


---

This tutorial covers the basic steps to install and configure Proxmox VE. For more detailed installation and configuration, please consult the official documentation.
