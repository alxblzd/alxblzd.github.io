---
title: "[Wiki] Iptable cheatsheet"
author: Alxblzd
date: 2024-09-06 18:10:00 +0200
categories: [Tutorial, Ansible]
tags: [iptable, network, linux, tutorial]
render_with_liquid: false
image: /assets/img/logo/netfilter_logo.webp
alt: "netfilter logo"
---

# Iptables Infos

In Linux, firewall management is handled by Netfilter, a kernel module that controls which network packets are permitted to enter or leave the system.

Iptables serves as the user-space tool that interacts with Netfilter, providing a command-line interface to define and manage the filtering rules. While they are often considered interchangeable, it's more accurate to view Netfilter as the backend that performs the actual filtering, and iptables as the frontend that allows users to configure it.

# Interfaces
-i inside               # Interface interne
-o outside              # Interface externe

# Adresses
-s source               # Adresse source
-d destination          # Adresse de destination

# Protocole
-p tcp                  # Protocole TCP

# Ports
--sport                 # Port source
--dport                 # Port de destination

# Module
-m                      # Module iptables
established, related     # Suivi de connexion

# Actions
-j ACCEPT               # Accepter le paquet
-j REJECT               # Rejeter le paquet
-j DENY                 # Bloquer le paquet
-j DROP                 # Ignorer le paquet
-j MASQUERADE           # Masquer le paquet

# Chain (Chaînes par défaut)
- INPUT   : Trafic entrant
- OUTPUT  : Trafic sortant
- FORWARD : Trafic transitant

# Politiques par défaut
- ACCEPT : Accepter le paquet
- DROP   : Bloquer le paquet

# Tables iptables
- Filter  : Filtrage des paquets
- Nat     : Traduction d’adresses (NAT)
- Mangle  : Modification des paquets
- Raw     : Configurations avancées

# Iptables LOG
iptables -I FORWARD -j LOG        # Logger les paquets de la chaîne FORWARD
sudo journalctl                   # Consulter les paquets loggés dans le journal

# Decision de routage
# Si un paquet est destiné au firewall, il passe par INPUT ; sinon, par FORWARD
# Exemple de règle NAT en prerouting :
iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination 192.168.1.100:8080

# Suivi de connexion
- NEW          : Requête initiale (SYN)
- ESTABLISHED  : Connexion établie (SYN-ACK)

# Conntrack vs State
-m conntrack --ctstate           # Conntrack moderne
-m state --state                 # Ancien suivi de connexion


# Proxy
- Accélération, Anonymisation, Filtrage via un proxy transparent avec DNAT

# Reverse Proxy
- Intercepter le flux client et rediriger avec DNAT vers un serveur ou plusieurs


## Commands

iptables -t nat -I PREROUTING -i eth0 -d <yourIP/32> -p udp -m multiport --dports 53,80,4444  -j REDIRECT --to-ports 15351




### Exemples de commandes
sudo iptables -A FORWARD -m conntrack --ctstate NEW -j ACCEPT          # Autoriser nouvelle connexion
sudo iptables -A FORWARD -m conntrack --ctstate ESTABLISHED -j ACCEPT   # Autoriser réponse à une connexion existante

### Listes et suppression des règles
sudo iptables -L --line-numbers    # Lister les règles
sudo iptables -D INPUT 3           # Supprimer la 3e règle de la chaîne INPUT
sudo iptables -F                   # Supprimer toutes les règles

### Gestion des connexions ESTABLISHED
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED -j ACCEPT
sudo iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -m conntrack --ctstate ESTABLISHED -j ACCEPT

### SNAT (Source Network Address Translation)
iptables -t nat -A POSTROUTING -o eth0 -j SNAT --to-source 1.2.3.4

### Masquerade
sudo iptables -t nat -A POSTROUTING -o ens33 -j MASQUERADE

### Voir la table NAT
sudo iptables -t nat -nvL

### Redirection de flux SNAT
iptables -t nat -A POSTROUTING -s 192.168.1.100 -j SNAT --to-source 10.0.0.100

### DNAT (Destination Network Address Translation)
sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination 192.168.1.100:8080
