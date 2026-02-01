---
title: "Linux disks"
article_type: cheatsheet
date: 2024-04-24 19:10:00 +0200
categories: [Tutorial, Disks]
tags: [disks, partition, linux, tutorial]
render_with_liquid: false
---


# Disks infos

## Initializing the Disk


#### Partition type: 
 - Primary partition is a bootable partition and it contains the operating 
 - Extended partition is a partition that is not bootable.
 
 Extended partition typically contains multiple logical partitions and it is used to store data.
  
#### Difference:
    - Quantity: At least 1 and a maximum of 4.
    - Bootable: The primary partition is bootable, and it contains the operating system/s of the computer.
    - Applicable scenarios: We can use it to boot the operating system, establish one to four primary partitions and install multiple operating systems without interfering.
    - Naming example: Primary partitions are assigned the first letters in the alphabet as drive letters (such as C, D). Logical drives in the extended partition get the other letters (such as E, F, G).


### Verifying and Writing Changes


Initializing a Linux Data Disk (fdisk):

```bash
 sudo fdisk -l
```
Partitioning the disk:
```bash
sudo fdisk /dev/sdx
```
Create the partition

```md
#Create a new partition:
  - n

#Primary or extended partition:
  - p
  - e

#Partition number:
  - Usually use the default, 1 to 4 for a primary partition

#First sector:
  - usually default

#Last sector:
  - same

#Verify:
  - p

#Write changes to the disk:
  - w
```

Run the following command to synchronize the new partition table to the OS:
```bash
partprobe
```

## Formatting the Disk

Format the disk to the correct file system format:
```bash
mkfs.ext4 /dev/sdx
#or
mkfs -t ext4 /dev/sdx
```
## Mounting the Disk

Mount the disk after formatting:
```bash
mount /dev/sdx /mnt/dir
```
## Configuring for Fstab

Find the UUID for fstab provisioning:
```bash
blkid /dev/sdx
```
Add a line to modify fstab and keeping partition change at boot:
```bash
UUID=0bdsdsds-1337-4abb-841d-bddd0b92693df /mnt/sdc       ext4    defaults        0 2
```
### Testing Automatic Mount
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

## Disk Usage

#### Disk Usage Commands:

    ```bash
    # Show child directory sizes of current directory in bytes
    du
    
    # Show human-readable directory sizes
    du -h
    
    # Show size of current directory only (nesting depth=0)
    du -d 0
    
    # Show child directory sizes of current directory in MB
    du -BM
    
    # Show child directory sizes of the specified directory in bytes
    du /path/to/directory
    
    # Show sizes of direct child directories only
    du -d 1 .
    
    # Sort directories by size
    du -BM -d 1 . | sort -n
    
    # Show sizes of all directories in root (/), sorted in reverse numerical order and view in less
    du / | sort -nr | less
    ```
