# Phase 7: Boot Configuration

## Overview
Configuring the firmware and kernel to use your custom initramfs at boot time.

---

## 7.1 Configure Firmware to Load Initramfs

### What You Did
```bash
sudo nano /boot/firmware/config.txt
```

### Current Configuration
Verify or add these lines:
```
arm_64bit=1
kernel=kernel8-console-v1.img
initramfs initramfs-console-v2.cpio.gz followkernel
#auto_initramfs=1
```

### Configuration Parameters

| Parameter | Purpose | Value |
|-----------|---------|-------|
| `arm_64bit=1` | Boot in 64-bit mode | 1 = enable |
| `kernel=` | Which kernel to load | kernel8-console-v1.img |
| `initramfs` | Initramfs file to load | initramfs-console-v2.cpio.gz |
| `followkernel` | Load initramfs after kernel | (flag) |
| `#auto_initramfs` | Disable auto initramfs | (commented) |

### Line-by-Line Explanation

**arm_64bit=1**
```
GPU: "I should initialize CPU in 64-bit mode"
→ ARM CPU starts in aarch64 architecture
→ 32-bit vs 64-bit capability unlocked
```

**kernel=kernel8-console-v1.img**
```
GPU: "Where's the kernel to load?"
→ Answer: kernel8-console-v1.img
→ GPU reads this file from FAT boot partition
→ GPU decompresses and loads into RAM
```

**initramfs initramfs-console-v2.cpio.gz followkernel**
```
GPU: "Load an initramfs too, after the kernel"
→ File: initramfs-console-v2.cpio.gz
→ Timing: Load after kernel (followkernel)
→ Result: GPU loads both kernel and initramfs
```

**#auto_initramfs=1** (commented out)
```
This would: "Automatically find and load initramfs"
We disable it because: We specify our own initramfs explicitly
```

---

## 7.2 Configure Kernel Command Line

### What You Did
```bash
sudo cp /boot/firmware/cmdline.txt /boot/firmware/cmdline.txt.backup
sudo nano /boot/firmware/cmdline.txt
```

### Current Configuration
Replace entire line with:
```
console=serial0,115200 console=tty1 root=/dev/ram0 rw rdinit=/init
```

### Parameter Breakdown

| Parameter | Purpose | Meaning |
|-----------|---------|---------|
| `console=serial0,115200` | Serial console | Send output to UART at 115200 baud |
| `console=tty1` | HDMI console | Also send output to video display |
| `root=/dev/ram0` | Root filesystem | Mount RAM disk as root |
| `rw` | Mount flags | Mount as read-write |
| `rdinit=/init` | Init in RAM | Execute /init from initramfs |

### Serial Console Explained
```
console=serial0,115200
        ^^^^^^^^^^^^^^^
        UART port at this speed
        
Allows:
- Kernel messages on serial port
- Terminal access over USB-to-serial
- Boot debugging
```

### HDMI Console
```
console=tty1
        ^^^^
        Virtual terminal 1 (HDMI display)

Allows:
- Kernel messages on HDMI
- Keyboard input from USB
- Visual boot process
```

### Root=/dev/ram0
```
root=/dev/ram0
     ^^^^^^^^^^
     RAM disk

Tells kernel:
"The / (root) filesystem is a RAM disk"

Effect:
- Kernel mounts /dev/ram0 as /
- /dev/ram0 = initramfs decompressed into RAM
- Entire OS runs from RAM
```

### rdinit=/init
```
rdinit=/init
^^^^^    ^^^^
|        Path to init script
|
"RAM init": Init to execute for RAM disk

Tells kernel:
"In the initramfs, run /init as PID 1"

NOT: /sbin/init (default)
```

---

## 7.3 Boot Parameter Details

### Full Boot Sequence with These Parameters

