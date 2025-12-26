---
title: "Suricata IPS on pfsense"
author: "Alxblzd"
date: 2024-12-07 20:05:00 +0100
categories: [Project, Security]
tags: [pfsense, suricata, ips, security, networking]
render_with_liquid: false
alt: "Suricata pfsense logo"
---


# Installing IDS/IPS on pfSense with Suricata

Installing an Intrusion Detection and Intrusion Prevention Systems (IDS/IPS) on pfSense,

Focus on Suricata, an open-source solution that monitors network traffic, detects threats, and can block them in real time. 

## 1. Pre-Installation Considerations

2 way of implementing it on pfsense, **Inline mode vs. Legacy mode**:

- **Inline mode**: Actively blocks threats in real time.
- **Legacy mode**: Captures a copy (pcap) of transiting packets and allows the traffic to pass through before analyzing it. While it can block an IP address, it still permits traffic to flow even if it hasn't determined whether the content is malicious.

Im going to use the Inline mode for a more precise way to block malicious actors

## 2. Installation of Suricata

A step-by-step walkthrough of installing Suricata on pfSense, including:

- Enabling the necessary repositories and dependencies.
- Installing the Suricata package.
- Configuring your network interfaces.
- Testing rules with quick fuzzing of url.

## 3. Sources of Rules

Theres different rules sources available in Suricata, each with unique gathering of threat intelligence:

- **Snort**: Proprietary rules providing high-quality threat detection.
- **Emerging Threats (ET)**: Free and open-source rules covering a wide range of threats.
- **Community**: Basic, community-contributed rules.
- **GeoIP**: gather informations on where treat probably came from
  

## 4. Managing Rules

You have multiples categories to handle rules differently:

- **SID management**: Enabling or disabling specific Signature ID rules.
- **DROP all categories**: Dropping all packets matching rules in specific categories for better threat prevention.
- **Excluding rules**: Excluding certain rules from categories to minimize false positives and reduce noise in your alerts.

### 4.1 Disabling Rules

There are cases where you might need to disable specific rules that generate unnecessary alerts. We’ll walk through the process of disabling individual rules to fine-tune your Suricata configuration.

## 6. Testing Suricata

Testing is crucial to ensure that Suricata effectively detects and blocks threats. 
For the moment I only tried fuzzing my website with fuff to see how it work:


```bash
sudo apt install git
wget https://go.dev/dl/go1.23.2.linux-amd64.tar.gz
sudo su
rm -rf /usr/local/go && tar -C /usr/local -xzf go1.23.2.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
exit
git clone https://github.com/ffuf/ffuf ; cd ffuf ; go get ; go build
wget https://raw.githubusercontent.com/six2dez/OneListForAll/refs/heads/main/onelistforallmicro.txt
ffuf -c -w onelistforallmicro.txt -u [target.com]/FUZZ
```


### To continue
- add screenshot
- add which interface to monitor and best practices
- limitation on interface with vlan, need one dedicated interface
- Logs handling
- More details on source of rules (ETOPEN, Abuse.ch Botnet C2, GeoLite2, how to snort rules )
- more details interface configuration

