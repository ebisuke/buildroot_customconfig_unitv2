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
mkdir -p $OUTPUT_PATH
GENTOO_STAGE3_URL="https://bouncer.gentoo.org/fetch/root/all/releases/arm/autobuilds/20230111T210213Z/stage3-armv7a_hardfp-systemd-20230111T210213Z.tar.xz"
LINUX_KERNEL_GIT_URL="https://github.com/linux-chenxing/linux.git"
LINUX_KERNEL_GIT_COMMIT="27736d409431814823c4a20a1190bdacb2c42191"
LINUX_VERSION="5.18.0-rc7+"
BUILDROOT_UNITV2_URL="https://github.com/fifteenhex/buildroot_unitv2.git"
BUILDROOT_UNITV2_COMMIT="34b6d9d863d496711436a30929e8d25c621c2688"
RTL8188FU_GIT_URL="https://github.com/kikuingithub/rtl8188fu_linux.git"
RTL8188FU_GIT_COMMIT="dfe0a5090a1ec593ba558b589f092cce29e6256f"
RTL8188FU_FILENAME="rtl8188fu.ko"

read -p "Enter the path of the microSD:" SD_PATH 
#check sd path
if [ ! -d "$SD_PATH" ]; then
	echo "Error: $SD_PATH is not a directory"
	echo "Disable SD Feature"

fi
echo "Start building Gentoo Linux Environment For UnitV2 Script"

echo "Install prerequisite packages"
sudo apt-get install -y git gcc-arm-linux-gnueabihf build-essential flex bison libncurses5-dev fakeroot xz-utils bc u-boot-tools  libssl-dev libnl-genl-3-dev libreadline-dev libncurses5-dev libdbus-1-dev
echo "Building phase"

echo "Downloading Linux Kernel"
git clone --recursive $LINUX_KERNEL_GIT_URL $LINUX_PATH
cd $LINUX_PATH
git checkout $LINUX_KERNEL_GIT_COMMIT
cd $BASE_PATH
echo "Downloading Buildroot UnitV2"
git clone --recursive  $BUILDROOT_UNITV2_URL $BUILDROOT_UNITV2_PATH
cd $BUILDROOT_UNITV2_PATH
git checkout $BUILDROOT_UNITV2_COMMIT
cd $BASE_PATH
echo "Copying Config Files for each project"
cp -f $INITIAL_PATH/configs/linux.config $LINUX_PATH/.config
cp -f $INITIAL_PATH/configs/buildroot.config $BUILDROOT_PATH/.config
cp -f $INITIAL_PATH/configs/uboot.config $BUILDROOT_PATH/uboot.config

echo "Building Linux Kernel"
cd $LINUX_PATH
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf-

echo "Building Buildroot"
cd $BUILDROOT_UNITV2_PATH
cp -f $INITIAL_PATH/configs/Makefile.replace $BUILDROOT_UNITV2_PATH/Makefile
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf-



echo "Rebuilding U-Boot"
cd $BUILDROOT_PATH/output/build/uboot-mstar_rebase_mainline_20220409
cp -f $INITIAL_PATH/configs/uboot.config .config
cp -f $INITIAL_PATH/configs/env.txt env.txt
cp -f $INITIAL_PATH/configs/unitv2.h include/configs/unitv2.h
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- clean
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf-
cp -f u-boot.img $TMP_PATH/unitv2-u-boot.img

echo "Creating RTL8188FU driver"
cd $BASE_PATH
git clone --recursive $RTL8188FU_GIT_URL $TMP_PATH/rtl8188fu_linux
cd $TMP_PATH/rtl8188fu_linux
git checkout $RTL8188FU_GIT_COMMIT
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- clean
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- KSRC=$LINUX_PATH M=$(pwd) modules

echo "Creating boot image"
cd $TMP_PATH
cp -f $LINUX_PATH/arch/arm/boot/zImage .
cp -f $INITIAL_PATH/configs/mstar-infinity2m-ssd202d-unitv2_mod.dtb .
cp -f $INITIAL_PATH/configs/kernel.its .

