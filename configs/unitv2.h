/* SPDX-License-Identifier: GPL-2.0+ */
/*
 */

#ifndef __UNITV2_CONFIG_H
#define __UNITV2_CONFIG_H

#include "mstarv7.h"


#define CONFIG_EXTRA_ENV_SETTINGS	"console=ttyS0,115200 ubi.mtd=UBI,2048 root=mmcblk0p1:ext4 rw init=/sbin/openrc-init rootwait=1 LX_MEM=0x7f00000 mma_heap=mma_heap_name0,miu=0,sz=0x380000 mma_memblock_remove=1 highres=off mmap_reserved=fb,miu=0,sz=0x300000,max_start_off=0x7C00000,max_end_off=0x7F00000 mtdparts=nand0:384k@0x140000(IPL0),384k(IPL1),384k(IPL_CUST0),384k(DUMMY0),768k(DUMMY2),768k(DUMMY3),384k(DUMMY4),128k(DUMMY5),5m(DUMMY6),5m(DUMMY7),-(UBI)\0 "\
					"bootcmd_rescue=ubi part UBI; ubi readvol ${loadaddr} rescue; bootm ${loadaddr}\0"\
					"bootcmd=ext4load mmc 0:1 ${loadaddr} /boot/gentoo-kernel.img;bootm ${loadaddr}\0"

#endif
