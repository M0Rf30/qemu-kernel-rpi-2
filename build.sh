#!/bin/sh
#
# Build latest stable ARM kernel for QEMU Raspberry Pi 2 Emulation
#
#######################################################
set -x

git config --global --add safe.directory /workspace

MODEL=rpi_2
REMOTE=https://www.kernel.org
TOOLCHAIN=arm-none-eabi
COMMIT=$(curl -s "$REMOTE" | grep -A1 latest_link | tail -n1 | grep -E -o '>[^<]+' | grep -E -o '[^>]+')
VERSION=$(echo "$COMMIT" | cut -d'-' -f2 | cut -d'.' -f1)

export ARCH=arm
export CROSS_COMPILE=${TOOLCHAIN}-

curl -L -O -C - "https://cdn.kernel.org/pub/linux/kernel/v$VERSION.x/linux-$COMMIT.tar.xz" || exit 1

# Kernel Compilation
if [ ! -d "linux-$COMMIT" ]; then
	tar xf "linux-$COMMIT.tar.xz"
fi

cd "linux-$COMMIT" || exit 1

KERNEL_VERSION=$(make kernelversion)
KERNEL_TARGET_FILE_NAME=../qemu_kernel_$MODEL-$KERNEL_VERSION
echo "Building Qemu Raspberry Pi kernel qemu-kernel-$KERNEL_VERSION"

# Config
make CC="ccache ${TOOLCHAIN}-gcc" ARCH=arm CROSS_COMPILE=${TOOLCHAIN}- vexpress_defconfig
scripts/kconfig/merge_config.sh .config ../config

# Compiling
#make CC="ccache ${TOOLCHAIN}-gcc" ARCH=arm CROSS_COMPILE=${TOOLCHAIN}- xconfig
make -j 4 -k CC="ccache ${TOOLCHAIN}-gcc" ARCH=arm CROSS_COMPILE=${TOOLCHAIN}- zImage
make -j 4 -k CC="ccache ${TOOLCHAIN}-gcc" ARCH=arm CROSS_COMPILE=${TOOLCHAIN}- dtbs

cat arch/arm/boot/dts/vexpress-v2p-ca15-tc1.dtb >>arch/arm/boot/zImage
cp arch/arm/boot/zImage "$KERNEL_TARGET_FILE_NAME"
