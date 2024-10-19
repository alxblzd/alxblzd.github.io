---
title: "[Wiki] Traefik Multiples instances"
author: Alxblzd
date: 2024-09-22 14:45:00 +0100
categories: [Project, Electronic]
tags: [Traefik, Docker, Proxy]
render_with_liquid: false
image: /assets/img/logo/traefik_logo.webp
alt: "Treafik logo"
---


## Issue

Traefik requires ports 80 and 443 for routing traffic to its applications, a router can forward these ports to only one internal host

The challenge arises when you have multiple servers running Traefik and you want them to serve different domains but are limited to one external IP

You want to host different services under different domains (`example1.com` and `example2.com`), each managed by a separate instance of Traefik, but you’re restricted by having only one IP address and the need to forward ports **80** and **443**.  


**Schematic to make**


### Concrete example

You are running a primary Traefik instance on your home server, which handles the main domains (* . webguardx . com). 
This server hosts services that are in current use. You want to set up a secondary Traefik instance on a other server to test new services like a development version of a website with a domain like : (* . test . webguardx . com)

### Solution: 

Using Traefik TCP Router The solution to this limitation is to use a **Traefik TCP router** on the primary instance, which acts as a passthrough for traffic to the secondary instance. 

The primary Traefik acts as the "gatekeeper" for both domains.  

### Primary Traefik Instance

1. **Port Forwarding Configuration**: Set up your router to forward ports **80** and **443** to the primary instance of Traefik running on your main server.  

2. **Primary Traefik Configuration**: On the primary server, configure a **TCP router** to handle requests meant for the secondary domain. This router will then forward those requests to the secondary instance on your NAS.  3. **YAML Configuration File**: Create a file, such as `tcp-router.yml`, in the rules folder of your primary Traefik instance:     


```yaml
tcp:
  routers:
    synology-traefik-rtr:
      entryPoints:
        - "https"
      rule: "HostSNIRegexp(`example2.com`) || HostSNIRegexp(`{subdomain:[a-z]+}.example2.com`)"
      service: synology-traefik-svc
      tls:
        passthrough: true

services:
  synology-traefik-svc:
    loadBalancer:
      servers:
        - address: "192.168.1.254:443"
```

- **entryPoints**: Define the HTTPS entry point.
- **rule**: Matches requests to the second domain or its subdomains.
- **tls.passthrough**: Forwards the request without terminating TLS.
- **loadBalancer**: Points to the second Traefik instance (e.g., the Synology NAS).
