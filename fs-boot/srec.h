/*! @file srec.h
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

#define SREC_START      0       /*!< Start Record (module name)               */
#define SREC_DATA2      1       /*!< Data  Record with 2 byte address         */
#define SREC_DATA3      2       /*!< Data  Record with 3 byte address         */
#define SREC_DATA4      3       /*!< Data  Record with 4 byte address         */
#define SREC_END4       7       /*!< End   Record with 4 byte start address   */
#define SREC_END3       8       /*!< End   Record with 3 byte start address   */
#define SREC_END2       9       /*!< End   Record with 2 byte start address   */
#define SREC_EMPTY      99      /*!< Empty Record without any data            */


int grab_hex_byte(char *buffer);
unsigned int grab_hex_word(char *buffer);
unsigned int grab_hex_dword(char *buffer);
int decode_srec_line(char *buffer, int *binlen, unsigned long *addr,
                                                          char *data);
#endif /* CONFIG_NO_SREC */
