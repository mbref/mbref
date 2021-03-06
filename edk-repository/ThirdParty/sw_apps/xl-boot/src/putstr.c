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
 *
 * derived from print.c:
 *    Copyright (c) 1995 Cygnus Support
 *
 *    The authors hereby grant permission to use, copy, modify,
 *    distribute, and license this software and its documentation
 *    for any purpose, provided that existing copyright notices are
 *    retained in all copies and that this notice is included verbatim
 *    in any distributions. No written agreement, license, or royalty
 *    fee is required for any of the authorized uses. Modifications to
 *    this software may be copyrighted by their authors and need not
 *    follow the licensing terms described here, provided that the new
 *    terms are clearly indicated on the first page of each file where
 *    they apply.
 */

/*
 * putstr -- do a raw print of a string
 */

extern void outbyte (char);

void putstr(char *ptr)
{
	while (*ptr)
		outbyte (*ptr++);
}
