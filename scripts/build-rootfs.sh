#!/bin/bash
# build-rootfs.sh
# Build root filesystem with BusyBox

set -e

BUSYBOX_DIR="build/busybox/busybox-1.36.1"
ROOTFS_DIR="build/rootfs"
BUSYBOX_CONFIG="scripts/config/busybox.config"

echo "=========================================="
echo "Building Root Filesystem"
echo "=========================================="
echo ""

# Check if BusyBox source exists
if [ ! -d "$BUSYBOX_DIR" ]; then
    echo "ERROR: BusyBox source not found at $BUSYBOX_DIR"
    echo "Run 'make setup' first"
    exit 1
fi

# Configure BusyBox
echo "[1/5] Configuring BusyBox..."
cd "$BUSYBOX_DIR"

if [ ! -f "../../../$BUSYBOX_CONFIG" ]; then
    echo "Generating default BusyBox config..."
    make defconfig > /dev/null
    cp .config ../../../"$BUSYBOX_CONFIG"
    echo "✓ Default config saved to $BUSYBOX_CONFIG"
else
    cp ../../../"$BUSYBOX_CONFIG" .config
    echo "✓ Config loaded"
fi
echo ""

# Build BusyBox
echo "[2/5] Compiling BusyBox (this takes 5-10 minutes)..."
make -j4 > /dev/null 2>&1
echo "✓ BusyBox compiled"
echo ""

# Install BusyBox
echo "[3/5] Installing BusyBox..."
mkdir -p ../../../"$ROOTFS_DIR"
make CONFIG_PREFIX=../../../"$ROOTFS_DIR" install > /dev/null 2>&1
echo "✓ BusyBox installed"
echo ""

cd ../../../

# Create directory structure
echo "[4/5] Creating filesystem structure..."
mkdir -p "$ROOTFS_DIR"/{dev,proc,sys,tmp,mnt,etc,home,root,var,usr/local}
chmod 1777 "$ROOTFS_DIR"/tmp
echo "✓ Directories created"
echo ""

# Create device nodes (requires sudo)
echo "[5/5] Creating device nodes..."
sudo mknod "$ROOTFS_DIR"/dev/console c 5 1 2>/dev/null || echo "console may already exist"
sudo mknod "$ROOTFS_DIR"/dev/null c 1 3 2>/dev/null || echo "null may already exist"
sudo chmod 600 "$ROOTFS_DIR"/dev/console
sudo chmod 666 "$ROOTFS_DIR"/dev/null
echo "✓ Device nodes created"
echo ""

# Copy init script
echo "Copying init script..."
sudo cp src/rootfs/init "$ROOTFS_DIR"/
sudo chmod +x "$ROOTFS_DIR"/init
echo "✓ Init script installed"
echo ""

echo "=========================================="
echo "✓ Root filesystem build complete!"
echo "=========================================="
echo ""
echo "Rootfs size:"
du -sh "$ROOTFS_DIR"
echo ""
