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

#ifndef _XLB_XTM_H
#define _XLB_XTM_H

#ifdef __cplusplus
extern "C" {
#endif

#include "xparameters.h"
#include "xlb_config.h"

#if (XLB_BOOT_COUNTER != 0)

extern inline void xtm_init(void);
extern inline void xtm_deinit(void);
extern inline unsigned int xtm_event(void);
extern inline void xtm_ack(void);

#endif /* XLB_BOOT_COUNTER */

#endif /* _XLB_XTM_H */
