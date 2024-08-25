---
title: "[PROJECT] Raspberry pi and UPS setup with power consumption monitoring"
author: Alxblzd
date: 2024-07-15 22:10:00 +0100
categories: [Project, Electronic]
tags: [RPI, Raspberry, Disk, Electronic, Battery]
render_with_liquid: false
---

# 
# Mini project : Raspberry Pi with UPS, and INA226 Voltage I2C Module

# Why ?

It has been a while since I last worked with the I2C bus and basic programs for it, but I have a good reason for revisiting it now.

My goal is to configure my Raspberry Pi as a backup for my primary Proxmox server. I intend to use it for several functions, backup website, backup file server, offering VPN access to my network if the Proxmox hypervisor fails. Additionally, I might explore creating a SDR with it in the future.

One of the advantages of using the Raspberry Pi is that it's powered by an uninterruptible power supply (UPS) with two Li-Ion batteries. I want to monitor these batteries to ensure I can gracefully shut down the Pi if needed and to estimate how long it can run on battery power.


# Components

Core project :
- A Raspberry Pi, here the 4B 2Gb, but it doesnt really matter
- INA226 current/voltage module
- Cheap aliexpress UPS module

Optionally :
- A 12v fan 
- Breadboard
- Module to power the breadboard
- NVME to USB adapter
- NVME Drive (overkill for rpi4)
- Heatsink for the cpu

# Building something to hold everything

I had a piece of acrylic and some nice wood, which I assembled to create two base linked together. This setup allows me to securely mount everything using M2 stands and screws. On it, I placed the NVMe SSD, the UPS module, and provided space for a small breadboard to facilitate wiring and to accommodate the INA226 module.

The result is this :

#picture




Step-by-Step Assembly
1. Preparing the Board

    Cut the Wooden Board: Cut the wooden board to your desired dimensions, ensuring it's large enough to hold all the components.
    Cut the Plastic Glass: Cut the plastic glass sheet to match the size of the wooden board. This will serve as the top cover.

2. Drilling and Mounting

    Drill Holes for M2 Support: Measure and mark the positions for mounting the Raspberry Pi, UPS, NVMe drive, and the INA226 module. Drill holes accordingly.
    Install M2 Supports: Screw in the M2 supports into the drilled holes to provide a raised platform for the components.

3. Mounting the Raspberry Pi and Components

    Mount the Raspberry Pi: Place the Raspberry Pi onto the M2 supports and secure it with screws.
    Install the UPS: Mount the UPS next to the Raspberry Pi, ensuring it's firmly in place.
    Secure the NVMe Drive: Connect the NVMe drive via USB 3.0 and secure it onto the board.
    Attach the INA226 Module: Mount the voltage module in a convenient location for easy access to power lines.

4. Wiring and Connections

    Connect the UPS to the Raspberry Pi: Ensure the power supply is connected securely.
    Wiring the INA226 Module: Connect the INA226 module to the power lines for accurate readings.
    USB Connections: Connect the NVMe drive to one of the USB 3.0 ports on the Raspberry Pi.

5. Customizations and Modifications

    UPS Modifications: To avoid noise and voltage drops after overclocking the Raspberry Pi, modify the UPS. This may involve adding capacitors or additional filtering to ensure a stable power supply.
    Overclocking Adjustments: Ensure the Raspberry Pi is adequately cooled, possibly adding heatsinks or a fan to manage the increased heat output.

6. Testing and Troubleshooting

    Power On: Power on the board and check for stable operation.
    Multimeter Checks: Use a multimeter to verify voltage and current readings from the INA226 module.
    System Stability: Monitor the Raspberry Pi under load to ensure there are no power issues.

More to come ...