# Raspbian / Pi OS factory reset images

:warning: Factory-resetting will delete any data off the root partition during
restoration. :warning: 

## Description

If you regularly need to reset or restore a Raspberry Pi, it can become a bit
annoying to have to power down the rPi, unplug the sdcard, and re-flash the
original image back again. Not to mention it causes mechanical stress to the 
sdcard slot and requires physical access to the rPi.

This project creates images that contain a `/boot/factory_reset` utility which 
can be used to reset the pi remotely over ssh back to the pristine installation 
state.

Basic usage is to run the following command from the image:

    root@raspberrypi:~# /boot/factory_reset --reset

The factory reset causes the rPi to reboot to a recovery partition, upon which
it restores the original root partition, and then reboots back to the fresh
installation.

### Ready to use images

These Pi OS/raspbian images can be directly flashed and run:

https://github.com/limepepper/raspberry-pi-factory-reset/wiki/Downloads

#### Note on image sizes

These zipped images contain a copy of the original root partition, a pristine
copy of the rootfs, and a recovery partition. So they are at least 2 times the
original size.


## Usage

### Building your own image

You will need an sdcard with at least enough space to flash the images. The
released images and script were tested with 32GB cards, but you might be able to
get away with 8GB for lite images.

1. clone the repo

```
git clone https://github.com/limepepper/raspberry-pi-factory-reset.git
```

2. Download a source [image](https://downloads.raspberrypi.org/raspios_lite_armhf/images/)
and save it to the root of the project directory then unzip it
```

$ wget https://downloads.raspberrypi.org/raspios_armhf/images/raspios_armhf-2021-03-25/2021-03-04-raspios-buster-armhf.zip

$ unzip 2021-03-04-raspios-buster-armhf.zip

$ ls
2021-03-04-raspios-buster-armhf.zip
2021-03-04-raspios-buster-armhf-lite.img
create-factory-reset
```

3. Make the script executable

```
$ chmod +x create-factory-reset
```

4. Execute the script which modifies the image:

```
$ sudo ./create-factory-reset -i 2021-03-04-raspios-buster-armhf-lite.img
```

5. This will produce a new image with  `restore` suffix like so;

```
2021-03-04-raspios-buster-armhf.restore.img
```
you can flash this to the rPi

### Resetting the rPi back to factory state

Once the pi is booted, it will work as a normal Pi OS/raspbian installation,
however it includes a utility which can be run as root with `--reset` argument,
which will trigger a factory-reset.

For example you could do the following (over ssh) from the rPi:

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


# Background

A typical raspbian image contains 2 partitions, one with the boot partition
and the other with the root partition containing the OS. Upon first booting,
raspbian expands the root partition as to completely fill the available space
in the sdcard.

This script modifies the rasbian image file to add the following features:

1. Adds a 3rd partition used for recovery containing a pristine copy of Pi OS
2. Adds a utility to the root partition to call a factory-reset

Build Prerequisites
-------

fedora

    sudo dnf install zip e2fsprogs

debian/ubuntu

    sudo apt-get install uuid-runtime zip

(and any other packages providing tools for your distro...) This has only been
tested on fedora 33





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

