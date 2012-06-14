/*
 * (C) Copyright 2012
 * Li-Pro.Net <www.li-pro.net>
 * Stephan Linz <linz@li-pro.net>
 *
 * Filename:    axi_mbref_mio.h
 * Version:     1.00.a
 * Description: axi_mbref_mio Driver Header File
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

#ifndef AXI_MBREF_MIO_H
#define AXI_MBREF_MIO_H

/***************************** Include Files *******************************/

#include "xbasic_types.h"
#include "xstatus.h"
#include "xil_io.h"

/************************** Constant Definitions ***************************/


/**************************** Type Definitions *****************************/


/**
 *
 * Write/Read 32 bit value to/from AXI_MBREF_MIO user logic memory (BRAM).
 *
 * @param   Address is the memory address of the AXI_MBREF_MIO device.
 * @param   Data is the value written to user logic memory.
 *
 * @return  The data from the user logic memory.
 *
 * @note
 * C-style signature:
 * 	void AXI_MBREF_MIO_mWriteMemory(Xuint32 Address, Xuint32 Data)
 * 	Xuint32 AXI_MBREF_MIO_mReadMemory(Xuint32 Address)
 *
 */
#define AXI_MBREF_MIO_mWriteMemory(Address, Data) \
 	Xil_Out32(Address, (Xuint32)(Data))
#define AXI_MBREF_MIO_mReadMemory(Address) \
 	Xil_In32(Address)

/************************** Function Prototypes ****************************/


/**
 *
 * Run a self-test on the driver/device. Note this may be a destructive test if
 * resets of the device are performed.
 *
 * If the hardware system is not built correctly, this function may never
 * return to the caller.
 *
 * @param   baseaddr_p is the base address of the AXI_MBREF_MIO instance to be worked on.
 *
 * @return
 *
 *    - XST_SUCCESS   if all self-test code passed
 *    - XST_FAILURE   if any self-test code failed
 *
 * @note    Caching must be turned off for this function to work.
 * @note    Self test may fail if data memory and device are not on the same bus.
 *
 */
XStatus AXI_MBREF_MIO_SelfTest(void * baseaddr_p);

#endif /** AXI_MBREF_MIO_H */
