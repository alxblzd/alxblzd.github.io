---
title: "[PROJECT] Raspberry pi NVME and USP setup"
author: Alxblzd
date: 2024-07-15 22:10:00 +0100
categories: [Project, Electronic]
tags: [RPI, Raspberry, Disk, Electronic, Battery]
render_with_liquid: false
---

# Raspberry Pi with UPS, NVMe Drive, and INA226 Voltage Module


# Why

This project began with a simple piece of wood and a sheet of plastic glass that were lying around my workspace. These materials sparked the idea of creating a custom board to house my Raspberry Pi and its components in a more organized and secure manner I was tired of having to put my rpi somewhere with the ugly nvme drive hanging out of it. 


I also add a voltage module working with I2C bus, an INA226 that I always wanted to use to measure the power of one of my electronic project, This one was perfect because It is battery powered in case of a power loss,
The module that can handle both power from the wall and from the battery in case of a power cut is called an uninterruptible power supply (UPS) and use 2x Lithium Ion 18650 battery, here is one of these module :

# PHOTO

In this post, I'll walk you into my process of transforming these materials into a practical setup, incorporating a Raspberry Pi, a UPS with 18650 lithium-ion battery, a 256GB NVMe drive via USB 3.0, and an INA226 voltage module for power metrics on a I2C bus.

I'll also share some tips on the customizations and modifications needed to ensure stable system, especially after overclocking the Raspberry Pi.

### Materials and Tools Needed

- Wooden Board
- Plastic Glass Sheet
- M2 Support and Screws
- Raspberry Pi 4/5/X
- 5V UPS Module
- 256GB NVMe Drive and adaptater
- Voltage Module INA226
- multiples tools, multimeter, soldering iron, hot glue, a drill


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