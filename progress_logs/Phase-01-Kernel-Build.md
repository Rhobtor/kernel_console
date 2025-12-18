# Phase 1: Kernel Preparation & Compilation

## Overview
Setting up the development environment and building a custom Linux kernel for ARM (Raspberry Pi 4).

---

## 1.1 Verify Raspberry Pi Architecture

### What You Did
```bash
uname -m
```

### Purpose
Confirms your Pi is running in **aarch64 (64-bit)** mode. This determines:
- Which kernel version to use
- Which configuration templates to apply
- Which cross-compilation flags are needed

### Expected Result
```
aarch64
```

---

## 1.2 Install Build Tools

### What You Did
```bash
sudo apt update
sudo apt install -y git bc bison flex libssl-dev make libc6-dev libncurses5-dev
```

### Tool Breakdown

| Tool | Purpose |
|------|---------|
| **git** | Downloads kernel source code from repositories |
| **bc** | Calculator utility used during kernel build |
| **bison, flex** | Parser and lexer generators for build tools |
| **libssl-dev** | Cryptographic libraries for kernel components |
| **make** | Orchestrates the entire compilation process |
| **libc6-dev** | C library headers needed for kernel compilation |
| **libncurses5-dev** | Terminal UI library for kernel menuconfig |

### Why These Matter
Without these tools, you cannot build a Linux kernel. Each one handles a specific part of the compilation pipeline.

---

## 1.3 Download Kernel Source

### What You Did
```bash
cd ~
mkdir -p kernel_test
cd kernel_test
git clone --depth=1 https://github.com/raspberrypi/linux
cd linux
```

### What Each Part Does

| Command | Purpose |
|---------|---------|
| `mkdir -p kernel_test` | Creates isolated development directory |
| `git clone --depth=1` | Downloads ONLY latest version (saves bandwidth) |
| `https://github.com/raspberrypi/linux` | Official Raspberry Pi kernel repo |

### Download Size
- Full repo: ~1-2 GB
- With `--depth=1`: ~200-400 MB (much faster)

### Expected Structure
```
kernel_test/
└── linux/
    ├── arch/          (architecture-specific code)
    ├── drivers/       (device drivers)
    ├── fs/            (filesystem support)
    ├── include/       (header files)
    ├── kernel/        (core kernel code)
    ├── Makefile       (build instructions)
    └── ...
```

---

## 1.4 Generate Default Configuration

### What You Did
```bash
export KERNEL=kernel8
make bcm2711_defconfig
```

### What It Does

| Step | Purpose |
|------|---------|
| `export KERNEL=kernel8` | Sets variable for 64-bit Pi kernel build |
| `make bcm2711_defconfig` | Loads optimized config for BCM2711 SoC (Pi 4) |

### Result
Creates `.config` file with **2000+ kernel options** pre-configured:
- ✓ ARM64 architecture enabled
- ✓ Pi 4 drivers enabled
- ✓ Required filesystems enabled
- ✓ Networking stack configured
- ✓ USB, SATA, GPIO drivers enabled

### File Size
```bash
ls -lh .config
# Output: -rw-r--r-- 1 user user 220K .config
```

---

## 1.5 Customize Kernel Identifier

### What You Did
```bash
nano .config
# Search for: CONFIG_LOCALVERSION=
# Change to: CONFIG_LOCALVERSION="-console-v1"
```

### How to Do This in nano
1. Press `Ctrl+W` to search
2. Type `CONFIG_LOCALVERSION`
3. Press `Enter`
4. Edit the line to: `CONFIG_LOCALVERSION="-console-v1"`
5. Save with `Ctrl+O`, then `Ctrl+X`

### Why This Matters
When you run `uname -a`, you'll see:
```
Linux raspberrypi 6.12.60-console-v1+ #1 SMP ...
                          ^^^^^^^^^^^^
                      This is your suffix!
```

Identifies this as YOUR custom kernel (not the standard Pi kernel).

---

## 1.6 Compile Everything

### What You Did
```bash
make -j4 Image.gz modules dtbs
```

### What Each Component Produces

| Component | What It Is | Size |
|-----------|-----------|------|
| **Image.gz** | Compressed kernel binary | ~10-15 MB |
| **modules** | Loadable kernel drivers (.ko) | ~200+ files |
| **dtbs** | Device Tree Blobs (hardware description) | ~5 MB |

### Build Parameters

| Flag | Meaning |
|------|---------|
| `-j4` | Use 4 parallel threads (Pi 4 has 4 cores) |
| `Image.gz` | Output file: kernel image |
| `modules` | Build all optional modules |
| `dtbs` | Device tree binaries |

### Compilation Time
- **First build:** 30-60 minutes (depends on Pi model)
- **Incremental rebuild:** 5-15 minutes

### Monitor Progress
In another terminal:
```bash
watch -n 1 "ps aux | grep gcc"
```

Shows active compilation processes.

---

## 1.7 Install Compiled Modules

### What You Did
```bash
sudo make modules_install
```

### What It Does
Copies all compiled module files to:
```
/lib/modules/6.12.60-console-v1+/
├── kernel/
│   ├── drivers/
│   ├── fs/
│   ├── net/
│   └── ...
└── modules.dep, modules.alias, etc.
```

### Module Dependency Files
These are created automatically:
- `modules.dep` - lists module dependencies
- `modules.alias` - maps device IDs to modules
- `modules.builtin` - modules compiled into kernel

### Verification
```bash
ls /lib/modules/
# You should see: 6.12.60-console-v1+

ls /lib/modules/6.12.60-console-v1+/kernel/
# Should list: drivers/, fs/, net/, etc.
```

---

## Compiled Kernel Outputs

After successful compilation, check:

```bash
# Compressed kernel
ls -lh arch/arm64/boot/Image.gz

# Modules
find . -name "*.ko" | head

# Device trees
ls -lh arch/arm64/boot/dts/*.dtb

# Build log
tail -100 /var/log/build.log  # if logged
```

---

## Common Issues & Solutions

### Issue: `make: command not found`
**Solution:**
```bash
sudo apt install build-essential
```

### Issue: `libssl-dev not found`
**Solution:**
```bash
sudo apt install libssl-dev
```

### Issue: Compilation runs out of memory
**Solution:** Reduce parallel jobs
```bash
make -j2 Image.gz modules dtbs  # Use 2 threads instead of 4
```

### Issue: `bcm2711_defconfig not found`
**Solution:** Ensure you're in the linux directory
```bash
pwd
# Should show: /home/user/kernel_test/linux

# If not:
cd ~/kernel_test/linux
```

---

## Next Steps

Once compilation completes successfully:
1. ✓ You have `Image.gz` kernel binary
2. ✓ You have `/lib/modules/` with drivers
3. ✓ You have device trees

→ **Proceed to Phase 2: Install and boot your kernel**

---

## Files Created/Modified

| File | Purpose | Size |
|------|---------|------|
| `.config` | Kernel configuration | 220 KB |
| `arch/arm64/boot/Image.gz` | Compiled kernel | 10-15 MB |
| `/lib/modules/6.12.60-console-v1+/` | Installed modules | 200+ MB |
| `arch/arm64/boot/dts/*.dtb` | Device trees | 5 MB |

## Time Investment
- Environment setup: 10-15 minutes
- Kernel download: 5-10 minutes
- Kernel compilation: 30-60 minutes
- Module installation: 5 minutes

**Total Phase 1: ~1-1.5 hours**
