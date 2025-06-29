#!/bin/sh

# busybox from apt seems not to have math-enabled awk, so we should compile it
# manually

set -e

echo "Setting up BusyBox with math-enabled AWK..."

# Check if we already have a working busybox with math-enabled awk
if command -v busybox >/dev/null 2>&1; then
    if busybox awk 'BEGIN { print 2 ** 32 }' >/dev/null 2>&1; then
        echo "BusyBox with working AWK already available"
        echo "$(which busybox) ash"
        exit 0
    fi
fi

# Install build dependencies
echo "Installing build dependencies..."
sudo apt-get update >/dev/null 2>&1
sudo apt-get install -y build-essential wget make gcc >/dev/null 2>&1

# Create temporary build directory
BUILD_DIR="/tmp/busybox-build"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Download BusyBox source
BUSYBOX_VERSION="1.36.1"
BUSYBOX_URL="https://busybox.net/downloads/busybox-${BUSYBOX_VERSION}.tar.bz2"

echo "Downloading BusyBox ${BUSYBOX_VERSION}..."
wget -q "$BUSYBOX_URL" -O busybox.tar.bz2

echo "Extracting BusyBox..."
tar -xjf busybox.tar.bz2
cd "busybox-${BUSYBOX_VERSION}"

# Configure BusyBox with default config and enable math support
echo "Configuring BusyBox..."
make defconfig >/dev/null 2>&1

# Enable math support in AWK, disable tc
sed -i 's/# CONFIG_FEATURE_AWK_LIBM is not set/CONFIG_FEATURE_AWK_LIBM=y/' .config
sed -i 's/CONFIG_TC=y/# CONFIG_TC is not set/' .config

# Build BusyBox
echo "Building BusyBox..."
make -j >/dev/null 2>&1

echo "$(pwd)/busybox ash"
