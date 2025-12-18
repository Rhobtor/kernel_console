# How to Build Kernel Console from GitHub

This document explains how to take this repository and build a complete, bootable OS for your Raspberry Pi 4.

## Overview

The entire build process is **fully automated** using a Makefile and shell scripts. You don't need to manually compile the kernel or BusyBox - just run commands!

## Quick Start (5 steps)

```bash
# 1. Clone this repository
git clone https://github.com/Rhobtor/kernel_console
cd kernel_console

# 2. View available build targets
make help

# 3. Download kernel and BusyBox sources (takes ~10 min, ~2-3 GB)
make setup

# 4. Build everything (takes 1-2 hours, grab ☕)
make build

# 5. See installation instructions
make install-pi
```

That's it! You'll have a complete OS ready to deploy to your Pi.

## What Gets Built

After `make build`, you'll have in `releases/v0.1-pi4/`:

- **kernel8-console-v1.img** (10-15 MB) - Your custom Linux kernel
- **initramfs-console-v2.cpio.gz** (2-3 MB) - Your complete OS in RAM
- **Device tree files** (.dtb) - Hardware description
- **boot-config/** - Configuration files for boot

## Key Directories

- **scripts/** - Build automation scripts
  - `setup-environment.sh` - Download sources
  - `build-kernel.sh` - Compile kernel
  - `build-rootfs.sh` - Create filesystem
  - `build-initramfs.sh` - Package into bootable image
  - `config/` - Configuration files

- **src/** - Source code
  - `rootfs/init` - Startup script for your OS

- **progress_logs/** - Detailed documentation
  - 8 complete phases explaining everything
  - Perfect for understanding how it works

- **releases/** - Final bootable images (generated after build)

## How to Use the Built OS

Once you have the compiled files, see **[progress_logs/Phase-07-Boot-Config.md](./progress_logs/Phase-07-Boot-Config.md)** for how to:

1. Copy files to Raspberry Pi 4 SD card
2. Update firmware configuration
3. Boot into your custom OS

## Important Notes

### What's in Git
- ✅ Scripts (shell scripts, Makefile)
- ✅ Configuration files (.config templates)
- ✅ Startup scripts (init)
- ✅ Documentation (everything in progress_logs/)

### What's NOT in Git (too large)
- ❌ Linux kernel source (downloaded by `make setup`)
- ❌ BusyBox source (downloaded by `make setup`)
- ❌ Compiled binaries (.img, .cpio.gz)
- ❌ Build artifacts

This keeps the repo small (~5 MB) while allowing complete reproducibility.

## Customization

Want to customize the build?

### Modify Kernel
```bash
# Edit script to use menuconfig instead:
# Inside scripts/build-kernel.sh, add:
# make menuconfig

# Or directly edit:
scripts/config/kernel.config
```

### Modify BusyBox Tools
```bash
# Edit script to use menuconfig:
# Inside scripts/build-rootfs.sh, add:
# make menuconfig

# Or directly edit:
scripts/config/busybox.config
```

### Add Your Own Files
Add files to `src/rootfs/` and they'll be included automatically in the next build.

## Build Times

- **make setup** - 10 minutes (depends on internet)
- **make build-kernel** - 30-60 minutes (depends on CPU cores)
- **make build-rootfs** - 5-10 minutes
- **make build-initramfs** - 2-5 minutes
- **Total build time** - 1-2 hours

## Troubleshooting

**Missing tools?**
```bash
# Install required build tools
sudo apt update
sudo apt install -y git make gcc bc bison flex wget libssl-dev \
                     libc6-dev libncurses5-dev
```

**Out of disk space?**
Make sure you have ~5 GB free in your home directory.

**Build fails?**
Check the detailed phase documentation in `progress_logs/` for solutions to common issues.

## Learning More

- **PROJECT_VISION.md** - Complete project roadmap (v0-v3)
- **BUILD_SYSTEM.md** - Detailed technical architecture
- **progress_logs/** - 8 detailed phases of development

Each phase explains:
- What you're doing
- Why you're doing it
- Common problems and solutions

## Next Steps After Building

Once you have a bootable image:

1. Install on Raspberry Pi 4
2. Boot your custom OS
3. Next phases: input system, graphics, game launcher

See `progress_logs/` for what comes next!

## Contributing

Found a bug or want to improve the build system?

1. Fork the repository
2. Make your changes
3. Test with `make clean && make build`
4. Submit a pull request

---

**Happy building!** 🚀

Questions? Check the documentation or open an issue on GitHub.
