/*!
 * @file fs-boot.c
 * FILE:   $Id:$
 *
 * DESCRIPTION:
 *     This is the main program for the first-stage bootloader FS-BOOT for the
 *     PetaLinux distribution.  
 *
 *     This bootloader is targeted for reconfigurable platform and is desgined
 *     to be run from BRAM.  Hence, elf size must remain below 8K bytes.
 *
 *     It supports the  booting of any second-stage bootloader from
 *     FLASH or RAM memory, SREC image download via the uartlite
 *     serial interface and image write to RAM memory.
 *
 *     Note: This program requires the following hardware support:
 *           - XuartLite or uart16550
 *           - BRAM >= 8Kb
 *
 * AUTHOR: 
 *     Benny Chen, PetaLogix <Benny.Chen@petalogix.com>
 *
 * MODIFICATION: 
 *     Michal Simek, PetaLogix 2008 <michal.simek@petalogix.com>
 *      Add uart16550 support
 *
 * LICENSING:
 *     Copyright (c) 2006 - 2008 PetaLogix. All rights reserved.
 *
 *  No part of this program may be reproduced or adapted in  any form  or by 
 *  any means, electronic or mechanical, without  permission from PetaLogix. 
 *  This program is  confidential and  may not be  disclosed, decompiled  or 
 *  reverse engineered without permission in writing from PetaLogix.
 *
 */
#include "fs-boot.h"
#include "srec.h"
#include "time.h"

/*! \brief Macro for Jump Instruction */
#define GO(addr) { ((void(*)(void))(addr))(); }

/*---------------------------------------------------------------------------*/

/*---------------------------------------------------------------------------*/
/* Global variables */
int do_erase = 1;

/*---------------------------------------------------------------------------*/
/* Local Function Prototype */
static void uart_init(void);

/*---------------------------------------------------------------------------*/

/*!
 * Run initialisation code to setup the opb_timer.
 * This routine only enables Timer 0.
 *
 * @param  None.
 *
 * @return  None.
 */
static void opb_timer_init(void)
{

    /* 
     * Initialised the timer to default value
     * The default settings for the timers are:
     *   - Interrupt generation disabled
     *   - Count up mode
     *   - Compare mode
     *   - Enable Auto Reload
     *   - External compare output disabled
     *   - External capture input disabled
     *   - Pulse width modulation disabled
     *   - Timer disabled, waits for Start function to be called
     */
	timer_init();
    return;
}

/*!
 * Run initialisation code to setup the UART for communication.
 * For UARTLITE, the bulk of the configuration is done in hardware.
 *
 * @param  None.
 *
 * @return  None.
 */
#if defined(CONFIG_UARTLITE)
static void uart_init(void)
{
    /* All mode and baud setup is done in hardware level */
    /* Reset FIFO and Enable Interrupt */
    XUartLite_mSetControlReg(UART_BASEADDR, (XUL_CR_ENABLE_INTR    |
                                           XUL_CR_FIFO_RX_RESET  |
                                           XUL_CR_FIFO_TX_RESET));
}
#elif defined(CONFIG_UART16550)
static void uart_init(void)
{
   XUartNs550_SetBaud(UART_BASEADDR, CONFIG_XILINX_UART16550_0_CLOCK_HZ, 115200);
   XUartNs550_mSetLineControlReg(UART_BASEADDR, XUN_LCR_8_DATA_BITS);
}
#endif


/*!
 * This function loads boot image to RAM.
 *
 * @param  src_addr  - The address of the  bootloader image.
 * @param  load_addr - The address in memory to load the image.
 * @param  size      - The size to copy.
 *
 * @return  none.
 */
void load_image(unsigned long src_addr , unsigned int load_addr, int size)
{
    int i;
    volatile unsigned char *dst = (unsigned char *)load_addr;

    for(i = 0; i < size; i ++) {
        *dst++ = *((volatile unsigned char *)(src_addr + i)); 
    }
    return;
}

/*!
 * This function implements a light weight
 * memcpy routine.
 *
 * @param  dst - Destination address in memory
 * @param  src - Source address in memory
 * @param  len - Length of data to copy.
 *
 * @return  None.
 */
void fs_memcpy(volatile char *dst, char *src, int len)
{
    int i;

    for(i = 0; i < len; i++) {
        *dst++ = *src++;
    }
    return;
}


