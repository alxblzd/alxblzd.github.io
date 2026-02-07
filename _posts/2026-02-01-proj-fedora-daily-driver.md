---
title: "Fedora Atomic Sway as a daily driver"
article_type: post
date: 2026-02-01 14:00:00 +0100
categories: [Linux, DevOps, Workflow]
tags: [fedora, atomic, sway, wayland, devops, homelab, dotfiles]
render_with_liquid: false
alt: "Fedora Atomic Sway desktop workflow"
image: /assets/img/fedora_atomic.webp
---


## Fedora Atomic Sway as a daily driver !

Starting a new year felt like a great time to reevaluate my workstation setup. I don't want my OS to be exciting (okay, maybe a little). I want it to be boring, predictable, and modern enough to not get in my way.

My workstation is not just “a random Linux laptop”. It's the pc I use every day to manage VMs, interact with resources, write Terraform, Ansible, and tools in Python etc....

This is a short recap of my use/setup of Fedora Atomic.

I did consider NixOS, but I didn't want my OS to become another project and NixOS isn't exactly lightweight. Fedora Atomic hit the sweet spot. The setup was super super easy, one day, clean install, minimal tweaks, done.

### 1. Life before Fedora Atomic, Debian Testing

Before that, I was running Debian Testing, still with the excellent sway WM, Debian Stable was a little too conservative for my needs. At the time,  maybe less so now, sway versions were outdated after release, which made testing a not so obvious middle ground.

It mostly worked but also came with frequent updates and occasional frustration.

#### Why sway

I've been on Sway long enough to be at ease with it, works well easily.

I tried Hyprland, lots of motion but it didn't bring anything meaningful to my workflow. With Sway, everything works and most important, i still have my existing habits :).

### 2. What Fedora Atomic is

Fedora Atomic is built around immutability, the base OS is delivered as an OSTree image, not as individual RPMs.

this command will shows which immutable OS image you're running now and what changes (updates, layered packages, rollbacks) will apply on the next boot.
```bash
rpm-ostree status
```
System updates are atomic and a new OS image is prepared alongside the current one.
```bash
sudo rpm-ostree upgrade
```
The root filesystem is read-only by default.

If you need system-level packages, you layer RPMs.
Layering means rpm-ostree rebuilds the OS image with those packages included, instead of modifying the running system.
```bash
rpm-ostree install restic
```

The new image (after update or layering rpms) becomes active only after reboot:
```bash
systemctl reboot
```

Layer a package only if it's system level something needed at boot, before login, or for core hardware and services.


### 3. Packages concepts, flatpak, toolbox
If you don't want to reboot, don't layer it.

You have two main options:
Dev tools and Cli → use a container with Toolbox
Desktop apps  → use Flatpak

Toolbox is a way to run a mutable Fedora environment on top of an immutable system, it use podman. It creates a container that looks and feels like a normal Fedora install.
```bash
toolbox enter
sudo dnf install ansible
```
Flatpak is designed for desktop applications.
Apps run sandboxed, with isolated dependencies and independent updates.
```bash
flatpak install flathub org.mozilla.Firefox
```
Together, Toolbox and Flatpak keep the OS clean while giving you flexibility.


### 4. I and everyone dotfiles handling

using the gracious Git and GNU Stow combo

All configuration files live in a single Git repository at the root of home directory in ~/ 

Stow then creates symlinks from this repository into the right locations.
```bash
mkdir ~/dotf-stow
cd ~/dotf-stow
cp ~/.bashrc .
cp -r ~/.config .
stow .
```
Stow links ~/dotf-stow/.bashrc → ~/.bashrc

### 5. Alias handling, .zshrc, .bashrc

I treat my aliases like this: when the shell starts, ~/.bashrc or ~/.zshrc loads and immediately hands off to main.sh.
All my aliases live in main.sh, so they're defined once and work the same way no matter which shell I'm using.


```bash
[alex ~/dotf-stow(main)]$ cat .bashrc 
# ~/.bashrc

# no double sourcing
if [ -z "$BASHRCSOURCED" ]; then
    BASHRCSOURCED="Y"

    # Only interactive shells
    if [ "$PS1" ]; then
        # Source main config
        [ -f "$HOME/.shellrc.d/main.sh" ] && source "$HOME/.shellrc.d/main.sh"
    fi
fi
```

Some aliases :

