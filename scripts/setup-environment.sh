#!/bin/bash
# setup-environment.sh
# Configure build environment and download sources

set -e

echo "=========================================="
echo "Kernel Console Build Environment Setup"
echo "=========================================="
echo ""

# 1. Check dependencies
echo "[1/4] Checking required tools..."
REQUIRED_TOOLS=("git" "make" "gcc" "bc" "bison" "flex" "wget")

MISSING_TOOLS=()
for tool in "${REQUIRED_TOOLS[@]}"; do
    if ! command -v "$tool" &> /dev/null; then
        MISSING_TOOLS+=("$tool")
    fi
done

if [ ${#MISSING_TOOLS[@]} -gt 0 ]; then
    echo "ERROR: Missing required tools: ${MISSING_TOOLS[*]}"
    echo ""
    echo "Install with:"
    echo "  sudo apt update"
    echo "  sudo apt install -y git make gcc bc bison flex wget libssl-dev libc6-dev libncurses5-dev"
    exit 1
fi
echo "✓ All required tools found"
echo ""

# 2. Create directories
echo "[2/4] Creating build directories..."
mkdir -p build/{kernel,busybox}
mkdir -p releases/v0.1-pi4
echo "✓ Directories created"
echo ""

# 3. Download kernel source if needed
echo "[3/4] Checking kernel source..."
if [ ! -d "build/kernel/linux" ]; then
    echo "Downloading Raspberry Pi Linux kernel (this may take a few minutes)..."
    cd build/kernel
    git clone --depth=1 https://github.com/raspberrypi/linux
    cd ../../
    echo "✓ Kernel source downloaded"
else
    echo "✓ Kernel source already present"
fi
echo ""

# 4. Download BusyBox if needed
echo "[4/4] Checking BusyBox source..."
if [ ! -f "build/busybox/busybox-1.36.1.tar.bz2" ]; then
    echo "Downloading BusyBox (this may take a moment)..."
    cd build/busybox
    wget -q https://busybox.net/downloads/busybox-1.36.1.tar.bz2
    tar xf busybox-1.36.1.tar.bz2
    cd ../../
    echo "✓ BusyBox source downloaded and extracted"
else
    echo "✓ BusyBox source already present"
fi
echo ""

echo "=========================================="
echo "✓ Environment setup complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. Review scripts/config/ files"
echo "  2. Run: make build"
echo "  3. Wait 1-2 hours for compilation..."
echo ""
