---
title: Writing a New Post
author: cotes
date: 2024-02-18 23:10:00 +0200
categories: [Blogging, Tutorial]
tags: [writing]
render_with_liquid: false
---
# Tuto Simplifié : Installation de Proxmox VE

## Prérequis

- Image ISO de l'installateur Proxmox VE
- Clé USB ou CD-ROM pour l'installation
- Serveur compatible (Debian Linux 64 bits)

## Étapes d'Installation

### 1. Préparation

- Insérez le média d'installation préparé (USB ou CD-ROM) dans le serveur.
- Assurez-vous que le démarrage à partir de ce média est activé dans les paramètres du firmware du serveur.
- Désactivez le démarrage sécurisé (Secure Boot).

### 2. Démarrage de l'Installateur

- Démarrez à partir du média d'installation.
- Choisissez l'option `Install Proxmox VE (Graphical)` pour une installation graphique ou une des autres options si nécessaire.

### 3. Sélection du Disque Cible

- Lisez et acceptez le CLUF (Contrat de Licence Utilisateur Final).
- Sélectionnez le(s) disque(s) dur(s) cible(s) pour l'installation. Notez que toutes les données existantes seront supprimées.

![Sélection du disque](screenshot/pve-select-target-disk.png)

### 4. Configuration de Base

- Sélectionnez les options de configuration de base telles que la localisation, le fuseau horaire et la disposition du clavier.



### 5. Configuration du Mot de Passe

- Définissez le mot de passe du superutilisateur (root) et une adresse e-mail pour recevoir les notifications système.



### 6. Configuration du Réseau

- Configurez les interfaces réseau disponibles. Vous pouvez spécifier une adresse IPv4 ou IPv6.


### 7. Récapitulatif et Installation

- Vérifiez les paramètres sélectionnés dans le résumé et apportez les modifications si nécessaire.
- Cliquez sur `Install` pour commencer l'installation. Attendez la fin de la copie des packages.



### 8. Finalisation

- Une fois l'installation terminée, retirez le média d'installation et redémarrez le système.


## Accès à l'Interface de Gestion

- Après le redémarrage, accédez à l'interface web de Proxmox VE via l'adresse IP définie durant l'installation, par exemple : `https://votreipaddress:8006`.
- Connectez-vous avec le nom d'utilisateur root et le mot de passe défini.



- Téléchargez votre clé de souscription pour accéder au dépôt Enterprise, ou configurez un dépôt public pour les mises à jour.

## Configuration Avancée

### Options Avancées LVM

- **hdsize** : Définir la taille totale du disque dur à utiliser.
- **swapsize** : Définir la taille de la partition swap.
- **maxroot** : Définir la taille maximale de la partition root.
- **maxvz** : Définir la taille maximale de la partition data.
- **minfree** : Définir l'espace libre à laisser dans le groupe de volumes LVM.

> Note : Pour plus de détails sur la configuration avancée, référez-vous à la documentation officielle de Proxmox VE.

---

Ce tutoriel couvre les étapes de base pour installer et configurer Proxmox VE. Pour une installation et une configuration plus détaillées, veuillez consulter la documentation officielle.