```bash
alias v='vi' # Vim is named vi on Fedora, it uses vi as a symbolic name for vim. 
alias df='df -h'
alias .='cd ..'
alias ..='cd ../..'
alias ...='cd ../../..'
alias ll='ls -lah --color=auto'
alias ls='ls -lhF --color=auto'
alias c='clear'
alias mkdir='mkdir -pv'
alias icat='kitty +kitten icat --align left'
alias tb='toolbox run -- bash -i '

alias k='kubectl'
alias kgp='kubectl get pods'
alias kl='kubectl logs -f'
alias kex='kubectl exec -it'
alias kga='kubectl get all'
alias kd='kubectl describe'

alias p='podman'
alias pps='podman ps -a'
alias pr='podman run -it'

alias gs='git status -sb'
```

### 6. VScodium setup
Installed as a flatpak, so running sandboxed. The integrated terminal in VSCodium runs the sandboxed shell not your host shell.

It means limited filesystem and system access and doesn't see tools installed on the host. On Fedora Atomic, this is expected.

You can work over SSH or use the terminal as a launcher and spawn commands on the host:
```bash
flatpak-spawn hostname
```

a great combo is to run the container toolbox we talked about before :

```bash
flatpak-spawn toolbox run -- bash -i
```
And even better we can make it as a default integrated terminal, in vscodium you can use a new profile inside your settings.json for user : 
```bash

        "toolbox": {
            "path": "flatpak-spawn",
            "args": ["--host", "toolbox", "run", "--", "bash", "-i"]
        }
    },
    "terminal.integrated.defaultProfile.linux": "toolbox",
```
![fedora_vscodium](assets/img/fedora_vscodium.webp)

Perfect ! 

### 7. Screenshot setup
Now lets talk about setting up a near perfect screenshot utilie, swappy, Prerequisite it to have : 
```bash
grim slurp wl-copy
```

I already had them installed by default except for swappy. I'm layering it because it's more than just a CLI tool, it's tightly integrated with the OS and the window manager.

```bash
sudo rpm-ostree install swappy
```
Then you have to setup the swappy default conf in our dotfiles managed
```bash
vi dotf-stow/.config/swappy/config
```
then
```bash
[Default]
save_dir=$HOME/Pictures
save_filename_format=screenshot-%Y%m%d-%H%M%S.png
show_panel=true
paint_mode=rectangle
fill_shape=false
```
and to finish, add this to sway : 
```bash
v dotf-stow/.config/sway/config.d/20-keys.conf
```
```bash
bindsym $mod+Shift+a exec grim -g "$(slurp)" - | swappy -f -
```
look at this beautiful screenshot of my screenshot tool,swappy ! 

![swappy_screenshot](assets/img/swappy_screenshot.webp)

### 8. Restic for encrypted backup

On my laptop

```bash
rpm-ostree install restic

```

On my backup server : 
```bash
sudo apt update && sudo apt install restic

# Dedicated user for backups 
sudo adduser --disabled-password --gecos "" bkpuser

# Base backup directory
sudo mkdir -p /backups
sudo chmod 711 /backups

# Restic repository location
sudo mkdir -p /backups/laptop
sudo chown -R bkpuser:bkpuser /backups/laptop
sudo chmod 700 /backups/laptop

# Reuse an already provisioned SSH public key
sudo mkdir -p /home/bkpuser/.ssh
sudo cat /home/ansible/.ssh/authorized_keys >> /home/bkpuser/.ssh/authorized_keys

# Permissions required by sshd
sudo chown -R bkpuser:bkpuser /home/bkpuser/.ssh
sudo chmod 700 /home/bkpuser/.ssh
sudo chmod 600 /home/bkpuser/.ssh/authorized_keys
```

Create the script  :

```bash
#!/usr/bin/env bash

REPO="sftp:bkpuser@myserverdomain.tld:/backups/laptop"

echo "Checking repo..."
if ! restic -r "$REPO" cat config >/dev/null 2>&1; then
  echo "Repository not found, creating"
  restic -r "$REPO" init
fi

echo "Running backup"
restic -r "$REPO" backup \
  "$HOME/Documents" \
  "$HOME/Desktop" \
  "$HOME/Pictures" \
  "$HOME/dotf-stow" \
  "$HOME/.ssh" \
  "$HOME/.local/share/keyrings"

echo "Cleaning old backups"
restic -r "$REPO" forget --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --prune

echo "OK - Backup finished"

```

executable and run : 
``` bash
chmod +x ~/restic-bkp.sh
./restic-bkp.sh
```

Restic will prompt:
``` 
enter password for repository:
```
![restic_output](assets/img/restic_backup.webp)


And the complete desk : 
![complete_desk](assets/img/complete_desk.webp)
