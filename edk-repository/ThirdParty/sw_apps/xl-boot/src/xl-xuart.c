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

#include <xenv_standalone.h>
#include <xlb_config.h>

#include "xl-xuart.h"

#ifdef XLB_UARTLITE
#include "xuartlite_l.h"
#if !defined(XUartLite_mReadReg)
#define XLB_XUART_NEED_XIL_MACROBACK
#endif
#endif

#ifdef XLB_UART16550
#include "xuartns550_l.h"
#if !defined(XUartNs550_mReadReg)
#define XLB_XUART_NEED_XIL_MACROBACK
#endif
#endif

/* bring back the removed _m macros */
#ifdef XLB_XUART_NEED_XIL_MACROBACK
#include "xil_macroback.h"
#endif

#if defined(XLB_UARTLITE)

inline u8 getkey(void)
{
	if(XUartLite_mIsReceiveEmpty(XLB_STDIO_BASEADDR)) {
		return '\0';
	} else {
		return XUartLite_RecvByte(XLB_STDIO_BASEADDR);
	}
}

#elif defined(XLB_UART16550)

#ifndef XLB_STDIO_BAUDRATE
#define XLB_STDIO_BAUDRATE	115200
#endif

inline void xuart16550_init(void)
{
	/* if we have a uart 16550, then that needs to be initialized */
	XUartNs550_SetBaud(XLB_STDIO_BASEADDR, XLB_XILINX_UART16550_0_CLOCK_HZ,
							XLB_STDIO_BAUDRATE);
	XUartNs550_mSetLineControlReg(XLB_STDIO_BASEADDR, XUN_LCR_8_DATA_BITS);
}

inline u8 getkey(void)
{
	if (!XUartNs550_mIsReceiveData(XLB_STDIO_BASEADDR)) {
		return '\0';
	} else {
		return XUartNs550_mReadReg(XLB_STDIO_BASEADDR, XUN_RBR_OFFSET);
	}
}

#endif /* XLB_UARTLITE || XLB_UART16550 */
