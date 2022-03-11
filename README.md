# preseeds

This repository contains OS preseeds for preparing Dasharo devices for testing.

## Usage

Start a http server from the terminal:

```bash
$ python -m http.server 8080
```

## Supported OSes

| OS | HTTP | netboot.xyz | local |
| --- | --- | --- | --- |
| Ubuntu | [Yes](#via-http)   | [Yes](#via-netbootxyz)   | [Yes](#locally)   |
| Debian | [Yes](#via-http-1) | [Yes](#via-netbootxyz-1) | [Yes](#locally-1) |

### Ubuntu 20.04

#### Via HTTP

Boot the Ubuntu Server 20.04 ISO and append the following to the kernel
commandline before launching the installer:

```
autoinstall ds=nocloud-net;s=http:[your ip]:8080/ubuntu/
```

For GRUB, add a backslash before the semicolon like so:

```
autoinstall ds=nocloud-net\;s=http:[your ip]:8080/ubuntu/
```

#### Via netboot.xyz

Add the following snippet to your netboot.xyz Ubuntu netboot entry:

```
set install_params autoinstall ds=nocloud-net;s=http:[your ip]:8080/ubuntu/
```

#### Locally

Autoinstall can also be used locally, by putting the preseed config into a
separate drive (e.g. USB stick)

Install cloud image utilities and create the image:

```bash
$ sudo apt install cloud-image-utils
$ cloud-localds ~/seed.iso ubuntu/user-data ubuntu/meta-data
```

Identify the USB stick:

```bash
$ lsblk
NAME                      MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
sda                         8:0    1   3.7G  0 disk              # <- Our USB stick
├─sda1                      8:1    1   731M  0 part
└─sda2                      8:2    1    76M  0 part
nvme0n1                   259:0    0 238.5G  0 disk
└─nvme0n1p1               259:1    0 238.5G  0 part
  ├─LVMGroup-Win10        254:0    0   125G  0 lvm
  └─LVMGroup-Ubuntu_3mdeb 254:1    0   100G  0 lvm
nvme1n1                   259:2    0 953.9G  0 disk
├─nvme1n1p1               259:3    0     1G  0 part /boot
└─nvme1n1p2               259:4    0 952.9G  0 part /
```

Write the created image to the USB stick:

*Warning: Triple-check the disk name. If you enter a wrong name here, you
may overwrite your OS or important data*

```bash
$ sudo dd if=seed.iso of=/dev/sdX bs=4M status=progress conv=fsync
                                ^
                                |
                     Enter drive letter here
```

Insert the USB stick along with the Ubuntu Server installer into the DUT and
power it on.

### Debian

Debian preseeds are located in the `debian/` directory.

### Via HTTP

Boot the Debian ISO and append the following to the kernel commandline before
launching the installer:

```
auto url=http://[your ip]:8080/debian/preseed.cfg
```

#### Via netboot.xyz

Add the following snippet to your netboot.xyz Debian netboot entry:

```
set preseedurl http://[your ip]:8080/debian/preseed.cfg
preseed/url=${preseedurl}
```

### Locally

Follow the steps in [the Debian documentation](https://wiki.debian.org/DebianInstaller/Preseed/EditIso)
to add the preseed file to a Debian installer ISO.
