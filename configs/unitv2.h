/* SPDX-License-Identifier: GPL-2.0+ */
/*
 */

#ifndef __UNITV2_CONFIG_H
#define __UNITV2_CONFIG_H

#include "mstarv7.h"


#define CONFIG_EXTRA_ENV_SETTINGS	"bootargs=console=ttyS0,115200 root=/dev/mmcblk0p1 rootwait rw rootfstype=ext4 init=/sbin/init clk_ignore_unused usbcore.autosuspend=-1\0"\
					"bootcmd_rescue=ubi part UBI; ubi readvol ${loadaddr} rescue; bootm ${loadaddr}\0"\
					"bootcmd=ext4load mmc 0:1 ${loadaddr} /boot/gentoo-kernel.img;bootm ${loadaddr}\0"


#endif
