Raspberry Pi factory reset utility
=========

This script modifies a raspbian image to add a `factory_reset` command, which
can be used in a running system to reset it back to pristie state.

For example you could do the following (over ssh if required):

    root@raspberrypi:~# /boot/factory_reset --reset
    factory restore script
    resetting
    rebooting...
    Connection to raspberrypi.local closed by remote host.
    Connection to raspberrypi.local closed.

The Pi will restore to a fresh installation:

![GitHub Logo](/assets/images/raspi-restore-screenshot_300px.png)

The pi will then reboot back to a fresh installation of Raspbian. The script
sets up the restored raspbian so ssh is running and available.


Background
-----

These days, almost all my installations are done using ansible and tested using
test-kitchen or molecule, however these tools assume that you can easily start
from a fresh OS build to run end-to-end integration tests. Recreation of base
installation is made difficult with raspberry pi is having to restore sdcards
when I want fresh Pi.

Obviously virtualization/containerization makes this easy for x86_64 systems.
But raspberry pis are on the Arm architecture, and emulating this on an x86_64
based linux desktop is not that straightforward. So an alternative solution is
to create a restore partition which can be used factory reset the Pi back to its
original state. We can then use this as the provisioner during setup in molecule
or test-kitchen.

**Or it can just be used to reset the pi when you have messed it up!!**

A typical raspbian image contains 2 partitions, one with the boot partition
and the other with the root partition containing the OS. Upon first booting,
raspbian expands the root partition as to completely fill the available space
in the sdcard.

This script modifies the rasbian image file to add the following features:

1. Adds a partition containing a pristine base installation
2. adds a utility to the root partition to call factory-reset
3. optionally reset the pi password on the restored OS

Instructions
--------

The script requires a locally available base image of raspbian in the same
directory as the script.

This script was tested with the series of images available here:
https://downloads.raspberrypi.org/raspbian_lite/images/



Future
-----

Raspberry pi seem to have stopped the sequence of releases [here](https://downloads.raspberrypi.org/raspbian/images/) and switched to calling it Raspberry Pi OS and providing downloads
here:

https://www.raspberrypi.org/software/operating-systems/#raspberry-pi-os-32-bit

Assuming these images are similarly structured, they would work as well, but they
are not tested.





Dependencies
------------

This script was developed on a linux desktop with packages installed for working
with disk images, archives and filesystems. The command lines tools I used are
available in the fedora/EPEL repos, and I assume are similarly available in
Ubuntu and mainstream distros.

* zip
* uuid

Warning
-------

Obviously factory resetting a device is a destructive process, so don't try this
unless you understand what you are doing.

License
-------

The code is provided as is, and can be used/modified for any purpose, attribution
is appreciated but not required.

Sources/References
----

This project was inspired by a blog post on binarycents.com, but that site appears
to be gone now:
http://www.binarycents.com/raspberry-pi/raspberry-pi-remote-reinstall/


Some other sources of information:

https://raspberrypi.stackexchange.com/questions/80070/remote-full-reset-re-install-of-a-raspberry

There is some more information about the process in these blog posts:

* https://limepepper.co.uk/raspberry-pi/2018/04/15/Remote-factory-reset-for-raspberry-pi-1.html
* https://limepepper.co.uk/raspberry-pi/2018/04/16/Remote-factory-reset-for-raspberry-pi-2.html

