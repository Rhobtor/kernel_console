# Phase 8: SD Card Access from Custom OS

## Overview
Accessing the physical SD card and its partitions from your running custom OS.

---

## 8.1 View Disk Partitions

### What You Did
```bash
/ # cat /proc/partitions
/ # ls /dev/mmc*
```

### Expected Output

#### /proc/partitions
```bash
/ # cat /proc/partitions

major minor  #blocks  name
 
 179        0    62333952 mmcblk0
 179        1      262144 mmcblk0p1
 179        2    62062080 mmcblk0p2
```

**Breakdown:**

| Entry | Type | Size | Purpose |
|-------|------|------|---------|
| `mmcblk0` | Entire card | 62.3 GB | Full SD card device |
| `mmcblk0p1` | Partition 1 | 262 MB | FAT boot partition |
| `mmcblk0p2` | Partition 2 | 62 GB | ext4 root partition |

#### Device Listing
```bash
/ # ls -l /dev/mmc*

brw-rw---- 1 root disk 179,  0 ... mmcblk0
brw-rw---- 1 root disk 179,  1 ... mmcblk0p1
brw-rw---- 1 root disk 179,  2 ... mmcblk0p2
                 ^^^ block devices
```

---

## 8.2 Understanding Device Names

### Device Naming Convention

```
/dev/mmcblk0
    ^^^^^^^^
    MMC (MultiMediaCard) Block device

Major: 179 (MMC controller)
Minor: 0 (first device)

/dev/mmcblk0p1
              ^
              Partition number
```

### Common Block Devices

| Device | Type | Purpose |
|--------|------|---------|
| `/dev/mmcblk0` | SD card | Full card access |
| `/dev/mmcblk0p1` | Partition | FAT boot (256 MB) |
| `/dev/mmcblk0p2` | Partition | Root filesystem (62 GB) |
| `/dev/sda` | USB drive | If plugged in |
| `/dev/nvme0` | NVMe SSD | If installed |

---

## 8.3 Inspect Partition Information

### Get Partition Details
```bash
/ # fdisk -l /dev/mmcblk0
```

Expected output:
```
Disk /dev/mmcblk0: 59.58 GiB, 62333952 sectors, 512 bytes/sector
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: dos
Disk identifier: 0x...

Device         Boot    Start      End  Sectors  Size Id Type
/dev/mmcblk0p1          2048   526335   524288  256M  c W95 FAT32
/dev/mmcblk0p2        526336 62333951 61807616 59.3G 83 Linux
```

**What This Shows:**
- Partition 1: FAT32 (boot) at 256 MB
- Partition 2: Linux ext4 (root) at 59.3 GB
- Disk label type: MBR (DOS style)

### Check Filesystem Type
```bash
/ # blkid /dev/mmcblk0p1
/dev/mmcblk0p1: LABEL="boot" UUID="..." TYPE="vfat"

/ # blkid /dev/mmcblk0p2
/dev/mmcblk0p2: LABEL="rootfs" UUID="..." TYPE="ext4"
```

---

## 8.4 Enable Dynamic Device Management (Optional)

### Mount devtmpfs
Some systems need this for all devices to appear:

```bash
/ # mount -t devtmpfs devtmpfs /dev
```

**What It Does:**
- Dynamically creates device nodes as kernel detects devices
- Kernel detects new hardware → device node automatically appears
- Better than static /dev nodes

### Verify
```bash
/ # ls /dev/ | wc -l
# Should show many more devices

/ # ls /dev/mem /dev/zero /dev/random
# Should all exist now
```

---

## 8.5 Mount Raspberry Pi OS Root Partition

### Create Mount Point
```bash
/ # mkdir -p /mnt/pi_root
```

### Mount the Partition
```bash
/ # mount /dev/mmcblk0p2 /mnt/pi_root
```

### Verify Mount
```bash
/ # mount | grep pi_root
/dev/mmcblk0p2 on /mnt/pi_root type ext4 (rw,relatime)

/ # df -h /mnt/pi_root
Filesystem      Size  Used Avail Use% Mounted on
/dev/mmcblk0p2 59.3G   10G   49G  17% /mnt/pi_root
```

