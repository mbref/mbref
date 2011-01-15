/*
 * (C) Copyright 2011
 * Li-Pro.Net <www.li-pro.net>
 * Stephan Linz <linz@li-pro.net>
 *
 * Filename:	plbv46_mbref_reg.c
 * Version:	1.00.a
 * Description:	plbv46_mbref_reg Driver Source File
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

/***************************** Include Files *******************************/

#include "plbv46_mbref_reg.h"

/************************** Function Definitions ***************************/

/**
 *
 * Enable all possible interrupts from PLBV46_MBREF_REG device.
 *
 * @param   baseaddr_p is the base address of the PLBV46_MBREF_REG device.
 *
 * @return  None.
 *
 * @note    None.
 *
 */
void PLBV46_MBREF_REG_EnableInterrupt(void * baseaddr_p)
{
  Xuint32 baseaddr;
  baseaddr = (Xuint32) baseaddr_p;

  /*
   * Enable all interrupt source from user logic.
   */
  PLBV46_MBREF_REG_mWriteReg(baseaddr, PLBV46_MBREF_REG_INTR_IPIER_OFFSET, 0x00000000);

  /*
   * Enable all possible interrupt sources from device.
   */
  PLBV46_MBREF_REG_mWriteReg(baseaddr, PLBV46_MBREF_REG_INTR_DIER_OFFSET,
    INTR_TERR_MASK
    | INTR_DPTO_MASK
    | INTR_IPIR_MASK
    );

  /*
   * Set global interrupt enable.
   */
  PLBV46_MBREF_REG_mWriteReg(baseaddr, PLBV46_MBREF_REG_INTR_DGIER_OFFSET, INTR_GIE_MASK);
}

/**
 *
 * Example interrupt controller handler for PLBV46_MBREF_REG device.
 * This is to show example of how to toggle write back ISR to clear interrupts.
 *
 * @param   baseaddr_p is the base address of the PLBV46_MBREF_REG device.
 *
 * @return  None.
 *
 * @note    None.
 *
 */
void PLBV46_MBREF_REG_Intr_DefaultHandler(void * baseaddr_p)
{
  Xuint32 baseaddr;
  Xuint32 IntrStatus;
Xuint32 IpStatus;
  baseaddr = (Xuint32) baseaddr_p;

  /*
   * Get status from Device Interrupt Status Register.
   */
  IntrStatus = PLBV46_MBREF_REG_mReadReg(baseaddr, PLBV46_MBREF_REG_INTR_DISR_OFFSET);

  xil_printf("Device Interrupt! DISR value : 0x%08x \n\r", IntrStatus);

  /*
   * Verify the source of the interrupt is the user logic and clear the interrupt
   * source by toggle write baca to the IP ISR register.
   */
  if ( (IntrStatus & INTR_IPIR_MASK) == INTR_IPIR_MASK )
  {
    xil_printf("User logic interrupt! \n\r");
    IpStatus = PLBV46_MBREF_REG_mReadReg(baseaddr, PLBV46_MBREF_REG_INTR_IPISR_OFFSET);
    PLBV46_MBREF_REG_mWriteReg(baseaddr, PLBV46_MBREF_REG_INTR_IPISR_OFFSET, IpStatus);
  }

}

