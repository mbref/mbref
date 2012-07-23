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
 * derived from U-Boot drivers/spi/xilinx_spi.c:
 *    Copyright (c) 2005-2008 Analog Devices Inc.
 *    Copyright (c) 2010 Thomas Chou <thomas@wytron.com.tw>
 *    Copyright (c) 2010 Graeme Smecher <graeme.smecher@mail.mcgill.ca>
 *    Copyright (c) 2012 Stephan Linz <linz@li-pro.net>
 *
 *    Licensed under the GPL-2 or later.
 */

#include <xenv_standalone.h>
#include <xlb_config.h>

#include "putstr.h"

#include "xl-xspi.h"

#ifdef XLB_SPI_FLASH_BASEADDR

#if (XLB_SPI_FLASH_TRANSFERBITS != 8)
#error "8-bit support only (change your design)"
#endif

#define XSP_BASEADDR		XLB_SPI_FLASH_BASEADDR
#define XSP_XFRBITS		XLB_SPI_FLASH_TRANSFERBITS
#define XSP_CS			XLB_SPI_FLASH_CS
#define XSP_SECTSZ_TO_SHOW	XLB_SPI_FLASH_SECTSIZE

#include "xspi_l.h"

/* back port missing spi macros */
#if !defined(XSpi_ReadReg)
#include "xio.h"
#define XSpi_ReadReg(BaseAddress, RegOffset) \
        XIo_In32((BaseAddress) + (RegOffset))
#define XSpi_WriteReg(BaseAddress, RegOffset, RegisterValue) \
        XIo_Out32((BaseAddress) + (RegOffset), (RegisterValue))
#endif

static inline void xspi_reset(void)
{
	XSpi_WriteReg(XSP_BASEADDR, XSP_SRR_OFFSET, XSP_SRR_RESET_MASK);
	XSpi_WriteReg(XSP_BASEADDR, XSP_SRR_OFFSET, ~0L);
}

static inline void xspi_cs_activate(u32 cs)
{
	XSpi_WriteReg(XSP_BASEADDR, XSP_SSR_OFFSET, ~(1 << (cs)));
}

static inline void xspi_cs_deactivate(void)
{
	XSpi_WriteReg(XSP_BASEADDR, XSP_SSR_OFFSET, ~0L);
}

int xspi_init(u32 opflags)
{
	u32 cr;

	xspi_reset();
	xspi_cs_deactivate();

	cr = XSP_CR_MANUAL_SS_MASK | XSP_CR_MASTER_MODE_MASK | \
			XSP_CR_ENABLE_MASK;

	if (opflags & XSPI_OPFLAG_CPHA)
		cr |= XSP_CR_CLK_PHASE_MASK;

	if (opflags & XSPI_OPFLAG_CPOL)
		cr |= XSP_CR_CLK_POLARITY_MASK;

	XSpi_WriteReg(XSP_BASEADDR, XSP_CR_OFFSET, cr);

	return 0;
}

int xspi_xfr(u32 bitlen, const void *dout, void *din, u32 opflags)
{
	u32 bytes = bitlen / XSP_XFRBITS;
	const u8 *txp = dout;
	u8 *rxp = din;

	if (bitlen == 0)
		goto done;

	if (bitlen % XSP_XFRBITS) {
		opflags |= XSPI_OPFLAG_XFR_END;
		goto done;
	}

	while (!(XSpi_ReadReg(XSP_BASEADDR, XSP_SR_OFFSET)
			& XSP_SR_RX_EMPTY_MASK))
		XSpi_ReadReg(XSP_BASEADDR, XSP_DRR_OFFSET);

	if (opflags & XSPI_OPFLAG_XFR_BEGIN)
		xspi_cs_activate(XSP_CS);

	while (bytes--) {
		u8 d = txp ? *txp++ : 0xff;

		XSpi_WriteReg(XSP_BASEADDR, XSP_DTR_OFFSET, d);
		while (XSpi_ReadReg(XSP_BASEADDR, XSP_SR_OFFSET)
				& XSP_SR_RX_EMPTY_MASK)
			/* wait and do nothing */;

		d = XSpi_ReadReg(XSP_BASEADDR, XSP_DRR_OFFSET);
		if (rxp)
			*rxp++ = d;

		if ((opflags & XSPI_OPFLAG_XFR_VERBOSE) && bytes
				&& !(bytes % XSP_SECTSZ_TO_SHOW))
			putstr(".");
	}

 done:
	if (opflags & XSPI_OPFLAG_XFR_END)
		xspi_cs_deactivate();

	return 0;
}

#endif /* XLB_SPI_FLASH_BASEADDR */
