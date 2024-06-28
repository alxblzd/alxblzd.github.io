---
title: "[TUTORIAL] Linux disks"
author: Alxblzd
date: 2024-04-24 19:10:00 +0200
categories: [Tutorial, Disks]
tags: [disks, partition, linux, tutorial]
render_with_liquid: false
---

# Chapter 1: Initializing the Disk

Initializing a Linux Data Disk (fdisk):

```bash
 sudo fdisk -l
```
Partitioning the disk:
```bash
sudo fdisk /dev/sdx
```

Create a new partition:
  - enter: n

#### Partition type: 
 - Primary partition is a bootable partition and it contains the operating 
 - Extended partition is a partition that is not bootable.
 
 Extended partition typically contains multiple logical partitions and it is used to store data.
  
#### Difference:
    - Quantity: At least 1 and a maximum of 4.
    - Bootable: The primary partition is bootable, and it contains the operating system/s of the computer.
    - Applicable scenarios: We can use it to boot the operating system, establish one to four primary partitions and install multiple operating systems without interfering.
    - Naming example: Primary partitions are assigned the first letters in the alphabet as drive letters (such as C, D). Logical drives in the extended partition get the other letters (such as E, F, G).

# Chapter 2: Verifying and Writing Changes

Primary or extended partition:
  - p
  - e

Partition number:
  Usually use the default, 1 to 4 for a primary partition

First sector:
  usually default

Last sector:
  same

Verify:
  - p

Write changes to the disk:
  enter: w

Run the following command to synchronize the new partition table to the OS:
```bash
partprobe
```

# Chapter 3: Formatting the Disk

Format the disk to the correct file system format:
```bash
mkfs -t ext4 /dev/sdx
```
# Chapter 4: Mounting the Disk

Mount the disk after formatting:
```bash
mount /dev/sdx /mnt/dir
```
# Chapter 5: Configuring for Fstab

Find the UUID for fstab provisioning:
```bash
blkid /dev/sdx
```
Add a line to modify fstab and keeping partition change at boot:
```bash
UUID=0bdsdsds-1337-4abb-841d-bddd0b92693df /mnt/sdc       ext4    defaults        0 2
```
# Chapter 6: Testing Automatic Mount


First: unmount the disk
```bash
unmount /dev/sdx
```
Second: Mount automatically using fstab file
```bash
mount -a
```

Optionnal: Verify the thingy
```bash
mount | grep /mnt/sdx
```


# Chapter 7: Creating an LVM Disk and Formatting in ext4

## Creating an LVM Disk and Formatting in ext4:

#### Create Physical Volume (PV)
```bash
sudo pvcreate /dev/sdx
```

#### Create Volume Group (VG)
```bash
sudo vgcreate vg_name /dev/sdx
```
#### Create Logical Volume (LV)
```bash
sudo lvcreate -L sizeG -n lv_name vg_name
```
#### Format the Logical Volume
```bash
sudo mkfs.ext4 /dev/vg_name/lv_name
```
## Mount the Logical Volume and Verify:

#### Create a mount point if necessary
```bash
sudo mkdir -p /mnt/lvm
```
#### Mount the logical volume
```bash
sudo mount /dev/vg_name/lv_name /mnt/lvm
```    
#### Verify the mount
```bash
mount | grep /mnt/lvm
```