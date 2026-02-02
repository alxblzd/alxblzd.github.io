---
title: "Traefik Multiple Instances on One IP"
article_type: post
date: 2024-11-19 22:27:00 +0100
categories: [Project, Networking]
tags: [traefik, docker, proxy, reverse-proxy]
render_with_liquid: false
alt: "Traefik logo"
---

## Why I Needed This

I run more than one server, and I like keeping my “stable” services separate from my “try‑new‑stuff” stack. The problem is simple: the router can only forward ports **80** and **443** to one internal host. So how do you run two Traefik instances behind a single public IP?

My answer: make the primary Traefik the gatekeeper, and let it pass TLS traffic to a secondary Traefik based on SNI.

## The Problem (In One Sentence)

Multiple Traefik instances want ports **80/443**, but one public IP can only forward those ports to a single host.

## The Idea

Use a **TCP router** on the primary Traefik to pass through TLS requests for the secondary domain. The primary Traefik keeps control of the public ports, and only forwards specific domains to the secondary instance.

Think of it as “one front door, multiple houses.”

## My Concrete Example

- Primary Traefik: runs on my main server and serves `*.webguardx.com`
- Secondary Traefik: runs on a second server (NAS) and serves `*.test.webguardx.com`
- Public IP: only one, only one port forward

## Steps

## How Traefik Config Is Organized

Think of Traefik config in two buckets:

- **Static**: how Traefik boots (entrypoints, providers, logging, ACME). This lives in `traefik.yml` (or `traefik.toml` / CLI flags) and only changes on restart.
- **Dynamic**: how traffic gets routed (routers, services, middlewares). This can change on the fly and usually lives in `dynamic/*.yml` or comes from Docker labels.

Files you’ll bump into a lot:

- `traefik.yml` for static config
- `dynamic/*.yml` for routers/services/middlewares
- `acme.json` for stored certificates

In this setup the primary Traefik boots with its static config, then just watches `tcp-router.yml` in the dynamic folder. The secondary Traefik is separate and owns TLS for the test domain.

### 1. Router Port Forwarding

Forward **80** and **443** to the primary Traefik host.

### 2. Add a TCP Router on the Primary

Create a file like `tcp-router.yml` in your primary Traefik rules folder:

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

What matters here:

- `rule`: Match the secondary domain and its subdomains.
- `tls.passthrough: true`: Do **not** terminate TLS on the primary. The secondary Traefik must handle certificates.
- `servers.address`: Point to the secondary Traefik host.

### 3. Secondary Traefik Handles TLS

Because we passthrough TLS, the secondary Traefik must:

- Listen on `:443`
- Have its own certificates (ACME, DNS challenge, or manual)
- Serve the services for that domain