/*!
 * Implements a blocking read character from uart.
 *
 * @param  None.
 *
 * @return  The character read.
 */
#if defined(CONFIG_UARTLITE)
char get_ch(void)
{
    while(XUartLite_mIsReceiveEmpty(UART_BASEADDR));
        return XUartLite_RecvByte(UART_BASEADDR);
}
#elif defined(CONFIG_UART16550)
char get_ch(void)
{
    while (!XUartNs550_mIsReceiveData(UART_BASEADDR));
    return XUartNs550_mReadReg(UART_BASEADDR, XUN_RBR_OFFSET);
}
#endif


/*!
 * Implements a non-blocking read char
 *
 * @param  None.
 *
 * @return  The character read.
 */
#if defined(CONFIG_UARTLITE)
char get_c(void)
{
    if(XUartLite_mIsReceiveEmpty(UART_BASEADDR)) {
        return '\0';
    } else {
        return XUartLite_RecvByte(UART_BASEADDR);
    }
}
#elif defined(CONFIG_UART16550)
char get_c(void)
{
	if (!XUartNs550_mIsReceiveData(UART_BASEADDR)) {
		return '\0';
	} else {
		return XUartNs550_mReadReg(UART_BASEADDR, XUN_RBR_OFFSET);
	}
}
#endif


/*!
 * Sends a single character to the uart fifo.
 * 
 * @param  data - The character to send
 *
 * @return  None.
 */
#if defined(CONFIG_UARTLITE)
void put_ch(unsigned char data)
{
    while (XUartLite_mIsTransmitFull(UART_BASEADDR));
    XUartLite_SendByte(UART_BASEADDR, data);

    return;
}
#elif defined(CONFIG_UART16550)
void put_ch (unsigned char data)
{
    XUartNs550_SendByte(UART_BASEADDR, data);
    return;
}
#endif


/*!
 * This routine reads each SREC line from
 * the UART. Each line is return via the buffer pointer 'buf'.
 * 
 * @param  buf - Pointer to buffer (buffer size = MAXSIZE + 1 for \0)
 * @param  len - length of buffer
 *
 * @return  int - the number of bytes read
 */
int read_line(char *buf, int len)
{
    char *p;
    char ch;

    len--;  /* leave room for \0 */

    for(p = buf; p < (buf + len); ++p) {
        ch = get_ch();
        switch (ch) {
            case '\n':
                *p = '\0';
                return (p - buf);
            case '\0':
            case 0x03:  /* Ctl'C */
                fsprint("\n\rExiting Serial image download.\n\r");
                return(-1);
            default:
                *p = ch;
        }
    }

    *p = '\0';
    return (p - buf);
}

#ifndef CONFIG_NO_FLASH
/*!
 * This routine send a command to the CUI
 * to put the FLASH into Read Array mode.
 * 
 * @param  addr - Memory address of FLASH device
 *
 * @return  none
 */
static void flash_readarray_mode(unsigned long flash_addr)
{

	/* 
	 * We assume it is all CFI FLASH
	 * Write 32-bit to take care off all flash
	 * configurations. 
	 */
	*((volatile unsigned long *)(flash_addr)) = 0xFFFFFFFF;
}
#endif

/*!
 * This routine evalutate if an address is
 * in the FLASH memory range.
 * 
 * @param  addr - Address to evaluate.
 *
 * @return  0 - for not in FLASH
 * @return  1 - for in FLASH
 */
static int image_exist(unsigned long image_addr)
{
	unsigned long *addr = (unsigned long *)image_addr;

	/* 
	 * b8b40008 corresponds to the instruction "brlid r5, locator;"
	 * defined in the bootstub routine in petalinux-reloc-blob
	 * This allows us to check if a valid u-boot image is in FLASH.
	 * Note: any changes to the bootstub code will need to update this. 
	 */
	if (*addr == 0xb8b40008) {
        return 1;
    } else {
        return 0;
    }
}

#ifndef CONFIG_NO_SREC
#ifndef CONFIG_NO_FLASH
/*!
 * This routine evalutate if an address is
 * in the FLASH memory range.
 * 
 * @param  addr - Address to evaluate.
 *
 * @return  0 - for not in FLASH
 * @return  1 - for in FLASH
 */
