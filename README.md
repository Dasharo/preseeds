# preseeds

This repository contains OS preseeds for preparing Dasharo devices for testing.

## Usage

Start a http server from the terminal:

```bash
python -m http.server 8080
```

### Ubuntu

Append the following to the kernel commandline:

```
autoboot ds=nocloud-net;s=http:[your ip]:8080/ubuntu/
```

For GRUB, add a backslash before the semicolon like so:

```
autoboot ds=nocloud-net\;s=http:[your ip]:8080/ubuntu/
```
