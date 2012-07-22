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
 *
 * derived from U-Boot drivers/mtd/spi/spi_flash.c:
 *    Copyright (C) 2008 Atmel Corporation
 *    Copyright (C) 2010 Reinhard Meyer, EMK Elektronik
 *
 *    Licensed under the GPL-2 or later.
 */

#include "putstr.h"
#include "putnum.h"

#include "xbasic_types.h"
#include "xparameters.h"
#include "xlb_config.h"

#include "xl-xspi.h"

#if 0
#define debug(STR)	putstr(STR)
#else
#define debug(STR)
#endif

#define CMD_READ_ID		0x9f
#define CMD_READ_ARRAY_FAST	0x0b

#ifdef XLB_SPI_FLASH_BASEADDR

static int xfr_defopflags = 0;

static int spi_flash_read_write(const u8 *cmd, u32 cmd_len,
		const u8 *data_out, u8 *data_in, u32 data_len)
{
	u32 opflags = XSPI_OPFLAG_XFR_BEGIN | xfr_defopflags;
	int ret;
                
	if (data_len == 0)
		opflags |= XSPI_OPFLAG_XFR_END;
                
	ret = xspi_xfr(cmd_len * 8, cmd, NULL, opflags);
	if (ret) {
		debug("SF: Failed to send command\n");
	} else if (data_len != 0) {
		ret = xspi_xfr(data_len * 8, data_out, data_in,
				XSPI_OPFLAG_XFR_END | xfr_defopflags);
		if (ret)
			debug("SF: Failed to transfer data\n");
	}

	return ret;
}

static inline int spi_flash_cmd_read(const u8 *cmd, u32 cmd_len,
					void *data, u32 data_len)
{
	return spi_flash_read_write(cmd, cmd_len, NULL, data, data_len);
}
 
static inline int spi_flash_cmd(u8 cmd, void *response, u32 len)
{
	return spi_flash_cmd_read(&cmd, 1, response, len);
}

static inline void spi_flash_addr(u32 addr, u8 *cmd)
{
	/* cmd[0] is actual command */
	cmd[1] = addr >> 16;
	cmd[2] = addr >> 8;
	cmd[3] = addr >> 0;
}

int spi_flash_probe(int verbose)
{
	int ret;
	u8 idcode[5];

	ret = xspi_init(XSPI_OPFLAG_CPHA | XSPI_OPFLAG_CPOL);
	if (ret)
		return ret;

	ret = spi_flash_cmd(CMD_READ_ID, idcode, sizeof(idcode));
	if (ret)
		return ret;

	if (verbose) {
		putstr("SF: ");
		putnumxx(24, (idcode[0] << 16) | (idcode[1] << 8) | (idcode[2] << 0));
		putstr("\r\n");
		xfr_defopflags = XSPI_OPFLAG_XFR_VERBOSE;
	}

	return 0;
}

int spi_flash_read_fast(u32 offset, u32 len, void *data)
{
	u8 cmd[5];

	cmd[0] = CMD_READ_ARRAY_FAST;
	spi_flash_addr(offset, cmd);
	cmd[4] = 0x00;

	return spi_flash_cmd_read(cmd, sizeof(cmd), data, len);
}

#endif /* XLB_SPI_FLASH_BASEADDR */
