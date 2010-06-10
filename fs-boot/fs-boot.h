/*! @file fs-boot.h
 * FILE:   $Id:$
 *
 * DESCRIPTION:
 *     Header file for the PetaLogix first-stage bootloader FS-BOOT.
 *
 * AUTHOR:
 *     Benny Chen, PetaLogix <Benny.Chen@petalogix.com>
 *
 * MODIFICATION:
 *     Michal Simek, PetaLogix 2008 <michal.simek@petalogix.com>
 *      Add uart16550 support
 *
 * LICENSING:
 *     Copyright (c) 2006 - 2008 PetaLogix. All rights reserved.
 *
 *  No part of this program may be reproduced or adapted in  any form  or by
 *  any means, electronic or mechanical, without  permission from PetaLogix.
 *  This program is  confidential and  may not be  disclosed, decompiled  or
 *  reverse engineered without permission in writing from PetaLogix.
 *
 */
#include "auto-config.h"

#ifdef CONFIG_UARTLITE
#include "xuartlite_l.h"
#elif CONFIG_UART16550
#include "xuartns550_l.h"
#endif

#if DEBUG
#include <stdio.h>
#endif

/* FS-BOOT Configuration */
#define CONFIG_FS_BOOT_DELAY	3

/*! Debug flag to turn on debug messages */
#define DEBUG 0

/* Disable SREC FS-BOOT functionality */
// #define CONFIG_NO_SREC

/* enable SREC functionality for system without flash */
#ifndef CONFIG_XILINX_FLASH_START
#define CONFIG_NO_FLASH
#endif

#ifdef CONFIG_NO_FLASH
#undef CONFIG_NO_SREC
#undef CONFIG_FS_KERNEL
#endif

/* Memory access type */
#define mtype   volatile unsigned long
#define REG32_READ(addr,offset)       (*(mtype *)(addr + offset))
#define REG32_WRITE(addr,data)        (*(mtype *)(addr) = data)

#ifndef CONFIG_NO_FLASH
/*! FLASH size */
#define FLASH_SIZE      CONFIG_XILINX_FLASH_SIZE
#endif

/*! SDRAM size */
#define RAM_SIZE        CONFIG_XILINX_ERAM_SIZE

/*! @defgroup mmap1 Memory Map Addressing Definitions
 * MEMORY MAP PERIPHERAL ADDRESS DEFINITIONS
 * @{ 
 */
/*! Start address of UART device. */
#define UART_BASEADDR CONFIG_STDINOUT_BASEADDR

#ifndef CONFIG_NO_FLASH
/*! Start address of FLASH device */
#define FLASH_BASE      CONFIG_XILINX_FLASH_START
/*! End address of FLASH device */
#define FLASH_END       (FLASH_BASE + FLASH_SIZE)
#endif

/*! Start address of SDRAM device */
#define RAM_START       CONFIG_XILINX_ERAM_START
/*! End address of SDRAM device */
#define RAM_END         (RAM_START + RAM_SIZE)

/*! @} */

#if defined(CONFIG_FS_KERNEL)
/*! @defgroup bl1 2nd Stage Bootloader Definitions.
 * 2ND STAGE BOOTLOADER MEMORY DEFINITIONS
 * @{
 */

#define MTD_ML401_8MB_KERN_OFFSET	0x00400000
#define MTD_ML401_8MB_KERN_MAXSIZE	0x00300000
#define CONFIG_FS_KERN_OFFSET		MTD_ML401_8MB_KERN_OFFSET
#define CONFIG_FS_KERN_START		(FLASH_BASE + CONFIG_FS_KERN_OFFSET)
#define CONFIG_FS_KERN_MAXSIZE		MTD_ML401_8MB_KERN_MAXSIZE
#endif

/* -FIXME
 * This is taken from the MTD Mapping for ML401 board
 * so we remember to synchronise it with the MTD mappings
 */
/*! Offset from FLASH base to the location of bootloader partition */
/* Allow posibility it's defined on the gcc command line with -D, so
   hardware projects can place u-boot at different locations in flash */
#ifndef CONFIG_FS_BOOT_OFFSET
#define CONFIG_FS_BOOT_OFFSET   0
#endif
/*! Start address in FLASH of the 2nd Stage bootloader */
#define CONFIG_FS_BOOT_START	FLASH_BASE + CONFIG_FS_BOOT_OFFSET
/*! Maximum size of the 2nd Stage bootloader partition in FLASH */
#define CONFIG_FS_BOOT_MAXSIZE  (256 * 1024)
/*! End address in FLASH of the 2nd Stage bootloader */
#define CONFIG_FS_BOOT_END	CONFIG_FS_BOOT_START + CONFIG_FS_BOOT_MAXSIZE

/*
 * MISC DEFINITIONS
 */
/*! Maximium length of each SREC line */
#define SREC_MAX_RECLEN         128
/*! Maximium length of binary data per SREC line */
#define SREC_MAX_BINLEN         SREC_MAX_RECLEN

/*
 * TIMER / COUNTER MACROS
 */
#define TIMER_BASE	CONFIG_XILINX_TIMER_0_BASEADDR
#define O_TIMER_TCSR0	0x00
#define O_TIMER_TLR0	0x04
#define O_TIMER_TCR0	0x08
#define CFG_HZ          CONFIG_XILINX_CPU_CLOCK_FREQ


/*
 * Initialised the timer to default value
 * The default settings for the timers are:
 *   - Interrupt generation disabled
 *   - Count up mode
 *   - Compare mode
 *   - Enable Auto Reload
 *   - External compare output disabled
 *   - External capture input disabled
 *   - Pulse width modulation disabled
 *   - Timer disabled, waits for Start function to be called
 */
#define TIMER_TCSR0_INIT	0x0490		/* Timer Control Reg Bits */
#define TIMER_RESET_VALUE   0x0     	/* Reset load value - count up timer*/


/*
 * GLOBAL FUNCTION PROTOTYPES
 */
void fsprint(char *s);
void load_image(unsigned long src_addr, unsigned int load_addr, int size);
