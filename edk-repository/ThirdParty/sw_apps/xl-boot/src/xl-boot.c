/*
 * (C) Copyright 2010-2012 Li-Pro.Net
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

#include "putstr.h"
#include "putnum.h"

#include "xbasic_types.h"
#include "xparameters.h"
#include "xlb_config.h"

#include "xl-blob.h"
#include "xl-xuart.h"
#include "xl-xtm.h"

#define XLB_SRC_VER		"0.50"

#ifndef XLB_BOOT_COUNTER
#define XLB_BOOT_COUNTER	10
#endif

#ifndef XLB_LOCBLOB_OFFSET
#define XLB_LOCBLOB_OFFSET	0
#endif

#if	defined(XLB_FLASH_START)
#define XLB_LOCBLOB_START	(XLB_FLASH_START + XLB_LOCBLOB_OFFSET)
#elif	defined(XLB_RAM_START)
#define XLB_LOCBLOB_START	(XLB_RAM_START)
#else
#error "missing XLB_FLASH_START or XLB_RAM_START to set XLB_LOCBLOB_START"
#endif

/*
 * Stubbed out version of newlib _exit hook and reduce code size
 * significantly. We can do this since we newer regist a newlib
 * exit handler with atexit().
 */
void __call_exitprocs(void)
{
}

#if (XLB_BOOT_COUNTER != 0)

static inline int boot_stop(void)
{
	int bc = XLB_BOOT_COUNTER;
	int bits, nibbles;

	putstr("Hit any key to stop autoboot: ");
	bits = putnum0(bc);

	xtm_init();
	while (bc) {
		nibbles = bits / 4;
		if (xtm_event()) {
			xtm_ack();
			while (nibbles--)
				putstr("\b");
			putnumxx(bits, --bc);
		}
		if (getkey()) {
			break;
		}
	}

	xtm_deinit();
	putstr("\r\n");
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
	struct locblob * const locblob = (struct locblob *)(XLB_LOCBLOB_START);
	locblobfp const locblob_start = (locblobfp)(locblob);

	xuart_init();

	/* bootloader greeting */
	putstr(XLB_GREETING_STR);

	/* search and run locator blob image */
	if (locblob_probe(locblob)) {
		if (!boot_stop()) {
			putstr("Start image locator...\r\n");
			locblob_start();
		}
	}

	putnum32((u32)locblob);
	putstr(": no image, use XMD for JTAG download.\r\n");
	return -1;
}
