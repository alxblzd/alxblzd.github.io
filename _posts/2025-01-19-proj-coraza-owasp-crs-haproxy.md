---
title: "Coraza-SPOA and Owasp Coreruleset on HAproxy"
article_type: post
author: "Alxblzd"
date: 2025-01-19 15:28:00 +0100
categories: [Project, Security]
tags: [haproxy, coraza, waf, owasp, security]
render_with_liquid: false
alt: "Haproxy and coraza + crs logo"
---


# Installing Coraza and use case with OWASP CRS + haproxy

I needed a frontend for my site and landed on HAProxy. I also wanted solid WAF coverage, so I paired it with Coraza and the OWASP Core Rule Set. Here's how I set it up.

## 1. Installing HAproxy
Grab packages from https://haproxy.debian.net/

I wanted the latest HAProxy on Debian LTS, so 3.0.0 at this time:
```bash
sudo apt update
sudo apt install curl gpg
sudo su
curl https://haproxy.debian.net/bernat.debian.org.gpg | gpg --dearmor > /usr/share/keyrings/haproxy.debian.net.gpg && echo "deb [signed-by=/usr/share/keyrings/haproxy.debian.net.gpg] http://haproxy.debian.net bookworm-backports-3.0 main" > /etc/apt/sources.list.d/haproxy.list
exit
sudo apt update
sudo apt install haproxy=3.0.\*
```

## 2. Installation of Coraza-SPOA

Install Go first (grab the latest stable from https://go.dev/dl/):

```bash
wget https://go.dev/dl/go1.23.5.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.23.5.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
echo 'export GOPATH=$HOME/go' >> ~/.bashrc
source ~/.bashrc
#This command should return the version if everything is good
go version  # should print the version
```


Install Coraza SPOA:

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
Now create directories, copy configs, and set up logging:
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
You now have a basic Coraza SPOA install.


## 3. Coraza integration with HAproxy

SPOE: Stream Processing Offload Engine. \
SPOA: Stream Processing Offload Agent. \
SPOP: Stream Processing Offload Protocol. \
WAF: Web Application Firewall. 

HAProxy uses SPOE to send requests to the SPOA and get responses back for processing.

Communication between SPOE and the SPOA happens via the SPOP (2 & 5). The result of the scan is sent back to HAProxy to authorize or block the traffic.


![Coraza_engine](assets/img/coraza_spoa_flow.webp)

### Configuration files


* /etc/haproxy/haproxy.cfg - HAProxy main configuration
* /etc/haproxy/coraza.cfg - HAProxy SPOE configuration
* /etc/coraza-spoa/config.yml - Coraza SPOA main configuration
* /etc/coraza-spoa/coraza.conf - Coraza engine configuration

### CRS Rules syntax
To simplify:

`SecRule` is a ModSecurity directive that Coraza understands. A rule has four parts:

- Variables - Instructs ModSecurity where to look (sometimes called Targets)
- Operators - Instructs ModSecurity when to trigger a match
- Transformations - Instructs ModSecurity how it should normalize variable data
- Actions - Instructs ModSecurity what to do if a rule matches 

The structure of the rule is as follows:

SecRule VARIABLES "OPERATOR" "TRANSFORMATIONS,ACTIONS" 
A very basic rule looks as follows:
``` bash
SecRule REQUEST_URI "@streq /index.php" "id:1,phase:1,t:lowercase,deny"
```

#### Phases
ModSecurity processes rules in five phases during the request cycle:

- Request Headers: First stage where the server reads the incoming request headers from the client.

- Request Body: Once the headers are read, ModSecurity then processes the body of the request. This is where most application-specific security rules are applied.

- Response Headers: In this phase, ModSecurity checks the headers before sending the response back to the client.

- Response Body: After headers are set, ModSecurity checks the body of the response, looking for sensitive information or errors before it reaches the client.

- Logging: Finally, after all other checks, ModSecurity logs the transaction and can modify how the logging is handled.


[More details here : https://github.com/owasp-modsecurity/ModSecurity/wiki/Reference-Manual-(v2.x)-Processing-Phases](https://github.com/owasp-modsecurity/ModSecurity/wiki/Reference-Manual-(v2.x)-Processing-Phases)

### To continue
- ansible playbook
- Logs handling
- Disable Rules, make exception for an IP address
- IP reputation, blocklist
- Exclusion for nextcloud or others services
- Phase 1 and Phase 2 to explain
- more details on conf files