```
Power On
    ↓
GPU reads /boot/firmware/config.txt
    ├─ arm_64bit=1 → Enable 64-bit mode
    ├─ kernel=kernel8-console-v1.img → Load this kernel
    └─ initramfs initramfs-console-v2.cpio.gz followkernel → Load initramfs
    ↓
GPU decompresses kernel and initramfs into RAM
    ↓
GPU transfers control to kernel with parameters:
    ├─ console=serial0,115200 → Use serial output
    ├─ console=tty1 → Use HDMI output
    ├─ root=/dev/ram0 → Root is RAM disk
    ├─ rw → Mount writable
    └─ rdinit=/init → Execute /init from initramfs
    ↓
Kernel boots
    ├─ Initializes ARM CPU (64-bit)
    ├─ Sets up interrupts
    ├─ Initializes memory management
    ├─ Discovers hardware
    ├─ Loads device drivers
    ├─ Decompresses initramfs into RAM
    └─ Mounts /dev/ram0 as root filesystem (/)
    ↓
Kernel looks for init:
    "Where is /init?"
    → Look in /dev/ram0 (root filesystem)
    → Execute /init
    ↓
Your /init script runs:
    ├─ Mounts /proc
    ├─ Mounts /sys
    ├─ Ensures /dev/console exists
    └─ Executes /bin/sh
    ↓
BusyBox shell starts (PID 1)
    ↓
You see: / #

Welcome to your custom OS!
```

---

## 7.4 Backup Original cmdline.txt

### What You Did
```bash
sudo cp /boot/firmware/cmdline.txt /boot/firmware/cmdline.txt.backup
```

### Why Backup?
If you make a mistake in cmdline.txt, the kernel won't boot properly.

### Restore If Needed
```bash
# If boot fails:
sudo cp /boot/firmware/cmdline.txt.backup /boot/firmware/cmdline.txt
sudo reboot
```

This reverts to Raspberry Pi OS defaults.

---

## 7.5 Verify Configuration Files

### Check config.txt
```bash
sudo nano /boot/firmware/config.txt
# Verify these lines exist:
# arm_64bit=1
# kernel=kernel8-console-v1.img
# initramfs initramfs-console-v2.cpio.gz followkernel
```

### Check cmdline.txt
```bash
cat /boot/firmware/cmdline.txt
# Should show:
# console=serial0,115200 console=tty1 root=/dev/ram0 rw rdinit=/init
```

### Check Files Exist
```bash
ls -lh /boot/firmware/kernel8-console-v1.img
# Output: -rw-r--r-- ... kernel8-console-v1.img

ls -lh /boot/firmware/initramfs-console-v2.cpio.gz
# Output: -rw-r--r-- ... initramfs-console-v2.cpio.gz
```

---

## 7.6 Prepare for Reboot

### Final Checklist

- ✅ `/boot/firmware/config.txt` has your kernel
- ✅ `/boot/firmware/config.txt` has your initramfs
- ✅ `/boot/firmware/cmdline.txt` has correct parameters
- ✅ `/boot/firmware/kernel8-console-v1.img` exists
- ✅ `/boot/firmware/initramfs-console-v2.cpio.gz` exists
- ✅ Backup of `cmdline.txt.backup` created
- ✅ Connected HDMI + keyboard for testing

### Reboot Command
```bash
sudo reboot
```

---

## 7.7 Expected Boot Output

### On HDMI Display
```
Booting up...
[Kernel boot messages...]
[Device initialization messages...]

=====================================
  Init minimal de la consola (v0.3)
=====================================

Montado /proc y /sys (o ya lo estaban)

Entrando en shell BusyBox...
/ #
```

### What You See
1. GPU firmware loads (no visible output usually)
2. Kernel decompresses and starts
3. Kernel initializes hardware (messages scroll)
4. Kernel executes your init script
5. Your BusyBox shell starts
6. You get the `/ #` prompt

### Verify Kernel Loaded
```bash
/ # uname -a
Linux raspberrypi 6.12.60-console-v1+ #1 SMP ...
                  ^^^^^^^^^^^^^^^^
                  Your kernel marker!
```

---

## Kernel Messages During Boot

### Common Messages

