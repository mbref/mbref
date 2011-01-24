/*
 * (C) Copyright 2011
 * Li-Pro.Net <www.li-pro.net>
 * Stephan Linz <linz@li-pro.net>
 *
 * Filename:    plbv46_mbref_mio.h
 * Version:     1.00.a
 * Description: plbv46_mbref_mio Driver Header File
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

#ifndef PLBV46_MBREF_MIO_H
#define PLBV46_MBREF_MIO_H

/***************************** Include Files *******************************/

#include "xbasic_types.h"
#include "xstatus.h"
#include "xil_io.h"

/************************** Constant Definitions ***************************/


/**
 * Software Reset Space Register Offsets
 * -- RST : software reset register
 */
#define PLBV46_MBREF_MIO_SOFT_RST_SPACE_OFFSET (0x00000000)
#define PLBV46_MBREF_MIO_RST_REG_OFFSET (PLBV46_MBREF_MIO_SOFT_RST_SPACE_OFFSET + 0x00000000)

/**
 * Software Reset Masks
 * -- SOFT_RESET : software reset
 */
#define SOFT_RESET (0x0000000A)

/**
 * Interrupt Controller Space Offsets
 * -- INTR_DISR  : device (peripheral) interrupt status register
 * -- INTR_DIPR  : device (peripheral) interrupt pending register
 * -- INTR_DIER  : device (peripheral) interrupt enable register
 * -- INTR_DIIR  : device (peripheral) interrupt id (priority encoder) register
 * -- INTR_DGIER : device (peripheral) global interrupt enable register
 * -- INTR_ISR   : ip (user logic) interrupt status register
 * -- INTR_IER   : ip (user logic) interrupt enable register
 */
#define PLBV46_MBREF_MIO_INTR_CNTRL_SPACE_OFFSET (0x00000100)
#define PLBV46_MBREF_MIO_INTR_DISR_OFFSET (PLBV46_MBREF_MIO_INTR_CNTRL_SPACE_OFFSET + 0x00000000)
#define PLBV46_MBREF_MIO_INTR_DIPR_OFFSET (PLBV46_MBREF_MIO_INTR_CNTRL_SPACE_OFFSET + 0x00000004)
#define PLBV46_MBREF_MIO_INTR_DIER_OFFSET (PLBV46_MBREF_MIO_INTR_CNTRL_SPACE_OFFSET + 0x00000008)
#define PLBV46_MBREF_MIO_INTR_DIIR_OFFSET (PLBV46_MBREF_MIO_INTR_CNTRL_SPACE_OFFSET + 0x00000018)
#define PLBV46_MBREF_MIO_INTR_DGIER_OFFSET (PLBV46_MBREF_MIO_INTR_CNTRL_SPACE_OFFSET + 0x0000001C)
#define PLBV46_MBREF_MIO_INTR_IPISR_OFFSET (PLBV46_MBREF_MIO_INTR_CNTRL_SPACE_OFFSET + 0x00000020)
#define PLBV46_MBREF_MIO_INTR_IPIER_OFFSET (PLBV46_MBREF_MIO_INTR_CNTRL_SPACE_OFFSET + 0x00000028)

/**
 * Interrupt Controller Masks
 * -- INTR_TERR_MASK : transaction error
 * -- INTR_DPTO_MASK : data phase time-out
 * -- INTR_IPIR_MASK : ip interrupt requeset
 * -- INTR_RFDL_MASK : read packet fifo deadlock interrupt request
 * -- INTR_WFDL_MASK : write packet fifo deadlock interrupt request
 * -- INTR_IID_MASK  : interrupt id
 * -- INTR_GIE_MASK  : global interrupt enable
 * -- INTR_NOPEND    : the DIPR has no pending interrupts
 */
#define INTR_TERR_MASK (0x00000001UL)
#define INTR_DPTO_MASK (0x00000002UL)
#define INTR_IPIR_MASK (0x00000004UL)
#define INTR_RFDL_MASK (0x00000020UL)
#define INTR_WFDL_MASK (0x00000040UL)
#define INTR_IID_MASK (0x000000FFUL)
#define INTR_GIE_MASK (0x80000000UL)
#define INTR_NOPEND (0x80)

/**************************** Type Definitions *****************************/


