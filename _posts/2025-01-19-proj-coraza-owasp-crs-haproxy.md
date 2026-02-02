---
title: "Coraza-SPOA and OWASP CRS on HAProxy"
article_type: post
date: 2025-01-19 15:28:00 +0100
categories: [Project, Security]
tags: [haproxy, coraza, waf, owasp, security]
render_with_liquid: false
alt: "HAProxy, Coraza, and CRS"
---

## Why This Setup

The old mighty HAProxy is still my go-to gatekeeper. I needed a fast, reliable frontend for my site, and then I wanted real WAF coverage without dragging in a heavyweight stack. I considered CrowdSec and BunkerWeb, but I preferred the hard-way setup to learn the basics properly. So I paired HAProxy with Coraza-SPOA and the OWASP Core Rule Set. This is the exact setup I run in my lab.

What it gives me:

- HAProxy as the edge proxy
- Coraza-SPOA as the WAF engine
- OWASP CRS for sensible, battle-tested rules

## 1. Install HAProxy (Debian Trixie)

`haproxy.debian.net` is a wizard that helps you choose the right repo for your OS and the HAProxy version you want. In my case, I am running Debian Trixie (13) and wanted HAProxy `3.0-stable (LTS)`, so I installed the packaged 3.0 series.

```bash
apt-get update
apt-get install haproxy=3.0.*
```

## 2. Install Coraza-SPOA

Coraza-SPOA is written in Go. I install Go, build the agent, and run it as a system user.

Install Go (grab the latest stable from `go.dev/dl/`):

```bash
wget https://go.dev/dl/go1.23.5.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.23.5.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
echo 'export GOPATH=$HOME/go' >> ~/.bashrc
source ~/.bashrc
go version
```

Build and install Coraza-SPOA:

```bash
sudo apt install git make gcc pkg-config wget unzip
git clone https://github.com/corazawaf/coraza-spoa.git
cd ./coraza-spoa

go run mage.go build

addgroup --quiet --system coraza-spoa
adduser --quiet --system --ingroup coraza-spoa --no-create-home --home /nonexistent --disabled-password coraza-spoa
```

Create directories, fetch CRS, and adjust config:

```bash
mkdir -p /etc/coraza-spoa
cd /etc/coraza-spoa

# Check latest version: https://github.com/coreruleset/coreruleset/releases
sudo wget https://github.com/coreruleset/coreruleset/archive/refs/tags/v4.10.0.zip

mkdir -p /var/log/coraza-spoa /var/log/coraza-spoa/audit
touch /var/log/coraza-spoa/server.log /var/log/coraza-spoa/error.log /var/log/coraza-spoa/audit.log /var/log/coraza-spoa/debug.log

cp -a ./build/coraza-spoa /usr/bin/coraza-spoa
chmod 750 /usr/bin/coraza-spoa

cp -a ./example/coraza-spoa.yaml /etc/coraza-spoa/config.yaml
sed -i 's/bind: 0.0.0.0:9000/bind: 127.0.0.1:9000/' /etc/coraza-spoa/config.yaml
sed -i 's|log_file:.*|log_file: /var/log/coraza-spoa/coraza-agent.log|' /etc/coraza-spoa/config.yaml
```

At this point, Coraza-SPOA is installed and ready.

## 3. Wire Coraza into HAProxy

A quick terminology refresher:

- SPOE: Stream Processing Offload Engine (HAProxy side)
- SPOA: Stream Processing Offload Agent (Coraza side)
- SPOP: Stream Processing Offload Protocol (wire protocol)
- WAF: Web Application Firewall

HAProxy sends request data to Coraza via SPOE/SPOP, Coraza evaluates rules, and HAProxy allows or blocks based on that decision.

![Coraza engine flow](/assets/img/coraza_spoa_flow.webp)

### Configuration files

- `/etc/haproxy/haproxy.cfg` for HAProxy core config
- `/etc/haproxy/coraza.cfg` for HAProxy SPOE config
- `/etc/coraza-spoa/config.yaml` for Coraza-SPOA config
- `/etc/coraza-spoa/coraza.conf` for the Coraza engine config

## 4. CRS Rules Primer

Coraza uses ModSecurity-style rules (`SecRule`). A rule has four parts:

- Variables (targets)
- Operators (how to match)
- Transformations (normalize input)
- Actions (what to do when it matches)

Structure:

```text
SecRule VARIABLES "OPERATOR" "TRANSFORMATIONS,ACTIONS"
```

Example:

```bash
SecRule REQUEST_URI "@streq /index.php" "id:1,phase:1,t:lowercase,deny"
```

### Rule Phases

ModSecurity processes rules in phases:

- Request Headers
- Request Body
- Response Headers
- Response Body
- Logging

Reference: https://github.com/owasp-modsecurity/ModSecurity/wiki/Reference-Manual-(v2.x)-Processing-Phases

## CRS Plugins (Nextcloud Example)

Plugins are optional rule packs that extend CRS or disable noisy rules for a specific app. I keep the core ruleset lean and add plugins only when I need them. It reduces false positives and keeps the “attack window” small.

How they fit in:

- CRS config loads first
- Plugin config loads next
- Plugin rules run before CRS
- CRS rules run
- Plugin rules run after CRS

For Nextcloud I use the official rule exclusion plugin:

`https://github.com/coreruleset/nextcloud-rule-exclusions-plugin`

Quick install idea:

- Ensure a `crs/plugins/` folder exists
- Copy the plugin files there (or symlink them)
- Rename any `*.example` config to `*.conf`
- Reload HAProxy/Coraza

If you run multiple apps behind the same proxy, you can conditionally enable the plugin per host using a rule in the plugin config (I use the `Host` header for Coraza).

## Next Steps I Want to Add

- Ansible playbook
- Log handling and rotation
- Rule exclusions and IP exceptions
- IP reputation or blocklists
- CRS tuning for Nextcloud and other apps
- Phase 1 vs Phase 2 explanation
- Deeper breakdown of each config file
