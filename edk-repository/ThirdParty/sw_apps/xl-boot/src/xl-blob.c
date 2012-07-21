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

#include "putstr.h"
#include "putnum.h"

#include "xl-blob.h"

static inline void locblob_info(struct locblob * const locblob)
{
	putstr("LB: ");
	putstr(locblob->header.name);
	putstr(", ");
	putstr(locblob->header.date);
	putstr(", ");
	putnum0(locblob->header.size);
	putstr(" byte\r\n");
}

int locblob_probe(struct locblob * const locblob)
{
	if (*(u32 *)locblob == XLB_LOCBLOB_KEY) {
		locblob_info(locblob);
		return 1;
	} else
		return 0;
}
