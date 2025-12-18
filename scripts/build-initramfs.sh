#!/bin/bash
# build-initramfs.sh
# Package root filesystem as compressed CPIO initramfs

set -e

ROOTFS_DIR="build/rootfs"
OUTPUT_DIR="releases/v0.1-pi4"
OUTPUT_FILE="$OUTPUT_DIR/initramfs-console-v2.cpio.gz"

echo "=========================================="
echo "Building Initramfs"
echo "=========================================="
echo ""

# Check if rootfs exists
if [ ! -d "$ROOTFS_DIR" ]; then
    echo "ERROR: Rootfs not found at $ROOTFS_DIR"
    echo "Run 'make build-rootfs' first"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

echo "Creating CPIO archive..."
cd "$ROOTFS_DIR"

# Create and compress
sudo find . | sudo cpio -H newc -o 2>/dev/null | gzip > "../../$OUTPUT_FILE"

cd ../../

echo "✓ CPIO archive created and compressed"
echo ""

echo "=========================================="
echo "✓ Initramfs build complete!"
echo "=========================================="
echo ""
echo "Output file:"
ls -lh "$OUTPUT_FILE"
echo ""
echo "Compression ratio:"
UNCOMPRESSED=$(du -sb "$ROOTFS_DIR" | cut -f1)
COMPRESSED=$(stat -f%z "$OUTPUT_FILE" 2>/dev/null || stat -c%s "$OUTPUT_FILE")
RATIO=$((100 * $COMPRESSED / $UNCOMPRESSED))
echo "Uncompressed: $((UNCOMPRESSED/1024/1024)) MB"
echo "Compressed: $((COMPRESSED/1024/1024)) MB"
echo "Ratio: $RATIO%"
echo ""
