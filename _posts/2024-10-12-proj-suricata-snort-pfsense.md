---
title: "[Project] Coraza-SPOA and Owasp Coreruleset on HAproxy"
author: Alxblzd
date: 2025-01-19 15:28:00 +0100
categories: [Project, Electronic]
tags: [Pfsense, Coraza, IPS]
render_with_liquid: false
image: /assets/img/logo/haproxy_logo.webp
alt: "Haproxy and coraza + crs logo"
---


# Installing Coraza and use case with OWASP CRS + haproxy

Installing an Intrusion Detection and Intrusion Prevention Systems (IDS/IPS) on pfSense,

Focus on Suricata, an open-source solution that monitors network traffic, detects threats, and can block them in real time. 

## 1. Installing HAproxy
You can use : https://haproxy.debian.net/

```bash
# In my case I wanted the last version of haproxy in LTS realse so the 3.0.0 at this time
sudo apt update
sudo apt install curl gpg
sudo su
curl https://haproxy.debian.net/bernat.debian.org.gpg | gpg --dearmor > /usr/share/keyrings/haproxy.debian.net.gpg && echo "deb [signed-by=/usr/share/keyrings/haproxy.debian.net.gpg] http://haproxy.debian.net bookworm-backports-3.0 main" > /etc/apt/sources.list.d/haproxy.list
exit
sudo apt update
sudo apt install haproxy=3.0.\*
```

## 2. Installation of Coraza-SPOA

GO installation, check lastest stable here : wget https://go.dev/dl/

```bash
wget https://go.dev/dl/go1.23.5.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.23.5.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
echo 'export GOPATH=$HOME/go' >> ~/.bashrc
source ~/.bashrc
#This command should return the version if everything is good
go version
```


Here we start the installation of Coraza SPOA

```bash

sudo apt install git make gcc pkg-config wget unzip
git clone https://github.com/corazawaf/coraza-spoa.git
cd ./coraza-spoa
#compilation
go run mage.go build




# create user and group
addgroup --quiet --system coraza-spoa
adduser --quiet --system --ingroup coraza-spoa --no-create-home --home /nonexistent --disabled-password coraza-spoa

```
We are not over yet, even if we have compiled coraza spoa, we still need to create te directory and copy configuration files and even activate the service, let's go :
```bash
mkdir -p /etc/coraza-spoa
cd /etc/coraza-spoa
#Check latest version : https://github.com/coreruleset/coreruleset/releases
sudo wget https://github.com/coreruleset/coreruleset/archive/refs/tags/v4.10.0.zip

mkdir -p /var/log/coraza-spoa /var/log/coraza-spoa/audit
touch /var/log/coraza-spoa/server.log /var/log/coraza-spoa/error.log /var/log/coraza-spoa/audit.log /var/log/coraza-spoa/debug.log
cp -a ./build/coraza-spoa /usr/bin/coraza-spoa
chmod 750 /usr/bin/coraza-spoa

cp -a ./example/coraza-spoa.yaml /etc/coraza-spoa/config.yaml
sed -i 's/bind: 0.0.0.0:9000/bind: 127.0.0.1:9000/' /etc/coraza-spoa/config.yaml
sed -i 's|log_file:.*|log_file: /var/log/coraza-spoa/coraza-agent.log|' /etc/coraza-spoa/config.yaml
```
Good, now we have a default installation






#### How it works

SPOE: Stream Processing Offload Engine.
SPOA: Stream Processing Offload Agent.
SPOP: Stream Processing Offload Protocol.
WAF: Web Application Firewall.

Coraza SPOA powers the Coraza WAF used by HAProxy. It works by using the Stream Processing Offload Engine (SPOE) to send requests to the Stream Processing Offload Agent (SPOA) for processing.

Communication between HAProxy and the SPOA happens via the Stream Processing Offload Protocol (SPOP). The result of the scan is then sent back to HAProxy to authorize or block the traffic.


### To continue
- ansible playbook
- Logs handling
- Disable Rules, make exception for an IP address
- IP reputation, blocklist
- Exclusion for nextcloud or others services