### List Contents
```bash
/ # ls /mnt/pi_root
bin   boot  dev  etc  home  lib  media  mnt  opt  proc  root  run  sbin  srv  sys  tmp  usr  var

/ # ls -la /mnt/pi_root/ | head -20
drwxr-xr-x  20 root root  4096 /mnt/pi_root
drwxr-xr-x   2 root root  4096 /mnt/pi_root/bin
drwxr-xr-x   3 root root  4096 /mnt/pi_root/boot
...
```

**What This Means:**
- ✓ You can access Pi OS filesystem as data
- ✓ All files readable from your custom OS
- ✓ Entire SD card content available

---

## 8.6 Mount Boot Partition (Optional)

### Create Mount Point
```bash
/ # mkdir -p /mnt/boot
```

### Mount FAT Partition
```bash
/ # mount /dev/mmcblk0p1 /mnt/boot
```

### Verify
```bash
/ # ls /mnt/boot
bcm2711-rpi-4-b.dtb  cmdline.txt  config.txt  ...
kernel8-console-v1.img
initramfs-console-v2.cpio.gz
```

### Edit Boot Configuration (if needed)
```bash
/ # cat /mnt/boot/cmdline.txt
console=serial0,115200 console=tty1 root=/dev/ram0 rw rdinit=/init

/ # cat /mnt/boot/config.txt | grep kernel
kernel=kernel8-console-v1.img
```

---

## 8.7 Access Pi OS via Chroot (Optional)

### What You Can Do
From your custom OS, you can actually run Raspberry Pi OS programs:

```bash
/ # chroot /mnt/pi_root /bin/bash
root@raspberrypi:/#
```

Now you're in:
- Your kernel (kernel8-console-v1)
- Pi OS userland (bash, apt, etc.)
- Mounted on RAM filesystem

### What's Available
```bash
root@raspberrypi:/# apt update
root@raspberrypi:/# apt list --installed | wc -l
# Shows many Pi OS packages installed

root@raspberrypi:/# uname -a
Linux raspberrypi 6.12.60-console-v1+ ...
                  ^^^^^^^^^^^^^^^^
                  Still your kernel!
```

### Exit Chroot
```bash
root@raspberrypi:/# exit
/ #
```

Back to your minimal OS.

---

## 8.8 Folder Structure Overview

### Your Current Setup

```
RAM Disk (/)
├── bin/busybox           ← Your tools
├── sbin/init            ← Your startup
├── proc/                ← Kernel info
├── sys/                 ← Hardware info
├── dev/                 ← Device nodes
├── tmp/                 ← Temp files
└── mnt/
    ├── pi_root/         ← Old Pi OS root (mounted)
    │   ├── bin/
    │   ├── lib/
    │   ├── usr/
    │   └── ...
    └── boot/            ← Boot partition (optional)
        ├── config.txt
        ├── cmdline.txt
        └── kernel8-console-v1.img
```

### From Your OS Perspective

```
/ # mount
rootfs on / type rootfs (rw)
devtmpfs on /dev type devtmpfs (rw)
proc on /proc type proc (rw)
sysfs on /sys type sysfs (rw)
/dev/mmcblk0p2 on /mnt/pi_root type ext4 (rw)
/dev/mmcblk0p1 on /mnt/boot type vfat (rw)
```

---

## 8.9 Common Operations

### Find a File on Pi OS Disk
```bash
/ # find /mnt/pi_root -name "*.config" -type f | head

/mnt/pi_root/root/.config
/mnt/pi_root/home/pi/.config
/mnt/pi_root/etc/...
```

### Copy Files from Pi OS to Your OS
```bash
/ # cp /mnt/pi_root/etc/os-release .
/ # cat os-release
PRETTY_NAME="Raspberry Pi OS (bullseye)"
NAME="Raspberry Pi OS"
VERSION_ID="11"
```

### Check Disk Usage
```bash
/ # du -sh /mnt/pi_root/*
10G  /mnt/pi_root/home
2.5G /mnt/pi_root/var
1.2G /mnt/pi_root/usr
...
```

### Backup a File
```bash
/ # cp /mnt/pi_root/etc/fstab /mnt/pi_root/etc/fstab.backup
```

---

## 8.10 Mount Options

### Remount Read-Only (Safety)
```bash
/ # mount -o remount,ro /mnt/pi_root
```

Now filesystem is read-only - safer!

### Remount Read-Write
```bash
/ # mount -o remount,rw /mnt/pi_root
```

### Mount Synchronously (Slower but Safer)
```bash
/ # mount -o sync /dev/mmcblk0p2 /mnt/pi_root
```