/***************** Macros (Inline Functions) Definitions *******************/

/**
 *
 * Write a value to a PLBV46_MBREF_MIO register. A 32 bit write is performed.
 * If the component is implemented in a smaller width, only the least
 * significant data is written.
 *
 * @param   BaseAddress is the base address of the PLBV46_MBREF_MIO device.
 * @param   RegOffset is the register offset from the base to write to.
 * @param   Data is the data written to the register.
 *
 * @return  None.
 *
 * @note
 * C-style signature:
 * 	void PLBV46_MBREF_MIO_mWriteReg(Xuint32 BaseAddress, unsigned RegOffset, Xuint32 Data)
 *
 */
#define PLBV46_MBREF_MIO_mWriteReg(BaseAddress, RegOffset, Data) \
 	Xil_Out32((BaseAddress) + (RegOffset), (Xuint32)(Data))

/**
 *
 * Read a value from a PLBV46_MBREF_MIO register. A 32 bit read is performed.
 * If the component is implemented in a smaller width, only the least
 * significant data is read from the register. The most significant data
 * will be read as 0.
 *
 * @param   BaseAddress is the base address of the PLBV46_MBREF_MIO device.
 * @param   RegOffset is the register offset from the base to write to.
 *
 * @return  Data is the data from the register.
 *
 * @note
 * C-style signature:
 * 	Xuint32 PLBV46_MBREF_MIO_mReadReg(Xuint32 BaseAddress, unsigned RegOffset)
 *
 */
#define PLBV46_MBREF_MIO_mReadReg(BaseAddress, RegOffset) \
 	Xil_In32((BaseAddress) + (RegOffset))


/**
 *
 * Write/Read 32 bit value to/from PLBV46_MBREF_MIO user logic memory (BRAM).
 *
 * @param   Address is the memory address of the PLBV46_MBREF_MIO device.
 * @param   Data is the value written to user logic memory.
 *
 * @return  The data from the user logic memory.
 *
 * @note
 * C-style signature:
 * 	void PLBV46_MBREF_MIO_mWriteMemory(Xuint32 Address, Xuint32 Data)
 * 	Xuint32 PLBV46_MBREF_MIO_mReadMemory(Xuint32 Address)
 *
 */
#define PLBV46_MBREF_MIO_mWriteMemory(Address, Data) \
 	Xil_Out32(Address, (Xuint32)(Data))
#define PLBV46_MBREF_MIO_mReadMemory(Address) \
 	Xil_In32(Address)

/**
 *
 * Reset PLBV46_MBREF_MIO via software.
 *
 * @param   BaseAddress is the base address of the PLBV46_MBREF_MIO device.
 *
 * @return  None.
 *
 * @note
 * C-style signature:
 * 	void PLBV46_MBREF_MIO_mReset(Xuint32 BaseAddress)
 *
 */
#define PLBV46_MBREF_MIO_mReset(BaseAddress) \
 	Xil_Out32((BaseAddress)+(PLBV46_MBREF_MIO_RST_REG_OFFSET), SOFT_RESET)

/************************** Function Prototypes ****************************/


/**
 *
 * Enable all possible interrupts from PLBV46_MBREF_MIO device.
 *
 * @param   baseaddr_p is the base address of the PLBV46_MBREF_MIO device.
 *
 * @return  None.
 *
 * @note    None.
 *
 */
void PLBV46_MBREF_MIO_EnableInterrupt(void * baseaddr_p);

/**
 *
 * Example interrupt controller handler.
 *
 * @param   baseaddr_p is the base address of the PLBV46_MBREF_MIO device.
 *
 * @return  None.
 *
 * @note    None.
 *
 */
void PLBV46_MBREF_MIO_Intr_DefaultHandler(void * baseaddr_p);

/**
 *
 * Run a self-test on the driver/device. Note this may be a destructive test if
 * resets of the device are performed.
 *
 * If the hardware system is not built correctly, this function may never
 * return to the caller.
 *
 * @param   baseaddr_p is the base address of the PLBV46_MBREF_MIO instance to be worked on.
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
XStatus PLBV46_MBREF_MIO_SelfTest(void * baseaddr_p);

#endif /** PLBV46_MBREF_MIO_H */
