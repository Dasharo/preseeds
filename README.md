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
| Fedora | No                 | No                       | [Yes](#fedora)    |

### Windows

* Install Windows first because the automatic installer cleans the entire disk
* Download the newest Windows Disk Image (ISO) from [official
  website](https://www.microsoft.com/en-us/software-download/)
* Run `windows/create_image.sh` giving the path to the downloaded iso as `-i`
parameter
* Use [WoeUSB](https://github.com/WoeUSB/WoeUSB) to make a bootable USB from the
resulting automatic windows installer iso. Example command:
    ```bash
    sudo woeusb --device windows-auto.iso /dev/sd[drive letter]
    ```
* Insert the USB into the platform and boot from the USB
* Windows will install automatically and configure
* If there are any problems during installation, you can make sure all steps
  have been completed by manually running the files
  [setup-ssh.ps1](./windows/custom-data/setup-ssh.ps1) and
  [install_intel_nic_drivers.ps1](./windows/custom_data/install_intel_nic_drivers.ps1)
  [standby_timeout.ps1](./windows/custom_data/standby_timeout.ps1)
  [install-updates.ps1](./windows/custom_data/install-updates.ps1)
    ```powershell
    PowerShell.exe -ExecutionPolicy UnRestricted -File C:\Users\Public\Desktop\custom_data\<script_name>
    ```

> If for some reason you want to upgrade to the latest version, Windows update
> does not allow it, you can do it by inserting the USB and running
> `.\setup.exe` under Windows. This solution leaves the bootloader. However, in
> most cases, the Windows + Ubuntu autoinstaller will be faster.

### Ubuntu

`ubuntu/create_image.sh` script automatically downloads Ubuntu release 22.04.4,
extracts it, injects preseeds and packages the new iso image. General preseed
configuration can be found in the `ubuntu/main.cfg` file, if necessary, it can
be edited. The script also takes arguments if the original Ubuntu iso image has
already been downloaded or extracted.

**Warning!** This script by default wipes the first disks and setups ubuntu
partitions! If you want custom partitioning run the program with `-p` argument.

#### Exemplary usages

Does everything and saves the image as `ubuntu-auto-22.04.4.iso` in the script
execution directory:

```bash
./ubuntu/create_image.sh
```

Extracts downloaded image and saves modified image (it is important that the
image is downloaded from
[here](https://ubuntu.task.gda.pl/ubuntu-releases/22.04.4/ubuntu-22.04.4-desktop-amd64.iso),
otherwise it may work incorrectly):

```bash
./ubuntu/create_image.sh -i ~/Downloads/ubuntu-22.04.4-desktop-amd64.iso
```

Saves modified image as `ubuntu.iso`:
```bash
./ubuntu/create_image.sh -o ubuntu.iso
```

There is a help if needed:

```bash
./ubuntu/create_image.sh -h
```

### Fedora
`fedora/create_image.sh` script downloads the Fedora 42 Everything iso and
replaces the `grub.cfg` file with `fedora/grub-efi.cfg`. The modified iso can
be used to create an installation medium by writing it to a flash drive.
The modifications cause the installer to download the kickstart file
at `fedora/ks.cfg` from this repository.
The installer does not wipe out other OSes. It creates a partition 50GB
in size automatically, but fails if there is not enough space on any
of the disks.

#### Example usage

Downloads Fedora and modifies the iso

```bash
./fedora/create-image.sh
```

Modifies the iso given as an argument. The script looks for `fedora.iso` by default.
Downloads the iso if the file is not found.

```bash
./fedora/create-image.sh -i fedora.iso
```

Save the modified iso to given path. The default output file name is `fedora-auto-{version}.iso`

```bash
./fedora/create-image.sh -o fedora-auto-42-1.1.iso
```

Show help

```bash
./fedora/create-image.sh -h
```


### QubesOS

`qubesos/create_image.sh` script downloads the QubesOS iso and replaces
the `grub.cfg` with `qubesos/grub-efi.cfg`. The modified iso can be written
onto a flash drive and used as an installation media.

__Important__
Currently [fully unattended installations are not possible](https://github.com/QubesOS/qubes-issues/issues/10381).
The installer will require the user to apply the default post-install
configuration settings in order to continue with the second part of
installation.

The installer sets up an SSH tunnel from `net-vm` to `dom0` allowing for
automated tests via SSH.

The installer **ONLY** installs QubesOS on `nvme0n1` drive.
It is enough for the day of writing the documentation, as only laptops with
single nvme drive support QubesOS. Should that change, the `qubesos/ks.cfg`
would need to include a script that detects the available drives,
like in https://github.com/Nitrokey/qubes-oem/blob/main/ks_template.cfg.

The installer does not override other OSes installed on the `nvme0n1` drive and
only uses ~80 GiB of disk space while leaving the rest free, so it can be
installed along other OSes in any order.

#### Example usage

Downloads QubesOS and modifies the iso

```bash
./qubesos/create_image.sh
```

Modifies the iso given as an argument. The script looks for `qubesos-${QUBES_VERSION}.iso` (`qubesos-R4.3.0-rc3.iso`) by default.
Downloads the iso if the file is not found.

```bash
./qubesos/create_image.sh -i qubesos-R4.3.0-rc3.iso
```

Save the modified iso to given path. The default output file name is `qubesos-auto-{version}.iso`

```bash
./qubesos/create_image.sh -o qubesos-auto-R4.3.0-rc3.iso
```

Show help

```bash
./qubesos/create_image.sh -h
```

### Debian

Debian preseeds are located in the `debian/` directory.

### Via HTTP

Boot the Debian ISO and append the following to the kernel commandline before
launching the installer:

```bash
auto url=http://[your ip]:8080/debian/preseed.cfg
```

#### Via netboot.xyz

Add the following snippet to your netboot.xyz Debian netboot entry:

```bash
set preseedurl http://[your ip]:8080/debian/preseed.cfg
preseed/url=${preseedurl}
```

### Locally

Follow the steps in [the Debian
documentation](https://wiki.debian.org/DebianInstaller/Preseed/EditIso) to add
the preseed file to a Debian installer ISO.
