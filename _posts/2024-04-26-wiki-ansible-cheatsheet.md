---
title: "[Wiki] Ansible cheatsheet"
author: "Alxblzd"
date: 2024-04-26 19:10:00 +0200
categories: [Tutorial, Ansible]
tags: [ansible, automation, linux, tutorial]
render_with_liquid: false
image: /assets/img/logo/ansible_logo.webp
alt: "ansible logo"
---

# Ansible Infos

## Directory Structure:
  - ansible.cfg: General configuration file
  - playbook.yml: Playbook file (YAML)
  - group_vars: Directory for group variables YAML files
  - host_vars: Directory for host variables YAML files
  - inventory.yml: Host inventory file (YAML)
  - templates: Directory for Jinja2 templates

##  Troubleshooting:
  - Test connection to hosts in inventory group:
      command: ansible routers -m ping -i inventory.yml
  - List modules in a collection:
      command: ansible-doc -l | grep cisco.ios
  - Display documentation for a module:
      command: ansible-doc ios_bgp

##  Inventory:
```yaml
  - group_A:
      children:
        subgroup_A:
          hosts:
            host_1:
              ansible_host: 192.168.1.2
            host_2:
              ansible_host: 192.168.1.3
            host_3:
              ansible_host: 192.168.1.4
```
###  Graphical view of inventory:
  command: ansible-inventory --graph -i inventory.yml

###  Complete list of hosts in inventory with their variables:
  command: ansible-inventory --list -i inventory.yml

###  View details of a host:
  command: ansible-inventory --host R1

## Playbook:
  - Run a playbook:
      command: ansible-playbook playbook.yml
  - Launch options:
      -i: Choose inventory file
      -C: Perform a check (no changes made)
      -M: Specify the module
      -c: Specify connection type
      -u: Specify the user
      -k: Specify the password
      -e: Provide a variables file
      --list-hosts: See targeted hosts (no changes made)
      --ask-vault-password: Prompt for vault password

### Variables:
#### Connection:
    ansible_connection: local or network_cli
    ansible_network_os: platform (Cisco -> ios)
    ansible_user: SSH username
    ansible_ssh_pass: SSH password
    ansible_ssh_private_key_file: SSH key file

#### Execution:
    ansible_command_timeout: execution timeout in seconds
    ansible_become: privilege escalation (yes or no)
    ansible_become_method: enable

#### Filters:
  - Convert compatible data to JSON or YAML:
      example: "{{ output | to_json }}"
               "{{ output | to_yaml }}"
  - Parse command output with a textfsm template:
      example: "{{ output | ansible.netcommon.parse_cli_textfsm('template') }}"
  - Find a regex pattern match:
      example: "{{ output | regex_search('[\d\w]{4}\.[\d\D]{4}\.[\d\D]{4}') }}"
  - List all occurrences of a regex pattern:
      example: "{{ output | regex_findall('GigabitEthernet0\/0\/[0-9]{1,2}') }}"

#### Common regex patterns:
```md
.: match any single character
^: match beginning of string
$: match end of string
|: equivalent to OR
[]: match any character in set
[^ ]: match any character not in set
(): capture group
{n}: match exactly n occurrences
\s: match whitespace
\d: match digit
\w: match word character
```
## Modules:
 #### ios_config:
```yaml  
    - name: top level configuration
      ios_config:
        lines: hostname my_device

    - name: configure interface 
      ios_config:
        lines:
          - description LAN
          - ip address 192.168.1.254 255.255.255.0
        parents: interface GigabitEthernet0/0

    - name: save running to startup when modified
      ios_config:
        save_when: modified
```
 ####  ios_command:
```yaml  
    - name: run commands
      ios_command:
        commands:
          - show version
          - show vlans
```
 #### li_parse:
```yaml  
    - name: run command and parse with ntc_templates
      ansible.utils.cli_parse:
        command: "show version"
        parser:
          name: ansible.netcommon.ntc_templates
      register: output
```
 #### debug:
```yaml
    - name: display result
      debug:
        msg: "{{ output }}

```