static int is_in_flash(unsigned long addr)
{
    if(addr >= FLASH_BASE && addr < FLASH_END) {
        return 1;
    } else {
        return 0;
    }
}
#endif

/*!
 * Loads the SREC bootloader image from the serial UART, 
 * decodes the SREC line and write it to FLASH or RAM.
 * 
 * @param  offset - Offset to be added to the address specified in the
 *          SREC.
 *
 * @return  boot location of downloaded image.
 * @return  0 for error.
 */
unsigned long serial_load(unsigned long offset)
{
    char srec_buffer[SREC_MAX_RECLEN + 1];  /* buffer for one S-Record       */
    char    binbuf[SREC_MAX_BINLEN];        /* buffer for binary data        */
    int     binlen;                         /* no. of data bytes in S-Rec.   */
    int     type;                           /* return code for record type   */
    unsigned long   addr;                   /* load address from S-Record    */
    unsigned long   store_addr = 0;         /* Final location to store image */

    int rtn;
    int total_line = 0;
    static char spin[] = "|/-\\|-";

    fsprint("FS-BOOT: Waiting for SREC image....\n\r");
    while ((rtn = read_line(srec_buffer, SREC_MAX_RECLEN + 1)) >= 0) {
        /* Decode the SREC line */
        type = decode_srec_line(srec_buffer, &binlen, &addr, binbuf);

#if DEBUG
        xil_printf("DEBUG:SREC Type:%d\n\r",type);
        xil_printf("DEBUG:Line Length:%d\n\r",rtn);
        xil_printf("DEBUG:Load Address:0x%lx\n\r",addr);
        xil_printf("DEBUG:Binary Length:%d\n\r",binlen);
#endif
        /* Check that SREC line parsed is valid */
        if (type < 0) {
            fsprint("\n\rFS-BOOT: Invalid SREC!\n\r");
            return 0;
        }

        switch (type) {
        case SREC_DATA2:
        case SREC_DATA3:
        case SREC_DATA4:
#if DEBUG
            xil_printf("DEBUG:SREC_DATA:%d\n\r",type);
#endif
            /* obtain the final store address */
            store_addr = addr + offset;

#ifndef CONFIG_NO_FLASH
            /* Check if address is in FLASH map range */
            if (is_in_flash(store_addr)) {
                fsprint("FS-BOOT: Destination address is in FLASH! Download Aborted.\n\r");
                return 0;
            } else
#endif
                /* write to SDRAM */
                fs_memcpy((char *)(store_addr), binbuf, binlen);


            break;
        case SREC_END2:
        case SREC_END3:
        case SREC_END4:
#if DEBUG
	    xil_printf("DEBUG:SREC_END:0x%lx\n\r",store_addr);
#endif
              /* No more record */

              /* Return the boot address */
              return (addr + offset);
        case SREC_START:
#if DEBUG
            xil_printf("DEBUG:SREC_START:0x%x\n\r",type);
#endif
            break;
        default:
            break;
        }

        total_line++;

        /* Print Progress */
        fsprint("\r");
        put_ch(spin[(total_line % 7)]);
        fsprint("\b");
    }

#if DEBUG
    xil_printf("DEBUG:Total Line processed:%d\n\r",total_line);
#endif

    return 0;
}

#endif

/*!
 * Lightweight print function to avoid using stdio.
 * 
 * @param  s - The string to print.
 *
 * @return  None.
 */
void fsprint(char *s)
{
    while (*s) {
        put_ch(*s);
        s++;
    }
}


/*---------------------------------------------------------------------------*/

#define xstr(s) str(s)
#define str(s)  #s

