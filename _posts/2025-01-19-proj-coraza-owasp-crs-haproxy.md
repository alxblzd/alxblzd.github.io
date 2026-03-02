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

## Update (2026): QUIC + AWS-LC on ARM

This stack evolved a lot since the initial write-up. The edge now runs HAProxy 3.3 with QUIC enabled, linked against AWS-LC, on ARM instances.

The main issue: `haproxy-awslc` was not available as a prebuilt package for my ARM target, so I had to compile HAProxy from source against a locally built AWS-LC.

Result after build validation:

- `+OPENSSL_AWSLC`
- `+QUIC`
- QUIC listener on UDP `:443`

## 1. Install HAProxy 3.3 with AWS-LC and QUIC (ARM)

I still configure the HAProxy repository first, but on ARM the AWS-LC package may be missing. In that case, build from source is the reliable path.

### 1.1 Repository setup

```bash
sudo install -d -m 0755 /usr/share/keyrings
sudo wget -qO /usr/share/keyrings/HAPROXY-key-community.asc https://pks.haproxy.com/linux/community/RPM-GPG-KEY-HAProxy
echo "deb [arch=arm64 signed-by=/usr/share/keyrings/HAPROXY-key-community.asc] https://www.haproxy.com/download/haproxy/performance/ubuntu/ha33 noble main" | sudo tee /etc/apt/sources.list.d/haproxy.list
sudo apt-get update
```

### 1.2 Build AWS-LC

```bash
sudo apt-get install -y build-essential cmake git libpcre2-dev zlib1g-dev
cd /usr/local/src
sudo git clone --branch v1.68.0 --depth 1 https://github.com/aws/aws-lc.git
cd aws-lc
sudo cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/aws-lc
sudo cmake --build build --parallel "$(nproc)"
sudo cmake --install build
```

### 1.3 Build HAProxy 3.3 against AWS-LC with QUIC

```bash
cd /usr/local/src
sudo wget -O haproxy-3.3.4.tar.gz https://www.haproxy.org/download/3.3/src/haproxy-3.3.4.tar.gz
sudo tar xzf haproxy-3.3.4.tar.gz
cd haproxy-3.3.4

sudo make -j"$(nproc)" \
  ERR=1 CC=gcc TARGET=linux-glibc \
  USE_OPENSSL_AWSLC=1 USE_QUIC=1 \
  USE_PCRE2=1 USE_ZLIB=1 \
  SSL_INC=/opt/aws-lc/include \
  SSL_LIB=/opt/aws-lc/lib \
  ADDLIB="-Wl,-rpath,/opt/aws-lc/lib"

sudo make install PREFIX=/usr SBINDIR=/usr/sbin
haproxy -vv | grep -Ei 'OPENSSL_AWSLC|QUIC'
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
sudo wget https://github.com/coreruleset/coreruleset/archive/refs/tags/v4.24.0.zip

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

For Nextcloud I use the official rule exclusion plugin, plus a narrow exclusion for `/web/config.json` to avoid noisy false positives on that path:

`https://github.com/coreruleset/nextcloud-rule-exclusions-plugin`

Quick install idea:

- Ensure a `crs/plugins/` folder exists
- Copy the plugin files there (or symlink them)
- Rename any `*.example` config to `*.conf`
- Reload HAProxy/Coraza

If you run multiple apps behind the same proxy, you can conditionally enable the plugin per host using a rule in the plugin config (I use the `Host` header for Coraza).

## Automation Note

I also keep this deployment automated with Ansible roles (HAProxy, Coraza, fail2ban, WireGuard, ACME), but the core of this setup is still the same architecture: HAProxy + Coraza-SPOA + OWASP CRS.

## Next Steps I Want to Add

- Log handling and rotation
- Rule exclusions and IP exceptions
- IP reputation or blocklists
- CRS tuning for Nextcloud and other apps
- Phase 1 vs Phase 2 explanation
- Deeper breakdown of each config file
