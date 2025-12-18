# Phase 6: Initramfs Packaging

## Overview
Converting your rootfs into a compressed archive that the kernel will load into RAM at boot time.

---

## 6.1 Create CPIO Archive

### What You Did
```bash
cd ~/os_lab/rootfs
sudo find . | cpio -H newc -o | gzip > ../initramfs-console-v2.cpio.gz
```

### Command Breakdown

```bash
sudo find . 
│    └─ Find all files/dirs in current directory (.)
│
| cpio -H newc -o
│     ├─ -H newc: Use modern CPIO format (newc = New C format)
│     └─ -o: Output mode (create archive)
│
| gzip 
│     └─ Compress the archive
│
> ../initramfs-console-v2.cpio.gz
      └─ Save to parent directory with this name
```

### What Each Tool Does

| Tool | Purpose |
|------|---------|
| **find .** | Lists all files and directories recursively |
| **cpio** | Archive tool (like tar, but older and simpler) |
| **-H newc** | CPIO header format (required for kernel) |
| **-o** | Create archive (output mode) |
| **gzip** | Compresses the archive |

### CPIO vs TAR

| Feature | CPIO | TAR |
|---------|------|-----|
| Format | Older, simpler | More modern |
| Kernel support | Native (initramfs) | Needs conversion |
| Compression | Via gzip/bzip2 | Native or external |
| Portability | Less common | Very common |

Kernel specifically needs CPIO for initramfs!

---

## 6.2 Verify Archive Creation

### Check File Size
```bash
ls -lh ~/os_lab/initramfs-console-v2.cpio.gz
# Output: -rw-r--r-- 1 root root 2.5M
```

### Compression Ratio
```bash
du -sh ~/os_lab/rootfs
# Uncompressed: 5-10 MB

ls -lh ~/os_lab/initramfs-console-v2.cpio.gz
# Compressed: 2-3 MB (≈50-60% compression)
```

### List Archive Contents
```bash
cd ~/os_lab
zcat initramfs-console-v2.cpio.gz | cpio -t | head -20
```

Output should show:
```
.
./init
./bin
./bin/busybox
./bin/sh
./sbin
./proc
./sys
./dev/console
./dev/null
./tmp
./mnt
... (all your rootfs files)
```

### Verify All Critical Files Present
```bash
# Check init script
zcat initramfs-console-v2.cpio.gz | cpio -t | grep init

# Check device nodes
zcat initramfs-console-v2.cpio.gz | cpio -t | grep "dev/"

# Check BusyBox
zcat initramfs-console-v2.cpio.gz | cpio -t | grep "bin/busybox"
```

---

## 6.3 Copy to Boot Partition

### What You Did
```bash
sudo cp ~/os_lab/initramfs-console-v2.cpio.gz /boot/firmware/
```

### Verify Copy
```bash
ls -lh /boot/firmware/initramfs*.cpio.gz
# Output: -rw-r--r-- /boot/firmware/initramfs-console-v2.cpio.gz
```

### Backup Previous Initramfs (if exists)
```bash
# If you have a previous version:
sudo mv /boot/firmware/initramfs-console-v2.cpio.gz \
        /boot/firmware/initramfs-console-v2.cpio.gz.old
```

### Boot Partition Layout
```
/boot/firmware/
├── bootcode.bin         (GPU bootloader)
├── start4.elf          (GPU firmware)
├── kernel8-console-v1.img   (YOUR kernel)
├── initramfs-console-v2.cpio.gz  (YOUR initramfs)
├── bcm2711-rpi-4-b.dtb (Device tree)
├── config.txt          (Firmware config)
└── cmdline.txt         (Kernel parameters)
```

---

## 6.4 Understand Initramfs Concept

### Traditional Boot

```
Power On
    ↓
GPU loads kernel from disk
    ↓
Kernel mounts /dev/mmcblk0p2 (SD card root)
    ↓
Kernel starts /sbin/init
    ↓
Init script runs (from SD card)
    ↓
Full OS loads
```

**Problem:** Need drivers to read SD card BEFORE OS loads (chicken-egg problem)

### Initramfs Boot

```
Power On
    ↓
GPU loads kernel AND initramfs from disk
    ↓
GPU decompresses initramfs into RAM
    ↓
GPU passes control to kernel with:
    root=/dev/ram0 (RAM disk is root)
    rdinit=/init (use initramfs /init)
    ↓
Kernel mounts /dev/ram0 (already in RAM)
    ↓
Kernel executes /init from initramfs
    ↓
Initramfs OS runs (your BusyBox)
    ↓
(Optionally) pivot_root to real root later
```

**Advantage:** Entire OS in RAM, no drivers needed yet!

### Initramfs Size Constraints

| Parameter | Typical | Notes |
|-----------|---------|-------|
| GPU memory | 256 MB | Can load large initramfs |
| RAM available | 4-8 GB | Plenty of room for OS |
| Typical initramfs | 2-10 MB | Well within limits |
| Your initramfs | ~2.5 MB | Very small, no issues |

---

## 6.5 Archive Format Deep Dive