int main()
{
    unsigned long image_start = 0;   /* The address of the final boot image */
//    int image_maxsize = 0;
#if defined(CONFIG_FS_KERNEL) || !defined(CONFIG_NO_SREC)
    int i;
#endif

#ifndef CONFIG_NO_SREC
    unsigned long start_addr;    /* The address of the loaded image */
    int do_srec = 0;         
    int boot_new = 1;		/* Default to boot new image when download occurs */
#endif
#if defined(CONFIG_FS_KERNEL)
    int do_kernel = 0;
#endif
    int bootdelay;		/* number of seconds delay */

    bootdelay = CONFIG_FS_BOOT_DELAY;
 
    /* UART Initialisation - no printing before this */
    uart_init();

    fsprint("\n\r=================================================\n\r" \
	"FS-BOOT First Stage Bootloader (c) 2006 PetaLogix\n\r" \
	"Project name: " CONFIG_PROJECT_NAME "\n\r" \
	"Build date: "__DATE__" "__TIME__ "  "
#ifndef CONFIG_NO_FLASH
	"F"
#endif
#ifndef CONFIG_NO_SREC
	"S"
#endif
#ifdef CONFIG_FS_KERNEL
	"K"
#endif
	"\n\rSerial console: "
#if defined(CONFIG_UARTLITE)
	"Uartlite\n\r"
#elif defined(CONFIG_UART16550)
	"Uart16550\n\r"
#endif
	"FS-BLOB at: " xstr(CONFIG_FS_BOOT_START) "\n\r"
	"=================================================\n\r");

    /* Counter/Timer initialisation */
    opb_timer_init();

    fsprint("FS-BOOT: System initialisation completed.\n\r");

#if defined(CONFIG_FS_KERNEL)
    /* Check if we want to boot kernel or bootloader */ 
    fsprint("FS-BOOT: Booting bootloader. Press 'k' for booting kernel.\n\r");
    /* Delay x secs */
    for(i = 0; i < (bootdelay * 100); i++) {
	if (!(i % 100)) put_ch('.');
        if(get_c() == 'k') {
            do_kernel = 1;
            break;
        }
		/* 10ms */
		udelay(10000);
    }

    if(do_kernel) {
        image_start = CONFIG_FS_KERN_START;
//        image_maxsize = CONFIG_FS_KERN_MAXSIZE;
    } else
#endif 
#ifndef CONFIG_NO_FLASH
    {
        /* Set the default bootloader boot parameters */
        image_start = CONFIG_FS_BOOT_START;
//        image_maxsize = CONFIG_FS_BOOT_MAXSIZE;
    }

	/* Initialise FLASH to read array mode */
	flash_readarray_mode(image_start);
#endif

#ifdef CONFIG_NO_SREC
	if(image_exist(image_start)) {
		fsprint("FS-BOOT: Booting from FLASH.\n\r");
	} else {
		fsprint("FS-BOOT: FLASH image failed.\n\r");
		fsprint("FS-BOOT: Please reset target.\n\r");
		return -1; 
	}
#else
	/* Look to see if FLASH has valid bootloader image !!!!*/
	if(image_exist(image_start)) {

		fsprint("FS-BOOT: Booting from FLASH. Press 's' for image download.\n\r");
		/* x second loop */
		for(i = 0; i < (bootdelay * 100); i++) {
			if (!(i % 100)) put_ch('.');
			if(get_c() == 's') {
				do_srec = 1;
				break;
			}
			/* 10ms */
			udelay(10000);
		}
	} else {
#ifndef CONFIG_NO_FLASH
		fsprint("FS-BOOT: No existing image in FLASH.  "
							"Starting image download.\n\r");
#endif
		do_srec = 1;
	}
    if(do_srec) {
        /* Download SREC FILE via Serial */
        start_addr = serial_load(0);

        if (start_addr <= 0) {
            fsprint("FS-BOOT: Image download failed.\n\r");
            fsprint("FS-BOOT: Please reset target.\n\r");
            return -1; 
        } else {
            fsprint("FS-BOOT: Image download successful.\n\r");

            /* Check that address is in our default bootloader partition */
            if(start_addr != image_start) {
                fsprint("FS-BOOT: Warning image location differ from default " 
                        "boot location. Image will not boot automatically after POR.\n\r");
            }

            fsprint("FS-BOOT: Press 'n' to boot old image.\n\r");
            /* x second loop */
            for(i = 0; i < (bootdelay * 100); i++) {
		if (!(i % 100)) put_ch('.');
                if(get_c() == 'n') {
                    boot_new = 0;
                    break;
                }
		        udelay(10000);
            }
            if(boot_new) {
                fsprint("FS-BOOT: Use new image.\n\r");
                /* Load using our new FLASH image */
                image_start = start_addr;
            }
        }
    }
#endif
    fsprint("FS-BOOT: Booting image...\n\r");
    GO(image_start); 

    /* Shouldn't return */
    return -1;
}
