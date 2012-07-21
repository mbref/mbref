/*
 * (C) Copyright 2010 Li-Pro.Net
 * Stephan Linz <linz@li-pro.net>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston,
 * MA 02111-1307 USA
 */

#include <stdio.h>

#include "xbasic_types.h"
#include "xparameters.h"
#include "xlb_config.h"

#include "xl-xuart.h"
#include "xl-xtm.h"

#define XLB_SRC_VER		"0.10"

#ifndef XLB_STDIO_BAUDRATE
#define XLB_STDIO_BAUDRATE	115200
#endif

#ifndef XLB_BOOT_COUNTER
#define XLB_BOOT_COUNTER	10
#endif

#ifndef XLB_LOCBLOB_OFFSET
#define XLB_LOCBLOB_OFFSET	0
#endif

#ifndef XLB_FLASH_START
#warning "missing XLB_FLASH_START, set to zero (HOT FIX, expand your BSP)"
#define XLB_FLASH_START		0
#endif

#define XLB_LOCBLOB_START	(XLB_FLASH_START + XLB_LOCBLOB_OFFSET)

/*
 * image key is the first fixed assmebly mnemonic of the image locator blob:
 *	brlid r5, locator	--> 0xb8b40008
 */
#define XLB_LOCBLOB_KEY		0xb8b40008

/* locator blob entry */
typedef void (*locblob)(void);

/*
 * Stubbed out version of newlib _exit hook and reduce code size
 * significantly.
 */
void __call_exitprocs(void)
{
}

#if (XLB_BOOT_COUNTER != 0)

static inline int boot_stop(void)
{
	int bc = XLB_BOOT_COUNTER;

	print("Hit any key to stop autoboot: ");
	putnum(bc);

	xtm_init();
	while (bc) {
		if (xtm_event()) {
			xtm_ack();
			print("\b\b\b\b\b\b\b\b");
			putnum(--bc);
		}
		if (getkey()) {
			break;
		}
	}

	xtm_deinit();
	print("\r\n");
	return bc;
}

#else

static inline int boot_stop(void)
{
	return 0;
}

#endif

#define XLB_GREETING_STR						\
	"\r\n"								\
	"XL-Boot " XLB_SRC_VER " (" XLB_MLD_VER ")\r\n"			\
	XLB_PROJECT_NAME "\r\n"						\
	"[" XLB_MB_FAMILY ":" XLB_MB_HW_VER ":" XLB_STDIO_HW		\
	":" __DATE__ " " __TIME__ "]\r\n"

int main(void)
{
	locblob locblob_start = (locblob)(XLB_LOCBLOB_START);

	xuart_init();

	/* bootloader greeting */
	print(XLB_GREETING_STR);

	/* search and run locator blob image */
	putnum(XLB_LOCBLOB_START);
	print(": ");
	if (*(u32 *)locblob_start == XLB_LOCBLOB_KEY) {
		print("start image locator...\r\n");
		if (!boot_stop()) {
			locblob_start();
		}
	}

	print("no image, use XMD for JTAG download.\r\n");
	return -1;
}