### CPIO Format
```
cpio = Copy In, Copy Out
```

Example of what's inside:

```
Header: C59B69FE (CPIO magic)
  Size: 0000100E (4110 bytes)
  Mode: 000081ED (regular file, 0755 permissions)
  Data: (file contents follow header)
Header: C59B69FE
  Size: 00000000 (0 bytes, directory)
  Mode: 000041ED (directory, 0755)
Header: (trailer, marks end of archive)
```

Modern newc format includes:
- File metadata (size, mode, owner, times)
- File contents
- Directory structure
- Proper ordering

---

## 6.6 Testing Archive Integrity

### Extract and Verify
```bash
# Create test directory
mkdir -p /tmp/test_initramfs
cd /tmp/test_initramfs

# Extract archive
zcat ~/os_lab/initramfs-console-v2.cpio.gz | cpio -i

# List extracted files
ls -la
# Should show: init, bin/, sbin/, dev/, proc/, sys/, etc.

# Verify init
file init
# Output: init: Bourne-Again shell script text executable

# Verify BusyBox
file bin/busybox
# Output: bin/busybox: ELF 64-bit LSB executable, ARM aarch64

# Verify device node
ls -l dev/console
# Output: crw------- console (major 5, minor 1)
```

### Check File Permissions
```bash
# Init should be executable
ls -l init
# Output: -rwxr-xr-x init

# Device nodes should have correct permissions
ls -l dev/
# console: crw------- (600)
# null:    crw-rw-rw- (666)
```

---

## File Size Analysis

### Typical Breakdown
```
Uncompressed rootfs:
  bin/busybox:        1.5 MB (BusyBox binary)
  bin/sh -> busybox:  0 KB (symlink)
  ... other applets:  0 KB (symlinks)
  sbin/init:          0 KB (small script)
  /dev nodes:         0 KB (special files)
  directories:        ~10 MB (depends on applets)
  TOTAL:              ~10-15 MB

Compressed (gzip):
  Ratio:              ~30-40% (text and symlinks compress well)
  Result:             ~2.5-5 MB
```

### Optimization Opportunities

If you want smaller initramfs:
```bash
# 1. Remove unused applets (menuconfig in Phase 3)
# 2. Strip symbols from busybox
strip ~/os_lab/rootfs/bin/busybox

# 3. Use bzip2 for better compression
cd ~/os_lab/rootfs
find . | cpio -H newc -o | bzip2 > ../initramfs-console-v2.cpio.bz2

# 4. Use xz for even better compression (slower)
cd ~/os_lab/rootfs
find . | cpio -H newc -o | xz > ../initramfs-console-v2.cpio.xz
```

Your current size (2.5 MB) is already excellent!

---

## Common Issues & Solutions

### Issue: "find: command not found" (in sudo)
**Cause:** find not in PATH for root's environment

**Solution:**
```bash
# Use full path
sudo /usr/bin/find . | cpio -H newc -o | gzip > ../initramfs-console-v2.cpio.gz

# Or don't use sudo (if directory is readable)
find . | sudo cpio -H newc -o | gzip | sudo tee ../initramfs-console-v2.cpio.gz > /dev/null
```

### Issue: "cpio: write error" (Disk full)
**Cause:** Not enough space in /home

**Solution:**
```bash
# Check space
df -h /home
df -h /tmp

# Use /tmp if it has more space (smaller in embedded systems though)
cd ~/os_lab/rootfs
sudo find . | cpio -H newc -o | gzip > /tmp/initramfs-console-v2.cpio.gz
sudo cp /tmp/initramfs-console-v2.cpio.gz ~/os_lab/
```

### Issue: "Permission denied" during copy to /boot/firmware
**Cause:** Need sudo for boot partition

**Solution:**
```bash
sudo cp ~/os_lab/initramfs-console-v2.cpio.gz /boot/firmware/
# Always use sudo for /boot files
```

### Issue: Archive is corrupted
**Cause:** Error during cpio/gzip

**Solution:**
```bash
# Test archive
gunzip -t ~/os_lab/initramfs-console-v2.cpio.gz
# Output: (ok) or error message

# If corrupted, regenerate
cd ~/os_lab/rootfs
sudo find . | cpio -H newc -o | gzip > ../initramfs-console-v2.cpio.gz.new
mv ../initramfs-console-v2.cpio.gz.new ../initramfs-console-v2.cpio.gz
```

---

## What You've Created

✅ Compressed initramfs archive
✅ Proper CPIO format for kernel
✅ Bootable OS package (~2.5 MB)
✅ Ready to load at boot time

---

## Files Created

| File | Size | Purpose |
|------|------|---------|
| `~/os_lab/initramfs-console-v2.cpio.gz` | 2.5 MB | Compressed OS image |
| `/boot/firmware/initramfs-console-v2.cpio.gz` | 2.5 MB | In boot partition |

---

## Next Steps

→ **Phase 7: Configure kernel to load initramfs**

You now have:
1. ✓ Compiled kernel
2. ✓ BusyBox rootfs
3. ✓ Compressed initramfs

Next: Tell the firmware and kernel to use this initramfs when booting!
