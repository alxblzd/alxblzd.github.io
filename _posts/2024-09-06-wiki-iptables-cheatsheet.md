---
title: "Iptables cheatsheet"
article_type: cheatsheet
date: 2024-09-06 18:10:00 +0200
categories: [Networking, Security]
tags: [iptables, network, linux, firewall, tutorial]
render_with_liquid: false
alt: "netfilter logo"
---

# Iptables Infos

## Introduction

In Linux, firewall is handled by Netfilter, a kernel module that controls which network packets are permitted to enter or leave the system.

Iptables serves as the user-space tool that interacts with Netfilter, providing a command-line interface to define and manage the filtering rules. 

We can view Netfilter as the backend that performs the filtering, and iptables as the frontend to configure it.

###  Chains

Iptable use 3 majors chains on which we can control and act on packet received,
These chain are : 
- INPUT   : Incoming traffic destined for the firewall
- OUTPUT  : Outgoing traffic originating from the firewall
- FORWARD : Traffic passing through the firewall (transit traffic)

### Default Policy
After installing iptables, the firewall capabilities are installed but not yet active. By default, the firewall is fully open, meaning :
- All chains are ACCEPTING traffic

```bash
# To see your defaults policy :
sudo iptables -L | grep policy
```
In a hardened configuration, it's common to use iptables to limit connections. Following the principle of least privilege, you should block all connections and only allow the ones you need

```bash
# Basic hardened default Policy :
sudo iptables -P INPUT DROP
sudo iptables -P FORWARD DROP
sudo iptables -P OUTPUT DROP
```

Tip to revert to accepting traffic after 30 seconds, in case you want to test your setup without locking yourself out of the machine:
```bash
# Put all chains to DROP then revert to ACCEPT after 30 sec
sudo iptables -P INPUT DROP && sudo iptables -P FORWARD DROP && sudo iptables -P OUTPUT DROP && sleep 30 && sudo iptables -P INPUT ACCEPT && sudo iptables -P FORWARD ACCEPT && sudo iptables -P OUTPUT ACCEPT
```


### Making commands

We can follow this image from bottom to top to formulate an iptables rule

![iptables](assets/img/Iptable_schem.webp)


#### Interfaces
```md
-i inside (internal)
-o outside (external)
```
#### Addresses
```md
-s source address
-d destination address
```
#### Protocol
```md
-p tcp (TCP protocol)
```
#### Ports
```md
--sport (source port)
--dport (destination port)
```
#### Modules
For modules and connection tracking see the end of this page


##### Actions
-j ACCEPT: Allow the packet to continue through the firewall.
-j REJECT: Reject the packet and send an error message back to the sender (ICMP port unreachable for UDP, TCP RST for TCP)
-j DROP: Discard the packet without sending any response to the sender
-j MASQUERADE: SNAT with the current firewall IP even if dynamic 
-j SNAT: SNAT with specified source ip, can do also port translation 
-j LOG: Log the packet's information in the system log, no impact on packet flow

#### Short example
To enable SSH access to a server and allow the corresponding output
```bash
sudo iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
sudo iptables -A OUTPUT -p tcp --sport 22 -m conntrack --ctstate ESTABLISHED -j ACCEPT
```

#### Iptables Tables
Tables are structures that define how different types of network traffic should be handled. Each table contains a set of rules organized into chains, which specify actions

We can create custom table to categorize traffic and simplify the administration, but hear we cover only the common ones


- Filter  : default table used for packet filtering
- Nat     : used for NAT, modifies packet headers to change source/dest, IP/port
- Mangle  : specialized packet alteration, such as changing field or setting certain flags
- Raw     : Advanced configurations

![iptables](assets/img/Iptable_schem2.webp)

#### More details

When a packet arrives, it goes through the PREROUTING chain of the NAT table, where it can be altered before routing decisions are made.


After the routing decision, if the packet is for a local process, it enters the INPUT chain of the Filter table. If it’s being routed to another destination, it goes to the FORWARD chain (fw designed as a gw for a client for example).


For outgoing packets, they first hit the OUTPUT chain of the Filter table, and then if they are being modified (like in NAT), they’ll pass through the POSTROUTING chain of the NAT table.

The Mangle table can intervene at any point to modify packets as necessary, allowing for complex routing and filtering scenarios.

#### iptables LOG
```bash
iptables -I FORWARD -j LOG        # Log packets in the FORWARD chain
sudo journalctl                   # View logged packets in the system journal
```

Example of a DNAT rule in prerouting, example usecase is a reverse proxy:
```bash
iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination 192.168.1.100:8080
```

```bash
# redirects incoming UDP traffic on ports 53, 80, and 4444 for the specified IP to port 15351, useful for wireguard server to listen on multilples ports
iptables -t nat -I PREROUTING -i eth0 -d <yourIP/32> -p udp -m multiport --dports 53,80,4444 -j REDIRECT --to-ports 15351

### Example Commands
sudo iptables -A FORWARD -m conntrack --ctstate NEW -j ACCEPT          # Allow new connections
sudo iptables -A FORWARD -m conntrack --ctstate ESTABLISHED -j ACCEPT   # Allow responses to existing connections

### Listing and Deleting Rules
sudo iptables -L --line-numbers    # List rules
sudo iptables -D INPUT 3           # Delete the 3rd rule from the INPUT chain
sudo iptables -F                   # Flush all rules

### Managing ESTABLISHED Connections
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED -j ACCEPT
sudo iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -m conntrack --ctstate ESTABLISHED -j ACCEPT

### SNAT (Source Network Address Translation)
iptables -t nat -A POSTROUTING -o eth0 -j SNAT --to-source 1.2.3.4

### Masquerade
sudo iptables -t nat -A POSTROUTING -o ens33 -j MASQUERADE

### View the NAT Table
sudo iptables -t nat -nvL

### SNAT Traffic Redirection
iptables -t nat -A POSTROUTING -s 192.168.1.100 -j SNAT --to-source 10.0.0.100

### DNAT (Destination Network Address Translation)
sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination 192.168.1.100:8080
```


### More on modules & connection tracking

##### Modules
-m (iptables module)
established, related (connection tracking)
###### Conntrack vs State
-m conntrack --ctstate (modern connection tracking)
-m state --state (legacy connection tracking, works same as conntrack)

##### Connection Tracking
- NEW: Packet is initiating a new connection or is associated with a connection that hasn't seen packets in both directions. a TCP SYN packet is marked as NEW

- ESTABLISHED: Packet is part of a connection that has seen packets in both directions, following the completion of a TCP handshake (SYN-ACK)

- RELATED: Packet is initiating a new connection and associated with an existing connection
