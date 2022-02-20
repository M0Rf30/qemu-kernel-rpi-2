#!/bin/sh
#
# Build latest stable ARM kernel for QEMU Raspberry Pi 2 Emulation
#
#######################################################
MODEL=rpi_2
TOOLCHAIN=arm-none-eabi
COMMIT=$(curl -s https://www.kernel.org | grep -A1 latest_link | tail -n1 | egrep -o '>[^<]+' | egrep -o '[^>]+')
export ARCH=arm
export CROSS_COMPILE=${TOOLCHAIN}-

curl -L -O -C - "https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-$COMMIT.tar.xz" || exit 1

# Kernel Compilation
if [ ! -d linux-$COMMIT ]; then
	tar xf linux-$COMMIT.tar.xz
fi

cd linux-$COMMIT

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

cat arch/arm/boot/dts/vexpress-v2p-ca15-tc1.dtb >> arch/arm/boot/zImage
cp arch/arm/boot/zImage $KERNEL_TARGET_FILE_NAME

