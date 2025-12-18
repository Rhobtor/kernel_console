# Kernel Console Build System Makefile

.PHONY: help setup build build-kernel build-rootfs build-initramfs clean install-pi release

.DEFAULT_GOAL := help

help:
	@echo "╔════════════════════════════════════════════════════════════╗"
	@echo "║     Kernel Console - Build System                          ║"
	@echo "║     Custom OS for Gaming Handhelds                         ║"
	@echo "╚════════════════════════════════════════════════════════════╝"
	@echo ""
	@echo "Available targets:"
	@echo ""
	@echo "  make setup          Configure environment & download sources"
	@echo "                      (2-3 GB download, ~10 minutes)"
	@echo ""
	@echo "  make build          Build everything (kernel + rootfs + initramfs)"
	@echo "                      (1-2 hours compilation)"
	@echo ""
	@echo "  make build-kernel   Build kernel only (~30-60 min)"
	@echo "  make build-rootfs   Build rootfs only (~5-10 min)"
	@echo "  make build-initramfs Build initramfs only (~2-5 min)"
	@echo ""
	@echo "  make install-pi     Show instructions for installing on Pi 4"
	@echo ""
	@echo "  make release        Create release package"
	@echo ""
	@echo "  make clean          Remove build artifacts"
	@echo ""
	@echo "Example workflow:"
	@echo "  1. make setup        # Download sources"
	@echo "  2. make build        # Compile everything (go get coffee!)"
	@echo "  3. make release      # Package everything"
	@echo ""

# Make scripts executable
setup: scripts/setup-environment.sh scripts/build-kernel.sh scripts/build-rootfs.sh scripts/build-initramfs.sh
	@chmod +x scripts/*.sh
	@./scripts/setup-environment.sh

# Full build
build: setup build-kernel build-rootfs build-initramfs
	@echo ""
	@echo "╔════════════════════════════════════════════════════════════╗"
	@echo "║  ✓ Build complete!                                         ║"
	@echo "╚════════════════════════════════════════════════════════════╝"
	@echo ""
	@echo "Output files ready in: releases/v0.1-pi4/"
	@echo ""
	@ls -lh releases/v0.1-pi4/ || true

# Individual build targets
build-kernel:
	@chmod +x scripts/build-kernel.sh
	@./scripts/build-kernel.sh

build-rootfs:
	@chmod +x scripts/build-rootfs.sh
	@./scripts/build-rootfs.sh

build-initramfs:
	@chmod +x scripts/build-initramfs.sh
	@./scripts/build-initramfs.sh

# Installation instructions
install-pi:
	@echo ""
	@echo "╔════════════════════════════════════════════════════════════╗"
	@echo "║  Kernel Console - Installation Instructions                ║"
	@echo "║  for Raspberry Pi 4                                        ║"
	@echo "╚════════════════════════════════════════════════════════════╝"
	@echo ""
	@echo "Prerequisites:"
	@echo "  ✓ Raspberry Pi 4 with SD card"
	@echo "  ✓ SD card with Raspberry Pi OS already installed"
	@echo "  ✓ USB keyboard + HDMI display (optional but recommended)"
	@echo ""
	@echo "Step 1: Copy kernel and initramfs to boot partition"
	@echo "────────────────────────────────────────────────────"
	@echo "On your Pi, run:"
	@echo ""
	@echo "  sudo cp releases/v0.1-pi4/kernel8-console-v1.img \\"
	@echo "          /boot/firmware/"
	@echo ""
	@echo "  sudo cp releases/v0.1-pi4/initramfs-console-v2.cpio.gz \\"
	@echo "          /boot/firmware/"
	@echo ""
	@echo "Step 2: Update firmware configuration"
	@echo "────────────────────────────────────"
	@echo "Edit /boot/firmware/config.txt:"
	@echo ""
	@echo "  sudo nano /boot/firmware/config.txt"
	@echo ""
	@echo "Add or modify these lines:"
	@echo ""
	@echo "  arm_64bit=1"
	@echo "  kernel=kernel8-console-v1.img"
	@echo "  initramfs initramfs-console-v2.cpio.gz followkernel"
	@echo "  #auto_initramfs=1"
	@echo ""
	@echo "Step 3: Update kernel command line"
	@echo "──────────────────────────────────"
	@echo "Edit /boot/firmware/cmdline.txt:"
	@echo ""
	@echo "  sudo nano /boot/firmware/cmdline.txt"
	@echo ""
	@echo "Replace the entire line with:"
	@echo ""
	@echo "  console=serial0,115200 console=tty1 root=/dev/ram0 rw rdinit=/init"
	@echo ""
	@echo "Step 4: Reboot"
	@echo "──────────────"
	@echo "  sudo reboot"
	@echo ""
	@echo "You should now boot into your custom OS!"
	@echo ""
	@echo "For more details, see: progress_logs/Phase-07-Boot-Config.md"
	@echo ""

# Create release package
release: build
	@mkdir -p releases/v0.1-pi4/boot-config
	@echo "Creating release package..."
	@cp scripts/config/* releases/v0.1-pi4/boot-config/ 2>/dev/null || true
	@tar czf releases/kernel-console-v0.1-pi4.tar.gz releases/v0.1-pi4/
	@echo ""
	@echo "✓ Release package created!"
	@echo ""
	@ls -lh releases/kernel-console-v0.1-pi4.tar.gz

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf build/
	@echo ""
	@echo "⚠  Note: releases/ directory not cleaned"
	@echo "   To remove final images, run: rm -rf releases/"
	@echo ""
	@echo "✓ Build artifacts cleaned"

# Clean everything (including sources)
distclean: clean
	@echo "Removing downloaded sources..."
	@rm -rf build/
	@echo "✓ All sources removed"
	@echo ""
	@echo "Note: run 'make setup' again to re-download"

.PHONY: clean distclean
