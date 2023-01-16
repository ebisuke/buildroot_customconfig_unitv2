#!/bin/bash
echo "Building Gentoo Linux Environment For UnitV2 Script"

MAKE_FLAGS="-j7"
INITIAL_PATH=$(pwd)
BASE_PATH=$(pwd)/../
LINUX_PATH=$BASE_PATH/linux
BUILDROOT_UNITV2_PATH=$BASE_PATH/buildroot_unitv2
BUILDROOT_PATH=$BUILDROOT_UNITV2_PATH/buildroot
UBOOT_PATH=$BUILDROOT_PATH/
OUTPUT_PATH=$BASE_PATH/output
TMP_PATH=$BASE_PATH/tmp

cd $BASE_PATH
# make tmp path
mkdir -p $TMP_PATH

GENTOO_STAGE3_URL="https://bouncer.gentoo.org/fetch/root/all/releases/arm/autobuilds/20230111T210213Z/stage3-armv7a_hardfp-openrc-20230111T210213Z.tar.xz"
LINUX_KERNEL_GIT_URL="https://github.com/linux-chenxing/linux.git"
LINUX_KERNEL_GIT_COMMIT="5b16308ae546df24c218e3785942e741f04ae326"
BUILDROOT_UNITV2_URL="https://github.com/fifteenhex/buildroot_unitv2.git"
BUILDROOT_UNITV2_COMMIT="34b6d9d863d496711436a30929e8d25c621c2688"

read -p "Enter the path of the microSD:" SD_PATH 
#check sd path
if [ ! -d "$SD_PATH" ]; then
	echo "Error: $SD_PATH is not a directory"
	exit 1
fi
echo "Start building Gentoo Linux Environment For UnitV2 Script"

echo "Building phase"

echo "Downloading Linux Kernel"
git clone --recursive $LINUX_KERNEL_GIT_URL $LINUX_PATH
cd $LINUX_PATH
git checkout $LINUX_KERNEL_GIT_COMMIT
cd $BASE_PATH
echo "Downloading Buildroot UnitV2"
git clone --recursive -b $BUILDROOT_UNITV2_BRANCH $BUILDROOT_UNITV2_URL $BUILDROOT_UNITV2_PATH
cd $BUILDROOT_UNITV2_PATH
git checkout $BUILDROOT_UNITV2_COMMIT
cd $BASE_PATH
echo "Copying Config Files for each project"
cp -f $INITIAL_PATH/configs/linux.config $LINUX_PATH/.config
cp -f $INITIAL_PATH/configs/buildroot.config $BUILDROOT_PATH/.config
cp -f $INITIAL_PATH/configs/uboot.config $BUILDROOT_PATH/uboot.config

echo "Building Linux Kernel"
cd $LINUX_PATH
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- $MAKE_FLAGS

echo "Building Buildroot"
cd $BUILDROOT_UNITV2_PATH
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- $MAKE_FLAGS

echo "Creating output directory"
mkdir -p $OUTPUT_PATH

echo "Creating boot image"
cd $TMP_PATH
cp -f $LINUX_PATH/arch/arm/boot/zImage .
cp -f $LINUX_PATH/arch/arm/boot/dts/mstar-infinity2m-ssd202d-unitv2.dtb .
cp -f $INITIAL_PATH/configs/kernel.its .

mkimage -f ./kernel.its ./gentoo-kernel.img
cp -f  $INITIAL_PATH/configs/kernel.its $TMP_PATH/
echo "Creaintg Flasing files"
cd $TMP_PATH

cp -f $BUILDROOT_UNITV2_PATH/outputs/unitv2-u-boot.img .
cp -f $INITIAL_PATH/env.img .
ubinize -o $OUTPUT_PATH/uImage -p 128KiB -m 2048 -s 2048 $INITIAL_PATH/configs/ubi.cfg

echo "Copying ipl file"
cd $OUTPUT_PATH
cp -f  $BUILDROOT_UNITV2_PATH/outputs/unitv2-ipl .

echo "Gentoo phase"
cd $SD_PATH

echo "Downloading Gentoo Stage3"
curl -L $GENTOO_STAGE3_URL -o $SD_PATH/stage3.tar.xz
tar xpvf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner
rm -f stage3-*.tar.xz

echo "Replace /etc/fstab"
cp -f $INITIAL_PATH/fs/etc/fstab etc/fstab

echo "Copy kernel boot files"
cp -rf $LINUX_PATH/arch/arm/boot/* boot/

echo "Copy kernel image"
cp -f $TMP_PATH/gentoo-kernel.img boot/

echo "Unmount SDCard"
cd $INITIAL_PATH
sync
sudo umount $SD_PATH

echo "Complete. Please write the image to the UnitV2's NAND flash via I2C."

