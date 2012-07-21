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

#include "xl-xtm.h"

#include "xtmrctr_l.h"
#if !defined(XTimerCtr_mReadReg)
#define XLB_XTM_NEED_XIL_MACROBACK
#endif

/* bring back the removed _m macros */
#ifdef XLB_XTM_NEED_XIL_MACROBACK
#include "xil_macroback.h"
#endif

#if (XLB_BOOT_COUNTER != 0)

inline void xtm_init(void)
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

inline void xtm_deinit(void)
{
	XTmrCtr_mDisable(XLB_TIMER_0_BASEADDR, 0);
}

inline u32 xtm_event(void)
{
	return XTmrCtr_mHasEventOccurred(XLB_TIMER_0_BASEADDR, 0);
}

#define XTmrCtr_mAckEvent(BaseAddress, TmrCtrNumber)			\
	XTmrCtr_mSetControlStatusReg((BaseAddress), (TmrCtrNumber),	\
	XTmrCtr_mGetControlStatusReg((BaseAddress), (TmrCtrNumber)))

inline void xtm_ack(void)
{
	XTmrCtr_mAckEvent(XLB_TIMER_0_BASEADDR, 0);
}

#endif /* XLB_BOOT_COUNTER */
