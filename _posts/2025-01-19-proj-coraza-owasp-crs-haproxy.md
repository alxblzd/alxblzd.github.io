---
title: "Coraza-SPOA and OWASP CRS on HAProxy"
article_type: post
date: 2025-01-19 15:28:00 +0100
categories: [Project, Security]
tags: [haproxy, coraza, waf, owasp, security, quic, http3]
render_with_liquid: false
alt: "HAProxy, Coraza, and CRS"
---

## Repositories

- Public repo : <https://github.com/alxblzd/ansible-oracle-haproxy-edge>

## Why I built this

HAProxy is still my preferred edge proxy. It's fast, stable, and behaves predictably under load.

I wanted proper WAF protection, but I also wanted to understand how a WAF actually works under the hood. Not just "enable it and hope for the best." I didn't want a heavy, all-in-one stack or something that hides the logic behind too many layers.

This setup forces you to understand the flow: how requests move through HAProxy, how Coraza evaluates rules, and how decisions are applied. It's not plug-and-play, but that's part of the point. You see what is happening, and you stay in control.

So I built the stack around:

- **HAProxy** at the edge
- **Coraza-SPOA** as the WAF engine

I also looked at CrowdSec and BunkerWeb, but this combination gave me clearer visibility into what was blocked and why, and it was easier to tune when something needed adjustment.

## 2026 update: QUIC + AWS-LC on ARM

The big change since the first version is HTTP/3 (QUIC) on ARM nodes with HAProxy 3.3 + AWS-LC.

HAProxy also provides official Performance Packages (HAProxy 3.2+ with modern crypto libraries): <https://www.haproxy.com/downloads>.

Main issue: on ARM, `haproxy-awslc` was not available in my environment, and I could not find a reliable prebuilt package.
So the only stable path was:

1. Build AWS-LC
2. Build HAProxy 3.3 against AWS-LC with QUIC

Building it was not the hardest part. Getting clean runtime behavior was.

Quick context before the build steps:

- **AWS-LC** is Amazon's crypto library (OpenSSL-compatible API) with very good performance and modern TLS support.
- **QUIC** is the transport behind HTTP/3 (UDP-based), useful for lower latency and better behavior on unstable networks.

For a great deep dive on TLS stack choices and tradeoffs, I strongly recommend this HAProxy article:
<https://www.haproxy.com/blog/state-of-ssl-stacks>

I chose this mostly because I wanted the challenge and wanted to really understand the full chain in production: TLS library choice, HTTP/3 behavior, logging, WAF decisions, and ban enforcement.

## 1. Install HAProxy 3.3 with AWS-LC and QUIC (ARM)

On ARM, I now default to building from source directly.
It is the most reliable way to get HAProxy 3.3 + AWS-LC + QUIC in a predictable way.


### 1.1 Build AWS-LC

```bash
sudo apt-get install -y build-essential cmake git libpcre2-dev zlib1g-dev
cd /usr/local/src
sudo git clone --branch v1.68.0 --depth 1 https://github.com/aws/aws-lc.git
cd aws-lc
sudo cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/aws-lc
sudo cmake --build build --parallel "$(nproc)"
sudo cmake --install build
```

### 1.2 Build HAProxy against AWS-LC with QUIC

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

Coraza-SPOA is in Go. I install Go, build the binary, and run it as a dedicated system user.

Install Go (pick a current stable release from `go.dev/dl/`):

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
sudo wget https://github.com/coreruleset/coreruleset/archive/refs/tags/v4.24.0.zip

mkdir -p /var/log/coraza-spoa /var/log/coraza-spoa/audit
touch /var/log/coraza-spoa/server.log /var/log/coraza-spoa/error.log /var/log/coraza-spoa/audit.log /var/log/coraza-spoa/debug.log

cp -a ./build/coraza-spoa /usr/bin/coraza-spoa
chmod 750 /usr/bin/coraza-spoa

