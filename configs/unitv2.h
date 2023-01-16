/* SPDX-License-Identifier: GPL-2.0+ */
/*
 */

#ifndef __UNITV2_CONFIG_H
#define __UNITV2_CONFIG_H

#include "mstarv7.h"


#define CONFIG_EXTRA_ENV_SETTINGS	"bootargs=console=ttyS0,115200 root=/dev/mmcblk0p1 rootwait rw rootfstype=ext4 init=/sbin/openrc-init\0"\
					"bootcmd_rescue=ubi part UBI; ubi readvol ${loadaddr} rescue; bootm ${loadaddr}\0"\
					"bootcmd=ext4load mmc 0:1 0x20008000 /boot/zImage;ext4load mmc 0:1 0x20208000 /boot/dts/mstar-infinity2m-ssd202d-unitv2.dtb;bootz 0x20008000 - 0x20208000\0"

#endif
