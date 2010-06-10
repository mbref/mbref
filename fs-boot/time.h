/*! @file time.h
 * FILE:   $Id:$
 *
 * DESCRIPTION:
 *     This is a light weight timer support for Xilinx's OPB_TIMER_0
 *
 * AUTHOR:
 *     Benny Chen, PetaLogix <Benny.Chen@petalogix.com>
 *
 * MODIFICATION:
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
void udelay(unsigned long usec);
int timer_init (void);
