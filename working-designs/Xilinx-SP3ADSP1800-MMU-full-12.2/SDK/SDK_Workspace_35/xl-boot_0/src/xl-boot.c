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

#include "xparameters.h"
#include "xlb_config.h"

#include "xtmrctr_l.h"

#ifdef XLB_UARTLITE
#include "xuartlite_l.h"
#define XLB_STDIO_HW		"uartlite"
#if !defined(XUartLite_mReadReg)
#define XLB_NEED_XIL_MACROBACK
#endif
#endif

#ifdef XLB_UART16550
#include "xuartns550_l.h"
#define XLB_STDIO_HW		"uart16550"
#if !defined(XUartNs550_mReadReg)
#define XLB_NEED_XIL_MACROBACK
#endif
#endif

/* bring back the removed _m macros */
#ifdef XLB_NEED_XIL_MACROBACK
#include "xil_macroback.h"
#endif

#define XLB_SRC_VER		"0.01"

#ifndef XLB_STDIO_BAUDRATE
#define XLB_STDIO_BAUDRATE	115200
#endif

#ifndef XLB_BOOT_COUNTER
#define XLB_BOOT_COUNTER	10
#endif

#ifndef XLB_LOCBLOB_OFFSET
#define XLB_LOCBLOB_OFFSET	0
#endif
#define XLB_LOCBLOB_START	(XLB_FLASH_START + XLB_LOCBLOB_OFFSET)

/*
 * image key is the first fixed assmebly mnemonic of the image locator blob:
 *	brlid r5, locator	--> 0xb8b40008
 */
#define XLB_LOCBLOB_KEY		0xb8b40008

/* locator blob entry */
typedef void (*locblob)(void);

#if (XLB_BOOT_COUNTER != 0)

#if defined(XLB_UARTLITE)

char getkey(void)
{
	if(XUartLite_mIsReceiveEmpty(XLB_STDIO_BASEADDR)) {
		return '\0';
	} else {
		return XUartLite_RecvByte(XLB_STDIO_BASEADDR);
	}
}

#elif defined(XLB_UART16550)

char getkey(void)
{
	if (!XUartNs550_mIsReceiveData(XLB_STDIO_BASEADDR)) {
		return '\0';
	} else {
		return XUartNs550_mReadReg(XLB_STDIO_BASEADDR, XUN_RBR_OFFSET);
	}
}

#endif

#define XTmrCtr_mAckEvent(BaseAddress, TmrCtrNumber)			\
	XTmrCtr_mSetControlStatusReg((BaseAddress), (TmrCtrNumber),	\
	XTmrCtr_mGetControlStatusReg((BaseAddress), (TmrCtrNumber)))

#define tm_ack()	XTmrCtr_mAckEvent(XLB_TIMER_0_BASEADDR, 0)
#define tm_event()	XTmrCtr_mHasEventOccurred(XLB_TIMER_0_BASEADDR, 0)
#define tm_deinit()	XTmrCtr_mDisable(XLB_TIMER_0_BASEADDR, 0)

inline void tm_init(void)
{
	/*
	 * TI	:= Timer Interval (in our case 1s)
	 * TLR	:= Timer Load Register
	 * FREQ	:= Frequency (CPU clock)
	 *
	 *	TLR + 2
	 * TI = --------	--> TLR	= TI * FREQ - 2		| TI = 1s
	 *	  FREQ			= FREQ - 2
	 *				  ========
	 */
	XTmrCtr_mSetLoadReg(XLB_TIMER_0_BASEADDR, 0, XLB_MB_CLOCK_FREQ - 2);
	XTmrCtr_mLoadTimerCounterReg(XLB_TIMER_0_BASEADDR, 0);
	XTmrCtr_mSetControlStatusReg(XLB_TIMER_0_BASEADDR, 0,
			XTC_CSR_AUTO_RELOAD_MASK | XTC_CSR_DOWN_COUNT_MASK);
	XTmrCtr_mEnable(XLB_TIMER_0_BASEADDR, 0);
}

inline int boot_stop(void)
{
	int bc = XLB_BOOT_COUNTER;

	print("Hit any key to stop autoboot: ");
	putnum(bc);

	tm_init();
	while (bc) {
		if (tm_event()) {
			tm_ack();
			print("\b\b\b\b\b\b\b\b");
			putnum(--bc);
		}
		if (getkey()) {
			break;
		}
	}

	tm_deinit();
	print("\r\n");
	return bc;
}

#else

inline int boot_stop(void)
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

int main ()
{
	locblob locblob_start = (locblob)(XLB_LOCBLOB_START);

#ifdef XLB_UART16550
	/* if we have a uart 16550, then that needs to be initialized */
	XUartNs550_SetBaud(XLB_STDIO_BASEADDR, XLB_XILINX_UART16550_0_CLOCK_HZ,
							XLB_STDIO_BAUDRATE);
	XUartNs550_mSetLineControlReg(XLB_STDIO_BASEADDR, XUN_LCR_8_DATA_BITS);
#endif

	/* bootloader greeting */
	print(XLB_GREETING_STR);

	/* search and run locator blob image */
	putnum(XLB_LOCBLOB_START);
	print(": ");
	if (*(unsigned int *)locblob_start == XLB_LOCBLOB_KEY) {
		print("start image locator...\r\n");
		if (!boot_stop()) {
			locblob_start();
		}
	}

	print("no image, use XMD for JTAG download.\r\n");
	return -1;
}
