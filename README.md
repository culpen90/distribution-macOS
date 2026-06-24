# Terminal OS

This repository now contains a tiny bootable terminal-only operating system image.
It is intentionally small: a BIOS boot sector loads a 16-bit kernel, and the kernel
starts a built-in command shell. There is no GUI, filesystem, userspace, networking,
or process model yet.

## Requirements

- `nasm`
- `qemu-system-i386`
- `make`

## Build

```sh
make
```

The bootable floppy image is written to `build/terminal-os.img`.

## Run

```sh
make run
```

For a terminal-only QEMU session over COM1 serial:

```sh
make run-serial
```

## Commands

- `help` shows available commands.
- `about` prints the system summary.
- `clear` or `cls` clears the VGA text console.
- `echo TEXT` prints text back.
- `mem` prints BIOS conventional memory.
- `reboot` resets the machine.
- `poweroff` asks QEMU-compatible ACPI firmware to power off.
- `halt` stops the CPU.

## Test

```sh
make smoke
```

The smoke test boots the image in headless QEMU, sends shell commands over serial,
and checks that the shell answers.
