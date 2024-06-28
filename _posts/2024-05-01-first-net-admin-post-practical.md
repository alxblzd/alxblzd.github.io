---
title: "[TUTORIAL] Pfsense installation on proxmox in double nat setup"
author: Alxblzd
date: 2024-04-26 23:10:00 +0200
categories: [Networking, Practical]
tags: [pfsense, router, network, vlan]
render_with_liquid: false
---
# Installation Guide for pfSense

## Step 1: Install pfSense
- **Set BIOS Settings**: Configure BIOS settings to enable pfSense installation. Disable unneeded features like RAID controllers and hyperthreading.
  
## Step 2: Boot from USB
- **Boot from USB**: Insert the USB stick and boot from it. Adjust boot options or use BIOS Boot menu to set device priority.

## Step 3: Accept EULA and Install
- **Accept EULA**: Agree to the copyright and distribution notice.
- **Install**: Choose to install pfSense from the boot menu.

## Step 4: Keymap Selection
- **Select Keymap**: Choose the required keymap or use the US default keymap.

## Step 5: Install on a Disk

> "Install with ZFS if you have an array on your proxmox server or if your physical devicce support it"

- **Select ZFS Partition Format**: Opt for the Auto (ZFS) option and configure the ZFS Pool type to Mirrored.
- **Select Disks**: Choose the pair of disk drives for installation

#### Or
- **Select Guided Disk Partition Format**: Opt for the Auto (UFS) option and configure pfsense on a simple disk.


## Step 6: Final Confirmation and Installation
- **Verify Disk Settings**: Ensure settings are correct and proceed with the installation.
- **Final Confirmation**: Confirm the final setup before clearing disk contents.

## Step 7: Initial Setup
- **First Boot**: After installation, the system will boot up. Connect to the LAN interface to access the web configurator. By default the WAN interface doesnt have the GUI fortunately

## Step 8: Configure pfSense
- **Login**: Use default credentials to log in to the web configurator.
- **Wizard Setup**: Follow the configuration wizard for initial setup.

## Step 9: General Configuration
- **DNS Server Settings**: Configure DNS settings to enable forwarder and specify DNS resolution behavior. We will be configuring the **DNS Resolver** after

> "DNS resolver handle the conversion of DNS names to IP addresses, eliminating dependency on external resolvers and ensuring continued functionality even if ISP or public resolvers are offline."

## Step 10: Advanced Configuration
- **Web Configurator**: Adjust settings related to web configurator access and security.
- **Secure Shell**: Enable SSH access to pfSense.

## Step 11: Firewall and Networking
- **Firewall/NAT Configuration**: Optimize firewall settings and configure bogon network blocking.
- **Networking**: Configure IPv6 options and adjust network interface settings.

## Step 12: Miscellaneous Configuration
- **Power Savings**: Configure power management settings.
- **Cryptographic Hardware Acceleration**: Enable cryptographic hardware acceleration for supported processors.

## Step 13: Interface Creation and Configuration
- **Create VLANs**: Configure VLANs for different network segments.
- **Create Interfaces**: Assign VLANs to interfaces.

## Step 14: Configure Interface IP Addresses
- **Match VLAN ID to IP Address**: Set static IP addresses for each VLAN interface.

## Step 15: Configure Interface DHCP
- **Set DHCP Ranges**: Define DHCP ranges for dynamic IP address allocation on each interface.

to be continued :) 