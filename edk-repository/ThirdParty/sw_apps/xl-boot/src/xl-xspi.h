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

#ifndef _XLB_XSPI_H
#define _XLB_XSPI_H

#ifdef __cplusplus
extern "C" {
#endif

#include "xbasic_types.h"
#include "xparameters.h"
#include "xlb_config.h"

#define XSPI_OPFLAG_XFR_VERBOSE	(1 << 31)
#define	XSPI_OPFLAG_XFR_END	(1 << 16)
#define	XSPI_OPFLAG_XFR_BEGIN	(1 << 15)
#define	XSPI_OPFLAG_CPHA	(1 << 1)
#define	XSPI_OPFLAG_CPOL	(1 << 0)

extern int xspi_init(u32 opflags);
extern int xspi_xfr(u32 bitlen, const void *dout, void *din, u32 opflags);

#ifdef __cplusplus
}
#endif

#endif /* _XLB_XSPI_H */
