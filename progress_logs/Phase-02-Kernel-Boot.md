# Phase 2: Kernel Installation & Boot

## Overview
Copying your compiled kernel to the boot partition and configuring the Pi firmware to use it.

---

## 2.1 Copy Kernel to Boot Partition

### What You Did
```bash
cd ~/kernel_test/linux
sudo cp arch/arm64/boot/Image.gz /boot/firmware/kernel8-console-v1.img
```

### Why This Naming
- `kernel8` = 64-bit kernel designation
- `-console-v1` = YOUR custom version identifier
- `.img` = image file extension

Keeps your kernel separate from the default Pi kernel (important for recovery!).

### Verification
```bash
ls -lh /boot/firmware/kernel8*.img
```

You should see:
```
-rw-r--r-- kernel8.img                 (default Pi kernel)
-rw-r--r-- kernel8-console-v1.img      (YOUR custom kernel)
```

---

## 2.2 Configure Firmware to Use Your Kernel

### What You Did
```bash
sudo nano /boot/firmware/config.txt
```

### Edit These Lines

Add or modify:
```
arm_64bit=1
kernel=kernel8-console-v1.img
#auto_initramfs=1
```

### Line-by-Line Explanation

| Line | Meaning | Impact |
|------|---------|--------|
| `arm_64bit=1` | Boot in 64-bit mode | Uses aarch64, not armv7l |
| `kernel=kernel8-console-v1.img` | Which kernel to load | GPU boots YOUR kernel |
| `#auto_initramfs=1` | Disable auto initramfs | Prevents conflicts later |

### File Location
```
/boot/firmware/config.txt
^^^^^^^^^^^^^^^
GPU reads this before booting kernel
```

### Full Example config.txt
```
# Enable 64-bit boot
arm_64bit=1

# Use your custom kernel
kernel=kernel8-console-v1.img

# Disable automatic initramfs handling
#auto_initramfs=1

# Standard Pi4 configurations
gpu_mem=256
over_voltage=0
arm_freq=1800

# Display and console
hdmi_group=1
hdmi_mode=16
```

---

## 2.3 Reboot and Verify

### What You Did
```bash
sudo reboot
```

### After Reboot
```bash
uname -a
```

### Expected Output
```
Linux raspberrypi 6.12.60-console-v1+ #1 SMP PREEMPT ...
                   ^^^^^^^^^^^^^^^^
                   YOUR kernel identifier!
```

### Verification Checklist

✅ **Check kernel version:**
```bash
uname -r
# Output: 6.12.60-console-v1+
```

✅ **Check architecture:**
```bash
uname -m
# Output: aarch64
```

✅ **Check if modules loaded:**
```bash
lsmod | head
# Shows loaded kernel modules
```

✅ **Check boot messages:**
```bash
dmesg | head -20
# Shows boot kernel messages
```

✅ **Check CPU info:**
```bash
cat /proc/cpuinfo | head -20
```

---

## 2.4 Kernel Features Verification

### Check Loaded Modules
```bash
lsmod | wc -l
# Shows number of loaded modules (should be 10-20+)
```

### List All Available Modules
```bash
find /lib/modules/$(uname -r)/kernel -name "*.ko" | wc -l
# Total available modules
```

### Check Hardware Detection
```bash
lspci
# Lists PCI devices detected by kernel

lsusb
# Lists USB devices
```

### Verify CONFIG Options
```bash
cat /proc/config.gz | gunzip | grep CONFIG_LOCALVERSION
# Output: CONFIG_LOCALVERSION="-console-v1"
```

---

## 2.5 Keep Backup of Original Kernel

### Safety Step
```bash
sudo cp /boot/firmware/kernel8.img /boot/firmware/kernel8-backup.img
```

If your custom kernel doesn't boot, you can recover:

Edit `/boot/firmware/config.txt`:
```
# Temporarily revert
kernel=kernel8-backup.img
```

Reboot and you're back to the default kernel.

---

## Boot Process Explained

```
Raspberry Pi Power On
        ↓
GPU Firmware Starts
        ↓
GPU reads /boot/firmware/config.txt
        ↓
GPU loads config options (arm_64bit=1, etc.)
        ↓
GPU loads kernel file: kernel8-console-v1.img
        ↓
GPU loads Device Trees (DTBs)
        ↓
GPU decompresses Image.gz
        ↓
GPU transfers control to kernel
        ↓
Kernel initializes hardware
        ↓
Kernel mounts rootfs
        ↓
Init script runs (Phase 4)
        ↓
You get a shell prompt
```

---

## Files Modified

| File | Change |
|------|--------|
| `/boot/firmware/kernel8-console-v1.img` | Added your kernel |
| `/boot/firmware/config.txt` | Added kernel= directive |
| `/lib/modules/6.12.60-console-v1+/` | Modules available |

---

## Common Issues & Solutions

### Issue: "kernel8-console-v1.img not found"
**Cause:** File wasn't copied correctly

**Solution:**
```bash
ls -lh /boot/firmware/kernel8*.img
# Verify file exists

# If missing, copy again:
sudo cp ~/kernel_test/linux/arch/arm64/boot/Image.gz \
  /boot/firmware/kernel8-console-v1.img
```

### Issue: Boots but shows wrong kernel version
**Cause:** config.txt still uses old kernel

**Solution:**
```bash
sudo nano /boot/firmware/config.txt
# Make sure this line exists:
# kernel=kernel8-console-v1.img

sudo reboot
```

### Issue: Boot hangs after GPU initialization
**Cause:** Kernel image corrupted or incompatible config

**Solution:**
1. Connect HDMI and USB keyboard
2. Revert to backup:
   ```bash
   sudo nano /boot/firmware/config.txt
   kernel=kernel8-backup.img
   sudo reboot
   ```
3. Check kernel compilation for errors
4. Review Phase 1

### Issue: Modules not loading
**Cause:** Module path doesn't exist or permissions wrong

**Solution:**
```bash
# Check module path
ls /lib/modules/$(uname -r)/

# If empty, reinstall modules
cd ~/kernel_test/linux
sudo make modules_install
```

---

## Next Steps

✅ Your kernel is now booting successfully!

→ **Next: Phase 3 - Create BusyBox and minimal rootfs**

You now have:
- ✓ Custom compiled kernel running
- ✓ Kernel modules available
- ✓ Device trees loaded
- ✓ Full hardware support

Next phase, you'll create a minimal OS to go with this kernel!

---

## Revert to Default Kernel (if needed)

If you want to go back to the original Pi kernel:

```bash
sudo nano /boot/firmware/config.txt
# Change to:
# kernel=kernel8.img

sudo reboot
```

---

## Performance Monitoring

Monitor your kernel while it's running:

```bash
# CPU usage and load
top

# Memory usage
free -h

# Kernel version details
cat /proc/version

# Device drivers loaded
lsmod | head -20

# Hardware info
cat /proc/cpuinfo
```

This kernel is now the foundation for everything that follows!
