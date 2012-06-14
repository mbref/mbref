/*
 * (C) Copyright 2012
 * Li-Pro.Net <www.li-pro.net>
 * Stephan Linz <linz@li-pro.net>
 *
 * Filename:    axi_mbref_mio_selftest.c
 * Version:     1.00.a
 * Description: Contains a diagnostic self-test function for the axi_mbref_mio driver
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

#include "axi_mbref_mio.h"
#include "xparameters.h"
#include "stdio.h"
#include "xio.h"

/************************** Constant Definitions ***************************/


/************************** Variable Definitions ****************************/


/************************** Function Definitions ***************************/

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
XStatus AXI_MBREF_MIO_SelfTest(void * baseaddr_p)
{
  int     Index;
  Xuint32 baseaddr;
  Xuint32 Mem32Value;

  /*
   * Check and get the device address
   */
  /*
   * Base Address maybe 0. Up to developer to uncomment line below.
  XASSERT_NONVOID(baseaddr_p != XNULL);
   */
  baseaddr = (Xuint32) baseaddr_p;

  xil_printf("******************************\n\r");
  xil_printf("* User Peripheral Self Test\n\r");
  xil_printf("******************************\n\n\r");

  /*
   * Write data to user logic BRAMs and read back
   */
  xil_printf("User logic memory test...\n\r");
  xil_printf("   - local memory address is 0x%08x\n\r", baseaddr);
  xil_printf("   - write pattern to local BRAM and read back\n\r");
  for ( Index = 0; Index < 256; Index++ )
  {
    AXI_MBREF_MIO_mWriteMemory(baseaddr+4*Index, (0xDEADBEEF % Index));
  }

  for ( Index = 0; Index < 256; Index++ )
  {
    Mem32Value = AXI_MBREF_MIO_mReadMemory(baseaddr+4*Index);
    if ( Mem32Value != (0xDEADBEEF % Index) )
    {
      xil_printf("   - write/read memory failed on address 0x%08x\n\r", baseaddr+4*Index);
      return XST_FAILURE;
    }
  }
  xil_printf("   - write/read memory passed\n\n\r");

  return XST_SUCCESS;
}
