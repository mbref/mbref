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

#ifndef _XLB_XUART_H
#define _XLB_XUART_H

#ifdef __cplusplus
extern "C" {
#endif

#include "xbasic_types.h"
#include "xparameters.h"
#include "xlb_config.h"

#if defined(XLB_UARTLITE)
#define XLB_STDIO_HW		"uartlite"
#endif

#if defined(XLB_UART16550)
#define XLB_STDIO_HW		"uart16550"
#endif

/*
 * There is problem in microblaze toolchain with weak attribute. We cannot
 * weak the xuart_init() symbol like this:
 *
 *     extern inline void xuart_init(void) __attribute__((weak));
 *
 * That's why we use the CPP and point to the specific init function; only
 * when there is anyone.
 */
#if defined(XLB_UARTLITE)
#define xuart_init()
#elif defined(XLB_UART16550)
extern inline void xuart16550_init(void);
#define xuart_init() xuart16550_init()
#endif

extern inline u8 getkey(void);

#ifdef __cplusplus
}
#endif
 
#endif /* _XLB_XUART_H */
