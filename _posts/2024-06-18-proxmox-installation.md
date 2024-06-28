---
title: "[PROJECT] Proxmox Hypervisor for Homelab"
author: cotes
date: 2024-04-18 23:10:00 +0200
categories: [Proxmox, Project]
tags: [proxmox, hypervisor, homelab, project]
render_with_liquid: false
---
# Simplified Tutorial: Proxmox VE Installation

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
