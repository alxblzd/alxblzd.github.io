---
title: "[Project] Suricata IPS on pfsense"
author: Alxblzd
date: 2024-09-22 14:45:00 +0100
categories: [Project, Electronic]
tags: [Pfsense, Suricata, IPS]
render_with_liquid: false
image: /assets/img/logo/suricata_logo.webp
alt: "Suricata pfsense logo"
---


# Installing IDS/IPS on pfSense with Suricata

Today, we will dive into installing Intrusion Detection and Intrusion Prevention Systems (IDS/IPS) on pfSense, with a focus on Suricata. Suricata is a robust, open-source tool that monitors network traffic, detects threats, and can block them in real time. We’ll cover the entire process, from installation to configuration, along with key considerations for setting up your own Suricata instance.

## 1. Pre-Installation Considerations

Understanding system requirements and network needs is crucial for optimal performance before setting up Suricata. We will also introduce the key difference between **Inline mode vs. Legacy mode**:

- **Inline mode**: Actively blocks threats in real time.
- **Legacy mode**: Captures a copy (pcap) of transiting packets and allows the traffic to pass through before analyzing it. While it can block an IP address, it still permits traffic to flow even if it hasn't determined whether the content is malicious.

## 2. Installation of Suricata

A step-by-step walkthrough of installing Suricata on pfSense, including:

- Enabling the necessary repositories and dependencies.
- Installing the Suricata package.
- Configuring your network interfaces.

## 3. Categories of Rules and Functioning

We’ll explore the different rule categories available in Suricata, each with unique sources of threat intelligence:

- **Snort**: Proprietary rules providing high-quality threat detection.
- **Emerging Threats (ET)**: Free and open-source rules covering a wide range of threats.
- **Community**: Basic, community-contributed rules.
  
Selecting the right rule categories and understanding their functionality is key to optimizing detection capabilities.

## 4. Managing Rules

Effective rule management ensures your IDS/IPS is both secure and efficient. Key areas to focus on include:

- **SID management**: Enabling or disabling specific Signature ID rules.
- **DROP all categories**: Dropping all packets matching rules in specific categories for better threat prevention.
- **Excluding rules**: Excluding certain rules from categories to minimize false positives and reduce noise in your alerts.

## 5. Disabling Rules

There are cases where you might need to disable specific rules that generate unnecessary alerts. We’ll walk through the process of disabling individual rules to fine-tune your Suricata configuration.

## 6. Testing Suricata and Fuzzing Websites

Testing is crucial to ensure that Suricata effectively detects and blocks threats. Best practices for testing your IDS/IPS include:

- Using **fuzzing websites** to simulate attacks.
- Monitoring Suricata’s performance and detection accuracy.

By following these steps, you’ll be well-prepared to install, configure, and manage Suricata on pfSense, providing your network with a strong IDS/IPS tailored to your needs.



Inline vs legacy mode :


Categories of rules way of functioning :
snort, ET cat, community, SNORT



Way to disable rules :


managing rules : 
SID management, DROP all categories, exclude rules from categories


Testing suricata, fuzzing website :
sudo apt install git
wget https://go.dev/dl/go1.23.2.linux-amd64.tar.gz
sudo su
rm -rf /usr/local/go && tar -C /usr/local -xzf go1.23.2.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
exit
git clone https://github.com/ffuf/ffuf ; cd ffuf ; go get ; go build
wget https://raw.githubusercontent.com/six2dez/OneListForAll/refs/heads/main/onelistforallmicro.txt
ffuf -c -w onelistforallmicro.txt -u [target.com]/FUZZ