mkimage -f ./kernel.its ./gentoo-kernel.img
cp -f  $INITIAL_PATH/configs/gentoo-kernel.img $TMP_PATH/
echo "Creating Flashing files"
cd $TMP_PATH

#cp -f $BUILDROOT_UNITV2_PATH/outputs/unitv2-u-boot.img .
cp -f $INITIAL_PATH/env.img .
rm -f $OUTPUT_PATH/uImage
ubinize -o $OUTPUT_PATH/uImage -p 128KiB -m 2048 -s 2048 $INITIAL_PATH/configs/ubi.cfg

echo "Copying ipl file"
cd $OUTPUT_PATH
cp -f  $BUILDROOT_UNITV2_PATH/outputs/unitv2-ipl .

if [ -d "$SD_PATH" ]; then

  echo "Gentoo phase"
  cd $SD_PATH

  echo "Downloading Gentoo Stage3"
  sudo curl -L $GENTOO_STAGE3_URL -o stage3.tar.xz
  sudo tar xpvf stage3.tar.xz --xattrs-include='*.*' --numeric-owner
  sudo rm -f stage3.tar.xz

  echo "Replace /etc/fstab"
  sudo cp -f $INITIAL_PATH/fs/etc/fstab etc/fstab
  sudo cp -f $INITIAL_PATH/fs/etc/shadow etc/shadow

  echo "git clone supplimental drivers source"

  sudo mkdir -p $SD_PATH/usr/src/
  cd $SD_PATH/usr/src
  sudo git clone --recursive $RTL8188FU_GIT_URL $SD_PATH/usr/src/rtl8188fu_linux
  cd $SD_PATH/usr/src/rtl8188fu_linux
  sudo git checkout $RTL8188FU_GIT_COMMIT
  cd $SD_PATH

  echo "Copy kernel boot files"
  sudo cp -rf $LINUX_PATH/arch/arm/boot/. boot/
  echo "Copy RTL8188FU driver"
  cd $TMP_PATH/rtl8188fu_linux
  sudo mkdir -p $SD_PATH/lib/modules/$LINUX_VERSION/
  sudo depmod -a -b $SD_PATH $LINUX_VERSION

  sudo mkdir -p $SD_PATH/lib/modules/$LINUX_VERSION/extra/
  sudo cp -f $TMP_PATH/rtl8188fu_linux/rtl8188fu.ko $SD_PATH/lib/modules/$LINUX_VERSION/extra/
  echo "For RTL8188FU config"
  cd $BUILDROOT_UNITV2_PATH/br2unitv2/board/m5stack/unitv2/overlay/etc/modprobe.d
  sudo mkdir -p $SD_PATH/etc/modprobe.d
  sudo cp -f rtl8188fu.conf $SD_PATH/etc/modprobe.d/
  cd $SD_PATH

  echo "Copy kernel header files"
  sudo mkdir -p $SD_PATH/lib/modules/$LINUX_VERSION/kernel
  cd $LINUX_PATH
  sudo make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- INSTALL_HDR_PATH=$SD_PATH/lib/modules/$LINUX_VERSION/kernel headers_install
  echo "Copy kernel source files"
  sudo mkdir -p $SD_PATH/lib/modules/$LINUX_VERSION/build
  sudo cp -rf $LINUX_PATH/. $SD_PATH/lib/modules/$LINUX_VERSION/build

  echo "Copy Extra files"
  sudo mkdir -p $SD_PATH/lib/modules/$LINUX_VERSION/extra
  sudo cp -f $TMP_PATH/rtl8188fu_linux/rtl8188fu.ko $SD_PATH/lib/modules/$LINUX_VERSION/extra/

  cd $SD_PATH
  echo "Copy kernel image"
  sudo cp -f $TMP_PATH/gentoo-kernel.img boot/
  echo "Copy wifi firmware and some stuffs"
  sudo cp -rf $BUILDROOT_PATH/output/target/lib/firmware $SD_PATH/lib/firmware



  echo "Syncing"
  cd $INITIAL_PATH
  sync
fi

echo "Complete. Please write the image to the UnitV2's NAND flash via I2C."

