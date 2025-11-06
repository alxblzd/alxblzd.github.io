---
title: "[Wiki] Automating Proxmox with Terraform and Cloud-Init"
date: 2025-11-06 20:34:00 +0100
categories: [Infrastructure, Automation]
tags: [terraform, proxmox, cloud-init, virtualization, automation]
render_with_liquid: false
---

## What is Terraform + Proxmox Automation?

Terraform lets you spin up VMs in Proxmox without clicking through the web UI every time. You define your VMs in code, and Terraform handles the rest.

- Uses the BPG Proxmox Provider
- Cloud-Init handles the initial setup

Full working example on [GitHub](https://github.com/alxblzd/proxmox-terraform-pbks/tree/main)


## The Stack

Pretty straightforward:

- **Proxmox VE** - the hypervisor running everything
- **Terraform** - describes what VMs you want
- **Cloud-Init** - configures VMs on first boot

## How It Works

### Template-Based Setup

Instead of installing from ISO every time, you make one template and clone it. Way faster. The template is just a base Debian image with Cloud-Init installed.

**Important gotcha**: Proxmox's built-in Cloud-Init drive (ide2) doesn't play nice with Terraform's initialization block. You need to create templates WITHOUT the Cloud-Init drive for Terraform to work properly.

### What Cloud-Init Does

On first boot, Cloud-Init handles:
1. **Network** - sets up static IPs, DNS, whatever you need
2. **Users** - adds your SSH keys, creates accounts
3. **Packages** - installs any initial software
4. **Scripts** - runs custom setup commands
5. **Files** - drops config files in place

### How a VM Gets Created

1. Start with your template (base Debian image)
2. Terraform clones it to a new VM
3. Cloud-Init config gets attached as an ISO
4. VM boots and Cloud-Init does its thing using snippet
5. QEMU agent confirms everything's ready

## Installation

### Prerequisites

#### Proxmox Setup
```bash
# Create API token for Terraform
pveum user add terraform@pve
pveum aclmod / -user terraform@pve -role Administrator
pveum user token add terraform@pve terraform -privsep 0

# Note the token - you'll need it for Terraform
```


#### Snippets creation 

Proxmox snippets allow you to inject cloud-init configurations directly into virtual machines at deployment time. They are especially useful for installing packages, updating systems, or setting initial parameters without manually accessing each VM.

For instance, I use the following simple snippet stored at /var/lib/vz/snippets/base_vm.yaml

```yaml
#cloud-config
packages:
  - qemu-guest-agent
package_update: true
power_state:
  mode: reboot
  timeout: 30
```

#### Template Creation
```bash
#!/bin/bash
# Creates two Debian 13 templates:
# - 9110 with cloudinit drive (for direct Proxmox use)
# - 9100 without cloudinit drive (for Terraform)

if [ "$EUID" -ne 0 ]; then
    echo "Run as root"
    exit 1
fi

VMID_WITH=9110
VMID_WITHOUT=9100
MEMORY=2048
BRIDGE="vmbr2"
STORAGE="vmdata"
SSH_KEY="$HOME/.ssh/authorized_keys"

echo "Downloading Debian 13 image..."
wget -q --show-progress https://cloud.debian.org/images/cloud/trixie/latest/debian-13-generic-amd64.qcow2

# Create base template with cloudinit
qm create $VMID_WITH --name debian13-cloud --memory $MEMORY --net0 virtio,bridge=$BRIDGE
qm importdisk $VMID_WITH debian-13-generic-amd64.qcow2 $STORAGE -format qcow2
qm set $VMID_WITH --scsihw virtio-scsi-pci --scsi0 $STORAGE:vm-$VMID_WITH-disk-0
qm set $VMID_WITH --ide2 $STORAGE:cloudinit --boot c --bootdisk scsi0 --serial0 socket --vga serial0
qm resize $VMID_WITH scsi0 +20G
qm set $VMID_WITH --ipconfig0 ip=10.0.100.10/24,gw=10.0.100.1

if [ -f "$SSH_KEY" ]; then
    qm set $VMID_WITH --sshkey $SSH_KEY
fi

qm template $VMID_WITH
echo "Created template $VMID_WITH with cloudinit"

# Clone for terraform (no cloudinit drive)
qm clone $VMID_WITH $VMID_WITHOUT --name debian13-cloud-template --full
qm set $VMID_WITHOUT --delete ide2
qm template $VMID_WITHOUT
echo "Created template $VMID_WITHOUT without cloudinit (for terraform)"

rm debian-13-generic-amd64.qcow2
echo "Done"
```

This script works fine for a few templates. If you need to manage a bunch of different OS templates, check out Packer instead.

## Configuration

### Provider Setup

Create `main.tf`:

```hcl
terraform {
  required_version = ">= 1.0"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.86"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.0"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox.endpoint
  api_token = var.proxmox.api_token
  insecure  = var.proxmox.insecure
}
```


### VM Resource Definition

```hcl
resource "proxmox_virtual_environment_vm" "vm" {
  for_each = { for vm in var.vms : vm.name => vm }

  name        = each.value.name
  node_name   = var.proxmox.node_name
  description = "Debian 13 VM"

  clone {
    vm_id        = var.proxmox.template_id
    full         = true
    datastore_id = var.datastore_id
    retries      = var.clone_retries
  }

  agent {
    enabled = true
    timeout = var.agent_timeout
  }

  cpu {
    cores = each.value.cpu_cores
  }

  memory {
    dedicated = each.value.memory_mb
  }

  disk {
    datastore_id = var.datastore_id
    size         = coalesce(each.value.disk_gb, var.disk_size_gb)
    interface    = var.disk_interface
    iothread     = true
    discard      = "on"
  }

  network_device {
    bridge  = each.value.bridge
    vlan_id = var.vlan_id
  }

  # Cloud-Init configuration - this is where the magic happens

  initialization {
    interface           = var.cloud_init_interface
    type                = "nocloud"
    vendor_data_file_id = var.vendor_data_file_id

    user_account {
      username = var.cloud_init_username
      password = var.cloud_init_password != "" ? var.cloud_init_password : null
      keys     = [trimspace(data.local_file.ssh_pub.content)]
    }

    ip_config {
      ipv4 {
        address = each.value.ip_address
        gateway = split("/", each.value.ip_address)[0] != each.value.ip_address ? cidrhost(each.value.ip_address, 1) : null
      }
    }

    dns {
      servers = var.dns_servers
    }
  }

  lifecycle {
    ignore_changes = [initialization["user_account"]]
  }

  started = true
  tags    = concat(var.tags, ["debian13"])
}
```

### Configuration Parameters

#### Proxmox Connection
- **endpoint**: Your Proxmox URL (https://proxmox.example.com:8006/)
- **api_token**: The token you created earlier (user@realm!token=secret)
- **insecure**: Set to true if you're using self-signed certs (totally fine for homelab)
- **node_name**: Which Proxmox node to put the VMs on

#### Cloud-Init Settings
- **username**: The default user that gets created
- **ssh_keys**: Your public SSH key for passwordless login
- **ip_address**: Static IP in CIDR format (like 10.0.100.10/24)
- **dns_servers**: Your DNS servers (probably your router or Pi-hole)
- **vendor_data**: Any custom Cloud-Init scripts you want to run

## Managing Your VMs

### Deploying

```bash
# Initialize providers
terraform init

# See what will change
terraform plan

# Deploy the VMs
terraform apply

# Get SSH commands
terraform output ssh_commands
```

### Checking Status

```bash
# See what Terraform knows about
terraform show

# List all your VMs
terraform state list

# Get details on a specific VM
terraform state show proxmox_virtual_environment_vm.vm["debian13-01"]

# Check Proxmox directly
pvesh get /nodes/pve01/qemu --output-format json | jq
```


### Adding More VMs

```bash
# Add another VM to your setup
cat >> terraform.tfvars <<EOF
  {
    name       = "debian13-03"
    cpu_cores  = 4
    memory_mb  = 4096
    ip_address = "10.0.100.50/24"
    bridge     = "vmbr0"
  }
EOF

# Apply just the new VM
terraform apply -target='proxmox_virtual_environment_vm.vm["debian13-03"]'
```

## Common Use Cases

### Testing/Dev VMs

Spin up a bunch of identical VMs for testing:

```hcl
locals {
  dev_vms = [
    for i in range(1, 6) : {
      name       = "dev-${format("%02d", i)}"
      cpu_cores  = 2
      memory_mb  = 2048
      disk_gb    = 20
      ip_address = "10.0.100.${20 + i}/24"
      bridge     = "vmbr0"
    }
  ]
}

vms = local.dev_vms
```

### Kubernetes Cluster

Set up a whole K8s cluster:

```hcl
vms = concat(
  # Control plane nodes
  [for i in range(1, 4) : {
    name       = "k8s-master-${format("%02d", i)}"
    cpu_cores  = 4
    memory_mb  = 8192
    disk_gb    = 50
    ip_address = "10.0.100.${10 + i}/24"
    bridge     = "vmbr0"
  }],
  # Worker nodes
  [for i in range(1, 6) : {
    name       = "k8s-worker-${format("%02d", i)}"
    cpu_cores  = 8
    memory_mb  = 16384
    disk_gb    = 100
    ip_address = "10.0.100.${20 + i}/24"
    bridge     = "vmbr0"
  }]
)
```

### Storage Optimization

If you're running on SSDs, enable TRIM support:

```hcl
disk {
  discard = "on"  # Enable TRIM support
  ssd     = true   # Optimize for SSD storage
}
```

Then in Cloud-Init:

```yaml
#cloud-config
runcmd:
  - echo "0 2 * * 0 root /usr/sbin/fstrim -av" >> /etc/crontab
```

## Security Notes

### API Token
- Create a dedicated user for Terraform (keeps things organized)
- Use token authentication instead of passwords
- Don't commit tokens to Git (use environment variables or .gitignore)

### Template Security
- Remove any default passwords from your template
- Disable root SSH login (use sudo instead)
- Run updates before creating the template so new VMs start fresh

## Troubleshooting

```bash
# Test if Proxmox API is reachable
curl -k -H "Authorization: PVEAPIToken=terraform@pve!terraform=your-token" \
  https://proxmox.example.com:8006/api2/json/nodes

# Check Cloud-Init logs inside a VM
sudo cat /var/log/cloud-init.log
sudo cloud-init status --long

```
