/*! @file srec.c
 * FILE:   $Id:$
 *
 * DESCRIPTION:
 *     This is a light weight Motorola SREC decoder.  The following SREC types
 *     are supported.
 *         Type 0 - SREC START
 *         Type 1 - SREC DATA 1
 *         Type 2 - SREC DATA 2
 *         Type 3 - SREC DATA 3
 *         Type 7 - SREC END TYPE 3
 *         Type 8 - SREC END TYPE 2
 *         Type 9 - SREC END TYPE 1
 *
 *     Refer to the Motorola SREC documentation for SREC format.
 *
 * AUTHOR:
 *     John Williams, PetaLogix <John.Williams@petalogix.com>
 *
 * MODIFICATION:
 *     Benny Chen, PetaLogix <Benny.Chen@petalogix.com>
 *
 * LICENSING:
 *     Copyright (c) 2006 PetaLogix. All rights reserved.
 *
 *  No part of this program may be reproduced or adapted in  any form  or by
 *  any means, electronic or mechanical, without  permission from PetaLogix.
 *  This program is  confidential and  may not be  disclosed, decompiled  or
 *  reverse engineered without permission in writing from PetaLogix.
 *
 */
#include "fs-boot.h"

#ifndef CONFIG_NO_SREC

/*!
 * Check if ASCII character is a digit
 * 
 * @param  ASCII character
 *
 * @return  Return 1 if is digit
 */
static int p_isdigit(char x)
{
    if(x >= '0' && x <= '9') {
        return 1;
    } else {
        return 0;
    }
}

static int p_isupper(char x)
{
    if(x >= 'A' && x <= 'F') {
        return 1;
    } else {
        return 0;
    }
}

static int p_islower(char x)
{
    if(x >= 'a' && x <= 'f') {
        return 1;
    } else {
        return 0;
    }
}

/*!
 * Return the hex equivalent value of the ASCII characer
 * 
 * @param  ASCII character
 *
 * @return  Return the hex value
 */
unsigned char nybble_to_val(char x)
{
	if(p_isdigit(x))
		return x-'0';
	else if(p_isupper(x))
		return x-'A'+10;
	else if(p_islower(x))
		return x-'a'+10;
	else
		return -1;
}

	
int grab_hex_byte(char *buffer)
{
	return nybble_to_val(buffer[0])*16 + nybble_to_val(buffer[1]);
}

unsigned int grab_hex_word(char *buffer)
{
	return grab_hex_byte(buffer)*256 + grab_hex_byte(buffer+2);
}

unsigned int grab_hex_dword(char *buffer)
{
	return grab_hex_word(buffer)*65536 + grab_hex_word(buffer+4);
}

/*!
 * Given a SREC line, parse the line and return the information associated
 * with the SREC.
 * 
 * @param  buffer - pointer to SREC line.
 * @param  binlen - pointer to storage for the data length.
 * @param  addr -   pointer to the address at which the data is to be written 
 *                  in memory.
 * @param  data -   Pointer to the buffer to store the binary data.
 *
 * @return  The SREC type.
 */
int decode_srec_line(char *buffer, int *binlen, unsigned long *addr,
                                                      unsigned char *data)
{
	int type, data_count, i; 
        unsigned int ch = 0;
        int inc = 0;
        unsigned char cksum = 0;

        /* Start from the first S */
        for(; *buffer; buffer++) {
            /* Found our S */
	    if(*buffer =='S') {
                /* Move to the next byte */
                buffer++;
                break;
            }
        }

        /* Check if there is any data */
        if(*buffer == '\0') {
            /* return an invalid type for empty record */
            return 99;
        } 

        /* Get the type */
	type = *buffer -'0';
        buffer++;

        /* Get our count in bytes - 1 byte field */
	if((*binlen = grab_hex_byte(buffer)) < 0) {
            /* Invalid count field */
            return -1;
        }
        /* Increment to start of address field */
        buffer += 2;

        /* Initialise our check sum */
        cksum = *binlen;

	data_count=0;
	switch(type)
	{
	case 0: /* Type Start */
	case 1:	/* Type 1 */
                /*  checksum = 1 byte, Address field = 2 bytes */
                *binlen -= 3;
                /* Get our 2 bytes address field */
                *addr = (unsigned long)grab_hex_word(buffer);
                /* Increment to start of data field */
                inc = 2;
		break;
	case 2: /* Type 2 */
                /*  checksum = 1 byte, Address field = 3 bytes */
                *binlen -= 4;
                *addr = (unsigned long)grab_hex_word(buffer);
                *addr = (*addr << 8) | grab_hex_byte(buffer + 4);
                inc = 3;
                break;
	case 3: /* Type 3 */
                /*  checksum = 1 byte, Address field = 4 bytes */
                *binlen -= 5;
                /* Get our 4 bytes address field */
                *addr = (unsigned long)grab_hex_dword(buffer);
                /* Increment to start of data field */
                inc = 4;
		break;
        case 7: /* SREC End for Type 3 */
                /* No data field */
                *binlen = 0;
                *addr = (unsigned long)grab_hex_dword(buffer);
                inc = 4;
                break;
        case 8: /* SREC End for Type 2 */
                /* No data field */
                *binlen = 0;
                *addr = (unsigned long)grab_hex_word(buffer);
                *addr = (*addr << 8) | grab_hex_byte(buffer + 4);
                inc = 3;
                break;
        case 9: /* SREC End for Type 1 */
                /* No data field */
                *binlen = 0;
                *addr = (unsigned long)grab_hex_word(buffer);
                inc = 2;
                break;
	default:
                /* Invalid or not supported type */
                return -1;
	}

        /* Update the cksum and increment to start of data */
        for(i = 0; i < inc; i++) {
            cksum += grab_hex_byte(buffer);
            buffer += 2;
        }

        /* Copy data */
	if((data_count = *binlen))
	{
		while(data_count--)
		{
			ch = grab_hex_byte(buffer);
                        *data = (unsigned char) ch;
                        data++;
                        cksum += ch;
                        buffer += 2;
		}
	}

        /* Get the checksum - 1 byte */
        if((ch = grab_hex_byte(buffer)) < 0) {
            /* No checksum found */
            return -1;
        }
        
        /* Compare the checksum */
        if((unsigned char) ch != (unsigned char)~cksum) {
            /* Checksum don't match */
            //xil_printf("DEBUG: Checksum failed: Expect:0x%x, Got:0x%x\n\r",
            //           (unsigned char) ch, (unsigned char)~cksum); 
            return -1;
        }

	return type;
}

#endif

