---
title: "Automating Proxmox with Terraform and Cloud-Init"
article_type: post
date: 2025-11-06 20:34:00 +0100
categories: [Infrastructure, Automation]
tags: [terraform, proxmox, cloud-init, virtualization, automation]
render_with_liquid: false
image: /assets/img/proxmox/proxmox1.webp

---

## Terraform + Proxmox Automation

Terraform spins up VMs in Proxmox without clicking through the web UI every time. Define the VMs in code and let Terraform do the work.

- Uses the BPG [Proxmox Provider](https://github.com/bpg/terraform-provider-proxmox)
- Cloud-Init handles initial setup

This is the homelab pattern I use to go from zero to SSH-ready VMs with almost no manual clicks.

Full working example on [https://github.com/alxblzd/proxmox-terraform-pbks/tree/main](https://github.com/alxblzd/proxmox-terraform-pbks/tree/main)


## How It Works

### Template-Based Setup

Instead of installing from ISO every time, create one template and clone it. Much faster. The template is a base Debian image with Cloud-Init installed.

### What Cloud-Init Does

On first boot, Cloud-Init handles:
1. **Network** - sets static IPs, DNS, whatever you need
2. **Users** - adds SSH keys, creates accounts
3. **Packages** - installs initial software
4. and more

### How a VM Gets Created

1. Start with your template (base Debian image with cloud-init)
2. Terraform clones it to a new VM
3. Cloud-Init config (Proxmox snippet) gets attached as an ISO
4. VM boots and Cloud-Init does its thing
5. You SSH in with your key and start working

### Prerequisites

#### Proxmox Setup
Run this once on Proxmox to give Terraform the right scope without using your own account:
```bash
# Create API token for Terraform
pveum user add terraform@pve
sudo pveum role add Terraform -privs "Realm.AllocateUser, VM.PowerMgmt, VM.GuestAgent.Unrestricted, Sys.Console, Sys.Audit, Sys.AccessNetwork, VM.Config.Cloudinit, VM.Replicate, Pool.Allocate, SDN.Audit, Realm.Allocate, SDN.Use, Mapping.Modify, VM.Config.Memory, VM.GuestAgent.FileSystemMgmt, VM.Allocate, SDN.Allocate, VM.Console, VM.Clone, VM.Backup, Datastore.AllocateTemplate, VM.Snapshot, VM.Config.Network, Sys.Incoming, Sys.Modify, VM.Snapshot.Rollback, VM.Config.Disk, Datastore.Allocate, VM.Config.CPU, VM.Config.CDROM, Group.Allocate, Datastore.Audit, VM.Migrate, VM.GuestAgent.FileWrite, Mapping.Use, Datastore.AllocateSpace, Sys.Syslog, VM.Config.Options, Pool.Audit, User.Modify, VM.Config.HWType, VM.Audit, Sys.PowerMgmt, VM.GuestAgent.Audit, Mapping.Audit, VM.GuestAgent.FileRead, Permissions.Modify"
sudo pveum aclmod / -user terraform@pve -role Terraform
sudo pveum user token add terraform@pve provider --privsep=0

# Note the token - you'll need it for later
```


#### Snippets creation 

Proxmox snippets inject cloud-init configurations into VMs at deployment time. They set initial parameters without logging into each VM.

I keep this tiny snippet at `/var/lib/vz/snippets/base_vm.yaml`:

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

This script works fine for a few templates. If you need to manage a bunch of different OS templates, check out Packer instead. Run it directly on the Proxmox shell and tweak the bridge/storage IDs for your setup.

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

Pinning provider versions like this keeps upgrades from surprising you later.


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
- **insecure**: Set to true for self-signed certs (fine for homelab)
- **node_name**: Which Proxmox node to put the VMs on

#### Cloud-Init Settings
- **username**: Default user to create
- **ssh_keys**: Public SSH key for passwordless login
- **ip_address**: Static IP in CIDR format (10.0.100.10/24, etc.)
- **dns_servers**: DNS servers (router or Pi-hole, usually)
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

# Apply only the new VM
terraform apply -target='proxmox_virtual_environment_vm.vm["debian13-03"]'
```
> `cat >>` appends to `terraform.tfvars`; double-check before committing it.

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
- Create a dedicated user for Terraform
- Use token authentication instead of passwords
- Don't commit tokens to Git (use environment variables or .gitignore)

### Template Security
- Remove any default passwords from your template
- Disable root SSH login (use sudo instead)
- Run updates before creating the template so new VMs start fresh

## Cloud-Init and VyOS

If you're also running VyOS, you can deploy it with cloud-init, but the format differs from standard Linux. VyOS only supports two top-level keys:

- **vyos_config_commands**: VyOS CLI commands executed on first boot
- **write_files**: Custom files written to the system

### VyOS Cloud-Init Format

Here's what a VyOS cloud-init snippet looks like:

```yaml
#cloud-config
vyos_config_commands:
  - set system host-name 'vyos-router'
  - set system time-zone 'UTC'
  - set system login user ansible authentication public-keys key-01 key 'AAAAB3NzaC...'
  - set system login user ansible authentication public-keys key-01 type 'ssh-rsa'
  - set interfaces ethernet eth0 address '192.168.1.1/24'
  - set interfaces ethernet eth0 description 'WAN'
  - set protocols static route 0.0.0.0/0 next-hop '192.168.1.254'
  - set service ssh port '22'
  - commit
  - save
```

**Important:** Standard cloud-init directives like `users:`, `packages:`, or `runcmd:` don't work with VyOS. You must use VyOS configuration commands.

### Uploading Cloud-Init Snippets with Terraform

Instead of manually creating snippets on the Proxmox server, you can upload them directly using Terraform. The BPG Proxmox provider includes a `proxmox_virtual_environment_file` resource for this:

```hcl
resource "proxmox_virtual_environment_file" "vyos_userdata" {
  for_each     = { for vm in var.vyos_vms : vm.name => vm }
  datastore_id = "local"  # Or your snippets datastore
  node_name    = "pve01"
  content_type = "snippets"

  source_raw {
    file_name = "cloud-init-${each.key}.yml"
    data = templatefile("${path.module}/cloud-init-vyos.tpl.yml", {
      hostname    = each.value.hostname
      wan_ip      = each.value.wan_ip
      wan_gateway = each.value.wan_gateway
      timezone    = var.timezone
      ssh_keys    = var.ssh_keys
    })
  }
}
```

Then reference the snippet in your VM resource:

```hcl
resource "proxmox_virtual_environment_vm" "vyos" {
  for_each = { for vm in var.vyos_vms : vm.name => vm }

  name      = each.value.name
  node_name = var.proxmox.node_name

  clone {
    vm_id = var.vyos_template_id
    full  = true
  }

  # Reference the uploaded cloud-init snippet
  initialization {
    type              = "nocloud"
    datastore_id      = "local"
    user_data_file_id = proxmox_virtual_environment_file.vyos_userdata[each.key].id
  }
}
```

### Benefits of Terraform-Managed Snippets

- Snippets are version-controlled alongside your Terraform code
- No manual SSH access to Proxmox needed
- Easy to template snippets with different variables per VM
- Terraform tracks snippet changes and updates them automatically

For a complete working example with VyOS deployment and zone-based firewall configuration, check out the [deploy-vyos-stack](https://github.com/alxblzd/deploy-vyos-stack) repository.

## Troubleshooting
These are the first checks I run when something feels off:

```bash
# Test if Proxmox API is reachable
curl -k -H "Authorization: PVEAPIToken=terraform@pve!terraform=your-token" \
  https://proxmox.example.com:8006/api2/json/nodes

# Check Cloud-Init logs inside a VM
sudo cat /var/log/cloud-init.log
sudo cloud-init status --long

```

Once those pass, the usual culprit is a typo in variables or a missing snippet reference. Checking `terraform plan` again usually shows it.
