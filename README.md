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

### Ubuntu

`ubuntu/create_image.sh` script automatically downloads Ubuntu release 22.04.2, extracts it, injects preseeds and packages the new iso image. General preseed configuration can be found in the `ubuntu/main.cfg` file, if necessary, it can be edited. The script also takes arguments if the original Ubuntu iso image has already been downloaded or extracted.

**Warning!** This script by default wipes the first disks and setups ubuntu partitions! If you want custom partitioning run the program with `-p` argument.

#### Exemplary usages:
Does everything and saves the image as `ubuntu-auto.iso` in the script execution directory:
```
./ubuntu/create_image.sh
```
Extracts downloaded image and saves modified image (it is important that the image is downloaded from [here](https://ubuntu.man.lodz.pl/ubuntu-releases/22.04.2/ubuntu-22.04.2-desktop-amd64.iso), otherwise it may work incorrectly):
```
./ubuntu/create_image.sh -i ~/Downloads/ubuntu-22.04.2-desktop-amd64.iso
```
Saves modified image as `ubuntu.iso`:
```
./ubuntu/create_image.sh -o ubuntu.iso
```

Thre is a help if needed:
```
./ubuntu/create_image.sh -h
```

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
