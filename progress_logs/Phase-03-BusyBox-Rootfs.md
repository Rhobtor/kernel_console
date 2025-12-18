# Phase 3: BusyBox & Minimal Rootfs

## Overview
Creating a lightweight root filesystem using BusyBox - a single binary that contains 300+ Unix tools.

---

## 3.1 Create Development Directory

### What You Did
```bash
cd ~
mkdir -p os_lab
cd os_lab
```

Creates an isolated workspace for OS development.

### Directory Structure After This Phase
```
os_lab/
├── busybox-1.36.1/      (BusyBox source)
├── rootfs/              (Your custom filesystem)
└── initramfs.cpio.gz    (Packaged OS)
```

---

## 3.2 Download BusyBox

### What You Did
```bash
wget https://busybox.net/downloads/busybox-1.36.1.tar.bz2
tar xf busybox-1.36.1.tar.bz2
cd busybox-1.36.1
```

### What is BusyBox?

BusyBox is a **single executable** that implements:
- `sh` (shell)
- `ls`, `cp`, `mv`, `rm` (file commands)
- `cat`, `grep`, `sed`, `awk` (text processing)
- `wget`, `curl` (network tools)
- `mount`, `umount` (filesystem tools)
- `modprobe`, `insmod` (module loading)
- **300+ more tools** (all in one binary!)

### Why Use BusyBox?

| Traditional | BusyBox |
|-------------|---------|
| bash: 1.5 MB | busybox: 1-3 MB |
| coreutils: 10 MB | (included) |
| grep: 0.2 MB | (included) |
| sed: 0.3 MB | (included) |
| **Total: 30+ MB** | **Total: 1-3 MB** |

Perfect for embedded systems!

### Download Size
```bash
ls -lh busybox-1.36.1.tar.bz2
# Output: ~2.2 MB
```

---

## 3.3 Configure BusyBox

### What You Did
```bash
make defconfig
make menuconfig
```

### Step 1: Default Configuration
```bash
make defconfig
```

Creates initial `.config` with standard options enabled.

### Step 2: Interactive Menu Configuration
```bash
make menuconfig
```

Opens interactive menu to customize features.

### Critical Settings to Modify

#### Disable Traffic Control (to avoid compilation errors)
```
Networking Utilities
  └─ [ ] tc (Traffic Control) ← UNCHECK THIS
```

Why: BusyBox includes tc by default, but it has compilation issues in some versions. Disabling it prevents build errors.

#### Enable Static Binary (optional, but recommended)
```
Settings
  └─ [*] Build static binary (no shared libs)
```

Why: 
- No dependency on system C library (/lib)
- Works everywhere, including in initramfs
- Single binary that's truly self-contained

#### Network Utilities to Keep
```
Networking Utilities
  ✓ wget       (download files)
  ✓ curl       (HTTP client)
  ✓ ifconfig   (network config)
  ✓ route      (routing)
  ✓ iptables   (firewall rules)
```

### Navigating menuconfig

| Key | Action |
|-----|--------|
| ↑/↓ | Navigate menu |
| ← /→ | Select buttons |
| Space | Toggle checkbox |
| y | Answer yes |
| n | Answer no |
| ? | Show help |
| / | Search |
| ESC | Exit/back |

---

## 3.4 Compile BusyBox

### What You Did
```bash
make clean
make -j4
```

### What Each Step Does

| Command | Purpose |
|---------|---------|
| `make clean` | Remove previous build files |
| `make -j4` | Compile with 4 parallel threads |

### Compilation Output
```
Compiling lib/
Compiling applets/
Compiling util-linux/
Linking busybox...
```

### Resulting Binary
```bash
ls -lh busybox
# Output: -rwxr-xr-x busybox 1.5M
```

### Verify It Works
```bash
./busybox --version
# Output: BusyBox v1.36.1

./busybox
# Shows list of 300+ applets
```

---

## 3.5 Install BusyBox to Rootfs

### What You Did
```bash
mkdir -p ~/os_lab/rootfs
make CONFIG_PREFIX=~/os_lab/rootfs install
```

### What It Does

```
BusyBox Installation Process:
    ↓
make install
    ↓
Creates bin/busybox (the binary)
    ↓
Creates symlinks for each applet:
  bin/sh -> busybox
  bin/ls -> busybox
  bin/cp -> busybox
  bin/grep -> busybox
  ... (300+ more)
    ↓
Creates standard directories:
  bin/, sbin/, usr/bin/, usr/sbin/
    ↓
Result: A complete minimal filesystem tree
```

