#!/bin/bash
# build-kernel.sh
# Compile Linux kernel for Raspberry Pi 4

set -e

KERNEL_SOURCE="build/kernel/linux"
KERNEL_CONFIG="scripts/config/kernel.config"
OUTPUT_DIR="releases/v0.1-pi4"

echo "=========================================="
echo "Building Kernel"
echo "=========================================="
echo ""

# Check if kernel source exists
if [ ! -d "$KERNEL_SOURCE" ]; then
    echo "ERROR: Kernel source not found at $KERNEL_SOURCE"
    echo "Run 'make setup' first"
    exit 1
fi

# Check if config exists
if [ ! -f "$KERNEL_CONFIG" ]; then
    echo "ERROR: Kernel config not found at $KERNEL_CONFIG"
    echo "Generating default config from BCM2711 template..."
    cd "$KERNEL_SOURCE"
    export KERNEL=kernel8
    make bcm2711_defconfig
    cp .config ../../"$KERNEL_CONFIG"
    cd ../../
    echo "✓ Default config saved to $KERNEL_CONFIG"
    echo ""
fi

echo "Entering kernel source directory..."
cd "$KERNEL_SOURCE"

# Apply custom configuration
echo "Applying configuration..."
cp ../../"$KERNEL_CONFIG" .config

# Show what version we're building
echo "Kernel version:"
head -1 Makefile | grep -o "Linux [0-9.]*" || true
echo ""

# Build
echo "Compiling kernel (this will take 30-60 minutes)..."
echo "Progress: Compiling..."
export KERNEL=kernel8
make -j4 Image.gz modules dtbs 2>&1 | tail -20

echo ""
echo "✓ Kernel compilation complete"
echo ""

# Install modules
echo "Installing kernel modules..."
mkdir -p ../../build/rootfs/lib/modules
make INSTALL_MOD_PATH=../../build/rootfs modules_install > /dev/null 2>&1
echo "✓ Modules installed"
echo ""

# Copy outputs
echo "Copying build artifacts..."
mkdir -p ../../"$OUTPUT_DIR"
cp arch/arm64/boot/Image.gz ../../"$OUTPUT_DIR"/kernel8-console-v1.img
cp arch/arm64/boot/dts/*.dtb ../../"$OUTPUT_DIR"/
echo "✓ Artifacts copied to $OUTPUT_DIR"
echo ""

cd ../../

echo "=========================================="
echo "✓ Kernel build complete!"
echo "=========================================="
echo ""
echo "Output files:"
ls -lh "$OUTPUT_DIR"/*.img 2>/dev/null || true
ls -lh "$OUTPUT_DIR"/*.dtb 2>/dev/null | head -3 || true
echo ""