### Check Mount Options
```bash
/ # mount | grep pi_root
/dev/mmcblk0p2 on /mnt/pi_root type ext4 (rw,relatime)
                                            ^^^^^^^^^^
                                            Mount options
```

---

## 8.11 Unmounting Partitions

### Clean Unmount
```bash
/ # umount /mnt/pi_root
/ # umount /mnt/boot
```

### Check What's Mounted
```bash
/ # mount | grep mnt
# Should be empty after unmount
```

### Force Unmount (if busy)
```bash
/ # umount -f /mnt/pi_root
# Or
/ # umount -l /mnt/pi_root  # Lazy unmount
```

---

## Complete Workflow Example

### Initial Boot
```bash
/ # mount /dev/mmcblk0p2 /mnt/pi_root
/ # ls /mnt/pi_root
bin boot dev etc home lib ...

/ # df -h /mnt/pi_root
/dev/mmcblk0p2 59.3G 10G 49G ...
```

### Browse Pi OS
```bash
/ # cat /mnt/pi_root/etc/hostname
raspberrypi

/ # cat /mnt/pi_root/etc/issue
Raspberry Pi OS (bullseye)
```

### Access Program
```bash
/ # cat /mnt/pi_root/usr/bin/python3 | head
#!/usr/bin/python3.9

/ # /mnt/pi_root/usr/bin/python3 --version
Python 3.9.13
```

### Cleanup
```bash
/ # umount /mnt/pi_root
```

---

## What You've Achieved

✅ Detected all SD card partitions
✅ Mounted Raspberry Pi OS as data disk
✅ Accessed old OS filesystem
✅ Can read/write Pi OS files
✅ Can run Pi OS programs (with chroot)
✅ Demonstrated full system integration

---

## Current System Status

### Your OS
```
Kernel:     6.12.60-console-v1+ (yours)
OS:         BusyBox minimal
Storage:    RAM disk (initramfs)
Devices:    /dev/console, /dev/null, etc.
```

### Accessible Resources
```
Boot Files:     /mnt/boot/ (FAT)
Root Files:     /mnt/pi_root/ (ext4)
Raw Devices:    /dev/mmcblk0*
Raw Partitions: /dev/mmcblk0p1, /dev/mmcblk0p2
```

---

## Security Considerations

### Mounted at Boot
Currently, your /init only mounts /proc and /sys.

For automated access, modify /init:
```bash
#!/bin/sh
echo "Booting custom console OS..."
mount -t proc proc /proc
mount -t sysfs sys /sys
mount /dev/mmcblk0p2 /mnt/pi_root
# Now SD card automatically available
exec /bin/sh
```

### Read-Only Option
For safety (no accidental writes):
```bash
mount -o ro /dev/mmcblk0p2 /mnt/pi_root
```

---

## Next Steps

Now that you have:
1. ✓ Custom kernel booting
2. ✓ Custom OS running from initramfs
3. ✓ Access to SD card data

You can:
- Add game emulators
- Implement controller input
- Build game launcher interface
- Optimize for games/console mode

---

## Files and Partitions Reference

| Item | Purpose | Size | Location |
|------|---------|------|----------|
| Kernel | Boot Linux | 10-15 MB | /boot/firmware/kernel8-console-v1.img |
| Initramfs | OS in RAM | 2.5 MB | /boot/firmware/initramfs-console-v2.cpio.gz |
| Pi Boot | Boot partition | 256 MB | /dev/mmcblk0p1 |
| Pi Root | Old OS | 59 GB | /dev/mmcblk0p2 |
| Total Card | Storage | 62 GB | /dev/mmcblk0 |

---

## Summary of Complete System

```
When you power on your Raspberry Pi now:

Power On
    ↓
GPU loads kernel + initramfs from FAT partition
    ↓
Kernel decompresses and boots (with your -console-v1 suffix)
    ↓
Kernel loads initramfs as root filesystem in RAM
    ↓
Your /init script runs
    ↓
BusyBox shell starts
    ↓
You can now:
    - Mount /dev/mmcblk0p2 to access old Pi OS
    - Use all BusyBox tools
    - Control hardware via /sys and /proc
    - Build your console interface
    - Run games/emulators
    
Your custom OS is independent from Raspberry Pi OS!
It runs completely in RAM with full hardware control.
```

Congratulations! You've built a complete custom embedded OS! 🎉