cp -a ./example/coraza-spoa.yaml /etc/coraza-spoa/config.yaml
sed -i 's/bind: 0.0.0.0:9000/bind: 127.0.0.1:9000/' /etc/coraza-spoa/config.yaml
sed -i 's|log_file:.*|log_file: /var/log/coraza-spoa/coraza-agent.log|' /etc/coraza-spoa/config.yaml
```

## 3. How Coraza works with HAProxy

Quick refresher:

- **SPOE**: Stream Processing Offload Engine (HAProxy side)
- **SPOA**: Stream Processing Offload Agent (Coraza side)
- **SPOP**: protocol between the two

Request flow:

1. Request hits HAProxy.
2. HAProxy sends request context to Coraza over SPOE/SPOP.
3. Coraza evaluates rules (CRS + plugin rules + custom exclusions).
4. Coraza returns a decision (allow / deny / redirect / drop).
5. HAProxy enforces the decision.

Important point: Coraza does not replace HAProxy. HAProxy still controls traffic. Coraza is the WAF decision engine.

![Coraza engine flow](/assets/img/coraza_spoa_flow.webp)

### Main config files

- `/etc/haproxy/haproxy.cfg`
- `/etc/haproxy/coraza.cfg`
- `/etc/coraza-spoa/config.yaml`
- `/etc/coraza-spoa/coraza.conf`

## 4. CRS rules quick primer

Coraza uses ModSecurity-style syntax:

```text
SecRule VARIABLES "OPERATOR" "TRANSFORMATIONS,ACTIONS"
```

Example:

```bash
SecRule REQUEST_URI "@streq /index.php" "id:1,phase:1,t:lowercase,deny"
```

Phases are:

- Request headers
- Request body
- Response headers
- Response body
- Logging

Reference: <https://github.com/owasp-modsecurity/ModSecurity/wiki/Reference-Manual-(v2.x)-Processing-Phases>

## 5. CRS plugins (Nextcloud example)

For Nextcloud, I use the official plugin:

<https://github.com/coreruleset/nextcloud-rule-exclusions-plugin>

I also keep narrow, path-specific exclusions when needed.
No broad bypasses.

## 6. Real QUIC pain points in production

### 6.1 Source build side effects

With source-built HAProxy, distro defaults may be missing:

- `haproxy` user/group
- systemd unit
- `/etc/haproxy/errors/*.http`

So you can have a good binary and still fail at startup/validation.

### 6.2 Logging quality

If forwarded headers and Coraza real-IP handling are not aligned, logs can show loopback instead of real client IPs.
That makes incident response much harder.

### 6.3 Correctly banning abusive QUIC clients

This part was trickier than expected.

At first, bans looked active in Fail2ban, but abusive HTTP/3 traffic could still show up.
It is not just “TCP bad / UDP good”.

For bans to work reliably, several conditions must be met at the same time:

1. HAProxy must log sufficient context for correlation (client IP, status code, request path, timing).
2. Coraza decisions must be clearly and consistently recorded in the logs.
3. Fail2ban filters must match the actual log format (journald vs file-based logs, correct regex).
4. The ban action must block all transport paths used by clients (both TCP and UDP on port 443).
5. nftables rules must be verified in the active chains or sets after Fail2ban reloads.

If one link is wrong, enforcement looks enabled but is incomplete.

## Enforcement model

Attacker (HTTP/3 over UDP/443)  
→ HAProxy frontend  
→ Coraza deny / 403  
→ Fail2ban catches repeated events  
→ nftables bans source for **TCP and UDP**

Two important things:

- Fail2ban does not inspect QUIC packets directly, it reacts to log events.
- If logging is incomplete or delayed, enforcement will be delayed too.


### Fail2ban pattern that worked

```ini
[coraza]
action = nftables[type=allports, protocol=tcp, name=coraza-tcp]
         nftables[type=allports, protocol=udp, name=coraza-udp]

[haproxy-rate]
action = nftables[type=allports, protocol=tcp, name=haproxy-rate-tcp]
         nftables[type=allports, protocol=udp, name=haproxy-rate-udp]
```

Then check three simple things:

1. Make sure the jails are actually loaded and running:
    - fail2ban-client status
    - fail2ban-client status coraza
    - fail2ban-client status haproxy-rate

2. Verify that nftables really has the ban rules in place (and that they apply to both TCP and UDP).

3. Test it for real, from a banned IP, try hitting the server over HTTP/2 and HTTP/3 and confirm it's blocked.

Also, be realistic about QUIC. Because it reuses connections and retries differently than TCP, a client might still look “active” for a short moment right after being banned. New connections should be dropped, but existing ones can linger briefly.


## 7. False positives and exclusion strategy

What stayed stable for me:

1. Keep CRS enabled.
2. Add official app plugin when available.
3. Add small, narrow exclusions only for proven false positives.
4. Keep scanner probes blocked (`/.ssh/id_rsa`, generic probes, etc.).

For Nextcloud DAV, parser-related false positives can happen. Handle them with URI + method scoped exclusions.

## 8. Automation note

Everything is deployed with Ansible roles (WireGuard, Fail2ban, Coraza, ACME, HAProxy and post-checks) so the setup stays reproducible. Doing it by hand each time would be painful and easy to mess up.

On an Oracle Cloud free tier 4-core ARM instance, a full build takes about 10 minutes end to end. After the build, a redeployement take around 2-3mn max

## 9. Final thoughts

Enabling HTTP/3 is the not so easy part (if you are on arm :') ). Keeping enforcement and observability correct under HTTP/3 is a little challenge.
