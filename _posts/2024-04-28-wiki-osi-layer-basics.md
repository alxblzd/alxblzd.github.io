---
title: "OSI layer basics"
author: "Alxblzd"
date: 2024-04-28 23:10:00 +0200
categories: [Networking, Concepts]
tags: [network, mac, osi, layer]
render_with_liquid: false
alt: "OSI logo"
---

## OSI Model Layers

### Layer 1: Physical layer
Handles the physical equipment for data transfer, like cables and switches. Converts data into a bit stream of 1s and 0s, ensuring a common signal convention for transmission and reception.

- medium selection, wired, wireless, fiber etc..
- multiplexing, physical media specificity

### Layer 2: Data link layer

Defines the protocol to establish and terminate a connection between two physically connected devices. It also defines the protocol for flow control between them.

The Data Link Layer of the 802.11 standard is composed of two sublayers:

- The Logical Link Control (LLC) sublayer
- The Media Access Control (MAC) sublayer

The MAC layer defines two different access methods:
- CSMA/CA method fulfilling the Distributed Coordination Function (DCF)
- The Point Coordination Function (PCF)

The access method used by wired machines is CSMA/CD (Carrier Sense Multiple Access with Collision Detection), where each machine is free to communicate when the network is clear (no ongoing signals).

In a wireless environment, this method is not usable because it is complex to listen to the medium during its own transmission.

MAC Address -> 6 bytes
OUI -> Organizational Unit Identifier -> First 3 bytes


### Layer 3: Network layer
Enable communication between devices across different networks. It divides data into smaller units known as packets and handles the routing of these packets to their destination. 

This layer ensures efficient data transmission by determining the best physical path for the packets to travel. 

Protocols used at level 3:
- IP, ARP, ICMP, IGMP, IPSEC, BGP, RIP, OSPF

#### IP (Internet Protocol) 
Addresse and routing packets across networks, ensuring delivery to the correct destination.
- IPV4 -> 32 bits
- IPV6 -> 128 bits 

#### ARP (Address Resolution Protocol)
- mapping IP addresses to MAC addresses in a local area network (LAN).
- ARP helps discover other devices on the same network by associating a hardware address (MAC) with an IP address, by using ARP broadcast

#### ICMP (Internet Control Message Protocol)
Reporting errors and providing diagnostic information for communications.
- ICMP messages are encapsulated within IP packets
- Used for diagnostic and error reporting

#### IGMP (Internet Group Management Protocol)
Manages multicast group memberships in IP networks, enabling distribution of data to multiple recipients.

#### IPSEC suite
Authentication and encryption for IP packets, ensuring confidentiality and integrity during transmission.
- encryption algorithms like AES and authentication mechanisms like HMAC
- widely used in VPN

### Layer 4: Transport layer
Ensures end-to-end communication between devices. Segments data into manageable chunks called segments. Handles flow and error control to optimize transmission speed and data integrity.
- TCP -> use 3 way handshakes to establish connextion
- UDP -> no ACK or control overhead, lighter, most of the time faster
- The Transport layer can implement QoS mecanisms

### Layer 5: Session layer
Controls opening, managing, and closing of communication sessions between devices. Synchronizes data transfer with checkpoints to optimize efficiency and reliability.
- Handles the negotiation and establishment of sessions
- Initiates session termination procedures
- Maintain session state informations
- Optimizes data transfer

### Layer 6: Presentation layer
Prepares data for the application layer, translating, encrypting, and compressing it as needed. Ensures compatibility between different systems and improves communication efficiency.
- Converts data into a format suitable for transmission
- encryption and compression over the newrtok
- standardize data formats and protocol

### Layer 7: Application layer
Interacts directly with user applications, managing content requests and returns in the required format. Responsible for initiating communications and providing protocols for data manipulation, ensuring meaningful data presentation to users.
- authentication and authorization mecanisms
-  enable users to interact with data and applications
- protocols such as HTTP, FTP, and SMTP
