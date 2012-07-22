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
#include "xl-spiflash.h"

static inline void locblob_info(struct locblob * const locblob)
{
	putstr("LB: ");
	putstr(locblob->header.name);
	putstr(", ");
	putstr(locblob->header.date);
	putstr(", ");
	putnum0(locblob->header.size);
	putstr(" byte\r\n");
}

#ifdef XLB_SPI_FLASH_BASEADDR

static inline int locblob_load(struct locblob * const locblob)
{
	int ret;

	if(spi_flash_probe(1 /* verbose */) != 0)
		return 0;

	if(spi_flash_read_fast(XLB_LOCBLOB_OFFSET,
			sizeof(struct locblob), (void *)locblob))
		return 0;

	if (*(u32 *)locblob != XLB_LOCBLOB_KEY || !locblob->header.size)
		return 0;

	putstr("LB: copy payload data... ");
	ret = spi_flash_read_fast(XLB_LOCBLOB_OFFSET + sizeof(struct locblob),
			locblob->header.size, (void *)(locblob + 1));
	putstr("\r\n");

	if (ret)
		return 0;

	return 1;
}

#endif /* XLB_SPI_FLASH_BASEADDR */

int locblob_probe(struct locblob * const locblob)
{
#ifdef XLB_SPI_FLASH_BASEADDR
	if ((u32)locblob == XLB_RAM_START)
		if (!locblob_load(locblob))
			return 0;
#endif

	if (*(u32 *)locblob == XLB_LOCBLOB_KEY) {
		locblob_info(locblob);
		return 1;
	} else
		return 0;
}