**Good Signs:**
```
[    0.000000] Linux version 6.12.60-console-v1+
[    0.000000] Command line: console=serial0,115200 console=tty1 root=/dev/ram0 rw rdinit=/init
[    0.000000] KERNEL supported cpus:
[    0.000000] CPU: ARMv8 Processor [410fd034] revision 4
[    0.000000] Machine: Raspberry Pi 4 Model B Rev 1.4
[    0.xxx000] cma: Reserved 76 MiB at ...
[    0.xxx000] Memory: ...
```

These indicate:
- ✓ Kernel decompressed successfully
- ✓ Detected Raspberry Pi 4
- ✓ Parameters passed correctly
- ✓ Memory initialized

**Expected Errors (Not Critical):**
```
[    x.xxxxxx] WARNING: CPU: x PID: x at drivers/...
[    x.xxxxxx] some module: ERROR: could not initialize X

These are usually non-critical driver messages
```

### Boot Hangs at Different Points

| Symptom | Likely Issue |
|---------|--------------|
| Hangs before kernel messages | GPU problem or kernel file corrupted |
| Kernel boots but no /init output | cmdline.txt wrong (rdinit=/init) |
| Shows messages but hangs | Init script error or missing device node |

---

## Troubleshooting Boot Issues

### Issue: Screen stays black
**Possible Causes:**
1. GPU can't find kernel file
2. Kernel won't decompress
3. Wrong console setting

**Solutions:**
```bash
# Check files exist
ls -lh /boot/firmware/kernel8*.img
ls -lh /boot/firmware/initramfs*.cpio.gz

# Add debugging to config.txt
sudo nano /boot/firmware/config.txt
# Add:
enable_uart=1        # Enable serial debug output

# Check USB-to-serial for messages
screen /dev/ttyUSB0 115200
```

### Issue: "kernel8-console-v1.img not found"
**Cause:** File doesn't exist or wrong name

**Solution:**
```bash
# Check exact filename
ls /boot/firmware/kernel8*.img

# Update config.txt with correct name
sudo nano /boot/firmware/config.txt
```

### Issue: Init script doesn't run
**Cause:** rdinit parameter wrong

**Solution:**
```bash
# Check cmdline.txt
cat /boot/firmware/cmdline.txt
# Must contain: rdinit=/init

# Verify init exists
zcat /boot/firmware/initramfs-console-v2.cpio.gz | cpio -t | grep "^./init$"
```

### Issue: "init: can't open /dev/console"
**Cause:** Device node not in initramfs

**Solution:**
```bash
# Regenerate initramfs with device nodes
cd ~/os_lab/rootfs
sudo find . | cpio -H newc -o | gzip > ../initramfs-console-v2.cpio.gz
sudo cp ../initramfs-console-v2.cpio.gz /boot/firmware/
sudo reboot
```

---

## Advanced Parameters (Optional)

### Enable Serial Debug
Add to `/boot/firmware/config.txt`:
```
enable_uart=1
```

Add to `/boot/firmware/cmdline.txt`:
```
console=serial0,115200 console=tty1 root=/dev/ram0 rw rdinit=/init loglevel=8
```

### Increase GPU Debug Output
```
config.txt:
dtdebug=1
```

### Disable Video
```
config.txt:
hdmi_blanking=2
```

---

## What You've Configured

✅ Firmware to load kernel and initramfs
✅ Kernel to use RAM disk as root
✅ Kernel to use your /init script
✅ Console output to both serial and HDMI
✅ Backup of original configuration

---

## Files Modified

| File | Change |
|------|--------|
| `/boot/firmware/config.txt` | Added initramfs directive |
| `/boot/firmware/cmdline.txt` | Changed root and rdinit parameters |
| `/boot/firmware/cmdline.txt.backup` | Saved original |

---

## Critical Points to Remember

1. **cmdline.txt is ONE line** - don't add newlines!
2. **root=/dev/ram0** - tells kernel root is in RAM
3. **rdinit=/init** - tells kernel which init to run
4. **followkernel** - timing for GPU loading
5. **Backup matters** - always save originals

---

## Next Steps

→ **Phase 8: Access SD card from your custom OS**

After first successful boot:
1. Verify kernel and OS running
2. Access the SD card partitions
3. Mount Raspberry Pi OS as data storage
4. Test full system integration

Ready to power on and watch your custom OS boot!