### Resulting Structure
```bash
ls -R ~/os_lab/rootfs/
```

Output:
```
bin/
  busybox          (1.5 MB, the main binary)
  sh -> busybox    (symlink)
  ls -> busybox
  cp -> busybox
  grep -> busybox
  ... (300+ more symlinks)

sbin/
  busybox -> /bin/busybox
  init -> busybox
  ... (50+ applets)

usr/
  bin/             (even more applets)
  sbin/

lib/               (if dynamic BusyBox)
linuxrc -> bin/sh
```

### Size Comparison

| Filesystem | Size |
|-----------|------|
| Full Linux distro | 2-5 GB |
| Raspberry Pi OS | 3-4 GB |
| BusyBox rootfs | 5-10 MB |
| Your rootfs (with extras) | 20-50 MB |

---

## 3.6 Verify Installation

### Check the Binary
```bash
file ~/os_lab/rootfs/bin/busybox
# Output: ELF 64-bit LSB executable, ARM aarch64...

ls -lh ~/os_lab/rootfs/bin/busybox
# Output: -rwxr-xr-x busybox 1.5M
```

### Check Symlinks
```bash
ls -l ~/os_lab/rootfs/bin/ | head -20
# Shows: sh -> busybox, ls -> busybox, etc.
```

### Count Applets
```bash
ls -l ~/os_lab/rootfs/bin/ | wc -l
# Output: ~250+ entries
```

### Test in Chroot (preview)
```bash
sudo chroot ~/os_lab/rootfs /bin/busybox --version
# Output: BusyBox v1.36.1
```

---

## Directory Structure After Phase 3

```
os_lab/
├── busybox-1.36.1/
│   ├── busybox          (compiled binary)
│   ├── .config
│   └── Makefile
│
└── rootfs/
    ├── bin/
    │   ├── busybox      (1.5 MB)
    │   ├── sh -> busybox
    │   ├── ls -> busybox
    │   └── ... (300+ more)
    │
    ├── sbin/
    │   ├── init -> busybox
    │   └── ... (50+ tools)
    │
    ├── usr/
    │   ├── bin/
    │   └── sbin/
    │
    └── lib/             (only if dynamic BusyBox)
```

---

## Common Issues & Solutions

### Issue: `make: gcc: command not found`
**Solution:**
```bash
sudo apt install build-essential
```

### Issue: Compilation fails with TCA_CBQ_ errors
**Cause:** tc (Traffic Control) enabled

**Solution:**
```bash
make menuconfig
# Disable: Networking Utilities → tc
make clean && make -j4
```

### Issue: `CONFIG_PREFIX` not working
**Cause:** Using wrong path or syntax

**Solution:**
```bash
# Make sure you're in busybox-1.36.1 directory
pwd
# Should be: /home/user/os_lab/busybox-1.36.1

make CONFIG_PREFIX=~/os_lab/rootfs install
```

### Issue: Symlinks not created correctly
**Solution:**
```bash
# Check symlinks
ls -l ~/os_lab/rootfs/bin/

# If missing, reinstall
cd ~/os_lab/busybox-1.36.1
make clean && make -j4
make CONFIG_PREFIX=~/os_lab/rootfs install
```

---

## What You Now Have

✓ BusyBox compiled for ARM64
✓ 300+ Unix tools in single binary
✓ Proper directory structure (/bin, /sbin, /usr, etc.)
✓ Foundation for your custom OS

---

## Next Steps

→ **Phase 4: Create /dev/console, /dev/null, and init script**

You now have the tools. Next, you'll:
1. Create device nodes
2. Create a filesystem structure
3. Write an init script
4. Create a complete bootable rootfs

---

## Applets Available in Your BusyBox

Common tools included:
```
File Tools:     ls, cp, mv, rm, chmod, chown, mkdir, rmdir, touch
Text Tools:     cat, grep, sed, awk, sort, uniq, head, tail, wc
Archive Tools:  tar, gzip, bzip2, zip, unzip
Network Tools:  wget, curl, ifconfig, route, ping, netstat
System Tools:   ps, top, df, mount, umount, modprobe, insmod
Shell:          sh, ash, bash (minimal)
```

**All in one 1.5 MB binary!**
