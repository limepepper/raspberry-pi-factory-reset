Raspbian / Pi OS factory reset images
=========

This [releases](https://github.com/limepepper/raspberry-pi-factory-reset/releases)
in this repo are modified raspbian/Pi OS images which have an added restore partition
and a `factory_reset` command, which can be used in a running system to reset it back
to a fresh installation.

Its mostly useful for testing automated deployments of
software to raspberry pi and will delete any data off the root partition during
restoration.

Download an image from the [releases](https://github.com/limepepper/raspberry-pi-factory-reset/releases) section and flash it to an sdcard. You generally want at least 32GB card, but you might
be able to get away with 16GB.


For example you could do the following (over ssh):

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

A typical raspbian image contains 2 partitions, one with the boot partition
and the other with the root partition containing the OS. Upon first booting,
raspbian expands the root partition as to completely fill the available space
in the sdcard.

This script modifies the rasbian image file to add the following features:

1. Adds a partition used for recovery containing a pristine copy of Pi OS
2. adds a utility to the root partition to call a factory-reset

Usage
-----

In general just use one of the Pi OS images available in the releases section:
https://github.com/limepepper/raspberry-pi-factory-reset/releases

download the image, unzip it, and flash it to your rPi as normal.

Howewver if you have custom requirements you can build the image locally using
the following steps:

Build Prerequisites
-------

fedora

    sudo dnf install zip e2fsprogs

debian/ubuntu

    sudo apt-get install uuid-runtime zip

(and any other packages providing tools for your distro...) This has only been
tested on fedora 33

Build Instructions
--------

The script requires a locally available base image of raspbian in the same
directory as the script. For example:

    $ ls
    2021-03-04-raspios-buster-armhf-lite.img
    main.sh

This script was tested with the series of images available here:
https://downloads.raspberrypi.org/raspbian_lite/images/


Run the script like so;

    $ chmod +x create-factory-reset
    $ sudo ./create-factory-reset -c -e -i 2021-03-04-raspios-buster-armhf-lite.img

script will ask for sudo password when required

To write the image to sdcard on linux, use something like this...


    sudo dd bs=4M \
        if=2021-01-11-raspios-buster-armhf-lite.restore.img \
        of=/dev/sdXXXX \
        conv=fsync \
        status=progress




Future
-----

Raspberry pi seem to have stopped the sequence of releases [here](https://downloads.raspberrypi.org/raspbian/images/) and switched to calling it Raspberry Pi OS and providing downloads
here:

https://www.raspberrypi.org/software/operating-systems/#raspberry-pi-os-32-bit

Assuming these images are similarly structured, they would work as well, but they
are not tested.



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

